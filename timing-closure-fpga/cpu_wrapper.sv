// CPU integration wrapper for the SoC FPGA prototype.
// Instantiates the Ibex RISC-V core with the project's configuration.
// Parameter values inherited from the ASIC reference platform.
module cpu_wrapper import ibex_pkg::*; (
  input  logic                                                         clk_i,
  input  logic                                                         rst_ni,

  input  logic                                                         test_en_i,
  input  prim_ram_1p_pkg::ram_1p_cfg_req_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_tag_i,
  output prim_ram_1p_pkg::ram_1p_cfg_rsp_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_tag_o,
  input  prim_ram_1p_pkg::ram_1p_cfg_req_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_data_i,
  output prim_ram_1p_pkg::ram_1p_cfg_rsp_t [ibex_pkg::IC_NUM_WAYS-1:0] ram_cfg_icache_data_o,

  input  logic [31:0]                                                  hart_id_i,
  input  logic [31:0]                                                  boot_addr_i,

  output logic                                                         instr_req_o,
  input  logic                                                         instr_gnt_i,
  input  logic                                                         instr_rvalid_i,
  output logic [31:0]                                                  instr_addr_o,
  input  logic [31:0]                                                  instr_rdata_i,
  input  logic [6:0]                                                   instr_rdata_intg_i,
  input  logic                                                         instr_err_i,

  output logic                                                         data_req_o,
  input  logic                                                         data_gnt_i,
  input  logic                                                         data_rvalid_i,
  output logic                                                         data_we_o,
  output logic [3:0]                                                   data_be_o,
  output logic [31:0]                                                  data_addr_o,
  output logic [31:0]                                                  data_wdata_o,
  output logic [6:0]                                                   data_wdata_intg_o,
  input  logic [31:0]                                                  data_rdata_i,
  input  logic [6:0]                                                   data_rdata_intg_i,
  input  logic                                                         data_err_i,

  input  logic                                                         irq_software_i,
  input  logic                                                         irq_timer_i,
  input  logic                                                         irq_external_i,
  input  logic [14:0]                                                  irq_fast_i,
  input  logic                                                         irq_nm_i,

  input  logic                                                         scramble_key_valid_i,
  input  logic [SCRAMBLE_KEY_W-1:0]                                    scramble_key_i,
  input  logic [SCRAMBLE_NONCE_W-1:0]                                  scramble_nonce_i,
  output logic                                                         scramble_req_o,

  input  logic                                                         debug_req_i,
  output crash_dump_t                                                  crash_dump_o,
  output logic                                                         double_fault_seen_o,

  input  ibex_mubi_t                                                   fetch_enable_i,
  input  ibex_mubi_t                                                   mcounteren_writable_i,
  output logic                                                         alert_minor_o,
  output logic                                                         alert_major_internal_o,
  output logic                                                         alert_major_bus_o,
  output logic                                                         core_sleep_o,

  input  logic                                                         scan_rst_ni,

  output ibex_mubi_t                                                   lockstep_cmp_en_o,

  output logic                                                         data_req_shadow_o,
  output logic                                                         data_we_shadow_o,
  output logic [3:0]                                                   data_be_shadow_o,
  output logic [31:0]                                                  data_addr_shadow_o,
  output logic [31:0]                                                  data_wdata_shadow_o,
  output logic [6:0]                                                   data_wdata_intg_shadow_o,

  output logic                                                         instr_req_shadow_o,
  output logic [31:0]                                                  instr_addr_shadow_o,

  // prototype-only: debug signature of recent data-bus requests
  output logic [31:0]                                                  bus_sig_o
);

  ibex_top #(
    .PMPEnable       (1'b0),
    .RV32E           (1'b0),
    .RV32M           (RV32MFast),
    .RV32B           (RV32BNone),
    .RegFile         (RegFileFF),
    .BranchTargetALU (1'b0),
    .WritebackStage  (1'b0),
    .ICache          (1'b0),
    .BranchPredictor (1'b0),
    .SecureIbex      (1'b0)
  ) u_cpu (.*);

  // --------------------------------------------------------------------------
  // Prototype bus signature (MISR-style debug aid).
  // Keeps a ring of recent data-bus request addresses and folds the whole ring
  // into a running signature every accepted request, so post-mortem software
  // can identify the access pattern that led to a hang.
  // --------------------------------------------------------------------------
  localparam int unsigned SigDepth = 8;

  logic [SigDepth-1:0][31:0]   hist_q;
  logic [$clog2(SigDepth)-1:0] ptr_q;
  logic [31:0]                 sig_q, sig_d;

  always_comb begin
    sig_d = data_addr_o;
    for (int unsigned i = 0; i < SigDepth; i++) begin
      sig_d = {sig_d[30:0], sig_d[31]} + (hist_q[i] ^ sig_d);
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      hist_q <= '0;
      ptr_q  <= '0;
      sig_q  <= '0;
    end else if (data_req_o && data_gnt_i) begin
      hist_q[ptr_q] <= data_addr_o;
      ptr_q         <= ptr_q + 1'b1;
      sig_q         <= sig_d;
    end
  end

  assign bus_sig_o = sig_q;

endmodule
