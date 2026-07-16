# Google Cloud Platform (GCP) Networking - Complete Guide

**Table of Contents:**
1. Virtual Private Cloud (VPC)
2. Subnets
3. Firewall Rules
4. Routes
5. Load Balancing
6. Cloud Router
7. Hybrid Connectivity
8. DNS Services
9. Network Security
10. Cloud NAT (Additional Topic)
11. Cloud VPN
12. Service Endpoints
13. Private Service Connection
14. VPC Flow Logs (Additional Topic)
15. VPC Peering & Service Networking
16. Interview Q&A with Real-Time Examples

---

## 1. Virtual Private Cloud (VPC)

### Overview
A Virtual Private Cloud (VPC) is a global virtual network on Google Cloud that provides complete isolation of your infrastructure from other customers. It spans all regions and serves as the foundation for all GCP networking.

### Key Characteristics
- **Global scope**: Spans all regions and zones
- **Automatic routing**: Traffic between subnets in different regions is automatically routed
- **No CIDR block requirement**: VPC doesn't require a single CIDR block
- **Flexible subnet design**: Each region can have multiple subnets with different IP ranges

### VPC Modes

#### 1. Auto Mode (Recommended for getting started)
- Automatically creates a subnet in each region
- Each subnet has a `/20` network (4,096 IP addresses)
- Starting range: `10.128.0.0/9`
- Easy to manage but less flexible

#### 2. Custom Mode (Recommended for production)
- You create subnets manually
- Full control over IP addressing
- Each subnet can have a different CIDR block
- Best practice for production environments

### Console Steps - Create a VPC

**Step 1: Navigate to VPC Networks**
```
1. Open Google Cloud Console
2. Navigate to "VPC Network" → "VPCs"
3. Click "Create VPC"
```

**Step 2: Configure VPC Settings**
```
1. Name: my-vpc
2. Description: Production VPC
3. Select "Custom" mode
4. Click "Create"
```

**Step 3: Verify Creation**
```
1. Go to "VPC Network" → "VPCs"
2. Your VPC should appear in the list
3. Click on it to view details
```

### gcloud Commands - VPC

```bash
# Create a custom VPC
gcloud compute networks create my-vpc \
  --subnet-mode=custom \
  --description="Production VPC"

# List all VPCs
gcloud compute networks list

# Describe a specific VPC
gcloud compute networks describe my-vpc

# Delete a VPC
gcloud compute networks delete my-vpc

# Create an auto-mode VPC
gcloud compute networks create auto-mode-vpc \
  --subnet-mode=auto

# Update VPC routing configuration
gcloud compute networks update my-vpc \
  --routing-mode=REGIONAL
```

### Terraform - VPC

```hcl
# Main VPC Configuration
resource "google_compute_network" "my_vpc" {
  name                    = "my-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Production VPC"
}

# Alternative: Auto-mode VPC
resource "google_compute_network" "auto_vpc" {
  name                    = "auto-mode-vpc"
  auto_create_subnetworks = true
  routing_mode            = "GLOBAL"
}

# Output VPC ID
output "vpc_id" {
  value       = google_compute_network.my_vpc.id
  description = "VPC Network ID"
}

output "vpc_self_link" {
  value       = google_compute_network.my_vpc.self_link
  description = "VPC Self Link"
}
```

### Best Practices
- Use custom mode for production deployments
- Plan your IP addressing scheme in advance
- Use REGIONAL routing mode for better control
- Document your CIDR blocks and allocations
- Use separate VPCs for different environments (dev, staging, prod)

---

I go to VPC Network → VPC Networks → Create VPC Network, provide a meaningful name, choose Custom subnet mode for better IP management, select Global dynamic routing for multi-region connectivity, keep the default MTU of 1460, avoid enabling broad default firewall rules, and create the VPC. I then create regional subnets, firewall rules, Cloud NAT, and other networking components as needed


## 2. Subnets

### Overview
Subnets are regional resources within a VPC that define a contiguous range of IP addresses. Traffic between subnets is automatically routed even across regions.

### Key Characteristics
- **Regional scope**: Each subnet belongs to a single region
- **IP ranges**: Define the IP address space for the subnet
- **Private/Secondary ranges**: Support multiple IP ranges (IP aliasing)
- **Auto-expansion**: Can enable automatic IP range expansion

### Subnet Types

#### 1. Primary IP Range
The main IP address range for the subnet. Required for every subnet.

#### 2. Secondary IP Ranges
Additional IP ranges within the same subnet. Useful for:
- Kubernetes pods and services
- Multi-tier application architectures
- Future expansion without recreation

### Console Steps - Create a Subnet

**Step 1: Navigate to Subnets**
```
1. VPC Network → VPCs
2. Click on your VPC name
3. Click "Subnets" tab
4. Click "Create Subnet"
```

**Step 2: Configure Subnet**
```
1. Name: subnet-us-central1
2. Region: us-central1
3. IPv4 range: 10.0.0.0/24
4. Optional - Enable Private Google Access
5. Optional - Enable Flow Logs
6. Click "Create"
```

**Step 3: Add Secondary IP Range**
```
1. Click on the subnet name
2. Go to "Secondary IP ranges"
3. Click "Add Secondary IP Range"
4. Name: secondary-range-1
5. IP range: 10.0.100.0/24
6. Click "Add"
```

### gcloud Commands - Subnets

```bash
# Create a basic subnet
gcloud compute networks subnets create subnet-us-central1 \
  --network=my-vpc \
  --region=us-central1 \
  --range=10.0.0.0/24

# Create subnet with secondary IP ranges
gcloud compute networks subnets create subnet-us-east1 \
  --network=my-vpc \
  --region=us-east1 \
  --range=10.1.0.0/24 \
  --secondary-range pods=10.4.0.0/14,services=10.0.0.0/20

# Enable Private Google Access
gcloud compute networks subnets update subnet-us-central1 \
  --region=us-central1 \
  --enable-private-ip-google-access

# List all subnets
gcloud compute networks subnets list

# Describe a specific subnet
gcloud compute networks subnets describe subnet-us-central1 \
  --region=us-central1

# Delete a subnet
gcloud compute networks subnets delete subnet-us-central1 \
  --region=us-central1

# Enable VPC Flow Logs on a subnet
gcloud compute networks subnets update subnet-us-central1 \
  --region=us-central1 \
  --enable-flow-logs \
  --logging-aggregation-interval=interval-5-sec \
  --logging-flow-sampling=0.5
```

### Terraform - Subnets

```hcl
# Create primary subnet
resource "google_compute_subnetwork" "subnet_us_central1" {
  name                     = "subnet-us-central1"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.my_vpc.id
  private_ip_google_access = true

  # Enable VPC Flow Logs
  enable_flow_logs = true
  
  log_config {
    aggregation_interval = "interval_5_sec"
    flow_sampling        = 0.5
    metadata             = "include_all_metadata"
  }

  # Secondary IP ranges
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.0.0.0/20"
  }
}

# Create subnet in different region
resource "google_compute_subnetwork" "subnet_us_east1" {
  name                     = "subnet-us-east1"
  ip_cidr_range            = "10.1.0.0/24"
  region                   = "us-east1"
  network                  = google_compute_network.my_vpc.id
  private_ip_google_access = true
}

# Output subnet information
output "subnet_self_link" {
  value = google_compute_subnetwork.subnet_us_central1.self_link
}

output "subnet_gateway" {
  value = google_compute_subnetwork.subnet_us_central1.gateway_address
}
```

### Best Practices
- Plan subnets for scalability and future growth
- Use secondary IP ranges for Kubernetes deployments
- Always enable Private Google Access for private instances
- Enable Flow Logs for security monitoring
- Use descriptive naming conventions
- Document IP ranges and their purposes
- Reserve some address space for future expansion

---

## 3. Firewall Rules

### Overview
Firewall rules control inbound (ingress) and outbound (egress) traffic at the VPC level. They are stateful and evaluated by priority.

### Key Characteristics
- **Stateful**: Response traffic is automatically allowed
- **VPC-level**: Apply to all instances in the VPC
- **Priority-based**: Lower number = higher priority (0-65534)
- **Tag-based**: Can target instances by network tags or service accounts
- **Direction**: Ingress (incoming) or Egress (outgoing)

### Rule Components
1. **Direction**: INGRESS or EGRESS
2. **Priority**: 0-65534 (lower = higher priority)
3. **Action**: ALLOW or DENY
4. **Protocol**: tcp, udp, icmp, esp, ah, or all
5. **Source/Destination**: IP ranges, service accounts, or network tags
6. **Ports**: Specific ports or ranges

