// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "can_defines.v"
`include "can_testbench_defines.v"

// Starter testbench for OpenCores CAN controller
// Exercises: basic mode only, 11-bit ID, 4-byte frame TX/RX.
// Structural holes: extended (29-bit) mode, RTR frames, acceptance
// filtering, error injection (bit/CRC/overrun).
module tb_can_basic();

parameter Tp = 1;
parameter BRP = 2*(`CAN_TIMING0_BRP + 1);

// 8051-style interface to node 1
reg        rst_i;
reg        ale_i;
reg        rd_i;
reg        wr_i;
wire [7:0] port_0;
wire [7:0] port_0_i;
reg  [7:0] port_0_o;
reg        port_0_en;
reg        port_free;

// 8051-style interface to node 2
reg        ale2_i;
reg        rd2_i;
reg        wr2_i;
wire [7:0] port2_0;
wire [7:0] port2_0_i;
reg  [7:0] port2_0_o;
reg        port2_0_en;
reg        port2_free;

reg        cs_can;
reg        cs_can2;
reg        clk;
reg        rx;
wire       tx_i;
wire       tx2_i;
wire       bus_off_on;
wire       bus_off2_on;
wire       irq;
wire       irq2;
wire       clkout;
wire       rx_and_tx;
reg        delayed_tx;
reg        tx_bypassed;
reg        extended_mode;
reg  [7:0] tmp_data;
reg  [7:0] tmp_data2;
integer    checks_passed;
integer    checks_failed;

// Tri-state bus for node 1
assign port_0_i  = port_0;
assign port_0    = port_0_en ? port_0_o : 8'hz;

// Tri-state bus for node 2
assign port2_0_i = port2_0;
assign port2_0   = port2_0_en ? port2_0_o : 8'hz;

// Combine tx outputs (wired-AND CAN bus)
wire tx_tmp1 = bus_off_on  ? tx_i  : 1'b1;
wire tx_tmp2 = bus_off2_on ? tx2_i : 1'b1;
wire tx      = tx_tmp1 & tx_tmp2;

// CAN bus: rx (testbench injection) ANDed with the delayed combined TX
assign rx_and_tx = rx & (delayed_tx | tx_bypassed);

// DUT: node 1
can_top i_can_top (
  .cs_can_i(cs_can),
  .rst_i(rst_i),
  .ale_i(ale_i),
  .rd_i(rd_i),
  .wr_i(wr_i),
  .port_0_io(port_0),
  .clk_i(clk),
  .rx_i(rx_and_tx),
  .tx_o(tx_i),
  .bus_off_on(bus_off_on),
  .irq_on(irq),
  .clkout_o(clkout)
);

// Listener: node 2
can_top i_can_top2 (
  .cs_can_i(cs_can2),
  .rst_i(rst_i),
  .ale_i(ale2_i),
  .rd_i(rd2_i),
  .wr_i(wr2_i),
  .port_0_io(port2_0),
  .clk_i(clk),
  .rx_i(rx_and_tx),
  .tx_o(tx2_i),
  .bus_off_on(bus_off2_on),
  .irq_on(irq2),
  .clkout_o()
);

// Clock: 25 MHz
initial clk = 0;
always #20 clk = ~clk;

// Transceiver delay model (matches upstream testbench)
initial delayed_tx = 1;
always begin
  wait (tx);
  repeat (2*BRP) @(posedge clk);
  #1 delayed_tx = tx;
  wait (~tx);
  repeat (2*BRP) @(posedge clk);
  #1 delayed_tx = tx;
end

// ---------------------------------------------------------------
// Node 1 register access (8051 ALE/RD/WR interface)
// ---------------------------------------------------------------
task write_reg1;
  input [7:0] addr;
  input [7:0] data;
  begin
    wait (port_free);
    port_free = 0;
    @(posedge clk); #Tp;
    cs_can = 1;
    @(negedge clk); #Tp;
    ale_i = 1; port_0_en = 1; port_0_o = addr;
    @(negedge clk); #Tp;
    ale_i = 0;
    #90; port_0_o = data; wr_i = 1;
    #158; wr_i = 0; port_0_en = 0;
    cs_can = 0; port_free = 1;
  end
