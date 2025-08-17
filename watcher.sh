
#!/bin/bash

# ----------------------------
# Configurable defaults
# ----------------------------
delay=2
input_file=""
files_to_watch=()
http_port=""
command=""
logFile=""

usage="Usage: $(basename "$0") -e entry_file -p http_port -c \"command\" [-w \"file1 file2 ...\"] [-d delay] [-l log_file]"

# ----------------------------
# Utility functions
# ----------------------------

print_options() {
    cat <<EOF

Runtime options:
o) Print available options
r) Restart server
p) Show running processes
c) Clear terminal
l) Read log file
t) Empty log file
u) Show usage
q) Quit and terminate processes

EOF
}

# Run the server command safely
run_cmd() {
    if [[ -n "$logFile" ]]; then
        mkdir -p "$(dirname "$logFile")"
        touch "$logFile"
        "$command" "$input_file" &> >(tee -a "$logFile") &
    else
        "$command" "$input_file" &
    fi
    server_pid=$!
    echo "Server started with PID $server_pid"
}

# Get PID(s) listening on the HTTP port
get_server_pid() {
    lsof -ti tcp:"$http_port"
}

# Gracefully stop the server
stop_server() {
    pid=$(get_server_pid)
    if [[ -n "$pid" ]]; then
        echo "Stopping process at port $http_port (PID $pid)"
        kill "$pid" 2>/dev/null
        sleep 1
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid"
    fi
}

# Restart server
restart_server() {
    stop_server
    run_cmd
}

# Show running processes
show_processes() {
    echo
    echo "Running processes:"
    echo "Watcher PID: $$"
    [[ -n "$server_pid" ]] && echo "Server PID: $server_pid"
    echo "Port $http_port PID(s): $(get_server_pid)"
    echo
}

# ----------------------------
# Argument parsing
# ----------------------------
while getopts 'w:e:p:c:d:l:' OPTION; do
    case "$OPTION" in
        w) files_to_watch=($OPTARG) ;;
        e) input_file=$OPTARG ;;
        p) http_port=$OPTARG ;;
        c) command=$OPTARG ;;
        d) delay=$OPTARG ;;
        l) logFile=$OPTARG ;;
        ?) echo "$usage" >&2; exit 1 ;;
    esac
done

# Check mandatory args
if [[ -z "$input_file" || -z "$http_port" || -z "$command" ]]; then
    echo "Missing required arguments." >&2
    echo "$usage" >&2
    exit 1
fi

# Include entry file if no extra files provided
[[ ${#files_to_watch[@]} -eq 0 ]] && files_to_watch=("$input_file")

# ----------------------------
# Cleanup on exit
# ----------------------------
trap 'stop_server; echo "Exiting..."; exit 0' EXIT

# ----------------------------
# Start server
# ----------------------------
run_cmd
print_options

# ----------------------------
# File watching loop (efficient with inotifywait)
# ----------------------------
watch_files() {
    while true; do
        # Wait for any modify/create/delete event
        inotifywait -e modify,create,delete -q -r "${files_to_watch[@]}" >/dev/null 2>&1
        echo "Change detected, restarting server..."
        restart_server
    done
}

# Run watcher in background
watch_files &

# ----------------------------
# Interactive keypress loop
# ----------------------------
while true; do
    if read -rsn1 input; then
        case $input in
            q) exit 0 ;;
            o) print_options ;;
            r) restart_server ;;
            c) clear ;;
            p) show_processes ;;
            l)
                if [[ -n "$logFile" && -f "$logFile" ]]; then
                    cat "$logFile"
                else
                    echo "Log file not specified or missing"
                fi
                ;;
            t)
                if [[ -n "$logFile" && -f "$logFile" ]]; then
                    truncate -s 0 "$logFile"
                    echo "Log file emptied"
                else
                    echo "Log file not specified or missing"
                fi
                ;;
            u) echo "$usage" ;;
        esac
    fi
done
