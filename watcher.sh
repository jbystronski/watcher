#!/bin/bash

watcher_pid=$$
server_pid=-1
timeout=5s
delay=1


function printHelp {

    echo "Printing help"

}

function bail {
    sleep $timeout
    echo "Something went wrong, so let's quit" >&2
    exit 1
}

function setServerPid {

    pid=$(lsof -n -i :"${http_port}" | grep "LISTEN" | awk '{print $2}')
    echo "PROC $pid"
    if [[ -z $pid ]];then
        server_pid=-1
        else
        server_pid=$pid
    fi

    echo "$server_pid"
}

function runCmd {
    echo "comm $command"
    eval "$command" "$input_file"
    setServerPid
}   

function setModTime {
    currentModTime=$(stat "$input_file" | grep "Modify")
}

function killServer {
    kill "$server_pid"
    setServerPid
    if [[ "$server_pid" != -1 ]]; then
            echo "Server still running"
            echo "$server_pid"
            killServer
        else
            echo "$server_pid"
            echo "http_port $http_port clear"
    fi
}

function printStart {
  
    me=$(whoami)
    
    echo "Hi $me, a watcher now observes port $http_port"
    echo
    echo "Runtime options:"
    echo
    echo "q - for clean quit"
    echo "r - to restart the server"
    echo "h - for help"
}

function restart {
    echo "Restarting due to changes"
    killServer
    eval "$0 -f $input_file -p $http_port -c \"$command\""
    kill $watcher_pid
}

function cleanup {
    killServer
    echo "Leaving"
    exit 0
}

function checkModTime {
    setModTime
    if [[ "$currentModTime" != "$originModTime"  ]];
        then
            restart
    fi
}

while getopts 'f:p:c:d:' OPTION; do 
    case "$OPTION" in
        f)
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
        ?)
            echo "usage: $(basename $0) [-f file to observe] [-p http port ] [-c command to run the file] [-i time interval between modification checks, default is 1s]" >&2
            exit 1
            ;;
    esac
done

missing_arguments=""
wrong_arguments=0

if [[ -z $http_port ]]; then
    missing_arguments=$missing_arguments" [ -p http port ]"
    wrong_arguments=1
fi

if [[ -z $command ]]; then
    missing_arguments=$missing_arguments" [ -c command ]"
    wrong_arguments=1
fi

if [[ -z $input_file ]]; then
    missing_arguments=$missing_arguments" [ -f file ]"
    wrong_arguments=1
fi

if [[ "$wrong_arguments" -eq 1 ]];then
    echo "missing arguments $missing_arguments" >&2
    exit 1
fi

originModTime=$(stat "$input_file" | grep "Modify")
currentModTime=$originModTime


printStart

trap cleanup EXIT

runCmd &

while true 
    do
        read -rsn1 input
        if [[ $input == "q" ]];then
            cleanup
        fi
        if [[ $input == "h" ]];then
            printHelp
        fi
        if [[ $input == "r" ]];then
            restart
        fi
        sleep 2s
        checkModTime
        # bail
    done

# if [[ "$?" -ne 0 ]];then

#     echo "$?"

# fi