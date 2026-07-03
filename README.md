# Lab 3 Monitoring, Logging & Operational Visibility
**Name:** Althea Barbato

Same server again (`webserver01`, `163.192.117.50`). Adds Uptime Kuma, three Grafana dashboards, security event monitoring via auth.log, and five alert rules on top of the Prometheus + Grafana stack from the previous lab.

## What's running

- **Prometheus** (9090) - scrapes metrics every 15s, evaluates 5 alert rules
- **Grafana** (3000) - three dashboards: Infrastructure Overview, Security Events, Availability
- **Uptime Kuma** (3001) - service status/availability monitoring
- **nginx_exporter** (9113) - nginx request rate + connection metrics
- **node_exporter** (9100) - system metrics + failed login count via textfile collector

## Layout

```
lab3-observability/
├── ansible/
│   ├── inventory.ini
│   ├── site.yml
│   ├── vars/main.yml
│   ├── playbooks/
│   │   ├── 01-security-metrics.yml
│   │   ├── 02-prometheus.yml
│   │   ├── 03-grafana.yml
│   │   └── 04-uptime-kuma.yml
│   └── roles/
│       ├── security_metrics/   auth.log scraper + textfile collector
│       ├── prometheus/         prometheus container + alert rules
│       ├── grafana/            grafana container + 3 dashboards
│       └── uptime_kuma/        uptime kuma container
├── deploy.sh
├── verify.sh
├── alert-demo.sh
└── docs/
    ├── architecture.md
    └── operational-analysis.md
```

## Running it

```bash
bash deploy.sh --check
bash deploy.sh
bash verify.sh
```

## Dashboards (login: admin / lab3monitoring)

| Dashboard | URL | Shows |
|---|---|---|
| Infrastructure Overview | http://163.192.117.50:3000/d/infra-overview | CPU, memory, disk, network, nginx |
| Security Events | http://163.192.117.50:3000/d/security-events | Failed SSH logins, firing alerts |
| Availability | http://163.192.117.50:3000/d/availability | Per-service up/down status + history |

Uptime Kuma is at `http://163.192.117.50:3001`

## Alerts

| Alert | Condition |
|---|---|
| InstanceDown | any target unreachable for 30s |
| HighCPUUsage | CPU > 80% for 1m |
| LowDiskSpace | root < 15% free for 2m |
| HighMemoryUsage | memory > 85% for 2m |
| FailedSSHLogins | > 20 new SSH failures in 1h |

## Alert demo

```bash
bash alert-demo.sh
```
