# 开发环境搭建

这篇搭建开发环境，下一篇稍微详述实现过程。这两篇来源于看《[自己动手写CPU][1]》（[作者博客][2]）时写代码顺带写的笔记。这是一本非常棒的介绍cpu工作原理并且实践性很强的入门书籍，看完之后对CPU内部构造、MIPS指令集、流水线设计、Verilog编程都有了一定的了解。这本书倾向于实践，涉及到的理论部分的内容基本上仅限于《[计算机组成与设计：硬件/软件接口][3]》的第三章。开始看这本书的起因是偶然在github上浏览到一个有趣的项目——[abcdabcd987/toy-cpu][4]，点进去看了之后，发现语言是verilog，仅十余个源文件，然后想自己也学过verilog，但都没写过电路。了解之后发现这个项目参考自《自己动手写CPU》这本书，然后知乎上逛了一圈，有人说《[CPU自制入门][5]》更好一些，然后屁颠屁颠买了之后。发现并不是很能看懂，而且全书有很大一部分是在讲如何制作印制电路板和FPGA什么的。看了100页，看不下去，仿真老是通不过，有输入，但是输出全为x，找不到原因，很受挫，于是去图书馆借了《自己动手写CPU》。看了之后觉得，比前面那一本更容易懂一些。这本书实现了MIPS指令集的MIPS32版本的所有整数指令。可以使用GNU的汇编工具将MIPS汇编翻译成机器码，就不用自己设计指令集、手动汇编或者写汇编程序（应该有一定难度）了。这里搭建开发环境、熟悉GNU工具的使用。

## Ubuntu虚拟机

这里需要用到Linux，我使用的VMware安装的[Ubuntu18.04 LTS][6]，虚拟机就不多介绍了，ubuntu直接无脑下一步就OK了。然后安装VMtools（[参考][7]），即可在虚拟机与物理机之间进行文字甚至文件拷贝，虚拟机即可以全屏。安装好之后，装一些必备软件以保证ssh连接能顺利进行。
```shell
sudo apt-get update
sudo apt-get install net-tools
sudo apt-get install ssh openssh-server
sudo apt-get install vim
sudo apt-get install lrzsz
```
先使用`ifconfig`命令获取ubuntu虚拟机的IP，这里虚拟机的网络连接最好用桥接，并且保证ubuntu网卡处于打开状态，如果没有则切换到root用户使用`ifup [网卡名称]`命令打开。然后使用XShell建立新连接：输入IP，端口号22，协议SSH，以及ubuntu的用户名和密码，进行远程连接，即可通过`rz`命令向虚拟机上传文件，`sz [file]`命令下载文件到本机。也可以通过Xftp建立ssh连接之后直接拖动文件即可完成传输。[XShell and Xftp is free for home/school.][8] 官网填写信息，即可免费下载。


## GNU工具链

这里使用GNU的MIPS工具链，下载文件`mips-2013.05-65-mips-sde-elf-i686-pc-linux-gnu.tar.bz2`（[CSDN下载][9]，我使用的这一个），`cp`到`/opt`目录下解压：
```
tar -xvjf ./mips-2013.05-65-mips-sde-elf-i686-pc-linux-gnu.tar.bz2
```
`cd`到`/home/username`，添加到当前用户的环境变量：用vim编辑隐藏文件`.bashrc`，在末尾添加一条语句：
```
export PATH="$PATH:/opt/mips-2013.05/bin"
```
使用下列命令使其生效。
```
source ./.bashrc
```
然后终端键入`mips-sde-elf-`，两次TAB自动补全，则对该用户即有下列命令可用。
```
mips-sde-elf-addr2line       mips-sde-elf-cpp             mips-sde-elf-gcc-nm          mips-sde-elf-nm              mips-sde-elf-readelf
mips-sde-elf-ar              mips-sde-elf-elfedit         mips-sde-elf-gcc-ranlib      mips-sde-elf-objcopy         mips-sde-elf-run
mips-sde-elf-as              mips-sde-elf-g++             mips-sde-elf-gcov            mips-sde-elf-objdump         mips-sde-elf-size
mips-sde-elf-c++             mips-sde-elf-gcc             mips-sde-elf-gdb             mips-sde-elf-qemu-system     mips-sde-elf-sprite
mips-sde-elf-c++filt         mips-sde-elf-gcc-4.7.3       mips-sde-elf-gprof           mips-sde-elf-qemu-system-el  mips-sde-elf-strings
mips-sde-elf-conv            mips-sde-elf-gcc-ar          mips-sde-elf-ld              mips-sde-elf-ranlib          mips-sde-elf-strip
```