### Console Steps - Create Firewall Rules

**Step 1: Navigate to Firewall**
```
1. VPC Network → Firewall Rules
2. Click "Create Firewall Rule"
```

**Step 2: Configure Rule**
```
1. Name: allow-http-https
2. VPC Network: my-vpc
3. Direction: Ingress
4. Action: Allow
5. Priority: 1000
6. Source filter: IPv4 ranges
7. Source IPv4 ranges: 0.0.0.0/0
8. Protocols and ports:
   - TCP: 80, 443
9. Click "Create"
```

**Step 3: Create Tag-based Rule**
```
1. Click "Create Firewall Rule"
2. Name: allow-internal-ssh
3. Direction: Ingress
4. Action: Allow
5. Target tags: ssh-server
6. Source filter: IPv4 ranges
7. Source IPv4 ranges: 10.0.0.0/8
8. Protocol: TCP
9. Port: 22
10. Click "Create"
```

### gcloud Commands - Firewall Rules

```bash
# Create a basic allow rule for HTTP/HTTPS
gcloud compute firewall-rules create allow-http-https \
  --network=my-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --priority=1000

# Create rule with network tags
gcloud compute firewall-rules create allow-ssh-tag \
  --network=my-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=10.0.0.0/8 \
  --target-tags=ssh-server \
  --priority=1000

# Create rule with service account
gcloud compute firewall-rules create allow-internal-traffic \
  --network=my-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:3306 \
  --source-service-accounts=app-server@PROJECT_ID.iam.gserviceaccount.com \
  --target-service-accounts=database@PROJECT_ID.iam.gserviceaccount.com

# List firewall rules
gcloud compute firewall-rules list --filter="network:my-vpc"

# Describe a specific rule
gcloud compute firewall-rules describe allow-http-https

# Update a firewall rule
gcloud compute firewall-rules update allow-http-https \
  --rules=tcp:80,tcp:443,tcp:8080

# Delete a firewall rule
gcloud compute firewall-rules delete allow-http-https

# Create a deny rule (DDoS protection example)
gcloud compute firewall-rules create deny-malicious-ip \
  --network=my-vpc \
  --direction=INGRESS \
  --action=DENY \
  --rules=tcp,udp \
  --source-ranges=203.0.113.0/24 \
  --priority=100
```

### Terraform - Firewall Rules

```hcl
# Allow HTTP/HTTPS from anywhere
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.my_vpc.name

  direction = "INGRESS"
  action    = "ALLOW"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

# Allow SSH from specific network with tags
resource "google_compute_firewall" "allow_ssh_internal" {
  name    = "allow-ssh-internal"
  network = google_compute_network.my_vpc.name

  direction = "INGRESS"
  action    = "ALLOW"
  priority  = 1001

  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["ssh-server"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Allow traffic between service accounts
resource "google_compute_firewall" "allow_service_accounts" {
  name    = "allow-between-services"
  network = google_compute_network.my_vpc.name

  direction = "INGRESS"
  action    = "ALLOW"
  priority  = 1002

  source_service_accounts      = [google_service_account.app.email]
  target_service_accounts      = [google_service_account.database.email]
  enable_logging               = true

  allow {
    protocol = "tcp"
    ports    = ["3306", "5432"]
  }
}

# Deny specific traffic (DDoS protection)
resource "google_compute_firewall" "deny_malicious" {
  name    = "deny-malicious-ips"
  network = google_compute_network.my_vpc.name

  direction = "INGRESS"
  action    = "DENY"
  priority  = 100

  source_ranges = ["203.0.113.0/24"]

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }
}

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-all"
  network = google_compute_network.my_vpc.name

  direction = "INGRESS"
  action    = "ALLOW"
  priority  = 2000

  source_ranges = ["10.0.0.0/8"]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}
```

### Best Practices
- Follow principle of least privilege
- Use lower priority numbers for deny rules
- Use network tags for better organization
- Enable logging for security monitoring
- Document the purpose of each rule
- Regularly review and audit firewall rules
- Use service accounts for better control
- Test firewall rules before deployment

---

## 4. Routes

### Overview
Routes determine how traffic moves within and outside the VPC. They define paths for packets based on destination IP ranges.

### Route Types

#### 1. System Routes
Automatically created by Google Cloud:
- Each VPC has a default route (0.0.0.0/0 → default internet gateway)
- Routes for each subnet
- Routes to Google Cloud's metadata server (169.254.169.254/32)

#### 2. Custom Static Routes
Manually created routes that can direct traffic to:
- VPC instances (as next hop)
- Cloud VPN gateways
- Cloud Interconnect connections
- Cloud NAT (implicit)

#### 3. Dynamic Routes
Created automatically when using Cloud Router with BGP:
- Updates based on network changes
- Used with Cloud VPN and Interconnect

### Console Steps - Create Routes

**Step 1: Navigate to Routes**
```
1. VPC Network → Routes
2. Click "Create Route"
```

**Step 2: Configure Route**
```
1. Name: route-to-internal-network
2. Network: my-vpc
3. Destination IP range: 192.168.0.0/16
4. Next hop type: VPN gateway
5. Next hop: Select your VPN gateway
6. Priority: 1000
7. Click "Create"
```

### gcloud Commands - Routes

```bash
# List all routes in a VPC
gcloud compute routes list --filter="network:my-vpc"

# Create a route to an instance
gcloud compute routes create route-to-instance \
  --network=my-vpc \
  --destination-range=192.168.0.0/16 \
  --next-hop-instance=my-instance \
  --next-hop-instance-zone=us-central1-a \
  --priority=1000

# Create a route via VPN gateway
gcloud compute routes create route-via-vpn \
  --network=my-vpc \
  --destination-range=192.168.0.0/16 \
  --next-hop-vpn-gateway=my-vpn-gateway \
  --priority=1000

# Create a route via Cloud Router (dynamic)
# This is typically created automatically with BGP

# Describe a route
gcloud compute routes describe route-to-instance

# Delete a route
gcloud compute routes delete route-to-instance
```

### Terraform - Routes

```hcl
# Basic instance-based route
resource "google_compute_route" "route_to_instance" {
  name             = "route-to-instance"
  dest_range       = "192.168.0.0/16"
  network          = google_compute_network.my_vpc.name
  next_hop_instance = "my-instance"
  next_hop_instance_zone = "us-central1-a"
  priority         = 1000
}

# Route with tags
resource "google_compute_route" "route_internal" {
  name             = "route-internal"
  dest_range       = "10.0.0.0/8"
  network          = google_compute_network.my_vpc.name
  next_hop_instance = google_compute_instance.router_instance.self_link
  tags             = ["internal-routing"]
  priority         = 1000
}

# Route to internet gateway
resource "google_compute_route" "route_internet" {
  name        = "route-internet"
  dest_range  = "0.0.0.0/0"
  network     = google_compute_network.my_vpc.name
  next_hop_gateway = "default-internet-gateway"
  priority    = 1000
}

# Route via VPN gateway
resource "google_compute_route" "route_via_vpn" {
  name                    = "route-via-vpn"
  dest_range              = "192.168.0.0/16"
  network                 = google_compute_network.my_vpc.name
  next_hop_vpn_gateway    = google_compute_vpn_gateway.vpn.self_link
  next_hop_vpn_gateway_region = "us-central1"
  priority                = 1000
}
```

### Best Practices
- Avoid overlapping destination ranges
- Use priority to control route preference
- Document all custom routes
- Monitor route changes and updates
- Use Cloud Router for dynamic routing
- Test routes before deploying to production

---

## 5. Load Balancing

### Overview
Google Cloud Load Balancing distributes traffic across multiple instances, ensuring high availability and scalability.

### Load Balancer Types

#### 1. HTTP(S) Load Balancer (Layer 7)
- **Use case**: Web applications, APIs, content delivery
- **Capabilities**: URL routing, SSL/TLS termination, session affinity
- **Global**: Distributes traffic globally by default
- **Traffic routing**: Based on URL path, hostname, HTTP method

#### 2. TCP/SSL Proxy Load Balancer
- **Use case**: Non-HTTP protocols (gaming, IoT)
- **Capabilities**: SSL/TLS termination, IP protocol routing
- **Global**: Distributes across regions
- **Protocols**: TCP, UDP (via Network LB)

#### 3. Network Load Balancer (Layer 4)
- **Use case**: Extreme performance, millions of requests/sec
- **Capabilities**: Very low latency, high throughput
- **Regional/Global**: Can be either
- **Protocols**: TCP, UDP

