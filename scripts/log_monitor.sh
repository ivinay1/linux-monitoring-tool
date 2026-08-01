#!/bin/bash

getStateFile(){
 
   updatedName=$(echo "$1" | sed 's#/#_#g' | sed 's#.#_#g')
   
   if [ ! -f state/$updatedName ] 
   then 
      touch state/$updatedName 
      echo "last_scan=0" > state/$updatedName 
   fi

 echo "state/$updatedName"
}

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

source config/config.env  || {

logError "unable to load configuration file"
exit 1

}

logInfo " Confirguration loaded sucessfully"
}


loadingState(){

source $1
logInfo "state File loaded sucessfully"
}


LOCK_FILE="/tmp/log_monitor.lock"

exec 200>"$LOCK_FILE"

flock -n 200 || {

logWarning "Another instance is already running.Exiting"
exit 1

}



validatingLogFile(){

  if [ -z "$1" ]
  then
     logError "ERROR: LOG FILE is not configured"
      return 1
  fi


  if [ -f "$1" ]
  then
          logInfo "Log File Found"
	  logInfo "Ready To Scan"
   else
          logError "Unable to find Log File"
           return 1
   fi
}


stateFileCreation(){

    # extract parent directory
    parentDir=$(dirname "$STATE_FILE")
    
    mkdir -p "$parentDir"    

    touch "$STATE_FILE" || {

      logError "stateFile creation failed"
      return 1

    }
    
    if [ ! -f "$STATE_FILE" ]
    then
	    logError " ERROR: unable to create state file" 
            return 1
    fi
   
    echo "LastProcessed=0" > "$STATE_FILE" 
    logInfo " STATE FILE CREATED"     
}


validatingStateFile(){

   if [ ! -z "$1" ]
   then  
          logInfo " STATE FILE variable found"
          logInfo " validating STATE FILE"

	   if [ -f "$1" ]
           then 
                  logInfo " validating STATE FILE"
	   else	   
                  logInfo " INVALID STATE FILE"
                  logInfo " CREATING STATE FILE"
                   stateFileCreation
	   fi
   else
           logError " ERROR: STATE FILE NOT CONFIGURED"
           return 1 
   fi	   
}


logsScanning(){

  
            TOTAL_NO_RECORDS=$(wc -l "$1" | awk '{print $1}')

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
		    return 0
            fi


	    RECORDS_TO_BE_SCANNED=$(tail -n "$TOTAL_RECORDS_TO_BE_SCANNED" "$1") 

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


	    if [ -z "$ERROR_INFO"  ]
            then
	      ERROR_INFO="no errors found"
	    fi

	    echo "======================Linux Monitor Report======================" >> $MONITOR_LOG
	    echo " Log File         :   $1                                        " >> $MONITOR_LOG
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

            sed -i "s/LastProcessed=$LastProcessed/LastProcessed=$VALUE_TO_BE_UPDATED/" $1 
            logInfo "updated state file"
}

main(){

scriptDir="$( dirname "${BASH_SOURCE[0]}" )"

targetDir="$scriptDir/.."

cd $targetDir

loadingConfigurations

for logFile in "${LOG_FILES[@]}"
do 
  validatingLogFile $logFile
 
  STATUS_VALIDATION= $?

  if [ $STATUS_VALIDATION -eq 1 ]
  then
     continue 
  fi

  stateFile=$(getStateFile $logFile)
  loadingState $stateFile
  validatingStateFile $stateFile
  logsScanning $logFile
  generateReport $logFile
  updateState $stateFile
done

exit 0
}

main


