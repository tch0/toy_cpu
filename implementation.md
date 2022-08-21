自上大学开始，很早就听说过了CPU这个东西，唯一知道的是：这个东西很复杂，这个东西是计算机的核心，这个东西集成电路做的，而且主要应该是数字集成电路做的，就是说主要进行的是0和1的操作。但对内部工作原理还是一脸懵逼。众所周知，计算机的五个组成部分为运算器（数据通路）、控制器、存储器、输入/输出设备。而CPU的角色应该就是运算器与控制器，两者是结合而并非独立的。但内部呢？依旧不懂。而后有学过8086汇编，对汇编有了一点基础的了解。大概知道CPU是读取一条条的机器指令来执行的，特定的指令会对寄存器、内存、特定的标志位进行操作。处理器内部电路依旧不知，汇编如何翻译成机器码依旧不知。但也只剩下这两个问题了。所以现在只需要解决两个问题：汇编如何翻译成机器码，机器码是如何在CPU里面运行起来的。

而汇编，很明显，是与具体的处理器相关的。也即是不同处理器的指令集体系结构（[ISA][1],Instruction Set Architecture）是不同的。对应的处理器设计也必然是不同的。主要可分为RISC和CISC，这里实现MIPS32指令集的部分指令。正文会简单介绍。

自4月份大概快结束时环境搭好后，实现大概花了半个月的课余时间，到现在都五月中旬了。很多时候在划水，其实应该要不了这么久的。而且我的目标只实现一部分指令就行了，能玩就可以了。按照实现顺序依次实现了：ori，逻辑运算、移位指令和空指令，移动操作指令，部分算术操作指令，条件分支、无条件转移指令，加载存储指令。没有实现协处理器相关指令和中断异常相关指令。至于什么指令级并行、数据级并行、乱序发射啥的统统都是没有的。不过有了前面的那些已经可以进行很多操作了。下面简单说一下实现思路。细节可参考《[自己动手写CPU][2]》，或者[作者博客][3]。我的实现基本上否是参考这本书，以及这个repo:[abcdabcd987/toy-cpu][4].


# ISA
先来看一下ISA的定义，[ISA-Wikipedia][5]：
>An instruction set architecture (ISA) is an abstract model of a computer. It is also referred to as architecture or computer architecture. A realization of an ISA is called an implementation. An ISA permits multiple implementations that may vary in performance, physical size, and monetary cost (among other things); because the ISA serves as the interface between software and hardware. Software that has been written for an ISA can run on different implementations of the same ISA. This has enabled binary compatibility between different generations of computers to be easily achieved, and the development of computer families. Both of these developments have helped to lower the cost of computers and to increase their applicability. For these reasons, the ISA is one of the most important abstractions in computing today.


首先ISA是一个抽象模型，一个ISA可以有不同的实现。ISA的角色是**硬件和软件的接口**。CPU通过电路物理上实现ISA，软件通过编译器将高级语言编译为ISA对应的汇编语言进而翻译为机器码，即可在实现了该ISA的处理器上运行。ISA可以说是计算机中最重要的抽象。

只要ISA相同，实现方式的不同并不会影响软件的运行，这也是**接口**这个伟大的抽象的意义。接口面向调用者，需要进行的所有操作通过接口去调用，内部实现对调用者是完全透明的。这样对于一款处理器，知道其ISA，我们就可以编写程序，而不需要知道内部实现。

## 抽象-接口-分层

有了接口这个抽象，我们便可以将计算机体系进行分层，分层在计算机科学中是广泛存在的，比如计算机层次结构：

![layers][6]

和计算机网络中的国际标准OSI七层模型与事实工业标准的TCP/IP四层模型：

![computer-network-layers][7]

都是很好的体现。在哪一层操作，我们只需要知道其下层的接口，而不必知道具体实现。这可以简化问题的复杂度，使我们只需专心处理其中一层的问题。


## 指令集体系结构

