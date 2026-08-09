// CAN controller filelist — plain Verilog (no -sverilog: RTL uses `do` as a port name)
// Paths are relative to this directory; compile from here.
+incdir+rtl
+incdir+tb

// RTL (leaves first, top last)
rtl/can_crc.v
rtl/can_register.v
rtl/can_register_asyn.v
rtl/can_register_asyn_syn.v
rtl/can_register_syn.v
rtl/can_ibo.v
rtl/can_fifo.v
rtl/can_acf.v
rtl/can_btl.v
rtl/can_bsp.v
rtl/can_registers.v
rtl/can_top.v

// Testbench
tb/tb_can_basic.v
