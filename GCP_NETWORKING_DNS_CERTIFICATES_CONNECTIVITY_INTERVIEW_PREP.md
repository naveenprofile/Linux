# GCP Networking, DNS, Certificates & Connectivity — Interview Prep

## How interviewers frame this topic
Five threads, matching your responsibilities:
1. **VPC fundamentals** — subnets, firewall rules, routing, private connectivity — the core mental model.
2. **Load balancing** — L4 vs L7, and picking the right one for the scenario.
3. **DNS & certificates** — practical request/config/validation, not just "Cloud DNS exists."
4. **Hybrid connectivity** — GCP-to-on-prem/external, the classic VPN vs Interconnect decision.
5. **Troubleshooting** — this domain gets more scenario-based diagnostic questions than any other, because networking failures are notoriously hard to reason about from symptoms alone.

Interviewers in this domain love layered scenario questions ("it works from this VM but not that one — why?") because they reveal whether you actually understand the packet path or just memorized product names.

---

## 1. VPC Networking, Firewall Rules, Routing, Private Connectivity

### Q: "Explain GCP's VPC model — how is it different from AWS's, if you've worked with both?"
**Answer:** A GCP VPC is a **global resource**; subnets are **regional** (not zonal like AWS), and a single VPC can span multiple regions without peering between them. Firewall rules are also **global** (attached to the VPC, not the subnet), evaluated by priority, and apply based on **network tags or service accounts**, not subnet membership. This is a meaningfully different model from AWS's zonal-subnet, per-subnet-route-table approach — worth stating explicitly if the interviewer has AWS context, since it's a common point of confusion.

**Follow-up: "How does firewall rule evaluation work — priority, direction, and default behavior?"**
Rules have a **priority** (0–65535, lower = higher priority), a **direction** (ingress/egress), and either allow or deny. GCP's implied default: **all ingress is denied, all egress is allowed** unless rules say otherwise — the opposite of some other clouds' defaults, so always confirm this explicitly rather than assuming. Rules are evaluated in priority order per direction; the first match wins, so an explicit low-priority-number deny can override a broader high-priority-number allow.

**Follow-up: "What's the difference between targeting a firewall rule by network tag vs service account?"**
Tags are simpler but weaker — any principal with edit access to the VM can add/remove tags, potentially escalating their own firewall exposure. **Service-account-based targeting** is the more secure pattern for production, since changing which SA a VM runs as requires a separate, more controlled IAM action — tags are fine for quick dev/test segmentation, service accounts are the recommended pattern where firewall exposure has real security consequence.

### Q: "How does routing work in a GCP VPC, and when do you need custom routes?"
**Answer:** Every VPC gets **implicit default routes** (one per subnet for local traffic, one default route to the internet via the default gateway). You need **custom static routes** for: routing specific destination ranges through a specific next hop (e.g., an NVA/appliance, a VPN tunnel, or a Cloud NAT gateway for controlled egress), or when using **Shared VPC / VPC Peering** where routes need explicit export/import configuration to propagate across the boundary — peered VPCs don't automatically share custom routes unless explicitly exported.

**Follow-up: "What's the difference between VPC Peering and Shared VPC, and when do you choose each?"**
**Shared VPC** — one host project owns the network, service projects attach and provision resources into shared subnets; centralized network administration, single team controls firewall/routing for everyone. Best for an org that wants strict centralized network governance across many teams/projects.
**VPC Peering** — two independent VPCs connect directly, each keeps its own administration; better for connecting VPCs across different orgs/business units or when teams need networking autonomy. Key limitation to mention: peering is **non-transitive** — if A peers with B and B peers with C, A cannot reach C through B without a direct A–C peering.

### Q: "What's Private Google Access, and why would you need it?"
**Answer:** Lets VM instances **without external IPs** reach Google APIs/services (GCS, BigQuery, etc.) over Google's internal network instead of requiring a public IP or NAT gateway — critical for security-conscious workloads that shouldn't have any internet-facing surface but still need to call Google-managed services. Related but distinct: **Private Service Connect**, which extends this pattern to let you privately consume services published by other VPCs/orgs (or your own services published for consumption) without VPC peering, using internal IPs and DNS.