endtask

task read_reg1;
  input  [7:0] addr;
  output [7:0] data;
  begin
    wait (port_free);
    port_free = 0;
    @(posedge clk); #Tp;
    cs_can = 1;
    @(negedge clk); #Tp;
    ale_i = 1; port_0_en = 1; port_0_o = addr;
    @(negedge clk); #Tp;
    ale_i = 0; #90; port_0_en = 0;
    rd_i = 1; #158;
    data = port_0_i;
    rd_i = 0; cs_can = 0; port_free = 1;
  end
endtask

// ---------------------------------------------------------------
// Node 2 register access
// ---------------------------------------------------------------
task write_reg2;
  input [7:0] addr;
  input [7:0] data;
  begin
    wait (port2_free);
    port2_free = 0;
    @(posedge clk); #Tp;
    cs_can2 = 1;
    @(negedge clk); #Tp;
    ale2_i = 1; port2_0_en = 1; port2_0_o = addr;
    @(negedge clk); #Tp;
    ale2_i = 0;
    #90; port2_0_o = data; wr2_i = 1;
    #158; wr2_i = 0; port2_0_en = 0;
    cs_can2 = 0; port2_free = 1;
  end
endtask

task read_reg2;
  input  [7:0] addr;
  output [7:0] data;
  begin
    wait (port2_free);
    port2_free = 0;
    @(posedge clk); #Tp;
    cs_can2 = 1;
    @(negedge clk); #Tp;
    ale2_i = 1; port2_0_en = 1; port2_0_o = addr;
    @(negedge clk); #Tp;
    ale2_i = 0; #90; port2_0_en = 0;
    rd2_i = 1; #158;
    data = port2_0_i;
    rd2_i = 0; cs_can2 = 0; port2_free = 1;
  end
endtask

// ---------------------------------------------------------------
// Self-check helper
// ---------------------------------------------------------------
task check_eq;
  input [7:0] expected;
  input [7:0] actual;
  input [63:0] label;
  begin
    if (expected === actual) begin
      checks_passed = checks_passed + 1;
    end else begin
      $display("FAIL [%s]: expected 0x%02x, got 0x%02x", label, expected, actual);
      checks_failed = checks_failed + 1;
    end
  end
endtask

