
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址，lui加载高20位进入t0，低12位为页内偏移量我们不需要
    # boot_page_table_sv39 是一个全局符号，它指向系统启动时使用的页表的开始位置
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量，这一步是得到虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号（物理地址右移12位抹除低12位后得到物理页号）
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39 39位虚拟地址模式
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    //一个按位或操作把satp的MODE字段，高1000后面全0，和三级页表的物理页号t1合并到一起
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    // satp放的是最高级页表的物理页号（44位），除此以外还有MODE字段（4位）、备用 ASID（address space identifier）16位
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    #如果不加参数的， sfence.vma 会刷新整个 TLB 。你可以在后面加上一个虚拟地址，这样 sfence.vma 只会刷新这个虚拟地址的映射
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop) // 指向一个预先定义的虚拟地址 bootstacktop，这是内核栈的顶部。
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <buf>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	43e60613          	addi	a2,a2,1086 # ffffffffc0206478 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	60e010ef          	jal	ra,ffffffffc0201658 <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00001517          	auipc	a0,0x1
ffffffffc0200056:	61e50513          	addi	a0,a0,1566 # ffffffffc0201670 <etext+0x6>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	0dc000ef          	jal	ra,ffffffffc020013a <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table 初始化中断描述符表IDT
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management 物理内存管理
ffffffffc0200066:	71d000ef          	jal	ra,ffffffffc0200f82 <pmm_init>
    pmm_init()函数需要注册缺页中断处理程序，用于处理页面访问异常。
    当程序试图访问一个不存在的页面时，CPU会触发缺页异常，此时会调用缺页中断处理程序
    该程序会在物理内存中分配一个新的页面，并将其映射到虚拟地址空间中。
    */

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    clock_init()函数需要注册时钟中断处理程序，用于定时触发时钟中断。
    当时钟中断被触发时，CPU会跳转到时钟中断处理程序，该程序会更新系统时间，并执行一些周期性的操作，如调度进程等
    */
    //这两个函数都需要使用中断描述符表，所以要在中断描述符表初始化之后再初始化时钟中断

    intr_enable();  // enable irq interrupt 开启中断
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	0dc010ef          	jal	ra,ffffffffc0201182 <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	0a6010ef          	jal	ra,ffffffffc0201182 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020013a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020013c:	00001517          	auipc	a0,0x1
ffffffffc0200140:	55450513          	addi	a0,a0,1364 # ffffffffc0201690 <etext+0x26>
void print_kerninfo(void) {
ffffffffc0200144:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200146:	f6dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020014a:	00000597          	auipc	a1,0x0
ffffffffc020014e:	ee858593          	addi	a1,a1,-280 # ffffffffc0200032 <kern_init>
ffffffffc0200152:	00001517          	auipc	a0,0x1
ffffffffc0200156:	55e50513          	addi	a0,a0,1374 # ffffffffc02016b0 <etext+0x46>
ffffffffc020015a:	f59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020015e:	00001597          	auipc	a1,0x1
ffffffffc0200162:	50c58593          	addi	a1,a1,1292 # ffffffffc020166a <etext>
ffffffffc0200166:	00001517          	auipc	a0,0x1
ffffffffc020016a:	56a50513          	addi	a0,a0,1386 # ffffffffc02016d0 <etext+0x66>
ffffffffc020016e:	f45ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200172:	00006597          	auipc	a1,0x6
ffffffffc0200176:	e9e58593          	addi	a1,a1,-354 # ffffffffc0206010 <buf>
ffffffffc020017a:	00001517          	auipc	a0,0x1
ffffffffc020017e:	57650513          	addi	a0,a0,1398 # ffffffffc02016f0 <etext+0x86>
ffffffffc0200182:	f31ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200186:	00006597          	auipc	a1,0x6
ffffffffc020018a:	2f258593          	addi	a1,a1,754 # ffffffffc0206478 <end>
ffffffffc020018e:	00001517          	auipc	a0,0x1
ffffffffc0200192:	58250513          	addi	a0,a0,1410 # ffffffffc0201710 <etext+0xa6>
ffffffffc0200196:	f1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	6dd58593          	addi	a1,a1,1757 # ffffffffc0206877 <end+0x3ff>
ffffffffc02001a2:	00000797          	auipc	a5,0x0
ffffffffc02001a6:	e9078793          	addi	a5,a5,-368 # ffffffffc0200032 <kern_init>
ffffffffc02001aa:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ae:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001b2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001b4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001b8:	95be                	add	a1,a1,a5
ffffffffc02001ba:	85a9                	srai	a1,a1,0xa
ffffffffc02001bc:	00001517          	auipc	a0,0x1
ffffffffc02001c0:	57450513          	addi	a0,a0,1396 # ffffffffc0201730 <etext+0xc6>
}
ffffffffc02001c4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001c6:	b5f5                	j	ffffffffc02000b2 <cprintf>

ffffffffc02001c8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001c8:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ca:	00001617          	auipc	a2,0x1
ffffffffc02001ce:	59660613          	addi	a2,a2,1430 # ffffffffc0201760 <etext+0xf6>
ffffffffc02001d2:	04e00593          	li	a1,78
ffffffffc02001d6:	00001517          	auipc	a0,0x1
ffffffffc02001da:	5a250513          	addi	a0,a0,1442 # ffffffffc0201778 <etext+0x10e>
void print_stackframe(void) {
ffffffffc02001de:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02001e0:	1cc000ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc02001e4 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001e4:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02001e6:	00001617          	auipc	a2,0x1
ffffffffc02001ea:	5aa60613          	addi	a2,a2,1450 # ffffffffc0201790 <etext+0x126>
ffffffffc02001ee:	00001597          	auipc	a1,0x1
ffffffffc02001f2:	5c258593          	addi	a1,a1,1474 # ffffffffc02017b0 <etext+0x146>
ffffffffc02001f6:	00001517          	auipc	a0,0x1
ffffffffc02001fa:	5c250513          	addi	a0,a0,1474 # ffffffffc02017b8 <etext+0x14e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02001fe:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200200:	eb3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200204:	00001617          	auipc	a2,0x1
ffffffffc0200208:	5c460613          	addi	a2,a2,1476 # ffffffffc02017c8 <etext+0x15e>
ffffffffc020020c:	00001597          	auipc	a1,0x1
ffffffffc0200210:	5e458593          	addi	a1,a1,1508 # ffffffffc02017f0 <etext+0x186>
ffffffffc0200214:	00001517          	auipc	a0,0x1
ffffffffc0200218:	5a450513          	addi	a0,a0,1444 # ffffffffc02017b8 <etext+0x14e>
ffffffffc020021c:	e97ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200220:	00001617          	auipc	a2,0x1
ffffffffc0200224:	5e060613          	addi	a2,a2,1504 # ffffffffc0201800 <etext+0x196>
ffffffffc0200228:	00001597          	auipc	a1,0x1
ffffffffc020022c:	5f858593          	addi	a1,a1,1528 # ffffffffc0201820 <etext+0x1b6>
ffffffffc0200230:	00001517          	auipc	a0,0x1
ffffffffc0200234:	58850513          	addi	a0,a0,1416 # ffffffffc02017b8 <etext+0x14e>
ffffffffc0200238:	e7bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc020023c:	60a2                	ld	ra,8(sp)
ffffffffc020023e:	4501                	li	a0,0
ffffffffc0200240:	0141                	addi	sp,sp,16
ffffffffc0200242:	8082                	ret

ffffffffc0200244 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200244:	1141                	addi	sp,sp,-16
ffffffffc0200246:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200248:	ef3ff0ef          	jal	ra,ffffffffc020013a <print_kerninfo>
    return 0;
}
ffffffffc020024c:	60a2                	ld	ra,8(sp)
ffffffffc020024e:	4501                	li	a0,0
ffffffffc0200250:	0141                	addi	sp,sp,16
ffffffffc0200252:	8082                	ret

ffffffffc0200254 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200254:	1141                	addi	sp,sp,-16
ffffffffc0200256:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200258:	f71ff0ef          	jal	ra,ffffffffc02001c8 <print_stackframe>
    return 0;
}
ffffffffc020025c:	60a2                	ld	ra,8(sp)
ffffffffc020025e:	4501                	li	a0,0
ffffffffc0200260:	0141                	addi	sp,sp,16
ffffffffc0200262:	8082                	ret

