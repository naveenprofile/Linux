# Apache MIG Setup — Complete Guide (Single Zone + Multi-Zone + Extras)

This covers four things:
1. **Part A** — the single-zone setup we already built (recap)
2. **Part B** — full Console steps for converting/rebuilding it as a **multi-zone (regional) MIG**
3. **Part C** — topics we hadn't covered yet: static IP, HTTPS/domain, security (Cloud Armor), IAM, logging, cost control, backups, and failover testing
4. **Part D** — the whole setup as Terraform (regional MIG + health check + autoscaling + Load Balancer + Cloud Armor + static IP)

---

# Part A — Single Zone Setup (Recap)

## 1. Firewall Rules

### Allow HTTP traffic (public)
**VPC network → Firewall → Create Firewall Rule**
- Name: `allow-http`
- Network: `default`
- Direction: `Ingress`
- Targets: `Specified target tags`
- Target tags: `http-server`
- Source IPv4 ranges: `0.0.0.0/0`
- Protocols and ports: `TCP`, port `80`

### Allow Google health check probes
**VPC network → Firewall → Create Firewall Rule**
- Name: `allow-health-check`
- Network: `default`
- Direction: `Ingress`
- Targets: `Specified target tags`
- Target tags: `http-server`
- Source IPv4 ranges: `130.211.0.0/22, 35.191.0.0/16`
- Protocols and ports: `TCP`, port `80`

> ⚠️ This second rule was the root cause of our original churn — without it, health checks can't reach instances, so autohealing kills them in a loop.

---

## 2. Instance Template

**Compute Engine → Instance templates → Create instance template**
- Name: `apache-template`
- Machine type: `e2-medium` (or similar)
- Boot disk → Change:
  - OS: `Debian`
  - Version: `Debian 12 (bookworm)`
- Firewall: check **Allow HTTP traffic**
- Advanced options → Management → Automation → Startup script:
```bash
#!/bin/bash
apt-get update
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
echo "<h1>Served by $(hostname)</h1>" > /var/www/html/index.html
```

---

## 3. Managed Instance Group (MIG)

**Compute Engine → Instance groups → Create instance group**
- Type: `New managed instance group (stateless)`
- Name: `apache-mig`
- Instance template: `apache-template`
- Location: **Single zone** → `us-central1-a`
- Number of instances: `2`
- Port mapping (needed later for the Load Balancer): add port name `http`, port number `80`

> Health check and autoscaling were **not** attached at creation — added afterward, once the base MIG was confirmed stable.

---

## 4. Health Check

**Compute Engine → Health checks → Create Health Check**
- Name: `apache-health-check`
- Protocol: `HTTP`
- Port: `80`
- Request path: `/`
- Check interval / timeout / thresholds: defaults (5s / 5s / 2 / 2)

---

## 5. Autohealing

**Instance group → apache-mig → Configure (next to "Autohealing off")**
- Health check: `apache-health-check`
- On failed health check: `Default action`
- Updates during VM instance repair: `Update instance configuration`
- Save

Result confirmed: **100% healthy**, no instance churn.

---

## 6. Autoscaling

**Instance group → apache-mig → Configure (next to "Autoscaling")**
- Autoscaling mode: `On: add and remove instances to the group`
- Minimum number of instances: `2`
- Maximum number of instances: `4`
- Autoscaling signal: `CPU utilization`, target `60%`
- Initialization period: `120` seconds
- Stabilization period: `600` seconds (default)
- Save

**Tested by generating load:**
```bash
sudo apt-get install -y stress
stress --cpu 2 --timeout 300
```
Result: MIG scaled from 2 → 4 instances, then back down after load stopped.

---

## 7. Load Balancer

**Network Services → Load balancing → Create load balancer**
- Type: `Application Load Balancer (HTTP/HTTPS)`
- Scope: `Global external Application Load Balancer`

**Backend configuration:**
- Backend service name: `apache-backend`
- Backend type: `Instance group`
- Backend: `apache-mig`, port `80`, balancing mode `Utilization`
- Health check: `apache-health-check`

**Frontend configuration:**
- Name: `apache-frontend`
- Protocol: `HTTP`
- Port: `80`
- IP: ephemeral (or reserved static — see note below)