一个指令集体系结构定义了：

 - 支持的数据类型（supported data types）
 - 主存与寄存器（the main memory and registers）
 - 内存一致性，寻址方式（memory consistency and addressing modes）
 - 机器指令集合（the set of machine instructions）
 - 输入输出模型（input/output model）

## MIPS指令集

详细信息参见[MIPS architecture - Wikipedia][8]。MIPS指令集是精简指令集（CISC）的典型代表。[龙芯][9]使用的便是MIPS指令集。MIPS算是一类架构，并不单一，有各种扩展以及子架构等。如MIPS I，MIPS II，MIPS III...MIPS 32，MIPS 64，MIPS 64 R2...等等。这算是一个比较学院派的指令集，在商业上并不算成功（相比Intel x86-64），但这对这里的实现并不会有什么影响。其设计者[John L. Hennessy][10]与 [David A. Patterson][11]是去年(2017)[ACM图灵奖][12]的获得者。下面看一下MIPS32指令集的一些细节。

**数据类型**：一个字4个字节32bit，支持半字与字节。
**寄存器**：定义了32个通用寄存器（与x86的专用寄存器设计不同）命名为`$0...$31`，很明显需要5个二进制位来寻址寄存器。并且还定义了两个专用寄存器`HI`和`LO`用来存储两个32位操作数的乘积或者商与余数。

**指令类型**：MIPS32的所有指令均为32位，分为三大类**R型**、**I型**、**J型**.

![mips-register][13]

其中`opcode`为指令码，R型指令中`rs`,`rt`保存源操作数的寄存器号，I型指令中一般`rs`位源操作数，`rt`为目的操作数，具体的指令具体看。`rd`代表要写入的目的寄存器。`shamt`代表位移量（仅在移位指令中使用）。`funct`为功能码，`opcode`相同的不同R型指令通过`funct`字段来区分。`immediate`代表16位立即数。`address`为26位地址，在分支跳转指令中使用。

**寻址方式**：立即数寻址、寄存器寻址、基址寻址、PC相对寻址。

**所有指令**：详细信息可以在[MIPS architecture - Wikipedia][14] 和 [MIPT-ILab/mipt-mips][15]中找到，太多不抄。


# 处理器结构

现在指令集有了，机器语言也有了（就是每一条汇编语句对应的32位机器码），那就需要来实现了。很明显我们需要对每条32位指令进行解码，然后执行，执行之前需要从寄存器堆中取出操作数。解码之前需要取出指令，所以就要有一个指向当前指令的程序计数器(PC)以及存储指令的指令存储器。执行完了之后需要将结果写入特定寄存器或者数据存储器。

那么一个处理器的大致结构就有了。具体怎么得到的请参考《[计算机组成与设计：硬件软件接口][16]》第三章（下面框图均来自该书）。这里没有包含控制模块，只给出了一些模块的控制信号。

![mips-cpu-architecture][17]

简单解释一下：
 1. PC为程序计数器，最小编址单位为字节，一条指令32字节。上面的加法器+4使PC移动到下一条指令。
 2. 从指令存储器取出指令解码后，需要从寄存器堆中取出最多两个源操作数，以及写入一个目的操作数。所以有两个读端口，一个写端口。
 3.  `Sign-extend`即符号扩展，这里将16位立即数（I型指令后16位）符号扩展到32位传递到下一阶段参与下一步操作。
 4. 在ALU中对操作数执行操作，得到结果，具体执行什么操作由具体指令决定。
 5. 执行之后的结果保存至存储器或者寄存器堆。
 6. 右上角的为分支跳转指令的地址处理模块，左移两位代表着分支跳转指令中的地址单位是字，所以需要左移两位(乘以4)。
 7. 执行条件转移指令时，下一条执行的指令由条件判定得到，即最右上角多路选择器输入信号为条件判定结果。
 8. ALU为通用的算术逻辑运算单元，可以对输入的32位操作数进行加减移位等操作。


## 流水线（pipeline）

