#!/usr/bin/env bash

for PID in $(ls /proc | grep -E '^[0-9]+$'); do

    P_PID=$(grep '^PPid:' /proc/${PID}/status | awk -F: '{print $2}')
    STATUS=$(grep '^State:' /proc/${PID}/status | awk -F: '{print $2}')
    
    if [ -z "$(tr '\0' ' ' < /proc/${PID}/cmdline 2>/dev/null)" ]; then
        COMMAND=$(grep '^Name:' /proc/${PID}/status | awk -F: '{print $2}')
    else
        COMMAND=$(tr '\0' ' ' < /proc/${PID}/cmdline)
    fi
    
    echo -e "PID = $PID\n"
    echo -e "PPID = ${P_PID}\n"
    echo -e "Status = ${STATUS}\n"
    echo -e "Command = ${COMMAND}\n"
    echo -e "----------------------\n\n"

done


