#!/bin/bash

loadingConfigurations(){

source config/config.env
echo "Confirguration loaded sucessfully"

}


loadingState(){

source $STATE_FILE
echo "State File loaded sucessfully"

}


validatingLogFile(){

  if [ -n "$LOG_FILE" ]
  then
      echo "ERROR: LOG FILE is not configured"
  fi


  if [ -f "$LOG_FILE" ]
  then
     echo "Log File Found"
     echo "Ready to scan"
   else
       echo "Unable to find Log File"
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
        echo "ERROR: unable to create state file"
        exit 1
    fi
   
    echo "LastProcessed=0" > "$STATE_FILE" 
    echo "STATE FILE CREATED"
    
    # immediate checking file existence
}


validatingStateFile(){

   if [ ! -z "$STATE_FILE" ]
   then  
	   echo "STATE FILE variable found"
	   echo "Validating STATE FILE"

	   if [ -f "$STATE_FILE" ]
           then 
		 echo "Validated STATE FILE"
	   else
		   echo "INVALID STATE FILE"
		   echo "CREATING STATE FILE"
                   stateFileCreation
	   fi
   else
	   echo "ERROR: STATE FILE NOT CONFIGURED"
           exit 1 
   fi	   
}


logsScanning(){

  
            TOTAL_NO_RECORDS=$(wc -l $LOG_FILE | awk '{print $1}')

            # checking log rotation
            if [ $TOTAL_NO_RECORDS -lt $LastProcessed ]
            then
		 echo "logs has been rotated or truncated"
		 LastProcessed=0
            fi 


	    TOTAL_RECORDS_TO_BE_SCANNED=$((TOTAL_NO_RECORDS - LastProcessed))
	

            if [ $TOTAL_RECORDS_TO_BE_SCANNED -eq 0 ]
            then
		 echo "No New LOGS are available for scanning"
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
}


updateState(){

            sed -i "s/LastProcessed=$LastProcessed/LastProcessed=$VALUE_TO_BE_UPDATED/" state/last_scan.txt 
}

main(){

loadingConfigurations

loadingState

validatingLogFile

validatingStateFile

logsScanning

generateReport

updateState

}

main