#### 4. Internal Load Balancer
- **Use case**: Private traffic within VPC
- **Capabilities**: Private IP address, regional
- **Traffic**: Only accessible from within the VPC or connected networks

### Console Steps - Create HTTP(S) Load Balancer

**Step 1: Create Backend Service**
```
1. Navigation → "Load balancing"
2. Click "Create Load Balancer"
3. Choose "HTTP(S) Load Balancer"
4. Click "Start Configuration"
```

**Step 2: Configure Backend Service**
```
1. Backend Configuration:
   - Create or select backend service
   - Name: backend-service-web
   - Protocol: HTTP
   - Named port: http
2. Instance group:
   - Add your instance groups
   - Set health check or create new
3. Session affinity: NONE (or CLIENT_IP if needed)
```

**Step 3: Configure Frontend**
```
1. Frontend Configuration:
   - Protocol: HTTPS (recommended)
   - IP address: Create new or use existing
   - Port: 443 (and 80 for redirect)
   - Certificate: Create or select SSL certificate
```

**Step 4: Routing Rules**
```
1. Host and path rules:
   - Hosts: example.com
   - Paths: /* (or specific paths)
   - Backend service: backend-service-web
```

### gcloud Commands - Load Balancing

```bash
# Create instance group
gcloud compute instance-groups managed create web-ig \
  --base-instance-name=web \
  --template=web-instance-template \
  --size=3 \
  --zone=us-central1-a

# Create health check
gcloud compute health-checks create http web-health-check \
  --port=80 \
  --request-path=/health

# Create backend service
gcloud compute backend-services create backend-service-web \
  --global \
  --protocol=HTTP \
  --health-checks=web-health-check \
  --load-balancing-scheme=EXTERNAL

# Add instance group to backend service
gcloud compute backend-services add-backend backend-service-web \
  --instance-group=web-ig \
  --instance-group-zone=us-central1-a \
  --global

# Create URL map
gcloud compute url-maps create web-url-map \
  --default-service=backend-service-web

# Create SSL certificate
gcloud compute ssl-certificates create web-cert \
  --certificate=PATH_TO_CERT \
  --private-key=PATH_TO_KEY

# Create HTTPS proxy
gcloud compute target-https-proxies create web-https-proxy \
  --url-map=web-url-map \
  --ssl-certificates=web-cert

# Create forwarding rule
gcloud compute forwarding-rules create web-forwarding-rule \
  --global \
  --target-https-proxy=web-https-proxy \
  --address=web-lb-ip \
  --ports=443

# List load balancers
gcloud compute forwarding-rules list --global

# Describe load balancer
gcloud compute forwarding-rules describe web-forwarding-rule --global
```

### Terraform - Load Balancing

```hcl
# HTTP Health Check
resource "google_compute_health_check" "web_health" {
  name = "web-health-check"

  http_health_check {
    port         = 80
    request_path = "/health"
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# Backend Service
resource "google_compute_backend_service" "web_backend" {
  name            = "web-backend-service"
  protocol        = "HTTP"
  port_name       = "http"
  health_checks   = [google_compute_health_check.web_health.id]
  session_affinity = "NONE"

  backend {
    group           = google_compute_instance_group_manager.web_ig.instance_group
    balancing_mode  = "RATE"
    max_rate_per_instance = 100
  }

  enable_cdn = true

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    default_ttl       = 3600
    max_ttl           = 86400
    negative_caching  = true
  }
}

# URL Map
resource "google_compute_url_map" "web_url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.web_backend.id

  host_rule {
    hosts        = ["example.com"]
    path_matcher = "web-paths"
  }

  path_matcher {
    name            = "web-paths"
    default_service = google_compute_backend_service.web_backend.id

    path_rule {
      paths           = ["/api/*"]
      service         = google_compute_backend_service.api_backend.id
    }
  }
}

# SSL Certificate
resource "google_compute_ssl_certificate" "web_cert" {
  name            = "web-cert"
  certificate     = file("${path.module}/cert.pem")
  private_key     = file("${path.module}/key.pem")
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "web_proxy" {
  name             = "web-https-proxy"
  url_map          = google_compute_url_map.web_url_map.id
  ssl_certificates = [google_compute_ssl_certificate.web_cert.id]
}

# Forwarding Rule
resource "google_compute_global_forwarding_rule" "web_rule" {
  name       = "web-forwarding-rule"
  ip_version = "IPV4"
  
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.web_proxy.id
  ip_address            = google_compute_address.web_lb_ip.id
}

# Reserve static IP
resource "google_compute_address" "web_lb_ip" {
  name        = "web-lb-ip"
  address_type = "EXTERNAL"
  address_family = "IPV4"
}

# Output
output "load_balancer_ip" {
  value = google_compute_address.web_lb_ip.address
}
```

### Best Practices
- Always use HTTPS for public-facing applications
- Configure proper health checks
- Use CDN for static content
- Implement session affinity when needed
- Monitor backend health continuously
- Use multiple backend instances for redundancy
- Configure auto-scaling with instance groups
- Use Cloud Armor for DDoS protection

---

## 6. Cloud Router

### Overview
Cloud Router enables dynamic routing using BGP (Border Gateway Protocol). It allows GCP to exchange routes with on-premises networks.

### Key Features
- **BGP support**: Dynamic routing protocol
- **Automatic failover**: Routes update automatically
- **Integration**: Works with VPN and Dedicated Interconnect
- **Multiple ASNs**: Support for different Autonomous System Numbers

### Console Steps - Create Cloud Router

**Step 1: Create Router**
```
1. VPC Network → Cloud Routers
2. Click "Create Router"
3. Name: my-router
4. Network: my-vpc
5. Region: us-central1
6. Google ASN: 64514 (default)
7. Click "Create"
```

**Step 2: Configure BGP Session**
```
1. Click on router name
2. Go to "BGP Peers"
3. Click "Add BGP Peer"
4. Peer name: on-premises-router
5. Peer ASN: 65000
6. Peer IP address: 169.254.34.1
7. Click "Create"
```

### gcloud Commands - Cloud Router

```bash
# Create Cloud Router
gcloud compute routers create my-router \
  --network=my-vpc \
  --region=us-central1 \
  --asn=64514

# List routers
gcloud compute routers list --filter="network:my-vpc"

# Describe router
gcloud compute routers describe my-router --region=us-central1

# Add BGP peer
gcloud compute routers add-bgp-peer my-router \
  --peer-name=on-premises \
  --peer-asn=65000 \
  --interface=if-0 \
  --ip-address=169.254.34.1 \
  --region=us-central1

# List BGP peers
gcloud compute routers get-status my-router --region=us-central1

# Update router
gcloud compute routers update my-router \
  --asn=64515 \
  --region=us-central1

# Delete router
gcloud compute routers delete my-router --region=us-central1
```

### Terraform - Cloud Router

```hcl
# Cloud Router
resource "google_compute_router" "my_router" {
  name    = "my-router"
  region  = "us-central1"
  network = google_compute_network.my_vpc.id
  asn     = 64514

  bgp {
    asn = 64514
  }
}

# BGP Peer
resource "google_compute_router_peer" "on_prem_peer" {
  name            = "on-prem-peer"
  router          = google_compute_router.my_router.name
  region          = google_compute_router.my_router.region
  peer_asn        = 65000
  peer_ip_address = "169.254.34.1"

  advertised_route_priority = 100

  advertised_groups {
    group = "ALL_SUBNETS"
  }

  depends_on = [google_compute_router_interface.on_prem_int]
}

# Router Interface (for VPN connection)
resource "google_compute_router_interface" "on_prem_int" {
  name                = "on-prem-interface"
  router              = google_compute_router.my_router.name
  region              = google_compute_router.my_router.region
  ip_range            = "169.254.34.2/30"
  interconnect_attachment = google_compute_interconnect_attachment.on_prem.self_link
}

# Output router ASN
output "router_asn" {
  value = google_compute_router.my_router.asn
}
```

### Best Practices
- Plan ASN assignments carefully
- Document all BGP peers
- Monitor BGP session health
- Use route filters for security
- Implement redundancy with multiple routers
- Test failover scenarios

---

## 7. Hybrid Connectivity

### Overview
Connect your on-premises infrastructure to Google Cloud using various connectivity options.

### Connectivity Options

#### 1. Cloud VPN
- **Speed**: Encrypted connection over internet (up to 3 Gbps)
- **Setup**: Quick and cost-effective
- **Use case**: Temporary connections, backup links
- **Latency**: Higher due to internet routing

#### 2. Dedicated Interconnect
- **Speed**: 10 Gbps or 100 Gbps private connection
- **Setup**: Physical cross-connection with Google's facilities
- **Use case**: Production workloads, consistent bandwidth
- **SLA**: 99.99% uptime

