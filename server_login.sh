#!/bin/bash

PRD_SERVERS=( "wrmsintra" "wrmsrmail" "brmail101d" "bmctr" )
STG_SERVERS=( "stg-wrmintra101zd" "stg-wrmsrmail101zd" "stg-brmail101c" )
DEV_SERVERS=( "dev-wrmsintra101zd" "dev-wrmsrmail101zd" "dev-brmail101c" )

login() {

    array=("$@")
    select item in "${array[@]}"; do
       if [ "$item" == "" ]; then
           echo "please choose from above list."
       elif [ "$item" == "bmctr" ]; then
           select item in `seq -w 1 12 | awk '{print "bmctr1"$1}'`; do
               echo $item
               exit 0
           done
       elif [ "$item" == "wrmsrmail" ]; then
           select item in `seq 1 3 | awk '{print "wrmsrmail10"$1"zd"}'`; do
               echo $item
               exit 0
           done 
       fi
       echo $item
       exit 0
    done

}

main() {

    hostname="loginjp101c"

    PS3="please choose login server: "

    server_info=`echo $hostname | cut -d - -f1`
  
    case "$server_info" in
        "dev" ) login "${DEV_SERVERS[@]}" ;;
        "stg" ) login "${STG_SERVERS[@]}" ;;
        * ) login "${PRD_SERVERS[@]}" ;;
    esac     

}

main
