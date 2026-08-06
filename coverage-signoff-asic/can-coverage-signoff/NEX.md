# CAN Controller Coverage Signoff

## Project Overview
This project targets coverage signoff for an OpenCores SJA1000-compatible CAN controller core.
- **Filelist**: `can.f`
- **Top Module**: `tb_can_basic`
- **Language**: Plain Verilog (Do not use SystemVerilog `-sverilog` flags as this is a strict Verilog project)

## Signoff Targets
To achieve coverage signoff, the following VCS/URG metrics must be met:
- **Total URG SCORE**: >= 67%
- **`can_bsp` module**: >= 72%
- **`can_acf` module**: >= 55%
- **All DUT modules**: >= 50%

## Verification Flow (VCS + URG)
1. **Compilation**: Use VCS and compile sources via the filelist (`-f can.f`). Ensure standard coverage collection is enabled (e.g., `-cm line+cond+fsm+tgl+branch`).
2. **Simulation**: Execute the compiled binary (`simv`) with coverage collection enabled (e.g., `-cm line+cond+fsm+tgl+branch`).
3. **Reporting**: Run `urg` (e.g., `urg -dir simv.vdb -format text`) to compile the coverage report.
4. **Analysis**: Use the VCS URG text report parser (via `vcs_parse_urg_report` or analyzing the generated text reports) to track progress against the signoff targets.

## Project Conventions
- **Agent Delegation**: Delegate simulation, testing, and coverage tasks to `agent_verification` using `flow="vcs"`.
- **RTL Modifications**: Only modify testbenches for coverage closure unless an RTL bug is definitively identified. Preserve the SJA1000-compatible behavior.
- **Targeted Tests**: To hit the `can_bsp` (Bit Stream Processor) and `can_acf` (Acceptance Filter) targets, write targeted stimulus in `tb_can_basic.v` based on uncovered bins in the URG reports.