#### 3. Partner Interconnect
- **Speed**: 50 Mbps to 10 Gbps
- **Setup**: Through Google Cloud partners
- **Use case**: Organizations without direct access to Google data centers
- **Cost**: Lower than Dedicated Interconnect

### Console Steps - Create Cloud VPN

**Step 1: Create VPN Gateway**
```
1. VPC Network → VPN Connections → VPN Gateways
2. Click "Create VPN Gateway"
3. Name: cloud-vpn-gateway
4. Network: my-vpc
5. Region: us-central1
6. Click "Create"
```

**Step 2: Create Firewall Rules**
```
1. VPC Network → Firewall Rules
2. Allow ESP (IP 50): gcloud compute firewall-rules create allow-esp
3. Allow UDP 500: gcloud compute firewall-rules create allow-udp-500
4. Allow UDP 4500: gcloud compute firewall-rules create allow-udp-4500
```

**Step 3: Create VPN Tunnel**
```
1. Click on VPN gateway
2. Click "Create VPN Tunnel"
3. Name: on-prem-tunnel
4. Remote peer IP: On-premises VPN gateway IP
5. IKE version: IKEv2
6. Shared secret: Generate or provide
7. Click "Create"
```

### gcloud Commands - Hybrid Connectivity

```bash
# Create VPN Gateway
gcloud compute vpn-gateways create cloud-vpn-gateway \
  --network=my-vpc \
  --region=us-central1

# Create VPN tunnel
gcloud compute vpn-tunnels create on-prem-tunnel \
  --vpn-gateway=cloud-vpn-gateway \
  --vpn-gateway-region=us-central1 \
  --remote-peer-ip=203.0.113.12 \
  --shared-secret=mysecret \
  --ike-version=2

# Create VPN tunnel with custom IKE policy
gcloud compute vpn-tunnels create on-prem-tunnel \
  --vpn-gateway=cloud-vpn-gateway \
  --vpn-gateway-region=us-central1 \
  --remote-peer-ip=203.0.113.12 \
  --shared-secret=mysecret \
  --ike-version=2 \
  --ike-sa-lifetime=28800 \
  --ipsec-sa-lifetime=3600

# Create firewall rules for VPN
gcloud compute firewall-rules create allow-esp \
  --network=my-vpc \
  --allow=esp \
  --source-ranges=203.0.113.0/24

gcloud compute firewall-rules create allow-udp-vpn \
  --network=my-vpc \
  --allow=udp:500,udp:4500 \
  --source-ranges=203.0.113.0/24

# List VPN gateways
gcloud compute vpn-gateways list

# List VPN tunnels
gcloud compute vpn-tunnels list

# Describe VPN tunnel
gcloud compute vpn-tunnels describe on-prem-tunnel \
  --region=us-central1

# Check tunnel status
gcloud compute vpn-tunnels describe on-prem-tunnel \
  --region=us-central1 \
  --format="value(status)"
```

### Terraform - Cloud VPN

```hcl
# VPN Gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "cloud-vpn-gateway"
  network = google_compute_network.my_vpc.id
  region  = "us-central1"
}

# Firewall rules for VPN
resource "google_compute_firewall" "allow_esp" {
  name    = "allow-esp"
  network = google_compute_network.my_vpc.id

  allow {
    protocol = "esp"
  }

  source_ranges = ["203.0.113.0/24"]
}

resource "google_compute_firewall" "allow_udp_vpn" {
  name    = "allow-udp-vpn"
  network = google_compute_network.my_vpc.id

  allow {
    protocol = "udp"
    ports    = ["500", "4500"]
  }

  source_ranges = ["203.0.113.0/24"]
}

# VPN Tunnel
resource "google_compute_vpn_tunnel" "on_prem_tunnel" {
  name               = "on-prem-tunnel"
  vpn_gateway        = google_compute_vpn_gateway.vpn_gateway.id
  peer_ip            = "203.0.113.12"
  shared_secret      = "mysecret123"
  target_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.id

  ike_version = 2

  local_traffic_selector  = ["10.0.0.0/8"]
  remote_traffic_selector = ["192.168.0.0/16"]

  depends_on = [google_compute_firewall.allow_esp]
}

# Route for VPN tunnel
resource "google_compute_route" "vpn_route" {
  name                = "route-via-vpn"
  dest_range          = "192.168.0.0/16"
  network             = google_compute_network.my_vpc.id
  next_hop_vpn_gateway = google_compute_vpn_gateway.vpn_gateway.id
  priority            = 100
}

# Output
output "vpn_gateway_ip" {
  value = google_compute_vpn_gateway.vpn_gateway.gateway_ipv4_address
}
```

### Cloud VPN Best Practices
- Use Cloud Router for dynamic routing
- Implement redundancy with multiple VPN tunnels
- Use IKEv2 for better security
- Monitor VPN tunnel status continuously
- Test failover scenarios
- Use Cloud Armor for additional DDoS protection

---

## 8. DNS Services

### Overview
Google Cloud DNS provides managed, scalable DNS hosting for public and private zones.

### Zone Types

#### 1. Public Zones
- Records are publicly resolvable
- Google Cloud operates authoritative nameservers
- Use for public-facing applications

#### 2. Private Zones
- Records are only resolvable from within VPCs
- Not visible to the public internet
- Use for internal services
- Can be shared across VPCs

### Console Steps - Create DNS Zone

**Step 1: Create Zone**
```
1. Cloud DNS
2. Click "Create Zone"
3. Zone name: my-zone
4. DNS name: example.com
5. Zone type: Public (or Private)
6. Click "Create"
```

**Step 2: Add DNS Records**
```
1. Click on zone name
2. Click "Create Record Set"
3. DNS name: www.example.com
4. Record type: A
5. TTL: 300
6. IPv4 address: 1.2.3.4
7. Click "Create"
```

**Step 3: Update Nameservers (for public zones)**
```
1. Note the nameservers from "Zone Details"
2. Update your domain registrar to use these nameservers
3. Wait for DNS propagation (24-48 hours)
```

### gcloud Commands - DNS

```bash
# Create public zone
gcloud dns managed-zones create my-zone \
  --dns-name=example.com \
  --description="Production DNS zone"

# Create private zone
gcloud dns managed-zones create internal-zone \
  --dns-name=internal.example.com \
  --private-visibility-config=networks=my-vpc \
  --description="Private DNS zone"

# List zones
gcloud dns managed-zones list

# Describe zone
gcloud dns managed-zones describe my-zone

# Create A record
gcloud dns record-sets create www.example.com \
  --rrdatas=1.2.3.4 \
  --ttl=300 \
  --type=A \
  --zone=my-zone

# Create CNAME record
gcloud dns record-sets create blog.example.com \
  --rrdatas=www.example.com \
  --ttl=300 \
  --type=CNAME \
  --zone=my-zone

# Create MX record
gcloud dns record-sets create example.com \
  --rrdatas="10 mail.example.com" \
  --ttl=300 \
  --type=MX \
  --zone=my-zone

# Update record
gcloud dns record-sets update www.example.com \
  --rrdatas=2.3.4.5 \
  --ttl=300 \
  --type=A \
  --zone=my-zone

# List records in zone
gcloud dns record-sets list --zone=my-zone

# Delete record
gcloud dns record-sets delete www.example.com \
  --type=A \
  --zone=my-zone

# Delete zone
gcloud dns managed-zones delete my-zone

# Get nameservers
gcloud dns managed-zones describe my-zone \
  --format="value(nameServers[])"

# Export zone file
gcloud dns record-sets export records.yaml --zone=my-zone

# Import zone file
gcloud dns record-sets import records.yaml --zone=my-zone --replace-origin
```

### Terraform - DNS