**Routing rules:** left as default (all traffic → `apache-backend`)

Result: `apache-lb` created, frontend IP `136.110.241.139`, backend showing **2 of 2 healthy**, tested working in browser.

> Optional (not done yet): reserve a static IP via **VPC network → IP addresses → Reserve External Static Address** (type: `Global`) before creating the LB frontend, so the IP never changes.

---

## 8. Monitoring & Alerting

### Notification channel
**Monitoring → Alerting → Edit Notification Channels**
- Added an Email channel

### Uptime check (site-down alert)
**Monitoring → Uptime checks → Create Uptime Check**
- Protocol: `HTTP`
- Resource type: `URL`
- Hostname: LB IP (`136.110.241.139`)
- Path: `/`
- Frequency: `1 minute`
- Alert: created inline, duration `1 minute`, notify via email
- Policy name: `apache-alert uptime failure`

### CPU alert
**Monitoring → Alerting → Create Policy**
- Metric: `VM Instance → CPU utilization`
- Filtered to `apache-mig` instances
- Condition: `is above 80%` for `5 minutes`
- Notify via email
- Policy name: `High CPU - apache-mig`

### LB error rate alert
**Monitoring → Alerting → Create Policy**
- Metric: `Loadbalancing → HTTPS/HTTP Backend Request Count`, filtered `response_code_class = 500`
- Condition: `is above 0` for `5 minutes`
- Notify via email
- Policy name: `LB 5xx errors`

**Verified working:** stopped instances manually → uptime alert fired → email received within ~1 minute → confirmed full chain (uptime check → policy → notification channel → inbox).

---

## Final result (single zone)

| Component | Config |
|---|---|
| VM OS | Debian 12, Apache installed via startup script |
| MIG location | Single zone — `us-central1-a` |
| Health check | HTTP, port 80, path `/` |
| Autohealing | On, using health check above |
| Autoscaling | Min 2, Max 4, CPU target 60%, init 120s, stabilization 600s |
| Load Balancer | Global external HTTP LB, backend = MIG |
| Alerting | Uptime, CPU, LB 5xx — all tested |

---

---

# Part B — Multi-Zone (Regional) MIG — Full Console Steps

The firewall rules, instance template, health check, and Load Balancer are **reused as-is** from Part A — you don't recreate those. The only new resource is the MIG itself, created with a regional (multi-zone) location instead of single-zone.

## B1. Decide: new MIG or convert the existing one?

Location (single-zone vs regional) **cannot be changed on an existing MIG** — it's set at creation and immutable. So:
- **Option 1 (recommended for testing):** create a second MIG, e.g. `apache-mig-regional`, alongside your existing one. Compare both, then delete the old one once satisfied.
- **Option 2:** delete `apache-mig` first, then recreate it with the same name but multi-zone location.

This guide assumes **Option 1** (new MIG, name it `apache-mig-regional`).

## B2. Create the Regional MIG

**Compute Engine → Instance groups → Create instance group**
- Type: `New managed instance group (stateless)`
- Name: `apache-mig-regional`
- Instance template: `apache-template` (same one from Part A — no changes needed)
- **Location: `Multiple zones`**
- **Region**: `us-central1`
- **Zones**: leave as "Any zone in selected region" (GCP auto-distributes), or click to manually pick specific zones (e.g. `us-central1-a`, `us-central1-b`, `us-central1-c`) if you want explicit control
- Number of instances: `3` (one per zone is a natural starting point for 3 zones — adjust based on your minimums)
- Port mapping: add port name `http`, port number `80` (same as before)
- Click **Create**

## B3. Attach the same Health Check

**apache-mig-regional → Configure (next to "Autohealing off")**
- Health check: `apache-health-check` (reuse the existing one — no need to create a new one)
- On failed health check: `Default action`
- Updates during VM instance repair: `Update instance configuration`
- Save

Confirm: Instance by health shows 100% healthy, and instances are distributed across zones (check the **Zone** column in VM instances — should show a mix of `us-central1-a`, `-b`, `-c` etc.)

## B4. Configure Autoscaling (same settings as before)

