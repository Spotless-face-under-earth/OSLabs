#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* 在首次适配算法中，分配器维护一个空闲块列表（称为空闲列表），并在接收到内存请求时，
   从列表中扫描第一个足够大的块来满足请求。如果选择的块明显大于请求的大小，则通常会将其分割，
   并将剩余部分添加回列表作为另一个空闲块。
   请参见严蔚敏的《数据结构——C语言版》第196~198页，第8.2节。
*/
// 你应该重写以下函数：default_init, default_init_memmap, default_alloc_pages, default_free_pages。
/*
 * 首次适配内存分配（FFMA）的详细说明
 * (1) 准备：为了实现首次适配内存分配（FFMA），我们需要使用某种列表来管理空闲内存块。
 *          结构体 `free_area_t` 用于管理空闲内存块。首先，你应该熟悉 `list.h` 中的 `struct list`。
 *          `struct list` 是一个简单的双向链表实现。你应该知道如何使用：
 *          list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *          另一个巧妙的方法是将通用的列表结构转换为特定的结构（如 `struct page`）：
 *          你可以找到一些宏：le2page（在 `memlayout.h` 中），（在未来的实验中：le2vma（在 `vmm.h` 中），le2proc（在 `proc.h` 中）等）
 * (2) default_init：你可以重用 `default_init` 函数来初始化 `free_list` 并将 `nr_free` 设置为 0。
 *          `free_list` 用于记录空闲内存块。`nr_free` 是空闲内存块的总数。
 * (3) default_init_memmap：调用图：kern_init --> pmm_init --> page_init --> init_memmap --> pmm_manager->init_memmap
 *          这个函数用于初始化一个空闲块（参数：addr_base, page_number）。
 *          首先，你应该初始化这个空闲块中的每个页面（在 `memlayout.h` 中），包括：
 *              p->flags 应设置位 PG_property（表示这个页面是有效的。在 `pmm_init` 函数（在 `pmm.c` 中）中，
 *              位 PG_reserved 已经在 p->flags 中设置）
 *              如果这个页面是空闲的并且不是空闲块的第一个页面，p->property 应设置为 0。
 *              如果这个页面是空闲的并且是空闲块的第一个页面，p->property 应设置为块的总数量。
 *              p->ref 应设置为 0，因为现在 p 是空闲的且没有引用。
 *              我们可以使用 p->page_link 将这个页面链接到 `free_list`，（例如：list_add_before(&free_list, &(p->page_link)); ）
 *          最后，我们应该计算空闲内存块的数量：nr_free += n
 * (4) default_alloc_pages：在空闲列表中搜索第一个足够大的空闲块（块大小 >= n），调整空闲块的大小，并返回分配块的地址。
 *          (4.1) 因此，你应该像这样搜索空闲列表：
 *                   list_entry_t le = &free_list;
 *                   while((le=list_next(le)) != &free_list) {
 *                   ....
 *                 (4.1.1) 在 while 循环中，获取 `struct page` 并检查 p->property（记录空闲块的数量）是否 >= n？
 *                   struct Page *p = le2page(le, page_link);
 *                   if(p->property >= n){ ...
 *                 (4.1.2) 如果我们找到了这个 p，这意味着我们找到了一个足够大的空闲块（块大小 >= n），前 n 个页面可以被分配。
 *                     这个页面的一些标志位应该被设置：PG_reserved = 1, PG_property = 0
 *                     从 `free_list` 中删除这些页面
 *                     (4.1.2.1) 如果 (p->property > n)，我们应该重新计算剩余空闲块的数量，
 *                           （例如：le2page(le, page_link))->property = p->property - n;）
 *                 (4.1.3) 重新计算 `nr_free`（剩余所有空闲块的数量）
 *                 (4.1.4) 返回 p
 *               (4.2) 如果找不到足够大的空闲块（块大小 >= n），则返回 NULL
 * (5) default_free_pages：将页面重新链接到空闲列表中，可能将小的空闲块合并成大的空闲块。
 *               (5.1) 根据撤回块的基地址，搜索空闲列表，找到正确的位置
 *                     （从低地址到高地址），并将页面插入。可以使用 list_next, le2page, list_add_before
 *               (5.2) 重置页面的字段，如 p->ref, p->flags (PageProperty)
 *               (5.3) 尝试合并低地址或高地址的块。注意：应该正确更改某些页面的 p->property。
 */