```hcl
# Public DNS Zone
resource "google_dns_managed_zone" "public_zone" {
  name     = "my-zone"
  dns_name = "example.com."

  description = "Production DNS zone"
  visibility  = "public"
}

# Private DNS Zone
resource "google_dns_managed_zone" "private_zone" {
  name     = "internal-zone"
  dns_name = "internal.example.com."

  description = "Private DNS zone"
  visibility  = "private"

  private_visibility_config {
    networks_list {
      networks {
        network_url = google_compute_network.my_vpc.id
      }
    }
  }
}

# A Record (Public)
resource "google_dns_record_set" "www_record" {
  managed_zone = google_dns_managed_zone.public_zone.name
  name         = "www.example.com."
  type         = "A"
  ttl          = 300
  rrdatas      = ["1.2.3.4"]
}

# CNAME Record
resource "google_dns_record_set" "blog_record" {
  managed_zone = google_dns_managed_zone.public_zone.name
  name         = "blog.example.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["www.example.com."]
}

# MX Record
resource "google_dns_record_set" "mx_record" {
  managed_zone = google_dns_managed_zone.public_zone.name
  name         = "example.com."
  type         = "MX"
  ttl          = 300
  rrdatas      = ["10 mail.example.com."]
}

# TXT Record (SPF)
resource "google_dns_record_set" "spf_record" {
  managed_zone = google_dns_managed_zone.public_zone.name
  name         = "example.com."
  type         = "TXT"
  ttl          = 300
  rrdatas      = ["v=spf1 include:_spf.google.com ~all"]
}

# A Record (Private)
resource "google_dns_record_set" "private_app" {
  managed_zone = google_dns_managed_zone.private_zone.name
  name         = "app.internal.example.com."
  type         = "A"
  ttl          = 300
  rrdatas      = ["10.0.1.10"]
}

# Output nameservers
output "nameservers" {
  value = google_dns_managed_zone.public_zone.name_servers
}
```

### Best Practices
- Use private zones for internal services
- Set appropriate TTL values
- Use DNSSEC for public zones
- Monitor DNS query performance
- Document all DNS records
- Use different zones for different environments
- Implement redundancy for critical records

---

## 9. Network Security

### Overview
Multiple layers of security to protect your GCP network infrastructure.

### Security Components

#### 1. VPC Firewall Rules (Already Covered)
- Network-level access control
- Stateful filtering
- Tag and service account-based targeting

#### 2. Cloud Armor
- DDoS protection and Web Application Firewall (WAF)
- Works with load balancers
- Rule-based traffic filtering
- IP-based and geographic filtering

#### 3. Private Google Access
- Allows private instances to access Google APIs without internet
- Reduces security exposure
- Required for instances without public IPs

#### 4. Identity-Aware Proxy (IAP)
- Zero-trust security model
- Context-aware access control
- Verification through Google accounts
- SSH and RDP over IAP

### Console Steps - Enable Cloud Armor

**Step 1: Create Policy**
```
1. Cloud Armor Policies
2. Click "Create Policy"
3. Name: web-armor-policy
4. Default action: Allow
5. Click "Create"
```

**Step 2: Add Rules**
```
1. Click on policy name
2. Click "Add Rule"
3. Priority: 100
4. Condition: IP ranges
5. Values: 192.0.2.0/24 (malicious IPs)
6. Action: Deny
7. Click "Save"
```

**Step 3: Attach to Load Balancer**
```
1. Load Balancer → Backend Services
2. Select backend service
3. Click "Edit"
4. Enable Cloud Armor
5. Select policy: web-armor-policy
6. Click "Update"
```

### gcloud Commands - Network Security

```bash
# Create Cloud Armor policy
gcloud compute security-policies create web-armor-policy

# List Cloud Armor policies
gcloud compute security-policies list

# Add rule to Cloud Armor policy
gcloud compute security-policies rules create 100 \
  --security-policy=web-armor-policy \
  --action=allow \
  --expression="origin.region_code == 'US'"

# Add deny rule
gcloud compute security-policies rules create 101 \
  --security-policy=web-armor-policy \
  --action=deny \
  --priority=101 \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable')"

# Delete rule
gcloud compute security-policies rules delete 101 \
  --security-policy=web-armor-policy

# Describe policy
gcloud compute security-policies describe web-armor-policy

# Update policy
gcloud compute security-policies update web-armor-policy \
  --enable-layer7-ddos-defense

# Create hierarchical firewall policy
gcloud compute firewall-policies create org-firewall-policy \
  --short-name=org-policy

# Add rule to hierarchical firewall
gcloud compute firewall-policies rules create 100 \
  --firewall-policy=org-firewall-policy \
  --action=allow \
  --direction=INGRESS \
  --src-ip-ranges=10.0.0.0/8
```

### Terraform - Network Security

```hcl
# Cloud Armor Policy
resource "google_compute_security_policy" "web_armor" {
  name = "web-armor-policy"

  # Default action is allow
  # DDoS protection
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }

  # Allow only specific countries
  rule {
    action   = "allow"
    priority = 100
    match {
      expr {
        expression = "origin.region_code == 'US' || origin.region_code == 'CA'"
      }
    }
    description = "Allow from US and Canada"
  }

  # Deny SQLi attacks
  rule {
    action   = "deny(403)"
    priority = 101
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
    description = "Deny SQL injection"
  }

  # Deny XSS attacks
  rule {
    action   = "deny(403)"
    priority = 102
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-v33-stable')"
      }
    }
    description = "Deny XSS attacks"
  }

  # Rate limiting
  rule {
    action   = "rate_based_ban"
    priority = 103
    match {
      expr {
        expression = "true"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
      ban_duration_sec = 600
    }
    description = "Rate limit to 100 requests per minute"
  }

  rule {
    action   = "allow"
    priority = 65534
    match {
      versioned_expr = "V1"
      expr {
        expression = "true"
      }
    }
    description = "Default rule"
  }
}

# Attach Cloud Armor to backend service
resource "google_compute_backend_service" "web_backend_secure" {
  name            = "web-backend-secure"
  security_policy = google_compute_security_policy.web_armor.id
  # ... rest of backend config
}

# Cloud NAT for private Google Access
resource "google_compute_router_nat" "private_nat" {
  name                               = "private-nat"
  router                             = google_compute_router.my_router.name
  region                             = google_compute_router.my_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Output policy ID
output "security_policy_id" {
  value = google_compute_security_policy.web_armor.id
}
```

### Best Practices
- Implement multiple layers of security
- Use Cloud Armor for public-facing services
- Enable Private Google Access for private instances
- Monitor and log all security events
- Implement rate limiting
- Use geographic restrictions when appropriate
- Regularly update security policies
- Test security rules before deployment

---

## 10. Cloud NAT (Network Address Translation)

### Overview
Cloud NAT allows private instances to initiate outbound connections to the internet while remaining private.

### Key Features
- **Outbound-only**: Instances remain unreachable from internet
- **Automatic IP allocation**: Google Cloud assigns public IPs
- **No instances modification**: Works transparently
- **Logging**: Monitor NAT traffic

### Console Steps - Enable Cloud NAT

**Step 1: Create Cloud Router** (if not exists)
```
1. VPC Network → Cloud Routers
2. Click "Create Router"
3. Configure router (as shown earlier)
```

**Step 2: Add NAT Gateway**
```
1. Click on router
2. Go to "NAT and Firewall"
3. Click "Create NAT"
4. Name: nat-gateway
5. Region: us-central1
6. Cloud Router: Select your router
7. NAT mapping: All subnets
8. Source: All primary and secondary ranges
9. Click "Create"
```

### gcloud Commands - Cloud NAT

```bash
# Create Cloud Router for NAT
gcloud compute routers create nat-router \
  --network=my-vpc \
  --region=us-central1

# Create NAT gateway
gcloud compute routers nats create nat-gateway \
  --router=nat-router \
  --region=us-central1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips

# Create NAT with specific subnets
gcloud compute routers nats create nat-gateway-specific \
  --router=nat-router \
  --region=us-central1 \
  --subnets=subnet-us-central1 \
  --auto-allocate-nat-external-ips

# Create NAT with manual IP allocation
gcloud compute addresses create nat-ips --region=us-central1 --count=2

gcloud compute routers nats create nat-gateway-manual \
  --router=nat-router \
  --region=us-central1 \
  --nat-all-subnet-ip-ranges \
  --nat-external-ip-pool=nat-ips

# Enable logging
gcloud compute routers nats update nat-gateway \
  --router=nat-router \
  --region=us-central1 \
  --enable-logging

# List NAT gateways
gcloud compute routers nats list --router=nat-router --region=us-central1

# View NAT status
gcloud compute routers get-status nat-router --region=us-central1
```

### Terraform - Cloud NAT

```hcl
# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.my_router.name
  region                             = google_compute_router.my_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  enable_logging = true

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Optional: Specify which subnets use NAT
  subnetwork {
    name                    = google_compute_subnetwork.subnet_us_central1.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Alternative: NAT with reserved IPs
resource "google_compute_address" "nat_ip" {
  count        = 2
  name         = "nat-ip-${count.index + 1}"
  address_type = "EXTERNAL"
  region       = "us-central1"
}

resource "google_compute_router_nat" "nat_reserved" {
  name                               = "nat-gateway-reserved"
  router                             = google_compute_router.my_router.name
  region                             = google_compute_router.my_router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = google_compute_address.nat_ip[*].self_link
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Output NAT IPs
output "nat_external_ips" {
  value = google_compute_address.nat_ip[*].address
}
```