**apache-mig-regional → Configure (next to "Autoscaling")**
- Autoscaling mode: `On: add and remove instances to the group`
- Minimum number of instances: `3` (one per zone, adjust as needed)
- Maximum number of instances: `6`
- Autoscaling signal: `CPU utilization`, target `60%`
- Initialization period: `120` seconds
- Stabilization period: `600` seconds
- Save

> With a regional MIG, autoscaling and autohealing account for zone distribution automatically — GCP tries to keep instances balanced across zones as it scales.

## B5. Point the Load Balancer's backend at the new MIG

You don't need a new Load Balancer — just update the existing one's backend.

**Network Services → Load balancing → apache-lb → Edit**
- Go to **Backend configuration → apache-backend → Edit**
- Under **Backends**, click **Add backend**
  - Instance group: `apache-mig-regional`
  - Port: `80`
  - Balancing mode: `Utilization`
  - Click **Done**
- (Optional) Remove the old `apache-mig` backend once you've confirmed the regional one is healthy and serving traffic, to fully cut over
- Click **Update**

## B6. Verify

1. **apache-lb → Details** — Backend should show both `apache-mig` and `apache-mig-regional` (or just the regional one if you removed the old backend), all healthy
2. Load the LB's IP in browser a few times — refresh repeatedly, and you should see `Served by <hostname>` responses coming from instances in different zones
3. **Instance groups → apache-mig-regional → VM instances** — confirm the `Zone` column shows instances spread across multiple zones, not all in one

## B7. Test zone-level failure (the actual point of going multi-zone)

This is the real benefit multi-zone gives you over single-zone — worth proving it works:

1. Note which zone has the most instances currently (check the VM instances list)
2. **Stop or delete** all instances in that one zone only (select them by zone in the VM instances list → **Stop**)
3. Immediately test the LB URL in your browser — it should **keep responding**, served by instances in the remaining healthy zones
4. Watch the MIG Overview — autohealing/autoscaling should detect the gap and either restart those instances or create replacements, potentially in a different zone if the original is having issues
5. Resume/restart the stopped instances once you've confirmed the site stayed up throughout

If the site stayed reachable the whole time, multi-zone resilience is confirmed working.

## B8. Clean up the old single-zone MIG (once confident)

Once `apache-mig-regional` is verified stable and serving traffic through the LB:
1. Remove `apache-mig` (the old single-zone one) as a backend from `apache-backend`, if not already done in B5
2. Delete `apache-mig` — **Instance groups → apache-mig → Delete Group**

---

# Part C — Topics Not Yet Covered

These weren't part of the original build but are worth knowing about, roughly in order of relevance.

## C1. Reserve a Static IP for the Load Balancer

Right now your LB uses an ephemeral IP (stable in practice, but not guaranteed permanent). To lock it in:

**VPC network → IP addresses → Reserve External Static Address**
- Name: `apache-lb-ip`
- Network Service Tier: `Premium`
- IP version: `IPv4`
- Type: `Global`
- Click **Reserve**

Then attach it to the LB:
**apache-lb → Edit → Frontend configuration → Edit → IP address → select `apache-lb-ip` → Update**

## C2. Custom Domain + HTTPS

Requires owning a domain name.

1. **DNS**: at your domain registrar, add an **A record** pointing to your LB's static IP
2. **SSL Certificate**: **apache-lb → Edit → Frontend configuration → Add Frontend IP and port**
   - Protocol: `HTTPS`, Port: `443`
   - Certificate: create a **Google-managed certificate**, enter your domain
   - Google auto-issues the cert once DNS is verified (can take 15 min–few hours)
3. Optional: add an HTTP→HTTPS redirect so all traffic is forced to HTTPS

## C3. Security — Cloud Armor

Adds a WAF layer (DDoS protection, IP allow/block lists, rate limiting) in front of your Load Balancer.

**Network Security → Cloud Armor → Create Policy**
- Add rules like: rate limiting per IP, geo-blocking, or blocking known bad IP ranges
- Attach the policy to `apache-backend` under **Backend services → apache-backend → Edit → Backend security policy**

## C4. IAM — Least-privilege access

