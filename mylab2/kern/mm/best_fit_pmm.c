#include <pmm.h>
#include <list.h>
#include <string.h>
#include <best_fit_pmm.h>
#include <stdio.h>

/* 在首次适应算法中，分配器维护一个空闲块列表（称为自由列表），并在接收到内存请求时，沿列表扫描第一个足够大的块来满足请求。
   如果选择的块显著大于请求的大小，那么通常会将其分割，剩余部分作为另一个空闲块添加到列表中。
   请参阅严蔚敏的《数据结构——C语言版》第196~198页，第8.2节。
*/

// 你应该重写以下函数：default_init, default_init_memmap, default_alloc_pages, default_free_pages。
/*
 * FFMA的详细说明
 * (1) 准备：为了实现首次适应内存分配（FFMA），我们需要使用某种列表来管理空闲内存块。
 *         结构体 free_area_t 用于管理空闲内存块。首先，你应该熟悉 list.h 中的 struct list 结构。
 *         struct list 是一个简单的双向链表实现。你应该知道如何使用：list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *         另一个巧妙的方法是将通用的 list 结构转换为特定的结构（如 struct page）：
 *         你可以找到一些宏：le2page（在 memlayout.h 中），（未来实验中：le2vma（在 vmm.h 中），le2proc（在 proc.h 中）等）
 * (2) default_init：你可以重用示例的 default_init 函数来初始化 free_list 并将 nr_free 设置为 0。
 *         free_list 用于记录空闲内存块。nr_free 是空闲内存块的总数。
 * (3) default_init_memmap：调用图：kern_init --> pmm_init --> page_init --> init_memmap --> pmm_manager->init_memmap
 *         此函数用于初始化一个空闲块（参数：addr_base, page_number）。
 *         首先，你应该初始化此空闲块中的每个页面（在 memlayout.h 中），包括：
 *             p->flags 应该设置 PG_property 位（表示该页面有效。在 pmm_init 函数（在 pmm.c 中），PG_reserved 位在 p->flags 中被设置）
 *             如果该页面是空闲的且不是空闲块的第一个页面，p->property 应该设置为 0。
 *             如果该页面是空闲的且是空闲块的第一个页面，p->property 应该设置为块的总数量。
 *             p->ref 应该设置为 0，因为现在 p 是空闲的，没有任何引用。
 *             我们可以使用 p->page_link 将此页面链接到 free_list（例如：list_add_before(&free_list, &(p->page_link));）
 *         最后，我们应该累加空闲内存块的数量：nr_free += n
 * (4) default_alloc_pages：在自由列表中查找第一个空闲块（块大小 >= n），调整空闲块的大小，并返回分配块的地址。
 *         (4.1) 因此，你应该像这样搜索自由列表：
 *                list_entry_t le = &free_list;
 *                while((le = list_next(le)) != &free_list) {
 *                ....
 *          (4.1.1) 在 while 循环中，获取 struct page 并检查 p->property（记录空闲块的数量）是否 >= n？
 *                struct Page *p = le2page(le, page_link);
 *                if(p->property >= n) { ...
 *          (4.1.2) 如果我们找到了这个 p，那么这意味着我们找到了一个空闲块（块大小 >= n），前 n 个页面可以被分配。
 *                  该页面的一些标志位应该被设置：PG_reserved = 1, PG_property = 0
 *                  从自由列表中取消链接这些页面
 *                  (4.1.2.1) 如果 (p->property > n)，我们应该重新计算剩余空闲块的数量，
 *                            （例如：le2page(le, page_link))->property = p->property - n;）
 *          (4.1.3) 重新计算 nr_free（剩余所有空闲块的数量）
 *          (4.1.4) 返回 p
 *          (4.2) 如果找不到一个空闲块（块大小 >= n），则返回 NULL
 * (5) default_free_pages：将页面重新链接到自由列表中，可能会将小的空闲块合并成大的空闲块。
 *         (5.1) 根据回收块的基地址，搜索自由列表，找到正确的位置
 *               （从低地址到高地址），并插入页面。（可能使用 list_next, le2page, list_add_before）
 *         (5.2) 重置页面的字段，例如 p->ref, p->flags（PageProperty）
 *         (5.3) 尝试合并低地址或高地址的块。注意：应该正确地更改某些页面的 p->property。
 */
// 在memlayout.h中可以找到相关定义

/*
初始化时准备Best Fit算法所需的数据结构,用来跟踪和选择最佳匹配的内存块以满足分配请求
*/

