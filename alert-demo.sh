#!/bin/bash
set -e

SERVER_IP="163.192.117.50"
SSH_KEY="$HOME/.ssh/lab1-key.pem"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=10"

echo "=== stopping node_exporter to trigger InstanceDown alert ==="
ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo docker stop node_exporter"

echo ""
echo "=== waiting 45s for alert to go Pending -> Firing ==="
sleep 45

echo ""
echo "=== current alert state ==="
curl -s "http://$SERVER_IP:9090/api/v1/alerts"

echo ""
echo "screenshot time:"
echo "  http://$SERVER_IP:9090/alerts"
echo "  http://$SERVER_IP:3000/alerting/list"
echo ""
read -p "Press Enter when done!!!"

echo "=== restarting node_exporter ==="
ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo docker start node_exporter"

echo "=== waiting 30s for alert to clear ==="
sleep 30
curl -s "http://$SERVER_IP:9090/api/v1/alerts"
echo ""
echo "alert should be cleared now"
