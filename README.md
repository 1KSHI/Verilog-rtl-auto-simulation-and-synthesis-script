
File structure:
```
/csrc               ----- verilotor文件夹
  ├── main.cpp          ----- verilator testbench
  └── tb_common.h       ----- verilator头文件

/sdc                -----约束文件夹
  ├── *.sdc             ----- yosys时序约束文件
  └── *.xdc             ----- vivado时序约束文件

/vsrc               ----- verilog文件夹
  ├── /tb               ----- testbench文件夹
  │ └── *.v
  └── *.v               ----- rtl 代码

/yosys              ----- 45nm工艺库
  ├── /bin
  ├── /nangate45
  └── /scripts

├── Makefile
└── *.tcl               ----- vivado tcl脚本
```

How to use?
```
make clean
删除临时文件

make wave
verilator rtl波形仿真

make sta
yosys 45nm工艺库综合

make vivado
vivado rtl波形仿真、综合、约束

```