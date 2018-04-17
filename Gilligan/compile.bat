echo off
cd /d %1
del *.6502
echo on

6502\ca65 -o main.o main.asm
6502\ld65 main.o -o main.6502 -C gilligan.cfg

gilligancc rom.6502

del main.6502
del *.o

pause