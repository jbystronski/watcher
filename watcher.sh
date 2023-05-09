#!/bin/bash

delay=2
p0=$$
p1=0
p2=0
originModTime=""
bulkModTime=""
usage="usage: $(basename $0) [ -e entry file] [ -p http port ] [ -c command to start the server, inside double quoutes e.g \"npm run\" \"node\" \"go run\" ] [ -w files / folders to watch for changes \"first second third ...\", if not present only the entry file will be watched ] [ -d delay in seconds between consecutive checks, default is 2] [ -l optional path to error log file, will be created if doesn't exist ]"

set -m

function printOptions {
    printf '
    Runtime options:
    
    o)  print available options
    r)  restart server
    p)  show running processes
    c)  clear terminal output
    l)  read the log file, if specified
    t)  empty the log file (truncate to 0)
    u)  show usage 
    q)  quit and terminate running processes
    \r
    '
}

function runCmd {
    streamToLog=""
    if [[ -n $logFile ]];then
        mkdir -p "${logFile%/*}" && touch "$logFile"
        streamToLog="2> >( tee -a $logFile )"
    fi
    eval "$command $input_file $streamToLog"
}

function getServerPid {
    id=$(lsof -n -i :"${http_port}" | grep "LISTEN" | awk '{print $2}')
    if [[ -z $id ]];then
    id=$(fuser -n tcp $http_port 2>/dev/null | awk '{print $1}')
    fi 
     if [[ -z $id ]];then
    id=$(fuser $http_port/tcp)
    fi
    echo $id
}

function killServer {   
    kill -9 "$(getServerPid)" 2> /dev/null
    echo "Stopping process at port $http_port"
}

function printStart {
    me=$(whoami) 
    echo "Hi $me, watcher now observes port $http_port"
    echo
    printOptions
}

function cleanup {
    kill -9 $p2
    killServer
    kill -9 $p1   
}

function quit {
    cleanup
    echo "Leaving"
    exit 0
}

function restart {
    killServer 
    runCmd &
    p1=$!
    
    printf "\n"
    printf "Restart"
    printf "\n"
}

function scanFiles {
    found=$(find $input_file $files_to_watch 2> /dev/null)
    bulkModTime=$(stat $found | grep "Modify")   
}

function checkModTime {
    scanFiles
    if [[ "$originModTime" != "$bulkModTime"  ]];
        then
            originModTime=$bulkModTime
            restart
    fi
}

function showProcesses {
    echo
    echo "    Running processes:"
    echo "    $p0"
    echo "    $p1"
    echo "    $p2"
    echo "    $(getServerPid) on port $http_port"
    echo
}

while getopts 'w:e:p:c:d:l:' OPTION; do 
    case "$OPTION" in
        w)
            files_to_watch=$OPTARG
            ;;
        e)
            input_file=$OPTARG
            ;;
        p)
            http_port=$OPTARG
            ;;
        c)
            command=$OPTARG
            ;;
        d) 
            delay=$OPTARG
            ;;
        l)
            logFile=$OPTARG
            ;;
        ?)
            echo "$usage" >&2
            exit 1
            ;;
    esac
done

missing_arguments=""
wrong_arguments=0
if [[ -z $input_file ]]; then
    missing_arguments=$missing_arguments" [ -e entry file ]"
    wrong_arguments=1
fi

if [[ -z $http_port ]]; then
    missing_arguments=$missing_arguments" [ -p http port ]"
    wrong_arguments=1
fi

if [[ -z $command ]]; then
    missing_arguments=$missing_arguments" [ -c command ]"
    wrong_arguments=1
fi

if [[ "$wrong_arguments" -eq 1 ]];then
    echo "missing arguments $missing_arguments" >&2
    exit 1
fi

scanFiles

originModTime=$bulkModTime

trap quit EXIT

printStart

runCmd &

p1=$!

while true  
    do
        sleep $delay
        checkModTime
    done &

p2=$!
getServerPid

while true 
    do
        if read -rsn1 input; then
            case $input in
                q)
                    exit 0
                ;;
                o)
                    printOptions
                ;;
                r)
                    restart
                ;;
                c)
                    clear
                ;;
                p)
                    showProcesses
                ;;
                l)
                    if [[ -n $logFile ]];then
                        cat $logFile
                    else
                        echo "Log file not specified"
                    fi
                ;;
                t)
                     if [[ -n $logFile ]];then
                        truncate -s 0 $logFile
                        echo "log file emptied"
                    else
                        echo "Log file not specified"
                    fi
                ;;
                u)
                    echo "$usage"
                ;;
            esac   
        fi     
    done