static free_area_t free_area; // 用于管理空闲内存块的结构体，包含一个双向链表 free_list 和一个整数 nr_free，分别用于存储空闲内存块和跟踪空闲内存块的数量。

#define free_list (free_area.free_list) // 存储空闲内存块的双向链表。
#define nr_free (free_area.nr_free)     // 记录当前可用的空闲页框数

static void
best_fit_init(void)
{
    list_init(&free_list); // 初始化链表free_list
    nr_free = 0;           // 初始化可用内存块数量为0
}

/*
在系统启动时初始化一段物理内存块的属性，准备一段物理内存，以供后续的内存分配操作使用，
同时确保这些内存块按照地址顺序排列，以便Best Fit算法能够高效地找到最佳匹配的内存块
*/

// best_fit_init_memmap 函数
// 作用：用于初始化一段物理内存块的属性，并将这些页框加入到空闲内存链表中。此函数会将连续的内存页初始化为“空闲状态”，并将它们按地址顺序插入到空闲链表中，以便后续分配时能快速找到适合的块。
// 流程：
// 遍历每个页框并清空标志位，设置引用计数为 0。
// 将这些页框标记为可用的“属性页”，并插入到空闲链表中。
// 如果链表已经包含其他页块，按照地址顺序将这些新页块插入合适的位置。

static void
best_fit_init_memmap(struct Page *base, size_t n)
{
    assert(n > 0); // 确保内存块数量大于0
    struct Page *p = base;

    // 遍历要初始化的内存块
    for (; p != base + n; p++)
    {
        assert(PageReserved(p)); // 确保内存块是保留的

        /*LAB2 EXERCISE 2: 2111454*/
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        // 结构体Page的相关定义见memlayout.h
        // 新添加代码
        p->flags = 0;       // 清空标志信息
        p->property = 0;    // 清空属性信息
        set_page_ref(p, 0); // 设置引用计数为0
    }

    base->property = n;    // 设置base的属性为n，表示这些页是连续的
    SetPageProperty(base); // 设置base为属性页
    nr_free += n;          // 增加可用内存块的数量

    if (list_empty(&free_list))
    {
        // 如果free_list为空，将base添加为第一个元素
        list_add(&free_list, &(base->page_link));
    }
    else
    {
        list_entry_t *le = &free_list;

        // 遍历free_list链表  按照地址大小进行插入
        while ((le = list_next(le)) != &free_list)
        {
            struct Page *page = le2page(le, page_link);
            /*LAB2 EXERCISE 2: 2111454*/
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            if (base < page)
            {
                list_add_before(&(page->page_link), &(base->page_link));
                break;
            }
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
            if (list_next(le) == &free_list)
            {
                list_add_after(&(page->page_link), &(base->page_link));
            }
        }
    }
}

/*
实现Best Fit算法的页面分配过程
高效地找到满足需求的最佳匹配的页面，并进行分配
*/
// best_fit_alloc_pages 函数
// 作用：实现 Best Fit 算法的内存分配函数。该函数会遍历空闲链表，找到一个最小的可满足分配请求的内存块进行分配。
// 流程：
// 遍历空闲链表，查找连续的空闲内存块，找到满足需求的最小块。
// 如果找到合适的块，则从链表中删除该块，并分配所需的页面数。
// 如果剩余的块大小大于所需的页面数，则将剩余部分重新插入链表。
// 如果找不到满足需求的块，则返回 NULL。

static struct Page *
best_fit_alloc_pages(size_t n)
{
    assert(n > 0); // 确保分配的页面数量大于0
    if (n > nr_free)
    { // 如果需求的页面数量大于可用的页面数量，分配失败
        return NULL;
    }

    struct Page *page = NULL;      // 用于记录分配的页面
    list_entry_t *le = &free_list; // 从free_list的头部开始查找可用页面
    size_t min_size = nr_free + 1; // 初始化最小连续空闲页框数量

    /*LAB2 EXERCISE 2: 2111454*/
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && min_size > p->property)
        { // 当前页是否够大&&是否小于之前找到的最小页块（即是否是更好的匹配）
            page = p;
            min_size = p->property;
        }
    }

    if (page != NULL)
    { // 开始分配
        list_entry_t *prev = list_prev(&(page->page_link));
        list_del(&(page->page_link)); // 从空闲链表中删除已分配的页面
        if (page->property > n)
        {
            struct Page *p = page + n;

            // 如果剩余的空闲页框数量大于需求的页面数量，将剩余部分添加到空闲链表
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link)); // 将剩余的空闲页块重新插入到链表中，插入到原来位置的前一个节点 prev 后面。
        }
        nr_free -= n;            // 减少可用内存块的数量
        ClearPageProperty(page); // 清除页面的属性标记
    }
    return page; // 返回分配的页面
}

