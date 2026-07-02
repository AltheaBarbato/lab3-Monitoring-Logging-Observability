#!/bin/bash
SERVER_IP="163.192.117.50"
SSH_KEY="$HOME/.ssh/lab1-key.pem"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o ConnectTimeout=10"

PASS=0
FAIL=0

check() {
    local label="$1"
    local result="$2"
    if [[ "$result" == "ok" ]]; then
        echo "  [PASS] $label"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $label ($result)"
        FAIL=$((FAIL + 1))
    fi
}

echo "--- Containers ---"
for container in prometheus grafana nginx_exporter node_exporter uptime_kuma; do
    status=$(ssh $SSH_OPTS "sysadmin@$SERVER_IP" "sudo docker inspect -f '{{.State.Running}}' $container 2>/dev/null || echo false")
    check "$container container running" "$( [[ "$status" == "true" ]] && echo ok || echo "not running" )"
done

echo "--- Prometheus ---"
http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:9090/-/ready")
check "Prometheus ready" "$( [[ "$http_code" == "200" ]] && echo ok || echo "got $http_code" )"

targets_up=$(curl -s "http://$SERVER_IP:9090/api/v1/query?query=sum(up)" | python3 -c "import sys,json; d=json.load(sys.stdin); print(int(float(d['data']['result'][0]['value'][1])))" 2>/dev/null || echo 0)
check "all Prometheus targets up ($targets_up/3)" "$( [[ "$targets_up" -ge 3 ]] && echo ok || echo "$targets_up/3 up" )"

rules=$(curl -s "http://$SERVER_IP:9090/api/v1/rules" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['data']['groups'][0]['rules']))" 2>/dev/null || echo 0)
check "alert rules loaded ($rules rules)" "$( [[ "$rules" -ge 5 ]] && echo ok || echo "only $rules rules" )"

echo "--- Grafana ---"
gf_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:3000/api/health")
check "Grafana healthy" "$( [[ "$gf_code" == "200" ]] && echo ok || echo "got $gf_code" )"

for uid in infra-overview security-events availability; do
    dash_code=$(curl -s -o /dev/null -w "%{http_code}" -u admin:lab3monitoring "http://$SERVER_IP:3000/api/dashboards/uid/$uid")
    check "dashboard $uid provisioned" "$( [[ "$dash_code" == "200" ]] && echo ok || echo "got $dash_code" )"
done

echo "--- Uptime Kuma ---"
kuma_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$SERVER_IP:3001")
check "Uptime Kuma reachable" "$( [[ "$kuma_code" == "200" || "$kuma_code" == "302" ]] && echo ok || echo "got $kuma_code" )"

echo "--- Security Metrics ---"
metric=$(curl -s "http://$SERVER_IP:9090/api/v1/query?query=node_failed_ssh_logins_total" | python3 -c "import sys,json; d=json.load(sys.stdin); print('ok' if d['data']['result'] else 'missing')" 2>/dev/null || echo missing)
check "failed_ssh_logins metric present" "$metric"

echo ""
echo "done — $PASS passed, $FAIL failed"