如果将上面所有操作都放在一个时钟周期内执行，那么时钟周期的取值必须要大于上面框图中最大的延时。我们可以将上述过程分为下列五个阶段：

- 取指（instruction fetch）IF
- 译码（instruction decode）ID
- 执行（execution）EX
- 访存（memory）MEM
- 写回（write back）WB

如果按照上面的数据流图来设计处理器，同一时刻必然只能执行上面五个操作中的一个，而执行其余操作额模块处于空闲状态，资源浪费明显。所以我们需要引入**流水线机制**。这五个阶段便是典型的五级流水线的流水阶段。我们在每一个阶段之间加入一个触发器，在时钟上升沿触发，将数据传送到下一阶段。如果流水线划分得当，可以使时钟周期下降为原来的五分之一。虽然一条指令需要五个周期才能执行完，但一个时钟周期内同时执行了五条指令。毫无疑问提高了效率。

MIPS的典型五级流水线框图：

![mips-five-stage-pipeline][18]

这里加上了控制模块。其中的`IF/ID`、`ID/EX`、`EX/MEM`、`MEM/WB`均为触发器，时钟上升沿来临时将信息传递到下一阶段。

## 流水线冒险

>任何事物都是有两面性的，如果一个事物看起来只有好处而没有任何坏处，那么它隐藏在水面下的暗流一定会在什么时候掀翻你的小船。——Tiko.T

流水线当然也不例外，伴随着流水线而来的便是**冒险（hazard）**，冒险指的是下一个周期的下一条指令将不能按照预定的计划执行，如果执行便会产生非预期结果的情况。

冒险分为三类：
**结构冒险**：硬件资源冲突，这在这里实现的流水线中非常容易避免。
**数据冒险**：后面执行的指令依赖于前面指令执行的结果，然而在后面指令需要数据的时候，前面的指令还未将其写入指定存储位置/寄存器。
**控制冒险**：流水线分支指令修改PC造成的冒险。

这里实现只会产生数据相关造成的冒险。解决途径：
**流水线暂停**：将依赖于前面指令运行结果的指令暂停，等到前面指令将结果写入后，再运行即可。
**数据前推**：某些指令在`EX`或者`MEM`阶段便已经得到结果。只需要将这时候的数据传递回ID阶段，便可以解决。
结合上述两种方式，便可以解决这里要实现的所有数据相关问题。


# verilog实现

使用verilog进行编程，verilog的编写思路与高级编程语言很不一样，就我个人的感觉。用verilog写电路是已经有了这个电路的功能、连接关系、时序后直接将其翻译为相应的verilog描述即可。这里只采用行为级描述与RTL级描述。不需要任何结构描述，我们只需要知道功能以及接口就可以了，不需要从晶体管、逻辑门层级上去建模。所以使用的全都是最简单的语法如`if`，`else`，`case`，`assign`，`<=`。verilog语法比较简单，但是就是因为简单，所以很多时候带来的是大量的冗余和重复代码下面介绍带参宏可以很好的解决这个问题。不得不说行为级描述非常棒，像我这种搞不懂晶体管的也可以写一个电路来娱乐一下。下面的代码就不贴了，已上传到[Github][19]，逻辑都比较简单，这里只简要叙述一下每个流水线阶段进行的操作。

## 第一条指令`ori`的实现

第一条实现的指令是`ori`，执行立即数或操作。
指令用法：`ori rs,rt,immidiate`
操作：`$rt = $rs | zero-extended(immidiate)`，即将立即数无符号扩展（即零扩展，前面填16个0即可）至32位后，与寄存器`rs`的值进行按位或操作，结果写入寄存器`rt`。
指令格式：I型，`op = 6'b001101`
![ori][20]

实现：

