restart

add_force clk {0 0} {1 5ns} -repeat_every 10ns
run 400ns

add_force btnu 0
add_force btnc 0
run 5ns

add_force btnc 1
run 5ns


