#!/bin/bash

path_to_repo="/fsg/twillis0/ECEN433/lane-following-stack-sons"

if [ "$1" == "lab4_masking" ]; then
    lab_specific_launcher="launcher-masking"
elif [ "$1" == "lab4_lines" ]; then
    lab_specific_launcher="launcher-lines"
elif [ "$1" == "lab5_pid" ]; then
    lab_specific_launcher="launcher-pid"
else
    echo "Incorrect lab number"
    exit 0
fi

cd $path_to_repo

dts devel run -X -L $lab_specific_launcher