- IF阶段：将32bit指令从指令存储器中取经过信号线`inst`传递到到ID（中间会经过触发器IF/ID，后同）。
- ID阶段译码：简单的`case`语句，判断`inst[31:26]`是否等于`ori`的`op`，是的话，将`rs`，`rt`寄存器的值，具体指令类型，符号扩展后的`immidiate`传到EX阶段。
- EX阶段执行：根据前一阶段传递过来的类型，对两个源操作数执行或操作，生成1bit寄存器写使能信号`we`，5bit要写入的寄存器编号`waddr`，32bit要写入寄存器的值`wdata`到MEM阶段。
- MEM阶段：仅传递这三个信号不执行任何其他操作。
- WB阶段：将这三个信号传递到寄存器堆`regfile`。
- `regfile`在下一个时钟周期上升沿来临时依据输入的三个信号，判断是否要写入，`we`有效则将值写入相应寄存器。则一条指令执行完成。

可以看到从ID到执行完毕，经过了四个触发器，并且`regfile`在时钟上升沿来临将值写入，指令执行完毕，共消耗五个时钟周期。`ori`实现完成。

上面的过程很简单，但是实际编码还是有一定的编码量的，需要实现的模块有：

- `inst_rom`，指令存储器，使用`$readmemh`读入指令文件`inst_ori_test.txt`
- `pc_reg`，程序计数器
- `if_id`，触发器
- `id`，译码阶段
- `regfile`，寄存器堆
- `ex`，执行阶段
- `ex_mem`，触发器
- `mem`，访存阶段
- `mem_wb`，触发器
- `openmips`，除去存储器之外的模块实例化，连接模块
- `open_mips_min_sopc`，最小SOPC，openmips以及inst_rom实例化
- `open_mips_min_sopc_tb`，test bench测试模块，使用`$dumpvars`和`$dumnpfile`将波形导出到`open_mips_min_sopc_tb.vcd`。

模块间连接关系如图（来自作者博客，侵删）：

![ori-modules][21]

测试使用的汇编源文件`inst_ori_test.s`:
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
编译得到机器码用十六进制字符表示，文件`inst_ori_test.txt`
```
34011100
34020020
3403ff00
3404ffff
```
如何编译查看上一篇文章：[环境搭建][22]。

实现之后，依次执行下列命令编译、仿真、查看波形：
```
iverilog -s open_mips_min_sopc_tb -o a.out ./*.v
vvp a.out
gtkwave open_mips_min_sopc_tb.vcd
```
即可看到以下波形：

![test1-ori][23]

上述波形给出了很详细的主要阶段的信号变化。可以看到`ori`指令应该实现正确了。
上面四条指令并没有出现数据相关，现在我们考虑数据相关。这里采用**数据前推**的方式解决。细节参见：[自己动手写CPU之第五阶段（1）——流水线数据相关问题][24]。

解决数据相关之后，测试如下汇编源文件：
```
  .org 0x0 
  .global _start
  .set noat
_start:
  ori $1,$0,0x1100
  ori $2,$1,0x0020
  ori $3,$2,0xff00
  ori $4,$3,0xffff
```
得到波形如下：

![ori-forwarding][25]

## 后续指令实现

后续依次实现逻辑、移位、空指令、移动操作指令（增加`hilo_reg`模块，同样采用数据前推处理数据相关）、算术操作指令（实现流水线暂停机制，增加模块`ctrl`）、转移指令（实现延迟分支）、加载存储指令（增加`data_ram`数据存储器模块，处理load相关，采用流水线暂停处理）。后续还有协处理器访问指令和异常相关指令，我并没有做实现。

细节不过多赘述，最后大概也就1k行代码左右，其中还有一半左右是输入输出信号线声明、模块实例化啥的，代码量不算大，但我感觉自己写了很久，还是太菜的缘故吧！有兴趣的话可参考《自己动手写CPU》，以及我的实现：[aojueliuyun/toy_cpu][27]。


# tricks

编写verilog时的一些小trick。

## 带参宏

`verilog`的语法是很简单的，这导致了很多时候经常要进行重复的赋值操作。人肉编码很容易出错，copy，paste也很麻烦，波形看花眼。而verilog中的函数是不可综合的。但是依然可以使用带参宏，整洁美观，缩减了代码量，提高可维护性。

