# Lab 1

## 练习一

`<span style="color:grey;">阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？</span>`

`la sp, bootstacktop` 完成的操作是初始化内核栈指针 sp，将sp的值设置为bootstacktop标签所代表的地址，而bootstacktop所在地址在之后的汇编代码中。由于硬件本身不提供单独的栈空间，因此，需要使用这条指令手动创建栈空间，同时在分配时保持栈由高到低的空间分布特点。

`tail kern_init `完成的操作是跳转到 kern_init 函数(init.c文件中，应该是**链接的时候把代码附到了一起**)启动内核初始化流程，kern_init是内核主体代码入口,它负责初始化内核。tail指令是尾递归函数调用，在调用函数后不会返回到调用者，它将**控制流直接转到kern_init函数**开始执行真正的内核初始化过程。此外，tail指令调用者的栈帧将被覆盖，直接将返回地址指向下一个函数调用的地址。

## 练习二

`<span style="color:grey;">请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。 要求完成问题1提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程和定时器中断中断处理的流程。实现要求的部分代码后，运行整个系统，大约每1秒会输出一次”100 ticks”，输出10行。</span>`

实现代码如下：

```cpp
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
             /* LAB1 EXERCISE2   YOUR CODE :  */
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个 `100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
	    clock_set_next_event();
	    ticks++;
	    if(tickts%100==0){
	    	print_tickts();
	    	num++;
	    }
	    if(num==10){
	    	sbi_shutdown();
	    }
            break;
        //……其他异常处理机制
        default:
            print_trapframe(tf);
            break;
    }
}
```

实现结果如下图：

! [实验结果一](https://github.com/Spotless-face-under-earth/OSLabs/blob/master/lab1/lab1-1.png)

## 扩展练习一

`<span style="color:grey;">回答：描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中各寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。</span>`

! [中断处理过程](https://github.com/Spotless-face-under-earth/OSLabs/blob/master/lab1/%E5%BC%82%E5%B8%B8%E5%A4%84%E7%90%86.png)

以S态的时钟中断为例，计时器通过传递时钟中断的参数给 `sbi_call` ，之后跳转到 `kern/trap/trapentry.S`的 `__alltraps`标记 ，通过 `SAVE_ALL `保存当前执行流的上下文，**并通过  `mov a0, sp `保存中断的栈地址 sp 参数**，之后切换为  `kern/trap/trap.c `的中断处理函数 `trap()`，进入 `trap()`的执行流。切换前的上下文作为一个结构体，传递给 `trap()`作为函数参数 ， `kern/trap/trap.c `按照中断类型进行分发(`trap_dispatch(), interrupt_handler()`)，然后执行时钟中断对应的处理语句，累加计数器，设置下一次时钟中断，最后返回到 `kern/trap/trapentry.S`。

SAVE_ALL中各寄存器保存在栈中的位置，使用了 `addi sp, sp, -36 * REGBYTES`开辟栈空间，并逐个通过 `STORE xi, i*REGBYTES(sp)`而存储在栈中的。

__alltraps 中需要保存所有寄存器。因为之后会通过 `jal trap`进行函数调用，在函数调用结束后，可能还要继续调用其他函数（虽然在本次实验中在trap函数中已经结束），这就需要返回地址处的寄存器值是正确的，以保证之后进行正确的执行流。

## 扩展练习二

`<span style="color:grey;">回答：在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？</span>`

trapentry.S中的汇编指令 `csrw sscratch, sp `能将中断产生时的 sp 值保存到 sscratch 特权寄存器中。`csrrw s0, sscratch, x0` 将原 sp 值（sscratch 特权寄存器中的值）存入 s0 中，然后将sscratch的值设置为0（相当于是复原）。目的是通过sscratch临时保存sp,避免在 `save all`期间修改sp值而导致的问题。

在 `save all`中保存 `stval ,scause`等 csr 寄存器,是为了记录异常中断的来源信息,如产生异常的指令地址和原因等。同时，在trap.c文件中有函数 `print_trapframe`和 `print_regs`用于输出寄存器信息，我们保存这些csr寄存器之后可以调用这些函数来获取异常中断有关信息。

在 `restore all`中不还原这些csr值,是因为这些值只在异常处理期间需要使用,恢复任务上下文时它们不相关。

## 扩展练习三

`<span style="color:grey;">编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。</span>`

实现代码如下：

```cpp
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at %p\n", tf->epc);
            tf->epc += 4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ breakpoint）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
            cprintf("Exception type:Illegal instruction\n");
            cprintf("Illegal instruction caught at %p\n", tf->epc);
            tf->epc += 2;
            break;
        case CAUSE_MISALIGNED_LOAD:
            break;
        case CAUSE_FAULT_LOAD:
            break;
        case CAUSE_MISALIGNED_STORE:
            break;
        case CAUSE_FAULT_STORE:
            break;
        case CAUSE_USER_ECALL:
            break;
        case CAUSE_SUPERVISOR_ECALL:
            break;
        case CAUSE_HYPERVISOR_ECALL:
            break;
        case CAUSE_MACHINE_ECALL:
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
```

这里需要注意的是，在输出异常后，还需要跳过当前指令，否则会一直执行异常指令。非法指令mret为4个字节，而ebreak断点异常为2个字节，让epc加上这个字节数、跳过异常指令即可。

验证结果如下图：

! [实验结果二](https://github.com/Spotless-face-under-earth/OSLabs/blob/master/lab1/lab1-2.png)

## 最终得分

! [最终得分](https://github.com/Spotless-face-under-earth/OSLabs/blob/master/lab1/lab1-3.png)