free_area_t free_area; // 一个空闲区域的结构，其中包含一个空闲列表（list_entry_t类型，里面有俩指针）和一个空闲块计数器。

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void)
{                          // 在物理内存分配过程中初始化一个空闲内存块链表和相应的计数器
    list_init(&free_list); // 调用 list_init 函数，目的是初始化一个链表结构 free_list ，它用来跟踪可用的物理内存块（或者说是空闲的内存块）。通过初始化 free_list，确保了链表是空的
    nr_free = 0;           // nr_free 是一个用来记录空闲内存块数量的计数器。通过将其初始化为 0，表示初始时没有任何内存块是空闲的
}
/*
随着物理内存的分配和释放，free_list 链表会动态地更新，
nr_free 计数器也会相应地增加或减少以反映系统中的空闲内存块数量。
这有助于操作系统在内存分配请求时找到适当的内存块以分配给进程
*/

static void
default_init_memmap(struct Page *base, size_t n)
{ // 在物理内存分配过程中初始化一个内存页映射表（mem_map）和一个链表（free_list）
    // 初始化一个给定地址和大小的空闲块。
    // base: 指向第一个页面的指。n: 页数。

    assert(n > 0); // 确保传递给函数的页数 n 大于 0

    // 遍历从 base 开始的每一个页面，
    // 确保每一页都被预留（PageReserved(p)）。然后清除每一页的标志和属性，并设置其引用计数为0
    struct Page *p = base; // 创建一个指向 base 的指针 p，它将用于遍历页表中的所有页
    for (; p != base + n; p++)
    {
        // 从基地址 base 开始，对 n 个连续的物理页面进行初始化
        assert(PageReserved(p));    // 检查页 p 是否被保留。在内存初始化过程中，通常某些页会被保留用于特定目的，例如内核代码或者设备驱动程序，这些页不应该用于通用内存分配
        p->flags = p->property = 0; // 将页的标志（flags）和属性（property）设置为零，表示这些页当前没有特殊的标志或属性。
        set_page_ref(p, 0);         // 设置引用计数(page的ref成员)为0,表示这些页当前没有被引用
    }

    // 设置基本页面的属性
    // 空闲块中第一个页的property属性标志整个空闲块中总页数
    base->property = n; // 将 base 页的属性字段设置为 n，表示该页表映射了多少个页

    // 将这个页面标记为空闲块开始的页面
    // 将page->flag的PG_property位，也就是第1位（总共0-63有64位）设置为1
    SetPageProperty(base); // 设置 base 页的一个特殊标志，表示这个页是页表

    // 更新空闲区域的结构中的空闲块的数量
    nr_free += n; // 将系统中的空闲页数增加 n，因为在初始化过程中，这些页是空闲的

    // 将初始化的页添加到 free_list 链表中。
    // 如果 free_list 为空，直接将初始化的页添加为链表的第一个元素。
    // 如果 free_list 不为空，它会遍历链表并将初始化的页插入到适当的位置，以保持链表的有序性。
    // 空闲链表为空就直接添加
    if (list_empty(&free_list))
    {
        list_add(&free_list, &(base->page_link));
        // 这个函数将在para2节点插入在para1后面
    }
    else
    {
        // 非空的话就遍历链表，找到合适的位置插入

        // 哨兵节点，表示链表的开始和结束。
        list_entry_t *le = &free_list;

        // 遍历一轮链表
        while ((le = list_next(le)) != &free_list)
        {
            struct Page *page = le2page(le, page_link); // le2page从给定的链表节点le获取到包含它的struct Page实例。

            // 找到了合适的位置，链表是排序的，便于后续搜索，插入要维持有序状态
            if (base < page)
            {
                // 在当前链表条目之前插入新页面
                list_add_before(le, &(base->page_link));
                break;
            }
            else if (list_next(le) == &free_list)
            {
                // 到了链表尾部，循环一轮的最后，直接添加
                list_add(le, &(base->page_link));
            }
        }
    }
}