如`id.v`中定义的：
```verilog
`define SET_INST(i_aluop, i_alusel, i_re1, i_reg1_addr, i_re2, i_reg2_addr, i_we, i_waddr, i_imm, i_inst_valid) if(1) begin \
    aluop_o       <=  i_aluop       ; \
    alusel_o      <=  i_alusel      ; \
    reg1_re_o     <=  i_re1         ; \
    reg1_addr_o   <=  i_reg1_addr   ; \
    reg2_re_o     <=  i_re2         ; \
    reg2_addr_o   <=  i_reg2_addr   ; \
    we_o          <=  i_we          ; \
    waddr_o       <=  i_waddr       ; \
    imm           <=  i_imm         ; \
    inst_valid    <=  i_inst_valid  ; \
end else if(0)
```
便可以很好的简化后续的赋值操作，这里使用了一个继承自C语言的梗`do ... while(0)`或者`if(1) ... else if(0)`。verilog中可使用后者。这样定义便可以像函数一样调用，后面就可以加上`;`。

## 内存分块

在`data_ram`模块的实现中，因为需要进行字节操作，如果只定义一个一维的内存的话，实现起来会不方便。所以可以分块定义为四个块，每个地址的字就是将四个块中对应地址的字节组合起来。

```verilog
reg  [`ByteWidth]    bank0 [0:`DataMemNum-1];
reg  [`ByteWidth]    bank1 [0:`DataMemNum-1];
reg  [`ByteWidth]    bank2 [0:`DataMemNum-1];
reg  [`ByteWidth]    bank3 [0:`DataMemNum-1];
```

## $dumpvars

使用系统任务`$dumpvars`导出变量到波形。
调用：`$dumpvars(level, module1, module2, ...)`，`level`为指定的模块向下的模块层次。也可以单独指定某一个信号，模块可以是某一模块的子模块。
使用系统任务`$dumpfile`将波形导出到vcd文件。
调用：`$dumpfile("test.vcd")`

## wire & reg

这是verilog基础，`wire`型只能使用`assign`进行连续性赋值，`reg`型只能在过程快中使用`=`或者`<=`进行赋值，多用`<=`非阻塞性赋值，不需要阻塞。并且多次使用`<=`赋值以最后一个为准，这在高级语言中是不言自明的，但是`<=`是非阻塞性赋值，是并行对所有信号线赋值的，所以这个需要注意。

输出一般情况下使用`reg`，某些信号也可以使用`wire`，输入均使用`wire`。定义存储器均使用`reg`。

## input & output

输入输出信号声明可以是在模块的端口列表中，也可以是在模块内部，我使用的全部是在端口列表中声明。缺省类型`wire`。

```verilog
module data_ram (
    input  wire                    clk    ,
    input  wire                    ce     ,
    input  wire                    we     ,
    input  wire  [ 3:0        ]    sel    ,
    input  wire  [`DataAddrBus]    addr   ,
    input  wire  [`DataBus    ]    data_i ,
    output  reg  [`DataBus    ]    data_o  
);
```

## $signed

使用`$signed()`将无符号数转换为有符号数，而无需自己通过检测最高位来判断有符号数的正负，这在有符号数加减法需要检测溢出时非常方便。
`ex.v`中加减法以及置位指令实现片段：
```verilog
case (aluop_i)
    `EXE_SLT_OP   : arith_res <= $signed(opv1_i) < $signed(opv2_i);
    `EXE_SLTU_OP  : arith_res <= opv1_i < opv2_i;
    `EXE_ADD_OP   : arith_res <= $signed(opv1_i) + $signed(opv2_i);
    `EXE_ADDU_OP  : arith_res <= opv1_i + opv2_i;
    `EXE_ADDI_OP  : arith_res <= $signed(opv1_i) + $signed(opv2_i);
    `EXE_ADDIU_OP : arith_res <= opv1_i + opv2_i;
    `EXE_SUB_OP   : arith_res <= $signed(opv1_i) - $signed(opv2_i);
    `EXE_SUBU_OP  : arith_res <= opv1_i - opv2_i;
```

## 内建的 / & *
乘法和除法指令实现时为了方便我采用的是内建的`/`和`*`，这样乘法和除法均在一周期内完成，这样效率并不高。作者并没有这样实现，想查看细节可以参考：[自己动手写CPU之第七阶段（9）——除法指令说明及实现思路][28]。

## 溢出检测

某些算术运算指令不检测溢出，但是某些需要。所以需要一个一位信号来保存。
`ex.v`中：
```verilog
wire  sum_overflow = ($signed(opv1_i) > 0 && $signed(opv2_i) > 0 && $signed(arith_res) < 0
                   || $signed(opv1_i) < 0 && $signed(opv2_i) < 0 && $signed(arith_res) > 0);
```


## 初始化

对存储器的初始化放在`initial`中一次性完成，`initial`是不可综合的，所以我编写时是将指令存储器的初始化放在了`test bench`中的。但最后综合出来其实没有太大意义，所以我没有做这一步，也不知道能否通过综合，就语法上来说应该是可以的。

初始化采用`$readmemh`任务读取，`$readmemh`任务采用16进制读取，要求输入文件每一行为8位16进制数，读取到存储单元的连续32bit中。

## PC

程序计数器模块是这样编写的：
```verilog
`include "const.v"

module pc_reg (
    input wire                    clk            ,
    input wire                    rst            ,
    input wire  [`StallBus   ]    stall          ,
    input wire                    branch_flag_i  ,
    input wire  [`RegBus     ]    branch_addr_i  ,
    output reg  [`InstAddrBus]    pc             ,
    output reg                    ce                // chip enable to inst_rom
);
    always @(posedge clk) begin
        if(rst == `RESET_ENABLE) begin 
            ce <= `CHIP_DISABLE;
        end else begin 
            ce <= `CHIP_ENABLE;
        end
    end
    always @(posedge clk) begin
        if(ce == `CHIP_DISABLE) begin
            pc <= 0;
        end else if (stall[0] == `NOSTOP) begin           // the pipeline do not stop
                if(branch_flag_i == `BRANCH)              // branch
                     pc <= branch_addr_i;
                else pc <= pc + 4;
        end
    end
endmodule
```

可以看到这里在复位信号从有效变为无效后，需要最多两个周期，即下下个时钟周期上升沿来临之后，才会输出有效的PC信号，进行指令的读取。


## regfile

寄存器堆中读取是组合逻辑电路，而写入是时序逻辑电路。为了防止错误，必须这样做。因为如果读取和写入的是一个寄存器，我们必须先读取后写入。而如果都是组合逻辑，那么在上升沿来临之前，最后读取的寄存器值就会变成刚写入的结果。

`regfile`读写端口操作：
```verilog
    //write port operation
    always @(posedge clk) begin
        if(rst == `RESET_DISABLE) begin 
            if((we == `READ_ENABLE) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end

    //read port 1 operation
    always @(*) begin
        if(rst == `RESET_ENABLE) begin
            rdata1 <= `ZERO_WORD;
        end else if(raddr1 == `RegNumLog2'h0) begin 
            rdata1 <= `ZERO_WORD;
        end else if((raddr1 == waddr) && (we == `WRITE_ENABLE) && (re1 == `READ_ENABLE)) begin
            rdata1 <= wdata;          // handle data-dependant hazard about instruction away from two inst
        end else if(re1 == `READ_ENABLE) begin 
            rdata1 <= regs[raddr1];   // read data
        end else begin
            rdata1 <= `ZERO_WORD;
        end
    end
```

## 自动测试

项目的[test目录][29]下是对每一个功能的自动测试。在汇编器没有做任何优化时（使用`.set noreorder`指示不要对指令重新排序），一段汇编的执行在任何一个时刻的CPU内部状态（包括PC、寄存器值、堆栈等）在仿真环境中都是可预测的。所以可以在test bench中对其进行断言，并输出是否通过测试的信息。

文件`assert.v`定义了几个相关宏：
```verilog
`ifndef ASSERT_V
`define ASSERT_V

`define ASSERT(x) if(1) begin \
    if (!(x)) begin \
        $display("\033[91;1m[%s:%0d] ASSERTION FAILURE: %s\033[0m", `__FILE__,  `__LINE__, `"x`"); \
        $finish_and_return(1); \
    end \
end else if(0)

`define PASS(test) #2 if(1) begin $display("\033[92;1m%s -> PASS\033[0m", `"test`"); $finish; end else if(0)
`define AR(id, expected) `ASSERT(open_mips_min_sopc0.openmips0.regfile1.regs[id] === expected) // generic register assertion
`define AHI(expected) `ASSERT(open_mips_min_sopc0.openmips0.hilo_reg0.hi_o === expected)       // register HI assertion
`define ALO(expected) `ASSERT(open_mips_min_sopc0.openmips0.hilo_reg0.lo_o === expected)       // register LO assertion

`endif
```
这里只需要对使用了的通用寄存器、`HI`、`LO`进行断言判断是否正确按照预期执行就OK了。

## run test

上面的都编写完之后，可以写一个makefile来一键运行所有测试。但是我的开发环境是windows，用不了make，虚拟机体验又不太好。所以写了一个[shell脚本][30]来替代一下，windows下（需要一个Bash，[Git Bash][31]就很好）和linux下都能运行。

有兴趣clone下来运行一下的话可以执行如下命令：

```shell
git clone https://github.com/aojueliuyun/toy_cpu ./toy_cpu
cd ./toy_cpu/test
./runtest.sh -t
```

依赖：Git，Icarus verilog，Gtkwave


# reference

\[1\] 雷思磊.自己动手写CPU[M].电子工业出版社,2014.
\[2\] 戴维 A.帕特森 (David A.Patterson),约翰 L.亨尼斯 (John L.Hennessy).计算机组成与设计(原书第5版)[M].机械工业出版社,2017.


  [1]: https://en.wikipedia.org/wiki/Instruction_set_architecture
  [2]: https://book.douban.com/subject/25960657/
  [3]: https://blog.csdn.net/leishangwen/article/list/5
  [4]: https://github.com/abcdabcd987/toy-cpu
  [5]: https://en.wikipedia.org/wiki/Instruction_set_architecture
  [6]: images/computer-layers.jpg
  [7]: images/computer-network-layers.png
  [8]: https://en.wikipedia.org/wiki/MIPS_architecture
  [9]: https://baike.baidu.com/item/%E9%BE%99%E8%8A%AF/145607?fr=aladdin
  [10]: https://amturing.acm.org/award_winners/hennessy_1426931.cfm
  [11]: https://amturing.acm.org/award_winners/patterson_2316693.cfm
  [12]: https://amturing.acm.org/
  [13]: images/mips-register.png
  [14]: https://en.wikipedia.org/wiki/MIPS_architecture
  [15]: https://github.com/MIPT-ILab/mipt-mips/wiki/MIPS-Instruction-Set
  [16]: https://book.douban.com/subject/10441748/
  [17]: images/mips-cpu-architecture.png
  [18]: images/mips-five-stage-pipeline.png
  [19]: https://github.com/aojueliuyun/toy_cpu
  [20]: images/instruction-format-ori.png
  [21]: images/ori-modules.jpg
  [22]: environment.md
  [23]: images/test1-ori.PNG
  [24]: https://blog.csdn.net/leishangwen/article/details/38298787
  [25]: images/test2-ori-forwarding.PNG
  [27]: https://github.com/aojueliuyun/toy_cpu
  [28]: https://blog.csdn.net/leishangwen/article/details/39079817
  [29]: https://github.com/aojueliuyun/toy_cpu/tree/master/test
  [30]: https://github.com/aojueliuyun/toy_cpu/blob/master/test/runtest.sh
  [31]: https://git-scm.com/downloads