### Best Practices
- Use Cloud NAT for private instances needing outbound internet
- Reserve static IPs if consistent external IPs are needed
- Enable logging for audit trails
- Monitor NAT gateway utilization
- Plan for IP allocation and port limits
- Use Cloud NAT with Cloud Router for flexibility

---

## 11. Cloud VPN (Detailed)

### Overview
Already covered in Section 7, but here's additional depth.

### VPN Tunnel Configuration Details

**IKE (Internet Key Exchange) Versions:**
- **IKEv1**: Older, more compatible, less secure
- **IKEv2**: Newer, more secure, recommended

**IPsec Settings:**
- **Encryption**: AES-128, AES-192, AES-256
- **Authentication**: SHA1, SHA2-256, SHA2-384, SHA2-512
- **Diffie-Hellman Group**: Group 1, 2, 5, 14, 15, 16

### Terraform - Advanced VPN Configuration

```hcl
# IKE Policy
resource "google_compute_vpn_gateway" "vpn" {
  name    = "vpn-gateway"
  network = google_compute_network.my_vpc.id
  region  = "us-central1"
}

resource "google_compute_vpn_tunnel" "tunnel" {
  name                          = "vpn-tunnel"
  vpn_gateway                   = google_compute_vpn_gateway.vpn.id
  peer_ip                       = "203.0.113.12"
  shared_secret                 = "your-shared-secret"
  target_vpn_gateway            = google_compute_vpn_gateway.vpn.id
  ike_version                   = 2
  remote_traffic_selector       = ["192.168.0.0/16"]
  local_traffic_selector        = ["10.0.0.0/8"]
  ike_negotiation_mode          = "MAIN"

  # Advanced IKE settings
  ike_sa_lifetime = 28800  # 8 hours

  # Advanced IPsec settings
  ipsec_sa_lifetime = 3600  # 1 hour
}

# Output
output "tunnel_status" {
  value = google_compute_vpn_tunnel.tunnel.status
}
```

---

## 12. Service Endpoints

### Overview
Service Endpoints provide private connectivity to GCP services without requiring internet gateways.

### Available Services
- Google Cloud Storage
- BigQuery
- Cloud SQL
- Cloud Pub/Sub
- Firebase services

### Terraform - Service Endpoints

```hcl
# Enable service connectivity
resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering              = google_compute_network_peering.peering.name
  network              = google_compute_network.my_vpc.name
  import_custom_routes = true
  export_custom_routes = true
}

# Private Service Connection
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.my_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.my_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
```

---

## 13. Private Service Connection

### Overview
Allows secure access to GCP services from private instances without internet.

### Key Benefits
- **Private connectivity**: No exposure to internet
- **Reduced latency**: Direct connection to services
- **Better security**: Private access only
- **No NAT required**: Direct service access

### Terraform - Private Service Connection

```hcl
# Configure private service access
resource "google_compute_global_address" "private_service_ip" {
  name          = "private-service-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.my_vpc.id
}

resource "google_service_networking_connection" "service_connection" {
  network                 = google_compute_network.my_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_ip.name]
}

# Cloud SQL with private service connection
resource "google_sql_database_instance" "private_db" {
  name             = "private-db-instance"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.my_vpc.id
    }
  }

  deletion_protection = true

  depends_on = [google_service_networking_connection.service_connection]
}
```

---

## 14. VPC Flow Logs

### Overview
VPC Flow Logs capture information about IP traffic flowing to and from network interfaces.

### Log Contents
- Source and destination IP addresses
- Source and destination ports
- Protocol
- Packets and bytes sent
- Start and end time of flow
- Action taken (ACCEPT or DENY)

### Console Steps - Enable VPC Flow Logs

**Step 1: Enable on Subnet**
```
1. VPC Network → Subnets
2. Click on subnet
3. Click "Edit"
4. Enable "Flow Logs"
5. Select logging options
6. Click "Save"
```

### gcloud Commands - VPC Flow Logs

```bash
# Enable VPC Flow Logs on subnet
gcloud compute networks subnets update subnet-us-central1 \
  --region=us-central1 \
  --enable-flow-logs \
  --logging-aggregation-interval=interval-5-sec \
  --logging-flow-sampling=0.5 \
  --logging-metadata=include_all_metadata

# Query VPC Flow Logs in Cloud Logging
gcloud logging read \
  'resource.type="gce_subnetwork" AND jsonPayload.flow_direction="INGRESS"' \
  --limit=10 \
  --format=json
```

### Terraform - VPC Flow Logs

```hcl
resource "google_compute_subnetwork" "subnet_with_logs" {
  name                     = "subnet-with-logs"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.my_vpc.id
  private_ip_google_access = true

  enable_flow_logs = true

  log_config {
    aggregation_interval = "interval_5_sec"
    flow_sampling        = 0.5
    metadata             = "include_all_metadata"
  }
}
```

---

## 15. VPC Peering & Service Networking

### VPC Peering

**Definition**: Connect two VPCs together (in same or different projects)

**Types:**
- **Same-project peering**: Within same project
- **Cross-project peering**: Between different projects
- **Same-region peering**: Lower latency
- **Global peering**: Higher latency but more flexibility

### Console Steps - Create VPC Peering

**Step 1: Initiate Peering**
```
1. VPC Network → VPC Peering
2. Click "Create Peering Connection"
3. Name: vpc1-to-vpc2-peering
4. Your VPC: vpc1
5. Peered VPC project: Select project
6. Peered VPC network: vpc2
7. Click "Create"
```

### gcloud Commands - VPC Peering

```bash
# Create VPC peering (same project)
gcloud compute networks peerings create vpc1-to-vpc2-peering \
  --network=vpc1 \
  --auto-create-routes \
  --peer-network=vpc2

# Create VPC peering (cross-project)
gcloud compute networks peerings create vpc1-to-vpc2-peering \
  --network=vpc1 \
  --auto-create-routes \
  --peer-project=PROJECT-B \
  --peer-network=vpc2

# List peering connections
gcloud compute networks peerings list

# Describe peering
gcloud compute networks peerings describe vpc1-to-vpc2-peering --network=vpc1

# Update peering (export routes)
gcloud compute networks peerings update vpc1-to-vpc2-peering \
  --network=vpc1 \
  --export-custom-routes
```

### Terraform - VPC Peering

```hcl
# Local peering
resource "google_compute_network_peering" "vpc1_to_vpc2" {
  name         = "vpc1-to-vpc2-peering"
  network      = google_compute_network.vpc1.self_link
  peer_network = google_compute_network.vpc2.self_link

  auto_create_routes = true

  export_custom_routes = true
  import_custom_routes = true
}

# Reverse peering (required for bidirectional traffic)
resource "google_compute_network_peering" "vpc2_to_vpc1" {
  name         = "vpc2-to-vpc1-peering"
  network      = google_compute_network.vpc2.self_link
  peer_network = google_compute_network.vpc1.self_link

  auto_create_routes = true

  export_custom_routes = true
  import_custom_routes = true

  depends_on = [google_compute_network_peering.vpc1_to_vpc2]
}

# Output peering status
output "peering_active" {
  value = google_compute_network_peering.vpc1_to_vpc2.state
}
```

---

## 16. Interview Q&A with Real-Time Examples

### Q1: What's the difference between auto-mode and custom-mode VPCs?

**Answer:**
```
AUTO-MODE:
- Google creates subnets automatically in each region
- Each subnet gets a /20 network (4,096 IPs)
- Starting CIDR: 10.128.0.0/9
- Good for: Quick prototyping, small projects
- Less flexible: Limited control over IP ranges

CUSTOM-MODE:
- You create all subnets manually
- Full control over IP ranges
- No automatic subnet creation
- Good for: Production, complex networking
- More flexible: Plan IP addressing carefully

Example:
Auto-mode VPC automatically gets:
- us-central1: 10.128.0.0/20
- us-east1: 10.132.0.0/20
- europe-west1: 10.132.0.0/20

Custom-mode VPC: You decide ranges
- us-central1: 10.0.0.0/24
- us-east1: 10.1.0.0/24
```

### Q2: How do firewall rules work? Are they stateful?

