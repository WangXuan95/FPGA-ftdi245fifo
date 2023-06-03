del sim.out dump.vcd
iverilog  -g2001  -o sim.out  ./*.v  ../RTL/ftdi_245fifo/*.v
vvp -n sim.out
del sim.out
pause