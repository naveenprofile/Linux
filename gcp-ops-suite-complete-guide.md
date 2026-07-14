# GCP Cloud Operations Suite — Complete Interview Guide
## Monitoring · Logging · Trace · Profiler · Error Reporting · Prometheus/OTel · Per-Service Monitoring · IAM · Terraform · Best Practices · Interview Scenarios

---


# PART 1 — CLOUD MONITORING

## 1.1 What is Cloud Monitoring?

Cloud Monitoring (formerly Stackdriver Monitoring) is GCP's managed observability service. It collects **metrics, events, and metadata** from GCP resources, hybrid/on-prem systems, and application code, then lets you visualize (dashboards), alert on (alerting policies), and query (MQL/PromQL) that data.

Key building blocks:
- **Metrics** — time-series numeric data (CPU utilization, request count, custom app metrics)
- **Monitored resources** — the "thing" a metric belongs to (a VM instance, a GKE container, a Cloud SQL instance)
- **Metric descriptors** — schema defining a metric's type, labels, and value type
- **Workspace / Metrics Scope** — the container that ties together the projects you monitor

## 1.2 Monitoring Architecture

```
[Resource: VM/GKE/CloudSQL/...] 
        │  (emits telemetry)
        ▼
[Ops Agent / API client / Managed Prometheus]
        │  writes via Cloud Monitoring API (monitoring.googleapis.com)
        ▼
[Time Series Database] ── indexed by (metric type + monitored resource + labels)
        │
        ├──► Dashboards (Console)
        ├──► Alerting Policies → Notification Channels (Email/Slack/PagerDuty/Webhook/SMS/PubSub)
        ├──► MQL / PromQL queries
        └──► Metrics Explorer / API reads
```

A **Metrics Scope** (the modern replacement for "Workspace") is a project designated as the monitoring host. You can attach multiple GCP projects to one Metrics Scope for centralized, multi-project monitoring — you see them all in one pane, but each project still owns its own metrics/IAM.

**Console steps — set up a Metrics Scope:**
1. Console → **Monitoring** → this auto-creates a Metrics Scope for the current project if none exists.
2. Go to **Monitoring → Settings → Metrics Scope**.
3. Click **Add GCP Projects**, select projects to monitor centrally.
4. Requires `roles/monitoring.viewer` (minimum) on the monitored project and `roles/monitoring.editor` on the scoping project.

```bash
# View current metrics scope
gcloud monitoring metrics-scopes describe <SCOPING_PROJECT_ID>

# Add a monitored project to a metrics scope (uses the Monitoring API, no dedicated gcloud verb — typically done via API/console)
curl -X POST \
  "https://monitoring.googleapis.com/v1/locations/global/metricsScopes/<SCOPING_PROJECT_ID>/projects" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{"name": "locations/global/metricsScopes/<SCOPING_PROJECT_ID>/projects/<MONITORED_PROJECT_ID>"}'
```

## 1.3 Monitored Resources, Resource Types, Labels

Every metric is attached to a **monitored resource** — e.g. `gce_instance`, `k8s_container`, `cloudsql_database`, `gcs_bucket`. Each resource type has **resource labels** (e.g. `instance_id`, `zone`, `project_id`) that identify a specific instance of that resource.

Metrics themselves have **metric labels** (e.g. `response_code`, `method`) that add dimensions within a metric type.

```bash
# List available monitored resource descriptors
gcloud monitoring monitored-resource-descriptors list --limit=20

# Describe a specific resource type
gcloud monitoring monitored-resource-descriptors describe gce_instance
```

## 1.4 Metrics

| Type | Source | Example |
|---|---|---|
| **System metrics** | Auto-collected by GCP for the resource, no agent needed | `compute.googleapis.com/instance/cpu/utilization` |
| **Agent metrics** | Collected inside the VM by Ops Agent | `agent.googleapis.com/memory/percent_used` |
| **Custom metrics** | App-defined, written via API/OpenTelemetry | `custom.googleapis.com/myapp/queue_depth` |
| **Logs-based metrics** | Derived by counting/extracting from log entries | `logging.googleapis.com/user/error_count` |
| **External metrics** | Ingested from third parties (e.g. Prometheus) | `external.googleapis.com/prometheus/...` |

**Metric kinds:** `GAUGE` (point-in-time value), `DELTA` (change since last sample), `CUMULATIVE` (running total since a start time).
**Value types:** `BOOL`, `INT64`, `DOUBLE`, `DISTRIBUTION`, `STRING`.

**Metric retention:** Cloud Monitoring stores most metric data for **24 months**, regardless of granularity — no manual archiving needed (unlike logs).

```bash
# List metric descriptors matching a filter
gcloud monitoring metrics-descriptors list \
  --filter="metric.type=starts_with(\"compute.googleapis.com\")" --limit=10

# Write a custom metric data point via API (no direct gcloud verb for writing)
curl -X POST \
  "https://monitoring.googleapis.com/v3/projects/<PROJECT_ID>/timeSeries" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "timeSeries": [{
      "metric": {"type": "custom.googleapis.com/myapp/queue_depth"},
      "resource": {"type": "global", "labels": {"project_id": "<PROJECT_ID>"}},
      "points": [{
        "interval": {"endTime": "'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},
        "value": {"int64Value": "42"}
      }]
    }]
  }'
```

## 1.5 Monitoring Agents

**Ops Agent** (current, recommended) combines metrics + logging collection in a single agent, replacing the legacy Monitoring Agent + Logging Agent. Built on Fluent Bit (logs) and OpenTelemetry Collector (metrics).

**Console steps — install Ops Agent on a VM:**
1. Compute Engine → VM instances → select instance → **Observability** tab → **Install Ops Agent** (guided install button), OR
2. Use the install script method below.

```bash
# SSH into the VM, then run the install script (Debian/Ubuntu example)
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Check agent status
sudo systemctl status google-cloud-ops-agent"*"

# Restart after config change
sudo systemctl restart google-cloud-ops-agent

# Install fleet-wide via OS Config (recommended for many VMs)
gcloud compute instances ops-agents policies create ops-agent-policy \
  --project=<PROJECT_ID> \
  --zone=us-central1-a \
  --agent-rules="type=ops-agent,enable-autoupgrade=true,version=latest" \
  --os-types=short-name=debian,version=11 \
  --group-labels=env=prod
```

Agent config lives at `/etc/google-cloud-ops-agent/config.yaml`. Common troubleshooting:
```bash
# Validate config syntax
sudo google-cloud-ops-agent config-validate

# View agent logs
sudo journalctl -u google-cloud-ops-agent"*" -f
```

## 1.6 Dashboards

Dashboards visualize metrics using widgets: **Line/Bar charts, Heatmaps, Scorecards (single big number), Gauges, Text widgets (Markdown notes), Alignment tables**.

**Console steps — build a dashboard:**
1. Monitoring → **Dashboards** → **Create Dashboard**.
2. Name it, click **Add Widget** → choose widget type (e.g. Line chart).
3. Configure: select a **Resource type + Metric** (e.g. `VM Instance → CPU utilization`), set **Filter** (by label), **Aggregator** (mean/sum/p99), **Group By**.
4. Save.
5. Share: **Share** button → export as link, or export dashboard as JSON for version control.

