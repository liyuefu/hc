#!/usr/bin/env bash
#ifconfig |grep inet |grep -Ev "inet6|127.0.0.1|169.254" | awk '{print $2}' | sort| sed 'N;s/\n/-/;N;s/\n/-/;N;s/\n/-/;N;s/\n/-/;N;s/\n/-/;N;s/\n/-/;N;s/\n/-/;N;s/\n/-/' |sed 's/addr://g'

ipv4_addresses=$(ip addr show | awk '/inet / && $2 !~ /^127\.0\.0\.1/ {print $2}' | cut -d'/' -f1)
connected_ipv4_addresses=$(echo "$ipv4_addresses" | tr '\n' '-')
echo "${connected_ipv4_addresses%-}"  # Remove the trailing dash
