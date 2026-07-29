# CPU FPGA prototype — working rules

- The project specification in `docs/prototype-spec.md` is **authoritative** for all
  requirements (clocking, latency budgets, signoff criteria). Consult it before making
  engineering decisions.
- Use the Vivado MCP tools for all project, synthesis, implementation, and reporting steps.
- `rtl_staging/ibex_*.sv` and `rtl_staging/prim_*.sv` are third-party IP: **do not modify
  them**. Changes belong in `cpu_wrapper.sv`, `fpga_top.sv`, or the constraints.
- Vivado projects go under `build/` — never inside `rtl_staging/`.
- After every RTL or constraint change, re-run synthesis and implementation and report the
  post-route worst negative slack (WNS) before drawing conclusions.
- Summarize timing results as: target, WNS, achieved fmax, critical path (start → end).