static struct Page *
default_alloc_pages(size_t n)
{
    // 在物理内存分配过程中，尝试分配连续的 n 个物理内存页

    assert(n > 0); // 确保请求的页数 n 大于 0

    // nr_free 记录了当前可用的空闲页数量，如果请求的页数 n 大于可用的页数，函数返回 NULL
    // 表示无法满足分配请求
    if (n > nr_free)
    {
        return NULL;
    }

    // 遍历空闲列表，找到第一个空闲块大小大于等于n的块
    struct Page *page = NULL;      // 初始化一个指向 Page 结构的指针 page，用于记录已分配的起始页
    list_entry_t *le = &free_list; // 初始化一个链表元素指针 le，指向空闲页链表的头部
    while ((le = list_next(le)) != &free_list)
    {                                            // 遍历空闲页链表
        struct Page *p = le2page(le, page_link); // 将链表元素 le 转换为 Page 结构，从而可以访问每个空闲页的属性
        if (p->property >= n)
        {
            // 检查当前空闲页 p 是否有足够多的连续页来满足请求。如果是，将当前页 p 分配给 page 变量，并退出循环
            page = p;
            break;
        }
    }
    if (page != NULL)
    {
        // 找到了要分配的页，获取这个块前面的链表条目，并从空闲列表中删除这个块。
        list_entry_t *prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n)
        {                                     // 找到的空闲块比请求的大，它将被拆分为两部分
            struct Page *p = page + n;        // p指向第二部分的第一个页面
            p->property = page->property - n; // 更新第二部分的空闲块大小
            SetPageProperty(p);               // 设置第二部分的第一个页面的属性，set property bit，标志空闲
            list_add(prev, &(p->page_link));  // 将第二部分添加到空闲列表中
        }

        // 更新空闲页面计数 nr_free，并清除已分配块的属性标志。
        nr_free -= n;
        ClearPageProperty(page);
    }
    return page;
}

// 释放一段连续的物理页面，base 是要释放的页面的起始地址，n 是要释放的页面数量
static void
default_free_pages(struct Page *base, size_t n)
{
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++)
    {
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页面不是保留的，也不是空闲块的第一个页面
        p->flags = 0;                                 // 清除页面的标志
        set_page_ref(p, 0);                           // 设置页面的引用计数为0
    }
    base->property = n;    // 将要释放的页面中的第一个页面的property属性设置为n，表示需要释放n个页面
    SetPageProperty(base); // 将页面的标志设置为 PG_property，表示这是一个空闲块的第一个页面。
    nr_free += n;          // 将要释放的页面数量 n 加到空闲页面计数 nr_free 中，表示这些页面现在是空闲的

    /*
     * 2110049
     * 用 list_empty 宏检查空闲页面链表是否为空
     * 如果为空，则将要添加的页面作为链表的头节点，并返回
     * 否则，函数遍历空闲页面链表，找到要添加的页面在链表中的位置，并将其插入到链表中
     */
    if (list_empty(&free_list))
    {
        list_add(&free_list, &(base->page_link));
    }
    else
    {
        list_entry_t *le = &free_list;
        while ((le = list_next(le)) != &free_list)
        {                                               // 遍历一轮链表
            struct Page *page = le2page(le, page_link); // 使用 le2page 宏将链表节点转换为页面结构体
            // 比较要添加的页面的地址和当前节点所对应的页面的地址的大小
            // 保证链表中页面地址的升序排列
            if (base < page)
            {
                list_add_before(le, &(base->page_link));
                break;
            }
            else if (list_next(le) == &free_list)
            {
                list_add(le, &(base->page_link)); // 加在链表末尾
            }
        }
    }

    // 合并空闲页面链表中相邻的空闲块
    // 判断空闲块之前的块
    list_entry_t *le = list_prev(&(base->page_link)); // 取空闲块的前一个页面的链表节点
    if (le != &free_list)                             // 如果 le 不等于空闲页面链表的头节点，则说明空闲块的前一个页面存在
    {
        /* 2110049
         * 函数使用 le2page 宏将链表节点转换为页面结构体，并将其赋值给指针 p
         * 如果 p 的 property 字段加上 p 的地址等于 base 的地址，则说明 p 和 base 是相邻的空闲块，可以将它们合并成一个更大的空闲块
         * 然后使用 ClearPageProperty 宏将 base 的 PG_property 标志位清除
         * 使用 list_del 宏将 base 从空闲页面链表中删除。
         * 函数将 base 的地址更新为 p 的地址，表示合并后的空闲块的起始页面为 p。
         */
        p = le2page(le, page_link);
        if (p + p->property == base)
        {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }

    // 判断空闲块之后的块
    le = list_next(&(base->page_link));
    if (le != &free_list)
    {
        p = le2page(le, page_link);
        if (base + base->property == p)
        {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}

static void
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

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
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

    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL);
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
    assert((p1 = alloc_pages(3)) != NULL);
    assert(alloc_page() == NULL);
    assert(p0 + 2 == p1);

    p2 = p0 + 1;
    free_page(p0);
    free_pages(p1, 3);
    assert(PageProperty(p0) && p0->property == 1);
    assert(PageProperty(p1) && p1->property == 3);

    assert((p0 = alloc_page()) == p2 - 1);
    free_page(p0);
    assert((p0 = alloc_pages(2)) == p2 + 1);

    free_pages(p0, 2);
    free_page(p2);

    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL);

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
}
// 这个结构体在
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};
