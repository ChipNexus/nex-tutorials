// FPGA prototype harness for timing the CPU macro standalone.
// Static configuration inputs are tied off exactly as the SoC will tie them;
// dynamic inputs arrive through a serial shift chain and outputs are
// XOR-compressed, so the harness needs only 4 pins in any package while the
// CPU-internal timing paths remain the real ones.
module fpga_top import ibex_pkg::*; (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic ser_in,
  output logic ser_out
);

  // ---- dynamic input shift chain ----------------------------------------
  localparam int unsigned InstrInW = 1 + 1 + 32 + 7 + 1;       // gnt, rvalid, rdata, intg, err
  localparam int unsigned DataInW  = 1 + 1 + 32 + 7 + 1;       // gnt, rvalid, rdata, intg, err
  localparam int unsigned IrqInW   = 3 + 15 + 1;               // sw/timer/ext, fast, nm
  localparam int unsigned CtrlInW  = 1 + 4 + 4;                // debug_req, fetch_enable, mcounteren
  localparam int unsigned InW      = InstrInW + DataInW + IrqInW + CtrlInW;

  logic [InW-1:0] in_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) in_q <= '0;
    else         in_q <= {in_q[InW-2:0], ser_in};
  end

  logic        instr_gnt, instr_rvalid, instr_err;
  logic [31:0] instr_rdata;
  logic [6:0]  instr_rdata_intg;
  logic        data_gnt, data_rvalid, data_err;
  logic [31:0] data_rdata;
  logic [6:0]  data_rdata_intg;
  logic        irq_software, irq_timer, irq_external, irq_nm;
  logic [14:0] irq_fast;
  logic        debug_req;
  logic [3:0]  fetch_enable_raw, mcounteren_raw;

  assign {instr_gnt, instr_rvalid, instr_rdata, instr_rdata_intg, instr_err,
          data_gnt, data_rvalid, data_rdata, data_rdata_intg, data_err,
          irq_software, irq_timer, irq_external, irq_fast, irq_nm,
          debug_req, fetch_enable_raw, mcounteren_raw} = in_q;

  // ---- CPU outputs -------------------------------------------------------
  logic        instr_req;
  logic [31:0] instr_addr;
  logic        data_req, data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr, data_wdata;
  logic [6:0]  data_wdata_intg;
  logic        scramble_req;
  crash_dump_t crash_dump;
  logic        double_fault_seen;
  logic        alert_minor, alert_major_internal, alert_major_bus, core_sleep;
  ibex_mubi_t  lockstep_cmp_en;
  logic        data_req_shadow, data_we_shadow;
  logic [3:0]  data_be_shadow;
  logic [31:0] data_addr_shadow, data_wdata_shadow;
  logic [6:0]  data_wdata_intg_shadow;
  logic        instr_req_shadow;
  logic [31:0] instr_addr_shadow;
  logic [31:0] bus_sig;
  prim_ram_1p_pkg::ram_1p_cfg_rsp_t [IC_NUM_WAYS-1:0] ram_cfg_tag_rsp, ram_cfg_data_rsp;

  cpu_wrapper u_cpu_wrapper (
    .clk_i                 (clk_i),
    .rst_ni                (rst_ni),

    // static ties, as in the SoC integration
    .test_en_i             (1'b0),
    .ram_cfg_icache_tag_i  ('0),
    .ram_cfg_icache_tag_o  (ram_cfg_tag_rsp),
    .ram_cfg_icache_data_i ('0),
    .ram_cfg_icache_data_o (ram_cfg_data_rsp),
    .hart_id_i             (32'd0),
    .boot_addr_i           (32'h0010_0000),
    .scramble_key_valid_i  (1'b0),
    .scramble_key_i        ('0),
    .scramble_nonce_i      ('0),
    .scan_rst_ni           (1'b1),

    // dynamic inputs from the shift chain
    .instr_gnt_i           (instr_gnt),
    .instr_rvalid_i        (instr_rvalid),
    .instr_rdata_i         (instr_rdata),
    .instr_rdata_intg_i    (instr_rdata_intg),
    .instr_err_i           (instr_err),
    .data_gnt_i            (data_gnt),
    .data_rvalid_i         (data_rvalid),
    .data_rdata_i          (data_rdata),
    .data_rdata_intg_i     (data_rdata_intg),
    .data_err_i            (data_err),
    .irq_software_i        (irq_software),
    .irq_timer_i           (irq_timer),
    .irq_external_i        (irq_external),
    .irq_fast_i            (irq_fast),
    .irq_nm_i              (irq_nm),
    .debug_req_i           (debug_req),
    .fetch_enable_i        (ibex_mubi_t'(fetch_enable_raw)),
    .mcounteren_writable_i (ibex_mubi_t'(mcounteren_raw)),

    // outputs
    .instr_req_o           (instr_req),
    .instr_addr_o          (instr_addr),
    .data_req_o            (data_req),
    .data_we_o             (data_we),
    .data_be_o             (data_be),
    .data_addr_o           (data_addr),
    .data_wdata_o          (data_wdata),
    .data_wdata_intg_o     (data_wdata_intg),
    .scramble_req_o        (scramble_req),
    .crash_dump_o          (crash_dump),
    .double_fault_seen_o   (double_fault_seen),
    .alert_minor_o         (alert_minor),
    .alert_major_internal_o(alert_major_internal),
    .alert_major_bus_o     (alert_major_bus),
    .core_sleep_o          (core_sleep),
    .lockstep_cmp_en_o     (lockstep_cmp_en),
    .data_req_shadow_o     (data_req_shadow),
    .data_we_shadow_o      (data_we_shadow),
    .data_be_shadow_o      (data_be_shadow),
    .data_addr_shadow_o    (data_addr_shadow),
    .data_wdata_shadow_o   (data_wdata_shadow),
    .data_wdata_intg_shadow_o (data_wdata_intg_shadow),
    .instr_req_shadow_o    (instr_req_shadow),
    .instr_addr_shadow_o   (instr_addr_shadow),
    .bus_sig_o             (bus_sig)
  );

  // ---- output compression ------------------------------------------------
  // Boundary registers first, then XOR-reduce the registered copy, so the
  // compressor never appears in the CPU's timing paths.
  localparam int unsigned OutW = $bits({instr_req, instr_addr, data_req, data_we,
      data_be, data_addr, data_wdata, data_wdata_intg, scramble_req, crash_dump,
      double_fault_seen, alert_minor, alert_major_internal, alert_major_bus,
      core_sleep, lockstep_cmp_en, data_req_shadow, data_we_shadow, data_be_shadow,
      data_addr_shadow, data_wdata_shadow, data_wdata_intg_shadow,
      instr_req_shadow, instr_addr_shadow, bus_sig, ram_cfg_tag_rsp, ram_cfg_data_rsp});

  logic [OutW-1:0] out_bnd_q;
  logic            out_xor_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      out_bnd_q <= '0;
      out_xor_q <= 1'b0;
    end else begin
      out_bnd_q <= {instr_req, instr_addr, data_req, data_we, data_be,
                    data_addr, data_wdata, data_wdata_intg, scramble_req,
                    crash_dump, double_fault_seen,
                    alert_minor, alert_major_internal, alert_major_bus,
                    core_sleep, lockstep_cmp_en,
                    data_req_shadow, data_we_shadow, data_be_shadow,
                    data_addr_shadow, data_wdata_shadow, data_wdata_intg_shadow,
                    instr_req_shadow, instr_addr_shadow, bus_sig,
                    ram_cfg_tag_rsp, ram_cfg_data_rsp};
      out_xor_q <= ^out_bnd_q;
    end
  end
  assign ser_out = out_xor_q;

endmodule
