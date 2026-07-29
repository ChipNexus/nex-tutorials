# CPU prototype timing constraints
# System clock per docs/prototype-spec.md: 60 MHz
create_clock -period 16.666 -name sys_clk [get_ports clk_i]
