# Operational Analysis Report
**Name:** Althea Barbato

## Why observability actually matters

Running a server without monitoring is basically flying blind. You don't know if something's slow, broken, or being attacked until either a user complains or you happen to log in and notice something weird. The whole point of this setup is that the system tells you when something's wrong instead of you having to go looking.

There's a difference between monitoring (is it up or down?) and observability (why is it behaving this way?). Uptime Kuma handles the first one, it polls the service and shows you a status page. Prometheus + Grafana handle the second, you can look at CPU over the last 6 hours and see exactly when a spike happened and how long it lasted.

For a class project this matters less, but for a real system, the difference between knowing "nginx went down at 2:47am" vs "we noticed the site was slow when someone checked in at 9am" is enormous.

## What I'm actually monitoring

**CPU, memory, disk** - standard system health. Right now CPU sits around 0.67% and memory at about 7.75% because there's no real traffic. Disk is at 11.35%, but I'm watching it since Prometheus keeps 7 days of time series data and it'll grow. Set `--storage.tsdb.retention.time=7d` in the Prometheus run command so it caps itself.

**Network** - mostly flat since nobody's hitting this server except me. Would tell you if traffic spiked or if something started exfiltrating data (unexpected outbound traffic).

**NGINX request rate** - basically zero (around 0.07 req/s). In a real deployment this is how you'd tell if traffic looks normal, too low (maybe a cache is serving everything), or too high (potential DDoS or viral traffic).

**Container status** - all five containers show `up = 1` in Prometheus which means they were all reachable on the last scrape. node_exporter exposes systemd unit states too so you can check if fail2ban is actually running.

**Failed SSH logins** - custom metric I set up using a cron job that counts "Failed password" entries in `/var/log/auth.log`. The internet actively scans for open SSH ports and tries common credentials, this metric makes that visible instead of it happening silently.

## Monitoring limitations

The biggest gap right now: alerts fire in the UI but nobody gets notified. Alertmanager or Grafana contact points would route alerts to email or Slack, but that's not set up. For this setup, "monitoring" really means "visibility if you're already logged in looking at the dashboard." Not real on-call coverage.

Second gap: no log search. I can see that failed logins happened (the count goes up) but I can't look at the actual log lines from Grafana. Loki would fix this, you'd be able to search logs directly from the dashboard. For now if I need to see what IPs were trying to log in I have to SSH in and grep auth.log manually.

Third: Uptime Kuma monitors from inside the same server. For real availability checking you want external monitoring. If the network itself goes down, Uptime Kuma goes down with everything else and you get no alert.

## False positives vs false negatives

False positives are alerts that fire when nothing's actually wrong. The `for:` duration in Prometheus alert rules is the main tool against this. InstanceDown needs to stay down for 30 continuous seconds before it fires, so a single missed scrape doesn't set off an alert. CPU needs to be above 80% for a full minute. Without these windows, every time the server did any brief burst of work (apt update, Docker pull, cron job) you'd get an alert for nothing.

False negatives are when something actually breaks but no alert fires. The LowDiskSpace threshold is 15% free. If the disk fills slowly and I don't check dashboards, it could cause real problems before hitting that threshold. Setting it higher (like 20%) would catch it earlier but would fire more often on servers that intentionally run with less free space.

The FailedSSHLogins alert threshold is set at 20 failures in an hour. The server legitimately gets scanned constantly, so a smaller number would fire all the time (false positives). But if an actual brute force happened and someone found valid credentials before hitting 20, the alert would miss it (false negative). It's a tradeoff.

## Security visibility

Fail2ban is already running from earlier labs and banning IPs after repeated failures. The monitoring adds a Prometheus metric (`node_failed_ssh_logins_total`) so I can actually graph the attack volume over time. Spike in the Security Events dashboard means something's actively scanning, flat line means it's quiet.

The systemd unit state metric (`node_systemd_unit_state`) shows whether fail2ban is running. If someone managed to stop it (or it crashed), the dashboard would show the fail2ban service as inactive, so you'd know the defense layer was down.

What this doesn't cover: successful logins. If someone got in with valid credentials there's no alert for that. That would require correlating auth.log for "Accepted password" or "session opened" events, which is something Loki or ELK would handle better.

## Operational maintenance

Prometheus data is capped at 7 days via `--storage.tsdb.retention.time=7d` so disk won't grow forever. Docker images need occasional pruning with `docker system prune` since old image layers pile up. The unattended-upgrades package handles security patches for the OS automatically.

Uptime Kuma stores its data in `/var/lib/uptime-kuma` which is mounted as a Docker volume, so it persists through container restarts. Same for Prometheus (`/var/lib/prometheus`) and Grafana (`/var/lib/grafana`).

Everything's deployed via Ansible so if the server ever needed to be rebuilt from scratch, the entire monitoring stack comes back up with one `bash deploy.sh`. The dashboards are provisioned as code in the repo, no clicking through the Grafana UI to rebuild them.
