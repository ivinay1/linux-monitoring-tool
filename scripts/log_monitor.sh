#!/bin/bash

#check if config file either exists
if [ -f "config/config.env" ]
then
    source config/config.env

    echo "Configuration Loaded Successsfully"
    
    if [ -z "$LOG_FILE"]
    then    
        echo "ERROR: '$LOG_FILE' is not configured"
        exit 1
    else
        if [ -f "$LOG_FILE"]
        then
            echo "Log File Found"
            echo "Ready To Scan..."
        
            exit 0
        else
            echo "ERROR: Log File '$LOG_FILE' not found"
            exit 1
        fi
    fi
else
    echo "ERROR: Configuration file 'config/config.env' not found"
    exit 1
fi