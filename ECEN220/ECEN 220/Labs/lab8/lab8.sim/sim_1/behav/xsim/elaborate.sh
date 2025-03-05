#!/bin/bash -f
# ****************************************************************************
# Vivado (TM) v2019.2 (64-bit)
#
# Filename    : elaborate.sh
# Simulator   : Xilinx Vivado Simulator
# Description : Script for elaborating the compiled design
#
# Generated by Vivado on Tue Nov 01 18:59:06 MDT 2022
# SW Build 2708876 on Wed Nov  6 21:39:14 MST 2019
#
# Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
#
# usage: elaborate.sh
#
# ****************************************************************************
set -Eeuo pipefail
echo "xelab -wto 45828138c504418fb6d0bc2aaa2c4a2e --incr --debug typical --relax --mt 8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot debounce_top_behav xil_defaultlib.debounce_top xil_defaultlib.glbl -log elaborate.log"
xelab -wto 45828138c504418fb6d0bc2aaa2c4a2e --incr --debug typical --relax --mt 8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot debounce_top_behav xil_defaultlib.debounce_top xil_defaultlib.glbl -log elaborate.log