**Console steps (enabling Private Google Access on a subnet):**
1. VPC Network → VPC networks → select the subnet.
2. Edit → Private Google Access → On.
3. Save.

**Terraform:**
```hcl
resource "google_compute_subnetwork" "private" {
  name                     = "private-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
}
```

### Q: "How do you design firewall rules for a multi-tier application (web, app, DB tiers) following least-privilege network access?"
**Answer:** Tag or SA-scope each tier separately, and only open exactly the tier-to-tier traffic needed — web tier accepts ingress from the load balancer's IP ranges on the app port; app tier accepts ingress only from the web tier's tag/SA; DB tier accepts ingress only from the app tier's tag/SA, never directly from web or the internet.

**Terraform:**
```hcl
resource "google_compute_firewall" "allow_lb_to_web" {
  name    = "allow-lb-to-web"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # GCP LB health check/proxy ranges
  target_tags   = ["web-tier"]
}

resource "google_compute_firewall" "allow_web_to_app" {
  name    = "allow-web-to-app"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["web-tier"]
  target_tags = ["app-tier"]
}

resource "google_compute_firewall" "allow_app_to_db" {
  name    = "allow-app-to-db"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_tags = ["app-tier"]
  target_tags = ["db-tier"]
}

resource "google_compute_firewall" "deny_all_ingress" {
  name      = "deny-all-ingress"
  network   = google_compute_network.vpc.id
  priority  = 65534
  direction = "INGRESS"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}
```

---

## 2. Load Balancing (L4 and L7)

### Q: "Walk me through GCP's load balancer types and how you'd choose between them."
**Answer:** The main axis is **L4 vs L7**, then **global vs regional**, then **external vs internal**:
- **L4 (Network Load Balancer)** — TCP/UDP pass-through, preserves client IP, no content inspection; use when you need raw performance, non-HTTP protocols, or the backend needs to see the original client IP directly. Regional.
- **L7 (Application Load Balancer / HTTP(S) LB)** — inspects HTTP(S), supports URL-based routing, host-based routing, and integrates with Cloud CDN and Cloud Armor (WAF). Can be **global** (anycast IP, routes to nearest healthy backend region) — this is the standout GCP capability versus most clouds where a single LB is region-bound.
- **Internal LBs** (both L4 and L7 variants) — for service-to-service traffic within the VPC that should never be internet-facing.

**Follow-up: "Why would you choose a Network Load Balancer over an Application Load Balancer even though L7 seems more feature-rich?"**
When you need raw TCP/UDP pass-through for non-HTTP protocols (e.g., a game server, a custom TCP protocol, gRPC without HTTP semantics needed at the LB layer), when you need the backend to see the original client IP without relying on `X-Forwarded-For` header trust, or when L7's content-based routing features are unnecessary overhead for a single-purpose backend and you want the lowest possible latency.

**Follow-up: "What's the difference between a global external HTTP(S) LB and a regional one, and why does GCP support global at L7 but not really at L4?"**
Global HTTP(S) LB uses a single **anycast IP** and Google's global network (Premium Tier) to route each request to the closest healthy backend across regions — this works at L7 because the LB terminates the connection and can inspect/route per-request. Regional LBs (including most L4 options) bind to a specific region's backend set. The practical reason to choose regional over global even when available: cost (Premium Tier networking costs more) or a requirement to keep traffic within a specific region for compliance/data residency.

