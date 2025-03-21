#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2019.2 (64-bit)
#
# Filename    : simulate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for simulating the design by launching the simulator
#
# Generated by Vivado on Tue Nov 15 18:56:38 MST 2022
# SW Build 2708876 on Wed Nov  6 21:39:14 MST 2019
#
# Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
#
# usage: simulate.sh
#
# ****************************************************************************
set -Eeuo pipefail
echo "xsim codebreaker_serial_top_behav -key {Behavioral:sim_1:Functional:codebreaker_serial_top} -tclbatch codebreaker_serial_top.tcl -log simulate.log"
xsim codebreaker_serial_top_behav -key {Behavioral:sim_1:Functional:codebreaker_serial_top} -tclbatch codebreaker_serial_top.tcl -log simulate.log