这里只使用其中几个，均以`mips-sde-elf-`开头。

 - `as`：GNU汇编器，通常称GAS(GNU Assembler)，对源程序进行编译产生目标文件。
 - `ld`：GNU链接器，将as产生的目标文件进行链接、重定位数据产生可执行文件。
 - `objcopy`：用于将一种格式的目标文件复制为另一种格式。
 - `objdump`：用于列出二进制文件的各种信息。
 - `readelf`：类似于objdump，但只能处理ELF格式文件。
 

## 开发工具

**编辑器**：[Sublime Text 3][10]
安装`system verilog`插件，语法高亮、关键字自动补全以及自动格式化，写起来非常舒服。并且sublime支持多行编辑以及块选择，这对于经常出现重复代码的verilog开发来说非常棒。
关于使用：[如何优雅地使用Sublime Text3][11]。
**ps** ：ubuntu下安装后使用命令`subl`打开。

**仿真工具**：[Icarus Verilog][12] & [GTKWave][13]
使用细节可参见：[Icarus Verilog和GTKwave使用简析][14]
命令行环境使用，免费开源跨平台，windows可使用[Git Bash][15]，安装之后添加系统path环境变量之后即可使用。亲测平台不同用起来并没有半毛钱差别。Windows平台也可使用Modelsim。
ububntu下安装Icarus verilog & Gtkwave：
```
sudo apt-get install iverilog
sudo apt-get install gtkwave
```

 * 使用`iverilog`命令编译，`-s`参数指定顶层模块，`-o`指定目标文件。
 * 使用`vvp [file]`对编译好的目标文件进行仿真。
 * 使用`gtkwave *.vcd`查看波形，vcd文件在编写的`test bench`中使用verilog的系统任务`$dumpfile`在仿真过程中产生。


## 问题及解决

**问题1**：Ubuntu下执行`mips-sde-elf-as`命令报错：bash: /opt/mips-2013.05/bin/mips-sde-elf-as: 没有那个文件或目录。

解决：这应该是64位的系统不支持32的程序，参考[64位Linux（ubuntu）安装、运行32位程序][16]，执行系列命令安装支持32位的程序的二进制库即可解决。
```
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install zlib1g:i386 libstdc++6:i386 libc6:i386
```
如果是CentOS的话，则执行
```
yum install glibc.i686
```
我也是通过CentOS7执行上述命令时的报错才知道了是这个原因，因为CentOS7的报错是这样的：bash: /opt/mips-2013.05/bin/mips-sde-elf-as: /lib/ld-linux.so.2: bad ELF interpreter: 没有那个文件或目录。然后参考了[解决linux安装软件：/lib/ld-linux.so.2: bad ELF interpreter问题][17]，才找到原因，耽误了很长时间。

**问题2**：执行命令时用户权限不够，不能写入目标文件。

原因：因为上面我们添加的是普通用户的环境变量，所以不能在所有权为root的目录执行操作。
以下方法均可解决：

- 确保工作目录所有者为当前执行用户。
- 更改工作目录权限，改为777即可。
- 添加系统环境变量，使所有用户均可使用这一系列命令。

也可以添加root用户环境变量，使用root用户进行操作。但一般情况下，我建议使用普通用户进行操作。root用户一不小心手残`rm -rf /*`了怎么办（笑而不语）。

**问题3**：Windows下的脚本文件传输到Linux下运行时，很可能会出现异常/bin/sh^M: bad interpreter: No such file or directory。

原因：DOS/Windows和Linux/Unix的文件换行回车格式不同，基于 DOS/Windows 的文本文件在每一行末尾有一个 CR（回车）和 LF（换行），而 UNIX 文本只有一个换行。

解决：`vim`打开编辑，底行模式`:set ff`查看文件编码格式，结果为`dos`或者`unix`，然后`:set ff=unix`转换为`unix`编码格式即可在linux环境下执行。
更详细信息参见：[批量将目录下所有文件进行 dos/unix 格式转换][18]。




# GNU工具的使用

首先创建一个MIPS汇编源文件`inst_rom.s`，因为第一条实现的指令是`ori`，其实这就是第一条指令实现之后的test case。
```
  .org 0x0             # 指示地址从0x0开始
  .global _start       # 定义一个全局符号 _start
  .set noat            # 允许自由使用寄存器$1
_start:
  ori $1,$0,0x1100
  ori $2,$0,0x0020
  ori $3,$0,0xff00
  ori $4,$0,0xffff
```
手动人脑编译后四条指令得到16进制机器码的文本格式。后面我们使用verilog的`$readmemh`任务读取指令的文本文件，所以后面需要写一个程序将编译好的二进制文件转换为表示16进制机器码的字符文本文件。
```
34011100
34020020
3403ff00
3404ffff
```

