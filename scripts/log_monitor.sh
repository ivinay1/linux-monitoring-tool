#!/bin/bash

#check if config file either exists
if [ -f "config/config.env" ]
then
    source config/config.env

    echo "Configuration Loaded Successsfully"
    
    if [ -z "$LOG_FILE" ]
    then    
        echo "ERROR: '$LOG_FILE' is not configured"
        exit 1
    else
        if [ -f "$LOG_FILE" ]
        then
            echo "Log File Found"
            echo "Ready To Scan..."

            ERROR_COUNT=$(grep -ic "ERROR" $LOG_FILE)
            INFO_COUNT=$(grep -ic "INFO" $LOG_FILE)
            WARNING_COUNT=$(grep -ic "WARNING" $LOG_FILE)

            STATUS="OK"
            if [ $ERROR_COUNT -gt 0 ]
            then
                STATUS="ALERT"
            elif [ $WARNING_COUNT -gt 0 ]
            then
                STATUS="WARNING"
            else 
                STATUS="OK"
            fi
            
	    ERROR_INFO=$(grep -i "ERROR" $LOG_FILE | awk '{$1=$2=$3=$4=""}1' | sort -u | nl)

            ERROR_INFO_STATUS=$?

	    if [ $ERROR_INFO_STATUS -eq 1 ]
            then
	      ERROR_INFO="no errors found"
	    fi

            echo "====================Linux Monitor Report======================"
            echo "Log File        :   $LOG_FILE                                "
            echo "                                                              "
            echo "INFO Count      :   $INFO_COUNT                              "
            echo "WARNING COUNT   :   $WARNING_COUNT                           "
            echo "ERROR Count     :   $ERROR_COUNT                             "
            echo "Status          :   $STATUS                                  "
	    echo "                                                             "
	    echo "----------------------------ERRORS---------------------------"
            echo "$ERROR_INFO"                     
            echo "============================================================="
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
