
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080200000 <kern_entry>:
#include <memlayout.h>

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    la sp, bootstacktop
    80200000:	00004117          	auipc	sp,0x4
    80200004:	00010113          	mv	sp,sp

    tail kern_init
    80200008:	a009                	j	8020000a <kern_init>

000000008020000a <kern_init>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    8020000a:	00004517          	auipc	a0,0x4
    8020000e:	00650513          	addi	a0,a0,6 # 80204010 <ticks>
    80200012:	00004617          	auipc	a2,0x4
    80200016:	01660613          	addi	a2,a2,22 # 80204028 <end>
int kern_init(void) {
    8020001a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    8020001c:	8e09                	sub	a2,a2,a0
    8020001e:	4581                	li	a1,0
int kern_init(void) {
    80200020:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
    80200022:	1c1000ef          	jal	ra,802009e2 <memset>

    cons_init();  // init the console
    80200026:	150000ef          	jal	ra,80200176 <cons_init>

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);
    8020002a:	00001597          	auipc	a1,0x1
    8020002e:	9ce58593          	addi	a1,a1,-1586 # 802009f8 <etext+0x4>
    80200032:	00001517          	auipc	a0,0x1
    80200036:	9e650513          	addi	a0,a0,-1562 # 80200a18 <etext+0x24>
    8020003a:	036000ef          	jal	ra,80200070 <cprintf>

    print_kerninfo();
    8020003e:	068000ef          	jal	ra,802000a6 <print_kerninfo>

    // grade_backtrace();

    idt_init();  // init interrupt descriptor table
    80200042:	144000ef          	jal	ra,80200186 <idt_init>

    // rdtime in mbare mode crashes
    clock_init();  // init clock interrupt
    80200046:	0ee000ef          	jal	ra,80200134 <clock_init>

    intr_enable();  // enable irq interrupt
    8020004a:	136000ef          	jal	ra,80200180 <intr_enable>
    
    __asm__ __volatile__("mret"); // 
    8020004e:	30200073          	mret
    __asm__ __volatile__("ebreak"); // 断点异常
    80200052:	9002                	ebreak
    while (1)
    80200054:	a001                	j	80200054 <kern_init+0x4a>

0000000080200056 <cputch>:

/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void cputch(int c, int *cnt) {
    80200056:	1141                	addi	sp,sp,-16
    80200058:	e022                	sd	s0,0(sp)
    8020005a:	e406                	sd	ra,8(sp)
    8020005c:	842e                	mv	s0,a1
    cons_putc(c);
    8020005e:	11a000ef          	jal	ra,80200178 <cons_putc>
    (*cnt)++;
    80200062:	401c                	lw	a5,0(s0)
}
    80200064:	60a2                	ld	ra,8(sp)
    (*cnt)++;
    80200066:	2785                	addiw	a5,a5,1
    80200068:	c01c                	sw	a5,0(s0)
}
    8020006a:	6402                	ld	s0,0(sp)
    8020006c:	0141                	addi	sp,sp,16
    8020006e:	8082                	ret

0000000080200070 <cprintf>:
 * cprintf - formats a string and writes it to stdout
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...) {
    80200070:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
    80200072:	02810313          	addi	t1,sp,40 # 80204028 <end>
int cprintf(const char *fmt, ...) {
    80200076:	8e2a                	mv	t3,a0
    80200078:	f42e                	sd	a1,40(sp)
    8020007a:	f832                	sd	a2,48(sp)
    8020007c:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020007e:	00000517          	auipc	a0,0x0
    80200082:	fd850513          	addi	a0,a0,-40 # 80200056 <cputch>
    80200086:	004c                	addi	a1,sp,4
    80200088:	869a                	mv	a3,t1
    8020008a:	8672                	mv	a2,t3
int cprintf(const char *fmt, ...) {
    8020008c:	ec06                	sd	ra,24(sp)
    8020008e:	e0ba                	sd	a4,64(sp)
    80200090:	e4be                	sd	a5,72(sp)
    80200092:	e8c2                	sd	a6,80(sp)
    80200094:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
    80200096:	e41a                	sd	t1,8(sp)
    int cnt = 0;
    80200098:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    8020009a:	55c000ef          	jal	ra,802005f6 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
    8020009e:	60e2                	ld	ra,24(sp)
    802000a0:	4512                	lw	a0,4(sp)
    802000a2:	6125                	addi	sp,sp,96
    802000a4:	8082                	ret

00000000802000a6 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
    802000a6:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
    802000a8:	00001517          	auipc	a0,0x1
    802000ac:	97850513          	addi	a0,a0,-1672 # 80200a20 <etext+0x2c>
void print_kerninfo(void) {
    802000b0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
    802000b2:	fbfff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  entry  0x%016x (virtual)\n", kern_init);
    802000b6:	00000597          	auipc	a1,0x0
    802000ba:	f5458593          	addi	a1,a1,-172 # 8020000a <kern_init>
    802000be:	00001517          	auipc	a0,0x1
    802000c2:	98250513          	addi	a0,a0,-1662 # 80200a40 <etext+0x4c>
    802000c6:	fabff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  etext  0x%016x (virtual)\n", etext);
    802000ca:	00001597          	auipc	a1,0x1
    802000ce:	92a58593          	addi	a1,a1,-1750 # 802009f4 <etext>
    802000d2:	00001517          	auipc	a0,0x1
    802000d6:	98e50513          	addi	a0,a0,-1650 # 80200a60 <etext+0x6c>
    802000da:	f97ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  edata  0x%016x (virtual)\n", edata);
    802000de:	00004597          	auipc	a1,0x4
    802000e2:	f3258593          	addi	a1,a1,-206 # 80204010 <ticks>
    802000e6:	00001517          	auipc	a0,0x1
    802000ea:	99a50513          	addi	a0,a0,-1638 # 80200a80 <etext+0x8c>
    802000ee:	f83ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  end    0x%016x (virtual)\n", end);
    802000f2:	00004597          	auipc	a1,0x4
    802000f6:	f3658593          	addi	a1,a1,-202 # 80204028 <end>
    802000fa:	00001517          	auipc	a0,0x1
    802000fe:	9a650513          	addi	a0,a0,-1626 # 80200aa0 <etext+0xac>
    80200102:	f6fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
    80200106:	00004597          	auipc	a1,0x4
    8020010a:	32158593          	addi	a1,a1,801 # 80204427 <end+0x3ff>
    8020010e:	00000797          	auipc	a5,0x0
    80200112:	efc78793          	addi	a5,a5,-260 # 8020000a <kern_init>
    80200116:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
    8020011a:	43f7d593          	srai	a1,a5,0x3f
}
    8020011e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200120:	3ff5f593          	andi	a1,a1,1023
    80200124:	95be                	add	a1,a1,a5
    80200126:	85a9                	srai	a1,a1,0xa
    80200128:	00001517          	auipc	a0,0x1
    8020012c:	99850513          	addi	a0,a0,-1640 # 80200ac0 <etext+0xcc>
}
    80200130:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
    80200132:	bf3d                	j	80200070 <cprintf>

0000000080200134 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    80200134:	1141                	addi	sp,sp,-16
    80200136:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
    80200138:	02000793          	li	a5,32
    8020013c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200140:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    80200144:	67e1                	lui	a5,0x18
    80200146:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    8020014a:	953e                	add	a0,a0,a5
    8020014c:	047000ef          	jal	ra,80200992 <sbi_set_timer>
}
    80200150:	60a2                	ld	ra,8(sp)
    ticks = 0;
    80200152:	00004797          	auipc	a5,0x4
    80200156:	ea07bf23          	sd	zero,-322(a5) # 80204010 <ticks>
    cprintf("++ setup timer interrupts\n");
    8020015a:	00001517          	auipc	a0,0x1
    8020015e:	99650513          	addi	a0,a0,-1642 # 80200af0 <etext+0xfc>
}
    80200162:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
    80200164:	b731                	j	80200070 <cprintf>