```bash
# List existing dashboards
gcloud monitoring dashboards list

# Describe one
gcloud monitoring dashboards describe <DASHBOARD_ID>

# Create a dashboard from a JSON definition file
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

Example minimal `dashboard.json`:
```json
{
  "displayName": "VM CPU Overview",
  "gridLayout": {
    "widgets": [
      {
        "title": "CPU Utilization",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" resource.type=\"gce_instance\"",
                "aggregation": {"alignmentPeriod": "60s", "perSeriesAligner": "ALIGN_MEAN"}
              }
            }
          }]
        }
      }
    ]
  }
}
```

## 1.7 Alerting

**Alert policy components:** condition(s) → threshold/rate-of-change/forecast → notification channel(s) → documentation (runbook text shown in the alert).

**Console steps — create a threshold alert:**
1. Monitoring → **Alerting** → **Create Policy**.
2. **Select a metric** → e.g. VM Instance → CPU utilization.
3. Configure trigger: **Threshold**, e.g. "above 0.8 for 5 minutes".
4. Add **Notification channels** (create Email/Slack/PagerDuty/Webhook if not existing).
5. Add **Documentation** (Markdown runbook — what to check, who to page).
6. Name the policy, **Save**.

```bash
# List notification channels
gcloud alpha monitoring channels list

# Create an email notification channel
gcloud alpha monitoring channels create \
  --display-name="Ops Team Email" \
  --type=email \
  --channel-labels=email_address=ops-team@example.com

# Create a Slack notification channel (requires prior OAuth setup in console once)
gcloud alpha monitoring channels create \
  --display-name="Slack Alerts" \
  --type=slack \
  --channel-labels=channel_name=#alerts

# Create an alert policy from a YAML/JSON file
gcloud alpha monitoring policies create --policy-from-file=cpu-alert.yaml
```

Example `cpu-alert.yaml` (disk-usage-over-80% example, matches interview scenario #4):
```yaml
displayName: "Disk usage > 80%"
combiner: OR
conditions:
  - displayName: "Disk utilization above 80%"
    conditionThreshold:
      filter: >
        metric.type="compute.googleapis.com/instance/disk/percent_used"
        resource.type="gce_instance"
      comparison: COMPARISON_GT
      thresholdValue: 0.8
      duration: 300s
      aggregations:
        - alignmentPeriod: 300s
          perSeriesAligner: ALIGN_MEAN
notificationChannels:
  - "projects/<PROJECT_ID>/notificationChannels/<CHANNEL_ID>"
documentation:
  content: "Disk usage exceeded 80%. Check `df -h` on the instance and clear logs/tmp if needed."
  mimeType: "text/markdown"
```

```bash
# List / update / delete policies
gcloud alpha monitoring policies list
gcloud alpha monitoring policies update <POLICY_ID> --policy-from-file=updated.yaml
gcloud alpha monitoring policies delete <POLICY_ID>
```

**Alert types:**
- **Metric threshold** — static value crossed.
- **Log-based alert** — fires directly off a log query match (e.g., a specific ERROR string appearing), console: Logging → Log Explorer → run query → **Create Alert**.
- **Uptime alert** — fires when an uptime check fails.
- **Forecast alert** — predicts if a metric will cross a threshold within a future window (e.g., disk will fill in 4 hours) — useful for proactive capacity alerts.
- **MQL alert** — condition expressed in Monitoring Query Language for complex logic.

**Alert Snoozing:** temporarily silence a policy without disabling it — Console → Alerting → Snooze → pick policy + duration + reason. Useful during planned maintenance.

**Incident Management:** each firing alert creates an **Incident**, viewable under Monitoring → Alerting → Incidents, with state (open/acknowledged/closed), timeline, and links back to metrics/logs at the time of firing.

## 1.8 Uptime Checks

Synthetic checks hitting your endpoint on a schedule (1/5/10/15 min) from multiple global locations.

**Console steps:**
1. Monitoring → **Uptime checks** → **Create Uptime Check**.
2. Protocol: HTTP/HTTPS/TCP. Target: hostname or resource (LB, App Engine, etc.), path (e.g. `/healthz`).
3. Check frequency, regions to check from.
4. Optional: response validation (status code, content match), SSL cert expiration check (for HTTPS).
5. Directly attach a notification channel (creates an alert policy automatically), or link to an existing alert policy.

```bash
# gcloud has no dedicated 'uptime-checks' group; managed via API or Terraform
curl -X POST \
  "https://monitoring.googleapis.com/v3/projects/<PROJECT_ID>/uptimeCheckConfigs" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "Public API Uptime",
    "httpCheck": {"path": "/health", "port": 443, "useSsl": true},
    "monitoredResource": {"type": "uptime_url", "labels": {"host": "api.example.com"}},
    "timeout": "10s",
    "period": "60s"
  }'
```

Internal uptime checks (for private VPC endpoints) require a **Private Uptime Check** setup with VPC connectivity via a designated network.

## 1.9 Service Monitoring (SLI / SLO / SLA / Error Budget)

- **SLI (Service Level Indicator):** a measured metric of service behavior, e.g. "% of requests with latency < 300ms" or "% of successful (non-5xx) requests".
- **SLO (Service Level Objective):** the internal target for an SLI over a window, e.g. "99.9% availability over 30 days".
- **SLA (Service Level Agreement):** the external, often contractual, commitment — usually looser than the SLO, with consequences (credits/penalties) if missed.
- **Error Budget:** `1 − SLO` — the allowed amount of "badness" (e.g. 0.1% for a 99.9% SLO ≈ 43 min/month of downtime).
- **Burn rate:** how fast you're consuming the error budget relative to a sustainable pace. A burn rate of 1 = exactly on pace to exhaust the budget by period end; burn rate > 1 means you'll exhaust it early — commonly alerted with multi-window (fast + slow) burn rate alerts to catch both sudden outages and slow leaks.

**Console steps — create an SLO:**
1. Monitoring → **Services** → select/define a service (auto-detected for GKE/App Engine/Cloud Run, or define custom).
2. **Create SLO** → choose SLI type (Availability, Latency, Custom).
3. Set target (e.g. 99.9%) and compliance window (rolling 30 days / calendar month).
4. **Create burn-rate alert**: choose lookback windows (e.g. 1h fast burn + 6h slow burn), set burn-rate thresholds.

```bash
# Services and SLOs are managed via API (monitoring.googleapis.com/v3/services)
curl -X POST \
  "https://monitoring.googleapis.com/v3/projects/<PROJECT_ID>/services/<SERVICE_ID>/serviceLevelObjectives" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "99.9% availability - 30 day",
    "goal": 0.999,
    "rollingPeriod": "2592000s",
    "serviceLevelIndicator": {
      "requestBased": {
        "goodTotalRatio": {
          "goodServiceFilter": "metric.type=\"loadbalancing.googleapis.com/https/request_count\" metric.label.response_code_class=\"200\"",
          "totalServiceFilter": "metric.type=\"loadbalancing.googleapis.com/https/request_count\""
        }
      }
    }
  }'
