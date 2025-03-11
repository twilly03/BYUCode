#!/bin/bash

path_to_repo="/fsg/twillis0/ECEN433/lab-1-and-2-twilly03"

if [ "$1" == "lab1" ]; then
    lab_specific_launcher="launcher-lab1"
    lab_text_file="lab1.txt"
    gedit $path_to_repo/assignments/$lab_text_file &
elif [ "$1" == "lab2" ]; then
    lab_specific_launcher="launcher-lab2"
    lab_text_file="lab2.txt"
    gedit $path_to_repo/assignments/$lab_text_file &
else
    echo "Incorrect lab number"
    exit 0
fi

cd $path_to_repo

dts devel run -X -L $lab_specific_launcher
