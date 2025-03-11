
#!/bin/bash
# ==============================================================================
# Script Name: dt_sd_card_fix.sh
# Author: Derek Benham
# Date: 2024-08-20
# Description:
#   Shell script to fix sudo access check when burning duckietown sd card.
#
# Usage:
#   bash dt_sd_card_fix.sh
#
# ==============================================================================
cd ~
echo "Editing Duckietown file"
file_path=".duckietown/shell/profiles/daffy/commands/duckietown/init_sd_card/command.py"

# Line 30 import fix
line_number=30  
new_content="from utils.misc_utils import human_time" 
sed -i "${line_number}s/.*/${new_content}/" "${file_path}"


# Line 449 remove sudo dependency check
line_number=449  
new_content="    # check_program_dependency(\"sudo\")"
sed -i "${line_number}s/.*/${new_content}/" "${file_path}"


# Line 547 remove sudo from command line
line_number=547  
new_content="    dd_cmd = ([] if sd_type == \"SD\" else []) + ["
sed -i "${line_number}s/.*/${new_content}/" "${file_path}"


# Line 573 remove sudo open
line_number=573
new_content="            with open(parsed.device, \"rb\") as destination:"
sed -i "${line_number}s/.*/${new_content}/" "${file_path}"


# Line 609 remove sudo dependency check
line_number=609
new_content="    #check_program_dependency(\"sudo\")"
sed -i "${line_number}s/.*/${new_content}/" "${file_path}"


# Line 695 remove sudo from command line
line_number=695
new_content="        dd_cmd = ([] if data.get(\"sd_type\", \"SD\") == \"SD\" else []) + ["
sed -i "${line_number}s/.*/${new_content}/" "${file_path}"
echo "Done"
