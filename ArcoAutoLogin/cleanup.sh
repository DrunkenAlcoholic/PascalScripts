#!/usr/bin/env bash

## compile with fpc + flags

# Flag meaning, use fpc -i to get an output of supported flags
# -P <--- Compiler CPU target e.g x86_64
# -Cp <--- CPU instruction set e.g -CpCOREAVX2
# -Cf <--- FPU instruction set e.g -CfAVX2
# -Op <--- target CPU of optimization e.g -OpCOREAVX2
# -O3 <--- optimization level( 1-4 )
# -Mobjfpc <--- FPC Mode with object pascal support
# -CX <--- create smartlink library
# -B <--- Build all modules
# -XXs <--- Strip all symbols and try to smart link units
# -v <--- verbose
fpc -Px86_64 -CpCOREAVX2 -CfAVX2 -OpCOREAVX2 -O3 -Mobjfpc -CX -B -XXs -v ArcoAutoLogin.lpr


## Remove object & discriptive files
find . -name "*.o" -type f -delete
find . -name "*.ppu" -type f -delete
