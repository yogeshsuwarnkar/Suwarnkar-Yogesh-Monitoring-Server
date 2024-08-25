#!/bin/bash

INTERFACE="enX0"  # actual network interface

#Function to monitor the top 10 most used applications (CPU and memory)
monitor_top_apps() {
    echo "--------------------------------"
    echo "Top 10 Applications by CPU and Memory Usage"
    echo "--------------------------------"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 11
}

monitor network
monitor_network() {
    echo "--------------------------------"
    echo "Network Monitoring"
    echo "--------------------------------"

    # Concurrent Connections
    echo "Concurrent Connections:"
    if command -v ss > /dev/null; then
        ss -H state ESTABLISHED | wc -l
    else
        echo "ss command not found. Please install iproute2."
    fi
    echo ""

    # Packet Drops
    echo "Packet Drops:"
    if command -v ip > /dev/null; then
        ip -s link show $INTERFACE | grep -A 1 "RX:" | tail -n 1
        ip -s link show $INTERFACE | grep -A 1 "TX:" | tail -n 1
    else
        echo "ip command not found. Please install iproute2."
    fi
    echo ""

    # Network Traffic (MB in/out)
    echo "Network Traffic (MB in/out):"
    if command -v ifstat > /dev/null; then
        ifstat -i $INTERFACE 1 1 | awk 'NR==3 {print "In: " $1 " MB, Out: " $2 " MB"}'
    else
        echo "ifstat command not found. Please install ifstat."
    fi

} 

monitor disk usage
monitor_disk() {
    echo "--------------------------------"
    echo "Disk Usage"
    echo "--------------------------------"
    if command -v df > /dev/null; then
        # Print the disk usage
        df -h
    else
        echo "df command not found. Please install coreutils."
    fi
}

monitor system load
monitor_load() {
    echo "--------------------------------"
    echo "System Load"
    echo "--------------------------------"
    uptime
    echo ""
    echo "CPU Usage Breakdown:"
    if command -v mpstat > /dev/null; then
        mpstat
    else
        echo "mpstat command not found. Please install sysstat."
    fi
}

Function to monitor memory usage
monitor_memory() {
    echo "--------------------------------"
    echo "Memory Usage"
    echo "--------------------------------"
    free -h
    echo ""
    echo "Swap Memory Usage:"
    free -h | grep -i swap
}

Function to monitor processes
monitor_processes() {
    echo "--------------------------------"
    echo "Process Monitoring"
    echo "--------------------------------"
    echo "Number of Active Processes:"
    ps aux | wc -l
    echo ""
    echo "Top 5 Processes by CPU and Memory Usage:"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
}

Function to monitor essential services
monitor_services() {
    echo "--------------------------------"
    echo "Service Monitoring"
    echo "--------------------------------"
    for service in sshd nginx httpd iptables; do
        if systemctl is-active --quiet $service; then
            echo "$service is running"
        else
            echo "$service is not running"
            # Attempt to start the service
            echo "Starting $service..."
            sudo systemctl start $service
            if systemctl is-active --quiet $service; then
                echo "$service started successfully"
            else
                echo "Failed to start $service"
            fi
        fi
    done
}

 Display help message
show_help() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -cpu       Show CPU usage"
    echo "  -memory    Show memory usage"
    echo "  -network   Show network statistics"
    echo "  -disk      Show disk usage"
    echo "  -services  Show service monitoring"
    echo "  -all       Show all statistics"
    echo "  -help      Show this help message"
}

Function to display the full dashboard
display_dashboard() {
    while true; do
        clear
        monitor_top_apps
        echo ""
        monitor_network
        echo ""
        monitor_disk
        echo ""
        monitor_load
        echo ""
        monitor_memory
        echo ""
        monitor_processes
        echo ""
        monitor_services
        sleep 5  # Refresh every 5 seconds
    done
}

 Parse command-line options
while getopts "cmndspahl" opt; do
    case ${opt} in
        a)
            display_dashboard
            ;;
        c)
            monitor_load
            ;;
        m)
            monitor_memory
            ;;
        n)
            monitor_network
            ;;
        d)
            monitor_disk
            ;;
        s)
            monitor_services
            ;;
        p)
            monitor_processes
            ;;
        h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

 If no options are provided, display the full dashboard
if [ $# -eq 0 ]; then
    display_dashboard
fi