```

## 1.10 Monitoring Query Language (MQL)

MQL is a pipeline query language (similar in spirit to SQL/PromQL) for advanced time-series analysis.

```
fetch gce_instance
| metric 'compute.googleapis.com/instance/cpu/utilization'
| filter resource.zone == 'us-central1-a'
| align rate(1m)
| every 1m
| group_by [resource.instance_id], [value_utilization_mean: mean(value.utilization)]
```

- **fetch** — chooses monitored resource type
- **filter** — restrict by labels
- **align** — resample/interpolate to a period
- **group_by / aggregation** — roll up across series
- **join** — combine two time series (e.g. errors / total for an error rate)

Run MQL in Console: Monitoring → **Metrics Explorer** → switch to **MQL** mode, or **Monitoring → Explorer → Language: MQL**.

```bash
# Query time series via API using an MQL-equivalent filter (gcloud doesn't run MQL directly; use API or console)
gcloud monitoring time-series list \
  --filter='metric.type="compute.googleapis.com/instance/cpu/utilization"' \
  --interval-start-time="$(date -u -d '-1 hour' +%Y-%m-%dT%H:%M:%SZ)" \
  --interval-end-time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## 1.11 Managed Service for Prometheus

GCP-managed, globally-scalable storage/query layer that is **wire-compatible with Prometheus** — lets you keep using PromQL and existing exporters/ServiceMonitors while GCP handles storage/HA. Enabled with a single `--enable-managed-prometheus` flag on a GKE cluster, scraped via Kubernetes-native `PodMonitoring` CRDs, and queryable from Metrics Explorer or Grafana.

→ Full architecture, setup commands, alerting rules, and Grafana integration are covered in **Part 6 (Managed Service for Prometheus — Deep Dive)**.

---

# PART 2 — CLOUD LOGGING

## 2.1 What is Cloud Logging?

Fully managed, real-time log management: ingestion, storage, search, analysis, and export. Every GCP service can emit **Admin Activity, Data Access, System Event, and Policy Denied** audit logs automatically; applications write structured/unstructured logs via the Logging API, agents, or client libraries.

## 2.2 Logging Architecture

```
[Source: GCE/GKE/App/Audit events]
        │
        ▼
   Log Entry (structured JSON: timestamp, severity, resource, jsonPayload/textPayload, labels)
        │
        ▼
    Log Router  ──► matches entries against Sinks (Inclusion/Exclusion filters)
        │
        ├──► _Default bucket (all logs, 30-day retention by default)
        ├──► _Required bucket (Admin Activity/System Event audit logs, 400-day retention, cannot be disabled)
        ├──► Custom Log Buckets (your retention/region)
        ├──► Cloud Storage (export, long-term/cheap archive)
        ├──► BigQuery (export, SQL analytics)
        └──► Pub/Sub (export, streaming to external SIEM/other systems)
```