If more than one person will manage this project, avoid everyone using the Owner role:
- **IAM & Admin → IAM → Grant Access**
- Use scoped roles like `Compute Instance Admin (v1)`, `Compute Network Admin`, or `Monitoring Editor` instead of blanket `Owner`/`Editor`, based on what each person actually needs to do

## C5. Logging

Beyond alerting, actual request-level logs are useful for debugging traffic patterns or investigating incidents:
- **apache-backend → Edit → Logging → Enable** (currently disabled in your setup)
- Adjust sample rate (100% for low traffic, lower for high traffic to control cost)
- View logs via **Logging → Logs Explorer**, filter by `resource.type="http_load_balancer"`

## C6. Cost Awareness

- **Billing → Budgets & alerts** — set a monthly budget alert (e.g., alert at 50%/90%/100% of a $X threshold) so autoscaling scale-ups don't surprise you on the bill
- Autoscaling max of 4-6 `e2-medium` instances plus a global LB is modest, but worth having a budget alert as a safety net, especially while testing (like your `stress` load tests)

## C7. Backups / Snapshots (if you later add persistent data)

Your current setup is fully **stateless** (Apache serving static content baked into the image via startup script), so there's nothing to back up today. If you later add a database or persistent uploads:
- Use **Compute Engine → Snapshots** with a **Snapshot schedule** attached to any persistent disks
- Keep stateful data (databases, uploads) **off** the MIG instances themselves — use Cloud SQL or a separate persistent-disk-backed VM, since MIG instances can be destroyed/recreated at any time

## C8. Documentation / Infrastructure-as-Code (optional, longer-term)

Once this setup is finalized, consider capturing it as Terraform or Deployment Manager config instead of Console clicks — makes it reproducible, versionable, and easy to tear down/rebuild identically (e.g., for a staging environment). Not urgent, but worth knowing about as the setup matures.

---

*Summary: Part A is what you already have running. Part B gets you to multi-zone resilience using the same building blocks. Part C fills in the gaps — static IP, HTTPS, security, access control, logging, cost, and backups — for whenever you're ready to harden this further.*

---

# Part D — Terraform

This reproduces the **production version** of the setup (regional/multi-zone MIG + static IP + Cloud Armor), not the original single-zone build. Adjust variables as needed. HTTPS/domain is included as commented-out guidance since it depends on a domain you own.

## Directory structure

```
apache-mig-terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars   (you create this, gitignore it if it has secrets)
```

## `variables.tf`

```hcl
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region for the regional MIG and resources"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "Zones to distribute the MIG across"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "min_replicas" {
  type    = number
  default = 3
}

variable "max_replicas" {
  type    = number
  default = 6
}

variable "target_cpu_utilization" {
  type    = number
  default = 0.6
}
```

## `main.tf`

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------
# Network / Firewall
# ---------------------------