0000000080200166 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    80200166:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
    8020016a:	67e1                	lui	a5,0x18
    8020016c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0x801e7960>
    80200170:	953e                	add	a0,a0,a5
    80200172:	0210006f          	j	80200992 <sbi_set_timer>

0000000080200176 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
    80200176:	8082                	ret

0000000080200178 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
    80200178:	0ff57513          	zext.b	a0,a0
    8020017c:	7fc0006f          	j	80200978 <sbi_console_putchar>

0000000080200180 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
    80200180:	100167f3          	csrrsi	a5,sstatus,2
    80200184:	8082                	ret

0000000080200186 <idt_init>:
 */
void idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
    80200186:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
    8020018a:	00000797          	auipc	a5,0x0
    8020018e:	34a78793          	addi	a5,a5,842 # 802004d4 <__alltraps>
    80200192:	10579073          	csrw	stvec,a5
}
    80200196:	8082                	ret

0000000080200198 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
    80200198:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
    8020019a:	1141                	addi	sp,sp,-16
    8020019c:	e022                	sd	s0,0(sp)
    8020019e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001a0:	00001517          	auipc	a0,0x1
    802001a4:	97050513          	addi	a0,a0,-1680 # 80200b10 <etext+0x11c>
void print_regs(struct pushregs *gpr) {
    802001a8:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
    802001aa:	ec7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
    802001ae:	640c                	ld	a1,8(s0)
    802001b0:	00001517          	auipc	a0,0x1
    802001b4:	97850513          	addi	a0,a0,-1672 # 80200b28 <etext+0x134>
    802001b8:	eb9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
    802001bc:	680c                	ld	a1,16(s0)
    802001be:	00001517          	auipc	a0,0x1
    802001c2:	98250513          	addi	a0,a0,-1662 # 80200b40 <etext+0x14c>
    802001c6:	eabff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
    802001ca:	6c0c                	ld	a1,24(s0)
    802001cc:	00001517          	auipc	a0,0x1
    802001d0:	98c50513          	addi	a0,a0,-1652 # 80200b58 <etext+0x164>
    802001d4:	e9dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
    802001d8:	700c                	ld	a1,32(s0)
    802001da:	00001517          	auipc	a0,0x1
    802001de:	99650513          	addi	a0,a0,-1642 # 80200b70 <etext+0x17c>
    802001e2:	e8fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
    802001e6:	740c                	ld	a1,40(s0)
    802001e8:	00001517          	auipc	a0,0x1
    802001ec:	9a050513          	addi	a0,a0,-1632 # 80200b88 <etext+0x194>
    802001f0:	e81ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
    802001f4:	780c                	ld	a1,48(s0)
    802001f6:	00001517          	auipc	a0,0x1
    802001fa:	9aa50513          	addi	a0,a0,-1622 # 80200ba0 <etext+0x1ac>
    802001fe:	e73ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
    80200202:	7c0c                	ld	a1,56(s0)
    80200204:	00001517          	auipc	a0,0x1
    80200208:	9b450513          	addi	a0,a0,-1612 # 80200bb8 <etext+0x1c4>
    8020020c:	e65ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
    80200210:	602c                	ld	a1,64(s0)
    80200212:	00001517          	auipc	a0,0x1
    80200216:	9be50513          	addi	a0,a0,-1602 # 80200bd0 <etext+0x1dc>
    8020021a:	e57ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
    8020021e:	642c                	ld	a1,72(s0)
    80200220:	00001517          	auipc	a0,0x1
    80200224:	9c850513          	addi	a0,a0,-1592 # 80200be8 <etext+0x1f4>
    80200228:	e49ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
    8020022c:	682c                	ld	a1,80(s0)
    8020022e:	00001517          	auipc	a0,0x1
    80200232:	9d250513          	addi	a0,a0,-1582 # 80200c00 <etext+0x20c>
    80200236:	e3bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
    8020023a:	6c2c                	ld	a1,88(s0)
    8020023c:	00001517          	auipc	a0,0x1
    80200240:	9dc50513          	addi	a0,a0,-1572 # 80200c18 <etext+0x224>
    80200244:	e2dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
    80200248:	702c                	ld	a1,96(s0)
    8020024a:	00001517          	auipc	a0,0x1
    8020024e:	9e650513          	addi	a0,a0,-1562 # 80200c30 <etext+0x23c>
    80200252:	e1fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
    80200256:	742c                	ld	a1,104(s0)
    80200258:	00001517          	auipc	a0,0x1
    8020025c:	9f050513          	addi	a0,a0,-1552 # 80200c48 <etext+0x254>
    80200260:	e11ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
    80200264:	782c                	ld	a1,112(s0)
    80200266:	00001517          	auipc	a0,0x1
    8020026a:	9fa50513          	addi	a0,a0,-1542 # 80200c60 <etext+0x26c>
    8020026e:	e03ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
    80200272:	7c2c                	ld	a1,120(s0)
    80200274:	00001517          	auipc	a0,0x1
    80200278:	a0450513          	addi	a0,a0,-1532 # 80200c78 <etext+0x284>
    8020027c:	df5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
    80200280:	604c                	ld	a1,128(s0)
    80200282:	00001517          	auipc	a0,0x1
    80200286:	a0e50513          	addi	a0,a0,-1522 # 80200c90 <etext+0x29c>
    8020028a:	de7ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
    8020028e:	644c                	ld	a1,136(s0)
    80200290:	00001517          	auipc	a0,0x1
    80200294:	a1850513          	addi	a0,a0,-1512 # 80200ca8 <etext+0x2b4>
    80200298:	dd9ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
    8020029c:	684c                	ld	a1,144(s0)
    8020029e:	00001517          	auipc	a0,0x1
    802002a2:	a2250513          	addi	a0,a0,-1502 # 80200cc0 <etext+0x2cc>
    802002a6:	dcbff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
    802002aa:	6c4c                	ld	a1,152(s0)
    802002ac:	00001517          	auipc	a0,0x1
    802002b0:	a2c50513          	addi	a0,a0,-1492 # 80200cd8 <etext+0x2e4>
    802002b4:	dbdff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
    802002b8:	704c                	ld	a1,160(s0)
    802002ba:	00001517          	auipc	a0,0x1
    802002be:	a3650513          	addi	a0,a0,-1482 # 80200cf0 <etext+0x2fc>
    802002c2:	dafff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
    802002c6:	744c                	ld	a1,168(s0)
    802002c8:	00001517          	auipc	a0,0x1
    802002cc:	a4050513          	addi	a0,a0,-1472 # 80200d08 <etext+0x314>
    802002d0:	da1ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
    802002d4:	784c                	ld	a1,176(s0)
    802002d6:	00001517          	auipc	a0,0x1
    802002da:	a4a50513          	addi	a0,a0,-1462 # 80200d20 <etext+0x32c>
    802002de:	d93ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
    802002e2:	7c4c                	ld	a1,184(s0)
    802002e4:	00001517          	auipc	a0,0x1
    802002e8:	a5450513          	addi	a0,a0,-1452 # 80200d38 <etext+0x344>
    802002ec:	d85ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
    802002f0:	606c                	ld	a1,192(s0)
    802002f2:	00001517          	auipc	a0,0x1
    802002f6:	a5e50513          	addi	a0,a0,-1442 # 80200d50 <etext+0x35c>
    802002fa:	d77ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
    802002fe:	646c                	ld	a1,200(s0)
    80200300:	00001517          	auipc	a0,0x1
    80200304:	a6850513          	addi	a0,a0,-1432 # 80200d68 <etext+0x374>
    80200308:	d69ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
    8020030c:	686c                	ld	a1,208(s0)
    8020030e:	00001517          	auipc	a0,0x1
    80200312:	a7250513          	addi	a0,a0,-1422 # 80200d80 <etext+0x38c>
    80200316:	d5bff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
    8020031a:	6c6c                	ld	a1,216(s0)
    8020031c:	00001517          	auipc	a0,0x1
    80200320:	a7c50513          	addi	a0,a0,-1412 # 80200d98 <etext+0x3a4>
    80200324:	d4dff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
    80200328:	706c                	ld	a1,224(s0)
    8020032a:	00001517          	auipc	a0,0x1
    8020032e:	a8650513          	addi	a0,a0,-1402 # 80200db0 <etext+0x3bc>
    80200332:	d3fff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
    80200336:	746c                	ld	a1,232(s0)
    80200338:	00001517          	auipc	a0,0x1
    8020033c:	a9050513          	addi	a0,a0,-1392 # 80200dc8 <etext+0x3d4>
    80200340:	d31ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
    80200344:	786c                	ld	a1,240(s0)
    80200346:	00001517          	auipc	a0,0x1
    8020034a:	a9a50513          	addi	a0,a0,-1382 # 80200de0 <etext+0x3ec>
    8020034e:	d23ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200352:	7c6c                	ld	a1,248(s0)
}
    80200354:	6402                	ld	s0,0(sp)
    80200356:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200358:	00001517          	auipc	a0,0x1
    8020035c:	aa050513          	addi	a0,a0,-1376 # 80200df8 <etext+0x404>
}
    80200360:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
    80200362:	b339                	j	80200070 <cprintf>