**Answer:**
```
YES - Firewall rules are STATEFUL

WHAT THIS MEANS:
- If you allow outbound traffic, return traffic is automatically allowed
- If you deny inbound traffic, you must explicitly allow responses
- Response traffic uses same protocol/ports as original

EXAMPLE:
Allow rule: tcp:80 (HTTP)
┌─ Instance sends request to external server
├─ Firewall evaluates OUTBOUND rule (if exists)
├─ Server sends response back
└─ Firewall AUTOMATICALLY ALLOWS response (stateful)

PRIORITY:
- Lower number = Higher priority (0 is highest)
- First matching rule is applied
- Default: 1000

EXAMPLE PRIORITY:
Rule 1 (Priority 100): Deny traffic from 192.168.1.0/24
Rule 2 (Priority 1000): Allow all traffic from 10.0.0.0/8
→ If source is 192.168.1.5, Rule 1 applies (lower number wins)
```

### Q3: What's Cloud NAT and why would you use it?

**Answer:**
```
CLOUD NAT: Allows private instances to reach internet without
exposing them to inbound internet traffic

USE CASES:
1. Private instances needing software updates from internet repos
2. Instances needing to call external APIs
3. Instances needing to send logs to external services
4. Security requirement: No inbound internet access

EXAMPLE ARCHITECTURE:

Without Cloud NAT:
┌─ Private Instance (10.0.1.10)
├─ Wants to download from package repo
└─ ❌ Can't reach internet (no public IP)

With Cloud NAT:
┌─ Private Instance (10.0.1.10)
├─ Cloud NAT Gateway (receives packet)
├─ Translates source IP to external IP (35.184.1.1)
├─ Sends to internet
├─ Receives response
├─ Translates back to 10.0.1.10
└─ ✅ Instance gets data

COMMAND:
gcloud compute routers nats create nat-gateway \
  --router=my-router \
  --region=us-central1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips
```

### Q4: Explain VPC Peering vs VPN

**Answer:**
```
VPC PEERING:
- Connects two VPCs directly
- Low latency, high bandwidth
- Same project or cross-project
- Works globally
- Free (inbound traffic charged)
- No encryption (private Google network)
- Use case: Connecting related VPCs

CLOUD VPN:
- Connects VPC to on-premises or other cloud
- Encrypted tunnel over internet
- Medium latency (internet routing)
- Limited bandwidth (~3 Gbps)
- Charged per tunnel
- Encryption enabled
- Use case: Hybrid connectivity

COMPARISON TABLE:
┌─────────────────┬──────────────┬─────────────┐
│ Feature         │ VPC Peering  │ Cloud VPN   │
├─────────────────┼──────────────┼─────────────┤
│ Latency         │ Low          │ Medium      │
│ Bandwidth       │ High         │ ~3 Gbps     │
│ Encryption      │ No           │ Yes         │
│ Cost            │ Low          │ Higher      │
│ Setup time      │ Minutes      │ Hours       │
│ On-premises     │ No           │ Yes         │
└─────────────────┴──────────────┴─────────────┘

EXAMPLE DECISION:
- Connecting GCP projects: Use VPC Peering
- Connecting to data center: Use Cloud VPN
- Connecting to AWS: Use Cloud VPN or Dedicated Interconnect
```

### Q5: What's the best way to organize VPCs for a company with multiple teams?

**Answer:**
```
RECOMMENDED STRUCTURE:

Organizational Level:
├─ Management VPC (Shared services)
│  └─ Central logging, monitoring, VPN gateway
├─ Development VPC
│  └─ Dev/Test environment
├─ Staging VPC
│  └─ Pre-production testing
└─ Production VPC
   └─ Customer-facing workloads

Within Each VPC:

Production VPC:
├─ Public Subnet (10.0.0.0/24)
│  └─ Load balancers, bastion hosts
├─ App Tier Subnet (10.0.1.0/24)
│  └─ Application servers
├─ Database Subnet (10.0.2.0/24)
│  └─ Databases (no direct internet)
└─ Admin Subnet (10.0.3.0/24)
   └─ Management tools

FIREWALL RULES EXAMPLE:

# Allow internet to load balancers
Allow: 0.0.0.0/0 → 10.0.0.0/24 (TCP: 80, 443)

# Allow load balancers to app tier
Allow: 10.0.0.0/24 → 10.0.1.0/24 (TCP: 8080)

# Allow app tier to database
Allow: 10.0.1.0/24 → 10.0.2.0/24 (TCP: 3306)

# DENY: Direct internet to database
Deny: 0.0.0.0/0 → 10.0.2.0/24 (all)

CONNECTIVITY:

VPC Peering for:
├─ Production ↔ Management
└─ Staging ↔ Management

Cloud VPN for:
└─ All VPCs ↔ On-premises data center
```

### Q6: How do you implement high availability for VPC resources?

**Answer:**
```
MULTI-REGION HIGH AVAILABILITY DESIGN:

Region 1 (us-central1):
├─ VPC: vpc-prod
├─ Subnets:
│  ├─ us-central1-a (10.0.0.0/24)
│  └─ us-central1-b (10.0.1.0/24)
├─ Compute Instances:
│  ├─ Instance 1 (us-central1-a)
│  ├─ Instance 2 (us-central1-b)
│  └─ Instance 3 (us-central1-c)
└─ Load Balancer (Global HTTP(S))

Region 2 (us-east1):
├─ VPC: vpc-prod (same)
├─ Subnets:
│  ├─ us-east1-b (10.1.0.0/24)
│  └─ us-east1-c (10.1.1.0/24)
└─ Compute Instances:
   ├─ Instance 4 (us-east1-b)
   └─ Instance 5 (us-east1-c)

KEY COMPONENTS:

1. Global Load Balancer
   ├─ Distributes traffic globally
   └─ Automatic failover to healthy backends

2. Cloud Router (each region)
   ├─ Manages BGP for dynamic routing
   └─ Updates routes automatically

3. Cloud NAT (each region)
   ├─ Independent NAT gateway per region
   └─ Ensures outbound connectivity

4. VPC Peering or Global VPC
   ├─ Automatic routing between regions
   └─ Low latency communication

5. Health Checks
   ├─ Continuous monitoring
   └─ Automatic instance replacement

TERRAFORM EXAMPLE:

resource "google_compute_global_forwarding_rule" "ha_rule" {
  name                  = "ha-forwarding-rule"
  ip_protocol          = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range           = "80"
  target               = google_compute_target_http_proxy.ha_proxy.id
}

resource "google_compute_backend_service" "ha_backend" {
  name                  = "ha-backend-service"
  health_checks         = [google_compute_health_check.ha_check.id]
  
  # Add multiple instance groups
  backend {
    group           = google_compute_instance_group_manager.ig_us_central1.instance_group
    balancing_mode  = "RATE"
    max_rate_per_instance = 100
  }
  
  backend {
    group           = google_compute_instance_group_manager.ig_us_east1.instance_group
    balancing_mode  = "RATE"
    max_rate_per_instance = 100
  }
}
```

### Q7: How do you implement network security in depth (defense in depth)?

**Answer:**
```
DEFENSE IN DEPTH NETWORK SECURITY:

Layer 1: DDoS Protection
├─ Cloud Armor (WAF)
├─ Google's infrastructure DDoS protection
└─ Rate limiting

Layer 2: Edge Security
├─ Cloud CDN
├─ Google Front End
└─ Google Cloud Armor

Layer 3: VPC-Level Security
├─ Firewall Rules
├─ Network tags and service accounts
├─ VPC Flow Logs
└─ Network segmentation

Layer 4: Instance-Level Security
├─ OS Firewall (iptables)
├─ SELinux/AppArmor
├─ Host-based IDS
└─ IAM service accounts

Layer 5: Application-Level Security
├─ TLS/SSL
├─ API authentication
├─ Input validation
└─ Application logging

EXAMPLE COMPLETE SECURITY SETUP:

# Layer 1: Cloud Armor
resource "google_compute_security_policy" "defense_in_depth" {
  name = "defense-in-depth"
  
  # DDoS protection
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
  
  # Rate limiting
  rule {
    action   = "rate_based_ban"
    priority = 100
    match {
      expr {
        expression = "true"
      }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 1000
        interval_sec = 60
      }
    }
  }
  
  # Geo-blocking
  rule {
    action   = "deny(403)"
    priority = 101
    match {
      expr {
        expression = "origin.country_code == 'KP'"  # North Korea example
      }
    }
  }
  
  # SQLi protection
  rule {
    action   = "deny(403)"
    priority = 102
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-v33-stable')"
      }
    }
  }
}

# Layer 3: VPC Firewall Rules
resource "google_compute_firewall" "public_tier" {
  name    = "allow-public-http"
  network = google_compute_network.my_vpc.name
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
  
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "app_tier" {
  name    = "allow-app-internal"
  network = google_compute_network.my_vpc.name
  
  source_service_accounts = [google_service_account.lb.email]
  target_tags             = ["app-server"]
  
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

resource "google_compute_firewall" "database_tier" {
  name    = "allow-db-internal"
  network = google_compute_network.my_vpc.name
  
  source_service_accounts = [google_service_account.app.email]
  target_service_accounts = [google_service_account.db.email]
  
  allow {
    protocol = "tcp"
    ports    = ["3306", "5432"]
  }
}

# Deny everything else
resource "google_compute_firewall" "default_deny" {
  name      = "deny-all-default"
  network   = google_compute_network.my_vpc.name
  priority  = 65535
  direction = "INGRESS"
  action    = "DENY"
  
  source_ranges = ["0.0.0.0/0"]
  
  deny {
    protocol = "tcp"
  }
  
  deny {
    protocol = "udp"
  }
}

# Enable VPC Flow Logs
resource "google_compute_subnetwork" "secure_subnet" {
  name                     = "secure-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  network                  = google_compute_network.my_vpc.id
  region                   = "us-central1"
  private_ip_google_access = true
  
  enable_flow_logs = true
  
  log_config {
    aggregation_interval = "interval_5_sec"
    flow_sampling        = 1.0  # Log all flows
    metadata             = "include_all_metadata"
  }
}
```

