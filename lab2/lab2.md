## Lab 2


#### 练习1：理解first-fit 连续物理内存分配算法（思考题）
<span style="color:grey;">first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合`kern/mm/default_pmm.c`中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。</span>
`default_init_memmap`中首先关注参数及调用时机。
`default_alloc_pages`是进行物理页的分配，参数为需要的内存大小。在函数里面操作系统将根据参数，在空闲页面链表里寻找最近合适的页，并将该页的大小`property`和剩余空闲链表中内存的大小`nr_free`等参数进行修改。
`default_free_pages`类似，但是会根据页的大小找到它对应的位置，找到位置后根据前后的`property`值的大小决定向前或向后合并。

#### 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）
<span style="color:grey;">在完成练习一后，参考kern/mm/default_pmm.c对First Fit算法的实现，编程实现Best Fit页面分配算法，算法的时空复杂度不做要求，能通过测试即可。 请在实验报告中简要说明你的设计实现过程，阐述代码是如何对物理内存进行分配和释放。</span>
内存分配时：遍历空闲链表，查找满足需求的空闲页框；如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
内存释放时：与内配内存时同样的查找方式，并进行合并。


#### 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）

Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...

   [伙伴分配器的一个极简实现](http://coolshell.cn/articles/10427.html)， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
 
#### 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）

slub算法，实现两层架构的高效内存单元分配，第一层是基于页大小的内存分配，第二层是在第一层基础上实现基于任意大小的内存分配。可简化实现，能够体现其主体思想即可。

 - 参考[linux的slub分配算法/](http://www.ibm.com/developerworks/cn/linux/l-cn-slub/)，在ucore中实现slub分配算法。要求有比较充分的测试用例说明实现的正确性，需要有设计文档。

#### 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）
  - 如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？


> Challenges是选做，完成Challenge的同学可单独提交Challenge。完成得好的同学可获得最终考试成绩的加分。