0000000080200364 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
    80200364:	1141                	addi	sp,sp,-16
    80200366:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
    80200368:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
    8020036a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
    8020036c:	00001517          	auipc	a0,0x1
    80200370:	aa450513          	addi	a0,a0,-1372 # 80200e10 <etext+0x41c>
void print_trapframe(struct trapframe *tf) {
    80200374:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
    80200376:	cfbff0ef          	jal	ra,80200070 <cprintf>
    print_regs(&tf->gpr);
    8020037a:	8522                	mv	a0,s0
    8020037c:	e1dff0ef          	jal	ra,80200198 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
    80200380:	10043583          	ld	a1,256(s0)
    80200384:	00001517          	auipc	a0,0x1
    80200388:	aa450513          	addi	a0,a0,-1372 # 80200e28 <etext+0x434>
    8020038c:	ce5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
    80200390:	10843583          	ld	a1,264(s0)
    80200394:	00001517          	auipc	a0,0x1
    80200398:	aac50513          	addi	a0,a0,-1364 # 80200e40 <etext+0x44c>
    8020039c:	cd5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    802003a0:	11043583          	ld	a1,272(s0)
    802003a4:	00001517          	auipc	a0,0x1
    802003a8:	ab450513          	addi	a0,a0,-1356 # 80200e58 <etext+0x464>
    802003ac:	cc5ff0ef          	jal	ra,80200070 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b0:	11843583          	ld	a1,280(s0)
}
    802003b4:	6402                	ld	s0,0(sp)
    802003b6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
    802003b8:	00001517          	auipc	a0,0x1
    802003bc:	ab850513          	addi	a0,a0,-1352 # 80200e70 <etext+0x47c>
}
    802003c0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
    802003c2:	b17d                	j	80200070 <cprintf>

00000000802003c4 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    802003c4:	11853783          	ld	a5,280(a0)
    802003c8:	472d                	li	a4,11
    802003ca:	0786                	slli	a5,a5,0x1
    802003cc:	8385                	srli	a5,a5,0x1
    802003ce:	08f76263          	bltu	a4,a5,80200452 <interrupt_handler+0x8e>
    802003d2:	00001717          	auipc	a4,0x1
    802003d6:	b6670713          	addi	a4,a4,-1178 # 80200f38 <etext+0x544>
    802003da:	078a                	slli	a5,a5,0x2
    802003dc:	97ba                	add	a5,a5,a4
    802003de:	439c                	lw	a5,0(a5)
    802003e0:	97ba                	add	a5,a5,a4
    802003e2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
    802003e4:	00001517          	auipc	a0,0x1
    802003e8:	b0450513          	addi	a0,a0,-1276 # 80200ee8 <etext+0x4f4>
    802003ec:	b151                	j	80200070 <cprintf>
            cprintf("Hypervisor software interrupt\n");
    802003ee:	00001517          	auipc	a0,0x1
    802003f2:	ada50513          	addi	a0,a0,-1318 # 80200ec8 <etext+0x4d4>
    802003f6:	b9ad                	j	80200070 <cprintf>
            cprintf("User software interrupt\n");
    802003f8:	00001517          	auipc	a0,0x1
    802003fc:	a9050513          	addi	a0,a0,-1392 # 80200e88 <etext+0x494>
    80200400:	b985                	j	80200070 <cprintf>
            cprintf("Supervisor software interrupt\n");
    80200402:	00001517          	auipc	a0,0x1
    80200406:	aa650513          	addi	a0,a0,-1370 # 80200ea8 <etext+0x4b4>
    8020040a:	b19d                	j	80200070 <cprintf>
