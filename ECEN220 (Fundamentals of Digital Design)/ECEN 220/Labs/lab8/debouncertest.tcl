restart

add_force clk {0 0} {1 5ns} -repeat_every 10ns
#set default
add_force btnu 0
add_force btnc 0
run 5ms
#reset push
add_force btnu 1
run 5ms
#reset let go
add_force btnu 0
run 5ms
#button push
add_force btnc 1
run 6ms
#button let go
add_force btnc 0
run 1ms
#button push
add_force btnu 1
run 5ms
#button let go
add_force btnu 0
run 1ms
#button push
add_force btnc 1
run 6ms
#button let go
add_force btnc 0
run 1ms
#button push
add_force btnc 1
run 2ms
#button let go
add_force btnc 0
run 1ms
#button push
add_force btnc 1
run 2ms
#button let go
add_force btnc 0
run 1ms
#button push
add_force btnc 1
run 2ms
#button let go
add_force btnc 0
run 1ms

