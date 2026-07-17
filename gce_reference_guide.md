# Google Compute Engine (GCE) — Complete Reference Guide
### Console Steps + gcloud CLI Commands + Terraform for a 9-Year GCP Cloud Engineer Interview

---

## Table of Contents
1. [Compute Engine Basics](#1-compute-engine-basics)
2. [VM Instance Creation](#2-vm-instance-creation)
3. [Machine Types](#3-machine-types)
4. [CPU & Memory](#4-cpu--memory)
5. [Boot Disks](#5-boot-disks)
6. [Storage / Persistent Disks](#6-storage--persistent-disks)
7. [Images](#7-images)
8. [Snapshots](#8-snapshots)
9. [Networking](#9-networking)
10. [SSH Access](#10-ssh-access)
11. [IAM & Service Accounts](#11-iam--service-accounts)
12. [Metadata & Startup/Shutdown Scripts](#12-metadata--startupshutdown-scripts)
13. [Availability & Maintenance](#13-availability--maintenance)
14. [Managed Instance Groups (MIG)](#14-managed-instance-groups-mig)
15. [Load Balancing](#15-load-balancing)
16. [Autoscaling](#16-autoscaling)
17. [VM Lifecycle](#17-vm-lifecycle)
18. [Security (Shielded / Confidential VM)](#18-security)
19. [Monitoring & Logging](#19-monitoring--logging)
20. [Backup & Disaster Recovery](#20-backup--disaster-recovery)
21. [Cost Optimization](#21-cost-optimization)
22. [GPU & Accelerators](#22-gpu--accelerators)
23. [Instance Templates](#23-instance-templates)
24. [Automation (Terraform / gcloud)](#24-automation)
25. [Troubleshooting](#25-troubleshooting)
26. [Best Practices](#26-best-practices)
27. [Quick Command Cheat Sheet](#27-quick-command-cheat-sheet)
28. [Terraform Resource Reference](#28-terraform-resource-reference)
29. [Real-Time Interview Scenarios](#29-real-time-interview-scenarios)

---

## 1. Compute Engine Basics

### What is Compute Engine?
Compute Engine (GCE) is Google Cloud's **Infrastructure-as-a-Service (IaaS)** product. It provides on-demand, configurable virtual machines (VMs) running in Google's global data centers. Unlike PaaS (App Engine) or serverless (Cloud Run), you manage the OS, runtime, and application stack yourself — Google manages the underlying hardware, hypervisor, and physical network.

**Key characteristics:**
- Per-second billing (after a 1-minute minimum)
- Choice of predefined or custom machine types
- Live migration during host maintenance (no reboot required)
- Global network with Google's private backbone

### IaaS vs PaaS vs SaaS
| Model | You Manage | Google Manages | Example |
|---|---|---|---|
| IaaS | OS, runtime, app, data | Hardware, virtualization, network | Compute Engine |
| PaaS | App, data | OS, runtime, scaling | App Engine, Cloud Run |
| SaaS | Nothing (just use it) | Everything | Google Workspace |

### Global Infrastructure — Regions & Zones
- **Region**: A specific geographic location (e.g., `us-central1`, `asia-south1`).
- **Zone**: An isolated deployment area within a region (e.g., `us-central1-a`, `us-central1-b`). Zones in the same region have low-latency, high-bandwidth network connections.
- Resources are **zonal** (VM instances, disks), **regional** (regional MIGs, regional disks), or **global** (images, snapshots, HTTP(S) load balancers).

```bash
# List all available regions
gcloud compute regions list

# List all zones in a specific region
gcloud compute zones list --filter="region:us-central1"

# Set default region/zone for your gcloud config (avoids repeating flags)
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

### Machine Images vs Custom Images
- **Machine Image**: Captures the *entire* VM — boot disk, additional disks, metadata, permissions, and machine type. Used for full VM backup/clone.
- **Custom Image**: Captures only a *boot disk* to reuse as a template for new VMs.

### Billing Concepts
- **Per-second billing**, 1-minute minimum usage.
- **Sustained Use Discounts (SUD)**: Automatic discount for running a VM a significant portion of the billing month (mostly applies to N1; newer families favor CUDs).
- **Committed Use Discounts (CUD)**: Commit to 1 or 3 years for a discount (up to ~57%).
- **Spot VMs**: Steep discount (up to 91%) but can be preempted anytime.
- Billing is based on: machine type (vCPU + memory), boot/persistent disk size & type, network egress, and any attached GPUs.


---

## 2. VM Instance Creation

### A. Creating a VM from the Console
1. Go to **Navigation Menu → Compute Engine → VM instances**.
2. Click **Create Instance**.
3. Set **Name**, **Region**, **Zone**.
4. Choose **Machine configuration** (series + machine type, e.g., E2 / e2-medium).
5. Under **Boot disk**, click **Change** → select OS image (e.g., Debian, Ubuntu), disk type (Balanced PD), and size.
6. Under **Firewall**, check **Allow HTTP/HTTPS traffic** if needed.
7. Expand **Advanced options** for:
   - **Networking**: network tags, network interface, IP configuration
   - **Management**: startup script, labels, description
   - **Security**: Shielded VM options, service account, access scopes
   - **Disks**: additional persistent disks
8. Click **Create**.

### B. Creating a VM using gcloud CLI
```bash
gcloud compute instances create my-vm-1 \
  --zone=us-central1-a \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --boot-disk-type=pd-balanced \
  --tags=http-server,https-server \
  --labels=env=dev,team=platform \
  --metadata=startup-script='#! /bin/bash
    apt-get update
    apt-get install -y nginx'
```

Common flags explained:
| Flag | Purpose |
|---|---|
| `--machine-type` | e.g., e2-medium, n2-standard-4 |
| `--image-family` / `--image-project` | OS image source |
| `--boot-disk-size` / `--boot-disk-type` | Boot disk config |
| `--tags` | Network tags for firewall rules |
| `--labels` | Key-value metadata for billing/organization |
| `--metadata` / `--metadata-from-file` | Custom metadata / startup scripts |
| `--network` / `--subnet` | VPC placement |
| `--no-address` | Create VM with no external IP |
| `--service-account` / `--scopes` | Attach identity & API access scopes |

### C. Creating a VM using Terraform
```hcl
resource "google_compute_instance" "vm_instance" {
  name         = "my-vm-1"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {} # ephemeral external IP
  }

  metadata_startup_script = "apt-get update && apt-get install -y nginx"

  labels = {
    env  = "dev"
    team = "platform"
  }

  tags = ["http-server", "https-server"]
}
```
```bash
terraform init
terraform plan
terraform apply
```

### Startup Scripts
Run automatically **every time the VM boots**. Used for software installs, configuration, or bootstrapping.
```bash
# Inline
gcloud compute instances create my-vm --metadata=startup-script='#! /bin/bash
echo "Hello from startup script" > /tmp/hello.txt'

# From a local file
gcloud compute instances create my-vm --metadata-from-file=startup-script=./startup.sh

# Update startup script on an existing VM (takes effect on next boot)
gcloud compute instances add-metadata my-vm \
  --zone=us-central1-a \
  --metadata-from-file=startup-script=./startup.sh
```

### Shutdown Scripts
Run when the VM is stopped, terminated, or deleted (best-effort, has a time limit ~90s for most termination types).
```bash
gcloud compute instances add-metadata my-vm \
  --zone=us-central1-a \
  --metadata-from-file=shutdown-script=./shutdown.sh
```

### Custom Metadata
Key-value pairs accessible inside the VM via the metadata server (`http://metadata.google.internal/computeMetadata/v1/`).
```bash
# Set custom metadata
gcloud compute instances add-metadata my-vm --zone=us-central1-a \
  --metadata=env=prod,owner=devops-team

# Read metadata from inside the VM
curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/env" \
  -H "Metadata-Flavor: Google"
```

### Labels vs Tags
- **Labels**: Key-value pairs for **billing, filtering, and organization** across all resource types. Do not affect networking.
- **Network Tags**: Simple string tags used specifically to **target firewall rules and routes**.

```bash
# Labels
gcloud compute instances add-labels my-vm --zone=us-central1-a --labels=env=prod

# Network tags
gcloud compute instances add-tags my-vm --zone=us-central1-a --tags=web-server
```


---

## 3. Machine Types

GCE machine types are grouped into families based on workload optimization:

| Family | Series | Best For |
|---|---|---|
| General Purpose | E2, N2, N2D, N4 | Balanced price/performance, web servers, dev/test |
| Compute Optimized | C2, C3 | High-performance computing, gaming, ad serving |
| Memory Optimized | M1, M2, M3 | In-memory DBs (SAP HANA), large caches |
| Accelerator Optimized | A2, G2 | ML training/inference, graphics workloads (GPUs) |
| Shared-core | E2-small, E2-micro, F1-micro | Low-traffic, cost-sensitive workloads |

**Why this matters:** picking the right family is a cost/performance decision, not just a technical one. E2 gives the cheapest general-purpose vCPU-hour (good default for web/app servers and dev/test). N2/N2D give guaranteed performance with no CPU sharing tricks. C2/C3 remove hyper-threading contention for latency-sensitive, single-threaded-heavy workloads. M-series exists almost entirely for licensed in-memory databases that require huge RAM-to-vCPU ratios. Interviewers often ask you to justify a family choice for a given workload — always tie it back to the workload's CPU/RAM ratio and whether it's latency- or throughput-bound.

### Console Steps — Change Machine Type
1. Go to **Compute Engine → VM instances**.
2. Click the VM name to open its details page.
3. Click **Stop** (machine type can only be changed while the VM is stopped).
4. Once stopped, click **Edit**.
5. Under **Machine configuration**, choose a new **Series** and **Machine type** (or select **Custom** to set exact vCPU/memory).
6. Click **Save**, then **Start** the VM again.

```bash
# List all machine types available in a zone
gcloud compute machine-types list --zones=us-central1-a

# Describe a specific machine type
gcloud compute machine-types describe e2-medium --zone=us-central1-a

# Change machine type of a stopped VM
gcloud compute instances stop my-vm --zone=us-central1-a
gcloud compute instances set-machine-type my-vm \
  --zone=us-central1-a --machine-type=n2-standard-4
gcloud compute instances start my-vm --zone=us-central1-a
```

### Custom Machine Types
Lets you define exact vCPU and memory instead of a fixed preset (useful for right-sizing cost).
```bash
gcloud compute instances create custom-vm \
  --zone=us-central1-a \
  --custom-cpu=4 \
  --custom-memory=8GB \
  --image-family=debian-12 --image-project=debian-cloud
```

---

## 4. CPU & Memory

- **vCPU**: A virtual CPU maps to a hardware hyper-thread (SMT) on the host CPU, not a full physical core.
- **Hyper-Threading (SMT)**: Most machine types use simultaneous multi-threading — 2 vCPUs per physical core. You can disable this via `--threads-per-core=1` for workloads sensitive to shared execution units.
- **CPU Platform**: The specific Intel/AMD processor generation backing your VM (e.g., Intel Ice Lake, AMD Milan). You can pin a minimum platform for consistent performance.
- **NUMA**: Non-Uniform Memory Access — relevant for large machine types (>16 vCPUs) where memory locality affects performance.
- **CPU Overcommit**: On shared-core machine types (E2-small, E2-micro, F1-micro), the vCPU is not a dedicated, always-available resource — Google oversubscribes the physical core across multiple tenants/VMs, similar to how a hypervisor oversubscribes RAM. This is *not* true of standard predefined machine types (e2-medium and above, N2, C2, etc.), where each vCPU maps to a dedicated hyper-thread with no oversubscription — overcommit is specifically a shared-core-tier behavior, in exchange for a much lower price.

**Why this matters:** SMT means two vCPUs can share the execution pipeline of one physical core, so a "4 vCPU" VM isn't always 4 dedicated cores of throughput — for CPU-bound, latency-sensitive workloads (e.g., real-time trading, some HPC jobs), disabling SMT (`--threads-per-core=1`) gives more predictable per-vCPU performance at the cost of paying for cores you're not fully using. Pinning `--min-cpu-platform` matters for benchmark-consistency or when an application needs a specific instruction set (e.g., AVX-512) that's only present on newer platforms. **On CPU overcommit specifically:** this is why shared-core machine types are recommended only for low-traffic, bursty, or dev/test workloads — under sustained heavy load, a shared-core VM can experience CPU throttling because it's competing with other tenants for the same physical core, which is a very different failure mode than simply "undersized" on a standard machine type. If an interviewer asks why a shared-core VM is showing inconsistent performance under load, overcommit contention is the answer they're listening for.

### Console Steps — Set Minimum CPU Platform / Disable SMT
1. **Compute Engine → VM instances → Create Instance**.
2. Under **Machine configuration**, click **CPU platform and GPU** (or expand advanced machine config).
3. Choose a **Minimum CPU platform** from the dropdown (e.g., Intel Ice Lake).
4. To control threads-per-core, expand **Management, security, disks, networking, sole tenancy → Management** and set **Visible core count** / thread settings (available on supported machine types).
5. Click **Create**.

```bash
# Set a minimum CPU platform
gcloud compute instances create my-vm \
  --min-cpu-platform="Intel Ice Lake" \
  --zone=us-central1-a --machine-type=n2-standard-4

# Disable simultaneous multithreading (visible CPU cores = physical cores)
gcloud compute instances create my-vm \
  --threads-per-core=1 \
  --zone=us-central1-a --machine-type=n2-standard-4

# Check CPU platform of a running VM
gcloud compute instances describe my-vm --zone=us-central1-a \
  --format="value(cpuPlatform)"
```

---

## 5. Boot Disks

| Disk Type | Description | Use Case |
|---|---|---|
| Standard PD (`pd-standard`) | HDD-backed | Cold storage, sequential I/O |
| Balanced PD (`pd-balanced`) | SSD-backed, balanced cost/performance | Most general-purpose workloads (default) |
| SSD PD (`pd-ssd`) | High-performance SSD | Databases, high IOPS needs |
| Hyperdisk | Next-gen configurable performance (IOPS/throughput independent of size) | High-scale, latency-sensitive workloads |
| Local SSD | Physically attached NVMe SSD | Ephemeral, extremely high IOPS, no durability guarantee |

**Why this matters:** the boot disk type is the single most common cost/performance lever people forget to tune. `pd-balanced` is the modern default and fine for most workloads. Use `pd-ssd` when you need consistent low-latency random I/O (databases). Use `pd-standard` only for rarely-accessed or archival boot volumes since it's HDD-backed and slow for random I/O. Local SSD is **not durable** — data is lost on stop/terminate/host failure — so it should never hold anything you can't afford to lose or regenerate, and is typically paired with a persistent disk for the OS.

### Console Steps — Configure/Resize a Boot Disk
1. **Create a VM with a custom boot disk**: Compute Engine → VM instances → **Create Instance** → under **Boot disk** click **Change** → pick the **Operating system**, **Version**, **Boot disk type**, and **Size**, then click **Select**.
2. **Resize an existing boot disk**: Compute Engine → VM instances → click the VM → under **Storage**, click the boot disk name → click **Edit** → increase **Size** → **Save**. (You still need to extend the filesystem inside the OS.)
3. **Encrypt with CMEK**: during disk creation/edit, expand **Encryption** → choose **Customer-managed key** → select the key from Cloud KMS.

```bash
# Create VM with a specific boot disk type & size
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --boot-disk-type=pd-ssd \
  --boot-disk-size=50GB \
  --image-family=debian-12 --image-project=debian-cloud

# Resize a boot disk (increase only — cannot shrink)
gcloud compute disks resize my-vm \
  --zone=us-central1-a --size=100GB
# NOTE: after resizing, you must extend the filesystem inside the OS (e.g., growpart + resize2fs / xfs_growfs)

# Encrypt boot disk with Customer-Managed Encryption Key (CMEK)
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --boot-disk-kms-key=projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY

# Replace/swap a boot disk on an existing VM
gcloud compute instances stop my-vm --zone=us-central1-a
gcloud compute instances detach-disk my-vm --zone=us-central1-a --disk=old-boot-disk
gcloud compute instances attach-disk my-vm --zone=us-central1-a \
  --disk=new-boot-disk --boot
gcloud compute instances start my-vm --zone=us-central1-a
```


---

## 6. Storage / Persistent Disks

Persistent Disks (PD) are network-attached, durable block storage — independent of VM lifecycle by default. Because they're network-attached (not physically inside the host), they survive VM stop/delete (unless explicitly deleted with the instance) and can be detached from one VM and attached to another, which is what makes disk snapshots and recovery workflows possible. Performance (IOPS/throughput) scales with disk size for standard PD types, which is why undersized disks are a common hidden performance bottleneck — this is one reason Hyperdisk exists (decouples performance from capacity).

**Regional persistent disks** synchronously replicate data across two zones in a region, so if one zone fails you can force-attach the disk to a VM in the surviving zone — this is the main building block for HA stateful workloads that can't use application-level replication.

### Console Steps — Create, Attach, and Resize a Disk
1. **Create a disk**: Compute Engine → **Disks** → **Create Disk** → set **Name**, **Region/Zone**, **Disk type**, **Size** → **Create**.
2. **Attach to a running VM**: Compute Engine → VM instances → click the VM → **Edit** → under **Additional disks**, click **Add new disk** or **Attach existing disk** → select the disk → **Save**.
3. **Detach a disk**: VM details page → **Edit** → find the disk under **Additional disks** → click the trash/detach icon next to it (this detaches, it does not delete, unless you also check "delete disk") → **Save**.
4. **Resize a disk**: Compute Engine → **Disks** → click the disk name → **Edit** → increase **Size** → **Save**, then extend the filesystem inside the OS.
5. **Create a regional (HA) disk**: Compute Engine → **Disks** → **Create Disk** → set **Location** to **Regional** → pick two zones for replicas → **Create**.

```bash
# Create a standalone persistent disk
gcloud compute disks create my-data-disk \
  --zone=us-central1-a --size=100GB --type=pd-balanced

# Attach disk to a running VM
gcloud compute instances attach-disk my-vm \
  --zone=us-central1-a --disk=my-data-disk

# Detach disk
gcloud compute instances detach-disk my-vm \
  --zone=us-central1-a --disk=my-data-disk

# Resize an existing disk (increase only)
gcloud compute disks resize my-data-disk \
  --zone=us-central1-a --size=200GB

# List disks
gcloud compute disks list

# Create a REGIONAL persistent disk (replicated across 2 zones for HA)
gcloud compute disks create my-regional-disk \
  --region=us-central1 \
  --replica-zones=us-central1-a,us-central1-b \
  --type=pd-balanced --size=100GB
```

### Multi-writer Disks
Allow simultaneous read/write from up to 2 VMs (used for clustered file systems).
```bash
gcloud compute disks create shared-disk \
  --zone=us-central1-a --size=100GB \
  --type=pd-ssd --multi-writer
```

### Inside the VM — mounting a new disk (Linux)
```bash
# Identify the disk device
lsblk

# Format (only for a brand-new disk!)
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb

# Mount
sudo mkdir -p /mnt/disks/data
sudo mount -o discard,defaults /dev/sdb /mnt/disks/data

# Persist across reboot via /etc/fstab
echo UUID=$(sudo blkid -s UUID -o value /dev/sdb) /mnt/disks/data ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
```

---

## 7. Images

- **Public Images**: Provided by Google/OS vendors (Debian, Ubuntu, CentOS, Windows Server, etc.), organized into **image families** so you always get the latest patch version.
- **Custom Images**: Created from an existing boot disk, snapshot, or another image — used as a "golden image" template for consistent VM provisioning.

**Why this matters:** golden images are the backbone of consistent, repeatable, and fast VM provisioning at scale — instead of running a startup script that installs software on every boot (slow, and fails if a package repo is down), you bake the software into the image once and every new VM boots ready-to-serve in seconds. This is the standard pattern feeding Instance Templates and MIGs in production.

### Console Steps — Create a Custom Image
1. **From a disk**: Compute Engine → **Images** → **Create Image** → set **Name**, **Source** = *Disk*, choose the source disk and zone → optionally set an **Image family** → **Create**.
2. **From a snapshot**: same as above but set **Source** = *Snapshot* and pick the snapshot.
3. **Create a VM from a custom image**: VM instances → **Create Instance** → under **Boot disk → Change**, select the **Custom images** tab → choose your image → **Select** → **Create**.
4. **Import an on-prem image**: Compute Engine → **Images** → **Import** wizard, or use the `gcloud compute images import` command shown below (the Console wizard walks you through selecting the Cloud Storage source file and target OS).

```bash
# List public image families
gcloud compute images list --filter="family:debian" --project=debian-cloud

# Create a custom image from a disk
gcloud compute images create my-golden-image \
  --source-disk=my-vm --source-disk-zone=us-central1-a \
  --family=my-app-family

# Create a custom image from a snapshot
gcloud compute images create my-image-from-snap \
  --source-snapshot=my-snapshot

# Create VM from a custom image
gcloud compute instances create new-vm \
  --zone=us-central1-a --image=my-golden-image

# Import an on-prem/VMware image (requires the image import tool)
gcloud compute images import my-imported-image \
  --source-file=gs://my-bucket/my-vm-disk.vmdk \
  --os=ubuntu-2204

# Export an image to Cloud Storage
gcloud compute images export \
  --image=my-golden-image \
  --destination-uri=gs://my-bucket/exported-image.tar.gz

# List custom images in the project
gcloud compute images list --no-standard-images
```

**Machine Images vs Custom Images (recap):** Machine images capture the whole VM (all disks + config); custom images capture just a boot disk.

---

## 8. Snapshots

Snapshots are **incremental**, block-level backups of persistent disks stored in Cloud Storage (regional or multi-regional). "Incremental" means after the first full snapshot, every subsequent snapshot only stores the blocks that changed — Google handles the chained dependency internally, so you can safely delete an old snapshot in the middle of a chain without breaking newer ones (Google merges the data behind the scenes). This is why snapshots are far cheaper to run frequently than full disk copies.

**Why this matters:** snapshots are the primary building block for both backup/recovery *and* for cloning environments (e.g., spinning up a copy of production for a load test). A snapshot schedule (Section 8 commands) is how you turn this into a hands-off, policy-driven backup strategy instead of relying on someone remembering to run a command.

### Console Steps — Create, Restore, and Schedule Snapshots
1. **Create a snapshot**: Compute Engine → **Snapshots** → **Create Snapshot** → set **Name**, **Source disk**, **Location** (regional/multi-regional) → **Create**.
2. **Restore a disk from a snapshot**: Compute Engine → **Disks** → **Create Disk** → under **Source type** choose **Snapshot** → select the snapshot → **Create**. Then attach this disk to a VM (as boot or additional disk).
3. **Create a snapshot schedule**: Compute Engine → **Snapshots** → tab **Snapshot Schedules** → **Create Snapshot Schedule** → set frequency (hourly/daily/weekly), start time, retention days → **Create** → then attach it to a disk from the disk's **Edit** page under **Snapshot schedule**.
4. **Delete a snapshot**: Compute Engine → **Snapshots** → select checkbox → **Delete**.

```bash
# Create a snapshot of a disk
gcloud compute disks snapshot my-data-disk \
  --zone=us-central1-a --snapshot-names=my-snapshot-2026-07-08

# Create a snapshot with storage location control (for cross-region DR)
gcloud compute disks snapshot my-data-disk \
  --zone=us-central1-a \
  --snapshot-names=my-cross-region-snap \
  --storage-location=us

# List snapshots
gcloud compute snapshots list

# Restore a disk from a snapshot
gcloud compute disks create restored-disk \
  --zone=us-central1-a --source-snapshot=my-snapshot-2026-07-08

# Delete a snapshot
gcloud compute snapshots delete my-snapshot-2026-07-08

# Create a snapshot schedule (automated recurring snapshots)
gcloud compute resource-policies create snapshot-schedule daily-backup-policy \
  --region=us-central1 \
  --max-retention-days=14 \
  --daily-schedule --start-time=03:00

# Attach the schedule to a disk
gcloud compute disks add-resource-policies my-data-disk \
  --zone=us-central1-a \
  --resource-policies=daily-backup-policy
```

**Snapshot Encryption**: Snapshots inherit CMEK/CSEK encryption from the source disk unless you specify a different key at creation time via `--csek-key-file` or `--kms-key`.


---

## 9. Networking

A **VPC (Virtual Private Cloud)** is a global, software-defined network for your project. Unlike traditional networks, a GCP VPC's subnets can span regions individually (each subnet is regional, but the VPC itself is global) — there's no need to peer networks across regions the way you would on-prem. **Auto mode** VPCs create one subnet per region automatically with predefined ranges; **Custom mode** (recommended for production) requires you to explicitly define subnet ranges, giving full control over IP planning and avoiding overlaps when peering/VPNs are involved.

### Console Steps — Create a VPC and Subnet
1. **Compute Engine** side note: networking lives under **VPC network** in the Console, not under Compute Engine.
2. Go to **VPC network → VPC networks** → **Create VPC network**.
3. Set **Name**, choose **Subnet creation mode** = *Custom*.
4. Under **New subnet**, set **Name**, **Region**, **IP address range** (CIDR), then click **Done**.
5. Repeat "Add subnet" for additional regions if needed.
6. Click **Create**.

### VPC & Subnets
```bash
# Create a custom-mode VPC
gcloud compute networks create my-vpc --subnet-mode=custom

# Create a subnet in a region
gcloud compute networks subnets create my-subnet \
  --network=my-vpc --region=us-central1 --range=10.0.0.0/24

# List networks / subnets
gcloud compute networks list
gcloud compute networks subnets list
```

### IP Addressing
```bash
# Reserve a static external IP
gcloud compute addresses create my-static-ip --region=us-central1

# Reserve a static internal IP
gcloud compute addresses create my-internal-ip \
  --region=us-central1 --subnet=my-subnet --addresses=10.0.0.10

# Assign a static IP at VM creation
gcloud compute instances create my-vm \
  --zone=us-central1-a --address=my-static-ip

# List reserved addresses
gcloud compute addresses list
```
- **Ephemeral IP**: Default; changes if the VM is stopped/started (unless promoted to static).
- **Alias IP Ranges**: Assign additional IP ranges to a VM's network interface (useful for containers/pods needing individual IPs).

### Console Steps — Reserve and Assign a Static IP
1. **VPC network → IP addresses** → **Reserve External Static Address** (or **Internal** tab for an internal IP).
2. Set **Name**, **Network Service Tier**, **Region**, and (for internal) the **Subnet**.
3. Click **Reserve**.
4. To attach it to a VM: **Compute Engine → VM instances → Create Instance** (or **Edit** an existing stopped VM) → **Networking** section → **Network interfaces** → edit the interface → under **External IPv4 address**, select your reserved static IP from the dropdown → **Save**.

```bash
# Add an alias IP range to a VM's network interface
gcloud compute instances network-interfaces update my-vm \
  --zone=us-central1-a \
  --aliases="10.0.1.0/24"
```

### Firewall Rules
Firewall rules in GCP are **stateful** and applied at the VPC level (not per-VM), targeted using network tags or service accounts. "Stateful" means once an outbound (or a matched inbound) connection is allowed, return traffic for that same connection is automatically permitted — you don't need a matching rule in the opposite direction like you would with a stateless ACL. Every VPC has two **implied rules** by default: allow all egress, deny all ingress — everything else is rules you add. Rules are evaluated by **priority** (lower number = higher priority), and the most specific/highest-priority matching rule wins.

**Why this matters:** using network tags (or better, service accounts) to target rules instead of IP-based rules means your firewall policy travels with the *role* of the VM, not its address — so scaling a MIG up/down or re-IPing a VM doesn't require touching firewall rules.

### Console Steps — Create a Firewall Rule
1. **VPC network → Firewall** → **Create Firewall Rule**.
2. Set **Name**, **Network**, **Priority** (lower = evaluated first).
3. Set **Direction of traffic** (Ingress/Egress) and **Action on match** (Allow/Deny).
4. Under **Targets**, choose **Specified target tags** (enter your tag, e.g., `http-server`) or **Specified service accounts**.
5. Under **Source filter**, choose **IP ranges** and enter the CIDR (e.g., `0.0.0.0/0` for anywhere, or a specific range).
6. Under **Protocols and ports**, select **Specified protocols and ports**, check **tcp**, enter the port (e.g., `80`).
7. Click **Create**.

```bash
# Allow inbound SSH from a specific IP range
gcloud compute firewall-rules create allow-ssh \
  --network=my-vpc --direction=INGRESS \
  --action=ALLOW --rules=tcp:22 \
  --source-ranges=203.0.113.0/24

# Allow HTTP traffic to tagged instances
gcloud compute firewall-rules create allow-http \
  --network=my-vpc --direction=INGRESS \
  --action=ALLOW --rules=tcp:80 \
  --target-tags=http-server --source-ranges=0.0.0.0/0

# List firewall rules
gcloud compute firewall-rules list

# Delete a firewall rule
gcloud compute firewall-rules delete allow-ssh
```

### Routes & DNS
```bash
# List routes
gcloud compute routes list

# Create a custom route (e.g., route through an NVA)
gcloud compute routes create custom-route \
  --network=my-vpc --destination-range=0.0.0.0/0 \
  --next-hop-instance=nat-gateway --next-hop-instance-zone=us-central1-a

# Cloud DNS - create a managed zone
gcloud dns managed-zones create my-zone \
  --dns-name="example.com." --description="My zone"

# Add a DNS record
gcloud dns record-sets create www.example.com. \
  --zone=my-zone --type=A --ttl=300 --rrdatas=203.0.113.5
```

---

## 10. SSH Access

Every VM has a **metadata server** that stores authorized SSH public keys. When you connect via `gcloud compute ssh` or Browser SSH, Google generates a short-lived key pair on the fly, pushes the public key into instance metadata, and the guest agent on the VM (pre-installed on public images) adds it to `~/.ssh/authorized_keys` — this is why basic SSH works with zero manual key setup. OS Login replaces this metadata-key flow with IAM-based identity, which is the recommended approach for teams since access is centrally granted/revoked via IAM roles instead of scattered public keys.

### Console Steps — Browser SSH
1. Go to **Compute Engine → VM instances**.
2. Find your VM (must be **Running** and reachable — external IP, or IAP if configured).
3. Click the **SSH** dropdown in that row → **Open in browser window**.
4. The Console auto-generates ephemeral keys, injects them into metadata, and opens an in-browser terminal.
5. If it fails, check: firewall allows tcp:22, VM is running, and check **Serial console output** for guest-agent/boot issues.

### Console Steps — Enable OS Login
1. **Compute Engine → Metadata** (project-level) → **Edit** → **Add item** → key `enable-oslogin`, value `TRUE` → **Save**.
2. Grant users access: **IAM & Admin → IAM** → **Grant Access** → enter the user's email → assign role **Compute OS Login** (or **Compute OS Admin Login** for sudo access) → **Save**.

### gcloud SSH (uses OS Login or metadata SSH keys automatically)
```bash
gcloud compute ssh my-vm --zone=us-central1-a

# SSH through Identity-Aware Proxy (IAP) tunnel (no external IP / bastion needed)
gcloud compute ssh my-vm --zone=us-central1-a --tunnel-through-iap
```

### SSH Keys (project/instance metadata based)
```bash
# Generate a key pair locally
ssh-keygen -t rsa -f ~/.ssh/gce-key -C "myuser"

# Add SSH key to project metadata (applies to all VMs)
gcloud compute project-info add-metadata \
  --metadata-from-file=ssh-keys=~/.ssh/gce-key.pub

# Add SSH key to a specific instance only
gcloud compute instances add-metadata my-vm --zone=us-central1-a \
  --metadata-from-file=ssh-keys=~/.ssh/gce-key.pub
```

### OS Login (recommended — ties SSH access to IAM identity)
```bash
# Enable OS Login at project level
gcloud compute project-info add-metadata --metadata=enable-oslogin=TRUE

# Grant a user SSH access via IAM (no manual key management)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:jane@example.com" \
  --role="roles/compute.osLogin"
```

### IAP Tunnel (secure access without external IP)
```bash
# Requires firewall rule allowing IAP's range (35.235.240.0/20) on tcp:22
gcloud compute firewall-rules create allow-iap-ssh \
  --network=my-vpc --direction=INGRESS --action=ALLOW \
  --rules=tcp:22 --source-ranges=35.235.240.0/20

gcloud compute start-iap-tunnel my-vm 22 \
  --local-host-port=localhost:2222 --zone=us-central1-a
```

### Serial Console (for debugging boot failures / lost SSH access)
```bash
# Enable serial port access
gcloud compute instances add-metadata my-vm --zone=us-central1-a \
  --metadata=serial-port-enable=TRUE

# Connect to serial console
gcloud compute connect-to-serial-port my-vm --zone=us-central1-a
```

### Bastion Host Pattern
A hardened VM with an external IP that acts as the sole entry point into a private VPC; internal VMs have no external IPs and are reached by SSH-hopping through the bastion (IAP tunneling is now generally preferred over a bastion).


---

## 11. IAM & Service Accounts

- **Service Account**: A special identity that a VM uses to call other GCP APIs — NOT a user login.
- **IAM Roles**: A role is simply a named bundle of permissions (e.g., `roles/compute.instanceAdmin.v1` bundles dozens of individual `compute.instances.*` permissions). GCP has three role types: **Basic roles** (Owner/Editor/Viewer — broad, legacy, generally discouraged in production), **Predefined roles** (Google-curated, service-specific, e.g., `roles/compute.osLogin`), and **Custom roles** (you hand-pick the exact permission list).
- **Custom Roles**: Used when even the narrowest predefined role still grants more than a workload needs — you compose your own role from individual permissions. This is the purest expression of least privilege, but comes with maintenance overhead: custom roles don't automatically pick up new permissions when Google adds features to a service, so they need periodic review.
- **OAuth Scopes**: Legacy VM-level access control layered on top of IAM roles (both must permit an action).
- **Least Privilege**: Grant only the exact roles needed, ideally at the resource level, not project-wide.

**Why this matters — the "double gate" concept:** a VM's ability to call an API is the *intersection* of its OAuth scopes (set on the VM) and its service account's IAM roles (set in IAM). Both must allow the action, or the call fails. The modern best practice is to set scope to `cloud-platform` (the broadest scope) and rely entirely on IAM roles for the real restriction — this avoids the confusing situation where a scope silently blocks something IAM would otherwise allow. This is a very common interview trip-up question.

**Predefined vs. Custom, when to reach for which:** always start with the narrowest predefined role that fits (Google maintains these, so they get security patches/new permissions automatically). Only build a custom role when a real requirement can't be met — e.g., an auditor requires a role that permits *only* reading VM metadata and nothing else, and no predefined role is that narrow. Basic roles (Owner/Editor/Viewer) should be treated as a smell in a production project since they grant access across every service, not just Compute Engine.

### Console Steps — Create a Service Account and Attach It to a VM
1. **IAM & Admin → Service Accounts** → **Create Service Account**.
2. Enter a **Name**, click **Create and Continue**.
3. Under **Grant this service account access to project**, select a role (e.g., **Storage Object Viewer**) → **Continue** → **Done**.
4. Attach it to a VM: **Compute Engine → VM instances → Create Instance** (or **Edit** a stopped VM) → expand **Identity and API access** → choose the service account from the **Service account** dropdown → set **Access scopes** to **Allow full access to all Cloud APIs** (recommended, paired with least-privilege IAM roles) → **Create/Save**.
5. To grant a user a role directly: **IAM & Admin → IAM** → **Grant Access** → enter principal email → select role → **Save**.

### Console Steps — Create a Custom Role
1. **IAM & Admin → Roles** → **Create Role**.
2. Set **Title**, **Description**, **ID**, and **Role launch stage** (e.g., General Availability).
3. Click **Add Permissions** → search and check individual permissions (e.g., `compute.instances.get`, `compute.instances.list`).
4. Click **Create**.
5. Assign it like any other role: **IAM & Admin → IAM → Grant Access** → select the principal → choose your custom role from the dropdown (it appears under "Custom" roles) → **Save**.

```bash
# Create a service account
gcloud iam service-accounts create my-vm-sa \
  --display-name="My VM Service Account"

# Grant it a role (least privilege example)
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:my-vm-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# Attach service account + scopes to a VM
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --service-account=my-vm-sa@PROJECT_ID.iam.gserviceaccount.com \
  --scopes=cloud-platform

# Change service account on an existing (stopped) VM
gcloud compute instances stop my-vm --zone=us-central1-a
gcloud compute instances set-service-account my-vm \
  --zone=us-central1-a \
  --service-account=my-vm-sa@PROJECT_ID.iam.gserviceaccount.com \
  --scopes=cloud-platform
gcloud compute instances start my-vm --zone=us-central1-a

# Create a custom IAM role
gcloud iam roles create customComputeViewer --project=PROJECT_ID \
  --title="Custom Compute Viewer" \
  --permissions=compute.instances.get,compute.instances.list
```

---

## 12. Metadata & Startup/Shutdown Scripts

*(See Section 2 for full startup/shutdown script commands.)*

**Metadata hierarchy:**
- **Project metadata**: Applies to all VMs in the project (e.g., shared SSH keys).
- **Instance metadata**: Overrides/extends project metadata for a specific VM.

**Why this matters:** the metadata server is the mechanism almost every "automatic" GCE behavior runs on — startup/shutdown scripts, SSH key injection, the guest agent's identity, and application configuration all flow through it. Understanding the project vs. instance hierarchy matters operationally: a value set at the instance level always overrides the same key set at the project level, which is how you can have an org-wide default (e.g., a monitoring agent config) while still letting individual VMs override it for special cases. It's also worth knowing the metadata server is only reachable *from inside* the VM (via the link-local address `169.254.169.254` / `metadata.google.internal`) — it is not exposed externally, which is why it's considered safe to store non-secret bootstrap config there, but not a substitute for Secret Manager when storing actual credentials.

### Console Steps — View and Edit Metadata
1. **Instance-level**: Compute Engine → VM instances → click the VM name → scroll to **Custom metadata** → click **Edit** → **Add item** (key/value) → **Save**.
2. **Project-level**: Compute Engine → **Metadata** (left nav) → **Edit** → **Add item** → **Save**. This applies to every VM in the project unless overridden at the instance level.
3. To set a startup script via Console: VM details page → **Edit** → scroll to **Automation** → **Startup script** text box → paste your script → **Save**.

```bash
# View all metadata on an instance
gcloud compute instances describe my-vm --zone=us-central1-a \
  --format="value(metadata)"

# Set project-wide metadata
gcloud compute project-info add-metadata --metadata=org=acme-corp

# Remove specific metadata keys
gcloud compute instances remove-metadata my-vm \
  --zone=us-central1-a --keys=startup-script
```

**Metadata Server** (inside the VM, no auth needed for basic values):
```bash
curl "http://metadata.google.internal/computeMetadata/v1/instance/" \
  -H "Metadata-Flavor: Google" --silent --show-error -X GET

# Get an identity/access token for the attached service account
curl "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" \
  -H "Metadata-Flavor: Google"
```

---

## 13. Availability & Maintenance

- **Live Migration**: Default behavior — GCP transparently migrates running VMs to another host during infrastructure maintenance with no downtime (not available for VMs with GPUs/Local SSD unless configured, and not for Spot VMs).
- **Automatic Restart**: If `TRUE` (default), VM restarts automatically after a host failure/crash (not after a user-initiated stop).
- **Host Maintenance Policy**: `MIGRATE` (default) or `TERMINATE`.
- **Sole-Tenant Nodes**: Dedicated physical servers for regulatory/licensing needs (e.g., BYOL Windows).

**Why this matters:** these settings define how your VM behaves during events you don't control — Google performing hardware/firmware maintenance on the host. Live migration is what makes GCE's maintenance largely invisible to standard VMs (the VM's memory state is copied to a new host while it keeps running), but some workloads *can't* be migrated — GPU-attached VMs, Local SSD-backed VMs, and Confidential VMs must use `TERMINATE`, meaning the VM is stopped and (if `--restart-on-failure` is set) automatically restarted on a healthy host instead. Knowing which workload types force `TERMINATE` is a common interview detail, because it directly affects your HA design: anything with `TERMINATE` policy needs to sit behind a MIG with auto-healing or an app-level failover, since it will experience a brief outage during host maintenance.

**Sole-Tenant Nodes** exist for a narrower reason than most people assume: it's not about performance isolation, it's mostly about **licensing compliance** (e.g., some Windows Server or Oracle licenses are tied to physical cores/sockets) and **regulatory requirements** that mandate no other customer's workloads share the same physical hardware.

### Console Steps — Configure Maintenance Behavior
1. **Compute Engine → VM instances → Create Instance** (or **Edit** a stopped VM).
2. Scroll to **Availability policies** (under Machine configuration or Advanced options).
3. Set **VM provisioning model** to **Standard**, **Spot**, or leave default.
4. Set **On host maintenance** to **Migrate VM instance** or **Terminate VM instance**.
5. Toggle **Automatic restart** on/off.
6. Click **Create** / **Save**.

### Console Steps — Create a Sole-Tenant Node Group
1. **Compute Engine → Sole-tenant nodes** → **Create node group**.
2. Set **Name**, **Zone**, **Node template** (defines node type, e.g., `n2-node-80-640`), and **Number of nodes**.
3. Click **Create**.
4. When creating a VM, under **Sole tenancy**, select this node group as the target.

```bash
# Set maintenance policy at VM creation
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --maintenance-policy=MIGRATE \
  --restart-on-failure

# Update maintenance behavior on existing VM
gcloud compute instances set-scheduling my-vm \
  --zone=us-central1-a \
  --maintenance-policy=TERMINATE \
  --no-restart-on-failure

# Create a sole-tenant node group
gcloud compute sole-tenancy node-groups create my-node-group \
  --zone=us-central1-a --node-type=n2-node-80-640 \
  --target-size=1

# Create VM on a sole-tenant node
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --node-group=my-node-group
```


---

## 14. Managed Instance Groups (MIG)

A MIG manages a collection of identical VMs created from an **Instance Template**, providing autohealing, autoscaling, and rolling/canary updates. This is the standard production pattern for stateless workloads: you never manually create/patch individual VMs — you update the template and let the MIG roll the change out, and if any VM becomes unhealthy the MIG automatically deletes and recreates it (auto-healing).

**Zonal vs Regional MIG:** a Zonal MIG places all VMs in one zone (simpler, but a single zone outage takes down the whole group). A Regional MIG spreads instances across multiple zones in a region automatically, which is why it's the default recommendation for production/HA workloads.

### Instance Templates
```bash
gcloud compute instance-templates create my-template \
  --machine-type=e2-medium \
  --image-family=debian-12 --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --tags=http-server \
  --metadata-from-file=startup-script=./startup.sh
```

### Console Steps — Create an Instance Template
1. **Compute Engine → Instance templates** → **Create instance template**.
2. Configure it exactly like creating a VM (name, machine type, boot disk, networking, metadata/startup script, service account).
3. Click **Create**. (Templates are immutable — to change config later you create a new template version.)

### Console Steps — Create a MIG
1. **Compute Engine → Instance groups** → **Create instance group**.
2. Choose **New managed instance group (stateless)**.
3. Set **Name**, and under **Instance template**, select the template you created.
4. Choose **Location**: **Single zone** (Zonal MIG) or **Multiple zones** (Regional MIG) and pick the region.
5. Set **Autoscaling**: min/max instances, and the scaling signal (CPU utilization, LB utilization, or a custom Cloud Monitoring metric).
6. Under **Autohealing**, select or create a **Health check**, and set **Initial delay**.
7. Click **Create**.

### Console Steps — Rolling Update
1. **Compute Engine → Instance groups** → click the MIG name.
2. Click **Rolling restart/replace** (or **Update VMs** depending on Console version).
3. Choose the new **Instance template** version.
4. Set the update policy: **Max surge**, **Max unavailable**, and update type (Proactive / Opportunistic).
5. Click **Apply** / **Start Rollout**.

### Create a Zonal MIG
```bash
gcloud compute instance-groups managed create my-mig \
  --base-instance-name=my-vm \
  --template=my-template \
  --size=3 \
  --zone=us-central1-a
```

### Create a Regional MIG (spreads across zones — higher availability)
```bash
gcloud compute instance-groups managed create my-regional-mig \
  --base-instance-name=my-vm \
  --template=my-template \
  --size=6 \
  --region=us-central1
```

### Auto Healing
```bash
# Create a health check
gcloud compute health-checks create http my-health-check \
  --port=80 --request-path=/healthz \
  --check-interval=10s --unhealthy-threshold=3

# Attach auto-healing policy to the MIG
gcloud compute instance-groups managed update my-mig \
  --zone=us-central1-a \
  --health-check=my-health-check \
  --initial-delay=300
```

### Rolling Updates
```bash
gcloud compute instance-groups managed rolling-action start-update my-mig \
  --zone=us-central1-a \
  --version=template=my-new-template \
  --max-surge=2 --max-unavailable=0
```

### Canary Deployment (two template versions in one MIG)
```bash
gcloud compute instance-groups managed rolling-action start-update my-mig \
  --zone=us-central1-a \
  --version=template=my-template,target-size=90% \
  --canary-version=template=my-canary-template,target-size=10%
```

### Blue-Green Deployment
Typically done by creating a **second MIG** with the new template, attaching it to the same backend service/load balancer, shifting traffic gradually (via backend weighting or a new URL map), then deleting the old MIG once verified.

```bash
# Resize / manage
gcloud compute instance-groups managed resize my-mig --zone=us-central1-a --size=5
gcloud compute instance-groups managed list
gcloud compute instance-groups managed describe my-mig --zone=us-central1-a
gcloud compute instance-groups managed delete-instances my-mig \
  --zone=us-central1-a --instances=my-vm-abcd
```

---

## 15. Load Balancing

| Type | Layer | Scope | Use Case |
|---|---|---|---|
| External HTTP(S) LB | L7 | Global | Public web apps |
| Internal HTTP(S) LB | L7 | Regional | Internal microservices |
| External/Internal TCP Proxy | L4 (proxied) | Global/Regional | Non-HTTP TCP traffic |
| SSL Proxy | L4 (proxied) | Global | TLS termination for non-HTTP |
| Network LB (TCP/UDP passthrough) | L4 | Regional | High-performance, pass-through |

**Why this matters — proxy vs pass-through:** "proxied" load balancers (HTTP(S), SSL Proxy, TCP Proxy) terminate the client connection at Google's edge and open a new connection to your backend — this lets them do things like URL-based routing, SSL termination, and health-aware retries, but the backend sees Google's IP, not the client's (unless you read it from headers). "Pass-through" Network LB preserves the original client packet all the way to the VM (backend sees the real client IP) and works at L4 only — no content-based routing. This distinction is a very common interview question: choose proxied for HTTP apps needing routing/SSL offload, choose pass-through Network LB when the backend needs to see the true client IP or for non-HTTP high-throughput protocols.

The GCP load balancer building blocks are always assembled the same way regardless of type: **Health Check → Backend Service (attaches MIG/NEG) → URL Map (routing rules) → Target Proxy → Forwarding Rule (the actual frontend IP:port)**.

### Console Steps — Create an External HTTP(S) Load Balancer
1. **Network Services → Load balancing** → **Create load balancer**.
2. Choose **Application Load Balancer (HTTP/S)** → **Internet-facing** → **Global** (or **Classic**, if required) → **Configure**.
3. Set a **Name** for the load balancer.
4. **Backend configuration**: click **Backend services → Create a backend service** → set protocol (HTTP), attach your **Instance group** (MIG) as the backend, set **Port numbers**, and select/create a **Health check**.
5. **Frontend configuration**: click **Add frontend IP and port** → choose Protocol (HTTP or HTTPS with a certificate), IP version, and the IP address (reserve a new static IP or use ephemeral).
6. **Routing rules**: leave default (route everything to the one backend service) or configure host/path-based rules under **Host and path rules** for multiple backends.
7. Review and click **Create**. It can take a few minutes to fully provision globally.
8. To verify: **Network Services → Load balancing** → click the LB name → check backend health status shows "Healthy".

### Basic External HTTP(S) Load Balancer setup
```bash
# 1. Health check
gcloud compute health-checks create http my-http-health-check --port=80

# 2. Backend service
gcloud compute backend-services create my-backend-service \
  --protocol=HTTP --health-checks=my-http-health-check --global

# 3. Add MIG as backend
gcloud compute backend-services add-backend my-backend-service \
  --instance-group=my-mig --instance-group-zone=us-central1-a --global

# 4. URL map
gcloud compute url-maps create my-url-map --default-service=my-backend-service

# 5. Target HTTP proxy
gcloud compute target-http-proxies create my-http-proxy --url-map=my-url-map

# 6. Global forwarding rule (frontend)
gcloud compute forwarding-rules create my-http-rule \
  --global --target-http-proxy=my-http-proxy --ports=80
```

### Internal Load Balancer (regional, internal clients only)
```bash
gcloud compute backend-services create my-internal-backend \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=HTTP --health-checks=my-http-health-check --region=us-central1
```

### Health Checks
```bash
gcloud compute health-checks list
gcloud compute health-checks describe my-http-health-check
gcloud compute health-checks update http my-http-health-check --check-interval=5s
```


---

## 16. Autoscaling

Autoscaling adjusts the number of VM instances in a MIG based on load signals. The **cool-down period** matters a lot in practice: it tells the autoscaler to ignore a new VM's metrics for that many seconds after it boots, since a freshly-started VM often shows artificially high CPU during initialization (package installs, app warm-up) — without a cool-down, the autoscaler could misread this as "still overloaded" and keep adding more instances than needed.

**Why this matters:** predictive autoscaling is worth knowing for interviews specifically because it solves the "always playing catch-up" problem — reactive (metric-based) autoscaling only reacts *after* load rises, meaning users hit degraded performance during the ramp-up window; predictive mode uses historical CPU patterns to pre-scale ahead of expected load (e.g., known daily traffic spikes).

### Console Steps — Configure Autoscaling on a MIG
1. **Compute Engine → Instance groups** → click the MIG name → **Edit**.
2. Toggle **Autoscaling** to **On**.
3. Set **Minimum number of instances** and **Maximum number of instances**.
4. Under **Autoscaling signals**, click **Add signal** and choose: **CPU utilization**, **Load balancing capacity**, **Monitoring metric** (custom), or **Schedule**. Set the target value (e.g., 60% CPU).
5. Set **Cool down period** (seconds).
6. Click **Save**.

```bash
# CPU-based autoscaling
gcloud compute instance-groups managed set-autoscaling my-mig \
  --zone=us-central1-a \
  --max-num-replicas=10 --min-num-replicas=2 \
  --target-cpu-utilization=0.6 \
  --cool-down-period=90

# Load-balancer serving capacity based
gcloud compute instance-groups managed set-autoscaling my-mig \
  --zone=us-central1-a \
  --max-num-replicas=10 \
  --target-load-balancing-utilization=0.8

# Custom Cloud Monitoring metric based
gcloud compute instance-groups managed set-autoscaling my-mig \
  --zone=us-central1-a \
  --max-num-replicas=10 \
  --update-stackdriver-metric=custom.googleapis.com/queue_depth \
  --stackdriver-metric-single-instance-assignment=10

# Schedule-based autoscaling (e.g., scale up before business hours)
gcloud compute instance-groups managed update my-mig \
  --zone=us-central1-a \
  --update-autoscaling-schedule=morning-scale-up \
  --schedule-min-required-replicas=10 \
  --schedule-cron="0 8 * * MON-FRI" \
  --schedule-time-zone="Asia/Kolkata" \
  --schedule-duration-sec=36000

# Predictive autoscaling (predicts future CPU load)
gcloud compute instance-groups managed set-autoscaling my-mig \
  --zone=us-central1-a \
  --max-num-replicas=10 \
  --target-cpu-utilization=0.6 \
  --mode=ON \
  --predictive-method=OPTIMIZE_AVAILABILITY
```

---

## 17. VM Lifecycle

**Why this matters:** these six states aren't interchangeable ways to "turn a VM off" — each has different billing, state-preservation, and recovery implications, and confusing them is a classic operational mistake. **Stop** and **Suspend** are the two most commonly confused: Stop cleanly shuts down the guest OS and discards RAM, so on next boot it's a normal cold boot — cheaper (no RAM-storage cost) but slower to resume. Suspend serializes RAM to persistent disk and freezes the VM's exact state, so resume is much faster (like waking a laptop from sleep) at the cost of storage for the saved RAM image. **Reset** is a hard power-cycle (like pulling the plug and plugging back in) — it does *not* run the guest OS's clean shutdown path, so it's only appropriate when a VM is unresponsive, not as a routine reboot method.

- **Stop**: VM shuts down, boot disk persists, billing stops for compute (disk still billed).
- **Suspend**: Like "hibernate" — RAM state saved to disk; faster resume than a cold start; still incurs some storage cost.
- **Reset**: Hard reboot without deleting the VM.
- **Delete**: Removes the VM; boot disk is deleted too unless `--keep-disks=boot` was set or "delete boot disk" was unchecked.

### Console Steps — Start, Stop, Suspend, Reset, Delete
1. **Compute Engine → VM instances**.
2. Select the checkbox next to the VM (or open the VM's details page for a single instance).
3. Use the top action bar (or the **⋮** menu on the row): **Start / Resume**, **Stop**, **Suspend**, **Reset**, or **Delete**.
4. For **Delete**, a confirmation dialog appears showing which attached disks will also be deleted — review this carefully, since it's where accidental data loss most often happens (Scenario 3 in Section 29).

### Console Steps — Configure Instance Scheduling (auto start/stop)
1. **Compute Engine → Instance schedules** → **Create schedule**.
2. Set **Name**, **Region**, **Start time** and **Stop time**, **Days of the week**, and **Timezone**.
3. Click **Create**.
4. Attach it to a VM: VM details page → **Edit** → under **Management → Availability policies**, select the schedule under **Instance schedule** → **Save**. (Or attach it during initial VM creation.)

```bash
gcloud compute instances start my-vm --zone=us-central1-a
gcloud compute instances stop my-vm --zone=us-central1-a
gcloud compute instances suspend my-vm --zone=us-central1-a   # preserves memory state to disk
gcloud compute instances resume my-vm --zone=us-central1-a
gcloud compute instances reset my-vm --zone=us-central1-a     # hard reset (like power cycle)
gcloud compute instances delete my-vm --zone=us-central1-a
```

**Instance Scheduling** (auto start/stop on a schedule — cost saving for dev/test):
```bash
gcloud compute resource-policies create instance-schedule my-schedule \
  --region=us-central1 \
  --vm-start-schedule="0 8 * * MON-FRI" \
  --vm-stop-schedule="0 19 * * MON-FRI" \
  --timezone="Asia/Kolkata"

gcloud compute instances add-resource-policies my-vm \
  --zone=us-central1-a --resource-policies=my-schedule
```

- **Stop**: VM shuts down, boot disk persists, billing stops for compute (disk still billed).
- **Suspend**: Like "hibernate" — RAM state saved to disk; faster resume than a cold start; still incurs some storage cost.
- **Reset**: Hard reboot without deleting the VM.
- **Delete**: Removes the VM; boot disk is deleted too unless `--keep-disks=boot` was set or "delete boot disk" was unchecked.

---

## 18. Security

### Shielded VM
Protects against rootkits and bootkits via three features:
- **Secure Boot**: Only verified, signed boot software runs.
- **vTPM (virtual Trusted Platform Module)**: Enables measured boot and key protection.
- **Integrity Monitoring**: Compares boot measurements against a baseline and alerts on unexpected changes.

**Why this matters:** Shielded VM defends against low-level attacks that traditional OS security (patching, antivirus) can't see — a bootkit that compromises the boot chain before the OS even loads is invisible to in-OS security tools. Secure Boot cryptographically verifies each stage of the boot process against known-good signatures; vTPM stores the measurements and secrets; Integrity Monitoring compares the current boot measurements to a baseline and can alert (via Cloud Monitoring) if something changed unexpectedly — e.g., a rootkit modified the kernel. Shielded VM is enabled by default on most public images today.

### Console Steps — Enable Shielded VM Options
1. **Compute Engine → VM instances → Create Instance** (or **Edit** a stopped VM).
2. Expand **Security** (or **Confidential VM service**) section.
3. Under **Shielded VM**, check **Turn on Secure Boot**, **Turn on vTPM**, and **Turn on Integrity Monitoring**.
4. Click **Create** / **Save**.

### Confidential VM
Encrypts data **in use** (in memory) using AMD SEV / Intel TDX, not just at rest and in transit. This closes the last gap in the "encrypt everywhere" story — data at rest (disk encryption) and in transit (TLS) have been standard for years, but data being actively processed in RAM was traditionally exposed to a compromised hypervisor or a malicious co-tenant with physical access; Confidential VM encrypts memory contents using keys generated and held inside the CPU itself, inaccessible even to Google.

### Console Steps — Enable Confidential VM
1. **Compute Engine → VM instances → Create Instance**.
2. Under **Machine configuration**, select a supported series (e.g., N2D, C2D).
3. Expand **Confidential VM service** → toggle **Enable the Confidential Computing service**.
4. Note that **Host maintenance policy** is forced to **Terminate** (Confidential VMs can't live-migrate) — this is shown automatically in the Console.
5. Click **Create**.

```bash
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring

gcloud compute instances create my-confidential-vm \
  --zone=us-central1-a \
  --machine-type=n2d-standard-4 \
  --confidential-compute \
  --maintenance-policy=TERMINATE
```

### Disk Encryption
- **Google-managed encryption (default)**: Automatic, no config needed.
- **CMEK (Customer-Managed Encryption Keys)**: Keys stored/managed in Cloud KMS — lets you control key rotation and revoke access to a disk by disabling the key, useful for compliance (e.g., "crypto-shredding" data by destroying the key).
- **CSEK (Customer-Supplied Encryption Keys)**: You supply and manage the raw key yourself (not stored by Google) — the highest control/highest operational burden option; if you lose the key, the data is permanently unrecoverable.

### Console Steps — Create a CMEK-Encrypted Disk
1. First create a key in **Security → Key Management** → **Create Key Ring** → **Create Key**.
2. **Compute Engine → Disks → Create Disk** (or the boot disk step during VM creation).
3. Expand **Encryption** → select **Customer-managed key** → choose the **Key ring** and **Key** you created.
4. Click **Create**.

```bash
# CMEK example
gcloud compute disks create my-disk --zone=us-central1-a --size=50GB \
  --kms-key=projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY

# CSEK example
gcloud compute disks create my-disk --zone=us-central1-a --size=50GB \
  --csek-key-file=csek-keys.json
```

### VM Manager (OS Patch Management, OS Inventory, OS Config Policies)

**VM Manager** is Google's suite for managing the guest OS at scale across a fleet of VMs, built on the **OS Config agent** (which you may see referred to as `google-osconfig-agent`, installed by default on most public images). It has three main capabilities:

- **OS Patch Management**: Automates applying OS security patches across a fleet on a schedule, instead of manually SSHing into every VM to run `apt upgrade`/`yum update`. You define a **patch job** (one-time) or a **patch deployment** (recurring schedule) targeting VMs by instance name, zone, or label, and VM Manager handles the patch and reports success/failure per VM.
- **OS Inventory Management**: Continuously collects data about what's installed on each VM — OS version, installed packages, available updates — and surfaces it centrally, so you can answer "which VMs are running package X version Y" without manually auditing every instance.
- **OS Config Policies (Vulnerability/Config Management)**: Lets you declare a desired configuration state (specific packages installed/removed, specific package repos configured) and have it enforced/drifted-detected across the fleet, plus surfaces known CVEs affecting installed packages so you can prioritize patching.

**Why this matters:** without VM Manager, patch compliance across a large fleet is either manual (doesn't scale, easy to miss VMs) or baked into custom images that need rebuilding for every patch cycle (slow feedback loop). VM Manager gives you the middle ground — patch running VMs on a schedule without needing a new image build — and gives auditors/security teams a queryable inventory instead of "trust us, we patch things." This is frequently the answer to "how do you ensure VMs stay patched" in a security-focused interview round, and it directly supports vulnerability management since it can tell you which VMs are exposed to a newly disclosed CVE before you even start patching.

### Console Steps — Enable VM Manager and Create a Patch Deployment
1. **Compute Engine → OS Config → VM Manager** (or search "VM Manager" in the top search bar).
2. If not already enabled, click **Enable OS Config API** for the project.
3. Go to the **Patch Deployments** tab → **Create Patch Deployment**.
4. Set **Name**, then under **Instance Details**, choose targeting: **All instances**, or filter by **Zones**, **Instance names**, or **Labels**.
5. Under **Rollout**, choose **Fully automated** or **Zone by zone** (safer — patches one zone, waits, then proceeds, limiting blast radius if a patch causes issues).
6. Set the **Schedule**: one-time or recurring (daily/weekly/monthly) with a time and duration window.
7. Optionally configure **Pre-patch/Post-patch scripts** (e.g., drain traffic before patching, run a health check after).
8. Click **Create**.

### Console Steps — View OS Inventory
1. **Compute Engine → OS Config → VM Manager → Inventory** tab.
2. Browse the list of VMs with collected OS/package data, or use the filter bar to find VMs running a specific package or OS version.

```bash
# Enable the OS Config API for the project
gcloud services enable osconfig.googleapis.com

# Create a one-time patch job targeting VMs by instance name filter
gcloud compute os-config patch-jobs execute \
  --instance-filter-names=my-vm-1,my-vm-2 \
  --description="Emergency security patch"

# Create a recurring patch deployment (weekly, Sunday 2 AM)
gcloud compute os-config patch-deployments create weekly-patch-deployment \
  --instance-filter-all \
  --recurring-weekly=day-of-week=SUNDAY,time-of-day=02:00:00 \
  --description="Weekly OS patching for all VMs"

# List patch jobs and their status
gcloud compute os-config patch-jobs list

# View OS inventory data for a specific VM
gcloud compute instances os-inventory describe my-vm --zone=us-central1-a

# List all VM inventory data in the project, filtered by OS short name
gcloud compute instances os-inventory list-instances \
  --filter="osInfo.osShortName:debian"
```

---

## 19. Monitoring & Logging

**Cloud Monitoring**: Metrics, dashboards, alerting. **Cloud Logging**: Centralized log aggregation. Both require the **Ops Agent** installed on the VM for detailed guest-level (CPU, memory, disk, custom app) metrics — basic hypervisor-level metrics (CPU utilization, network, disk I/O) are collected automatically without any agent, but you can't see memory usage or disk-space-used, for example, without the agent (this trips up a lot of people troubleshooting OOM issues, since the "memory" they can see by default is really just allocated, not actual in-guest usage).

### Console Steps — View Metrics and Create a Dashboard
1. **Monitoring → Dashboards** → select an existing dashboard or **Create Dashboard**.
2. Click **Add Widget** → choose a chart type → in **Select a metric**, search for e.g. `VM Instance > CPU utilization`.
3. Filter by instance/label if needed, then **Apply**.
4. Save the dashboard.

### Console Steps — Create an Alerting Policy
1. **Monitoring → Alerting** → **Create Policy**.
2. Click **Select a metric**, search for the metric (e.g., CPU utilization), **Apply**.
3. Set the **Threshold** (e.g., "above 0.9"), the **Duration** (e.g., 5 minutes retest window).
4. Click **Next** → configure **Notification channels** (email, Slack, PagerDuty) → add a **Documentation** note for on-call context.
5. Name the policy → **Create Policy**.

### Console Steps — View Logs
1. **Logging → Logs Explorer**.
2. In the query builder, set **Resource type** = *VM Instance*, optionally filter by instance name/severity.
3. Click **Run query**.

### Console Steps — Install Ops Agent (during VM creation)
1. **Compute Engine → VM instances → Create Instance**.
2. Under **Observability**, toggle **Install Ops Agent for Monitoring and Logging**.
3. Continue creating the VM as normal — the Ops Agent installs automatically on first boot via a managed startup script.

```bash
# Install Ops Agent on a running Debian/Ubuntu VM
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Or install via startup script at VM creation
gcloud compute instances create my-vm \
  --zone=us-central1-a \
  --metadata=enable-osconfig=TRUE \
  --metadata-from-file=startup-script=install-ops-agent.sh

# View logs for a specific VM
gcloud logging read "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" \
  --limit=50 --format=json

# Create a log-based alert (via Cloud Monitoring alerting policy, example: high CPU)
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High CPU Alert" \
  --condition-display-name="CPU > 90%" \
  --condition-filter='resource.type="gce_instance" AND metric.type="compute.googleapis.com/instance/cpu/utilization"' \
  --condition-threshold-value=0.9 \
  --condition-threshold-duration=300s

# Create an uptime check
gcloud monitoring uptime create my-uptime-check \
  --resource-type=uptime-url --host=example.com --path=/healthz
```

---

## 20. Backup & Disaster Recovery

**Strategy layers:**
1. **Snapshots** — frequent, incremental, disk-level backups (RPO in hours).
2. **Machine Images** — full-VM backups including config (used for faster full recovery).
3. **Cross-region storage** — store snapshots/images in a different region for regional-outage protection.
4. **Documented DR runbook** — RTO/RPO targets, failover procedure, tested regularly.

**Why this matters:** RPO (Recovery Point Objective — how much data you can afford to lose, driven by snapshot frequency) and RTO (Recovery Time Objective — how fast you must be back up, driven by how automated your restore process is) are the two numbers that should drive every backup design decision, and interviewers frequently ask you to map a backup strategy to specific RPO/RTO targets rather than just describing the tools.

### Console Steps — Create a Machine Image (Full VM Backup)
1. **Compute Engine → VM instances** → select the VM's checkbox (or open it) → click **Create Machine Image** (or find it under the VM's **⋮** menu).
2. Set **Name**, choose **Location** (regional, for DR consider a different region than the source).
3. Click **Create**.

### Console Steps — Recover a VM from a Machine Image
1. **Compute Engine → Machine images** → select the image → click **Create Instance**.
2. Adjust **Name**, **Zone/Region** (can be a different region for DR failover), and any config overrides.
3. Click **Create**.

```bash
# Full VM backup via machine image
gcloud compute machine-images create my-vm-backup \
  --source-instance=my-vm --source-instance-zone=us-central1-a

# Recover: create a new VM from the machine image (in same or different region)
gcloud compute instances create recovered-vm \
  --source-machine-image=my-vm-backup --zone=us-east1-b

# Cross-region snapshot for DR
gcloud compute disks snapshot my-disk --zone=us-central1-a \
  --snapshot-names=dr-snapshot --storage-location=us-east1

# Restore VM from snapshot in a DR region
gcloud compute disks create recovered-disk --zone=us-east1-b \
  --source-snapshot=dr-snapshot
gcloud compute instances create recovered-vm --zone=us-east1-b \
  --disk=name=recovered-disk,boot=yes
```

---

## 21. Cost Optimization

**Why this matters:** cost optimization questions in interviews usually test whether you know *which lever fits which workload* — Spot VMs only make sense for fault-tolerant/stateless/batch work that can handle a 30-second-notice preemption; CUDs make sense for a known, stable baseline load (e.g., your minimum production fleet size that never scales down); rightsizing is an ongoing hygiene practice, not a one-time fix, since workloads change over time.

### Console Steps — Create a Spot VM
1. **Compute Engine → VM instances → Create Instance**.
2. Under **Machine configuration**, scroll to **Availability policies** (or **VM provisioning model**).
3. Select **Spot** (instead of Standard).
4. Choose the **On VM termination** action: **Stop** or **Delete**.
5. Click **Create**.

### Console Steps — View Recommendations
1. **Compute Engine → VM instances** — look for the lightbulb/recommendation icons next to VMs, or:
2. Go to **Recommendation Hub** (search "Recommendations" in the top search bar) → filter by **Compute Engine** to see machine-type rightsizing and idle-resource recommendations with estimated savings.
3. Click a recommendation to see details, then **Apply** (for supported recommendation types) or action it manually.

### Console Steps — Purchase a Committed Use Discount
1. **Compute Engine → Committed use discounts** → **Purchase commitment**.
2. Choose commitment type (resource-based or spend-based), **Term** (1 or 3 years), **Region**, and **Resources** (vCPU, memory, or GPU count).
3. Review estimated savings → **Purchase**.

```bash
# Spot VM (up to ~91% cheaper, can be preempted with 30s notice)
gcloud compute instances create spot-vm \
  --zone=us-central1-a --provisioning-model=SPOT \
  --instance-termination-action=STOP

# View rightsizing recommendations
gcloud recommender recommendations list \
  --project=PROJECT_ID --location=us-central1-a \
  --recommender=google.compute.instance.MachineTypeRecommender

# View idle VM recommendations
gcloud recommender recommendations list \
  --project=PROJECT_ID --location=us-central1-a \
  --recommender=google.compute.instance.IdleResourceRecommender

# Purchase a Committed Use Discount (1 or 3 years)
gcloud compute commitments create my-commitment \
  --region=us-central1 --plan=twelve-month \
  --resources=vcpu=8,memory=32
```

- **Sustained Use Discounts**: Automatic, no action needed — applies as a VM runs longer within a billing month (mainly N1 family).
- **Committed Use Discounts**: Manually purchased commitment for guaranteed usage.
- **Preemptible VMs**: Legacy version of Spot VMs — max 24-hour runtime, being phased out in favor of Spot VMs.

---

## 22. GPU & Accelerators

**Why this matters:** GPUs attached via `--accelerator` (on N1 machine types) are separate from GPUs that are *built into* the A2/G2 families — A2/G2 VMs have a fixed GPU-to-vCPU ratio baked into the machine type itself (e.g., `a2-highgpu-1g` always has exactly 1 A100), while N1 + `--accelerator` lets you attach a flexible number of older-generation GPUs to a general-purpose VM. Also note: GPU VMs cannot live-migrate, so `--maintenance-policy=TERMINATE` is mandatory — the VM stops during host maintenance and Google recommends handling this at the application/orchestration layer (e.g., MIG auto-healing).

### Console Steps — Create a GPU VM
1. **Compute Engine → VM instances → Create Instance**.
2. Under **Machine configuration**, choose the **GPUs** tab (or select machine series **A2**/**G2** for pre-integrated GPUs).
3. For N1 + separate GPU: select **N1** series, then under **GPUs** click **Add GPU**, choose **GPU type** (e.g., NVIDIA T4) and **Number of GPUs**.
4. The Console will show a notice that **Host maintenance policy** is automatically set to **Terminate VM instance**.
5. Under **Boot disk**, select a GPU-compatible/Deep Learning VM image if you want drivers pre-installed, or plan to install NVIDIA drivers via startup script after creation.
6. Click **Create**.

```bash
# Create a VM with an attached NVIDIA GPU
gcloud compute instances create gpu-vm \
  --zone=us-central1-a \
  --machine-type=n1-standard-8 \
  --accelerator=type=nvidia-tesla-t4,count=1 \
  --maintenance-policy=TERMINATE \
  --image-family=debian-12 --image-project=debian-cloud

# Install NVIDIA drivers (via startup script, Debian/Ubuntu)
gcloud compute instances add-metadata gpu-vm --zone=us-central1-a \
  --metadata-from-file=startup-script=install-gpu-driver.sh

# List available accelerator types in a zone
gcloud compute accelerator-types list --filter="zone:us-central1-a"

# A2/G2 machine types come with GPUs pre-integrated (no separate --accelerator flag needed)
gcloud compute instances create ml-vm \
  --zone=us-central1-a --machine-type=a2-highgpu-1g \
  --image-family=common-cu121-debian-11 --image-project=deeplearning-platform-release
```
TPUs are managed via a separate service (Cloud TPU / `gcloud compute tpus`), not standard Compute Engine GPU attachment.

**TPU (Tensor Processing Unit)** is Google's custom-built ASIC (application-specific chip), purpose-designed for the matrix-multiplication-heavy math behind neural network training and inference. Where GPUs are general-purpose parallel processors that happen to be very good at ML (and also handle graphics, video, and other workloads), TPUs are built for *only* ML math and typically offer better price/performance for large-scale training jobs on frameworks that support them well (TensorFlow, JAX, and increasingly PyTorch/XLA) — the trade-off is less flexibility than a GPU for non-ML or less-standard workloads. TPUs are provisioned and billed as their own resource type, separate from a Compute Engine VM's machine type, though they're often used alongside a "host" VM that orchestrates the TPU.

```bash
# Example: create a Cloud TPU (separate from a GCE VM's machine type)
gcloud compute tpus tpu-vm create my-tpu \
  --zone=us-central1-a \
  --accelerator-type=v5litepod-8 \
  --version=tpu-vm-tf-2.15.0
```

**Choosing GPU vs. TPU for AI/ML workloads:** GPUs (via N1+`--accelerator` or the A2/G2 families) are the more flexible default — better framework/library compatibility, suitable for both training and inference, and the natural choice if the workload isn't purely TensorFlow/JAX-based. TPUs make sense at larger training scale where the workload is TensorFlow/JAX-native and the cost-per-training-run matters enough to justify the narrower tooling fit. For inference-only workloads with moderate throughput needs, a smaller GPU (e.g., T4) attached to a general-purpose VM is often the most cost-effective and simplest option — this is a common interview question about matching accelerator choice to workload phase (training vs. inference) and scale.


---

## 23. Instance Templates

Immutable blueprints for VM creation — used by MIGs. Templates cannot be edited once created (create a **new version** instead).

**Why this matters:** immutability is a deliberate design choice, not a limitation — if templates *could* be edited in place, a MIG referencing "the template" could silently change its rollout behavior mid-flight, and there'd be no clean way to roll back a bad change. Because each template version is a separate, permanent object, rolling out a change is really "point the MIG at a new template" (Section 14's rolling update), and rolling back a bad deploy is just as simple: point the MIG back at the previous template version. This is also why it's worth adding a version suffix or date to template names (`web-template-v2`, `web-template-2026-07-08`) — you'll often want several historical versions around for exactly this rollback scenario, and old unused ones should be cleaned up periodically since there's no automatic limit.

*(Console steps for creating a template and rolling a MIG onto a new version are covered in Section 14 — "Console Steps — Create an Instance Template" and "Console Steps — Rolling Update," since templates aren't useful in isolation from a MIG.)*

### Console Steps — Create a Template from an Existing VM
1. **Compute Engine → VM instances** → select the VM's checkbox → click **Create Instance Template** (or via the VM's **⋮** menu → **Create machine image** is different — for a *template*, use **Compute Engine → Instance templates → Create instance template → "Import from existing instance"** if available in your Console version).
2. Alternatively use the command below, which is the most reliable path for this specific action.

### Console Steps — Delete an Old Template
1. **Compute Engine → Instance templates**.
2. Select the checkbox next to the old/unused template.
3. Click **Delete**. (The Console will block deletion if a MIG still references it — detach or update the MIG first.)

```bash
# Create a template
gcloud compute instance-templates create web-template-v1 \
  --machine-type=e2-medium \
  --image-family=debian-12 --image-project=debian-cloud \
  --metadata-from-file=startup-script=./startup.sh

# List / describe templates
gcloud compute instance-templates list
gcloud compute instance-templates describe web-template-v1

# "Versioning" = create a new template and roll the MIG onto it
gcloud compute instance-templates create web-template-v2 \
  --machine-type=e2-standard-2 \
  --image-family=debian-12 --image-project=debian-cloud

gcloud compute instance-groups managed rolling-action start-update my-mig \
  --zone=us-central1-a --version=template=web-template-v2

# Create a template from an existing running VM's config
gcloud compute instance-templates create template-from-vm \
  --source-instance=my-vm --source-instance-zone=us-central1-a

# Delete an old template (only after no MIG references it)
gcloud compute instance-templates delete web-template-v1
```

---

## 24. Automation

**Deployment Automation — the umbrella concept:** everything in this section is really answering one question — "how do I make infrastructure changes repeatable and hands-off instead of manual clicking?" The right tool depends on *what kind* of automation you need: **gcloud** for imperative, one-off, or scripted operational tasks; **Terraform** for declarative, version-controlled infrastructure state (the standard for anything you'd call "infrastructure as code"); and **Cloud Scheduler + Cloud Functions** for event-driven or time-driven automation that reacts to a schedule or a trigger (e.g., a Pub/Sub message) rather than being run on-demand by a human or a CI/CD pipeline. A mature environment typically uses all three together: Terraform for the baseline infrastructure definition, gcloud/scripts inside CI/CD for deployment steps, and Scheduler/Functions for ongoing operational automation like scheduled start/stop or auto-remediation.

### gcloud CLI
Scriptable, imperative — ideal for one-off tasks, quick fixes, and CI/CD pipeline steps.

### Terraform
Declarative infrastructure-as-code — ideal for repeatable, version-controlled infrastructure (see Section 28 for resource reference).

### Cloud Scheduler + Cloud Functions (event-driven automation)
Example: Auto-stop dev VMs every night via a scheduled Cloud Function.
```bash
# Deploy a Cloud Function that stops a VM
gcloud functions deploy stopInstance \
  --runtime=nodejs20 --trigger-topic=stop-vm-topic \
  --entry-point=stopInstance

# Create a Cloud Scheduler job to trigger it nightly at 8 PM
gcloud scheduler jobs create pub-sub stop-vm-job \
  --schedule="0 20 * * *" \
  --topic=stop-vm-topic \
  --message-body="{\"zone\":\"us-central1-a\",\"instance\":\"my-vm\"}" \
  --time-zone="Asia/Kolkata"
```

### Instance Scheduling (simpler native alternative — see Section 17)

---

## 25. Troubleshooting

| Issue | Common Causes | Diagnostic Steps |
|---|---|---|
| **VM won't start** | Quota exceeded, invalid image, disk corruption | `gcloud compute operations list`, check quota: `gcloud compute regions describe REGION` |
| **SSH connection issues** | Firewall blocking :22, missing SSH key, OS Login misconfig | Check firewall rules, use Serial Console, verify `enable-oslogin` metadata |
| **Boot failures** | Corrupted boot disk, bad kernel, fsck failure | Attach boot disk to a rescue VM as a secondary disk to inspect/fix |
| **Disk full** | Logs/temp files filled disk | SSH in, run `df -h`, `du -sh /*`, clean up, or resize disk + extend filesystem |
| **High CPU utilization** | App inefficiency, undersized machine type | Cloud Monitoring CPU graphs, `top`/`htop` inside VM, consider vertical scaling |
| **Memory issues (OOM)** | App memory leak, undersized machine type | Check `dmesg | grep -i "out of memory"`, monitor via Ops Agent |
| **Kernel panic** | Driver/kernel incompatibility, corrupted image | View Serial Console output for panic trace |
| **Firewall issues** | Missing/incorrect ingress rule, wrong tags | `gcloud compute firewall-rules list`, verify target-tags match VM tags |
| **Startup script failures** | Script syntax errors, missing permissions | Check Serial Console: `sudo journalctl -u google-startup-scripts.service` |
| **Metadata issues** | Wrong key name, malformed value | `gcloud compute instances describe VM --format="value(metadata)"` |
| **Network connectivity problems** | Route missing, NAT misconfigured, firewall deny | `gcloud compute routes list`, `ping`/`traceroute` inside VM, check Cloud NAT config |

### Key diagnostic commands
```bash
# View serial console output (great for boot failures / kernel panics)
gcloud compute instances get-serial-port-output my-vm --zone=us-central1-a

# Check recent operations/errors on a VM
gcloud compute operations list --filter="targetLink:my-vm"

# Check current quotas
gcloud compute regions describe us-central1 --format="table(quotas)"

# Startup script logs (from inside VM)
sudo journalctl -u google-startup-scripts.service --no-pager

# Check firewall rules applying to a VM
gcloud compute firewall-rules list --filter="targetTags:http-server"
```


---

## 26. Best Practices

- **High Availability**: Deploy across multiple zones using Regional MIGs; use regional persistent disks or replication for stateful data; use global/regional load balancers to route around zone failure.
- **Multi-region architecture**: For DR beyond a single region — cross-region snapshots, multi-region Cloud Storage, global load balancing with backends in multiple regions.
- **Least Privilege IAM**: Scope service account roles narrowly; avoid `roles/owner` or `--scopes=cloud-platform` combined with broad IAM roles unless necessary; prefer per-resource IAM bindings.
- **Labeling strategy**: Consistent `env`, `team`, `cost-center`, `app` labels on every resource for billing attribution and automation filtering.
- **Naming conventions**: e.g., `<app>-<env>-<region>-<role>-<suffix>` (`web-prod-us-central1-frontend-01`).
- **Backup strategy**: Automated snapshot schedules + periodic machine-image backups + tested restore procedure.
- **Monitoring and alerting**: Alerting policies for CPU, memory, disk, uptime checks on customer-facing endpoints; route to Slack/PagerDuty via notification channels.
- **Security hardening**: Shielded VM enabled by default, OS Login instead of static SSH keys, disable serial port access in production, minimal firewall exposure, CMEK where compliance requires it.
- **Cost optimization**: Use Spot VMs for fault-tolerant/batch workloads, rightsizing recommendations reviewed monthly, CUDs for stable baseline load, auto-shutdown schedules for dev/test.

---

## 27. Quick Command Cheat Sheet

```bash
# --- VM Basics ---
gcloud compute instances list
gcloud compute instances create VM_NAME --zone=ZONE --machine-type=TYPE --image-family=FAMILY --image-project=PROJECT
gcloud compute instances delete VM_NAME --zone=ZONE
gcloud compute instances start VM_NAME --zone=ZONE
gcloud compute instances stop VM_NAME --zone=ZONE
gcloud compute instances describe VM_NAME --zone=ZONE

# --- SSH ---
gcloud compute ssh VM_NAME --zone=ZONE
gcloud compute ssh VM_NAME --zone=ZONE --tunnel-through-iap

# --- Disks & Snapshots ---
gcloud compute disks create DISK_NAME --zone=ZONE --size=SIZE
gcloud compute disks snapshot DISK_NAME --zone=ZONE --snapshot-names=SNAP_NAME
gcloud compute instances attach-disk VM_NAME --zone=ZONE --disk=DISK_NAME
gcloud compute instances detach-disk VM_NAME --zone=ZONE --disk=DISK_NAME

# --- Images ---
gcloud compute images create IMAGE_NAME --source-disk=DISK_NAME --source-disk-zone=ZONE
gcloud compute images list

# --- Instance Templates & MIGs ---
gcloud compute instance-templates create TEMPLATE_NAME --machine-type=TYPE --image-family=FAMILY --image-project=PROJECT
gcloud compute instance-groups managed create MIG_NAME --template=TEMPLATE_NAME --size=N --zone=ZONE
gcloud compute instance-groups managed set-autoscaling MIG_NAME --zone=ZONE --max-num-replicas=N --target-cpu-utilization=0.6
gcloud compute instance-groups managed rolling-action start-update MIG_NAME --zone=ZONE --version=template=NEW_TEMPLATE

# --- Load Balancing ---
gcloud compute health-checks create http HC_NAME --port=80
gcloud compute backend-services create BS_NAME --protocol=HTTP --health-checks=HC_NAME --global
gcloud compute url-maps create URLMAP_NAME --default-service=BS_NAME
gcloud compute target-http-proxies create PROXY_NAME --url-map=URLMAP_NAME
gcloud compute forwarding-rules create RULE_NAME --global --target-http-proxy=PROXY_NAME --ports=80

# --- Firewall & Networking ---
gcloud compute firewall-rules create RULE_NAME --network=NETWORK --allow=tcp:PORT --source-ranges=CIDR
gcloud compute networks subnets create SUBNET_NAME --network=NETWORK --region=REGION --range=CIDR

# --- IAM & Service Accounts ---
gcloud iam service-accounts create SA_NAME
gcloud projects add-iam-policy-binding PROJECT_ID --member="serviceAccount:SA_EMAIL" --role="ROLE"

# --- Monitoring ---
gcloud compute instances get-serial-port-output VM_NAME --zone=ZONE
gcloud logging read "resource.type=gce_instance" --limit=50
```


---

## 28. Terraform Resource Reference

| Resource | Purpose |
|---|---|
| `google_compute_instance` | Define a single VM instance |
| `google_compute_disk` | Standalone persistent disk |
| `google_compute_snapshot` | Disk snapshot |
| `google_compute_image` | Custom image |
| `google_compute_machine_image` | Full-VM machine image |
| `google_compute_instance_template` | Reusable VM blueprint for MIGs |
| `google_compute_instance_group_manager` | Zonal MIG |
| `google_compute_region_instance_group_manager` | Regional MIG |
| `google_compute_autoscaler` | Autoscaling policy attached to a zonal MIG |
| `google_compute_region_autoscaler` | Autoscaling policy for a regional MIG |
| `google_compute_firewall` | VPC firewall rule |
| `google_compute_address` | Static external/internal IP |
| `google_compute_route` | Custom VPC route |
| `google_compute_network` | VPC network |
| `google_compute_subnetwork` | VPC subnet |
| `google_compute_health_check` | Health check for MIG/backend service |
| `google_compute_backend_service` | Load balancer backend service |
| `google_compute_url_map` | HTTP(S) LB URL routing |
| `google_compute_target_http_proxy` | LB target proxy |
| `google_compute_global_forwarding_rule` | LB frontend entry point |

### Example: Instance Template + Regional MIG + Autoscaler
```hcl
resource "google_compute_instance_template" "web_template" {
  name_prefix  = "web-template-"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = file("startup.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "web_mig" {
  name               = "web-mig"
  region             = "us-central1"
  base_instance_name = "web"
  target_size        = 3

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web_hc.id
    initial_delay_sec = 300
  }
}

resource "google_compute_health_check" "web_hc" {
  name = "web-health-check"
  http_health_check {
    port = 80
  }
}

resource "google_compute_region_autoscaler" "web_autoscaler" {
  name   = "web-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.web_mig.id

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 2
    cooldown_period = 90
    cpu_utilization {
      target = 0.6
    }
  }
}
```

---

## 29. Real-Time Interview Scenarios

Each scenario below follows the structure an interviewer actually wants to hear: **clarify the problem → explain your reasoning/approach → walk through the solution step-by-step → name the trade-offs and what you'd monitor/verify afterward.** Don't just recite commands — narrate *why* each step exists. That's what separates a senior answer from a junior one.

---

### 1. Migrate an on-premises server to Compute Engine

**Clarify first:** Ask about OS type, downtime tolerance, data volume, and whether it's a one-time lift-and-shift or an ongoing hybrid state. This changes the tool you'd pick.

**Approach:**
- **Small scale / one-off:** Export a disk image (VMDK/VHD/RAW) from the on-prem hypervisor, import it as a GCE custom image, then create a VM from that image.
- **Large scale / minimal downtime:** Use **Migrate to Virtual Machines** (Google's dedicated migration service), which continuously replicates the source VM's disks to GCP while it's still running on-prem, then lets you do a fast, low-downtime cutover.

**Step-by-step (manual path):**
1. Export the source disk to a supported format and upload it to Cloud Storage.
2. `gcloud compute images import my-imported-image --source-file=gs://bucket/disk.vmdk --os=ubuntu-2204`
3. Create a test VM from the image in a non-prod project/VPC first — validate boot, networking, and application health.
4. Plan the cutover: update DNS/load balancer to point at the new VM, keep the on-prem source as rollback for a defined window.
5. Decommission the source only after a soak period with no issues.

**What I'd call out to the interviewer:** the riskiest part isn't the disk import, it's DNS/IP cutover and driver compatibility (on-prem VMs often need GCP guest environment drivers installed before or right after import). I'd also mention testing the migrated VM in isolation before touching production traffic.

---

### 2. Resize a VM with minimal downtime

**Clarify first:** Is this a standalone VM or part of a MIG? Is "minimal downtime" a hard SLA or just "avoid a long outage"?

**Approach — standalone VM (some downtime unavoidable):**
Machine type changes require the VM to be stopped, so true zero-downtime isn't possible for a single VM. Minimize the window:
```bash
gcloud compute instances stop my-vm --zone=us-central1-a
gcloud compute instances set-machine-type my-vm --zone=us-central1-a --machine-type=n2-standard-4
gcloud compute instances start my-vm --zone=us-central1-a
```
This is typically a 1–2 minute outage — acceptable for a maintenance window but not for a live production node with no redundancy.

**Approach — MIG-backed service (effectively zero downtime):**
Instead of resizing an individual VM, create a new instance template with the bigger machine type, then do a rolling update:
```bash
gcloud compute instance-groups managed rolling-action start-update my-mig \
  --zone=us-central1-a --version=template=bigger-template \
  --max-surge=2 --max-unavailable=0
```
`--max-unavailable=0` guarantees capacity never drops during the rollout — new, bigger VMs are added before old ones are removed.

**Key point for the interviewer:** the real answer to "minimal downtime resize" in production is architectural — you shouldn't be resizing standalone VMs at all; you should be running behind a MIG so resizing is just a template rollout.

---

### 3. Recover a VM after accidental deletion

**Clarify first:** Was the boot disk configured with "delete boot disk when instance is deleted" checked? This determines whether the disk survived.

**Approach:**
1. Check if the boot disk still exists: `gcloud compute disks list --filter="name:my-vm"`.
2. **If the disk survived** (auto-delete was off): simply recreate the VM pointing at the existing disk as boot:
   ```bash
   gcloud compute instances create my-vm --zone=us-central1-a \
     --disk=name=my-vm-disk,boot=yes
   ```
3. **If the disk was also deleted**: restore from the most recent snapshot or machine image:
   ```bash
   gcloud compute disks create restored-disk --zone=us-central1-a --source-snapshot=latest-snapshot
   gcloud compute instances create my-vm --zone=us-central1-a --disk=name=restored-disk,boot=yes
   ```
4. If neither exists, this is a full data-loss event — the only recovery is whatever backup existed (this is exactly why snapshot schedules and machine-image backups matter, and I'd bring the conversation back to prevention).

**What this tests:** the interviewer usually wants to hear you connect this back to prevention — deletion protection (`--deletion-protection` flag) and automated snapshot schedules are what avoid this scenario entirely.
```bash
# Enable deletion protection on a critical VM
gcloud compute instances update my-vm --zone=us-central1-a --deletion-protection
```

---

### 4. Restore a VM from a snapshot

**Approach:** A snapshot is disk-level, not VM-level, so restoring means: create a new disk from the snapshot, then create (or repoint) a VM to use that disk as boot.
```bash
# 1. Create a disk from the snapshot
gcloud compute disks create restored-disk \
  --zone=us-central1-a --source-snapshot=my-snapshot-2026-07-08

# 2. Create a VM using that disk as the boot disk
gcloud compute instances create recovered-vm \
  --zone=us-central1-a --disk=name=restored-disk,boot=yes
```
**Nuance to mention:** if you're restoring in place (replacing a corrupted disk on an existing VM), you'd stop the VM, detach the bad disk, attach the restored one as boot, and start it — rather than creating a whole new VM. Also mention that a snapshot is point-in-time and crash-consistent unless the application was quiesced (e.g., a database mid-write) — for transactional systems, app-consistent backups (e.g., a DB dump alongside the snapshot) may be needed for a truly clean restore.

---

### 5. Troubleshoot SSH access failures

**Approach — work outside-in, ruling out layers systematically:**
1. **Network path:** Is there a firewall rule allowing tcp:22 from your source (or from IAP's range `35.235.240.0/20` if using IAP)?
   ```bash
   gcloud compute firewall-rules list --filter="ALLOW:22"
   ```
2. **VM state:** Is the instance actually running? `gcloud compute instances describe my-vm --zone=us-central1-a --format="value(status)"`
3. **Identity/auth path:** Is OS Login enabled and does the user have `roles/compute.osLogin`? Or, if using metadata keys, is the public key actually present in instance/project metadata?
4. **Guest-level issue:** If the network path and auth look fine, the problem may be inside the VM — SSH daemon crashed, disk full preventing login, or a bad boot. Use the **Serial Console** to check without needing SSH at all:
   ```bash
   gcloud compute instances get-serial-port-output my-vm --zone=us-central1-a
   ```
5. **Isolate network vs. guest issue:** Try connecting via IAP tunnel — if that also fails but Serial Console shows a healthy boot, it's almost certainly a firewall/routing issue, not a VM problem.

**What this tests:** systematic, layered troubleshooting rather than guessing. Naming the order (network → auth → guest OS) is what interviewers are listening for.

---

### 6. Reduce Compute Engine costs

**Approach — organize the answer by discount type vs. waste elimination, since these are two different levers:**

**A. Eliminate waste (do this first — it's free savings):**
- Idle VM detection and rightsizing recommendations via **Recommendation Hub**.
- Delete unattached persistent disks and unused reserved static IPs (both are billed even when idle).
- Clean up orphaned/old snapshots beyond your retention policy.

**B. Match pricing model to workload:**
- **Spot VMs** for fault-tolerant, stateless, batch, or CI/CD workloads — up to ~91% cheaper, accept preemption risk.
- **Committed Use Discounts** for your known, stable baseline (e.g., the minimum number of VMs you always run) — don't commit on top of your peak, only your floor.
- **Sustained Use Discounts** are automatic for eligible machine types — no action needed, just awareness that this exists.
- **Scheduled start/stop** for dev/test environments that don't need to run 24/7 (e.g., stop nightly, start weekday mornings).

**What I'd say to close this out:** cost optimization isn't a one-time project — it needs to be a recurring review (monthly rightsizing checks, quarterly CUD renewal review) because workloads and traffic patterns drift over time.

---

### 7. Handle high CPU or memory utilization

**Clarify first:** Is this sudden (an incident) or a gradual trend (capacity planning)? The response is different.

**Approach — sudden spike (incident response):**
1. Confirm with Cloud Monitoring dashboards — is it one VM or fleet-wide?
2. Check if it's traffic-driven (legitimate load) vs. a bug (e.g., infinite loop, memory leak) — check request rate/QPS alongside CPU.
3. If traffic-driven and behind a MIG: let autoscaling absorb it, or manually bump `min-num-replicas` temporarily.
4. If it's a single, standalone VM: vertical scale (bigger machine type) is a stopgap, but flag that a single VM with no redundancy is itself a design gap worth fixing after the fire is out.
5. If it's a leak (memory climbing steadily, not correlated with load): this is an application bug — restarting the VM/process is a temporary mitigation, not a fix; escalate to the app team with the memory graph as evidence.

**Approach — gradual trend (capacity planning):**
Use historical Cloud Monitoring data to right-size the machine type or tune autoscaling targets/thresholds proactively, rather than reacting to alerts.

**What this tests:** whether you reach for "just make the VM bigger" reflexively, versus diagnosing root cause first. Interviewers want to hear you distinguish a scaling problem from a bug.

---

### 8. Scale applications using MIGs and autoscaling

**Approach — build it up in the correct dependency order (this is the order an interviewer expects):**
1. **Instance Template** — the versioned blueprint (machine type, image, startup script, service account).
2. **Health Check** — defines what "healthy" means for auto-healing (e.g., HTTP 200 on `/healthz`).
3. **Managed Instance Group** (prefer **Regional** for HA) — references the template and health check; this gives auto-healing (unhealthy instances auto-recreated) for free.
4. **Backend Service + Load Balancer** — attach the MIG as a backend so traffic is distributed and only routed to healthy instances.
5. **Autoscaling policy** on the MIG — CPU-based is the simplest default; load-balancing-utilization or custom metrics (e.g., queue depth) are better when CPU doesn't correlate well with actual load (common for I/O-bound or queue-consumer workloads).

```bash
gcloud compute instance-groups managed set-autoscaling my-mig \
  --zone=us-central1-a --max-num-replicas=10 --min-num-replicas=2 \
  --target-cpu-utilization=0.6 --cool-down-period=90
```

**Nuance to raise:** min-replicas should never be 0 for a live service (cold-start latency for the first request), and max-replicas should be set with awareness of regional quota limits, or scaling will silently fail at the quota ceiling — a real production incident cause worth mentioning.

---

### 9. Design a highly available Compute Engine deployment across multiple zones

**Approach — answer in layers: compute, data, traffic, and operations:**

**Compute layer:** Regional Managed Instance Group spanning at least 3 zones — losing one zone only removes a third of capacity, and the MIG auto-heals by redistributing new instances to healthy zones.

**Data layer:** Depends on the workload —
- Stateless app tier: no special handling needed, MIG handles it.
- Stateful tier needing block storage: **Regional Persistent Disks** (synchronous replication across 2 zones) for VM-attached storage, or better, offload state to a managed service (Cloud SQL with HA, Spanner, etc.) which handles replication natively and is usually the stronger interview answer for anything beyond a single disk.

**Traffic layer:** **Global External HTTP(S) Load Balancer** in front of the regional MIG — health checks automatically stop routing to unhealthy zones/instances, and (if you extend to multi-region) the global LB can route across regions too for a full regional-outage scenario, not just a zonal one.

**Operations layer:** Monitoring + alerting on both infrastructure metrics and the health-check status itself, plus a documented, periodically-tested failover runbook — HA architecture that's never been tested is not proven HA.

**What I'd flag as a follow-up distinction:** zonal HA (what's described above) protects against a zone outage; true regional/DR-level protection requires multi-region deployment with cross-region data replication and a global load balancer — I'd ask the interviewer which failure domain they actually mean before assuming.

---

### 10. Secure VMs using Shielded VMs, service accounts, and least-privilege access

**Approach — organize by attack surface (boot-time, identity, network, data), since that's how a security review is actually structured:**

**Boot-time integrity:** Enable **Shielded VM** (Secure Boot, vTPM, Integrity Monitoring) — defends against rootkits/bootkits that compromise the OS before it even loads, which endpoint security tools running inside the OS can't see.

**Identity (least privilege):** Attach a purpose-built service account per workload (not the default Compute Engine service account, which is often over-privileged), scoped to only the IAM roles that workload actually needs — e.g., `roles/storage.objectViewer` instead of `roles/storage.admin` if it only reads objects. Set VM access scope to `cloud-platform` and let IAM do the real enforcement, to avoid the scope/IAM "double gate" confusion.

**Human access:** Use **OS Login** tied to IAM instead of static SSH keys scattered in metadata — access is centrally granted/revoked, and it integrates with 2FA/org policy.

**Network exposure:** Firewall rules scoped tightly by tag/service-account, not by broad `0.0.0.0/0` unless truly public-facing (e.g., only allow SSH from a bastion/IAP range, never open to the internet). Prefer **IAP tunneling** over exposing port 22 externally at all.

**Data at rest:** Enable **CMEK** for disks holding sensitive data where compliance requires customer control over key rotation/revocation.

**What I'd close with:** none of these are a single silver bullet — this is defense-in-depth, and I'd mention that in a real environment I'd also enable **Org Policy constraints** (e.g., disabling default service account use, requiring Shielded VM org-wide) so these protections are enforced automatically rather than relying on every engineer remembering to check a box.

---

*End of reference guide.*