void interrupt_handler(struct trapframe *tf) {
    8020040c:	1141                	addi	sp,sp,-16
    8020040e:	e022                	sd	s0,0(sp)
    80200410:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
	    clock_set_next_event();
    80200412:	d55ff0ef          	jal	ra,80200166 <clock_set_next_event>
	    ticks++;
    80200416:	00004797          	auipc	a5,0x4
    8020041a:	bfa78793          	addi	a5,a5,-1030 # 80204010 <ticks>
    8020041e:	6398                	ld	a4,0(a5)
    80200420:	00004417          	auipc	s0,0x4
    80200424:	bf840413          	addi	s0,s0,-1032 # 80204018 <num>
    80200428:	0705                	addi	a4,a4,1
    8020042a:	e398                	sd	a4,0(a5)
	    if(ticks%TICK_NUM==0)
    8020042c:	639c                	ld	a5,0(a5)
    8020042e:	06400713          	li	a4,100
    80200432:	02e7f7b3          	remu	a5,a5,a4
    80200436:	cf99                	beqz	a5,80200454 <interrupt_handler+0x90>
	    {
		    print_ticks();
		    num++;
	    }
	    if(num==10)
    80200438:	6018                	ld	a4,0(s0)
    8020043a:	47a9                	li	a5,10
    8020043c:	02f70863          	beq	a4,a5,8020046c <interrupt_handler+0xa8>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    80200440:	60a2                	ld	ra,8(sp)
    80200442:	6402                	ld	s0,0(sp)
    80200444:	0141                	addi	sp,sp,16
    80200446:	8082                	ret
            cprintf("Supervisor external interrupt\n");
    80200448:	00001517          	auipc	a0,0x1
    8020044c:	ad050513          	addi	a0,a0,-1328 # 80200f18 <etext+0x524>
    80200450:	b105                	j	80200070 <cprintf>
            print_trapframe(tf);
    80200452:	bf09                	j	80200364 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
    80200454:	06400593          	li	a1,100
    80200458:	00001517          	auipc	a0,0x1
    8020045c:	ab050513          	addi	a0,a0,-1360 # 80200f08 <etext+0x514>
    80200460:	c11ff0ef          	jal	ra,80200070 <cprintf>
		    num++;
    80200464:	601c                	ld	a5,0(s0)
    80200466:	0785                	addi	a5,a5,1
    80200468:	e01c                	sd	a5,0(s0)
    8020046a:	b7f9                	j	80200438 <interrupt_handler+0x74>
}
    8020046c:	6402                	ld	s0,0(sp)
    8020046e:	60a2                	ld	ra,8(sp)
    80200470:	0141                	addi	sp,sp,16
		    sbi_shutdown();
    80200472:	ab2d                	j	802009ac <sbi_shutdown>

0000000080200474 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
    80200474:	11853783          	ld	a5,280(a0)
    80200478:	470d                	li	a4,3
    8020047a:	04f76063          	bltu	a4,a5,802004ba <exception_handler+0x46>
    8020047e:	4705                	li	a4,1
    80200480:	04f77363          	bgeu	a4,a5,802004c6 <exception_handler+0x52>