Every project auto-creates a **_Default** sink → **_Default** bucket, and a **_Required** sink → **_Required** bucket (for Admin Activity + System Event audit logs, which are always captured and can't be turned off, though Data Access logs are opt-in due to volume/cost).

## 2.3 Log Entries — Anatomy

Key fields: `logName`, `resource` (monitored resource + labels), `timestamp`, `severity` (DEFAULT/DEBUG/INFO/NOTICE/WARNING/ERROR/CRITICAL/ALERT/EMERGENCY), `textPayload` or `jsonPayload` or `protoPayload` (used for audit logs), `labels`, `trace` (for correlating with Cloud Trace), `insertId`.

```bash
# Write a simple log entry
gcloud logging write my-log "Deployment finished successfully" --severity=INFO

# Read recent logs with a filter
gcloud logging read 'resource.type="gce_instance" AND severity>=ERROR' \
  --limit=20 --format=json --freshness=1d
```

## 2.4 Log Types

- **Admin Activity logs** — API calls that modify config/metadata (e.g. creating a VM). Always on, 400-day retention, free.
- **Data Access logs** — reads/writes of user-provided data (e.g. reading a Cloud Storage object, a BigQuery query). Off by default (except BigQuery) due to volume; must be explicitly enabled per service.
- **System Event logs** — GCP-system-generated changes not from a user API call (e.g. live migration of a VM by Google). Always on.
- **Policy Denied logs** — a request denied due to a security policy (e.g. VPC Service Controls, Org Policy). Always on where applicable.

**Console steps — enable Data Access logs:**
1. IAM & Admin → **Audit Logs**.
2. Find the service (e.g. "Cloud Storage"), expand it.
3. Check **Admin Read / Data Read / Data Write** as needed.
4. Save. (Note: Data Access logs can significantly increase log volume/cost — enable selectively.)

```bash
# Audit config is part of the IAM policy — fetch, edit, set
gcloud projects get-iam-policy <PROJECT_ID> --format=json > policy.json
# edit policy.json to add an "auditConfigs" block for the desired service, then:
gcloud projects set-iam-policy <PROJECT_ID> policy.json
```
Example `auditConfigs` block to add:
```json
"auditConfigs": [
  {
    "service": "storage.googleapis.com",
    "auditLogConfigs": [
      {"logType": "DATA_READ"},
      {"logType": "DATA_WRITE"}
    ]
  }
]
```

## 2.5 Log Router — Sinks, Filters, Destinations

A **sink** routes a defined subset of logs (via an inclusion filter, optionally minus an exclusion filter) to a destination.

**Console steps — create a sink:**
1. Logging → **Log Router** → **Create Sink**.
2. Name it, choose **destination** (Cloud Storage bucket / BigQuery dataset / Pub/Sub topic / another project's log bucket).
3. Define the **inclusion filter** (which logs to send) using the Log Explorer query syntax.
4. Optionally add **exclusion filters** (e.g. exclude noisy health-check logs).
5. Save — GCP auto-creates a service account for the sink; grant it write permission on the destination if not automatic.

```bash
# Create a sink to BigQuery for security analysis (matches interview scenario: export firewall logs)
gcloud logging sinks create firewall-logs-to-bq \
  bigquery.googleapis.com/projects/<PROJECT_ID>/datasets/firewall_logs \
  --log-filter='logName="projects/<PROJECT_ID>/logs/compute.googleapis.com%2Ffirewall"' \
  --project=<PROJECT_ID>

# Grant the sink's auto-created service account access to write to BigQuery
gcloud logging sinks describe firewall-logs-to-bq --format='value(writerIdentity)'
# then, using that SA email:
bq add-iam-policy-binding \
  --member="serviceAccount:<SINK_WRITER_IDENTITY>" \
  --role="roles/bigquery.dataEditor" \
  <PROJECT_ID>:firewall_logs

# Create a sink to Cloud Storage for long-term archive
gcloud logging sinks create archive-all-logs \
  storage.googleapis.com/my-log-archive-bucket \
  --log-filter='' \
  --include-children

# Create a sink to Pub/Sub for streaming to external SIEM
gcloud logging sinks create logs-to-pubsub \
  pubsub.googleapis.com/projects/<PROJECT_ID>/topics/log-stream \
  --log-filter='severity>=WARNING'

# List / update / delete sinks
gcloud logging sinks list
gcloud logging sinks update firewall-logs-to-bq --log-filter='NEW_FILTER'
gcloud logging sinks delete firewall-logs-to-bq
```

## 2.6 Log Buckets

Storage containers for logs within Cloud Logging itself (distinct from Cloud Storage buckets).

- **Regional or global** location
- **Retention**: configurable per bucket, 1–3650 days (default 30 days for `_Default`, 400 for `_Required`)
- **Locking**: once locked, retention can only increase, never decrease/delete early — used for compliance
- **Views**: sub-filters over a bucket to restrict what a given IAM principal can see within it (e.g. give a team visibility into only their service's logs within a shared bucket)
- **CMEK**: customer-managed encryption keys for the bucket, for extra compliance control

**Console steps — create a custom log bucket with 7-year retention (interview scenario #5):**
1. Logging → **Logs Storage** → **Create Bucket**.
2. Name (e.g. `audit-logs-7yr`), region, retention = `2555` days (~7 years), enable **Locked** if required for compliance.
3. Then create a sink routing audit logs into this bucket (see 2.5), and adjust `_Default` bucket retention to 30 days for app logs.

```bash
# Create a custom log bucket, 7-year retention, locked
gcloud logging buckets create audit-logs-7yr \
  --location=us-central1 \
  --retention-days=2555

gcloud logging buckets update audit-logs-7yr \
  --location=us-central1 \
  --locked

# Route audit logs (Admin Activity/Data Access) into it
gcloud logging sinks create audit-to-7yr-bucket \
  logging.googleapis.com/projects/<PROJECT_ID>/locations/us-central1/buckets/audit-logs-7yr \
  --log-filter='logName:"logs/cloudaudit.googleapis.com"'

# Set _Default bucket retention to 30 days for application logs
gcloud logging buckets update _Default \
  --location=global \
  --retention-days=30

# Create a log view restricting visibility to one service's logs
gcloud logging views create team-a-view \
  --bucket=audit-logs-7yr --location=us-central1 \
  --log-filter='resource.labels.service_name="team-a-service"'
```

## 2.7 Log Explorer

Console tool for interactive log search.

**Console steps:**
1. Logging → **Logs Explorer**.
2. Use the **Query builder** (dropdowns for resource type, log name, severity) or write raw queries in the **Query editor** using Cloud Logging query language.
3. Example query: `resource.type="gce_instance" AND severity>=ERROR AND timestamp>="2026-07-01T00:00:00Z"`.
4. **Save query** (star icon) for reuse.
5. **Actions → Create sink** or **Create metric** directly from a query.
6. **Download** results as JSON/CSV, or **Export** via a sink.

```bash
# Equivalent query from the CLI
gcloud logging read \
  'resource.type="gce_instance" AND severity>=ERROR AND timestamp>="2026-07-01T00:00:00Z"' \
  --limit=50 --format=json
```

## 2.8 Logs-based Metrics

Turn log queries into metrics you can alert/dashboard on.

- **Counter metric** — counts matching log entries per interval.
- **Distribution metric** — extracts a numeric field from matching entries (e.g. request latency from a JSON log field) into a histogram.

**Console steps:**
1. Logging → Logs Explorer → run/refine your query.
2. **Actions → Create metric**.
3. Choose type (Counter/Distribution), name it, for Distribution specify the field to extract as the value.
4. Save — it now appears in Monitoring → Metrics Explorer under `logging.googleapis.com/user/<metric_name>`, usable in dashboards and alert policies exactly like any other metric.

```bash
# Create a counter logs-based metric
gcloud logging metrics create error_count \
  --description="Count of ERROR severity log entries" \
  --log-filter='severity=ERROR'

# Create a distribution metric extracting a numeric field
gcloud logging metrics create request_latency \
  --description="Request latency distribution" \
  --log-filter='jsonPayload.latency_ms>0' \
  --value-extractor='EXTRACT(jsonPayload.latency_ms)' \
  --bucket-options=exponential,growth-factor=2,scale=1,num-finite-buckets=64

# List / describe
gcloud logging metrics list
gcloud logging metrics describe error_count
```
Then wire it to an alert exactly as in section 1.7 (`metric.type="logging.googleapis.com/user/error_count"`).

## 2.9 Audit Logs (recap with IAM angle)

```bash
# Read only Admin Activity audit logs for a project
gcloud logging read 'logName="projects/<PROJECT_ID>/logs/cloudaudit.googleapis.com%2Factivity"' --limit=20

# Read Data Access audit logs
gcloud logging read 'logName="projects/<PROJECT_ID>/logs/cloudaudit.googleapis.com%2Fdata_access"' --limit=20

# Read Policy Denied logs (useful for debugging VPC-SC / Org Policy blocks)
gcloud logging read 'logName="projects/<PROJECT_ID>/logs/cloudaudit.googleapis.com%2Fpolicy"' --limit=20
```

## 2.10 Log Analytics (SQL over logs)

Log Analytics lets you run **SQL** directly against a log bucket (must be a log-analytics-enabled bucket) — great for ad-hoc investigation without exporting to BigQuery, or you can link the bucket to BigQuery for federated SQL from BigQuery itself.

**Console steps:**
1. Logging → **Logs Storage** → select bucket → toggle **Upgrade to use Log Analytics** (enables SQL).
2. Logging → **Log Analytics** → write SQL against the bucket's generated view, e.g.:
```sql
SELECT
  timestamp, severity, resource.labels.instance_id, textPayload
FROM
  `my-project.global._Default._AllLogs`
WHERE
  severity = 'ERROR'
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)
ORDER BY timestamp DESC
LIMIT 100
```
3. Optional: **Link to BigQuery** dataset so you can join log data with other BigQuery tables.

```bash
# Enable Log Analytics on a bucket (upgrade)
gcloud logging buckets update _Default \
  --location=global \
  --enable-analytics

# Create a linked BigQuery dataset view over the bucket
gcloud logging links create my-bq-link \
  --bucket=_Default --location=global \
  --dataset=projects/<PROJECT_ID>/datasets/log_analytics_view
```

---

# PART 3 — CLOUD TRACE

## 3.1 What is Cloud Trace?

Distributed tracing system that captures **latency data** as requests propagate across services, letting you see where time is spent across a call chain (e.g. frontend → auth service → DB) — essential for diagnosing "app is slow but VM metrics look normal" type issues (interview scenario #2), since the bottleneck is often a downstream dependency, not the host itself.

## 3.2 Core Concepts

- **Trace** — the full record of one request's journey through the system, identified by a `trace_id`.
- **Span** — a single timed operation within a trace (e.g. "call to payments-service", "SQL query"), with a start time, duration, and its own `span_id`.
- **Root span** — the first span, representing the overall request (e.g. the incoming HTTP call).
- **Parent/Child span** — spans nest to represent sub-operations; a child span's duration should fall within its parent's.
- **Context propagation** — passing `trace_id`/`span_id` between services (typically via HTTP headers like `traceparent` in the W3C Trace Context standard, or the legacy `X-Cloud-Trace-Context` header) so spans from different services stitch into one trace.

## 3.3 Instrumentation

**OpenTelemetry** is the recommended, vendor-neutral SDK for instrumenting apps; it exports to Cloud Trace via the OTLP/Cloud Trace exporter. Auto-instrumentation covers common frameworks/libraries (HTTP servers, gRPC, SQL clients) with minimal code; manual instrumentation lets you add custom spans around specific business logic.

**Console/setup steps:**
1. Enable the API:
```bash
gcloud services enable cloudtrace.googleapis.com
```
2. Grant the app's service account the trace-writer role:
```bash
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<APP_SA_EMAIL>" \
  --role="roles/cloudtrace.agent"
```
3. Add the OpenTelemetry SDK + Cloud Trace exporter to your app (Node.js example):
```bash
npm install @opentelemetry/api @opentelemetry/sdk-trace-node \
  @opentelemetry/exporter-trace-otlp-http @google-cloud/opentelemetry-cloud-trace-exporter
```
```javascript
// tracing.js
const { NodeSDK } = require('@opentelemetry/sdk-trace-node');
const { TraceExporter } = require('@google-cloud/opentelemetry-cloud-trace-exporter');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  traceExporter: new TraceExporter(),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
```
4. Manual span example:
```javascript
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('my-app');

async function processOrder(order) {
  return tracer.startActiveSpan('processOrder', async (span) => {
    span.setAttribute('order.id', order.id);
    try {
      await chargePayment(order);   // creates a child span if instrumented
    } finally {
      span.end();
    }
  });
}
```
GKE/Cloud Run workloads typically don't need extra IAM setup beyond the workload identity / default service account already having `roles/cloudtrace.agent`.

## 3.4 Trace Analysis

**Console steps:**
1. **Trace → Trace Explorer** — list/filter traces by URI, latency, time range.
2. Click a trace to see the **waterfall / timeline view**: each span as a horizontal bar, nested by parent/child, showing exact start offset and duration — instantly reveals which downstream call dominates total latency.
3. **Trace → Analysis Reports** — GCP auto-generates latency distribution reports comparing a time window against a baseline, flagging regressions.
4. Use **Trace ID lookup** to jump straight to one request if you have the ID (e.g. from a user bug report or correlated log entry's `trace` field — Cloud Logging entries written within an active trace context automatically link back to the corresponding Cloud Trace trace).

```bash
# List recent traces
gcloud beta trace traces list --project=<PROJECT_ID>

# Describe a specific trace by ID
gcloud beta trace traces describe <TRACE_ID> --project=<PROJECT_ID>
```

**Bottleneck/dependency-analysis workflow (ties back to interview scenario #8 — tracing a request across microservices):**
1. Ensure context propagation headers pass through every hop (load balancer, service mesh, app frameworks — most GCP-managed products like Cloud Run, GKE with Anthos Service Mesh, and App Engine propagate automatically).
2. Reproduce/find the slow request → get its `trace_id` (from response header, or a log entry's `trace` field).
3. Open in Trace Explorer → waterfall view → find the widest span → that's your bottleneck (e.g. a slow downstream DB query span nested three levels deep, invisible to VM-level CPU/memory metrics).
4. Cross-reference with Cloud Logging (filter by the same `trace_id`) to see the actual error/query text logged during that span.
5. Cross-reference with Cloud Profiler if the bottleneck is CPU-bound within a single service, not I/O-bound across services.

---

# PART 4 — CLOUD PROFILER

Continuous, low-overhead **production profiling** — different from Trace (per-request latency across services): Profiler tells you *which functions/lines* burn CPU or allocate memory *inside one process*, sampled continuously with negligible overhead (~sub-1%), so you don't have to reproduce load in staging.

## 4.1 Profile Types
- **CPU time** — wall-clock time spent executing each function.
- **Heap** — memory allocated and *still held* at sampling time (good for leak-hunting).
- **Allocated memory** — total memory allocated over time, including freed (good for GC pressure/churn).
- **Thread/Contention** — time blocked on locks/synchronization.
- **Wall-clock time** — end-to-end time per function including I/O waits (useful when CPU profile looks idle but the function is still slow).

## 4.2 Setup

```bash
gcloud services enable cloudprofiler.googleapis.com

gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<APP_SA_EMAIL>" \
  --role="roles/cloudprofiler.agent"
```

Node.js example:
```bash
npm install @google-cloud/profiler
```
```javascript
require('@google-cloud/profiler').start({
  serviceContext: {
    service: 'checkout-service',
    version: '1.4.2',
  },
});
// then the rest of your app entrypoint
```
Java/Go/Python have equivalent agent libraries; for Java it's typically a `-agentpath` JVM flag pointing at the profiler agent `.so`, no code change required.

## 4.3 Console Steps — Reading a Profile

1. Console → **Profiler**.
2. Filter by **Service** and **Version**, choose **Profile type** (CPU/Heap/Wall).
3. View the **flame graph**: width = proportion of samples in that function; click to zoom into a subtree.
4. Compare two time windows (e.g. before/after a deploy) to spot regressions.

**Interview framing:** Profiler answers *"why is this one service using so much CPU/memory"* at the code level; Trace answers *"where does time go across a multi-service request"*; Monitoring answers *"is the VM/container as a whole under stress."* They're complementary layers.

---

# PART 5 — ERROR REPORTING

Automatically aggregates and groups exceptions/stack traces from your logs and app frameworks into unique **error groups**, tracks their frequency/first-seen/last-seen, and can alert on new or spiking errors.

## 5.1 How Errors Get Collected
- **Automatic**: any log entry with `severity=ERROR` (or higher) that looks like an exception (has a recognizable stack trace format) is picked up automatically from Cloud Logging — no extra setup for many runtimes (App Engine, Cloud Functions, Cloud Run, GKE with common language stack traces).
- **Manual/SDK**: use the Error Reporting client library to explicitly report handled exceptions.

```bash
gcloud services enable clouderrorreporting.googleapis.com
```
```javascript
const {ErrorReporting} = require('@google-cloud/error-reporting');
const errors = new ErrorReporting();

try {
  riskyOperation();
} catch (e) {
  errors.report(e);
}
```

## 5.2 Error Grouping & Stack Trace

Error Reporting groups by a fingerprint derived from the exception type + stack trace shape, so 10,000 occurrences of the same `NullPointerException` at the same line show up as **one group** with a count, not 10,000 separate alerts — critical for noise reduction.

## 5.3 Console Steps

1. Console → **Error Reporting**.
2. See a table of error groups: message, count, affected users (if available), first/last seen.
3. Click a group → full stack trace, sample log entries, occurrence timeline, and a direct **Create Alert** button.
4. **Error Notifications**: Error Reporting → Settings → enable email notifications for new error types (distinct from Monitoring alert policies, though you can also build a logs-based metric + alert policy off `severity=ERROR` for more control over thresholds).

```bash
# List/describe error groups (API-based; no dedicated gcloud group, use REST)
curl -X GET \
  "https://clouderrorreporting.googleapis.com/v1beta1/projects/<PROJECT_ID>/groupStats" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)"
```

---

# PART 6 — MANAGED SERVICE FOR PROMETHEUS (Deep Dive)

## 6.1 Architecture

```
[App/Exporter emits /metrics endpoint]
        │  scraped by
        ▼
[Collector: managed by GMP, runs as a GKE DaemonSet, OR self-deployed]
        │  remote-writes to
        ▼
[Google-managed, globally-scalable Prometheus-compatible storage]
        │
        ├──► Query via PromQL (Console Metrics Explorer, Grafana, or API)
        └──► Alerting via AlertManager (self-hosted or Google Cloud Managed rules)
```
Fully compatible with existing **PromQL**, **ServiceMonitor/PodMonitoring CRDs**, and exporters — no rewrite needed when migrating from self-managed Prometheus.

## 6.2 Enabling & Scraping (recap + rules)

```bash
gcloud container clusters update <CLUSTER_NAME> --zone=us-central1-a \
  --enable-managed-prometheus
```
Kubernetes-native scrape config (applied via `kubectl`, not `gcloud`):
```yaml
apiVersion: monitoring.googleapis.com/v1
kind: PodMonitoring
metadata:
  name: redis-monitor
spec:
  selector:
    matchLabels: {app: redis}
  endpoints:
    - port: metrics
      interval: 30s
```
Recording/alerting rules can be defined as `GlobalRules`/`Rules` CRDs, evaluated server-side by GMP:
```yaml
apiVersion: monitoring.googleapis.com/v1
kind: Rules
metadata:
  name: redis-rules
spec:
  groups:
    - name: redis.rules
      rules:
        - alert: RedisDown
          expr: up{job="redis"} == 0
          for: 5m
```

## 6.3 AlertManager

You can run **self-managed AlertManager** (standard Prometheus ecosystem tool) pointed at GMP's rule evaluation output, or route via Cloud Monitoring's own notification channels using an MQL/PromQL-based alert policy in the Console — teams already invested in AlertManager configs (routing trees, silences, inhibition rules) typically keep AlertManager and just swap the storage backend to GMP.

## 6.4 Grafana Integration

Point Grafana at the GMP Prometheus-compatible query endpoint:
```
https://monitoring.googleapis.com/v1/projects/<PROJECT_ID>/location/global/prometheus
```
Auth via a Google service account key or Workload Identity, added as a standard "Prometheus" datasource in Grafana — existing Grafana dashboards built on PromQL work with zero query changes.

---

# PART 7 — OPENTELEMETRY

## 7.1 Architecture

```
[App code + auto-instrumentation libraries]
        │  emits OTLP (metrics, logs, traces)
        ▼
[OpenTelemetry Collector]  (Receivers → Processors → Exporters pipeline)
        │
        ├──► Exporter: Cloud Trace
        ├──► Exporter: Cloud Monitoring
        └──► Exporter: Cloud Logging
```
- **Receivers** — ingest telemetry (OTLP gRPC/HTTP, Prometheus scrape, etc.).
- **Processors** — transform in-flight (batch, filter, add resource attributes, sample).
- **Exporters** — ship to backend(s) — can fan out to multiple simultaneously (e.g. Cloud + a third-party APM).

Collector config example (`otel-collector-config.yaml`):
```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:
processors:
  batch:
  resourcedetection:
    detectors: [gcp]
exporters:
  googlecloud:
    project: "<PROJECT_ID>"
  googlecloudtrace:
    project: "<PROJECT_ID>"
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, resourcedetection]
      exporters: [googlecloudtrace]
    metrics:
      receivers: [otlp]
      processors: [batch, resourcedetection]
      exporters: [googlecloud]
```
Deploy as a sidecar, DaemonSet, or standalone Deployment on GKE:
```bash
kubectl apply -f otel-collector-config.yaml
kubectl apply -f otel-collector-deployment.yaml
```

## 7.2 Context Propagation

OpenTelemetry uses the **W3C Trace Context** standard (`traceparent`/`tracestate` HTTP headers) by default, ensuring spans across services (even non-GCP ones) stitch into a single trace — this is what makes cross-microservice tracing (Part 3.4) work end-to-end.

---

# PART 8 — MONITORING KUBERNETES (GKE)

## 8.1 What's Collected

GKE integrates Cloud Monitoring/Logging by default (**GKE Monitoring / "Cloud Operations for GKE"**) at these levels:
- **Cluster metrics** — node count, cluster-wide resource usage.
- **Control plane metrics** — API server latency/request rate, etcd, scheduler (visible for Standard clusters; largely abstracted away on Autopilot).
- **Node metrics** — CPU/memory/disk/network per node (same as Compute Engine metrics, `k8s_node` resource type).
- **Pod / Workload / Container metrics** — per-pod CPU/memory usage vs requests/limits, restart counts, `k8s_container` resource type.

## 8.2 Console Steps

1. Console → **Kubernetes Engine → Clusters → select cluster → Observability** tab — pre-built dashboards for CPU/memory/network at cluster, node, and workload level.
2. **Monitoring → Dashboards → GKE** (auto-populated dashboard) for a fleet-wide view.
3. **Logging → Logs Explorer**, filter `resource.type="k8s_container"` and narrow by `resource.labels.pod_name` / `namespace_name` / `container_name`.

```bash
# Ensure monitoring + logging are enabled (on by default for new clusters)
gcloud container clusters update <CLUSTER_NAME> --zone=us-central1-a \
  --monitoring=SYSTEM,WORKLOAD \
  --logging=SYSTEM,WORKLOAD

# Check current config
gcloud container clusters describe <CLUSTER_NAME> --zone=us-central1-a \
  --format="value(monitoringConfig,loggingConfig)"
```

## 8.3 Common Queries

```bash
# Pods with high restart counts, last 1 hour
gcloud logging read \
  'resource.type="k8s_pod" AND jsonPayload.reason="BackOff"' \
  --freshness=1h --limit=50

# Container OOMKilled events
gcloud logging read \
  'resource.type="k8s_node" AND jsonPayload.message:"oom-kill"' \
  --freshness=1h --limit=50
```
MQL for container memory vs. limit:
```
fetch k8s_container
| metric 'kubernetes.io/container/memory/used_bytes'
| filter resource.pod_name == 'my-pod'
| group_by [resource.container_name], mean(value.used_bytes)
```

---

# PART 9 — MONITORING COMPUTE ENGINE

## 9.1 Metrics Available Without an Agent (system metrics)
CPU utilization, disk read/write bytes & ops, network bytes in/out, uptime — collected automatically by the hypervisor layer.

## 9.2 Metrics Requiring Ops Agent
Memory usage/percent, disk usage **percent** (vs. raw bytes), swap, per-process CPU/memory, custom app logs. (This is the classic interview trap: "why don't I see memory metrics for my VM?" → because memory isn't hypervisor-visible, it needs the in-guest Ops Agent.)

```bash
# Install Ops Agent (see Part 1 for full script) then verify metrics are flowing:
gcloud monitoring time-series list \
  --filter='metric.type="agent.googleapis.com/memory/percent_used" resource.labels.instance_id="<INSTANCE_ID>"' \
  --interval-start-time="$(date -u -d '-10 min' +%Y-%m-%dT%H:%M:%SZ)" \
  --interval-end-time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## 9.3 Process-Level Monitoring
Ops Agent can be configured to report top-N processes by CPU/memory via its metrics receiver config in `/etc/google-cloud-ops-agent/config.yaml`:
```yaml
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  processors:
    metrics_filter:
      type: exclude_metrics
      metrics_pattern: []
  service:
    pipelines:
      pipeline1:
        receivers: [hostmetrics]
```

---

# PART 10 — MONITORING CLOUD SQL

## 10.1 Key Metrics
- `cloudsql.googleapis.com/database/cpu/utilization`
- `cloudsql.googleapis.com/database/memory/utilization`
- `cloudsql.googleapis.com/database/disk/utilization` and `.../disk/bytes_used`
- `cloudsql.googleapis.com/database/network/connections` (current connections vs. `max_connections`)
- `cloudsql.googleapis.com/database/mysql/queries` or `postgresql/...` for QPS
- `cloudsql.googleapis.com/database/replication/replica_lag` — critical for read-replica health

## 10.2 Console Steps
1. Console → **SQL → select instance → Monitoring** tab — pre-built charts for CPU, memory, storage, connections, replication lag.
2. **Query Insights** (SQL instance → Query Insights) — identifies slow/expensive queries, shows query plans, tags by query fingerprint. This is usually the fastest path for "why is my Cloud SQL slow" beyond generic CPU/memory metrics.

```bash
# Enable Query Insights
gcloud sql instances patch <INSTANCE_NAME> \
  --insights-config-query-insights-enabled \
  --insights-config-record-application-tags \
  --insights-config-record-client-address

# Alert on replication lag > 60s
gcloud alpha monitoring policies create --policy-from-file=replica-lag-alert.yaml
```
```yaml
# replica-lag-alert.yaml
displayName: "Cloud SQL replica lag > 60s"
combiner: OR
conditions:
  - displayName: "Replica lag"
    conditionThreshold:
      filter: >
        metric.type="cloudsql.googleapis.com/database/replication/replica_lag"
        resource.type="cloudsql_database"
      comparison: COMPARISON_GT
      thresholdValue: 60
      duration: 120s
      aggregations:
        - alignmentPeriod: 60s
          perSeriesAligner: ALIGN_MEAN
notificationChannels: ["projects/<PROJECT_ID>/notificationChannels/<CHANNEL_ID>"]
```

---

# PART 11 — MONITORING LOAD BALANCERS

## 11.1 Key Metrics (HTTP(S) Load Balancer)
- `loadbalancing.googleapis.com/https/backend_latencies` — time from LB to backend response (distribution; check p50/p95/p99).
- `loadbalancing.googleapis.com/https/request_count` — sliceable by `response_code_class` (2xx/4xx/5xx), `backend_target_name`.
- `loadbalancing.googleapis.com/https/backend_request_count` and backend **health state** (via backend service health checks).
- SSL: certificate expiry, handshake metrics.

## 11.2 Console Steps
1. Console → **Network Services → Load Balancing → select LB → Monitoring** tab — request volume, latency percentiles, error rate by backend.
2. **Backend health**: Load Balancing → select backend service → **Health checks** column shows healthy/unhealthy instance counts per backend group.

```bash
# Check backend health directly
gcloud compute backend-services get-health <BACKEND_SERVICE_NAME> --global

# Alert on 5xx rate (ratio-style MQL-backed alert, conceptually)
gcloud alpha monitoring policies create --policy-from-file=lb-5xx-alert.yaml
```
```yaml
displayName: "LB 5xx error rate high"
combiner: OR
conditions:
  - displayName: "5xx responses"
    conditionThreshold:
      filter: >
        metric.type="loadbalancing.googleapis.com/https/request_count"
        resource.type="https_lb_rule"
        metric.label.response_code_class="500"
      comparison: COMPARISON_GT
      thresholdValue: 10
      duration: 300s
      aggregations:
        - alignmentPeriod: 60s
          perSeriesAligner: ALIGN_RATE
notificationChannels: ["projects/<PROJECT_ID>/notificationChannels/<CHANNEL_ID>"]
```

---

# PART 12 — MONITORING CLOUD STORAGE

## 12.1 Key Metrics
- `storage.googleapis.com/storage/object_count` — objects per bucket (sliceable by storage class).
- `storage.googleapis.com/storage/total_bytes` — bucket size.
- `storage.googleapis.com/api/request_count` — API requests, sliceable by `response_code`, `method`.
- `storage.googleapis.com/network/sent_bytes` / `received_bytes`.
- Latency isn't emitted as a standalone GCS metric by default — commonly derived by instrumenting client-side calls or via logs-based distribution metrics from Data Access logs (needs Data Access audit logging enabled).

## 12.2 Console/gcloud

```bash
# Bucket size via gcloud (uses gsutil under the hood for this specific stat, or Monitoring API)
gsutil du -sh gs://my-bucket

# Query object count metric
gcloud monitoring time-series list \
  --filter='metric.type="storage.googleapis.com/storage/object_count" resource.labels.bucket_name="my-bucket"' \
  --interval-start-time="$(date -u -d '-1 hour' +%Y-%m-%dT%H:%M:%SZ)" \
  --interval-end-time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---

# PART 13 — IAM FOR MONITORING & LOGGING

| Role | Purpose |
|---|---|
| `roles/monitoring.viewer` | Read-only: dashboards, metrics, alert policies. |
| `roles/monitoring.editor` | Create/edit dashboards, alert policies, uptime checks; cannot manage IAM. |
| `roles/monitoring.admin` | Full control including notification channel management. |
| `roles/logging.viewer` | Read logs (excluding Data Access logs by default via a stricter role split). |
| `roles/logging.privateLogViewer` | Adds ability to read Data Access / Policy Denied logs. |
| `roles/logging.admin` | Full control: buckets, sinks, views, retention. |
| `roles/logging.configWriter` | Manage sinks/log routing config without full admin (log-router-only scope). |
| `roles/logging.logWriter` | Write-only — typical for app/service-account log-writing identities (least privilege for producers). |

**Least-privilege pattern:**
```bash
# App/service identity: write-only
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<APP_SA>" \
  --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="serviceAccount:<APP_SA>" \
  --role="roles/monitoring.metricWriter"

# On-call engineer: read + alert management, no destructive config changes
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="user:oncall@example.com" \
  --role="roles/monitoring.editor"

gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="user:oncall@example.com" \
  --role="roles/logging.viewer"

# Security team: needs Data Access logs too
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member="group:security-team@example.com" \
  --role="roles/logging.privateLogViewer"
```

---

# PART 14 — LOGGING & MONITORING WITH TERRAFORM

```hcl
# Notification channel
resource "google_monitoring_notification_channel" "email" {
  display_name = "Ops Team Email"
  type         = "email"
  labels = {
    email_address = "ops-team@example.com"
  }
}

# Alert policy
resource "google_monitoring_alert_policy" "disk_usage" {
  display_name = "Disk usage > 80%"
  combiner     = "OR"
  conditions {
    display_name = "Disk utilization above 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/disk/percent_used\" resource.type=\"gce_instance\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Dashboard (JSON embedded)
resource "google_monitoring_dashboard" "vm_overview" {
  dashboard_json = file("${path.module}/dashboard.json")
}

# Log bucket, 7-year retention, locked
resource "google_logging_project_bucket_config" "audit_7yr" {
  project        = var.project_id
  location       = "us-central1"
  bucket_id      = "audit-logs-7yr"
  retention_days = 2555
  locked         = true
}

# Sink routing audit logs to that bucket
resource "google_logging_project_sink" "audit_sink" {
  name        = "audit-to-7yr-bucket"
  destination = "logging.googleapis.com/${google_logging_project_bucket_config.audit_7yr.id}"
  filter      = "logName:\"logs/cloudaudit.googleapis.com\""
}

# Sink to BigQuery for firewall logs
resource "google_bigquery_dataset" "firewall_logs" {
  dataset_id = "firewall_logs"
  location   = "US"
}

resource "google_logging_project_sink" "firewall_to_bq" {
  name        = "firewall-logs-to-bq"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.firewall_logs.dataset_id}"
  filter      = "logName=\"projects/${var.project_id}/logs/compute.googleapis.com%2Ffirewall\""
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  dataset_id = google_bigquery_dataset.firewall_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.firewall_to_bq.writer_identity
}

# Uptime check
resource "google_monitoring_uptime_check_config" "api_health" {
  display_name = "Public API Uptime"
  timeout      = "10s"
  period       = "60s"
  http_check {
    path      = "/health"
    port      = 443
    use_ssl   = true
  }
  monitored_resource {
    type = "uptime_url"
    labels = {
      host = "api.example.com"
    }
  }
}

# IAM: least-privilege log writer for an app SA
resource "google_project_iam_member" "app_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.app_service_account}"
}
```

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

# PART 15 — BEST PRACTICES

- **Centralized logging/monitoring** — use a Metrics Scope (Part 1) and cross-project log sinks so one team can observe many projects without duplicating config in each.
- **Log retention policies** — keep the `_Default` bucket short (30 days) for high-volume app logs; route audit/compliance logs to a separate, longer-retention **locked** bucket — don't pay to retain everything at the same TTL.
- **Cost optimization** — enable Data Access logs selectively, not globally; export cold data to Cloud Storage instead of keeping it "hot" in a Log bucket; use exclusion filters on sinks to drop known-noisy log lines (health checks, readiness probes) before they're even stored.
- **Naming standards** — consistent prefixes for sinks/metrics/alert policies (`team-service-purpose`) so ownership is obvious at 2am.
- **Dashboard design** — one dashboard per service, "golden signals" first (latency, traffic, errors, saturation) at the top, drill-down widgets below; avoid one giant dashboard with 50 unrelated widgets.
- **Alert noise reduction** — alert on symptoms (SLO burn rate, user-facing error rate) rather than every possible cause metric; use `duration` fields to require sustained breaches, not single-sample blips; consolidate related conditions into one policy with `combiner: OR` rather than firing five separate pages for one incident.
- **SLI/SLO-based monitoring** — prefer error-budget/burn-rate alerts over dozens of static per-metric thresholds; they scale better and directly reflect user impact.
- **Multi-project monitoring** — Metrics Scopes + shared VPC/log sinks; avoid replicating alert policies per project when a single scoped policy can cover a fleet.
- **Least privilege IAM** — `logWriter`/`metricWriter` for producers, `viewer` for most humans, `admin` for a small platform team only (Part 13).
- **Secure log storage** — CMEK on sensitive log buckets, restrict `privateLogViewer` tightly since Data Access/Policy Denied logs can contain sensitive request detail.
- **Use custom metrics only when necessary** — custom metrics have quotas/cost; prefer existing system/agent/logs-based metrics wherever they already cover the signal you need.
- **Archive logs to Cloud Storage** — cheapest long-term retention path for compliance logs you rarely query; pair with a **BigQuery** sink instead if you need to actually run analytics against historical logs regularly.

---

# PART 16 — ALL 10 INTERVIEW SCENARIOS (full worked answers)

**"VM CPU reached 95% — how would you investigate?"**
1. Monitoring → Metrics Explorer → `compute.googleapis.com/instance/cpu/utilization` for that instance, check if sustained or spiky.
2. `gcloud compute instances describe <VM> --zone=<ZONE>` for machine type/sizing.
3. SSH in, run `top`/`htop` to find the offending process; check Ops Agent process-level metrics if enabled (Part 9.3).
4. Check Logs Explorer for app errors/restarts around the same time.
5. Decide: right-size the machine type, add autoscaling (MIG), or fix a runaway process/query.

**"An application is slow but VM metrics look normal"**
→ Points away from the host and toward a dependency. Use **Cloud Trace** (Part 3.4) to find which downstream span/service dominates latency, then **Cloud Logging** filtered by `trace_id` for the specific error/slow-query detail, and **Cloud Profiler** (Part 4) if it turns out to be in-process CPU time rather than a network hop.

**"A GKE pod keeps restarting — what monitoring tools would you use?"**
1. `kubectl get pods` / `kubectl describe pod <pod>` for `CrashLoopBackOff` reason and events.
2. Monitoring → GKE dashboards (Part 8.2) → container restart count metric, and memory/CPU usage vs configured limits (OOMKilled is a very common cause).
3. Logging → Logs Explorer, filter `resource.type="k8s_container" AND resource.labels.pod_name="<pod>"` (Part 8.3) for the app's own error output right before each crash.
4. Check liveness/readiness probe configuration if restarts correlate with probe failures rather than crashes.

**"You need an email alert when disk usage exceeds 80%"**
→ Fully worked in section 1.7 (`cpu-alert.yaml` pattern, swap metric to `compute.googleapis.com/instance/disk/percent_used`) and Part 14 Terraform `google_monitoring_alert_policy.disk_usage`. Requires Ops Agent installed for percent-based disk metrics on the guest filesystem (raw byte metrics are available without the agent, but *percent used* needs it — same trap as memory metrics, 9.2).

**"Store audit logs for 7 years while keeping application logs for 30 days"**
→ Fully worked in section 2.6: custom **locked** log bucket at 2555-day retention + a sink filtering `logName:"cloudaudit.googleapis.com"` into it, while `_Default` stays at 30 days for everything else. Terraform version in Part 14.

**"Export firewall logs to BigQuery for security analysis"**
→ Fully worked in section 2.5: `gcloud logging sinks create ... bigquery.googleapis.com/...` with filter `logName="...compute.googleapis.com%2Ffirewall"`, then grant the sink's `writerIdentity` `roles/bigquery.dataEditor` on the dataset. Terraform version in Part 14. Once in BigQuery, typical follow-up is scheduled queries or a Looker Studio dashboard on denied-connection patterns.

**"Monitor a multi-region application with a single dashboard"**
1. Ensure a single **Metrics Scope** includes all regional projects if they're separate projects, or it's one project with regional resource labels if not.
2. Build one dashboard with widgets **grouped by `resource.label.region`** (or `zone`) so each chart shows one line per region on the same chart — e.g. LB latency widget grouped by `resource.labels.region`.
3. Add a **scorecard** widget per region for at-a-glance health, plus one aggregate "global" line for overall traffic/error-rate.
4. If using GKE across regions, tag workloads with a `region` label consistently so `group_by` in MQL/dashboard widgets works uniformly.

**"Trace a request across multiple microservices to identify latency"**
→ Fully worked in section 3.4: propagate `traceparent` headers end-to-end (OpenTelemetry default, Part 7.2), capture the `trace_id`, open Trace Explorer's waterfall view, find the widest span, cross-reference Logging filtered by that same `trace_id`.

**"Create an uptime check for a public API and notify Slack on failure"**
1. Create a **Slack notification channel** — one-time OAuth authorization of the Cloud Monitoring Slack app into your workspace via Console (Alerting → Notification Channels → Slack → Authorize), then it's reusable via `gcloud alpha monitoring channels create --type=slack`.
2. Create the **uptime check** against the API's health endpoint.
3. From the uptime check creation flow, directly attach the Slack channel (Console auto-generates an alert policy tied to that uptime check's `check_passed` metric), or create the alert policy manually filtering `metric.type="monitoring.googleapis.com/uptime_check/check_passed"` with `comparison: COMPARISON_EQ, thresholdValue: 0`.

**"Build an SLO with a 99.9% availability target and alert on error-budget burn"**
→ Fully worked in section 1.9: define the service, create the SLO (`goal: 0.999`, 30-day rolling window) via API/Console, then create a **multi-window burn-rate alert** (e.g., fast burn: 1-hour window at 14.4x burn rate catches a hard outage within ~2 min of budget-relevant impact; slow burn: 6-hour window at 6x burn rate catches a slow leak) — Console: Monitoring → Services → your SLO → **Create Alerting Policy** lets you pick these standard multi-window presets directly rather than hand-writing the MQL.

---

This completes coverage of the original outline: Cloud Monitoring, Cloud Logging, Cloud Trace, Cloud Profiler, Error Reporting, Managed Prometheus, OpenTelemetry, per-service monitoring (GKE/Compute/SQL/LB/Storage), IAM, Terraform, best practices, and all 10 interview scenarios.