resource "google_compute_firewall" "allow_http" {
  name          = "allow-http"
  network       = "default"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "allow_health_check" {
  name          = "allow-health-check"
  network       = "default"
  direction     = "INGRESS"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

# ---------------------------
# Instance Template
# ---------------------------

resource "google_compute_instance_template" "apache_template" {
  name_prefix  = "apache-template-"
  machine_type = var.machine_type
  tags         = ["http-server"]

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {} # ephemeral public IP for each instance
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl enable apache2
    systemctl start apache2
    echo "<h1>Served by $(hostname)</h1>" > /var/www/html/index.html
  EOT

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------
# Health Check
# ---------------------------

resource "google_compute_health_check" "apache_health_check" {
  name                = "apache-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# ---------------------------
# Regional (multi-zone) MIG
# ---------------------------

resource "google_compute_region_instance_group_manager" "apache_mig_regional" {
  name               = "apache-mig-regional"
  region             = var.region
  base_instance_name = "apache-mig"

  version {
    instance_template = google_compute_instance_template.apache_template.id
  }

  target_size = var.min_replicas

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.apache_health_check.id
    initial_delay_sec = 120
  }

  distribution_policy_zones = var.zones
}

resource "google_compute_region_autoscaler" "apache_autoscaler" {
  name   = "apache-mig-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.apache_mig_regional.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 120

    cpu_utilization {
      target = var.target_cpu_utilization
    }
  }
}

# ---------------------------
# Static IP for Load Balancer
# ---------------------------

resource "google_compute_global_address" "apache_lb_ip" {
  name = "apache-lb-ip"
}

# ---------------------------
# Backend Service + Load Balancer (HTTP)
# ---------------------------

resource "google_compute_backend_service" "apache_backend" {
  name                  = "apache-backend"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 30
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group           = google_compute_region_instance_group_manager.apache_mig_regional.instance_group
    balancing_mode  = "UTILIZATION"
    max_utilization = 0.8
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_health_check.apache_health_check.id]

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  security_policy = google_compute_security_policy.apache_armor_policy.id
}

resource "google_compute_url_map" "apache_url_map" {
  name            = "apache-url-map"
  default_service = google_compute_backend_service.apache_backend.id
}

resource "google_compute_target_http_proxy" "apache_http_proxy" {
  name    = "apache-http-proxy"
  url_map = google_compute_url_map.apache_url_map.id
}

resource "google_compute_global_forwarding_rule" "apache_forwarding_rule" {
  name                  = "apache-forwarding-rule"
  target                = google_compute_target_http_proxy.apache_http_proxy.id
  port_range            = "80"
  ip_address             = google_compute_global_address.apache_lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

# ---------------------------
# Cloud Armor
# ---------------------------

resource "google_compute_security_policy" "apache_armor_policy" {
  name = "apache-armor-policy"

  # Rate limiting rule
  rule {
    action   = "throttle"
    priority = 1000

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      enforce_on_key = "IP"

      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }

  # Preconfigured WAF rule - SQLi
  rule {
    action   = "deny(403)"
    priority = 700

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }
  }

  # Preconfigured WAF rule - XSS
  rule {
    action   = "deny(403)"
    priority = 701

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
  }

  # Default rule (required - lowest priority, catches everything else)
  rule {
    action   = "allow"
    priority = 2147483647

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

# ---------------------------
# Monitoring: Uptime Check + Alert
# ---------------------------

resource "google_monitoring_uptime_check_config" "apache_uptime_check" {
  display_name = "apache-uptime-check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/"
    port         = 80
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_compute_global_address.apache_lb_ip.address
    }
  }
}

resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Email Alerts"
  type         = "email"

  labels = {
    email_address = "you@example.com" # <-- replace with your email
  }
}

resource "google_monitoring_alert_policy" "uptime_alert" {
  display_name = "apache-alert-uptime-failure"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failure"

    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.id]
}

resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "High-CPU-apache-mig"
  combiner     = "OR"

  conditions {
    display_name = "CPU above 80%"

    condition_threshold {
      filter          = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.id]
}
```

## `outputs.tf`

```hcl
output "load_balancer_ip" {
  description = "Public static IP of the Load Balancer"
  value       = google_compute_global_address.apache_lb_ip.address
}

output "mig_self_link" {
  value = google_compute_region_instance_group_manager.apache_mig_regional.self_link
}
```

## `terraform.tfvars` (example)

```hcl
project_id = "project-500af57b-8354-48a8-b74"
region     = "us-central1"
```

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Confirm the plan shows creation (not modification) of these resources if this is a fresh project. If you're importing this on top of *existing* Console-created resources with the same names, you'll need `terraform import` for each resource first, or Terraform will try to create duplicates and fail on name conflicts.

## Notes / things to adjust before running this for real

- **Email address** — replace `you@example.com` in the notification channel with your real address.
- **HTTPS** — not included here since it requires a domain you own. Once you have one, add a `google_compute_managed_ssl_certificate` resource, a `google_compute_target_https_proxy`, and a second `google_compute_global_forwarding_rule` on port 443. Happy to add this once you share the domain.
- **State file** — for anything beyond solo experimentation, use a remote backend (GCS bucket) instead of local state, so state isn't just sitting on your laptop:
  ```hcl
  terraform {
    backend "gcs" {
      bucket = "your-terraform-state-bucket"
      prefix = "apache-mig"
    }
  }
  ```
- **Cost warning** — running `terraform apply` on this creates real billable resources (regional MIG at min 3 instances, global LB, Cloud Armor policy). Run `terraform destroy` when you're done testing to avoid ongoing charges.
