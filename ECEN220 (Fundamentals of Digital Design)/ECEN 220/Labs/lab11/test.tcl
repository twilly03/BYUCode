restart

add_force clk {0 0} {1 5ns} -repeat_every 10ns
run 400ns

add_force Reset 1
run 100ns

add_force Reset 0
add_force Sin 1
run 500ns

add_force Sin 0
run 52083ns

add_force Sin 0
run 52083ns

add_force Sin 1
run 52083ns

add_force Sin 0
run 52083ns

add_force Sin 1
run 52083ns

add_force Sin 0
run 52083ns

add_force Sin 1
run 52083ns

add_force Sin 1
run 52083ns

add_force Sin 1
run 52083ns

add_force Sin 0
run 52083ns

add_force Sin 1
run 52083ns

add_force Received 1
run 100ns