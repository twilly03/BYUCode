restart

# add oscillating clock input with 10ns period
add_force CLK {0 0} {1 5ns} -repeat_every 10ns

add_force CLR 0
run 10ns
add_force INC 0
run 30ns
add_force CLR 0
run 20ns
run 100 ns

add_force CLR 0
add_force INC 0
run 20ns

add_force CLR 0
add_force INC 1
run 20ns

add_force CLR 1
add_force INC 0
run 20ns

add_force CLR 1
add_force INC 1
run 20ns

add_force CLR 0
add_force INC 1
run 200ns

