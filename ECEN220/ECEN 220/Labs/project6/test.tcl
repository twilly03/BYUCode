restart
add_force clk {0 0} {1 500000ns} -repeat_every 1000000ns

add_force reset 1
add_force run 0
run 10000000ns 


## test if increment works
add_force reset 0
add_force run 1
run 100000000ns 

## test if reset works
add_force reset 1
add_force run 0
run 1000000ns

## test if reset takes precedence
add_force run 1
run 1000000ns

## test if rolling over works
add_force reset 0
add_force run 1
run 160ns