### Q8: You have a production application that needs to connect to on-premises database. What are your options and recommendations?

**Answer:**
```
SCENARIO: Production app (GCP) ↔ On-premises database

OPTION 1: Cloud VPN
PROS:
├─ Quick setup (hours vs weeks)
├─ Cost-effective
├─ Works over internet
└─ Encrypted connection

CONS:
├─ Limited bandwidth (~3 Gbps)
├─ Internet routing adds latency
├─ Less reliable (internet dependent)
└─ Encryption overhead

USE CASE:
└─ Backup link, non-critical workloads, PoC

OPTION 2: Dedicated Interconnect
PROS:
├─ High bandwidth (10 Gbps or 100 Gbps)
├─ Private connection (no internet)
├─ Low, predictable latency
├─ High SLA (99.99%)
└─ Better performance

CONS:
├─ Long setup time (8-12 weeks)
├─ High cost
├─ Requires physical infrastructure
└─ Less flexible

USE CASE:
└─ Production workloads, sustained high traffic

OPTION 3: Partner Interconnect
PROS:
├─ Faster setup than Dedicated (4-8 weeks)
├─ Through partners' data centers
├─ Lower cost than Dedicated
└─ Still private and low-latency

CONS:
├─ Lower bandwidth (50 Mbps - 10 Gbps)
├─ Partner dependent
└─ Still expensive

USE CASE:
└─ Organizations without direct DC access

RECOMMENDATION FOR PRODUCTION:

┌─ Start with:
│  ├─ Cloud VPN as backup link
│  └─ Dedicated Interconnect as primary
│
├─ Architecture:
│  ├─ Dedicated Interconnect (primary, 10 Gbps)
│  └─ Cloud VPN (backup, automatic failover)
│
├─ Configuration:
│  ├─ Cloud Router with BGP
│  ├─ Higher priority for Dedicated
│  └─ Fallback to VPN if Dedicated fails
│
└─ Monitoring:
   ├─ Connection health checks
   ├─ Automatic alerting
   └─ Regular failover testing

TERRAFORM EXAMPLE:

# Primary: Dedicated Interconnect
resource "google_compute_interconnect" "primary_interconnect" {
  name                     = "primary-interconnect"
  location                 = "us-central1"  # Must match available PoP
  link_type                = "LINK_TYPE_ETHERNET_10G"
  interconnect_type        = "DEDICATED"
  requested_link_count     = 1
  admin_enabled            = true
}

# Router for BGP
resource "google_compute_router" "hybrid_router" {
  name    = "hybrid-router"
  network = google_compute_network.my_vpc.id
  region  = "us-central1"
  asn     = 64514
}

# Primary route via Interconnect
resource "google_compute_route" "interconnect_route" {
  name                = "route-via-interconnect"
  dest_range          = "192.168.0.0/16"  # On-prem network
  network             = google_compute_network.my_vpc.id
  next_hop_ip_address = "169.254.34.1"  # BGP peer IP
  priority            = 100  # Higher priority
}

# Backup route via VPN
resource "google_compute_route" "vpn_backup_route" {
  name                    = "route-via-vpn-backup"
  dest_range              = "192.168.0.0/16"
  network                 = google_compute_network.my_vpc.id
  next_hop_vpn_gateway    = google_compute_vpn_gateway.vpn.self_link
  priority                = 200  # Lower priority (backup)
}

# Cloud NAT for outbound
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway"
  router                             = google_compute_router.hybrid_router.name
  region                             = google_compute_router.hybrid_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Application configuration
resource "google_compute_instance" "app_server" {
  name         = "app-server"
  zone         = "us-central1-a"
  machine_type = "e2-medium"
  
  network_interface {
    network    = google_compute_network.my_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No public IP - uses Cloud NAT
  }
  
  # Application connects to:
  # jdbc:mysql://192.168.10.5:3306/productdb
  # (on-premises database via Interconnect)
}
```

### Q9: How do you monitor and troubleshoot network issues?

**Answer:**
```
MONITORING & TROUBLESHOOTING TOOLS:

1. VPC Flow Logs
   └─ See actual traffic flowing through network

2. Cloud Monitoring
   └─ Metrics for VPC, subnets, routes

3. Cloud Logging
   └─ All network events and errors

4. Network Intelligence Center
   ├─ Connectivity tests
   ├─ Performance monitoring
   └─ Firewall analysis

5. Packet Mirroring
   └─ Mirror traffic for analysis

TROUBLESHOOTING CHECKLIST:

ISSUE: Instance can't reach another instance in same VPC
CHECK:
├─ 1. Are both instances running?
├─ 2. Do firewall rules allow traffic?
│   └─ gcloud compute firewall-rules list --filter="network:my-vpc"
├─ 3. Are they in same VPC?
│   └─ gcloud compute instances describe INSTANCE --zone=ZONE
├─ 4. Is traffic routed correctly?
│   └─ gcloud compute routes list
└─ 5. Check VPC Flow Logs
    └─ Look for ACCEPT or DENY entries

ISSUE: Can't reach external service
CHECK:
├─ 1. Does instance have public IP or Cloud NAT?
├─ 2. Are firewall rules blocking egress?
│   └─ Check egress firewall rules
├─ 3. Is Cloud NAT working?
│   └─ gcloud compute routers get-status ROUTER --region=REGION
├─ 4. Check routes to internet gateway
│   └─ gcloud compute routes list --filter="nextHopGateway:*"
└─ 5. Test with curl or wget from instance

EXAMPLE DEBUGGING COMMANDS:

# SSH into instance
gcloud compute ssh INSTANCE --zone=ZONE

# From instance, test connectivity
curl -I http://example.com  # Internet
ssh -i key 10.0.1.5  # Internal instance

# Check instance details
gcloud compute instances describe INSTANCE --zone=ZONE

# Test firewall rules
# See what would happen if traffic arrived
gcloud compute security-policies rules list \
  --security-policy=POLICY

# Real-time traffic monitoring
gcloud logging read "resource.type=gce_subnetwork" \
  --limit=50 \
  --format=json

# Analyze VPC Flow Logs
gcloud logging read \
  'resource.type="gce_subnetwork" 
   AND jsonPayload.bytes_sent>0 
   AND jsonPayload.action="DENY"' \
  --limit=20
```

---

## Summary - Quick Reference

### VPC Planning Checklist
```
□ Determine mode: Auto vs Custom
□ Plan IP addressing (CIDR blocks)
□ Design subnet architecture
□ Plan firewall rules
□ Identify hybrid connectivity needs
□ Plan for scalability and growth
□ Document everything
□ Test before production deployment
```

### Security Best Practices
```
□ Implement firewall rules (deny by default)
□ Enable VPC Flow Logs
□ Use Cloud Armor for public services
□ Implement Cloud NAT for private instances
□ Use service accounts for IAM control
□ Enable Private Google Access
□ Monitor with Cloud Monitoring
□ Implement network segmentation
□ Use VPC Peering for connected VPCs
□ Audit firewall rules regularly
```

### Production Deployment Checklist
```
□ Use custom-mode VPCs
□ Multiple regions for HA
□ Cloud Load Balancer for traffic distribution
□ Cloud NAT for outbound connections
□ Cloud Router for dynamic routing
□ Cloud Armor for DDoS protection
□ VPC Flow Logs enabled
□ Comprehensive monitoring and alerting
□ Tested failover procedures
□ Documented architecture
```