### Q: "How does health checking work, and what's a mistake teams make configuring it?"
**Answer:** Health checks probe backends on an interval/threshold and pull unhealthy instances out of rotation automatically. Common mistake: health check path/port doesn't match what the app actually serves readiness on (e.g., checking `/` when the app's real health endpoint is `/healthz` and `/` does expensive work or requires auth) — this either falsely marks healthy instances as down (adding auth accidentally) or falsely reports healthy when the app is actually degraded (checking a static path that doesn't exercise real dependencies). Health check endpoints should be **cheap, dependency-aware, and separate from business logic routes**.

### Q: "How would you design a load balancing setup for a service that needs to serve users globally with low latency and also protect against common web attacks?"
**Answer:** Global external HTTP(S) LB (anycast, routes to nearest region) + **Cloud CDN** enabled on the backend for cacheable content (reduces origin load and improves latency further) + **Cloud Armor** attached as a security policy for WAF rules (rate limiting, geo-blocking, OWASP rule sets) — all three compose on the same L7 LB resource rather than being separate infrastructure.

**Terraform (skeleton):**
```hcl
resource "google_compute_backend_service" "app_backend" {
  name                  = "app-backend"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.app_hc.id]
  enable_cdn            = true

  security_policy = google_compute_security_policy.waf_policy.id

  backend {
    group = google_compute_region_network_endpoint_group.app_neg.id
  }
}

resource "google_compute_security_policy" "waf_policy" {
  name = "app-waf-policy"

  rule {
    action   = "rate_based_ban"
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
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
  }

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
```

---

## 3. DNS & SSL/TLS Certificates

### Q: "How do you set up DNS for a new service on GCP, end to end?"
**Answer:**
1. **Cloud DNS managed zone** — public zone for internet-resolvable domains, private zone for internal-only VPC resolution.
2. **Record creation** — A/AAAA for direct IP, CNAME for aliasing, or for LB-fronted services, an A record pointing at the LB's static/anycast IP.
3. **Validation** — confirm propagation and correct resolution before cutover, and check TTL is appropriately low *before* a planned migration (so old records expire fast) and raised again after stabilization (to reduce query load/cost).

**Console steps:**
1. Network Services → Cloud DNS → Create Zone (choose Public or Private, specify DNS name).
2. Within the zone → Add Record Set → choose type (A/CNAME/etc.), set TTL, set data (IP or target).
3. If public: update the domain registrar's nameservers to the zone's assigned NS records (shown in the zone details) if this is the authoritative zone for the domain.

**Terraform:**
```hcl
resource "google_dns_managed_zone" "public" {
  name     = "example-com-zone"
  dns_name = "example.com."
}

resource "google_dns_record_set" "app_a_record" {
  name         = "app.example.com."
  managed_zone = google_dns_managed_zone.public.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.lb_ip.address]
}
```

**Follow-up: "What's the difference between a public and private Cloud DNS zone, and how do you handle split-horizon DNS (same domain resolving differently internally vs externally)?"**
Public zones are internet-authoritative; private zones are only resolvable from VPCs you explicitly attach them to. Split-horizon: create both a public zone and a private zone for the **same domain name**, with different records in each — internal VPC clients resolve via the private zone (e.g., pointing to an internal LB), external clients resolve via the public zone (pointing to the external LB) — GCP handles the precedence automatically for resources inside the attached VPC.

### Q: "How do you request and configure an SSL/TLS certificate on GCP, and what's the tradeoff between Google-managed and self-managed certs?"
**Answer:**
- **Google-managed certificates** — attached to an HTTPS LB target proxy, auto-provisioned and **auto-renewed** via domain validation (DNS or HTTP-01 style validation against the domain pointed at the LB) — the default recommendation, since it removes manual renewal risk (expired certs are a classic self-inflicted outage).
- **Self-managed certificates** — needed when you require a specific CA (e.g., an internal enterprise CA for compliance), wildcard certs with custom issuance policies, or certs that need to be used outside GCP's LB context.

**Follow-up: "Walk me through validating that a Google-managed cert actually provisioned correctly, and troubleshooting if it's stuck in PROVISIONING."**
Check status via `gcloud compute ssl-certificates describe` or Console → Network Services → Load balancing → Certificates. If stuck in `PROVISIONING`, the near-universal cause is the **DNS record isn't yet pointing at the LB's IP**, or hasn't propagated — Google-managed cert issuance requires the domain to actually resolve to the LB before it can complete domain validation. Also check the LB's forwarding rule/target proxy is actually referencing the certificate resource, and that port 443 is reachable (not blocked by a firewall rule), since some validation paths depend on reachability.

**Terraform:**
```hcl
resource "google_compute_managed_ssl_certificate" "app_cert" {
  name = "app-ssl-cert"
  managed {
    domains = ["app.example.com"]
  }
}

resource "google_compute_target_https_proxy" "app_https_proxy" {
  name             = "app-https-proxy"
  url_map          = google_compute_url_map.app_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.app_cert.id]
}
```

### Q: "A certificate renewed but clients are still getting cert errors / an old cert. What's going on?"
**Answer:** Almost always one of: **client-side caching/pinning** (browser or CDN edge cache not yet refreshed), the **target proxy still references the old certificate resource** (Google-managed cert renewal creates continuity, but a *manually replaced* self-managed cert requires updating the target proxy's reference explicitly, it doesn't auto-swap), or a **CDN/downstream proxy in front of the LB** serving a cached response/handshake. Isolate by testing directly against the LB IP with a fresh client (e.g., `curl -v --resolve`) bypassing any intermediate cache.

---

## 4. Hybrid / On-Prem & External Connectivity

### Q: "What are GCP's options for connecting to on-premises infrastructure, and how do you choose?"
**Answer:**
- **Cloud VPN** (HA VPN) — IPsec tunnels over the internet; fastest to set up, lowest cost, but subject to internet variability — fine for moderate throughput, non-latency-critical, or as a backup path.
- **Dedicated Interconnect** — direct physical connection into Google's network at a colocation facility; highest throughput (10/100 Gbps circuits), lowest latency, but requires physical presence at a supported colo and longer lead time to provision.
- **Partner Interconnect** — same idea as Dedicated, but through a supported service provider when you're not physically colocated with Google — lower throughput tiers available (sub-10Gbps), faster to provision than Dedicated.
- **Cross-Cloud Interconnect** — dedicated connectivity specifically to another cloud provider (AWS/Azure), for multi-cloud architectures needing consistent high-throughput low-latency links.

Choice comes down to: **required throughput/latency**, **budget**, **provisioning timeline**, and whether you have physical colo presence.

**Follow-up: "How do you design for redundancy in hybrid connectivity so a single link failure doesn't cause an outage?"**
Two Interconnect (or VPN) connections in **different metro/edge availability domains**, combined with **Cloud Router** running BGP so routes fail over automatically when one path drops — never rely on a single physical circuit for production hybrid connectivity. For a cost-conscious middle ground, pair a Dedicated/Partner Interconnect as primary with an HA VPN as an automatic failback path.

### Q: "What's Cloud Router, and why is it needed alongside VPN/Interconnect rather than just static routes?"
**Answer:** Cloud Router runs **BGP** to dynamically exchange routes between your GCP VPC and the on-prem/peer network — this means route changes on either side propagate automatically without manual route table updates, and it enables automatic failover between redundant paths (if a BGP session drops, routes through that path withdraw automatically). Static routes work for simple, unchanging topologies but don't scale to multi-path redundancy or environments where the on-prem network topology changes over time.

### Q: "How would you securely expose an internal GCP service to a specific external partner without exposing it to the whole internet?"
**Answer:** **Private Service Connect** (publish the service as a PSC endpoint the partner consumes privately if they're also on GCP), or if the partner is external/non-GCP, a combination of an **internal LB** plus a tightly scoped **VPN tunnel or Interconnect** to their specific network, with firewall rules restricting to their exact source ranges — never a public IP with an IP allowlist alone, since that still exposes the surface to internet-based scanning/attack even if traffic is nominally blocked at the firewall.

---

## 5. Troubleshooting Network, DNS, Certificate, Routing & Connectivity Issues

### Q: "A VM can't reach the internet — walk through your troubleshooting steps."
**Answer — funnel from most to least likely:**
1. **Does the VM have an external IP, or is it meant to go through Cloud NAT?** — check both; a common mistake is assuming Cloud NAT is configured when it isn't, for a VM with no external IP.
2. **Firewall egress rules** — remember GCP's default is allow-all-egress, so a deny rule was likely added explicitly; check for an overly broad deny rule.
3. **Routes** — is there a default route to the internet gateway (`0.0.0.0/0` next-hop-gateway)? Someone may have deleted or overridden it with a custom route.
4. **Cloud NAT config** (if no external IP) — confirm the NAT gateway covers this subnet/VM's IP range, and check for **NAT port exhaustion** if many VMs share one NAT gateway under high connection volume.
5. Use **VPC Connectivity Tests** to simulate the path and get GCP's own diagnosis of exactly which hop is blocking, rather than manually re-deriving it.

### Q: "Two VMs in the same VPC, different subnets, can't communicate. What do you check?"
**Answer:**
1. Firewall rules — even same-VPC traffic requires an explicit allow (there's no automatic "same VPC = allowed" beyond the implied rules, which only cover intra-subnet by default depending on setup) — check ingress rules on the target scoped correctly by tag/SA/source range.
2. Subnet routes — confirm both subnets exist in the same VPC's routing scope (not accidentally split across peered-but-not-fully-routed VPCs).
3. If subnets are in **different regions**, confirm this isn't accidentally going through a path with a regional firewall/policy difference or a Shared VPC boundary with incomplete route export.
4. OS-level firewall (iptables/firewalld) on the VM itself — GCP firewall isn't the only layer; the guest OS can independently block traffic that GCP allows.

### Q: "DNS resolution works from your laptop but not from a GCP VM (or vice versa) for the same private zone. Why?"
**Answer:** Private Cloud DNS zones only resolve for **VPCs explicitly attached** to that zone — if the VM's VPC isn't attached, it falls through to public DNS resolution (or fails, if the name isn't public) even though the zone exists in the project. Confirm the zone's attached-networks list includes the VM's VPC, and if using Shared VPC, confirm the private zone is attached at the right project level (host vs service project DNS attachment has its own nuance).

### Q: "How do you troubleshoot intermittent latency between two services that are usually fine but occasionally spike?"
**Answer:** Rule out in order: (1) **application-level** — GC pauses, connection pool exhaustion, thread contention — check app metrics/traces first since this is statistically the most common cause; (2) **autoscaling churn** — new instances warming up (cold start, JIT warmup, cache miss) coinciding with scale-out events; (3) **network path** — cross-region calls occasionally hitting a congested path, checked via Network Intelligence Center's performance dashboards; (4) **NAT port exhaustion or connection reuse issues** under bursty load; (5) **DNS resolution latency** if the client isn't caching/reusing resolved connections and re-resolves per request. Correlate spike timestamps against deploy/autoscale event logs before assuming it's "the network's fault," since app and infra events are the more common root cause even when the symptom looks network-shaped.

---

## Quick-reference cheat sheet

| Need | GCP mechanism |
|---|---|
| Multi-region single network | VPC (global resource) |
| Centralized network governance | Shared VPC |
| Cross-org/autonomous network links | VPC Peering (non-transitive) |
| No-external-IP access to Google APIs | Private Google Access |
| Private cross-VPC service consumption | Private Service Connect |
| Raw TCP/UDP, preserve client IP | Network Load Balancer (L4) |
| HTTP routing, global anycast, CDN/WAF | Application Load Balancer (L7) |
| Caching at the edge | Cloud CDN |
| WAF / rate limiting | Cloud Armor |
| DNS hosting | Cloud DNS (public/private zones) |
| Auto-renewing TLS cert | Google-managed SSL certificate |
| Dynamic route exchange | Cloud Router (BGP) |
| Internet-based hybrid link | Cloud VPN (HA VPN) |
| Dedicated physical hybrid link | Dedicated / Partner Interconnect |
| Multi-cloud dedicated link | Cross-Cloud Interconnect |
| Path/connectivity diagnosis | VPC Network Connectivity Tests |
| Network performance visibility | Network Intelligence Center |
