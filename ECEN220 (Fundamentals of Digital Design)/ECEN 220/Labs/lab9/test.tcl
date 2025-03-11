restart

# Start clock
add_force clk {0} {1 5} -repeat_every 10
run 10ns

# Reset design
add_force Reset 1
add_force Send 0
run 10ns
add_force Reset 0
run 10ns

# Run for some time
run 50us

# Send a byte
add_force -radix hex Din 47
add_force Send 1
run 10ns
add_force Send 0
run 1ms

# Send another byte
add_force -radix hex Din 4F
add_force Send 1
run 10ns
add_force Send 0
run 1ms
