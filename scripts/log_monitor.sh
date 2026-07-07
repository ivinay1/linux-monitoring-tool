#!/bin/bash

#check if config file either exists
if [ -f "config/config.env" ] 
then
    source config/config.env
    
    if [ ! -f "state/last_scan.txt" ]
    then
	mkdir state
        touch state/last_scan.txt
	echo 'LastProcessed=0' > state/last_scan.txt
    fi
        echo "Configuration Loaded Successsfully"
        echo "State file Loaded Successfully"

        if [ -z "$LOG_FILE" ]
        then    
         echo "ERROR: '$LOG_FILE' is not configured"
        exit 1
        else
         if [ -f "$LOG_FILE" ]
         then
             echo "Log File Found"
             echo "Ready To Scan..."

            TOTAL_NO_RECORDS=$(wc -l $LOG_FILE | awk '{print $1}')

	    TOTAL_RECORDS_TO_BE_SCANNED=$((TOTAL_NO_RECORDS - LastProcessed))
		
	    RECORDS_TO_BE_SCANNED=$(tail -n $TOTAL_RECORDS_TO_BE_SCANNED $LOG_FILE) 

	    VALUE_TO_BE_UPDATED=$((LastProcessed + TOTAL_RECORDS_TO_BE_SCANNED))

            sed -i "s/LastProcessed=$LastProcessed/LastProcessed=$VALUE_TO_BE_UPDATED/" state/last_scan.txt 

            ERROR_COUNT=$(echo "$RECORDS_TO_BE_SCANNED" | grep -ic "ERROR" )
            INFO_COUNT=$(echo "$RECORDS_TO_BE_SCANNED" | grep -ic "INFO" )
            WARNING_COUNT=$(echo "$RECORDS_TO_BE_SCANNED" | grep -ic "WARNING" )

            
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
            
            
	    ERROR_INFO=$(echo "$RECORDS_TO_BE_SCANNED" | grep -i "ERROR" | awk '{$1=$2=$3=$4=""}1' | sort -u | nl)

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
