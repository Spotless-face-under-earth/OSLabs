#include <console.h>
#include <sbi.h>

/* kbd_intr - try to feed input characters from keyboard */
void kbd_intr(void) {}//处理键盘中断

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}//处理串口中断

/* cons_init - initializes the console devices */
void cons_init(void) {}//初始化控制台设备

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }//将一个字符输出到控制台。

/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {//从控制台读取下一个输入字符
    int c = 0;
    c = sbi_console_getchar();
    return c;
}