/*
实现了Best Fit算法的页面释放
*/

// best_fit_free_pages 函数
// 作用：实现 Best Fit 算法的内存释放函数。它将释放的页面重新插入到空闲链表中，并且会尝试将连续的空闲页块合并成更大的块。
// 流程：
// 释放指定的页块并将它们重新插入到空闲链表中。
// 检查前后是否存在可以合并的空闲页块，如果是，则将这些块合并成更大的块，以减少内存碎片。

static void
best_fit_free_pages(struct Page *base, size_t n)
{
    assert(n > 0); // 确保分配的页面数量大于0
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(!PageReserved(p) && !PageProperty(p));

        // 清除当前页块的标志和属性信息，并将页块的引用计数设置为0
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: 2111454*/
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值

    // 设置当前页块的属性为已释放的页块数，并将当前页块标记为已分配状态，然后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;

    if (list_empty(&free_list))
    {
        // 如果空闲链表为空，直接将当前页块添加到链表头部
        list_add(&free_list, &(base->page_link));
    }
    else
    {
        // 如果空闲链表非空，遍历链表，找到合适的位置插入当前页块
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list)
        {
            struct Page *page = le2page(le, page_link);

            // 当当前页块的地址小于当前遍历的页块地址时，将当前页块插入到当前遍历的页块前面
            if (base < page)
            {
                list_add_before(le, &(base->page_link));
                break;
            }
            else if (list_next(le) == &free_list)
            {
                // 如果已经到达链表尾部，将当前页块添加到链表尾部
                list_add(le, &(base->page_link));
            }
        }
    }

    list_entry_t *le = list_prev(&(base->page_link)); // 合并前面的连续页块
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: 2111454*/
        // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
        // 3、清除当前页块的属性标记，表示不再是空闲页块
        // 4、从链表中删除当前页块
        // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块

        // 判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        if (p + p->property == base)
        {
            // 更新前一个空闲页块的大小，加上当前页块的大小
            p->property += base->property;
            ClearPageProperty(base);      // 清除当前页块的属性标记，表示不再是空闲页块
            list_del(&(base->page_link)); // 从链表中删除当前页块
            base = p;                     // 将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        if (base + base->property == p)
        {
            // 判断后面的空闲页块是否与当前页块是连续的，如果是连续的，则将它们合并
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t
best_fit_nr_free_pages(void)
{
    return nr_free; // 返回当前系统中空闲页面的数量。
}

static void
// basic_check 函数
// 作用：基本的检查函数，测试内存分配器的最基本功能（如分配、释放内存等），并验证内存分配器的工作是否正确。
basic_check(void)
{
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    assert(alloc_page() == NULL);

    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3);

    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(alloc_page() == NULL);

    free_page(p0);
    assert(!list_empty(&free_list));

    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);

    assert(nr_free == 0);
    free_list = free_list_store;
    nr_free = nr_free_store;

    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the best fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!

// best_fit_check 函数
// 作用：用于验证 Best Fit 内存管理算法的正确性。它会执行一系列的分配和释放操作，确保算法按照预期工作并且没有错误。

static void
best_fit_check(void)
{
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count++, total += p->property;
    }
    assert(total == nr_free_pages());

    basic_check();

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
    free_pages(p0 + 4, 1);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
    assert(alloc_pages(2) != NULL); // best fit feature
    assert(p0 + 4 == p1);

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    p2 = p0 + 1;
    free_pages(p0, 5);
    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
    assert(nr_free == 0);
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
    }
    assert(count == 0);
    assert(total == 0);
#ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
#endif
}

// 这是一个全局的 pmm_manager 结构体，它封装了内存管理器的所有操作接口，包括初始化、内存分配、内存释放、检查等函数。这个结构体的 name 字段标识了这是一个 Best Fit 内存管理器。
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager",
    .init = best_fit_init,
    .init_memmap = best_fit_init_memmap,
    .alloc_pages = best_fit_alloc_pages,
    .free_pages = best_fit_free_pages,
    .nr_free_pages = best_fit_nr_free_pages,
    .check = best_fit_check,
};