// ---------------------------------------------------------------
// Main test
// ---------------------------------------------------------------
initial begin
  // Initialise signals
  rst_i       = 1;
  cs_can      = 0;
  cs_can2     = 0;
  ale_i       = 0; rd_i  = 0; wr_i  = 0;
  ale2_i      = 0; rd2_i = 0; wr2_i = 0;
  port_0_o    = 0; port_0_en  = 0; port_free  = 1;
  port2_0_o   = 0; port2_0_en = 0; port2_free = 1;
  rx          = 1;
  tx_bypassed = 0;
  extended_mode = 0;
  checks_passed = 0;
  checks_failed = 0;

  // Release reset after 200 ns
  #200 rst_i = 0;
  #200;

  // ---- Setup: both nodes in basic mode ----

  // Set bit timing (both nodes identical)
  write_reg1(8'd6, {`CAN_TIMING0_SJW, `CAN_TIMING0_BRP});
  write_reg1(8'd7, {`CAN_TIMING1_SAM, `CAN_TIMING1_TSEG2, `CAN_TIMING1_TSEG1});
  write_reg2(8'd6, {`CAN_TIMING0_SJW, `CAN_TIMING0_BRP});
  write_reg2(8'd7, {`CAN_TIMING1_SAM, `CAN_TIMING1_TSEG2, `CAN_TIMING1_TSEG1});

  // Acceptance filter: accept all (mask=FF means don't care)
  write_reg1(8'd4, 8'h00); // acceptance code: irrelevant with mask=FF
  write_reg1(8'd5, 8'hff); // acceptance mask: all don't-care → accept every frame
  write_reg2(8'd4, 8'h00);
  write_reg2(8'd5, 8'hff);

  // Exit reset mode; enable TX and RX interrupts (CR[2:1]=11, CR[0]=0)
  write_reg1(8'd0, 8'h06);
  write_reg2(8'd0, 8'h06);

  // Wait for bus-free: 11 bit times, each bit = (TSEG1+TSEG2+3)*BRP clocks
  repeat (11 * (`CAN_TIMING1_TSEG1 + `CAN_TIMING1_TSEG2 + 3) * BRP) @(posedge clk);

  // ---- Test 1: basic frame TX from node 1, RX by node 2 ----
  // Frame: ID = 11'h1D0 (ID[10:3]=8'hE8, ID[2:0]=3'h0), RTR=0, DLC=4
  // Data: 0xA5, 0x5A, 0xC3, 0x3C

  // Load TX buffer on node 1 (registers 10-15 in basic mode)
  write_reg1(8'd10, 8'hE8);  // ID[10:3]
  write_reg1(8'd11, 8'h04);  // {ID[2:0]=3'h0, RTR=0, DLC=4'h4}
  write_reg1(8'd12, 8'hA5);  // data byte 0
  write_reg1(8'd13, 8'h5A);  // data byte 1
  write_reg1(8'd14, 8'hC3);  // data byte 2
  write_reg1(8'd15, 8'h3C);  // data byte 3

  // Request transmission (CMR bit 0)
  write_reg1(8'd1, 8'h01);
  $display("[%0t] TX requested from node 1", $time);

  // Wait for TX complete interrupt on node 1 (IR bit 1)
  begin : wait_tx
    integer timeout;
    for (timeout = 0; timeout < 200000; timeout = timeout + 1) begin
      @(posedge clk);
      read_reg1(8'd3, tmp_data);
      if (tmp_data[1]) disable wait_tx;  // TX interrupt set
    end
    $display("TIMEOUT waiting for TX interrupt");
    checks_failed = checks_failed + 1;
  end
  $display("[%0t] Node 1 TX complete (IR=0x%02x)", $time, tmp_data);

  // Wait for RX interrupt on node 2 (IR bit 0)
  begin : wait_rx
    integer timeout;
    for (timeout = 0; timeout < 200000; timeout = timeout + 1) begin
      @(posedge clk);
      read_reg2(8'd3, tmp_data2);
      if (tmp_data2[0]) disable wait_rx;  // RX interrupt set
    end
    $display("TIMEOUT waiting for RX interrupt on node 2");
    checks_failed = checks_failed + 1;
  end
  $display("[%0t] Node 2 RX complete (IR=0x%02x)", $time, tmp_data2);

  // Read RX buffer on node 2 (basic mode: registers 20-25)
  read_reg2(8'd20, tmp_data2);
  check_eq(8'hE8, tmp_data2, "RX_ID_HI");
  read_reg2(8'd21, tmp_data2);
  check_eq(8'h04, tmp_data2, "RX_ID_LO");
  read_reg2(8'd22, tmp_data2);
  check_eq(8'hA5, tmp_data2, "RX_DATA0");
  read_reg2(8'd23, tmp_data2);
  check_eq(8'h5A, tmp_data2, "RX_DATA1");
  read_reg2(8'd24, tmp_data2);
  check_eq(8'hC3, tmp_data2, "RX_DATA2");
  read_reg2(8'd25, tmp_data2);
  check_eq(8'h3C, tmp_data2, "RX_DATA3");

  // Release RX buffer on node 2 (CMR bit 2 = release receive buffer)
  write_reg2(8'd1, 8'h04);

  #1000;

  // ---- Final report ----
  if (checks_failed == 0)
    $display("TEST PASSED (%0d checks)", checks_passed);
  else
    $display("TEST FAILED (%0d passed, %0d failed)", checks_passed, checks_failed);

  $finish;
end

endmodule
