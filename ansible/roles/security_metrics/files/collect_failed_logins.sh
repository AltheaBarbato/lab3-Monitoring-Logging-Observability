#!/bin/bash
# counts failed SSH login attempts from the last hour in auth.log

AUTH_LOG="/var/log/auth.log"
COUNT=0

if [[ -f "$AUTH_LOG" ]]; then
    COUNT=$(grep "Failed password" "$AUTH_LOG" 2>/dev/null | wc -l)
fi

cat <<EOF
# HELP node_failed_ssh_logins_total Total failed SSH login attempts in auth.log
# TYPE node_failed_ssh_logins_total counter
node_failed_ssh_logins_total $COUNT
EOF
