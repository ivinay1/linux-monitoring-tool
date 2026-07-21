#!/bin/bash



logInfo(){

echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> $MONITOR_EXECUTION_LOG

}

logWarning(){

echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> $MONITOR_EXECUTION_LOG

}

logError(){

echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> $MONITOR_EXECUTION_LOG

}


loadingConfigurations(){

source config/config.env
logInfo " Confirguration loaded sucessfully"
}


loadingState(){

source $STATE_FILE
logInfo "state File loaded sucessfully"
}


LOCK_FILE="/tmp/log_monitor.lock"

exec 200>"$LOCK_FILE"

flock -n 200 || {

logWarning "Another instance is already running.Exiting"
exit 1

}



validatingLogFile(){

  if [ -z "$LOG_FILE" ]
  then
     logError "ERROR: LOG FILE is not configured"
      exit 1
  fi


  if [ -f "$LOG_FILE" ]
  then
          logInfo "Log File Found"
	  logInfo "Ready To Scan"
   else
          logError "Unable to find Log File"
           exit 1
   fi
}


stateFileCreation(){

    # extract parent directory
    parentDir=$(dirname "$STATE_FILE")
    
    mkdir -p "$parentDir"    

    touch "$STATE_FILE"
    
    if [ ! -f "$STATE_FILE" ]
    then
	    logError " ERROR: unable to create state file" 
            exit 1
    fi
   
    echo "LastProcessed=0" > "$STATE_FILE" 
    logInfo " STATE FILE CREATED"     
}


validatingStateFile(){

   if [ ! -z "$STATE_FILE" ]
   then  
          logInfo " STATE FILE variable found"
          logInfo " validating STATE FILE"

	   if [ -f "$STATE_FILE" ]
           then 
                  logInfo " validating STATE FILE"
	   else	   
                  logInfo " INVALID STATE FILE"
                  logInfo " CREATING STATE FILE"
                   stateFileCreation
	   fi
   else
           logError " ERROR: STATE FILE NOT CONFIGURED"
           exit 1 
   fi	   
}


logsScanning(){

  
            TOTAL_NO_RECORDS=$(wc -l $LOG_FILE | awk '{print $1}')

            # checking log rotation
            if [ $TOTAL_NO_RECORDS -lt $LastProcessed ]
            then
		    logInfo "logs has been rotated or truncated"
		    LastProcessed=0
            fi 


	    TOTAL_RECORDS_TO_BE_SCANNED=$((TOTAL_NO_RECORDS - LastProcessed))
	

            if [ $TOTAL_RECORDS_TO_BE_SCANNED -eq 0 ]
            then
		    logInfo "No New LOGS are available for scanning"
		    exit 0
            fi


	    RECORDS_TO_BE_SCANNED=$(tail -n $TOTAL_RECORDS_TO_BE_SCANNED $LOG_FILE) 

	    VALUE_TO_BE_UPDATED=$((LastProcessed + TOTAL_RECORDS_TO_BE_SCANNED))

}


generateReport(){


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

	    echo "======================Linux Monitor Report======================" >> $MONITOR_LOG
	    echo " Log File         :   $LOG_FILE                                 " >> $MONITOR_LOG
	    echo "                                                                " >> $MONITOR_LOG
	    echo " INFO Count       :   $INFO_COUNT                               " >> $MONITOR_LOG
	    echo " WARNING COUNT    :   $WARNING_COUNT                            " >> $MONITOR_LOG
	    echo " ERROR Count      :   $ERROR_COUNT                              " >> $MONITOR_LOG
	    echo " Status           :   $STATUS                                   " >> $MONITOR_LOG
	    echo "                                                                " >> $MONITOR_LOG
	    echo "------------------------------ERRORS----------------------------" >> $MONITOR_LOG
	    echo "$ERROR_INFO" >> $MONITOR_LOG   
	    echo "================================================================" >> $MONITOR_LOG 
	    echo "                                                                " >> $MONITOR_LOG
       	   
}


updateState(){

            sed -i "s/LastProcessed=$LastProcessed/LastProcessed=$VALUE_TO_BE_UPDATED/" state/last_scan.txt 
            logInfo "updated state file"
}

main(){

scriptDir="$( dirname "${BASH_SOURCE[0]}" )"

targetDir="$scriptDir/.."

cd $targetDir

loadingConfigurations

loadingState

validatingLogFile

validatingStateFile

logsScanning

generateReport

updateState
exit 0
}

main