## 编译
这里给出命令，细节比较复杂，但只需要执行这两条命令就行了。详解见作者博客：[自己动手写CPU之第四阶段（3）——MIPS编译环境的建立][19]
```
mips-sde-elf-as -mips32 inst_rom.s -o inst_rom.o
```
得到的`inst_rom.o`是一个ELF文件，需要链接才可以成为可执行文件。

## 链接

创建链接描述脚本文件`ram.ld`
```
MEMORY
{
	ram : ORIGIN = 0x00000000, LENGTH = 0x00001000 
}

SECTIONS 
{         
	.text :        
	{         
 	*(.text)
 	} > ram
	
	.data :         
	{
	*(.data)     
	} > ram

	.bss :
	{
	*(.data)
	} > ram
}
ENTRY (_start)
```
然后使用`mips-sde-elf-ld`进行链接
```
mips-sde-elf-ld -T ram.ld inst_rom.o -o inst_rom.om
```
得到的`inst_rom.om`是可执行文件，但并不能执行。因为指令集不同。

## 转换为二进制形式

然后使用`mips-sde-elf-objcopy`将将其转换为二进制形式。
```
mips-sde-elf-objcopy -O binary inst_rom.om inst_rom.bin
```
用notepad++安装`hex-editer`插件，使用16进制格式查看，可以看到与人肉汇编出来的一模一样。

![hex][20]

# 进一步完善

## 将二进制文件转换为16进制文本文件

然后我们需要将其转换为16进制文本文件，以便verilog的任务`$readmemh`读取。作者提供了一个工具，感觉很简单，所以我自己写了一个。

思路：将二进制按字节（使用`char`）顺序读入，类型转换为`int`，输出到目标文件。需要注意所有字节均是两位16进制数。

实现：
```C++
#include <iostream>
#include <fstream>
#include <string>
using namespace std;
std::ifstream fin;
std::ofstream fout;
string source_file_name;
string target_file_name;
const string default_file_name = "a.data";
void bin_to_hex_text();
void print_err_info(const string & err);

int main(int argc, char * argv[])
{
	if(argc == 1)
		return 0;
	if(string(argv[1]) == "-o")
	{
		if(argc > 4)
			print_err_info("arguments is more than ecpected!");
		else if(argc < 4)
			print_err_info("arguments is less than expected!");
		else
		{
			source_file_name = argv[3];
			target_file_name = argv[2];
		}
	}
	else
	{
		if(argc > 2)
			print_err_info("arguments is more than ecpected!");
		else if(argc < 2)
			print_err_info("arguments is less than expected!");
		else
		{
			source_file_name = argv[1];
			target_file_name = default_file_name;
		}
	}
	bin_to_hex_text();
	return 0;
}

void print_err_info(const string & err)
{
	cout << '\n'<< err << "\nThere just two types of commands are available:\n\n    command -o target_file_name source_file_name\n";
	cout << "    command source_file_name  \n\nin the second case, the target file name is " << default_file_name << " which is default\n";
	cout << "please check out and retype.\n";
	exit(-1);
}

void bin_to_hex_text()
{
	fin.open(source_file_name);
	if(!fin)
	{
		cout << "failed to open source file " << source_file_name << endl;;
		exit(-1);
	}
	fout.open(target_file_name);
	if(!fout)
	{
		cout << "failed to create target file " << source_file_name << endl;
		exit(-1);
	}
	fout << hex;    // 十六进制形式输出
	char ch;
	int count = 0;
	while(fin.get(ch))
	{
		count ++;
		int value = static_cast<unsigned char>(ch);
		// cout << value << endl;
		if(value < 0x10)
			fout << '0';
		fout << value;
		if(count % 4 == 0) // 4个字节，32位，一条指令
			fout << '\n';
	}
	fin.close();
	fout.close();
}
```
上述程序支持一个`-o`选项来指定目标文件，但对文件顺序有要求，源文件一定要在命令的最后。顺便写了一些报错信息。

**值得注意的是**：一定要用`get()`读取，不然可能会忽略空白符出现错误，但是`get`只支持`char`类型而不支持`unsigned char`，而`char`默认是有符号的，所以如果直接将`char`类型转换为`int`的话会对负数进行**符号扩展**。也就是说将值为`0xff`的`char`转换为`int`后就变成了`0xffffffff`，那么最后就会出错。这取决于被转换的数，所以要先将其类型转换为`unsigned char`再转换为`int`。

