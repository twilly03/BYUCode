restart

# Simulate A=0, B=0, C=0 for 10 ns
add_force A 0
add_force B 0
add_force C 0
run 10 ns

# Simulate A=0, B=0, C=1 for 10 ns
add_force A 0
add_force B 0
add_force C 1
run 10 ns

# Simulate A=0, B=1, C=0 for 10 ns
add_force A 0
add_force B 1
add_force C 0
run 10 ns

# Simulate A=1, B=0, C=0 for 10 ns
add_force A 1
add_force B 0
add_force C 0
run 10 ns

# Simulate A=0, B=1, C=1 for 10 ns
add_force A 0
add_force B 1
add_force C 1
run 10 ns

# Simulate A=1, B=1, C=0 for 10 ns
add_force A 1
add_force B 1
add_force C 0
run 10 ns

# Simulate A=1, B=0, C=1 for 10 ns
add_force A 0
add_force B 1
add_force C 0
run 10 ns

# Simulate A=1, B=1, C=1 for 10 ns
add_force A 1
add_force B 1
add_force C 1
run 10 ns


