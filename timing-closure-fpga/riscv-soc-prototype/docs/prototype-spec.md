# CPU FPGA Prototype — Specification (rev B)

## Platform
- Device: AMD Artix-7 `xc7a100tfgg484-1`
- Synthesis top: `fpga_top` (prototype harness; 4 external pins)

## Clocking
- `clk_i`: **60 MHz** system clock. This is the only frequency requirement for the
  prototype; production ASIC clock targets do not apply to this platform.

## Debug features
- The bus debug signature (`bus_sig_o` logic in `cpu_wrapper.sv`) is prototype-only debug
  logic. Its value may lag the observed bus by **up to four clock cycles**; the post-mortem
  software that reads it tolerates this latency.

## Harness IO
- `ser_in` / `ser_out` are low-speed debug pins driven and sampled asynchronously by the
  bench. They carry no cycle-accurate external timing requirement.

## Timing signoff
- Setup and hold met at 60 MHz, post-route.
- The timing report must be trustworthy: no outstanding timing-methodology issues
  (e.g. unconstrained IO) that would undermine the report's validity.