保存上述cpp文件为`bin2mem.cpp`，编译并对上面得到的`inst_rom.bin`进行转换。
```
g++ -o bin2mem ./bin2mem.cpp
./bin2mem -o inst_rom.data inst_rom.bin
```
得到`inst_rom.data`，`cat`一下：
```
$ cat inst_rom.data
34011100
34020020
3403ff00
3404ffff
```
可以看到与人肉汇编的结果一致。至此工具链就闭合了。开发测试环境就算搭建好了。


## Makefile编写

上面的工作完成后，我们可以编写`makefile`来简化所有这些工作。
```makefile
ifndef cross_compile
cross_compile = mips-sde-elf-
endif

CC = $(cross_compile)as
LD = $(cross_compile)ld
OBJCOPY = $(cross_compile)objcopy
OBJDUMP = $(cross_compile)objdump

OBJECTS = inst_rom.o

## compile rules

all: inst_rom.data

%.o: %.s
	$(CC) -mips32 $< -o $@

inst_rom.om: ram.ld $(OBJECTS)
	$(LD) -T ram.ld $(OBJECTS) -o $@

inst_rom.bin: inst_rom.om
	$(OBJCOPY) -O binary $< $@

inst_rom.data: inst_rom.bin
	./bin2mem -o $@ $<

clean:
	rm -f *.o *.om *.bin *.data
```

上述代码保存为文件`Makefile`,可以看到上面所有命令都囊括其中了，如果没有安装`make`，则需要先安装`make`：
```
sudo apt-get install make
```
然后执行`make all`则可一个命令完成上面所有操作。执行之前，我们需要将上面的`bin2mem.cpp`编译得到的可执行文件`bin2mem`，以及链接脚本文件`ram.ld`，以及汇编源文件`inst_rom.s`，以及`Makefile`放在同一目录下。`make clean`即可清理所有生成文件。

## 反汇编

我们可以使用下列命令对可执行文件`inst_rom.om`进行反汇编。
```
mips-sde-elf-objdump -D inst_rom.om > inst_rom.asm
```
得到`asm`汇编文件内容如下：
```
inst_rom.om:     file format elf32-tradbigmips

Disassembly of section .text:

00000000 <_start>:
   0:	34011100 	li	at,0x1100
   4:	34020020 	li	v0,0x20
   8:	3403ff00 	li	v1,0xff00
   c:	3404ffff 	li	a0,0xffff

Disassembly of section .reginfo:

00000000 <.reginfo>:
   0:	0000001e 	0x1e
	...
```
可以看到其中的指令为`li`其实就是`ori`，可以看到反汇编结果与汇编源程序`inst_rom.s`是一致的。

# 结语

环境搭建是开发的基础，其中也有很多坑，第一次用ubuntu很多不熟悉，很多很简单的问题都被坑。从来没有正经的折腾过一个linux的发行版，虽然装过很多发行版，都是虚拟机装一下，装个GCC写个helloworld，体验一下GUI，然后就不知道干什么了。什么时候有空好好折腾折腾，把linux kernel好好了解一下。话说命令行真好玩，make真方便。

# reference

\[1\] 雷思磊.自己动手写CPU[M].电子工业出版社,2014.


  [1]: https://book.douban.com/subject/25960657/
  [2]: https://blog.csdn.net/leishangwen
  [3]: https://book.douban.com/subject/2110638/
  [4]: https://github.com/abcdabcd987/toy-cpu
  [5]: https://book.douban.com/subject/25780703/
  [6]: https://www.ubuntu.com/download/desktop
  [7]: https://www.linuxidc.com/Linux/2016-04/130807.htm
  [8]: https://www.netsarang.com/download/free_license.html
  [9]: https://download.csdn.net/download/wz1226864411/10116997
  [10]: https://www.sublimetext.com/3
  [11]: https://www.jianshu.com/p/3cb5c6f2421c
  [12]: http://iverilog.icarus.com/
  [13]: http://gtkwave.sourceforge.net/
  [14]: https://blog.csdn.net/husipeng86/article/details/60469543
  [15]: https://gitforwindows.org/
  [16]: https://blog.csdn.net/kingroc/article/details/51143327
  [17]: https://yq.aliyun.com/ziliao/79563
  [18]: https://blog.csdn.net/changqing1234/article/details/58585462
  [19]: https://blog.csdn.net/leishangwen/article/details/38228305#t3
  [20]: images/hex-inst_rom.png