void exception_handler(struct trapframe *tf) {
    80200484:	1141                	addi	sp,sp,-16
    80200486:	e022                	sd	s0,0(sp)
    80200488:	842a                	mv	s0,a0
             /* LAB1 CHALLENGE3   YOUR CODE :  */
            /*(1)输出指令异常类型（ Illegal instruction）
             *(2)输出异常指令地址
             *(3)更新 tf->epc寄存器
            */
	    cprintf("Exception type:Illegal instruction\n");
    8020048a:	00001517          	auipc	a0,0x1
    8020048e:	ade50513          	addi	a0,a0,-1314 # 80200f68 <etext+0x574>
void exception_handler(struct trapframe *tf) {
    80200492:	e406                	sd	ra,8(sp)
	    cprintf("Exception type:Illegal instruction\n");
    80200494:	bddff0ef          	jal	ra,80200070 <cprintf>
            cprintf("Illegal instruction caught at %p\n", tf->epc);
    80200498:	10843583          	ld	a1,264(s0)
    8020049c:	00001517          	auipc	a0,0x1
    802004a0:	af450513          	addi	a0,a0,-1292 # 80200f90 <etext+0x59c>
    802004a4:	bcdff0ef          	jal	ra,80200070 <cprintf>
            tf->epc += 4;
    802004a8:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
    802004ac:	60a2                	ld	ra,8(sp)
            tf->epc += 4;
    802004ae:	0791                	addi	a5,a5,4
    802004b0:	10f43423          	sd	a5,264(s0)
}
    802004b4:	6402                	ld	s0,0(sp)
    802004b6:	0141                	addi	sp,sp,16
    802004b8:	8082                	ret
    switch (tf->cause) {
    802004ba:	17f1                	addi	a5,a5,-4
    802004bc:	471d                	li	a4,7
    802004be:	00f77363          	bgeu	a4,a5,802004c4 <exception_handler+0x50>
            print_trapframe(tf);
    802004c2:	b54d                	j	80200364 <print_trapframe>
    802004c4:	8082                	ret
    802004c6:	8082                	ret

00000000802004c8 <trap>:

/* trap_dispatch - dispatch based on what type of trap occurred */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
    802004c8:	11853783          	ld	a5,280(a0)
    802004cc:	0007c363          	bltz	a5,802004d2 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
    802004d0:	b755                	j	80200474 <exception_handler>
        interrupt_handler(tf);
    802004d2:	bdcd                	j	802003c4 <interrupt_handler>

00000000802004d4 <__alltraps>:
    .endm

    .globl __alltraps
.align(2)
__alltraps:
    SAVE_ALL
    802004d4:	14011073          	csrw	sscratch,sp
    802004d8:	712d                	addi	sp,sp,-288
    802004da:	e002                	sd	zero,0(sp)
    802004dc:	e406                	sd	ra,8(sp)
    802004de:	ec0e                	sd	gp,24(sp)
    802004e0:	f012                	sd	tp,32(sp)
    802004e2:	f416                	sd	t0,40(sp)
    802004e4:	f81a                	sd	t1,48(sp)
    802004e6:	fc1e                	sd	t2,56(sp)
    802004e8:	e0a2                	sd	s0,64(sp)
    802004ea:	e4a6                	sd	s1,72(sp)
    802004ec:	e8aa                	sd	a0,80(sp)
    802004ee:	ecae                	sd	a1,88(sp)
    802004f0:	f0b2                	sd	a2,96(sp)
    802004f2:	f4b6                	sd	a3,104(sp)
    802004f4:	f8ba                	sd	a4,112(sp)
    802004f6:	fcbe                	sd	a5,120(sp)
    802004f8:	e142                	sd	a6,128(sp)
    802004fa:	e546                	sd	a7,136(sp)
    802004fc:	e94a                	sd	s2,144(sp)
    802004fe:	ed4e                	sd	s3,152(sp)
    80200500:	f152                	sd	s4,160(sp)
    80200502:	f556                	sd	s5,168(sp)
    80200504:	f95a                	sd	s6,176(sp)
    80200506:	fd5e                	sd	s7,184(sp)
    80200508:	e1e2                	sd	s8,192(sp)
    8020050a:	e5e6                	sd	s9,200(sp)
    8020050c:	e9ea                	sd	s10,208(sp)
    8020050e:	edee                	sd	s11,216(sp)
    80200510:	f1f2                	sd	t3,224(sp)
    80200512:	f5f6                	sd	t4,232(sp)
    80200514:	f9fa                	sd	t5,240(sp)
    80200516:	fdfe                	sd	t6,248(sp)
    80200518:	14001473          	csrrw	s0,sscratch,zero
    8020051c:	100024f3          	csrr	s1,sstatus
    80200520:	14102973          	csrr	s2,sepc
    80200524:	143029f3          	csrr	s3,stval
    80200528:	14202a73          	csrr	s4,scause
    8020052c:	e822                	sd	s0,16(sp)
    8020052e:	e226                	sd	s1,256(sp)
    80200530:	e64a                	sd	s2,264(sp)
    80200532:	ea4e                	sd	s3,272(sp)
    80200534:	ee52                	sd	s4,280(sp)

    move  a0, sp
    80200536:	850a                	mv	a0,sp
    jal trap
    80200538:	f91ff0ef          	jal	ra,802004c8 <trap>

000000008020053c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
    8020053c:	6492                	ld	s1,256(sp)
    8020053e:	6932                	ld	s2,264(sp)
    80200540:	10049073          	csrw	sstatus,s1
    80200544:	14191073          	csrw	sepc,s2
    80200548:	60a2                	ld	ra,8(sp)
    8020054a:	61e2                	ld	gp,24(sp)
    8020054c:	7202                	ld	tp,32(sp)
    8020054e:	72a2                	ld	t0,40(sp)
    80200550:	7342                	ld	t1,48(sp)
    80200552:	73e2                	ld	t2,56(sp)
    80200554:	6406                	ld	s0,64(sp)
    80200556:	64a6                	ld	s1,72(sp)
    80200558:	6546                	ld	a0,80(sp)
    8020055a:	65e6                	ld	a1,88(sp)
    8020055c:	7606                	ld	a2,96(sp)
    8020055e:	76a6                	ld	a3,104(sp)
    80200560:	7746                	ld	a4,112(sp)
    80200562:	77e6                	ld	a5,120(sp)
    80200564:	680a                	ld	a6,128(sp)
    80200566:	68aa                	ld	a7,136(sp)
    80200568:	694a                	ld	s2,144(sp)
    8020056a:	69ea                	ld	s3,152(sp)
    8020056c:	7a0a                	ld	s4,160(sp)
    8020056e:	7aaa                	ld	s5,168(sp)
    80200570:	7b4a                	ld	s6,176(sp)
    80200572:	7bea                	ld	s7,184(sp)
    80200574:	6c0e                	ld	s8,192(sp)
    80200576:	6cae                	ld	s9,200(sp)
    80200578:	6d4e                	ld	s10,208(sp)
    8020057a:	6dee                	ld	s11,216(sp)
    8020057c:	7e0e                	ld	t3,224(sp)
    8020057e:	7eae                	ld	t4,232(sp)
    80200580:	7f4e                	ld	t5,240(sp)
    80200582:	7fee                	ld	t6,248(sp)
    80200584:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
    80200586:	10200073          	sret

000000008020058a <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
    8020058a:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    8020058e:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
    80200590:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
    80200594:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
    80200596:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
    8020059a:	f022                	sd	s0,32(sp)
    8020059c:	ec26                	sd	s1,24(sp)
    8020059e:	e84a                	sd	s2,16(sp)
    802005a0:	f406                	sd	ra,40(sp)
    802005a2:	e44e                	sd	s3,8(sp)
    802005a4:	84aa                	mv	s1,a0
    802005a6:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
    802005a8:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
    802005ac:	2a01                	sext.w	s4,s4
    if (num >= base) {
    802005ae:	03067e63          	bgeu	a2,a6,802005ea <printnum+0x60>
    802005b2:	89be                	mv	s3,a5
        while (-- width > 0)
    802005b4:	00805763          	blez	s0,802005c2 <printnum+0x38>
    802005b8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
    802005ba:	85ca                	mv	a1,s2
    802005bc:	854e                	mv	a0,s3
    802005be:	9482                	jalr	s1
        while (-- width > 0)
    802005c0:	fc65                	bnez	s0,802005b8 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
    802005c2:	1a02                	slli	s4,s4,0x20
    802005c4:	00001797          	auipc	a5,0x1
    802005c8:	9f478793          	addi	a5,a5,-1548 # 80200fb8 <etext+0x5c4>
    802005cc:	020a5a13          	srli	s4,s4,0x20
    802005d0:	9a3e                	add	s4,s4,a5
}
    802005d2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
    802005d4:	000a4503          	lbu	a0,0(s4)
}
    802005d8:	70a2                	ld	ra,40(sp)
    802005da:	69a2                	ld	s3,8(sp)
    802005dc:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
    802005de:	85ca                	mv	a1,s2
    802005e0:	87a6                	mv	a5,s1
}
    802005e2:	6942                	ld	s2,16(sp)
    802005e4:	64e2                	ld	s1,24(sp)
    802005e6:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
    802005e8:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
    802005ea:	03065633          	divu	a2,a2,a6
    802005ee:	8722                	mv	a4,s0
    802005f0:	f9bff0ef          	jal	ra,8020058a <printnum>
    802005f4:	b7f9                	j	802005c2 <printnum+0x38>

