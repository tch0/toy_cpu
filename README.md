## 一个软核的玩具CPU实现
- 五级流水线。
- 与MIPS32兼容。
- 只实现了一部分指令。

依赖：
- Icarus Verilog
- GtkWave
- g++
- Make

运行测试:
```shell
cd ./test
./runtest.sh -t
```


参考：
- 《[自己动手写CPU][1]》
- [abcdabcd987/toy-cpu][2]

笔记：
- [环境搭建][3]
- [实现细节][4]


  [1]: https://blog.csdn.net/leishangwen/article/list/5?
  [2]: https://github.com/abcdabcd987/toy-cpu
  [3]: environment.md
  [4]: implementation.md