ffffffffc0200264 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200264:	7115                	addi	sp,sp,-224
ffffffffc0200266:	ed5e                	sd	s7,152(sp)
ffffffffc0200268:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020026a:	00001517          	auipc	a0,0x1
ffffffffc020026e:	5c650513          	addi	a0,a0,1478 # ffffffffc0201830 <etext+0x1c6>
kmonitor(struct trapframe *tf) {
ffffffffc0200272:	ed86                	sd	ra,216(sp)
ffffffffc0200274:	e9a2                	sd	s0,208(sp)
ffffffffc0200276:	e5a6                	sd	s1,200(sp)
ffffffffc0200278:	e1ca                	sd	s2,192(sp)
ffffffffc020027a:	fd4e                	sd	s3,184(sp)
ffffffffc020027c:	f952                	sd	s4,176(sp)
ffffffffc020027e:	f556                	sd	s5,168(sp)
ffffffffc0200280:	f15a                	sd	s6,160(sp)
ffffffffc0200282:	e962                	sd	s8,144(sp)
ffffffffc0200284:	e566                	sd	s9,136(sp)
ffffffffc0200286:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200288:	e2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020028c:	00001517          	auipc	a0,0x1
ffffffffc0200290:	5cc50513          	addi	a0,a0,1484 # ffffffffc0201858 <etext+0x1ee>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc0200298:	000b8563          	beqz	s7,ffffffffc02002a2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020029c:	855e                	mv	a0,s7
ffffffffc020029e:	3a4000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002a2:	00001c17          	auipc	s8,0x1
ffffffffc02002a6:	626c0c13          	addi	s8,s8,1574 # ffffffffc02018c8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002aa:	00001917          	auipc	s2,0x1
ffffffffc02002ae:	5d690913          	addi	s2,s2,1494 # ffffffffc0201880 <etext+0x216>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002b2:	00001497          	auipc	s1,0x1
ffffffffc02002b6:	5d648493          	addi	s1,s1,1494 # ffffffffc0201888 <etext+0x21e>
        if (argc == MAXARGS - 1) {
ffffffffc02002ba:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002bc:	00001b17          	auipc	s6,0x1
ffffffffc02002c0:	5d4b0b13          	addi	s6,s6,1492 # ffffffffc0201890 <etext+0x226>
        argv[argc ++] = buf;
ffffffffc02002c4:	00001a17          	auipc	s4,0x1
ffffffffc02002c8:	4eca0a13          	addi	s4,s4,1260 # ffffffffc02017b0 <etext+0x146>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002cc:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002ce:	854a                	mv	a0,s2
ffffffffc02002d0:	234010ef          	jal	ra,ffffffffc0201504 <readline>
ffffffffc02002d4:	842a                	mv	s0,a0
ffffffffc02002d6:	dd65                	beqz	a0,ffffffffc02002ce <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02002dc:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002de:	e1bd                	bnez	a1,ffffffffc0200344 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc02002e0:	fe0c87e3          	beqz	s9,ffffffffc02002ce <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002e4:	6582                	ld	a1,0(sp)
ffffffffc02002e6:	00001d17          	auipc	s10,0x1
ffffffffc02002ea:	5e2d0d13          	addi	s10,s10,1506 # ffffffffc02018c8 <commands>
        argv[argc ++] = buf;
ffffffffc02002ee:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4401                	li	s0,0
ffffffffc02002f2:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02002f4:	330010ef          	jal	ra,ffffffffc0201624 <strcmp>
ffffffffc02002f8:	c919                	beqz	a0,ffffffffc020030e <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002fa:	2405                	addiw	s0,s0,1
ffffffffc02002fc:	0b540063          	beq	s0,s5,ffffffffc020039c <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200300:	000d3503          	ld	a0,0(s10)
ffffffffc0200304:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200306:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	31c010ef          	jal	ra,ffffffffc0201624 <strcmp>
ffffffffc020030c:	f57d                	bnez	a0,ffffffffc02002fa <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020030e:	00141793          	slli	a5,s0,0x1
ffffffffc0200312:	97a2                	add	a5,a5,s0
ffffffffc0200314:	078e                	slli	a5,a5,0x3
ffffffffc0200316:	97e2                	add	a5,a5,s8
ffffffffc0200318:	6b9c                	ld	a5,16(a5)
ffffffffc020031a:	865e                	mv	a2,s7
ffffffffc020031c:	002c                	addi	a1,sp,8
ffffffffc020031e:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200322:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200324:	fa0555e3          	bgez	a0,ffffffffc02002ce <kmonitor+0x6a>
}
ffffffffc0200328:	60ee                	ld	ra,216(sp)
ffffffffc020032a:	644e                	ld	s0,208(sp)
ffffffffc020032c:	64ae                	ld	s1,200(sp)
ffffffffc020032e:	690e                	ld	s2,192(sp)
ffffffffc0200330:	79ea                	ld	s3,184(sp)
ffffffffc0200332:	7a4a                	ld	s4,176(sp)
ffffffffc0200334:	7aaa                	ld	s5,168(sp)
ffffffffc0200336:	7b0a                	ld	s6,160(sp)
ffffffffc0200338:	6bea                	ld	s7,152(sp)
ffffffffc020033a:	6c4a                	ld	s8,144(sp)
ffffffffc020033c:	6caa                	ld	s9,136(sp)
ffffffffc020033e:	6d0a                	ld	s10,128(sp)
ffffffffc0200340:	612d                	addi	sp,sp,224
ffffffffc0200342:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200344:	8526                	mv	a0,s1
ffffffffc0200346:	2fc010ef          	jal	ra,ffffffffc0201642 <strchr>
ffffffffc020034a:	c901                	beqz	a0,ffffffffc020035a <kmonitor+0xf6>
ffffffffc020034c:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200350:	00040023          	sb	zero,0(s0)
ffffffffc0200354:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200356:	d5c9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200358:	b7f5                	j	ffffffffc0200344 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020035a:	00044783          	lbu	a5,0(s0)
ffffffffc020035e:	d3c9                	beqz	a5,ffffffffc02002e0 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200360:	033c8963          	beq	s9,s3,ffffffffc0200392 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200364:	003c9793          	slli	a5,s9,0x3
ffffffffc0200368:	0118                	addi	a4,sp,128
ffffffffc020036a:	97ba                	add	a5,a5,a4
ffffffffc020036c:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200374:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200376:	e591                	bnez	a1,ffffffffc0200382 <kmonitor+0x11e>
ffffffffc0200378:	b7b5                	j	ffffffffc02002e4 <kmonitor+0x80>
ffffffffc020037a:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020037e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200380:	d1a5                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200382:	8526                	mv	a0,s1
ffffffffc0200384:	2be010ef          	jal	ra,ffffffffc0201642 <strchr>
ffffffffc0200388:	d96d                	beqz	a0,ffffffffc020037a <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	00044583          	lbu	a1,0(s0)
ffffffffc020038e:	d9a9                	beqz	a1,ffffffffc02002e0 <kmonitor+0x7c>
ffffffffc0200390:	bf55                	j	ffffffffc0200344 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200392:	45c1                	li	a1,16
ffffffffc0200394:	855a                	mv	a0,s6
ffffffffc0200396:	d1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020039a:	b7e9                	j	ffffffffc0200364 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020039c:	6582                	ld	a1,0(sp)
ffffffffc020039e:	00001517          	auipc	a0,0x1
ffffffffc02003a2:	51250513          	addi	a0,a0,1298 # ffffffffc02018b0 <etext+0x246>
ffffffffc02003a6:	d0dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc02003aa:	b715                	j	ffffffffc02002ce <kmonitor+0x6a>

ffffffffc02003ac <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ac:	00006317          	auipc	t1,0x6
ffffffffc02003b0:	06430313          	addi	t1,t1,100 # ffffffffc0206410 <is_panic>
ffffffffc02003b4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003b8:	715d                	addi	sp,sp,-80
ffffffffc02003ba:	ec06                	sd	ra,24(sp)
ffffffffc02003bc:	e822                	sd	s0,16(sp)
ffffffffc02003be:	f436                	sd	a3,40(sp)
ffffffffc02003c0:	f83a                	sd	a4,48(sp)
ffffffffc02003c2:	fc3e                	sd	a5,56(sp)
ffffffffc02003c4:	e0c2                	sd	a6,64(sp)
ffffffffc02003c6:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003c8:	020e1a63          	bnez	t3,ffffffffc02003fc <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003cc:	4785                	li	a5,1
ffffffffc02003ce:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003d2:	8432                	mv	s0,a2
ffffffffc02003d4:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003d6:	862e                	mv	a2,a1
ffffffffc02003d8:	85aa                	mv	a1,a0
ffffffffc02003da:	00001517          	auipc	a0,0x1
ffffffffc02003de:	53650513          	addi	a0,a0,1334 # ffffffffc0201910 <commands+0x48>
    va_start(ap, fmt);
ffffffffc02003e2:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003e4:	ccfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02003e8:	65a2                	ld	a1,8(sp)
ffffffffc02003ea:	8522                	mv	a0,s0
ffffffffc02003ec:	ca7ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc02003f0:	00001517          	auipc	a0,0x1
ffffffffc02003f4:	36850513          	addi	a0,a0,872 # ffffffffc0201758 <etext+0xee>
ffffffffc02003f8:	cbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02003fc:	062000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200400:	4501                	li	a0,0
ffffffffc0200402:	e63ff0ef          	jal	ra,ffffffffc0200264 <kmonitor>
    while (1) {
ffffffffc0200406:	bfed                	j	ffffffffc0200400 <__panic+0x54>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	1b2010ef          	jal	ra,ffffffffc02015d2 <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	fe07b923          	sd	zero,-14(a5) # ffffffffc0206418 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00001517          	auipc	a0,0x1
ffffffffc0200432:	50250513          	addi	a0,a0,1282 # ffffffffc0201930 <commands+0x68>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	18c0106f          	j	ffffffffc02015d2 <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	andi	a0,a0,255
ffffffffc0200450:	1680106f          	j	ffffffffc02015b8 <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	1980106f          	j	ffffffffc02015ec <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	2e478793          	addi	a5,a5,740 # ffffffffc020074c <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00001517          	auipc	a0,0x1
ffffffffc0200482:	4d250513          	addi	a0,a0,1234 # ffffffffc0201950 <commands+0x88>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00001517          	auipc	a0,0x1
ffffffffc0200492:	4da50513          	addi	a0,a0,1242 # ffffffffc0201968 <commands+0xa0>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00001517          	auipc	a0,0x1
ffffffffc02004a0:	4e450513          	addi	a0,a0,1252 # ffffffffc0201980 <commands+0xb8>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00001517          	auipc	a0,0x1
ffffffffc02004ae:	4ee50513          	addi	a0,a0,1262 # ffffffffc0201998 <commands+0xd0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00001517          	auipc	a0,0x1
ffffffffc02004bc:	4f850513          	addi	a0,a0,1272 # ffffffffc02019b0 <commands+0xe8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00001517          	auipc	a0,0x1
ffffffffc02004ca:	50250513          	addi	a0,a0,1282 # ffffffffc02019c8 <commands+0x100>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00001517          	auipc	a0,0x1
ffffffffc02004d8:	50c50513          	addi	a0,a0,1292 # ffffffffc02019e0 <commands+0x118>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00001517          	auipc	a0,0x1
ffffffffc02004e6:	51650513          	addi	a0,a0,1302 # ffffffffc02019f8 <commands+0x130>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00001517          	auipc	a0,0x1
ffffffffc02004f4:	52050513          	addi	a0,a0,1312 # ffffffffc0201a10 <commands+0x148>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00001517          	auipc	a0,0x1
ffffffffc0200502:	52a50513          	addi	a0,a0,1322 # ffffffffc0201a28 <commands+0x160>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00001517          	auipc	a0,0x1
ffffffffc0200510:	53450513          	addi	a0,a0,1332 # ffffffffc0201a40 <commands+0x178>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00001517          	auipc	a0,0x1
ffffffffc020051e:	53e50513          	addi	a0,a0,1342 # ffffffffc0201a58 <commands+0x190>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	54850513          	addi	a0,a0,1352 # ffffffffc0201a70 <commands+0x1a8>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00001517          	auipc	a0,0x1
ffffffffc020053a:	55250513          	addi	a0,a0,1362 # ffffffffc0201a88 <commands+0x1c0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00001517          	auipc	a0,0x1
ffffffffc0200548:	55c50513          	addi	a0,a0,1372 # ffffffffc0201aa0 <commands+0x1d8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00001517          	auipc	a0,0x1
ffffffffc0200556:	56650513          	addi	a0,a0,1382 # ffffffffc0201ab8 <commands+0x1f0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00001517          	auipc	a0,0x1
ffffffffc0200564:	57050513          	addi	a0,a0,1392 # ffffffffc0201ad0 <commands+0x208>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00001517          	auipc	a0,0x1
ffffffffc0200572:	57a50513          	addi	a0,a0,1402 # ffffffffc0201ae8 <commands+0x220>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00001517          	auipc	a0,0x1
ffffffffc0200580:	58450513          	addi	a0,a0,1412 # ffffffffc0201b00 <commands+0x238>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00001517          	auipc	a0,0x1
ffffffffc020058e:	58e50513          	addi	a0,a0,1422 # ffffffffc0201b18 <commands+0x250>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00001517          	auipc	a0,0x1
ffffffffc020059c:	59850513          	addi	a0,a0,1432 # ffffffffc0201b30 <commands+0x268>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00001517          	auipc	a0,0x1
ffffffffc02005aa:	5a250513          	addi	a0,a0,1442 # ffffffffc0201b48 <commands+0x280>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00001517          	auipc	a0,0x1
ffffffffc02005b8:	5ac50513          	addi	a0,a0,1452 # ffffffffc0201b60 <commands+0x298>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00001517          	auipc	a0,0x1
ffffffffc02005c6:	5b650513          	addi	a0,a0,1462 # ffffffffc0201b78 <commands+0x2b0>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00001517          	auipc	a0,0x1
ffffffffc02005d4:	5c050513          	addi	a0,a0,1472 # ffffffffc0201b90 <commands+0x2c8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00001517          	auipc	a0,0x1
ffffffffc02005e2:	5ca50513          	addi	a0,a0,1482 # ffffffffc0201ba8 <commands+0x2e0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	5d450513          	addi	a0,a0,1492 # ffffffffc0201bc0 <commands+0x2f8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00001517          	auipc	a0,0x1
ffffffffc02005fe:	5de50513          	addi	a0,a0,1502 # ffffffffc0201bd8 <commands+0x310>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00001517          	auipc	a0,0x1
ffffffffc020060c:	5e850513          	addi	a0,a0,1512 # ffffffffc0201bf0 <commands+0x328>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00001517          	auipc	a0,0x1
ffffffffc020061a:	5f250513          	addi	a0,a0,1522 # ffffffffc0201c08 <commands+0x340>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00001517          	auipc	a0,0x1
ffffffffc0200628:	5fc50513          	addi	a0,a0,1532 # ffffffffc0201c20 <commands+0x358>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00001517          	auipc	a0,0x1
ffffffffc020063a:	60250513          	addi	a0,a0,1538 # ffffffffc0201c38 <commands+0x370>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00001517          	auipc	a0,0x1
ffffffffc020064e:	60650513          	addi	a0,a0,1542 # ffffffffc0201c50 <commands+0x388>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00001517          	auipc	a0,0x1
ffffffffc0200666:	60650513          	addi	a0,a0,1542 # ffffffffc0201c68 <commands+0x3a0>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00001517          	auipc	a0,0x1
ffffffffc0200676:	60e50513          	addi	a0,a0,1550 # ffffffffc0201c80 <commands+0x3b8>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00001517          	auipc	a0,0x1
ffffffffc0200686:	61650513          	addi	a0,a0,1558 # ffffffffc0201c98 <commands+0x3d0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00001517          	auipc	a0,0x1
ffffffffc020069a:	61a50513          	addi	a0,a0,1562 # ffffffffc0201cb0 <commands+0x3e8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76c63          	bltu	a4,a5,ffffffffc0200724 <interrupt_handler+0x82>
ffffffffc02006b0:	00001717          	auipc	a4,0x1
ffffffffc02006b4:	6e070713          	addi	a4,a4,1760 # ffffffffc0201d90 <commands+0x4c8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00001517          	auipc	a0,0x1
ffffffffc02006c6:	66650513          	addi	a0,a0,1638 # ffffffffc0201d28 <commands+0x460>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00001517          	auipc	a0,0x1
ffffffffc02006d0:	63c50513          	addi	a0,a0,1596 # ffffffffc0201d08 <commands+0x440>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00001517          	auipc	a0,0x1
ffffffffc02006da:	5f250513          	addi	a0,a0,1522 # ffffffffc0201cc8 <commands+0x400>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00001517          	auipc	a0,0x1
ffffffffc02006e4:	66850513          	addi	a0,a0,1640 # ffffffffc0201d48 <commands+0x480>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02006ee:	d4dff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006f2:	00006697          	auipc	a3,0x6
ffffffffc02006f6:	d2668693          	addi	a3,a3,-730 # ffffffffc0206418 <ticks>
ffffffffc02006fa:	629c                	ld	a5,0(a3)
ffffffffc02006fc:	06400713          	li	a4,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	02e7f733          	remu	a4,a5,a4
ffffffffc0200706:	e29c                	sd	a5,0(a3)
ffffffffc0200708:	cf19                	beqz	a4,ffffffffc0200726 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070a:	60a2                	ld	ra,8(sp)
ffffffffc020070c:	0141                	addi	sp,sp,16
ffffffffc020070e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200710:	00001517          	auipc	a0,0x1
ffffffffc0200714:	66050513          	addi	a0,a0,1632 # ffffffffc0201d70 <commands+0x4a8>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00001517          	auipc	a0,0x1
ffffffffc020071e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0201ce8 <commands+0x420>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00001517          	auipc	a0,0x1
ffffffffc0200730:	63450513          	addi	a0,a0,1588 # ffffffffc0201d60 <commands+0x498>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200736:	bab5                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200738 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200738:	11853783          	ld	a5,280(a0)
ffffffffc020073c:	0007c763          	bltz	a5,ffffffffc020074a <trap+0x12>
    switch (tf->cause) {
ffffffffc0200740:	472d                	li	a4,11
ffffffffc0200742:	00f76363          	bltu	a4,a5,ffffffffc0200748 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200746:	8082                	ret
            print_trapframe(tf);
ffffffffc0200748:	bded                	j	ffffffffc0200642 <print_trapframe>
        interrupt_handler(tf);
ffffffffc020074a:	bfa1                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	addi	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f89ff0ef          	jal	ra,ffffffffc0200738 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <buddy_init>:
static unsigned int buddy_page_num; //伙伴页数目
static unsigned int useable_page_num; //可用的页数目
static struct Page* useable_page_base;

static void
buddy_init(void) {}
ffffffffc0200802:	8082                	ret

ffffffffc0200804 <buddy_nr_free_pages>:
    }
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_page[1];
ffffffffc0200804:	00006797          	auipc	a5,0x6
ffffffffc0200808:	c1c7b783          	ld	a5,-996(a5) # ffffffffc0206420 <buddy_page>
}
ffffffffc020080c:	0047e503          	lwu	a0,4(a5)
ffffffffc0200810:	8082                	ret

ffffffffc0200812 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc0200812:	c56d                	beqz	a0,ffffffffc02008fc <buddy_alloc_pages+0xea>
    if (n > buddy_page[1]){
ffffffffc0200814:	00006817          	auipc	a6,0x6
ffffffffc0200818:	c0c80813          	addi	a6,a6,-1012 # ffffffffc0206420 <buddy_page>
ffffffffc020081c:	00083583          	ld	a1,0(a6)
ffffffffc0200820:	0045e783          	lwu	a5,4(a1)
ffffffffc0200824:	0ca7ea63          	bltu	a5,a0,ffffffffc02008f8 <buddy_alloc_pages+0xe6>
    unsigned int index = 1;
ffffffffc0200828:	4705                	li	a4,1
        if (buddy_page[LEFT_CHILD(index)] >= n){
ffffffffc020082a:	0017169b          	slliw	a3,a4,0x1
ffffffffc020082e:	02069793          	slli	a5,a3,0x20
ffffffffc0200832:	83f9                	srli	a5,a5,0x1e
ffffffffc0200834:	97ae                	add	a5,a5,a1
ffffffffc0200836:	0007e783          	lwu	a5,0(a5)
ffffffffc020083a:	0007061b          	sext.w	a2,a4
ffffffffc020083e:	0006871b          	sext.w	a4,a3
ffffffffc0200842:	fea7f4e3          	bgeu	a5,a0,ffffffffc020082a <buddy_alloc_pages+0x18>
        else if (buddy_page[RIGHT_CHILD(index)] >= n){
ffffffffc0200846:	2705                	addiw	a4,a4,1
ffffffffc0200848:	02071793          	slli	a5,a4,0x20
ffffffffc020084c:	83f9                	srli	a5,a5,0x1e
ffffffffc020084e:	97ae                	add	a5,a5,a1
ffffffffc0200850:	0007e783          	lwu	a5,0(a5)
ffffffffc0200854:	fca7fbe3          	bgeu	a5,a0,ffffffffc020082a <buddy_alloc_pages+0x18>
    unsigned int size = buddy_page[index]; //整个找到的页面一起分配出去
ffffffffc0200858:	02061793          	slli	a5,a2,0x20
ffffffffc020085c:	83f9                	srli	a5,a5,0x1e
ffffffffc020085e:	95be                	add	a1,a1,a5
ffffffffc0200860:	4198                	lw	a4,0(a1)
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc0200862:	00006517          	auipc	a0,0x6
ffffffffc0200866:	bce53503          	ld	a0,-1074(a0) # ffffffffc0206430 <useable_page_base>
    buddy_page[index] = 0; //清零计数，表示在管理页中该节点和其之下的所有结点都不能使用
ffffffffc020086a:	0005a023          	sw	zero,0(a1)
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc020086e:	02e607bb          	mulw	a5,a2,a4
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc0200872:	02071693          	slli	a3,a4,0x20
ffffffffc0200876:	9281                	srli	a3,a3,0x20
ffffffffc0200878:	00269713          	slli	a4,a3,0x2
ffffffffc020087c:	9736                	add	a4,a4,a3
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc020087e:	00006697          	auipc	a3,0x6
ffffffffc0200882:	bba6a683          	lw	a3,-1094(a3) # ffffffffc0206438 <useable_page_num>
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc0200886:	070e                	slli	a4,a4,0x3
    struct Page* new_page = &useable_page_base[index * size - useable_page_num];
ffffffffc0200888:	9f95                	subw	a5,a5,a3
ffffffffc020088a:	1782                	slli	a5,a5,0x20
ffffffffc020088c:	9381                	srli	a5,a5,0x20
ffffffffc020088e:	00279693          	slli	a3,a5,0x2
ffffffffc0200892:	97b6                	add	a5,a5,a3
ffffffffc0200894:	078e                	slli	a5,a5,0x3
ffffffffc0200896:	953e                	add	a0,a0,a5
    for (struct Page* p = new_page; p != new_page + size; p++){
ffffffffc0200898:	972a                	add	a4,a4,a0
ffffffffc020089a:	00e50e63          	beq	a0,a4,ffffffffc02008b6 <buddy_alloc_pages+0xa4>
ffffffffc020089e:	87aa                	mv	a5,a0
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02008a0:	56f5                	li	a3,-3
ffffffffc02008a2:	00878593          	addi	a1,a5,8
ffffffffc02008a6:	60d5b02f          	amoand.d	zero,a3,(a1)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02008aa:	0007a023          	sw	zero,0(a5)
ffffffffc02008ae:	02878793          	addi	a5,a5,40
ffffffffc02008b2:	fee798e3          	bne	a5,a4,ffffffffc02008a2 <buddy_alloc_pages+0x90>
    index = PARENT(index);
ffffffffc02008b6:	0016561b          	srliw	a2,a2,0x1
    while(index > 0){
ffffffffc02008ba:	c221                	beqz	a2,ffffffffc02008fa <buddy_alloc_pages+0xe8>
        buddy_page[index] = MAX(buddy_page[LEFT_CHILD(index)], buddy_page[RIGHT_CHILD(index)]);
ffffffffc02008bc:	00083683          	ld	a3,0(a6)
ffffffffc02008c0:	0016179b          	slliw	a5,a2,0x1
ffffffffc02008c4:	0017871b          	addiw	a4,a5,1
ffffffffc02008c8:	1702                	slli	a4,a4,0x20
ffffffffc02008ca:	1782                	slli	a5,a5,0x20
ffffffffc02008cc:	9301                	srli	a4,a4,0x20
ffffffffc02008ce:	9381                	srli	a5,a5,0x20
ffffffffc02008d0:	070a                	slli	a4,a4,0x2
ffffffffc02008d2:	078a                	slli	a5,a5,0x2
ffffffffc02008d4:	97b6                	add	a5,a5,a3
ffffffffc02008d6:	9736                	add	a4,a4,a3
ffffffffc02008d8:	438c                	lw	a1,0(a5)
ffffffffc02008da:	4318                	lw	a4,0(a4)
ffffffffc02008dc:	00261793          	slli	a5,a2,0x2
ffffffffc02008e0:	0005881b          	sext.w	a6,a1
ffffffffc02008e4:	0007089b          	sext.w	a7,a4
ffffffffc02008e8:	97b6                	add	a5,a5,a3
ffffffffc02008ea:	0108f363          	bgeu	a7,a6,ffffffffc02008f0 <buddy_alloc_pages+0xde>
ffffffffc02008ee:	872e                	mv	a4,a1
ffffffffc02008f0:	c398                	sw	a4,0(a5)
        index = PARENT(index);
ffffffffc02008f2:	8205                	srli	a2,a2,0x1
    while(index > 0){
ffffffffc02008f4:	f671                	bnez	a2,ffffffffc02008c0 <buddy_alloc_pages+0xae>
ffffffffc02008f6:	8082                	ret
        return NULL;
ffffffffc02008f8:	4501                	li	a0,0
}
ffffffffc02008fa:	8082                	ret
Page* buddy_alloc_pages(size_t n) {
ffffffffc02008fc:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02008fe:	00001697          	auipc	a3,0x1
ffffffffc0200902:	4c268693          	addi	a3,a3,1218 # ffffffffc0201dc0 <commands+0x4f8>
ffffffffc0200906:	00001617          	auipc	a2,0x1
ffffffffc020090a:	4c260613          	addi	a2,a2,1218 # ffffffffc0201dc8 <commands+0x500>
ffffffffc020090e:	03800593          	li	a1,56
ffffffffc0200912:	00001517          	auipc	a0,0x1
ffffffffc0200916:	4ce50513          	addi	a0,a0,1230 # ffffffffc0201de0 <commands+0x518>
Page* buddy_alloc_pages(size_t n) {
ffffffffc020091a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020091c:	a91ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200920 <buddy_check>:

static void
buddy_check(void) {
ffffffffc0200920:	7179                	addi	sp,sp,-48
ffffffffc0200922:	e44e                	sd	s3,8(sp)
ffffffffc0200924:	f406                	sd	ra,40(sp)
ffffffffc0200926:	f022                	sd	s0,32(sp)
ffffffffc0200928:	ec26                	sd	s1,24(sp)
ffffffffc020092a:	e84a                	sd	s2,16(sp)
ffffffffc020092c:	e052                	sd	s4,0(sp)
    int all_pages = nr_free_pages();
ffffffffc020092e:	61a000ef          	jal	ra,ffffffffc0200f48 <nr_free_pages>
ffffffffc0200932:	89aa                	mv	s3,a0
    struct Page* p0, *p1, *p2, *p3;
    // 分配过大的页数
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200934:	2505                	addiw	a0,a0,1
ffffffffc0200936:	594000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
ffffffffc020093a:	26051263          	bnez	a0,ffffffffc0200b9e <buddy_check+0x27e>
    // 分配两个组页
    p0 = alloc_pages(1);
ffffffffc020093e:	4505                	li	a0,1
ffffffffc0200940:	58a000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
ffffffffc0200944:	842a                	mv	s0,a0
    assert(p0 != NULL);
ffffffffc0200946:	22050c63          	beqz	a0,ffffffffc0200b7e <buddy_check+0x25e>
    p1 = alloc_pages(2);
ffffffffc020094a:	4509                	li	a0,2
ffffffffc020094c:	57e000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
    assert(p1 == p0 + 2);
ffffffffc0200950:	05040793          	addi	a5,s0,80
    p1 = alloc_pages(2);
ffffffffc0200954:	84aa                	mv	s1,a0
    assert(p1 == p0 + 2);
ffffffffc0200956:	1af51463          	bne	a0,a5,ffffffffc0200afe <buddy_check+0x1de>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020095a:	641c                	ld	a5,8(s0)
    assert(!PageReserved(p0) && !PageProperty(p0));
ffffffffc020095c:	8b85                	andi	a5,a5,1
ffffffffc020095e:	12079063          	bnez	a5,ffffffffc0200a7e <buddy_check+0x15e>
ffffffffc0200962:	641c                	ld	a5,8(s0)
ffffffffc0200964:	8385                	srli	a5,a5,0x1
ffffffffc0200966:	8b85                	andi	a5,a5,1
ffffffffc0200968:	10079b63          	bnez	a5,ffffffffc0200a7e <buddy_check+0x15e>
ffffffffc020096c:	651c                	ld	a5,8(a0)
    assert(!PageReserved(p1) && !PageProperty(p1));
ffffffffc020096e:	8b85                	andi	a5,a5,1
ffffffffc0200970:	0e079763          	bnez	a5,ffffffffc0200a5e <buddy_check+0x13e>
ffffffffc0200974:	651c                	ld	a5,8(a0)
ffffffffc0200976:	8385                	srli	a5,a5,0x1
ffffffffc0200978:	8b85                	andi	a5,a5,1
ffffffffc020097a:	0e079263          	bnez	a5,ffffffffc0200a5e <buddy_check+0x13e>
    // 再分配两个组页
    p2 = alloc_pages(1);
ffffffffc020097e:	4505                	li	a0,1
ffffffffc0200980:	54a000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
    assert(p2 == p0 + 1);
ffffffffc0200984:	02840793          	addi	a5,s0,40
    p2 = alloc_pages(1);
ffffffffc0200988:	8a2a                	mv	s4,a0
    assert(p2 == p0 + 1);
ffffffffc020098a:	12f51a63          	bne	a0,a5,ffffffffc0200abe <buddy_check+0x19e>
    p3 = alloc_pages(8);
ffffffffc020098e:	4521                	li	a0,8
ffffffffc0200990:	53a000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
    assert(p3 == p0 + 8);
ffffffffc0200994:	14040793          	addi	a5,s0,320
    p3 = alloc_pages(8);
ffffffffc0200998:	892a                	mv	s2,a0
    assert(p3 == p0 + 8);
ffffffffc020099a:	24f51263          	bne	a0,a5,ffffffffc0200bde <buddy_check+0x2be>
ffffffffc020099e:	651c                	ld	a5,8(a0)
ffffffffc02009a0:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p3) && !PageProperty(p3 + 7) && PageProperty(p3 + 8));
ffffffffc02009a2:	8b85                	andi	a5,a5,1
ffffffffc02009a4:	efc9                	bnez	a5,ffffffffc0200a3e <buddy_check+0x11e>
ffffffffc02009a6:	12053783          	ld	a5,288(a0)
ffffffffc02009aa:	8385                	srli	a5,a5,0x1
ffffffffc02009ac:	8b85                	andi	a5,a5,1
ffffffffc02009ae:	ebc1                	bnez	a5,ffffffffc0200a3e <buddy_check+0x11e>
ffffffffc02009b0:	14853783          	ld	a5,328(a0)
ffffffffc02009b4:	8385                	srli	a5,a5,0x1
ffffffffc02009b6:	8b85                	andi	a5,a5,1
ffffffffc02009b8:	c3d9                	beqz	a5,ffffffffc0200a3e <buddy_check+0x11e>
    // 回收页
    free_pages(p1, 2);
ffffffffc02009ba:	4589                	li	a1,2
ffffffffc02009bc:	8526                	mv	a0,s1
ffffffffc02009be:	54a000ef          	jal	ra,ffffffffc0200f08 <free_pages>
ffffffffc02009c2:	649c                	ld	a5,8(s1)
ffffffffc02009c4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && PageProperty(p1 + 1));
ffffffffc02009c6:	8b85                	andi	a5,a5,1
ffffffffc02009c8:	0c078b63          	beqz	a5,ffffffffc0200a9e <buddy_check+0x17e>
ffffffffc02009cc:	789c                	ld	a5,48(s1)
ffffffffc02009ce:	8385                	srli	a5,a5,0x1
ffffffffc02009d0:	8b85                	andi	a5,a5,1
ffffffffc02009d2:	c7f1                	beqz	a5,ffffffffc0200a9e <buddy_check+0x17e>
    assert(p1->ref == 0);
ffffffffc02009d4:	409c                	lw	a5,0(s1)
ffffffffc02009d6:	14079463          	bnez	a5,ffffffffc0200b1e <buddy_check+0x1fe>
    free_pages(p0, 1);
ffffffffc02009da:	4585                	li	a1,1
ffffffffc02009dc:	8522                	mv	a0,s0
ffffffffc02009de:	52a000ef          	jal	ra,ffffffffc0200f08 <free_pages>
    free_pages(p2, 1);
ffffffffc02009e2:	8552                	mv	a0,s4
ffffffffc02009e4:	4585                	li	a1,1
ffffffffc02009e6:	522000ef          	jal	ra,ffffffffc0200f08 <free_pages>
    // 回收后再分配
    p2 = alloc_pages(3);
ffffffffc02009ea:	450d                	li	a0,3
ffffffffc02009ec:	4de000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
    assert(p2 == p0);
ffffffffc02009f0:	16a41763          	bne	s0,a0,ffffffffc0200b5e <buddy_check+0x23e>
    free_pages(p2, 3);
ffffffffc02009f4:	458d                	li	a1,3
ffffffffc02009f6:	512000ef          	jal	ra,ffffffffc0200f08 <free_pages>
    assert((p2 + 2)->ref == 0);
ffffffffc02009fa:	483c                	lw	a5,80(s0)
ffffffffc02009fc:	14079163          	bnez	a5,ffffffffc0200b3e <buddy_check+0x21e>
    assert(nr_free_pages() == all_pages >> 1);
ffffffffc0200a00:	2981                	sext.w	s3,s3
ffffffffc0200a02:	546000ef          	jal	ra,ffffffffc0200f48 <nr_free_pages>
ffffffffc0200a06:	4019d993          	srai	s3,s3,0x1
ffffffffc0200a0a:	0d351a63          	bne	a0,s3,ffffffffc0200ade <buddy_check+0x1be>

    p1 = alloc_pages(129);
ffffffffc0200a0e:	08100513          	li	a0,129
ffffffffc0200a12:	4b8000ef          	jal	ra,ffffffffc0200eca <alloc_pages>
    assert(p1 == p0 + 256);
ffffffffc0200a16:	678d                	lui	a5,0x3
ffffffffc0200a18:	80078793          	addi	a5,a5,-2048 # 2800 <kern_entry-0xffffffffc01fd800>
ffffffffc0200a1c:	943e                	add	s0,s0,a5
ffffffffc0200a1e:	1a851063          	bne	a0,s0,ffffffffc0200bbe <buddy_check+0x29e>
    free_pages(p1, 256);
ffffffffc0200a22:	10000593          	li	a1,256
ffffffffc0200a26:	4e2000ef          	jal	ra,ffffffffc0200f08 <free_pages>
    free_pages(p3, 8);
}
ffffffffc0200a2a:	7402                	ld	s0,32(sp)
ffffffffc0200a2c:	70a2                	ld	ra,40(sp)
ffffffffc0200a2e:	64e2                	ld	s1,24(sp)
ffffffffc0200a30:	69a2                	ld	s3,8(sp)
ffffffffc0200a32:	6a02                	ld	s4,0(sp)
    free_pages(p3, 8);
ffffffffc0200a34:	854a                	mv	a0,s2
}
ffffffffc0200a36:	6942                	ld	s2,16(sp)
    free_pages(p3, 8);
ffffffffc0200a38:	45a1                	li	a1,8
}
ffffffffc0200a3a:	6145                	addi	sp,sp,48
    free_pages(p3, 8);
ffffffffc0200a3c:	a1f1                	j	ffffffffc0200f08 <free_pages>
    assert(!PageProperty(p3) && !PageProperty(p3 + 7) && PageProperty(p3 + 8));
ffffffffc0200a3e:	00001697          	auipc	a3,0x1
ffffffffc0200a42:	47268693          	addi	a3,a3,1138 # ffffffffc0201eb0 <commands+0x5e8>
ffffffffc0200a46:	00001617          	auipc	a2,0x1
ffffffffc0200a4a:	38260613          	addi	a2,a2,898 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200a4e:	09200593          	li	a1,146
ffffffffc0200a52:	00001517          	auipc	a0,0x1
ffffffffc0200a56:	38e50513          	addi	a0,a0,910 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200a5a:	953ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageReserved(p1) && !PageProperty(p1));
ffffffffc0200a5e:	00001697          	auipc	a3,0x1
ffffffffc0200a62:	40a68693          	addi	a3,a3,1034 # ffffffffc0201e68 <commands+0x5a0>
ffffffffc0200a66:	00001617          	auipc	a2,0x1
ffffffffc0200a6a:	36260613          	addi	a2,a2,866 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200a6e:	08c00593          	li	a1,140
ffffffffc0200a72:	00001517          	auipc	a0,0x1
ffffffffc0200a76:	36e50513          	addi	a0,a0,878 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200a7a:	933ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(!PageReserved(p0) && !PageProperty(p0));
ffffffffc0200a7e:	00001697          	auipc	a3,0x1
ffffffffc0200a82:	3c268693          	addi	a3,a3,962 # ffffffffc0201e40 <commands+0x578>
ffffffffc0200a86:	00001617          	auipc	a2,0x1
ffffffffc0200a8a:	34260613          	addi	a2,a2,834 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200a8e:	08b00593          	li	a1,139
ffffffffc0200a92:	00001517          	auipc	a0,0x1
ffffffffc0200a96:	34e50513          	addi	a0,a0,846 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200a9a:	913ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(PageProperty(p1) && PageProperty(p1 + 1));
ffffffffc0200a9e:	00001697          	auipc	a3,0x1
ffffffffc0200aa2:	45a68693          	addi	a3,a3,1114 # ffffffffc0201ef8 <commands+0x630>
ffffffffc0200aa6:	00001617          	auipc	a2,0x1
ffffffffc0200aaa:	32260613          	addi	a2,a2,802 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200aae:	09500593          	li	a1,149
ffffffffc0200ab2:	00001517          	auipc	a0,0x1
ffffffffc0200ab6:	32e50513          	addi	a0,a0,814 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200aba:	8f3ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p2 == p0 + 1);
ffffffffc0200abe:	00001697          	auipc	a3,0x1
ffffffffc0200ac2:	3d268693          	addi	a3,a3,978 # ffffffffc0201e90 <commands+0x5c8>
ffffffffc0200ac6:	00001617          	auipc	a2,0x1
ffffffffc0200aca:	30260613          	addi	a2,a2,770 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200ace:	08f00593          	li	a1,143
ffffffffc0200ad2:	00001517          	auipc	a0,0x1
ffffffffc0200ad6:	30e50513          	addi	a0,a0,782 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200ada:	8d3ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(nr_free_pages() == all_pages >> 1);
ffffffffc0200ade:	00001697          	auipc	a3,0x1
ffffffffc0200ae2:	48268693          	addi	a3,a3,1154 # ffffffffc0201f60 <commands+0x698>
ffffffffc0200ae6:	00001617          	auipc	a2,0x1
ffffffffc0200aea:	2e260613          	addi	a2,a2,738 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200aee:	09e00593          	li	a1,158
ffffffffc0200af2:	00001517          	auipc	a0,0x1
ffffffffc0200af6:	2ee50513          	addi	a0,a0,750 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200afa:	8b3ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p1 == p0 + 2);
ffffffffc0200afe:	00001697          	auipc	a3,0x1
ffffffffc0200b02:	33268693          	addi	a3,a3,818 # ffffffffc0201e30 <commands+0x568>
ffffffffc0200b06:	00001617          	auipc	a2,0x1
ffffffffc0200b0a:	2c260613          	addi	a2,a2,706 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200b0e:	08a00593          	li	a1,138
ffffffffc0200b12:	00001517          	auipc	a0,0x1
ffffffffc0200b16:	2ce50513          	addi	a0,a0,718 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200b1a:	893ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p1->ref == 0);
ffffffffc0200b1e:	00001697          	auipc	a3,0x1
ffffffffc0200b22:	40a68693          	addi	a3,a3,1034 # ffffffffc0201f28 <commands+0x660>
ffffffffc0200b26:	00001617          	auipc	a2,0x1
ffffffffc0200b2a:	2a260613          	addi	a2,a2,674 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200b2e:	09600593          	li	a1,150
ffffffffc0200b32:	00001517          	auipc	a0,0x1
ffffffffc0200b36:	2ae50513          	addi	a0,a0,686 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200b3a:	873ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((p2 + 2)->ref == 0);
ffffffffc0200b3e:	00001697          	auipc	a3,0x1
ffffffffc0200b42:	40a68693          	addi	a3,a3,1034 # ffffffffc0201f48 <commands+0x680>
ffffffffc0200b46:	00001617          	auipc	a2,0x1
ffffffffc0200b4a:	28260613          	addi	a2,a2,642 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200b4e:	09d00593          	li	a1,157
ffffffffc0200b52:	00001517          	auipc	a0,0x1
ffffffffc0200b56:	28e50513          	addi	a0,a0,654 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200b5a:	853ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p2 == p0);
ffffffffc0200b5e:	00001697          	auipc	a3,0x1
ffffffffc0200b62:	3da68693          	addi	a3,a3,986 # ffffffffc0201f38 <commands+0x670>
ffffffffc0200b66:	00001617          	auipc	a2,0x1
ffffffffc0200b6a:	26260613          	addi	a2,a2,610 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200b6e:	09b00593          	li	a1,155
ffffffffc0200b72:	00001517          	auipc	a0,0x1
ffffffffc0200b76:	26e50513          	addi	a0,a0,622 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200b7a:	833ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p0 != NULL);
ffffffffc0200b7e:	00001697          	auipc	a3,0x1
ffffffffc0200b82:	2a268693          	addi	a3,a3,674 # ffffffffc0201e20 <commands+0x558>
ffffffffc0200b86:	00001617          	auipc	a2,0x1
ffffffffc0200b8a:	24260613          	addi	a2,a2,578 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200b8e:	08800593          	li	a1,136
ffffffffc0200b92:	00001517          	auipc	a0,0x1
ffffffffc0200b96:	24e50513          	addi	a0,a0,590 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200b9a:	813ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(alloc_pages(all_pages + 1) == NULL);
ffffffffc0200b9e:	00001697          	auipc	a3,0x1
ffffffffc0200ba2:	25a68693          	addi	a3,a3,602 # ffffffffc0201df8 <commands+0x530>
ffffffffc0200ba6:	00001617          	auipc	a2,0x1
ffffffffc0200baa:	22260613          	addi	a2,a2,546 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200bae:	08500593          	li	a1,133
ffffffffc0200bb2:	00001517          	auipc	a0,0x1
ffffffffc0200bb6:	22e50513          	addi	a0,a0,558 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200bba:	ff2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p1 == p0 + 256);
ffffffffc0200bbe:	00001697          	auipc	a3,0x1
ffffffffc0200bc2:	3ca68693          	addi	a3,a3,970 # ffffffffc0201f88 <commands+0x6c0>
ffffffffc0200bc6:	00001617          	auipc	a2,0x1
ffffffffc0200bca:	20260613          	addi	a2,a2,514 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200bce:	0a100593          	li	a1,161
ffffffffc0200bd2:	00001517          	auipc	a0,0x1
ffffffffc0200bd6:	20e50513          	addi	a0,a0,526 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200bda:	fd2ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(p3 == p0 + 8);
ffffffffc0200bde:	00001697          	auipc	a3,0x1
ffffffffc0200be2:	2c268693          	addi	a3,a3,706 # ffffffffc0201ea0 <commands+0x5d8>
ffffffffc0200be6:	00001617          	auipc	a2,0x1
ffffffffc0200bea:	1e260613          	addi	a2,a2,482 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200bee:	09100593          	li	a1,145
ffffffffc0200bf2:	00001517          	auipc	a0,0x1
ffffffffc0200bf6:	1ee50513          	addi	a0,a0,494 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200bfa:	fb2ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200bfe <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc0200bfe:	1141                	addi	sp,sp,-16
ffffffffc0200c00:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200c02:	cded                	beqz	a1,ffffffffc0200cfc <buddy_free_pages+0xfe>
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200c04:	00259693          	slli	a3,a1,0x2
ffffffffc0200c08:	96ae                	add	a3,a3,a1
ffffffffc0200c0a:	068e                	slli	a3,a3,0x3
ffffffffc0200c0c:	96aa                	add	a3,a3,a0
ffffffffc0200c0e:	87aa                	mv	a5,a0
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c10:	4609                	li	a2,2
ffffffffc0200c12:	02d50263          	beq	a0,a3,ffffffffc0200c36 <buddy_free_pages+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c16:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200c18:	8b05                	andi	a4,a4,1
ffffffffc0200c1a:	e369                	bnez	a4,ffffffffc0200cdc <buddy_free_pages+0xde>
ffffffffc0200c1c:	6798                	ld	a4,8(a5)
ffffffffc0200c1e:	8b09                	andi	a4,a4,2
ffffffffc0200c20:	ef55                	bnez	a4,ffffffffc0200cdc <buddy_free_pages+0xde>
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c22:	00878713          	addi	a4,a5,8
ffffffffc0200c26:	40c7302f          	amoor.d	zero,a2,(a4)
ffffffffc0200c2a:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p != base + n; p++) {
ffffffffc0200c2e:	02878793          	addi	a5,a5,40
ffffffffc0200c32:	fed792e3          	bne	a5,a3,ffffffffc0200c16 <buddy_free_pages+0x18>
    unsigned int index = useable_page_num + (unsigned int)(base - useable_page_base), size = 1;
ffffffffc0200c36:	00005797          	auipc	a5,0x5
ffffffffc0200c3a:	7fa7b783          	ld	a5,2042(a5) # ffffffffc0206430 <useable_page_base>
ffffffffc0200c3e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200c42:	878d                	srai	a5,a5,0x3
ffffffffc0200c44:	00001717          	auipc	a4,0x1
ffffffffc0200c48:	76c73703          	ld	a4,1900(a4) # ffffffffc02023b0 <error_string+0x38>
ffffffffc0200c4c:	02e78733          	mul	a4,a5,a4
ffffffffc0200c50:	00005797          	auipc	a5,0x5
ffffffffc0200c54:	7e87a783          	lw	a5,2024(a5) # ffffffffc0206438 <useable_page_num>
    while(buddy_page[index] > 0){
ffffffffc0200c58:	00005617          	auipc	a2,0x5
ffffffffc0200c5c:	7c863603          	ld	a2,1992(a2) # ffffffffc0206420 <buddy_page>
    unsigned int index = useable_page_num + (unsigned int)(base - useable_page_base), size = 1;
ffffffffc0200c60:	4685                	li	a3,1
ffffffffc0200c62:	9fb9                	addw	a5,a5,a4
    while(buddy_page[index] > 0){
ffffffffc0200c64:	02079713          	slli	a4,a5,0x20
ffffffffc0200c68:	8379                	srli	a4,a4,0x1e
ffffffffc0200c6a:	9732                	add	a4,a4,a2
ffffffffc0200c6c:	430c                	lw	a1,0(a4)
ffffffffc0200c6e:	c999                	beqz	a1,ffffffffc0200c84 <buddy_free_pages+0x86>
        index=PARENT(index);
ffffffffc0200c70:	0017d79b          	srliw	a5,a5,0x1
    while(buddy_page[index] > 0){
ffffffffc0200c74:	02079713          	slli	a4,a5,0x20
ffffffffc0200c78:	8379                	srli	a4,a4,0x1e
ffffffffc0200c7a:	9732                	add	a4,a4,a2
ffffffffc0200c7c:	430c                	lw	a1,0(a4)
        size <<= 1;
ffffffffc0200c7e:	0016969b          	slliw	a3,a3,0x1
    while(buddy_page[index] > 0){
ffffffffc0200c82:	f5fd                	bnez	a1,ffffffffc0200c70 <buddy_free_pages+0x72>
    buddy_page[index] = size;
ffffffffc0200c84:	c314                	sw	a3,0(a4)
    while((index = PARENT(index)) > 0){
ffffffffc0200c86:	0017d59b          	srliw	a1,a5,0x1
ffffffffc0200c8a:	e199                	bnez	a1,ffffffffc0200c90 <buddy_free_pages+0x92>
ffffffffc0200c8c:	a0a9                	j	ffffffffc0200cd6 <buddy_free_pages+0xd8>
ffffffffc0200c8e:	85ba                	mv	a1,a4
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200c90:	9bf9                	andi	a5,a5,-2
ffffffffc0200c92:	0017871b          	addiw	a4,a5,1
ffffffffc0200c96:	1702                	slli	a4,a4,0x20
ffffffffc0200c98:	1782                	slli	a5,a5,0x20
ffffffffc0200c9a:	9381                	srli	a5,a5,0x20
ffffffffc0200c9c:	9301                	srli	a4,a4,0x20
ffffffffc0200c9e:	078a                	slli	a5,a5,0x2
ffffffffc0200ca0:	070a                	slli	a4,a4,0x2
ffffffffc0200ca2:	97b2                	add	a5,a5,a2
ffffffffc0200ca4:	9732                	add	a4,a4,a2
ffffffffc0200ca6:	4388                	lw	a0,0(a5)
ffffffffc0200ca8:	4318                	lw	a4,0(a4)
            buddy_page[index] = size;
ffffffffc0200caa:	02059793          	slli	a5,a1,0x20
        size <<= 1;
ffffffffc0200cae:	0016969b          	slliw	a3,a3,0x1
            buddy_page[index] = size;
ffffffffc0200cb2:	83f9                	srli	a5,a5,0x1e
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cb4:	00e508bb          	addw	a7,a0,a4
        size <<= 1;
ffffffffc0200cb8:	8836                	mv	a6,a3
            buddy_page[index] = size;
ffffffffc0200cba:	97b2                	add	a5,a5,a2
        if(buddy_page[LEFT_CHILD(index)] + buddy_page[RIGHT_CHILD(index)] == size){
ffffffffc0200cbc:	00d88663          	beq	a7,a3,ffffffffc0200cc8 <buddy_free_pages+0xca>
            buddy_page[index] = MAX(buddy_page[LEFT_CHILD(index)], buddy_page[RIGHT_CHILD(index)]);
ffffffffc0200cc0:	882a                	mv	a6,a0
ffffffffc0200cc2:	00e57363          	bgeu	a0,a4,ffffffffc0200cc8 <buddy_free_pages+0xca>
ffffffffc0200cc6:	883a                	mv	a6,a4
ffffffffc0200cc8:	0107a023          	sw	a6,0(a5)
    while((index = PARENT(index)) > 0){
ffffffffc0200ccc:	0015d71b          	srliw	a4,a1,0x1
ffffffffc0200cd0:	0005879b          	sext.w	a5,a1
ffffffffc0200cd4:	ff4d                	bnez	a4,ffffffffc0200c8e <buddy_free_pages+0x90>
}
ffffffffc0200cd6:	60a2                	ld	ra,8(sp)
ffffffffc0200cd8:	0141                	addi	sp,sp,16
ffffffffc0200cda:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200cdc:	00001697          	auipc	a3,0x1
ffffffffc0200ce0:	2bc68693          	addi	a3,a3,700 # ffffffffc0201f98 <commands+0x6d0>
ffffffffc0200ce4:	00001617          	auipc	a2,0x1
ffffffffc0200ce8:	0e460613          	addi	a2,a2,228 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200cec:	06500593          	li	a1,101
ffffffffc0200cf0:	00001517          	auipc	a0,0x1
ffffffffc0200cf4:	0f050513          	addi	a0,a0,240 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200cf8:	eb4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert(n > 0);
ffffffffc0200cfc:	00001697          	auipc	a3,0x1
ffffffffc0200d00:	0c468693          	addi	a3,a3,196 # ffffffffc0201dc0 <commands+0x4f8>
ffffffffc0200d04:	00001617          	auipc	a2,0x1
ffffffffc0200d08:	0c460613          	addi	a2,a2,196 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200d0c:	06200593          	li	a1,98
ffffffffc0200d10:	00001517          	auipc	a0,0x1
ffffffffc0200d14:	0d050513          	addi	a0,a0,208 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200d18:	e94ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200d1c <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200d1c:	1141                	addi	sp,sp,-16
ffffffffc0200d1e:	e406                	sd	ra,8(sp)
    assert((n > 0));
ffffffffc0200d20:	18058663          	beqz	a1,ffffffffc0200eac <buddy_init_memmap+0x190>
ffffffffc0200d24:	46f5                	li	a3,29
ffffffffc0200d26:	4601                	li	a2,0
ffffffffc0200d28:	4705                	li	a4,1
ffffffffc0200d2a:	a801                	j	ffffffffc0200d3a <buddy_init_memmap+0x1e>
    for (int i = 1;
ffffffffc0200d2c:	36fd                	addiw	a3,a3,-1
         i++, useable_page_num <<= 1);
ffffffffc0200d2e:	0017179b          	slliw	a5,a4,0x1
ffffffffc0200d32:	4605                	li	a2,1
    for (int i = 1;
ffffffffc0200d34:	14068363          	beqz	a3,ffffffffc0200e7a <buddy_init_memmap+0x15e>
         i++, useable_page_num <<= 1);
ffffffffc0200d38:	873e                	mv	a4,a5
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200d3a:	0097579b          	srliw	a5,a4,0x9
ffffffffc0200d3e:	9fb9                	addw	a5,a5,a4
ffffffffc0200d40:	1782                	slli	a5,a5,0x20
ffffffffc0200d42:	9381                	srli	a5,a5,0x20
ffffffffc0200d44:	feb7e4e3          	bltu	a5,a1,ffffffffc0200d2c <buddy_init_memmap+0x10>
ffffffffc0200d48:	12060463          	beqz	a2,ffffffffc0200e70 <buddy_init_memmap+0x154>
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200d4c:	00a7579b          	srliw	a5,a4,0xa
ffffffffc0200d50:	2785                	addiw	a5,a5,1
    useable_page_base = base + buddy_page_num;
ffffffffc0200d52:	02079693          	slli	a3,a5,0x20
ffffffffc0200d56:	9281                	srli	a3,a3,0x20
ffffffffc0200d58:	00269613          	slli	a2,a3,0x2
ffffffffc0200d5c:	9636                	add	a2,a2,a3
    useable_page_num >>= 1;
ffffffffc0200d5e:	0017571b          	srliw	a4,a4,0x1
    useable_page_base = base + buddy_page_num;
ffffffffc0200d62:	060e                	slli	a2,a2,0x3
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200d64:	00005697          	auipc	a3,0x5
ffffffffc0200d68:	6c468693          	addi	a3,a3,1732 # ffffffffc0206428 <buddy_page_num>
    useable_page_base = base + buddy_page_num;
ffffffffc0200d6c:	962a                	add	a2,a2,a0
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200d6e:	c29c                	sw	a5,0(a3)
    useable_page_num >>= 1;
ffffffffc0200d70:	00005897          	auipc	a7,0x5
ffffffffc0200d74:	6c888893          	addi	a7,a7,1736 # ffffffffc0206438 <useable_page_num>
    useable_page_base = base + buddy_page_num;
ffffffffc0200d78:	00005797          	auipc	a5,0x5
ffffffffc0200d7c:	6ac7bc23          	sd	a2,1720(a5) # ffffffffc0206430 <useable_page_base>
    useable_page_num >>= 1;
ffffffffc0200d80:	00e8a023          	sw	a4,0(a7)
    for (int i = 0; i != buddy_page_num; i++){
ffffffffc0200d84:	00850793          	addi	a5,a0,8
ffffffffc0200d88:	4701                	li	a4,0
ffffffffc0200d8a:	4805                	li	a6,1
ffffffffc0200d8c:	4107b02f          	amoor.d	zero,a6,(a5)
ffffffffc0200d90:	4290                	lw	a2,0(a3)
ffffffffc0200d92:	2705                	addiw	a4,a4,1
ffffffffc0200d94:	02878793          	addi	a5,a5,40
ffffffffc0200d98:	fee61ae3          	bne	a2,a4,ffffffffc0200d8c <buddy_init_memmap+0x70>
    for (int i = buddy_page_num; i != n; i++){
ffffffffc0200d9c:	1702                	slli	a4,a4,0x20
ffffffffc0200d9e:	9301                	srli	a4,a4,0x20
ffffffffc0200da0:	02e58563          	beq	a1,a4,ffffffffc0200dca <buddy_init_memmap+0xae>
ffffffffc0200da4:	00271793          	slli	a5,a4,0x2
ffffffffc0200da8:	97ba                	add	a5,a5,a4
ffffffffc0200daa:	078e                	slli	a5,a5,0x3
ffffffffc0200dac:	07a1                	addi	a5,a5,8
ffffffffc0200dae:	97aa                	add	a5,a5,a0
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200db0:	5679                	li	a2,-2
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200db2:	4689                	li	a3,2
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200db4:	60c7b02f          	amoand.d	zero,a2,(a5)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200db8:	40d7b02f          	amoor.d	zero,a3,(a5)
ffffffffc0200dbc:	fe07ac23          	sw	zero,-8(a5)
ffffffffc0200dc0:	0705                	addi	a4,a4,1
ffffffffc0200dc2:	02878793          	addi	a5,a5,40
ffffffffc0200dc6:	fee597e3          	bne	a1,a4,ffffffffc0200db4 <buddy_init_memmap+0x98>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dca:	00005697          	auipc	a3,0x5
ffffffffc0200dce:	67e6b683          	ld	a3,1662(a3) # ffffffffc0206448 <pages>
ffffffffc0200dd2:	40d506b3          	sub	a3,a0,a3
ffffffffc0200dd6:	00001617          	auipc	a2,0x1
ffffffffc0200dda:	5da63603          	ld	a2,1498(a2) # ffffffffc02023b0 <error_string+0x38>
ffffffffc0200dde:	868d                	srai	a3,a3,0x3
ffffffffc0200de0:	02c686b3          	mul	a3,a3,a2
ffffffffc0200de4:	00001617          	auipc	a2,0x1
ffffffffc0200de8:	5d463603          	ld	a2,1492(a2) # ffffffffc02023b8 <nbase>
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200dec:	00005717          	auipc	a4,0x5
ffffffffc0200df0:	65473703          	ld	a4,1620(a4) # ffffffffc0206440 <npage>
ffffffffc0200df4:	96b2                	add	a3,a3,a2
ffffffffc0200df6:	00c69793          	slli	a5,a3,0xc
ffffffffc0200dfa:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dfc:	06b2                	slli	a3,a3,0xc
ffffffffc0200dfe:	08e7fb63          	bgeu	a5,a4,ffffffffc0200e94 <buddy_init_memmap+0x178>
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e02:	0008a783          	lw	a5,0(a7)
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200e06:	00005617          	auipc	a2,0x5
ffffffffc0200e0a:	66263603          	ld	a2,1634(a2) # ffffffffc0206468 <va_pa_offset>
ffffffffc0200e0e:	9636                	add	a2,a2,a3
ffffffffc0200e10:	00005717          	auipc	a4,0x5
ffffffffc0200e14:	60c73823          	sd	a2,1552(a4) # ffffffffc0206420 <buddy_page>
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e18:	0017959b          	slliw	a1,a5,0x1
ffffffffc0200e1c:	0007871b          	sext.w	a4,a5
ffffffffc0200e20:	02b7f263          	bgeu	a5,a1,ffffffffc0200e44 <buddy_init_memmap+0x128>
ffffffffc0200e24:	40f586bb          	subw	a3,a1,a5
ffffffffc0200e28:	36fd                	addiw	a3,a3,-1
ffffffffc0200e2a:	1682                	slli	a3,a3,0x20
ffffffffc0200e2c:	9281                	srli	a3,a3,0x20
ffffffffc0200e2e:	96ba                	add	a3,a3,a4
ffffffffc0200e30:	0685                	addi	a3,a3,1
ffffffffc0200e32:	070a                	slli	a4,a4,0x2
ffffffffc0200e34:	068a                	slli	a3,a3,0x2
ffffffffc0200e36:	9732                	add	a4,a4,a2
ffffffffc0200e38:	96b2                	add	a3,a3,a2
        buddy_page[i] = 1;
ffffffffc0200e3a:	4585                	li	a1,1
ffffffffc0200e3c:	c30c                	sw	a1,0(a4)
    for (int i = useable_page_num; i < useable_page_num << 1; i++){
ffffffffc0200e3e:	0711                	addi	a4,a4,4
ffffffffc0200e40:	fee69ee3          	bne	a3,a4,ffffffffc0200e3c <buddy_init_memmap+0x120>
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200e44:	fff7869b          	addiw	a3,a5,-1
ffffffffc0200e48:	87b6                	mv	a5,a3
ffffffffc0200e4a:	02d05063          	blez	a3,ffffffffc0200e6a <buddy_init_memmap+0x14e>
ffffffffc0200e4e:	068a                	slli	a3,a3,0x2
ffffffffc0200e50:	0017979b          	slliw	a5,a5,0x1
ffffffffc0200e54:	96b2                	add	a3,a3,a2
        buddy_page[i] = buddy_page[i << 1] << 1;
ffffffffc0200e56:	00279713          	slli	a4,a5,0x2
ffffffffc0200e5a:	9732                	add	a4,a4,a2
ffffffffc0200e5c:	4318                	lw	a4,0(a4)
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200e5e:	16f1                	addi	a3,a3,-4
ffffffffc0200e60:	37f9                	addiw	a5,a5,-2
        buddy_page[i] = buddy_page[i << 1] << 1;
ffffffffc0200e62:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200e66:	c2d8                	sw	a4,4(a3)
    for (int i = useable_page_num - 1; i > 0; i--){
ffffffffc0200e68:	f7fd                	bnez	a5,ffffffffc0200e56 <buddy_init_memmap+0x13a>
}
ffffffffc0200e6a:	60a2                	ld	ra,8(sp)
ffffffffc0200e6c:	0141                	addi	sp,sp,16
ffffffffc0200e6e:	8082                	ret
         (i < BUDDY_MAX_DEPTH) && (useable_page_num + (useable_page_num >> 9) < n);
ffffffffc0200e70:	02800613          	li	a2,40
ffffffffc0200e74:	4785                	li	a5,1
ffffffffc0200e76:	4701                	li	a4,0
ffffffffc0200e78:	b5f5                	j	ffffffffc0200d64 <buddy_init_memmap+0x48>
    buddy_page_num = (useable_page_num >> 9) + 1;
ffffffffc0200e7a:	00a7d79b          	srliw	a5,a5,0xa
ffffffffc0200e7e:	2785                	addiw	a5,a5,1
    useable_page_base = base + buddy_page_num;
ffffffffc0200e80:	02079693          	slli	a3,a5,0x20
ffffffffc0200e84:	9281                	srli	a3,a3,0x20
ffffffffc0200e86:	00269613          	slli	a2,a3,0x2
    useable_page_num >>= 1;
ffffffffc0200e8a:	1706                	slli	a4,a4,0x21
    useable_page_base = base + buddy_page_num;
ffffffffc0200e8c:	9636                	add	a2,a2,a3
    useable_page_num >>= 1;
ffffffffc0200e8e:	9305                	srli	a4,a4,0x21
    useable_page_base = base + buddy_page_num;
ffffffffc0200e90:	060e                	slli	a2,a2,0x3
ffffffffc0200e92:	bdc9                	j	ffffffffc0200d64 <buddy_init_memmap+0x48>
    buddy_page = (unsigned int*)KADDR(page2pa(base));
ffffffffc0200e94:	00001617          	auipc	a2,0x1
ffffffffc0200e98:	13460613          	addi	a2,a2,308 # ffffffffc0201fc8 <commands+0x700>
ffffffffc0200e9c:	02c00593          	li	a1,44
ffffffffc0200ea0:	00001517          	auipc	a0,0x1
ffffffffc0200ea4:	f4050513          	addi	a0,a0,-192 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200ea8:	d04ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    assert((n > 0));
ffffffffc0200eac:	00001697          	auipc	a3,0x1
ffffffffc0200eb0:	11468693          	addi	a3,a3,276 # ffffffffc0201fc0 <commands+0x6f8>
ffffffffc0200eb4:	00001617          	auipc	a2,0x1
ffffffffc0200eb8:	f1460613          	addi	a2,a2,-236 # ffffffffc0201dc8 <commands+0x500>
ffffffffc0200ebc:	45dd                	li	a1,23
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	f2250513          	addi	a0,a0,-222 # ffffffffc0201de0 <commands+0x518>
ffffffffc0200ec6:	ce6ff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0200eca <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200eca:	100027f3          	csrr	a5,sstatus
ffffffffc0200ece:	8b89                	andi	a5,a5,2
ffffffffc0200ed0:	e799                	bnez	a5,ffffffffc0200ede <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200ed2:	00005797          	auipc	a5,0x5
ffffffffc0200ed6:	57e7b783          	ld	a5,1406(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200eda:	6f9c                	ld	a5,24(a5)
ffffffffc0200edc:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200ede:	1141                	addi	sp,sp,-16
ffffffffc0200ee0:	e406                	sd	ra,8(sp)
ffffffffc0200ee2:	e022                	sd	s0,0(sp)
ffffffffc0200ee4:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200ee6:	d78ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200eea:	00005797          	auipc	a5,0x5
ffffffffc0200eee:	5667b783          	ld	a5,1382(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200ef2:	6f9c                	ld	a5,24(a5)
ffffffffc0200ef4:	8522                	mv	a0,s0
ffffffffc0200ef6:	9782                	jalr	a5
ffffffffc0200ef8:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200efa:	d5eff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200efe:	60a2                	ld	ra,8(sp)
ffffffffc0200f00:	8522                	mv	a0,s0
ffffffffc0200f02:	6402                	ld	s0,0(sp)
ffffffffc0200f04:	0141                	addi	sp,sp,16
ffffffffc0200f06:	8082                	ret

ffffffffc0200f08 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f08:	100027f3          	csrr	a5,sstatus
ffffffffc0200f0c:	8b89                	andi	a5,a5,2
ffffffffc0200f0e:	e799                	bnez	a5,ffffffffc0200f1c <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200f10:	00005797          	auipc	a5,0x5
ffffffffc0200f14:	5407b783          	ld	a5,1344(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200f18:	739c                	ld	a5,32(a5)
ffffffffc0200f1a:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200f1c:	1101                	addi	sp,sp,-32
ffffffffc0200f1e:	ec06                	sd	ra,24(sp)
ffffffffc0200f20:	e822                	sd	s0,16(sp)
ffffffffc0200f22:	e426                	sd	s1,8(sp)
ffffffffc0200f24:	842a                	mv	s0,a0
ffffffffc0200f26:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200f28:	d36ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200f2c:	00005797          	auipc	a5,0x5
ffffffffc0200f30:	5247b783          	ld	a5,1316(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200f34:	739c                	ld	a5,32(a5)
ffffffffc0200f36:	85a6                	mv	a1,s1
ffffffffc0200f38:	8522                	mv	a0,s0
ffffffffc0200f3a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200f3c:	6442                	ld	s0,16(sp)
ffffffffc0200f3e:	60e2                	ld	ra,24(sp)
ffffffffc0200f40:	64a2                	ld	s1,8(sp)
ffffffffc0200f42:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200f44:	d14ff06f          	j	ffffffffc0200458 <intr_enable>

ffffffffc0200f48 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200f48:	100027f3          	csrr	a5,sstatus
ffffffffc0200f4c:	8b89                	andi	a5,a5,2
ffffffffc0200f4e:	e799                	bnez	a5,ffffffffc0200f5c <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f50:	00005797          	auipc	a5,0x5
ffffffffc0200f54:	5007b783          	ld	a5,1280(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200f58:	779c                	ld	a5,40(a5)
ffffffffc0200f5a:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200f5c:	1141                	addi	sp,sp,-16
ffffffffc0200f5e:	e406                	sd	ra,8(sp)
ffffffffc0200f60:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200f62:	cfcff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200f66:	00005797          	auipc	a5,0x5
ffffffffc0200f6a:	4ea7b783          	ld	a5,1258(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200f6e:	779c                	ld	a5,40(a5)
ffffffffc0200f70:	9782                	jalr	a5
ffffffffc0200f72:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200f74:	ce4ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200f78:	60a2                	ld	ra,8(sp)
ffffffffc0200f7a:	8522                	mv	a0,s0
ffffffffc0200f7c:	6402                	ld	s0,0(sp)
ffffffffc0200f7e:	0141                	addi	sp,sp,16
ffffffffc0200f80:	8082                	ret

ffffffffc0200f82 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200f82:	00001797          	auipc	a5,0x1
ffffffffc0200f86:	08678793          	addi	a5,a5,134 # ffffffffc0202008 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f8a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200f8c:	1101                	addi	sp,sp,-32
ffffffffc0200f8e:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200f90:	00001517          	auipc	a0,0x1
ffffffffc0200f94:	0b050513          	addi	a0,a0,176 # ffffffffc0202040 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200f98:	00005497          	auipc	s1,0x5
ffffffffc0200f9c:	4b848493          	addi	s1,s1,1208 # ffffffffc0206450 <pmm_manager>
void pmm_init(void) {
ffffffffc0200fa0:	ec06                	sd	ra,24(sp)
ffffffffc0200fa2:	e822                	sd	s0,16(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200fa4:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200fa6:	90cff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc0200faa:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fac:	00005417          	auipc	s0,0x5
ffffffffc0200fb0:	4bc40413          	addi	s0,s0,1212 # ffffffffc0206468 <va_pa_offset>
    pmm_manager->init();
ffffffffc0200fb4:	679c                	ld	a5,8(a5)
ffffffffc0200fb6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fb8:	57f5                	li	a5,-3
ffffffffc0200fba:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200fbc:	00001517          	auipc	a0,0x1
ffffffffc0200fc0:	09c50513          	addi	a0,a0,156 # ffffffffc0202058 <buddy_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200fc4:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0200fc6:	8ecff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200fca:	46c5                	li	a3,17
ffffffffc0200fcc:	06ee                	slli	a3,a3,0x1b
ffffffffc0200fce:	40100613          	li	a2,1025
ffffffffc0200fd2:	16fd                	addi	a3,a3,-1
ffffffffc0200fd4:	07e005b7          	lui	a1,0x7e00
ffffffffc0200fd8:	0656                	slli	a2,a2,0x15
ffffffffc0200fda:	00001517          	auipc	a0,0x1
ffffffffc0200fde:	09650513          	addi	a0,a0,150 # ffffffffc0202070 <buddy_pmm_manager+0x68>
ffffffffc0200fe2:	8d0ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200fe6:	777d                	lui	a4,0xfffff
ffffffffc0200fe8:	00006797          	auipc	a5,0x6
ffffffffc0200fec:	48f78793          	addi	a5,a5,1167 # ffffffffc0207477 <end+0xfff>
ffffffffc0200ff0:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0200ff2:	00005517          	auipc	a0,0x5
ffffffffc0200ff6:	44e50513          	addi	a0,a0,1102 # ffffffffc0206440 <npage>
ffffffffc0200ffa:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200ffe:	00005597          	auipc	a1,0x5
ffffffffc0201002:	44a58593          	addi	a1,a1,1098 # ffffffffc0206448 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201006:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201008:	e19c                	sd	a5,0(a1)
ffffffffc020100a:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020100c:	4701                	li	a4,0
ffffffffc020100e:	4885                	li	a7,1
ffffffffc0201010:	fff80837          	lui	a6,0xfff80
ffffffffc0201014:	a011                	j	ffffffffc0201018 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc0201016:	619c                	ld	a5,0(a1)
ffffffffc0201018:	97b6                	add	a5,a5,a3
ffffffffc020101a:	07a1                	addi	a5,a5,8
ffffffffc020101c:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201020:	611c                	ld	a5,0(a0)
ffffffffc0201022:	0705                	addi	a4,a4,1
ffffffffc0201024:	02868693          	addi	a3,a3,40
ffffffffc0201028:	01078633          	add	a2,a5,a6
ffffffffc020102c:	fec765e3          	bltu	a4,a2,ffffffffc0201016 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201030:	6190                	ld	a2,0(a1)
ffffffffc0201032:	00279713          	slli	a4,a5,0x2
ffffffffc0201036:	973e                	add	a4,a4,a5
ffffffffc0201038:	fec006b7          	lui	a3,0xfec00
ffffffffc020103c:	070e                	slli	a4,a4,0x3
ffffffffc020103e:	96b2                	add	a3,a3,a2
ffffffffc0201040:	96ba                	add	a3,a3,a4
ffffffffc0201042:	c0200737          	lui	a4,0xc0200
ffffffffc0201046:	08e6ef63          	bltu	a3,a4,ffffffffc02010e4 <pmm_init+0x162>
ffffffffc020104a:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc020104c:	45c5                	li	a1,17
ffffffffc020104e:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201050:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201052:	04b6e863          	bltu	a3,a1,ffffffffc02010a2 <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201056:	609c                	ld	a5,0(s1)
ffffffffc0201058:	7b9c                	ld	a5,48(a5)
ffffffffc020105a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020105c:	00001517          	auipc	a0,0x1
ffffffffc0201060:	0ac50513          	addi	a0,a0,172 # ffffffffc0202108 <buddy_pmm_manager+0x100>
ffffffffc0201064:	84eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201068:	00004597          	auipc	a1,0x4
ffffffffc020106c:	f9858593          	addi	a1,a1,-104 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201070:	00005797          	auipc	a5,0x5
ffffffffc0201074:	3eb7b823          	sd	a1,1008(a5) # ffffffffc0206460 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201078:	c02007b7          	lui	a5,0xc0200
ffffffffc020107c:	08f5e063          	bltu	a1,a5,ffffffffc02010fc <pmm_init+0x17a>
ffffffffc0201080:	6010                	ld	a2,0(s0)
}
ffffffffc0201082:	6442                	ld	s0,16(sp)
ffffffffc0201084:	60e2                	ld	ra,24(sp)
ffffffffc0201086:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201088:	40c58633          	sub	a2,a1,a2
ffffffffc020108c:	00005797          	auipc	a5,0x5
ffffffffc0201090:	3cc7b623          	sd	a2,972(a5) # ffffffffc0206458 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201094:	00001517          	auipc	a0,0x1
ffffffffc0201098:	09450513          	addi	a0,a0,148 # ffffffffc0202128 <buddy_pmm_manager+0x120>
}
ffffffffc020109c:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020109e:	814ff06f          	j	ffffffffc02000b2 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02010a2:	6705                	lui	a4,0x1
ffffffffc02010a4:	177d                	addi	a4,a4,-1
ffffffffc02010a6:	96ba                	add	a3,a3,a4
ffffffffc02010a8:	777d                	lui	a4,0xfffff
ffffffffc02010aa:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02010ac:	00c6d513          	srli	a0,a3,0xc
ffffffffc02010b0:	00f57e63          	bgeu	a0,a5,ffffffffc02010cc <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc02010b4:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02010b6:	982a                	add	a6,a6,a0
ffffffffc02010b8:	00281513          	slli	a0,a6,0x2
ffffffffc02010bc:	9542                	add	a0,a0,a6
ffffffffc02010be:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02010c0:	8d95                	sub	a1,a1,a3
ffffffffc02010c2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02010c4:	81b1                	srli	a1,a1,0xc
ffffffffc02010c6:	9532                	add	a0,a0,a2
ffffffffc02010c8:	9782                	jalr	a5
}
ffffffffc02010ca:	b771                	j	ffffffffc0201056 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc02010cc:	00001617          	auipc	a2,0x1
ffffffffc02010d0:	00c60613          	addi	a2,a2,12 # ffffffffc02020d8 <buddy_pmm_manager+0xd0>
ffffffffc02010d4:	06b00593          	li	a1,107
ffffffffc02010d8:	00001517          	auipc	a0,0x1
ffffffffc02010dc:	02050513          	addi	a0,a0,32 # ffffffffc02020f8 <buddy_pmm_manager+0xf0>
ffffffffc02010e0:	accff0ef          	jal	ra,ffffffffc02003ac <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02010e4:	00001617          	auipc	a2,0x1
ffffffffc02010e8:	fbc60613          	addi	a2,a2,-68 # ffffffffc02020a0 <buddy_pmm_manager+0x98>
ffffffffc02010ec:	06f00593          	li	a1,111
ffffffffc02010f0:	00001517          	auipc	a0,0x1
ffffffffc02010f4:	fd850513          	addi	a0,a0,-40 # ffffffffc02020c8 <buddy_pmm_manager+0xc0>
ffffffffc02010f8:	ab4ff0ef          	jal	ra,ffffffffc02003ac <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02010fc:	86ae                	mv	a3,a1
ffffffffc02010fe:	00001617          	auipc	a2,0x1
ffffffffc0201102:	fa260613          	addi	a2,a2,-94 # ffffffffc02020a0 <buddy_pmm_manager+0x98>
ffffffffc0201106:	08a00593          	li	a1,138
ffffffffc020110a:	00001517          	auipc	a0,0x1
ffffffffc020110e:	fbe50513          	addi	a0,a0,-66 # ffffffffc02020c8 <buddy_pmm_manager+0xc0>
ffffffffc0201112:	a9aff0ef          	jal	ra,ffffffffc02003ac <__panic>

ffffffffc0201116 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201116:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020111a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020111c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201120:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201122:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201126:	f022                	sd	s0,32(sp)
ffffffffc0201128:	ec26                	sd	s1,24(sp)
ffffffffc020112a:	e84a                	sd	s2,16(sp)
ffffffffc020112c:	f406                	sd	ra,40(sp)
ffffffffc020112e:	e44e                	sd	s3,8(sp)
ffffffffc0201130:	84aa                	mv	s1,a0
ffffffffc0201132:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201134:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201138:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020113a:	03067e63          	bgeu	a2,a6,ffffffffc0201176 <printnum+0x60>
ffffffffc020113e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201140:	00805763          	blez	s0,ffffffffc020114e <printnum+0x38>
ffffffffc0201144:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201146:	85ca                	mv	a1,s2
ffffffffc0201148:	854e                	mv	a0,s3
ffffffffc020114a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020114c:	fc65                	bnez	s0,ffffffffc0201144 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020114e:	1a02                	slli	s4,s4,0x20
ffffffffc0201150:	00001797          	auipc	a5,0x1
ffffffffc0201154:	01878793          	addi	a5,a5,24 # ffffffffc0202168 <buddy_pmm_manager+0x160>
ffffffffc0201158:	020a5a13          	srli	s4,s4,0x20
ffffffffc020115c:	9a3e                	add	s4,s4,a5
}
ffffffffc020115e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201160:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201164:	70a2                	ld	ra,40(sp)
ffffffffc0201166:	69a2                	ld	s3,8(sp)
ffffffffc0201168:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020116a:	85ca                	mv	a1,s2
ffffffffc020116c:	87a6                	mv	a5,s1
}
ffffffffc020116e:	6942                	ld	s2,16(sp)
ffffffffc0201170:	64e2                	ld	s1,24(sp)
ffffffffc0201172:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201174:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201176:	03065633          	divu	a2,a2,a6
ffffffffc020117a:	8722                	mv	a4,s0
ffffffffc020117c:	f9bff0ef          	jal	ra,ffffffffc0201116 <printnum>
ffffffffc0201180:	b7f9                	j	ffffffffc020114e <printnum+0x38>

ffffffffc0201182 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201182:	7119                	addi	sp,sp,-128
ffffffffc0201184:	f4a6                	sd	s1,104(sp)
ffffffffc0201186:	f0ca                	sd	s2,96(sp)
ffffffffc0201188:	ecce                	sd	s3,88(sp)
ffffffffc020118a:	e8d2                	sd	s4,80(sp)
ffffffffc020118c:	e4d6                	sd	s5,72(sp)
ffffffffc020118e:	e0da                	sd	s6,64(sp)
ffffffffc0201190:	fc5e                	sd	s7,56(sp)
ffffffffc0201192:	f06a                	sd	s10,32(sp)
ffffffffc0201194:	fc86                	sd	ra,120(sp)
ffffffffc0201196:	f8a2                	sd	s0,112(sp)
ffffffffc0201198:	f862                	sd	s8,48(sp)
ffffffffc020119a:	f466                	sd	s9,40(sp)
ffffffffc020119c:	ec6e                	sd	s11,24(sp)
ffffffffc020119e:	892a                	mv	s2,a0
ffffffffc02011a0:	84ae                	mv	s1,a1
ffffffffc02011a2:	8d32                	mv	s10,a2
ffffffffc02011a4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011a6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02011aa:	5b7d                	li	s6,-1
ffffffffc02011ac:	00001a97          	auipc	s5,0x1
ffffffffc02011b0:	ff0a8a93          	addi	s5,s5,-16 # ffffffffc020219c <buddy_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02011b4:	00001b97          	auipc	s7,0x1
ffffffffc02011b8:	1c4b8b93          	addi	s7,s7,452 # ffffffffc0202378 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011bc:	000d4503          	lbu	a0,0(s10)
ffffffffc02011c0:	001d0413          	addi	s0,s10,1
ffffffffc02011c4:	01350a63          	beq	a0,s3,ffffffffc02011d8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02011c8:	c121                	beqz	a0,ffffffffc0201208 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02011ca:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011cc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02011ce:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02011d0:	fff44503          	lbu	a0,-1(s0)
ffffffffc02011d4:	ff351ae3          	bne	a0,s3,ffffffffc02011c8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011d8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02011dc:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02011e0:	4c81                	li	s9,0
ffffffffc02011e2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02011e4:	5c7d                	li	s8,-1
ffffffffc02011e6:	5dfd                	li	s11,-1
ffffffffc02011e8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02011ec:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02011ee:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02011f2:	0ff5f593          	andi	a1,a1,255
ffffffffc02011f6:	00140d13          	addi	s10,s0,1
ffffffffc02011fa:	04b56263          	bltu	a0,a1,ffffffffc020123e <vprintfmt+0xbc>
ffffffffc02011fe:	058a                	slli	a1,a1,0x2
ffffffffc0201200:	95d6                	add	a1,a1,s5
ffffffffc0201202:	4194                	lw	a3,0(a1)
ffffffffc0201204:	96d6                	add	a3,a3,s5
ffffffffc0201206:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201208:	70e6                	ld	ra,120(sp)
ffffffffc020120a:	7446                	ld	s0,112(sp)
ffffffffc020120c:	74a6                	ld	s1,104(sp)
ffffffffc020120e:	7906                	ld	s2,96(sp)
ffffffffc0201210:	69e6                	ld	s3,88(sp)
ffffffffc0201212:	6a46                	ld	s4,80(sp)
ffffffffc0201214:	6aa6                	ld	s5,72(sp)
ffffffffc0201216:	6b06                	ld	s6,64(sp)
ffffffffc0201218:	7be2                	ld	s7,56(sp)
ffffffffc020121a:	7c42                	ld	s8,48(sp)
ffffffffc020121c:	7ca2                	ld	s9,40(sp)
ffffffffc020121e:	7d02                	ld	s10,32(sp)
ffffffffc0201220:	6de2                	ld	s11,24(sp)
ffffffffc0201222:	6109                	addi	sp,sp,128
ffffffffc0201224:	8082                	ret
            padc = '0';
ffffffffc0201226:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201228:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020122c:	846a                	mv	s0,s10
ffffffffc020122e:	00140d13          	addi	s10,s0,1
ffffffffc0201232:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201236:	0ff5f593          	andi	a1,a1,255
ffffffffc020123a:	fcb572e3          	bgeu	a0,a1,ffffffffc02011fe <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020123e:	85a6                	mv	a1,s1
ffffffffc0201240:	02500513          	li	a0,37
ffffffffc0201244:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201246:	fff44783          	lbu	a5,-1(s0)
ffffffffc020124a:	8d22                	mv	s10,s0
ffffffffc020124c:	f73788e3          	beq	a5,s3,ffffffffc02011bc <vprintfmt+0x3a>
ffffffffc0201250:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201254:	1d7d                	addi	s10,s10,-1
ffffffffc0201256:	ff379de3          	bne	a5,s3,ffffffffc0201250 <vprintfmt+0xce>
ffffffffc020125a:	b78d                	j	ffffffffc02011bc <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020125c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201260:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201264:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201266:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020126a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020126e:	02d86463          	bltu	a6,a3,ffffffffc0201296 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201272:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201276:	002c169b          	slliw	a3,s8,0x2
ffffffffc020127a:	0186873b          	addw	a4,a3,s8
ffffffffc020127e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201282:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201284:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201288:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020128a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020128e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201292:	fed870e3          	bgeu	a6,a3,ffffffffc0201272 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201296:	f40ddce3          	bgez	s11,ffffffffc02011ee <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020129a:	8de2                	mv	s11,s8
ffffffffc020129c:	5c7d                	li	s8,-1
ffffffffc020129e:	bf81                	j	ffffffffc02011ee <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02012a0:	fffdc693          	not	a3,s11
ffffffffc02012a4:	96fd                	srai	a3,a3,0x3f
ffffffffc02012a6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012aa:	00144603          	lbu	a2,1(s0)
ffffffffc02012ae:	2d81                	sext.w	s11,s11
ffffffffc02012b0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02012b2:	bf35                	j	ffffffffc02011ee <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02012b4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012b8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02012bc:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012be:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02012c0:	bfd9                	j	ffffffffc0201296 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02012c2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012c4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012c8:	01174463          	blt	a4,a7,ffffffffc02012d0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02012cc:	1a088e63          	beqz	a7,ffffffffc0201488 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02012d0:	000a3603          	ld	a2,0(s4)
ffffffffc02012d4:	46c1                	li	a3,16
ffffffffc02012d6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02012d8:	2781                	sext.w	a5,a5
ffffffffc02012da:	876e                	mv	a4,s11
ffffffffc02012dc:	85a6                	mv	a1,s1
ffffffffc02012de:	854a                	mv	a0,s2
ffffffffc02012e0:	e37ff0ef          	jal	ra,ffffffffc0201116 <printnum>
            break;
ffffffffc02012e4:	bde1                	j	ffffffffc02011bc <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02012e6:	000a2503          	lw	a0,0(s4)
ffffffffc02012ea:	85a6                	mv	a1,s1
ffffffffc02012ec:	0a21                	addi	s4,s4,8
ffffffffc02012ee:	9902                	jalr	s2
            break;
ffffffffc02012f0:	b5f1                	j	ffffffffc02011bc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02012f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02012f4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02012f8:	01174463          	blt	a4,a7,ffffffffc0201300 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02012fc:	18088163          	beqz	a7,ffffffffc020147e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201300:	000a3603          	ld	a2,0(s4)
ffffffffc0201304:	46a9                	li	a3,10
ffffffffc0201306:	8a2e                	mv	s4,a1
ffffffffc0201308:	bfc1                	j	ffffffffc02012d8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020130a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc020130e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201310:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201312:	bdf1                	j	ffffffffc02011ee <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201314:	85a6                	mv	a1,s1
ffffffffc0201316:	02500513          	li	a0,37
ffffffffc020131a:	9902                	jalr	s2
            break;
ffffffffc020131c:	b545                	j	ffffffffc02011bc <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020131e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201322:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201324:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201326:	b5e1                	j	ffffffffc02011ee <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201328:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020132a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020132e:	01174463          	blt	a4,a7,ffffffffc0201336 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201332:	14088163          	beqz	a7,ffffffffc0201474 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201336:	000a3603          	ld	a2,0(s4)
ffffffffc020133a:	46a1                	li	a3,8
ffffffffc020133c:	8a2e                	mv	s4,a1
ffffffffc020133e:	bf69                	j	ffffffffc02012d8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201340:	03000513          	li	a0,48
ffffffffc0201344:	85a6                	mv	a1,s1
ffffffffc0201346:	e03e                	sd	a5,0(sp)
ffffffffc0201348:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020134a:	85a6                	mv	a1,s1
ffffffffc020134c:	07800513          	li	a0,120
ffffffffc0201350:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201352:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201354:	6782                	ld	a5,0(sp)
ffffffffc0201356:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201358:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020135c:	bfb5                	j	ffffffffc02012d8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020135e:	000a3403          	ld	s0,0(s4)
ffffffffc0201362:	008a0713          	addi	a4,s4,8
ffffffffc0201366:	e03a                	sd	a4,0(sp)
ffffffffc0201368:	14040263          	beqz	s0,ffffffffc02014ac <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020136c:	0fb05763          	blez	s11,ffffffffc020145a <vprintfmt+0x2d8>
ffffffffc0201370:	02d00693          	li	a3,45
ffffffffc0201374:	0cd79163          	bne	a5,a3,ffffffffc0201436 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201378:	00044783          	lbu	a5,0(s0)
ffffffffc020137c:	0007851b          	sext.w	a0,a5
ffffffffc0201380:	cf85                	beqz	a5,ffffffffc02013b8 <vprintfmt+0x236>
ffffffffc0201382:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201386:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020138a:	000c4563          	bltz	s8,ffffffffc0201394 <vprintfmt+0x212>
ffffffffc020138e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201390:	036c0263          	beq	s8,s6,ffffffffc02013b4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201394:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201396:	0e0c8e63          	beqz	s9,ffffffffc0201492 <vprintfmt+0x310>
ffffffffc020139a:	3781                	addiw	a5,a5,-32
ffffffffc020139c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201492 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02013a0:	03f00513          	li	a0,63
ffffffffc02013a4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02013a6:	000a4783          	lbu	a5,0(s4)
ffffffffc02013aa:	3dfd                	addiw	s11,s11,-1
ffffffffc02013ac:	0a05                	addi	s4,s4,1
ffffffffc02013ae:	0007851b          	sext.w	a0,a5
ffffffffc02013b2:	ffe1                	bnez	a5,ffffffffc020138a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02013b4:	01b05963          	blez	s11,ffffffffc02013c6 <vprintfmt+0x244>
ffffffffc02013b8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02013ba:	85a6                	mv	a1,s1
ffffffffc02013bc:	02000513          	li	a0,32
ffffffffc02013c0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02013c2:	fe0d9be3          	bnez	s11,ffffffffc02013b8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02013c6:	6a02                	ld	s4,0(sp)
ffffffffc02013c8:	bbd5                	j	ffffffffc02011bc <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013ca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013cc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02013d0:	01174463          	blt	a4,a7,ffffffffc02013d8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02013d4:	08088d63          	beqz	a7,ffffffffc020146e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02013d8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02013dc:	0a044d63          	bltz	s0,ffffffffc0201496 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02013e0:	8622                	mv	a2,s0
ffffffffc02013e2:	8a66                	mv	s4,s9
ffffffffc02013e4:	46a9                	li	a3,10
ffffffffc02013e6:	bdcd                	j	ffffffffc02012d8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02013e8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013ec:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02013ee:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02013f0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02013f4:	8fb5                	xor	a5,a5,a3
ffffffffc02013f6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013fa:	02d74163          	blt	a4,a3,ffffffffc020141c <vprintfmt+0x29a>
ffffffffc02013fe:	00369793          	slli	a5,a3,0x3
ffffffffc0201402:	97de                	add	a5,a5,s7
ffffffffc0201404:	639c                	ld	a5,0(a5)
ffffffffc0201406:	cb99                	beqz	a5,ffffffffc020141c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201408:	86be                	mv	a3,a5
ffffffffc020140a:	00001617          	auipc	a2,0x1
ffffffffc020140e:	d8e60613          	addi	a2,a2,-626 # ffffffffc0202198 <buddy_pmm_manager+0x190>
ffffffffc0201412:	85a6                	mv	a1,s1
ffffffffc0201414:	854a                	mv	a0,s2
ffffffffc0201416:	0ce000ef          	jal	ra,ffffffffc02014e4 <printfmt>
ffffffffc020141a:	b34d                	j	ffffffffc02011bc <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc020141c:	00001617          	auipc	a2,0x1
ffffffffc0201420:	d6c60613          	addi	a2,a2,-660 # ffffffffc0202188 <buddy_pmm_manager+0x180>
ffffffffc0201424:	85a6                	mv	a1,s1
ffffffffc0201426:	854a                	mv	a0,s2
ffffffffc0201428:	0bc000ef          	jal	ra,ffffffffc02014e4 <printfmt>
ffffffffc020142c:	bb41                	j	ffffffffc02011bc <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020142e:	00001417          	auipc	s0,0x1
ffffffffc0201432:	d5240413          	addi	s0,s0,-686 # ffffffffc0202180 <buddy_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201436:	85e2                	mv	a1,s8
ffffffffc0201438:	8522                	mv	a0,s0
ffffffffc020143a:	e43e                	sd	a5,8(sp)
ffffffffc020143c:	1cc000ef          	jal	ra,ffffffffc0201608 <strnlen>
ffffffffc0201440:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201444:	01b05b63          	blez	s11,ffffffffc020145a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201448:	67a2                	ld	a5,8(sp)
ffffffffc020144a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020144e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201450:	85a6                	mv	a1,s1
ffffffffc0201452:	8552                	mv	a0,s4
ffffffffc0201454:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201456:	fe0d9ce3          	bnez	s11,ffffffffc020144e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020145a:	00044783          	lbu	a5,0(s0)
ffffffffc020145e:	00140a13          	addi	s4,s0,1
ffffffffc0201462:	0007851b          	sext.w	a0,a5
ffffffffc0201466:	d3a5                	beqz	a5,ffffffffc02013c6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201468:	05e00413          	li	s0,94
ffffffffc020146c:	bf39                	j	ffffffffc020138a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020146e:	000a2403          	lw	s0,0(s4)
ffffffffc0201472:	b7ad                	j	ffffffffc02013dc <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201474:	000a6603          	lwu	a2,0(s4)
ffffffffc0201478:	46a1                	li	a3,8
ffffffffc020147a:	8a2e                	mv	s4,a1
ffffffffc020147c:	bdb1                	j	ffffffffc02012d8 <vprintfmt+0x156>
ffffffffc020147e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201482:	46a9                	li	a3,10
ffffffffc0201484:	8a2e                	mv	s4,a1
ffffffffc0201486:	bd89                	j	ffffffffc02012d8 <vprintfmt+0x156>
ffffffffc0201488:	000a6603          	lwu	a2,0(s4)
ffffffffc020148c:	46c1                	li	a3,16
ffffffffc020148e:	8a2e                	mv	s4,a1
ffffffffc0201490:	b5a1                	j	ffffffffc02012d8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201492:	9902                	jalr	s2
ffffffffc0201494:	bf09                	j	ffffffffc02013a6 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201496:	85a6                	mv	a1,s1
ffffffffc0201498:	02d00513          	li	a0,45
ffffffffc020149c:	e03e                	sd	a5,0(sp)
ffffffffc020149e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02014a0:	6782                	ld	a5,0(sp)
ffffffffc02014a2:	8a66                	mv	s4,s9
ffffffffc02014a4:	40800633          	neg	a2,s0
ffffffffc02014a8:	46a9                	li	a3,10
ffffffffc02014aa:	b53d                	j	ffffffffc02012d8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02014ac:	03b05163          	blez	s11,ffffffffc02014ce <vprintfmt+0x34c>
ffffffffc02014b0:	02d00693          	li	a3,45
ffffffffc02014b4:	f6d79de3          	bne	a5,a3,ffffffffc020142e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02014b8:	00001417          	auipc	s0,0x1
ffffffffc02014bc:	cc840413          	addi	s0,s0,-824 # ffffffffc0202180 <buddy_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02014c0:	02800793          	li	a5,40
ffffffffc02014c4:	02800513          	li	a0,40
ffffffffc02014c8:	00140a13          	addi	s4,s0,1
ffffffffc02014cc:	bd6d                	j	ffffffffc0201386 <vprintfmt+0x204>
ffffffffc02014ce:	00001a17          	auipc	s4,0x1
ffffffffc02014d2:	cb3a0a13          	addi	s4,s4,-845 # ffffffffc0202181 <buddy_pmm_manager+0x179>
ffffffffc02014d6:	02800513          	li	a0,40
ffffffffc02014da:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02014de:	05e00413          	li	s0,94
ffffffffc02014e2:	b565                	j	ffffffffc020138a <vprintfmt+0x208>

ffffffffc02014e4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014e4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02014e6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014ea:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02014ec:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02014ee:	ec06                	sd	ra,24(sp)
ffffffffc02014f0:	f83a                	sd	a4,48(sp)
ffffffffc02014f2:	fc3e                	sd	a5,56(sp)
ffffffffc02014f4:	e0c2                	sd	a6,64(sp)
ffffffffc02014f6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02014f8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02014fa:	c89ff0ef          	jal	ra,ffffffffc0201182 <vprintfmt>
}
ffffffffc02014fe:	60e2                	ld	ra,24(sp)
ffffffffc0201500:	6161                	addi	sp,sp,80
ffffffffc0201502:	8082                	ret

ffffffffc0201504 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201504:	715d                	addi	sp,sp,-80
ffffffffc0201506:	e486                	sd	ra,72(sp)
ffffffffc0201508:	e0a6                	sd	s1,64(sp)
ffffffffc020150a:	fc4a                	sd	s2,56(sp)
ffffffffc020150c:	f84e                	sd	s3,48(sp)
ffffffffc020150e:	f452                	sd	s4,40(sp)
ffffffffc0201510:	f056                	sd	s5,32(sp)
ffffffffc0201512:	ec5a                	sd	s6,24(sp)
ffffffffc0201514:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201516:	c901                	beqz	a0,ffffffffc0201526 <readline+0x22>
ffffffffc0201518:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020151a:	00001517          	auipc	a0,0x1
ffffffffc020151e:	c7e50513          	addi	a0,a0,-898 # ffffffffc0202198 <buddy_pmm_manager+0x190>
ffffffffc0201522:	b91fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc0201526:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201528:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020152a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020152c:	4aa9                	li	s5,10
ffffffffc020152e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201530:	00005b97          	auipc	s7,0x5
ffffffffc0201534:	ae0b8b93          	addi	s7,s7,-1312 # ffffffffc0206010 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201538:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020153c:	beffe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201540:	00054a63          	bltz	a0,ffffffffc0201554 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201544:	00a95a63          	bge	s2,a0,ffffffffc0201558 <readline+0x54>
ffffffffc0201548:	029a5263          	bge	s4,s1,ffffffffc020156c <readline+0x68>
        c = getchar();
ffffffffc020154c:	bdffe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201550:	fe055ae3          	bgez	a0,ffffffffc0201544 <readline+0x40>
            return NULL;
ffffffffc0201554:	4501                	li	a0,0
ffffffffc0201556:	a091                	j	ffffffffc020159a <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201558:	03351463          	bne	a0,s3,ffffffffc0201580 <readline+0x7c>
ffffffffc020155c:	e8a9                	bnez	s1,ffffffffc02015ae <readline+0xaa>
        c = getchar();
ffffffffc020155e:	bcdfe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201562:	fe0549e3          	bltz	a0,ffffffffc0201554 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201566:	fea959e3          	bge	s2,a0,ffffffffc0201558 <readline+0x54>
ffffffffc020156a:	4481                	li	s1,0
            cputchar(c);
ffffffffc020156c:	e42a                	sd	a0,8(sp)
ffffffffc020156e:	b7bfe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc0201572:	6522                	ld	a0,8(sp)
ffffffffc0201574:	009b87b3          	add	a5,s7,s1
ffffffffc0201578:	2485                	addiw	s1,s1,1
ffffffffc020157a:	00a78023          	sb	a0,0(a5)
ffffffffc020157e:	bf7d                	j	ffffffffc020153c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201580:	01550463          	beq	a0,s5,ffffffffc0201588 <readline+0x84>
ffffffffc0201584:	fb651ce3          	bne	a0,s6,ffffffffc020153c <readline+0x38>
            cputchar(c);
ffffffffc0201588:	b61fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	a8450513          	addi	a0,a0,-1404 # ffffffffc0206010 <buf>
ffffffffc0201594:	94aa                	add	s1,s1,a0
ffffffffc0201596:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020159a:	60a6                	ld	ra,72(sp)
ffffffffc020159c:	6486                	ld	s1,64(sp)
ffffffffc020159e:	7962                	ld	s2,56(sp)
ffffffffc02015a0:	79c2                	ld	s3,48(sp)
ffffffffc02015a2:	7a22                	ld	s4,40(sp)
ffffffffc02015a4:	7a82                	ld	s5,32(sp)
ffffffffc02015a6:	6b62                	ld	s6,24(sp)
ffffffffc02015a8:	6bc2                	ld	s7,16(sp)
ffffffffc02015aa:	6161                	addi	sp,sp,80
ffffffffc02015ac:	8082                	ret
            cputchar(c);
ffffffffc02015ae:	4521                	li	a0,8
ffffffffc02015b0:	b39fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02015b4:	34fd                	addiw	s1,s1,-1
ffffffffc02015b6:	b759                	j	ffffffffc020153c <readline+0x38>

ffffffffc02015b8 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015b8:	4781                	li	a5,0
ffffffffc02015ba:	00005717          	auipc	a4,0x5
ffffffffc02015be:	a4e73703          	ld	a4,-1458(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015c2:	88ba                	mv	a7,a4
ffffffffc02015c4:	852a                	mv	a0,a0
ffffffffc02015c6:	85be                	mv	a1,a5
ffffffffc02015c8:	863e                	mv	a2,a5
ffffffffc02015ca:	00000073          	ecall
ffffffffc02015ce:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015d0:	8082                	ret

ffffffffc02015d2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02015d2:	4781                	li	a5,0
ffffffffc02015d4:	00005717          	auipc	a4,0x5
ffffffffc02015d8:	e9c73703          	ld	a4,-356(a4) # ffffffffc0206470 <SBI_SET_TIMER>
ffffffffc02015dc:	88ba                	mv	a7,a4
ffffffffc02015de:	852a                	mv	a0,a0
ffffffffc02015e0:	85be                	mv	a1,a5
ffffffffc02015e2:	863e                	mv	a2,a5
ffffffffc02015e4:	00000073          	ecall
ffffffffc02015e8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02015ea:	8082                	ret

ffffffffc02015ec <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02015ec:	4501                	li	a0,0
ffffffffc02015ee:	00005797          	auipc	a5,0x5
ffffffffc02015f2:	a127b783          	ld	a5,-1518(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc02015f6:	88be                	mv	a7,a5
ffffffffc02015f8:	852a                	mv	a0,a0
ffffffffc02015fa:	85aa                	mv	a1,a0
ffffffffc02015fc:	862a                	mv	a2,a0
ffffffffc02015fe:	00000073          	ecall
ffffffffc0201602:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201604:	2501                	sext.w	a0,a0
ffffffffc0201606:	8082                	ret

ffffffffc0201608 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201608:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020160a:	e589                	bnez	a1,ffffffffc0201614 <strnlen+0xc>
ffffffffc020160c:	a811                	j	ffffffffc0201620 <strnlen+0x18>
        cnt ++;
ffffffffc020160e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201610:	00f58863          	beq	a1,a5,ffffffffc0201620 <strnlen+0x18>
ffffffffc0201614:	00f50733          	add	a4,a0,a5
ffffffffc0201618:	00074703          	lbu	a4,0(a4)
ffffffffc020161c:	fb6d                	bnez	a4,ffffffffc020160e <strnlen+0x6>
ffffffffc020161e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201620:	852e                	mv	a0,a1
ffffffffc0201622:	8082                	ret

ffffffffc0201624 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201624:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201628:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020162c:	cb89                	beqz	a5,ffffffffc020163e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020162e:	0505                	addi	a0,a0,1
ffffffffc0201630:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201632:	fee789e3          	beq	a5,a4,ffffffffc0201624 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201636:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020163a:	9d19                	subw	a0,a0,a4
ffffffffc020163c:	8082                	ret
ffffffffc020163e:	4501                	li	a0,0
ffffffffc0201640:	bfed                	j	ffffffffc020163a <strcmp+0x16>

ffffffffc0201642 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201642:	00054783          	lbu	a5,0(a0)
ffffffffc0201646:	c799                	beqz	a5,ffffffffc0201654 <strchr+0x12>
        if (*s == c) {
ffffffffc0201648:	00f58763          	beq	a1,a5,ffffffffc0201656 <strchr+0x14>
    while (*s != '\0') {
ffffffffc020164c:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201650:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201652:	fbfd                	bnez	a5,ffffffffc0201648 <strchr+0x6>
    }
    return NULL;
ffffffffc0201654:	4501                	li	a0,0
}
ffffffffc0201656:	8082                	ret

ffffffffc0201658 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201658:	ca01                	beqz	a2,ffffffffc0201668 <memset+0x10>
ffffffffc020165a:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020165c:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020165e:	0785                	addi	a5,a5,1
ffffffffc0201660:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201664:	fec79de3          	bne	a5,a2,ffffffffc020165e <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201668:	8082                	ret