00000000802005f6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
    802005f6:	7119                	addi	sp,sp,-128
    802005f8:	f4a6                	sd	s1,104(sp)
    802005fa:	f0ca                	sd	s2,96(sp)
    802005fc:	ecce                	sd	s3,88(sp)
    802005fe:	e8d2                	sd	s4,80(sp)
    80200600:	e4d6                	sd	s5,72(sp)
    80200602:	e0da                	sd	s6,64(sp)
    80200604:	fc5e                	sd	s7,56(sp)
    80200606:	f06a                	sd	s10,32(sp)
    80200608:	fc86                	sd	ra,120(sp)
    8020060a:	f8a2                	sd	s0,112(sp)
    8020060c:	f862                	sd	s8,48(sp)
    8020060e:	f466                	sd	s9,40(sp)
    80200610:	ec6e                	sd	s11,24(sp)
    80200612:	892a                	mv	s2,a0
    80200614:	84ae                	mv	s1,a1
    80200616:	8d32                	mv	s10,a2
    80200618:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    8020061a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
    8020061e:	5b7d                	li	s6,-1
    80200620:	00001a97          	auipc	s5,0x1
    80200624:	9cca8a93          	addi	s5,s5,-1588 # 80200fec <etext+0x5f8>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200628:	00001b97          	auipc	s7,0x1
    8020062c:	ba0b8b93          	addi	s7,s7,-1120 # 802011c8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200630:	000d4503          	lbu	a0,0(s10)
    80200634:	001d0413          	addi	s0,s10,1
    80200638:	01350a63          	beq	a0,s3,8020064c <vprintfmt+0x56>
            if (ch == '\0') {
    8020063c:	c121                	beqz	a0,8020067c <vprintfmt+0x86>
            putch(ch, putdat);
    8020063e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200640:	0405                	addi	s0,s0,1
            putch(ch, putdat);
    80200642:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
    80200644:	fff44503          	lbu	a0,-1(s0)
    80200648:	ff351ae3          	bne	a0,s3,8020063c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
    8020064c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
    80200650:	02000793          	li	a5,32
        lflag = altflag = 0;
    80200654:	4c81                	li	s9,0
    80200656:	4881                	li	a7,0
        width = precision = -1;
    80200658:	5c7d                	li	s8,-1
    8020065a:	5dfd                	li	s11,-1
    8020065c:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
    80200660:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
    80200662:	fdd6059b          	addiw	a1,a2,-35
    80200666:	0ff5f593          	zext.b	a1,a1
    8020066a:	00140d13          	addi	s10,s0,1
    8020066e:	04b56263          	bltu	a0,a1,802006b2 <vprintfmt+0xbc>
    80200672:	058a                	slli	a1,a1,0x2
    80200674:	95d6                	add	a1,a1,s5
    80200676:	4194                	lw	a3,0(a1)
    80200678:	96d6                	add	a3,a3,s5
    8020067a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
    8020067c:	70e6                	ld	ra,120(sp)
    8020067e:	7446                	ld	s0,112(sp)
    80200680:	74a6                	ld	s1,104(sp)
    80200682:	7906                	ld	s2,96(sp)
    80200684:	69e6                	ld	s3,88(sp)
    80200686:	6a46                	ld	s4,80(sp)
    80200688:	6aa6                	ld	s5,72(sp)
    8020068a:	6b06                	ld	s6,64(sp)
    8020068c:	7be2                	ld	s7,56(sp)
    8020068e:	7c42                	ld	s8,48(sp)
    80200690:	7ca2                	ld	s9,40(sp)
    80200692:	7d02                	ld	s10,32(sp)
    80200694:	6de2                	ld	s11,24(sp)
    80200696:	6109                	addi	sp,sp,128
    80200698:	8082                	ret
            padc = '0';
    8020069a:	87b2                	mv	a5,a2
            goto reswitch;
    8020069c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802006a0:	846a                	mv	s0,s10
    802006a2:	00140d13          	addi	s10,s0,1
    802006a6:	fdd6059b          	addiw	a1,a2,-35
    802006aa:	0ff5f593          	zext.b	a1,a1
    802006ae:	fcb572e3          	bgeu	a0,a1,80200672 <vprintfmt+0x7c>
            putch('%', putdat);
    802006b2:	85a6                	mv	a1,s1
    802006b4:	02500513          	li	a0,37
    802006b8:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
    802006ba:	fff44783          	lbu	a5,-1(s0)
    802006be:	8d22                	mv	s10,s0
    802006c0:	f73788e3          	beq	a5,s3,80200630 <vprintfmt+0x3a>
    802006c4:	ffed4783          	lbu	a5,-2(s10)
    802006c8:	1d7d                	addi	s10,s10,-1
    802006ca:	ff379de3          	bne	a5,s3,802006c4 <vprintfmt+0xce>
    802006ce:	b78d                	j	80200630 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
    802006d0:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
    802006d4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
    802006d8:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
    802006da:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
    802006de:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    802006e2:	02d86463          	bltu	a6,a3,8020070a <vprintfmt+0x114>
                ch = *fmt;
    802006e6:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
    802006ea:	002c169b          	slliw	a3,s8,0x2
    802006ee:	0186873b          	addw	a4,a3,s8
    802006f2:	0017171b          	slliw	a4,a4,0x1
    802006f6:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
    802006f8:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
    802006fc:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
    802006fe:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
    80200702:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
    80200706:	fed870e3          	bgeu	a6,a3,802006e6 <vprintfmt+0xf0>
            if (width < 0)
    8020070a:	f40ddce3          	bgez	s11,80200662 <vprintfmt+0x6c>
                width = precision, precision = -1;
    8020070e:	8de2                	mv	s11,s8
    80200710:	5c7d                	li	s8,-1
    80200712:	bf81                	j	80200662 <vprintfmt+0x6c>
            if (width < 0)
    80200714:	fffdc693          	not	a3,s11
    80200718:	96fd                	srai	a3,a3,0x3f
    8020071a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
    8020071e:	00144603          	lbu	a2,1(s0)
    80200722:	2d81                	sext.w	s11,s11
    80200724:	846a                	mv	s0,s10
            goto reswitch;
    80200726:	bf35                	j	80200662 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
    80200728:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
    8020072c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
    80200730:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
    80200732:	846a                	mv	s0,s10
            goto process_precision;
    80200734:	bfd9                	j	8020070a <vprintfmt+0x114>
    if (lflag >= 2) {
    80200736:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200738:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    8020073c:	01174463          	blt	a4,a7,80200744 <vprintfmt+0x14e>
    else if (lflag) {
    80200740:	1a088e63          	beqz	a7,802008fc <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
    80200744:	000a3603          	ld	a2,0(s4)
    80200748:	46c1                	li	a3,16
    8020074a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
    8020074c:	2781                	sext.w	a5,a5
    8020074e:	876e                	mv	a4,s11
    80200750:	85a6                	mv	a1,s1
    80200752:	854a                	mv	a0,s2
    80200754:	e37ff0ef          	jal	ra,8020058a <printnum>
            break;
    80200758:	bde1                	j	80200630 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
    8020075a:	000a2503          	lw	a0,0(s4)
    8020075e:	85a6                	mv	a1,s1
    80200760:	0a21                	addi	s4,s4,8
    80200762:	9902                	jalr	s2
            break;
    80200764:	b5f1                	j	80200630 <vprintfmt+0x3a>
    if (lflag >= 2) {
    80200766:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200768:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    8020076c:	01174463          	blt	a4,a7,80200774 <vprintfmt+0x17e>
    else if (lflag) {
    80200770:	18088163          	beqz	a7,802008f2 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
    80200774:	000a3603          	ld	a2,0(s4)
    80200778:	46a9                	li	a3,10
    8020077a:	8a2e                	mv	s4,a1
    8020077c:	bfc1                	j	8020074c <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
    8020077e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
    80200782:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200784:	846a                	mv	s0,s10
            goto reswitch;
    80200786:	bdf1                	j	80200662 <vprintfmt+0x6c>
            putch(ch, putdat);
    80200788:	85a6                	mv	a1,s1
    8020078a:	02500513          	li	a0,37
    8020078e:	9902                	jalr	s2
            break;
    80200790:	b545                	j	80200630 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
    80200792:	00144603          	lbu	a2,1(s0)
            lflag ++;
    80200796:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
    80200798:	846a                	mv	s0,s10
            goto reswitch;
    8020079a:	b5e1                	j	80200662 <vprintfmt+0x6c>
    if (lflag >= 2) {
    8020079c:	4705                	li	a4,1
            precision = va_arg(ap, int);
    8020079e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
    802007a2:	01174463          	blt	a4,a7,802007aa <vprintfmt+0x1b4>
    else if (lflag) {
    802007a6:	14088163          	beqz	a7,802008e8 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
    802007aa:	000a3603          	ld	a2,0(s4)
    802007ae:	46a1                	li	a3,8
    802007b0:	8a2e                	mv	s4,a1
    802007b2:	bf69                	j	8020074c <vprintfmt+0x156>
            putch('0', putdat);
    802007b4:	03000513          	li	a0,48
    802007b8:	85a6                	mv	a1,s1
    802007ba:	e03e                	sd	a5,0(sp)
    802007bc:	9902                	jalr	s2
            putch('x', putdat);
    802007be:	85a6                	mv	a1,s1
    802007c0:	07800513          	li	a0,120
    802007c4:	9902                	jalr	s2
            num = (unsigned long long)va_arg(ap, void *);
    802007c6:	0a21                	addi	s4,s4,8
            goto number;
    802007c8:	6782                	ld	a5,0(sp)
    802007ca:	46c1                	li	a3,16
            num = (unsigned long long)va_arg(ap, void *);
    802007cc:	ff8a3603          	ld	a2,-8(s4)
            goto number;
    802007d0:	bfb5                	j	8020074c <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
    802007d2:	000a3403          	ld	s0,0(s4)
    802007d6:	008a0713          	addi	a4,s4,8
    802007da:	e03a                	sd	a4,0(sp)
    802007dc:	14040263          	beqz	s0,80200920 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
    802007e0:	0fb05763          	blez	s11,802008ce <vprintfmt+0x2d8>
    802007e4:	02d00693          	li	a3,45
    802007e8:	0cd79163          	bne	a5,a3,802008aa <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007ec:	00044783          	lbu	a5,0(s0)
    802007f0:	0007851b          	sext.w	a0,a5
    802007f4:	cf85                	beqz	a5,8020082c <vprintfmt+0x236>
    802007f6:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
    802007fa:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802007fe:	000c4563          	bltz	s8,80200808 <vprintfmt+0x212>
    80200802:	3c7d                	addiw	s8,s8,-1
    80200804:	036c0263          	beq	s8,s6,80200828 <vprintfmt+0x232>
                    putch('?', putdat);
    80200808:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
    8020080a:	0e0c8e63          	beqz	s9,80200906 <vprintfmt+0x310>
    8020080e:	3781                	addiw	a5,a5,-32
    80200810:	0ef47b63          	bgeu	s0,a5,80200906 <vprintfmt+0x310>
                    putch('?', putdat);
    80200814:	03f00513          	li	a0,63
    80200818:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    8020081a:	000a4783          	lbu	a5,0(s4)
    8020081e:	3dfd                	addiw	s11,s11,-1
    80200820:	0a05                	addi	s4,s4,1
    80200822:	0007851b          	sext.w	a0,a5
    80200826:	ffe1                	bnez	a5,802007fe <vprintfmt+0x208>
            for (; width > 0; width --) {
    80200828:	01b05963          	blez	s11,8020083a <vprintfmt+0x244>
    8020082c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
    8020082e:	85a6                	mv	a1,s1
    80200830:	02000513          	li	a0,32
    80200834:	9902                	jalr	s2
            for (; width > 0; width --) {
    80200836:	fe0d9be3          	bnez	s11,8020082c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
    8020083a:	6a02                	ld	s4,0(sp)
    8020083c:	bbd5                	j	80200630 <vprintfmt+0x3a>
    if (lflag >= 2) {
    8020083e:	4705                	li	a4,1
            precision = va_arg(ap, int);
    80200840:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
    80200844:	01174463          	blt	a4,a7,8020084c <vprintfmt+0x256>
    else if (lflag) {
    80200848:	08088d63          	beqz	a7,802008e2 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
    8020084c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
    80200850:	0a044d63          	bltz	s0,8020090a <vprintfmt+0x314>
            num = getint(&ap, lflag);
    80200854:	8622                	mv	a2,s0
    80200856:	8a66                	mv	s4,s9
    80200858:	46a9                	li	a3,10
    8020085a:	bdcd                	j	8020074c <vprintfmt+0x156>
            err = va_arg(ap, int);
    8020085c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    80200860:	4719                	li	a4,6
            err = va_arg(ap, int);
    80200862:	0a21                	addi	s4,s4,8
            if (err < 0) {
    80200864:	41f7d69b          	sraiw	a3,a5,0x1f
    80200868:	8fb5                	xor	a5,a5,a3
    8020086a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
    8020086e:	02d74163          	blt	a4,a3,80200890 <vprintfmt+0x29a>
    80200872:	00369793          	slli	a5,a3,0x3
    80200876:	97de                	add	a5,a5,s7
    80200878:	639c                	ld	a5,0(a5)
    8020087a:	cb99                	beqz	a5,80200890 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
    8020087c:	86be                	mv	a3,a5
    8020087e:	00000617          	auipc	a2,0x0
    80200882:	76a60613          	addi	a2,a2,1898 # 80200fe8 <etext+0x5f4>
    80200886:	85a6                	mv	a1,s1
    80200888:	854a                	mv	a0,s2
    8020088a:	0ce000ef          	jal	ra,80200958 <printfmt>
    8020088e:	b34d                	j	80200630 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
    80200890:	00000617          	auipc	a2,0x0
    80200894:	74860613          	addi	a2,a2,1864 # 80200fd8 <etext+0x5e4>
    80200898:	85a6                	mv	a1,s1
    8020089a:	854a                	mv	a0,s2
    8020089c:	0bc000ef          	jal	ra,80200958 <printfmt>
    802008a0:	bb41                	j	80200630 <vprintfmt+0x3a>
                p = "(null)";
    802008a2:	00000417          	auipc	s0,0x0
    802008a6:	72e40413          	addi	s0,s0,1838 # 80200fd0 <etext+0x5dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008aa:	85e2                	mv	a1,s8
    802008ac:	8522                	mv	a0,s0
    802008ae:	e43e                	sd	a5,8(sp)
    802008b0:	116000ef          	jal	ra,802009c6 <strnlen>
    802008b4:	40ad8dbb          	subw	s11,s11,a0
    802008b8:	01b05b63          	blez	s11,802008ce <vprintfmt+0x2d8>
                    putch(padc, putdat);
    802008bc:	67a2                	ld	a5,8(sp)
    802008be:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008c2:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
    802008c4:	85a6                	mv	a1,s1
    802008c6:	8552                	mv	a0,s4
    802008c8:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
    802008ca:	fe0d9ce3          	bnez	s11,802008c2 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    802008ce:	00044783          	lbu	a5,0(s0)
    802008d2:	00140a13          	addi	s4,s0,1
    802008d6:	0007851b          	sext.w	a0,a5
    802008da:	d3a5                	beqz	a5,8020083a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
    802008dc:	05e00413          	li	s0,94
    802008e0:	bf39                	j	802007fe <vprintfmt+0x208>
        return va_arg(*ap, int);
    802008e2:	000a2403          	lw	s0,0(s4)
    802008e6:	b7ad                	j	80200850 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
    802008e8:	000a6603          	lwu	a2,0(s4)
    802008ec:	46a1                	li	a3,8
    802008ee:	8a2e                	mv	s4,a1
    802008f0:	bdb1                	j	8020074c <vprintfmt+0x156>
    802008f2:	000a6603          	lwu	a2,0(s4)
    802008f6:	46a9                	li	a3,10
    802008f8:	8a2e                	mv	s4,a1
    802008fa:	bd89                	j	8020074c <vprintfmt+0x156>
    802008fc:	000a6603          	lwu	a2,0(s4)
    80200900:	46c1                	li	a3,16
    80200902:	8a2e                	mv	s4,a1
    80200904:	b5a1                	j	8020074c <vprintfmt+0x156>
                    putch(ch, putdat);
    80200906:	9902                	jalr	s2
    80200908:	bf09                	j	8020081a <vprintfmt+0x224>
                putch('-', putdat);
    8020090a:	85a6                	mv	a1,s1
    8020090c:	02d00513          	li	a0,45
    80200910:	e03e                	sd	a5,0(sp)
    80200912:	9902                	jalr	s2
                num = -(long long)num;
    80200914:	6782                	ld	a5,0(sp)
    80200916:	8a66                	mv	s4,s9
    80200918:	40800633          	neg	a2,s0
    8020091c:	46a9                	li	a3,10
    8020091e:	b53d                	j	8020074c <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
    80200920:	03b05163          	blez	s11,80200942 <vprintfmt+0x34c>
    80200924:	02d00693          	li	a3,45
    80200928:	f6d79de3          	bne	a5,a3,802008a2 <vprintfmt+0x2ac>
                p = "(null)";
    8020092c:	00000417          	auipc	s0,0x0
    80200930:	6a440413          	addi	s0,s0,1700 # 80200fd0 <etext+0x5dc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
    80200934:	02800793          	li	a5,40
    80200938:	02800513          	li	a0,40
    8020093c:	00140a13          	addi	s4,s0,1
    80200940:	bd6d                	j	802007fa <vprintfmt+0x204>
    80200942:	00000a17          	auipc	s4,0x0
    80200946:	68fa0a13          	addi	s4,s4,1679 # 80200fd1 <etext+0x5dd>
    8020094a:	02800513          	li	a0,40
    8020094e:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
    80200952:	05e00413          	li	s0,94
    80200956:	b565                	j	802007fe <vprintfmt+0x208>

0000000080200958 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200958:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
    8020095a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    8020095e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
    80200960:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
    80200962:	ec06                	sd	ra,24(sp)
    80200964:	f83a                	sd	a4,48(sp)
    80200966:	fc3e                	sd	a5,56(sp)
    80200968:	e0c2                	sd	a6,64(sp)
    8020096a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
    8020096c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
    8020096e:	c89ff0ef          	jal	ra,802005f6 <vprintfmt>
}
    80200972:	60e2                	ld	ra,24(sp)
    80200974:	6161                	addi	sp,sp,80
    80200976:	8082                	ret

0000000080200978 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
    80200978:	4781                	li	a5,0
    8020097a:	00003717          	auipc	a4,0x3
    8020097e:	68673703          	ld	a4,1670(a4) # 80204000 <SBI_CONSOLE_PUTCHAR>
    80200982:	88ba                	mv	a7,a4
    80200984:	852a                	mv	a0,a0
    80200986:	85be                	mv	a1,a5
    80200988:	863e                	mv	a2,a5
    8020098a:	00000073          	ecall
    8020098e:	87aa                	mv	a5,a0
int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
    80200990:	8082                	ret

0000000080200992 <sbi_set_timer>:
    __asm__ volatile (
    80200992:	4781                	li	a5,0
    80200994:	00003717          	auipc	a4,0x3
    80200998:	68c73703          	ld	a4,1676(a4) # 80204020 <SBI_SET_TIMER>
    8020099c:	88ba                	mv	a7,a4
    8020099e:	852a                	mv	a0,a0
    802009a0:	85be                	mv	a1,a5
    802009a2:	863e                	mv	a2,a5
    802009a4:	00000073          	ecall
    802009a8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
    802009aa:	8082                	ret

00000000802009ac <sbi_shutdown>:
    __asm__ volatile (
    802009ac:	4781                	li	a5,0
    802009ae:	00003717          	auipc	a4,0x3
    802009b2:	65a73703          	ld	a4,1626(a4) # 80204008 <SBI_SHUTDOWN>
    802009b6:	88ba                	mv	a7,a4
    802009b8:	853e                	mv	a0,a5
    802009ba:	85be                	mv	a1,a5
    802009bc:	863e                	mv	a2,a5
    802009be:	00000073          	ecall
    802009c2:	87aa                	mv	a5,a0


void sbi_shutdown(void)
{
    sbi_call(SBI_SHUTDOWN,0,0,0);
    802009c4:	8082                	ret

00000000802009c6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    802009c6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
    802009c8:	e589                	bnez	a1,802009d2 <strnlen+0xc>
    802009ca:	a811                	j	802009de <strnlen+0x18>
        cnt ++;
    802009cc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
    802009ce:	00f58863          	beq	a1,a5,802009de <strnlen+0x18>
    802009d2:	00f50733          	add	a4,a0,a5
    802009d6:	00074703          	lbu	a4,0(a4)
    802009da:	fb6d                	bnez	a4,802009cc <strnlen+0x6>
    802009dc:	85be                	mv	a1,a5
    }
    return cnt;
}
    802009de:	852e                	mv	a0,a1
    802009e0:	8082                	ret

00000000802009e2 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
    802009e2:	ca01                	beqz	a2,802009f2 <memset+0x10>
    802009e4:	962a                	add	a2,a2,a0
    char *p = s;
    802009e6:	87aa                	mv	a5,a0
        *p ++ = c;
    802009e8:	0785                	addi	a5,a5,1
    802009ea:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
    802009ee:	fec79de3          	bne	a5,a2,802009e8 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
    802009f2:	8082                	ret
