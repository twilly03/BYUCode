restart
#add oscillating clock
add_force clk {0 0} {1 5ns} -repeat_every 10ns

#set inputs low
add_force reset 1
add_force noisy 0
run 10ns

#short time with no debounce
add_force reset 0
add_force noisy 1
run 1ms
add_force noisy 0
run 1ms
add_force noisy 1
run 1ms
add_force noisy 0
run 1ms
add_force noisy 1
run 1ms
add_force noisy 0
run 2ms

#load a 0
add_force noisy 1
run 6ms

#long time with debounce
add_force noisy 0
run 1ms
add_force noisy 1
run 1ms
add_force noisy 0
run 1ms
add_force noisy 1
run 1ms
add_force noisy 0
run 1ms
add_force noisy 1
run 1ms

