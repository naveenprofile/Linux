# Terraform Master Guide — GCP Edition
### Complete Reference: Fundamentals → Enterprise Operations & Recovery

> This guide reframes a full Terraform curriculum (originally AWS-oriented) entirely around **Google Cloud Platform (GCP)**. Every section includes a detailed explanation plus working, production-grade HCL/Terraform code using GCP resources (Cloud Storage, Compute Engine, GKE, Cloud SQL, Cloud Build, IAM, VPC, Cloud DNS, Cloud Armor, etc.).

---

## Table of Contents
1. [Section 1: Fundamentals](#section-1-fundamentals)
2. [Section 2: Intermediate Topics](#section-2-intermediate-topics)
3. [Section 3: Advanced Patterns](#section-3-advanced-patterns)
4. [Section 4: CI/CD & Testing](#section-4-cicd--testing)
5. [Section 5: Real-World Scenarios](#section-5-real-world-scenarios)
6. [Section 6: Enterprise Operations](#section-6-enterprise-operations)
7. [Section 7: Expert Troubleshooting & Recovery](#section-7-expert-troubleshooting--recovery)

---

# SECTION 1: FUNDAMENTALS

## 1.1 What is Terraform and Why Infrastructure as Code

**Terraform** is a declarative Infrastructure as Code (IaC) tool from HashiCorp. Instead of clicking through the GCP Console to create a VPC, a GKE cluster, or a Cloud SQL instance, you describe the *desired end state* in HCL (HashiCorp Configuration Language), and Terraform figures out the steps to get there.

**Why IaC matters on GCP specifically:**
- **Reproducibility** — spin up identical `dev`, `staging`, `prod` projects from the same code.
- **Auditability** — every infrastructure change goes through a pull request and a `plan` output, satisfying SOC2/ISO27001 audit trails.
- **Drift detection** — Terraform can tell you if someone hand-edited a firewall rule in the Console.
- **Multi-service orchestration** — a single `apply` can create a VPC, subnets, a GKE cluster, IAM bindings, and a Cloud SQL instance in the correct dependency order.
- **GCP-native alternative comparison**: Google offers **Deployment Manager** (deprecated) and **Config Connector** (Kubernetes-native), but Terraform is the de facto standard because it is cloud-agnostic and has the largest community/module ecosystem (`terraform-google-modules`).

```hcl
# providers.tf — the simplest possible GCP Terraform file
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
  }
}

provider "google" {
  project = "my-gcp-project-id"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# main.tf — your first resource: a GCS bucket
resource "google_storage_bucket" "example" {
  name          = "my-gcp-project-id-example-bucket"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
}
```

Run `terraform init`, `terraform plan`, `terraform apply` — Terraform calls the GCP APIs (Cloud Resource Manager, Compute, Storage, etc.) via the `google` provider, which wraps Google's REST APIs.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Terraform's core idea is *declarative convergence* — you describe an end state, and a reconciliation loop (the provider's CRUD calls, orchestrated by Terraform's dependency graph) computes the diff and drives reality toward it. This is fundamentally different from *imperative* automation (a Bash script that runs `gcloud compute instances create` step by step), where the script itself has no idea what already exists.

**Trade-offs:** Declarative IaC is safer and more auditable, but harder to express highly conditional, stateful logic (e.g., "if this VM already exists and has been running > 30 days, do X") — that kind of logic belongs in a wrapper script or a CI job around Terraform, not inside HCL itself.

**Likely interview questions:**
- *"Why choose Terraform over Deployment Manager or Config Connector for a GCP-only shop?"* — Terraform is cloud-agnostic (useful if multi-cloud or hybrid is ever on the roadmap), has a far larger module ecosystem, and isn't tied to being inside a Kubernetes cluster the way Config Connector is.
- *"What's the difference between declarative and imperative IaC?"* — Declarative describes the *what* (desired end state); imperative describes the *how* (ordered steps). Terraform, CloudFormation, and Config Connector are declarative; a Bash/`gcloud` script is imperative.

---

## 1.2 Core Workflow: init → plan → apply → destroy (Detailed)

| Command | What happens under the hood on GCP |
|---|---|
| `terraform init` | Downloads the `hashicorp/google` (and `google-beta`) provider plugin, initializes the backend (e.g., GCS bucket for state), downloads any modules from the Registry or Git. |
| `terraform validate` | Checks HCL syntax and internal consistency (no API calls). |
| `terraform plan` | Calls GCP APIs (read-only) to compare real-world state vs. your `.tf` files and the state file. Produces a diff: `+ create`, `~ update in-place`, `-/+ replace`, `- destroy`. |
| `terraform apply` | Executes the plan, calling GCP write APIs (`compute.instances.insert`, `storage.buckets.insert`, etc.) in dependency order, updating the state file after each resource. |
| `terraform destroy` | Reverse-order deletion of every resource tracked in state. |

```bash
# Typical day-to-day loop
terraform init -upgrade
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan -var-file="envs/prod.tfvars"
terraform apply tfplan
```

**GCP-specific nuance**: many resources require the underlying API to be *enabled* on the project first (e.g., `compute.googleapis.com`, `container.googleapis.com`). Terraform can do this for you:

```hcl
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])
  project            = "my-gcp-project-id"
  service            = each.value
  disable_on_destroy = false
}
```
If you `apply` a `google_compute_instance` before the Compute API is enabled, you'll get a `403 PERMISSION_DENIED — API not enabled` error — always enable APIs first, ideally with `depends_on`.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** `plan` is Terraform's most important safety feature — it is a **read-only, side-effect-free dry run** that builds a full diff before anything is touched. Internally, `plan` walks the resource dependency graph, calls each provider's `Read`/`Plan` RPCs to refresh current state, then computes a diff against your desired config. `apply` walks the same graph but calls `Create`/`Update`/`Delete` RPCs, updating the state file after each individual resource operation (not just at the end) — so a failure partway through `apply` leaves state accurately reflecting what *did* succeed.

**Trade-offs:** Skipping `plan` review (`terraform apply -auto-approve` outside CI) trades safety for speed — acceptable in a sandboxed dev project, dangerous in prod.

**Likely interview questions:**
- *"What happens to the state file if `apply` fails halfway through?"* — Terraform updates state incrementally per-resource, so successfully-created resources are recorded even if a later resource in the same apply fails; re-running `apply` will pick up from there.
- *"Is `terraform plan` guaranteed to be 100% accurate?"* — No — it can be stale if resources changed between `plan` and `apply`, or if a provider's plan-time value depends on something only known at apply time (a `(known after apply)` value).

---

## 1.3 HCL Syntax: Resources, Providers, Variables, Outputs (Extended)

```hcl
# variables.tf
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
  validation {
    condition     = can(regex("^(e2|n2|n2d)-", var.machine_type))
    error_message = "machine_type must be an e2, n2, or n2d family type."
  }
}

variable "labels" {
  type    = map(string)
  default = { environment = "dev", managed-by = "terraform" }
}

# main.tf
resource "google_compute_instance" "web" {
  name         = "web-server"
  machine_type = var.machine_type
  zone         = "${var.region}-a"
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = "default"
    access_config {} # ephemeral public IP
  }
}

# outputs.tf
output "instance_ip" {
  value       = google_compute_instance.web.network_interface[0].access_config[0].nat_ip
  description = "Public IP of the web server"
}

output "instance_self_link" {
  value = google_compute_instance.web.self_link
}
```

Key HCL building blocks:
- **Providers** configure *which* cloud/API to talk to (`google`, `google-beta` for preview features like some GKE Autopilot options).
- **Resources** (`resource "type" "name" {}`) are the things Terraform creates/manages.
- **Data sources** (`data "type" "name" {}`) are read-only lookups (see 1.4).
- **Variables** parameterize configuration; **outputs** expose values for humans or other Terraform configs (via `terraform_remote_state`).
- **Locals** compute derived values without exposing them as inputs:

```hcl
locals {
  name_prefix = "${var.project_id}-${var.region}"
  common_labels = merge(var.labels, {
    cost-center = "platform-eng"
  })
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** HCL is a *configuration language*, not a general-purpose programming language — it has no imperative control flow (no `if`/`for` loops in the traditional sense), only declarative expressions (`for_each`, `for` expressions, conditional/ternary expressions). This constraint is deliberate: it keeps configurations analyzable and diffable, which a Turing-complete language would make much harder.

**Trade-offs:** The declarative constraint means genuinely complex conditional logic (e.g., "provision differently based on the result of an external API call made at runtime") requires an escape hatch — `external` data source, or pre-computing values outside Terraform and feeding them in as variables.

**Likely interview questions:**
- *"What's the difference between a resource and a data source?"* — A `resource` block is something Terraform creates/owns/can destroy; a `data` block is a read-only lookup of something that already exists (managed by Terraform or not).
- *"What are `locals` for, and how do they differ from variables?"* — `locals` are internal, computed values not exposed as configurable inputs; `variables` are external inputs the caller can set.

---

## 1.4 Data Sources & Cross-Stack Lookups (Advanced)

Data sources let you reference existing GCP resources (created manually, by another team, or another Terraform state) without re-declaring them.

```hcl
# Look up an existing VPC network created by the networking team
data "google_compute_network" "shared_vpc" {
  name    = "shared-vpc"
  project = "networking-host-project"
}

data "google_compute_subnetwork" "app_subnet" {
  name    = "app-subnet-us-central1"
  region  = "us-central1"
  project = "networking-host-project"
}

# Look up the default service account created by GCP for the project
data "google_compute_default_service_account" "default" {
  project = var.project_id
}

# Look up the latest Debian image instead of hardcoding it
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "app" {
  name         = "app-vm"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.app_subnet.self_link
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
}
```

**Cross-stack lookups via remote state** (reading outputs from a *different* Terraform state file, e.g., a "networking" stack consumed by an "app" stack):

```hcl
data "terraform_remote_state" "networking" {
  backend = "gcs"
  config = {
    bucket = "my-org-tfstate"
    prefix = "networking/prod"
  }
}

resource "google_compute_instance" "app" {
  # ...
  network_interface {
    subnetwork = data.terraform_remote_state.networking.outputs.app_subnet_self_link
  }
}
```
This pattern is central to enterprise multi-repo Terraform: a platform team owns VPC/IAM stacks, and application teams consume outputs rather than re-declaring shared infrastructure.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Data sources decouple *ownership* from *usage* — a networking team can own the VPC's lifecycle in their own state file, while an application team's Terraform config only ever *reads* it via a `data` block or `terraform_remote_state`. This is the foundation of hierarchical, multi-team Terraform architectures (see 3.3).

**Trade-offs:** Over-relying on data sources for values that change frequently means every `plan` re-fetches them, adding API latency; and if the underlying resource is deleted, your `data` lookup fails at `plan` time with a cryptic "resource not found" error rather than a clear ownership signal.

**Likely interview questions:**
- *"How would you let an app team consume a shared VPC without giving them permission to modify it?"* — Grant them a `Viewer`-level IAM role on the networking project, and have their Terraform reference the VPC via a `data` source or `terraform_remote_state`, never declaring the `google_compute_network` resource themselves.
- *"What happens if a data source's target doesn't exist yet at plan time?"* — `terraform plan` fails immediately with an error, since data sources are resolved eagerly during refresh, not lazily deferred like resource creation order.

---

## 1.5 State File Fundamentals (Deep Dive)

The **state file** (`terraform.tfstate`) is a JSON file mapping your HCL resource addresses (e.g., `google_compute_instance.web`) to real-world GCP resource IDs (e.g., `projects/my-project/zones/us-central1-a/instances/web-server`). It also stores all resource attributes so Terraform doesn't need to re-fetch everything from the API on every `plan`.

**Why it matters:**
- Without state, Terraform cannot know that `google_storage_bucket.logs` already exists — it would try to create it again and fail (bucket names are globally unique) or, worse, create a duplicate resource.
- State stores **sensitive data in plaintext** by default (e.g., a Cloud SQL generated password) — this is why remote, encrypted, access-controlled backends are mandatory in production (see 1.6).

```bash
# Inspecting state
terraform show
terraform state list
terraform state show google_compute_instance.web
terraform state pull > state-backup.json
```

**Common state anti-patterns to avoid:**
- Committing `terraform.tfstate` to Git (leaks secrets, causes merge conflicts).
- One giant state file for an entire org (a single bad `apply` can blast-radius everything — see 3.3 for hierarchical state).
- Manually editing the JSON state file — always use `terraform state mv` / `terraform state rm` / `terraform import` instead.

```bash
# Renaming a resource without destroying/recreating it
terraform state mv google_compute_instance.web google_compute_instance.web_server

# Removing a resource from state (without deleting it in GCP)
terraform state rm google_storage_bucket.legacy
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** State is Terraform's *source of truth about what it manages* — it's a cache of the last-known-good real-world attributes for every resource, indexed by resource address. Without it, Terraform would have to infer identity purely from your config, which is ambiguous (multiple GCS buckets could have the same `name` in your HCL logic but Terraform needs a way to map "this specific declared resource" to "this specific real API object").

**Trade-offs:** State gives speed and identity-tracking but introduces a real operational hazard — it's a single point of failure, and it can leak secrets (a Cloud SQL password shows up in plaintext in state unless explicitly marked and further protected). Encrypting the backend and restricting IAM on it is non-negotiable in production.

**Likely interview questions:**
- *"Why can't Terraform just query GCP directly instead of using a state file?"* — Because GCP's APIs have no concept of "which of these ten identical-looking VMs is the one Terraform block `google_compute_instance.web` refers to" — state is what supplies that mapping, plus it avoids re-fetching every attribute of every resource on every command for performance.
- *"Where do secrets end up if you provision a database password via Terraform?"* — In the state file, in plaintext, by default — mitigated with `sensitive = true` on outputs (hides CLI display, not state content) and encrypting/restricting the state backend itself.

---

## 1.6 Remote Backend Configuration (Expanded)

On AWS this section would use S3 + DynamoDB. On **GCP**, the equivalent, idiomatic backend is a **Google Cloud Storage (GCS) bucket** — GCS natively supports **object versioning** (state history) and Terraform's GCS backend has built-in **state locking** using GCS object generation preconditions (no separate "DynamoDB-equivalent" lock table is needed).

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-org-tfstate-prod"
    prefix = "app/prod"
  }
}
```

Bootstrapping the backend bucket itself (chicken-and-egg problem — usually done with local state once, or in a separate "bootstrap" stack):

```hcl
resource "google_storage_bucket" "tfstate" {
  name                        = "my-org-tfstate-prod"
  location                    = "US"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.tfstate.id
  }
}

resource "google_storage_bucket_iam_binding" "tfstate_admins" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  members = [
    "group:platform-team@example.com",
  ]
}
```

Switching backends:
```bash
terraform init -migrate-state
```

**Locking behavior**: when you run `terraform apply`, the GCS backend writes a lock object; a second concurrent `apply` will fail with `Error acquiring the state lock` until the first completes or the lock is force-released (`terraform force-unlock <LOCK_ID>` — use with extreme caution).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** A remote backend solves two problems at once: **shared access** (a team can't all use a local `terraform.tfstate` file without constant merge conflicts) and **locking** (preventing two simultaneous `apply` runs from corrupting state). GCS achieves locking not via a separate lock table (like AWS's DynamoDB pattern) but via **conditional writes** — Terraform writes a lock object using `ifGenerationMatch`, an atomic compare-and-swap the GCS API supports natively.

**Trade-offs:** GCS-backend locking is simpler to operate (no second service to manage) but is *implicit* — you don't get a queryable "who's holding the lock and for how long" table the way a DynamoDB-based lock could easily expose; you have to inspect the lock object directly.

**Likely interview questions:**
- *"How does GCS backend locking work without a separate lock table like DynamoDB?"* — It uses GCS's native object generation preconditions (atomic compare-and-swap on write) to create/check a lock object in the same bucket, rather than a separate database.
- *"What do you do if a CI job dies mid-apply and leaves a stale lock?"* — Confirm no other run is genuinely active, then run `terraform force-unlock <LOCK_ID>` — never delete the lock object manually via `gsutil`, which can leave Terraform's internal bookkeeping inconsistent.

---

## 1.7 Conditional Logic & Looping (count, for_each, for) (Comprehensive)

```hcl
# count — simplest repetition, index-based
resource "google_compute_instance" "worker" {
  count        = 3
  name         = "worker-${count.index}"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params { image = "debian-cloud/debian-12" }
  }
  network_interface { network = "default" }
}

# for_each with a set — stable identity, safer than count for lists that change
variable "environments" {
  type    = set(string)
  default = ["dev", "staging", "prod"]
}

resource "google_storage_bucket" "env_bucket" {
  for_each = var.environments
  name     = "my-app-${each.key}-artifacts"
  location = "US"
}

# for_each with a map — richer per-item configuration
variable "gke_node_pools" {
  type = map(object({
    machine_type = string
    node_count   = number
  }))
  default = {
    general = { machine_type = "e2-standard-4", node_count = 3 }
    spot    = { machine_type = "e2-standard-4", node_count = 5 }
  }
}

resource "google_container_node_pool" "pools" {
  for_each = var.gke_node_pools
  name     = each.key
  cluster  = google_container_cluster.primary.name
  location = "us-central1"

  node_count = each.value.node_count

  node_config {
    machine_type = each.value.machine_type
    spot         = each.key == "spot"
  }
}

# for expressions — transforming lists/maps
locals {
  instance_names = [for i in google_compute_instance.worker : i.name]
  bucket_urls    = { for k, b in google_storage_bucket.env_bucket : k => b.url }
}

# conditional expressions (ternary)
resource "google_compute_instance" "conditional" {
  machine_type = var.environments == "prod" ? "n2-standard-4" : "e2-medium"
  # ...
  name = "app"
  zone = "us-central1-a"
  boot_disk { initialize_params { image = "debian-cloud/debian-12" } }
  network_interface { network = "default" }
}
```

**Rule of thumb**: prefer `for_each` over `count` whenever items can be added/removed from the middle of a list — `count` re-indexes everything after the changed item, causing unnecessary destroy/recreate; `for_each` keys are stable.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** `count` and `for_each` both create multiple instances of a resource, but they use fundamentally different **addressing schemes**: `count` indexes by position (`resource[0]`, `resource[1]`), while `for_each` indexes by a stable key (`resource["a"]`, `resource["b"]`). This difference is why removing an item from the middle of a `count`-driven list reshuffles every subsequent index, forcing Terraform to destroy/recreate resources that didn't actually change.

**Trade-offs:** `count` is simpler for truly homogeneous, position-independent resources (e.g., "N identical worker VMs where none has individual identity"); `for_each` is safer whenever items can be added/removed out of order or need distinct per-item configuration.

**Likely interview questions:**
- *"Why did removing one VM from the middle of my `count`-based list cause 5 other VMs to be destroyed and recreated?"* — `count` re-indexes positionally; every VM after the removed index shifts down one slot, and Terraform treats a shifted index as "this resource no longer exists at this address, create a new one at the new address."
- *"When would you still choose `count` over `for_each`?"* — When creating a genuinely interchangeable, unordered set of identical resources with no natural unique key, or a simple 0-or-1 conditional resource (`count = var.enabled ? 1 : 0`).

---

## 1.8 Version Constraints & Provider Management (Expert Guide)

```hcl
terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"   # allows 5.30.x and 5.31+, blocks 6.x
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

Version constraint operators:
| Operator | Meaning |
|---|---|
| `= 5.30.0` | Exact version only |
| `>= 5.30.0` | 5.30.0 or newer |
| `~> 5.30` | >= 5.30, < 6.0 (allows minor/patch bumps) |
| `~> 5.30.0` | >= 5.30.0, < 5.31.0 (patch bumps only) |

```bash
# Lock file — commit this to git for reproducible builds
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64
cat .terraform.lock.hcl
```

`google-beta` is required for provider-preview features (e.g., some newer GKE Autopilot fields, certain Cloud Run v2 fields) before they graduate to the GA `google` provider — you must explicitly set `provider = google-beta` on those resources:

```hcl
resource "google_container_cluster" "autopilot" {
  provider = google-beta
  name     = "autopilot-cluster"
  location = "us-central1"
  enable_autopilot = true
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Provider version constraints exist because providers evolve independently of Terraform core and can introduce breaking changes (renamed fields, changed defaults, removed resources) between major versions. The `.terraform.lock.hcl` file additionally pins exact provider *builds* (including checksums) so that "it works on my machine" doesn't silently break in CI due to a provider patch release changing behavior.

**Trade-offs:** Pinning too tightly (`= 5.30.0`) means you must manually bump versions to get bug fixes; pinning too loosely (no constraint at all) risks an unreviewed major version upgrade silently changing resource behavior mid-pipeline.

**Likely interview questions:**
- *"What's the difference between `required_version` and `required_providers`?"* — `required_version` constrains the Terraform CLI/core version itself; `required_providers` constrains the plugin versions (e.g., `hashicorp/google`) used to talk to a specific cloud API.
- *"Why do you need both `google` and `google-beta` providers?"* — `google-beta` exposes preview/beta-only GCP API fields not yet promoted to GA in the `google` provider; using the wrong one silently drops beta fields or fails validation.

---

## 1.9 NEW: Terraform Cloud & Enterprise Integration

Terraform Cloud (TFC) / Terraform Enterprise (TFE) can replace the GCS backend with a managed **remote execution** backend, adding: a UI, Sentinel policy checks, cost estimation, private module registry, and SSO.

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      tags = ["gcp", "prod"]
    }
  }
}
```

Authenticating TFC to GCP typically uses **Workload Identity Federation** (no long-lived service account keys):

```hcl
resource "google_iam_workload_identity_pool" "tfc_pool" {
  workload_identity_pool_id = "terraform-cloud-pool"
}

resource "google_iam_workload_identity_pool_provider" "tfc_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.tfc_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "tfc-provider"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    issuer_uri = "https://app.terraform.io"
  }
}

resource "google_service_account_iam_member" "tfc_wif_binding" {
  service_account_id = google_service_account.tfc_runner.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.sub/organization:my-org:project:my-project:workspace:prod:run_phase:apply"
}
```

Set TFC environment variables per workspace: `TFC_GCP_PROVIDER_AUTH=true`, `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL`, `TFC_GCP_WORKLOAD_POOL_ID`, `TFC_GCP_WORKLOAD_PROVIDER_ID` — this is the modern, key-less replacement for storing a downloaded JSON service account key as a sensitive TFC variable.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** TFC/TFE replaces a "backend" (just state storage + locking) with a full **remote execution environment** — `plan`/`apply` themselves run on HashiCorp's infrastructure (or your self-hosted TFE), not on a laptop or even a CI runner, giving centralized logs, policy enforcement, and RBAC baked into the run itself rather than bolted on via external CI scripting.

**Trade-offs:** You gain governance and a managed UI, but add a dependency on an external SaaS control plane (see 6.8's break-glass discussion) and a per-workspace cost model that needs to be budgeted for at scale.

**Likely interview questions:**
- *"Why prefer Workload Identity Federation over a downloaded service account JSON key for TFC-to-GCP auth?"* — WIF issues short-lived, automatically-rotated credentials tied to the specific CI run's identity, eliminating the risk of a long-lived key leaking and being reused outside its intended context.
- *"What's the practical difference between the GCS backend and the TFC `cloud` block?"* — GCS backend only stores/locks state; the TFC `cloud` block also runs the actual `plan`/`apply` execution remotely and applies policy sets before allowing an apply.

---

## 1.10 NEW: Best Practices & Common Mistakes

**Best Practices:**
1. One state per environment (`prod`, `staging`, `dev`) at minimum; ideally one state per logical stack (network, GKE, data) per environment.
2. Always pin provider versions (`~>`) and commit `.terraform.lock.hcl`.
3. Use `terraform plan -out=tfplan` then `apply tfplan` in CI — never apply an unreviewed plan.
4. Tag/label every resource (`environment`, `owner`, `cost-center`) for FinOps and cleanup automation.
5. Never store secrets in `.tfvars` committed to git — use Secret Manager + `data "google_secret_manager_secret_version"`.
6. Use `prevent_destroy` lifecycle on stateful resources (Cloud SQL, GCS buckets with critical data).

```hcl
resource "google_sql_database_instance" "prod" {
  name             = "prod-db"
  database_version = "POSTGRES_15"
  region           = "us-central1"

  settings {
    tier = "db-custom-4-16384"
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

**Common Mistakes:**
- Forgetting `uniform_bucket_level_access = true` on GCS buckets, leading to inconsistent legacy ACL behavior.
- Hardcoding project IDs/zones instead of variables — breaks reusability across environments.
- Using `count` for lists that can be reordered → unwanted destroy/recreate churn.
- Not enabling required GCP APIs before referencing their resources.
- Running `terraform apply` locally against a shared prod state without locking discipline.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Most Terraform "best practices" exist to reduce **blast radius** and **cognitive load** — smaller, well-labeled, well-pinned configurations are easier to reason about, safer to change, and faster to recover from when something goes wrong. Nearly every mistake in the "common mistakes" list is a blast-radius problem in disguise (a hardcoded value that breaks reuse, a missing `prevent_destroy` that turns a typo into data loss).

**Trade-offs:** Strict best practices (mandatory labels, `prevent_destroy` everywhere, small per-layer state files) add upfront ceremony that can feel like overhead on a two-person side project — but that overhead is exactly what prevents a costly incident once a team and its GCP footprint grow.

**Likely interview questions:**
- *"What's the single most important Terraform best practice for a production environment?"* — Reasonable answers include: never `apply` an unreviewed plan, or: always use a remote, locked, versioned backend — the throughline is "make every change reviewable and every mistake reversible."
- *"How would you prevent an accidental production database deletion in Terraform?"* — `lifecycle { prevent_destroy = true }` on the resource, plus a policy-as-code rule (3.4) that blocks any plan containing a `delete` action against a resource tagged `environment=prod`.

---

# SECTION 2: INTERMEDIATE TOPICS

## 2.1 Modules and Reusability (Extended with Design Patterns)

A **module** is a reusable, parameterized bundle of resources. Structure:

```
modules/
  gke-cluster/
    main.tf
    variables.tf
    outputs.tf
    versions.tf
```

```hcl
# modules/gke-cluster/variables.tf
variable "cluster_name" { type = string }
variable "region"       { type = string }
variable "network"      { type = string }
variable "subnetwork"   { type = string }
variable "node_pools" {
  type = map(object({
    machine_type = string
    node_count   = number
    disk_size_gb = optional(number, 100)
  }))
}

# modules/gke-cluster/main.tf
resource "google_container_cluster" "this" {
  name       = var.cluster_name
  location   = var.region
  network    = var.network
  subnetwork = var.subnetwork

  remove_default_node_pool = true
  initial_node_count       = 1

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${data.google_project.this.project_id}.svc.id.goog"
  }
}

data "google_project" "this" {}

resource "google_container_node_pool" "pools" {
  for_each   = var.node_pools
  name       = each.key
  cluster    = google_container_cluster.this.name
  location   = var.region
  node_count = each.value.node_count

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}

# modules/gke-cluster/outputs.tf
output "cluster_endpoint" { value = google_container_cluster.this.endpoint }
output "cluster_ca_certificate" {
  value     = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive = true
}
```

**Consuming the module** (root module):
```hcl
module "gke_prod" {
  source       = "./modules/gke-cluster"
  cluster_name = "prod-cluster"
  region       = "us-central1"
  network      = google_compute_network.vpc.self_link
  subnetwork   = google_compute_subnetwork.gke_subnet.self_link

  node_pools = {
    general = { machine_type = "n2-standard-4", node_count = 3 }
    spot    = { machine_type = "n2-standard-4", node_count = 5, disk_size_gb = 50 }
  }
}
```

**Design patterns:**
- **Thin wrapper modules** around `terraform-google-modules` (e.g., the official `terraform-google-modules/network/google` module) rather than reinventing VPC logic.
- **Composition root** pattern: a top-level environment folder (`envs/prod/main.tf`) that only calls modules — no raw resources — keeping environments DRY and consistent.
- Version-pin remote modules: `source = "github.com/my-org/tf-modules//gke?ref=v2.3.0"`.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Modules are Terraform's unit of abstraction and reuse — they let you hide implementation complexity (e.g., all the wiring needed for a hardened GKE cluster) behind a small, stable interface (a handful of input variables and outputs). This mirrors function/library design in general software engineering: consumers depend on the *interface*, not the internals.

**Trade-offs:** Over-abstracting too early (a module with 40 input variables trying to handle every possible use case) becomes as hard to use as no abstraction at all; the discipline is designing modules around genuine, repeated patterns, not hypothetical future flexibility.

**Likely interview questions:**
- *"How do you decide what should be a module versus inline resources?"* — If the same group of resources is declared more than once (or is likely to be, across environments/teams), it's a module candidate; one-off, environment-specific resources usually stay inline in the root/environment config.
- *"How do you version a module safely for consumers?"* — Semantic versioning with Git tags (`?ref=v2.3.0`) or a private registry; consumers pin an exact or constrained version so a breaking change in the module doesn't silently propagate.

---

## 2.2 Lifecycle Rules & Provisioners (Advanced Patterns)

```hcl
resource "google_compute_instance" "app" {
  name         = "app-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params { image = "debian-cloud/debian-12" }
  }
  network_interface { network = "default" }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [metadata["startup-script-hash"]]
    prevent_destroy        = false
    replace_triggered_by   = [null_resource.image_version.id]
  }

  metadata_startup_script = file("${path.module}/scripts/bootstrap.sh")

  provisioner "local-exec" {
    when    = create
    command = "echo 'Instance ${self.name} created at ${timestamp()}' >> deploy.log"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "debian"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      "sudo apt-get update",
      "sudo systemctl enable my-app",
    ]
  }
}
```

**Guidance**: HashiCorp explicitly considers provisioners a **last resort**. Prefer:
- `metadata_startup_script` / `metadata_startup_script` on Compute Engine (cloud-init style),
- baked custom images (Packer) so instances boot ready-to-serve,
- or GKE + container images instead of configuring VMs post-boot.

`create_before_destroy` is essential for zero-downtime replacement of resources like `google_compute_instance_template` used behind a Managed Instance Group.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** `lifecycle` blocks override Terraform's *default* replacement behavior for specific edge cases — `create_before_destroy` flips the default destroy-then-create order to avoid downtime; `ignore_changes` tells Terraform to tolerate drift on specific fields (often ones mutated by something other than Terraform, like an autoscaler); `prevent_destroy` is a hard safety rail. Provisioners, by contrast, are an escape hatch for imperative configuration Terraform's declarative model doesn't natively express — which is exactly why HashiCorp considers them a last resort.

**Trade-offs:** `create_before_destroy` requires the resource to tolerate two instances existing simultaneously (e.g., a uniquely-named resource can't do this without a `name_prefix`); provisioners couple your infrastructure definition to network reachability and SSH/WinRM credentials at apply time, a common source of flaky applies.

**Likely interview questions:**
- *"Why would `terraform apply` fail with a naming conflict when using `create_before_destroy`?"* — Because the new resource is created before the old one is destroyed, both must have valid, non-conflicting identifiers simultaneously — typically solved with `name_prefix` instead of a fixed `name`.
- *"Why are provisioners discouraged?"* — They introduce imperative, order-sensitive, network-dependent steps into an otherwise declarative model, and Terraform has no way to reliably know if a provisioner's remote effect succeeded or needs to be reversed on rollback.

---

## 2.3 Type Constraints & Validation (Expert Level)

```hcl
variable "node_pool_config" {
  type = object({
    machine_type = string
    disk_size_gb = number
    preemptible  = bool
    labels       = map(string)
    taints       = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  })

  validation {
    condition     = contains(["e2-standard-2", "e2-standard-4", "n2-standard-4"], var.node_pool_config.machine_type)
    error_message = "machine_type must be one of the approved SKUs for cost control."
  }

  validation {
    condition     = var.node_pool_config.disk_size_gb >= 50 && var.node_pool_config.disk_size_gb <= 500
    error_message = "disk_size_gb must be between 50 and 500."
  }
}

variable "region" {
  type = string
  validation {
    condition     = can(regex("^(us|europe|asia)-", var.region))
    error_message = "region must be a valid GCP region prefix (us-, europe-, asia-)."
  }
}
```

Complex types (`object`, `list(object(...))`, `map(object(...))`) plus `validation` blocks turn Terraform into a light schema-enforcement layer, catching bad input at `plan` time instead of a failed `apply` halfway through provisioning.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Type constraints and `validation` blocks move error detection earlier in the workflow — from a failed `apply` (or worse, a runtime failure after a bad value silently propagated) to `plan` time, or even to the moment someone types an invalid value. This is analogous to static typing catching bugs at compile time rather than at runtime in general programming.

**Trade-offs:** Rich `object` types with nested `optional()` fields are powerful but harder to read/document than flat primitive variables; overly strict `validation` blocks can also block legitimate edge cases the author didn't anticipate, requiring a config change to accommodate.

**Likely interview questions:**
- *"What's the benefit of `optional()` in an object type over just making a separate variable?"* — It lets consumers omit a field and get a sensible default while still keeping related configuration grouped in a single structured variable, rather than scattering many independent flat variables.
- *"How would you enforce that a variable is one of a fixed set of allowed values?"* — A `validation` block with `contains([...], var.x)` as the condition, or a type constraint isn't enough on its own since `string` doesn't restrict to an enum — validation blocks are how Terraform approximates enums.

---

## 2.4 Workspaces vs Separate State Files (Decision Framework)

Terraform **workspaces** (`terraform workspace new prod`) let one configuration manage multiple states differentiated by `terraform.workspace`, sharing the same backend prefix logically.

```hcl
resource "google_compute_instance" "app" {
  name         = "app-${terraform.workspace}"
  machine_type = terraform.workspace == "prod" ? "n2-standard-4" : "e2-medium"
  zone         = "us-central1-a"
  boot_disk { initialize_params { image = "debian-cloud/debian-12" } }
  network_interface { network = "default" }
}
```

| Criterion | Workspaces | Separate state files/directories |
|---|---|---|
| Config drift risk between envs | Low (same code) | Higher (can diverge) |
| Blast radius isolation | Weak — same backend, easy to `apply` against wrong workspace | Strong — physically separate buckets/prefixes |
| IAM isolation (prod locked down) | Hard to enforce | Easy — separate GCS buckets, separate service accounts |
| Recommended for | Small teams, ephemeral feature-branch environments | Production-grade, regulated environments |

**Recommendation for GCP production**: use **separate state files per environment** (often per-project, since GCP's project-per-environment model is a strong isolation boundary), reserving workspaces for short-lived preview/PR environments layered on `dev`.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Workspaces and separate state files/directories both solve "multiple environments from similar config," but they differ in **isolation strength**. Workspaces share the same backend configuration and the same `.tf` code path, meaning a `terraform workspace select prod && terraform apply` mistake (forgetting to switch workspace) is a real operational risk; separate directories/state files require an explicit, harder-to-fumble action (different working directory, different backend config) to target the wrong environment.

**Trade-offs:** Workspaces reduce code duplication for near-identical environments; separate state buys stronger blast-radius and IAM isolation at the cost of some config duplication (usually mitigated with shared modules, not copy-pasted resources).

**Likely interview questions:**
- *"Why might workspaces be risky for managing production versus dev?"* — Because switching the active workspace is a lightweight, easy-to-forget CLI command against the *same* backend — there's no strong access-control boundary preventing someone from running `apply` against `prod` by mistake the way a separate GCS bucket/service account per environment would provide.
- *"How would you achieve strong isolation between dev and prod GCP environments in Terraform?"* — Separate GCP projects, separate state buckets, separate service accounts/IAM per environment, with shared logic factored into versioned modules rather than relying on workspaces alone.

---

## 2.5 Import & Refactoring Existing Resources (Step-by-Step)

Bringing manually-created GCP resources under Terraform management:

```bash
# Step 1: write the resource skeleton in HCL first
```
```hcl
resource "google_storage_bucket" "existing_logs" {
  name     = "my-project-existing-logs-bucket"
  location = "US"
}
```
```bash
# Step 2: import (legacy CLI method)
terraform import google_storage_bucket.existing_logs my-project-existing-logs-bucket

# Step 2 (modern, Terraform 1.5+): declarative import blocks
```
```hcl
import {
  to = google_storage_bucket.existing_logs
  id = "my-project-existing-logs-bucket"
}
```
```bash
terraform plan   # shows the generated diff for review
terraform apply  # or: terraform plan -generate-config-out=generated.tf to scaffold HCL automatically
```

**Refactoring** (renaming/moving resources without destroy/recreate) uses `moved` blocks (Terraform 1.1+), replacing manual `terraform state mv`:

```hcl
moved {
  from = google_compute_instance.web
  to   = module.web_servers.google_compute_instance.web
}
```

**Full workflow for adopting a legacy GCP project into Terraform:**
1. Inventory resources with `gcloud asset search-all-resources`.
2. Write HCL skeletons or use `terraform plan -generate-config-out` (Terraform 1.5+) for supported resource types.
3. Import in small batches, verifying `terraform plan` shows **no changes** after each import (a diff means your HCL doesn't match reality yet).
4. Add `lifecycle { prevent_destroy = true }` to critical resources immediately after import.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** `import` (and `moved` blocks) exist because real infrastructure is rarely greenfield — resources get created by hand during incidents, by a departed engineer, or before Terraform adoption. Import brings an existing resource under Terraform's state *without* recreating it; the key conceptual risk is that Terraform only imports the **state entry**, not the HCL — you must still hand-write (or generate) matching configuration, or the next `plan` will show a confusing diff (or worse, try to "fix" real attributes back to some default).

**Trade-offs:** `terraform plan -generate-config-out` (1.5+) automates the tedious HCL-writing step for many resource types, but generated config is a starting point, not a finished, idiomatic module — it still needs review and refactoring.

**Likely interview questions:**
- *"What's the risk of importing a resource without first writing matching HCL?"* — The very next `plan` will show a large diff between your (empty/wrong) config and the real resource's actual attributes, and an unreviewed `apply` could revert real settings to unintended defaults.
- *"How do you rename a resource in code without Terraform destroying and recreating it?"* — A `moved` block (or the older `terraform state mv` command), which tells Terraform "this address maps to that address," preserving the existing state entry.

---

## 2.6 Team Collaboration & State Locking (Enterprise Workflows)

With the GCS backend, locking is automatic — Terraform writes a lock file using **conditional writes** (`ifGenerationMatch`) so two `apply` operations can't race.

```hcl
terraform {
  backend "gcs" {
    bucket = "my-org-tfstate-prod"
    prefix = "app/prod"
  }
}
```

Team workflow guardrails:
```bash
# CI enforces plan-then-apply, never local apply against prod
terraform plan -out=tfplan
# ... PR review of plan output ...
terraform apply tfplan
```

- Grant `roles/storage.objectAdmin` on the state bucket only to the CI service account and a small "break-glass" admin group.
- Use **GCS bucket versioning** (see 1.6) so a bad `apply` can be recovered via `terraform state pull` from a prior object generation.
- For genuinely concurrent teams, split state by service/component (see 3.3) so most day-to-day changes never contend on the same lock.

```bash
# Diagnosing a stuck lock (e.g., CI job was killed mid-apply)
terraform force-unlock <LOCK_ID>   # confirm no other apply is truly running first!
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** State locking exists to serialize concurrent writes to a single shared resource (the state file) — without it, two simultaneous `apply` runs could both read the same "before" state, compute independent diffs, and overwrite each other's results, silently corrupting Terraform's record of reality. This is the same fundamental problem optimistic/pessimistic concurrency control solves in databases, just applied to infrastructure state.

**Trade-offs:** Strict locking means a legitimate second `apply` must simply wait its turn — for very large teams making frequent changes to the *same* state file, this becomes a throughput bottleneck, which is the practical argument for splitting state by layer/service (3.3) rather than fighting for a single lock.

**Likely interview questions:**
- *"What actually gets locked when Terraform 'locks state'?"* — Not the underlying GCP resources themselves, only Terraform's own state file/backend — GCP resources can still be modified out-of-band (e.g., via Console) even while Terraform holds a lock, which is why IAM restrictions on direct Console access matter just as much as state locking.
- *"How would you handle a team that keeps hitting lock contention?"* — Split the monolithic state into smaller, independently-applied layers/components (3.3) so unrelated changes don't compete for the same lock.

---

## 2.7 Debugging & Troubleshooting Strategies (Comprehensive)

```bash
# Verbose provider-level logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply

# Narrow logging to just the provider (less noisy)
export TF_LOG_PROVIDER=DEBUG

# See exactly what API calls google provider is making
export TF_LOG=TRACE
```

Common GCP-specific errors and fixes:
| Error | Cause | Fix |
|---|---|---|
| `googleapi: Error 403: ... API has not been used` | Required API not enabled | Add `google_project_service` resource, `depends_on` it |
| `googleapi: Error 409: ... already exists` | Resource created outside Terraform | `terraform import` it |
| `Error: Cycle` | Circular `depends_on`/implicit refs | Break cycle with `data` source or restructure modules |
| `Quota 'CPUS' exceeded` | Regional quota limit | Request quota increase in Console, or spread across regions |
| `Error acquiring the state lock` | Concurrent apply / stale lock | Wait, or `force-unlock` after confirming no other run is active |

```bash
# Compare state vs real world without applying
terraform plan -refresh-only

# Console-based single-resource debugging
terraform console
> google_compute_instance.web.network_interface[0].access_config[0].nat_ip
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Terraform's error messages are sometimes generic (`Error: Cycle`, `Provider produced inconsistent result`) because the failure can originate at any of several layers — HCL evaluation, the internal dependency graph, or the provider's own gRPC implementation. Effective debugging means first identifying *which layer* failed: a syntax/graph problem is fixable in your `.tf` files; a provider-level inconsistency often means a provider bug requiring a version bump or upstream issue report.

**Trade-offs:** `TF_LOG=TRACE` gives maximum information but produces enormous, hard-to-read logs — most of the time `TF_LOG=DEBUG` (or provider-scoped `TF_LOG_PROVIDER`) is a better first step, reserving `TRACE` for genuinely stubborn issues.

**Likely interview questions:**
- *"You get `Error: Cycle` — what does that mean and how do you fix it?"* — Two or more resources have a circular dependency (directly or via `depends_on`/implicit references); fix by breaking the cycle, often by introducing a `data` source or restructuring which resource references which.
- *"How would you debug a `plan` that behaves differently in CI than locally?"* — Compare provider versions and Terraform CLI versions (check `.terraform.lock.hcl` is actually being respected), check for environment-specific variables/credentials causing different API responses, and enable `TF_LOG=DEBUG` in both environments to diff the API calls being made.

---

## 2.8 Sensitive Data & Secrets Management (Security Focus)

**Never** put secrets (DB passwords, API keys) directly in `.tf`/`.tfvars`. Use **Secret Manager**:

```hcl
resource "random_password" "db_password" {
  length  = 24
  special = true
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "prod-db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

resource "google_sql_database_instance" "prod" {
  name             = "prod-db"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  settings { tier = "db-custom-2-8192" }
}

resource "google_sql_user" "app" {
  instance = google_sql_database_instance.prod.name
  name     = "app_user"
  password = random_password.db_password.result
}

# Marking outputs sensitive
output "db_connection_name" {
  value     = google_sql_database_instance.prod.connection_name
  sensitive = false
}
output "db_password_secret" {
  value     = google_secret_manager_secret.db_password.secret_id
  sensitive = true
}
```

Runtime access from an application (e.g., Cloud Run) pulls the secret directly, never via Terraform variables:
```hcl
resource "google_cloud_run_v2_service" "app" {
  name     = "app"
  location = "us-central1"
  template {
    containers {
      image = "us-central1-docker.pkg.dev/my-project/app/app:latest"
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }
  }
}
```
Additional hardening: encrypt state itself with a **CMEK** on the GCS backend bucket (1.6), restrict `roles/secretmanager.secretAccessor` to specific service accounts, and enable **VPC Service Controls** to prevent secret exfiltration.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** The core principle is *secrets should never enter version control or Terraform's own plaintext state as their "source of truth"* — Secret Manager (or a similar vault) is the actual authoritative store; Terraform only orchestrates *provisioning access* to secrets (creating the secret container, granting IAM), and applications fetch the secret value directly at runtime rather than receiving it baked into an environment variable set by Terraform.

**Trade-offs:** Even with Secret Manager, a *generated* password (e.g., via `random_password`) still transits through Terraform state at least once during creation — meaning state encryption and backend IAM restriction (1.6, 2.8) remain necessary even when using a secrets manager; Secret Manager doesn't eliminate the need for state hygiene, it reduces exposure surface for ongoing access.

**Likely interview questions:**
- *"Does marking a Terraform output `sensitive = true` actually encrypt the value?"* — No — it only suppresses the value from CLI output/logs; the value is still stored in plaintext in the state file, which is why backend encryption and access control matter independently.
- *"How would an application actually retrieve a database password provisioned by Terraform, without Terraform ever exposing it as a plain variable?"* — The application calls the Secret Manager API directly at runtime (or via a sidecar/injected environment variable sourced from Secret Manager, e.g., Cloud Run's `secret_key_ref`), rather than Terraform outputting the value into a config file or CI variable.

---

## 2.9 NEW: VPC & Networking Deep Dive

```hcl
resource "google_compute_network" "vpc" {
  name                    = "prod-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "app_subnet" {
  name          = "app-subnet-us-central1"
  ip_cidr_range = "10.10.0.0/20"
  region        = "us-central1"
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.0.0/16"
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.30.0.0/20"
  }

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.10.0.0/20", "10.20.0.0/16"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"] # Identity-Aware Proxy range only
  target_tags   = ["ssh-allowed"]
}

resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.vpc.id
  region  = "us-central1"
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.nat_router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
```

This gives you: no public IPs required on private VMs (NAT egress), IAP-only SSH (no `0.0.0.0/0` port 22), VPC Flow Logs for observability, and secondary ranges pre-sized for a future GKE cluster.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** GCP's VPC model is fundamentally **global** (a single VPC can span all regions, unlike AWS's region-scoped VPCs), with **regional subnets** inside it — this changes how you think about network design: you don't need VPC peering across regions for a single global app, just multiple regional subnets within one VPC. Firewall rules are also global constructs applied via network tags/service accounts, not subnet-attached like AWS security groups.

**Trade-offs:** GCP's global VPC simplifies multi-region architecture significantly, but it also means a single firewall misconfiguration has organization-wide (not just regional) blast radius — network segmentation across environments is usually achieved with separate VPCs (or Shared VPC with per-team subnets) rather than relying on regional boundaries alone.

**Likely interview questions:**
- *"How is a GCP VPC different from an AWS VPC?"* — GCP VPCs are global resources with regional subnets; AWS VPCs are region-scoped, requiring VPC peering or Transit Gateway to span regions.
- *"Why use Cloud NAT instead of giving VMs public IPs?"* — Cloud NAT provides outbound internet access for private VMs without exposing them to unsolicited inbound traffic, reducing attack surface while still allowing package installs/API calls.

---

## 2.10 NEW: Database Migration to Terraform

Migrating an existing hand-created **Cloud SQL** instance into Terraform management:

```hcl
resource "google_sql_database_instance" "legacy" {
  name             = "legacy-prod-db"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier              = "db-custom-4-16384"
    availability_type = "REGIONAL"
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
    }
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

```bash
# 1. Import the existing instance
terraform import google_sql_database_instance.legacy legacy-prod-db

# 2. Import databases and users individually
terraform import google_sql_database.app legacy-prod-db/app_db
terraform import google_sql_user.app legacy-prod-db/app_user
```

**Zero-downtime migration pattern** (e.g., moving from unmanaged VM-hosted MySQL to Cloud SQL): stand up Cloud SQL via Terraform, use **Database Migration Service (DMS)** for continuous replication, cut over DNS/connection strings, then decommission the old VM — all while Terraform manages only the *target* Cloud SQL resource from day one, avoiding importing a mid-migration moving target.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Migrating a database into Terraform management is riskier than most resources because databases are **stateful and hard to recreate** — an accidental `destroy`/`recreate` (e.g., from changing an immutable field like `region`) can mean real, unrecoverable data loss, not just a brief outage. This is why `prevent_destroy` and careful import-before-first-apply discipline matter more here than almost anywhere else in this guide.

**Trade-offs:** Using Database Migration Service for a zero-downtime cutover adds operational complexity (replication lag monitoring, cutover timing) compared to a simple "stop writes, dump/restore, resume" migration — but the trade-off is usually worth it for any database that can't tolerate a maintenance window.

**Likely interview questions:**
- *"What Terraform field changes on `google_sql_database_instance` are likely to force a destroy/recreate, and how do you guard against that?"* — Fields like `region` or `database_version` (in some transitions) can force replacement; guard with `lifecycle { prevent_destroy = true }` and always review the `# forces replacement` annotation in `plan` output before applying.
- *"How would you migrate a hand-run MySQL server into Cloud SQL with minimal downtime?"* — Provision the target Cloud SQL instance via Terraform, use Database Migration Service for continuous replication, validate data parity, then cut over connection strings/DNS during a short window and decommission the source.

---

# SECTION 3: ADVANCED PATTERNS

## 3.1 Advanced Module Design & Testing (Enterprise Grade)

Enterprise module design principles: single responsibility, no hardcoded environment logic inside the module, semantic versioning, and automated tests.

```hcl
# modules/vpc/variables.tf
variable "subnets" {
  type = list(object({
    name          = string
    cidr          = string
    region        = string
    private_access = optional(bool, true)
  }))
}
```

**Testing with `terraform test`** (native, Terraform 1.6+):
```hcl
# tests/vpc.tftest.hcl
run "creates_expected_subnet_count" {
  command = plan

  variables {
    subnets = [
      { name = "a", cidr = "10.0.0.0/24", region = "us-central1" },
      { name = "b", cidr = "10.0.1.0/24", region = "us-east1" },
    ]
  }

  assert {
    condition     = length(google_compute_subnetwork.this) == 2
    error_message = "Expected 2 subnets to be planned"
  }
}

run "rejects_overlapping_cidrs" {
  command = plan
  variables {
    subnets = [
      { name = "a", cidr = "10.0.0.0/24", region = "us-central1" },
      { name = "b", cidr = "10.0.0.0/24", region = "us-east1" },
    ]
  }
  expect_failures = [var.subnets]
}
```
```bash
terraform test
```

Also common: **Terratest** (Go) for full `apply` + assertion + `destroy` integration tests against a real (sandbox) GCP project — see 4.3 for detail. Enterprise-grade modules publish to a **private module registry** (Terraform Cloud/Enterprise, or Artifact Registry Terraform modules) with semver tags, README-driven examples, and CI that runs `terraform test` + `tflint` + `checkov`/`tfsec` on every PR.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Testing Terraform modules addresses a real gap — HCL has no compiler that catches logic errors, only syntax/type errors. `terraform test` catches "does this module produce the plan I expect" issues cheaply (no real resources), while Terratest-style integration tests catch "does this module actually work against a real API" issues that a plan-only test structurally cannot (e.g., an IAM permission that's missing only becomes visible on a real `apply`).

**Trade-offs:** Plan-only tests are fast and free but can't catch every real-world failure mode (quota limits, actual permission errors, API-side validation); full apply-based integration tests catch those but are slow, cost money, and need careful cleanup (`defer terraform.Destroy`) to avoid leaving orphaned resources in a sandbox project.

**Likely interview questions:**
- *"What's the difference between `terraform test` (native) and Terratest?"* — Native `terraform test` can run in plan-only mode with fast, free assertions on the plan's shape; Terratest (Go) actually applies real infrastructure, asserts against live resources, and tears down afterward — better for catching real API-level issues but slower and costlier.
- *"How would you structure a CI pipeline to balance fast feedback with real integration coverage?"* — Run cheap static checks (`fmt`, `validate`, `tflint`, plan-based `terraform test`) on every PR; reserve expensive apply-based Terratest suites for merge-to-main or nightly scheduled runs.

---

## 3.2 Multi-Cloud & Hybrid Deployments (Detailed)

Terraform's provider-agnostic core lets a single configuration span GCP + on-prem/other clouds when required (e.g., DNS failover, hybrid connectivity).

```hcl
provider "google" {
  project = var.gcp_project
  region  = "us-central1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "dr_site"
}

# Primary workload on GCP
resource "google_compute_instance" "primary" {
  name         = "primary-app"
  machine_type = "n2-standard-4"
  zone         = "us-central1-a"
  boot_disk { initialize_params { image = "debian-cloud/debian-12" } }
  network_interface { network = "default" }
}

# DR / secondary footprint elsewhere (illustrative hybrid pattern)
resource "aws_instance" "dr_standby" {
  provider      = aws.dr_site
  ami           = "ami-0abcd1234"
  instance_type = "t3.large"
}

# Unified DNS failover via Cloud DNS
resource "google_dns_managed_zone" "primary_zone" {
  name     = "example-com"
  dns_name = "example.com."
}

resource "google_dns_record_set" "app" {
  name         = "app.example.com."
  type         = "A"
  ttl          = 60
  managed_zone = google_dns_managed_zone.primary_zone.name
  rrdatas      = [google_compute_instance.primary.network_interface[0].access_config[0].nat_ip]
}
```

**Hybrid connectivity to on-prem** (see also 2.9 for pure VPC): use **Cloud VPN** or **Cloud Interconnect** so on-prem systems can reach GCP-hosted services during a phased migration:

```hcl
resource "google_compute_vpn_gateway" "target_gateway" {
  name    = "onprem-vpn-gw"
  network = google_compute_network.vpc.id
  region  = "us-central1"
}

resource "google_compute_ha_vpn_gateway" "ha_gateway" {
  name    = "onprem-ha-vpn-gw"
  network = google_compute_network.vpc.id
  region  = "us-central1"
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Multi-cloud/hybrid Terraform works because the *provider* abstraction is orthogonal to Terraform's core engine — the same dependency graph, state model, and plan/apply lifecycle apply regardless of which providers are declared. This lets one configuration coordinate resources across `google`, `aws`, and on-prem-facing providers, provided you accept that each provider still has its own authentication, its own resource semantics, and its own quirks.

**Trade-offs:** Multi-cloud Terraform reduces tooling fragmentation (one IaC language for everything), but doesn't eliminate the deeper cost of true multi-cloud operations — different networking models, different IAM models, and different failure modes still need to be understood per cloud; Terraform unifies the *tooling*, not the underlying platforms' behavior.

**Likely interview questions:**
- *"What's the benefit of managing a hybrid GCP/on-prem/AWS setup in one Terraform config versus separate tools per cloud?"* — Consistent workflow (`plan`/`apply`), consistent state/locking discipline, and the ability to reference outputs across providers directly (e.g., wiring a GCP DNS record to point at an AWS instance's IP) without manual handoff between separate tools.
- *"What GCP services would you use for hybrid on-prem connectivity, and why choose one over the other?"* — Cloud VPN for lower-throughput/cost-sensitive links via IPsec over the public internet; Cloud Interconnect for dedicated, higher-throughput, lower-latency private connectivity when volume/reliability requirements justify the cost.

---

## 3.3 State Management at Scale (Hierarchical Structures)

For large orgs, split state along two axes: **environment** (dev/staging/prod) and **layer** (network → shared services → application):

```
repos/
  network-stack/       -> gs://org-tfstate/network/{env}
  shared-services/      -> gs://org-tfstate/shared/{env}   (GKE, Cloud SQL, Redis)
  app-frontend/          -> gs://org-tfstate/app-frontend/{env}
  app-backend/            -> gs://org-tfstate/app-backend/{env}
```

Each layer reads the layer beneath via `terraform_remote_state`:
```hcl
data "terraform_remote_state" "network" {
  backend = "gcs"
  config = {
    bucket = "org-tfstate"
    prefix = "network/${var.environment}"
  }
}

data "terraform_remote_state" "shared" {
  backend = "gcs"
  config = {
    bucket = "org-tfstate"
    prefix = "shared/${var.environment}"
  }
}

resource "google_cloud_run_v2_service" "backend" {
  name     = "backend"
  location = "us-central1"
  template {
    vpc_access {
      connector = data.terraform_remote_state.shared.outputs.vpc_connector_id
    }
    containers {
      image = "us-central1-docker.pkg.dev/${var.project_id}/app/backend:latest"
    }
  }
}
```

**Benefits**: a bad `apply` in `app-frontend` can never touch the network layer's state; the network team can lock down `roles/storage.objectAdmin` on their state bucket to a tiny group while app teams self-serve on their own buckets. **Trade-off**: more `remote_state` plumbing and slightly slower cross-layer changes (must apply bottom-up).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Splitting state by layer is a direct application of the **blast radius** principle from 1.10 — the probability of a catastrophic mistake is roughly constant per `apply`, so the way to limit damage is to limit *what* any single `apply` can touch. A network-layer mistake should never be able to accidentally destroy an application-layer resource, and vice versa; separating state files (and often separate GCP projects/service accounts per layer) enforces that boundary structurally, not just by convention.

**Trade-offs:** More layers means more `terraform_remote_state`/`tfe_outputs` plumbing and a stricter "apply bottom-up" ordering discipline (you can't apply the app layer before the network layer it depends on exists) — the operational overhead is the price paid for the safety.

**Likely interview questions:**
- *"How would you design a Terraform state architecture for a large multi-team GCP organization?"* — Split by both environment (dev/staging/prod) and layer (network → shared services → application), each with its own state file/bucket and often its own GCP project, with lower layers exposing outputs consumed by higher layers via remote state.
- *"What's the risk of one giant monolithic state file for an entire org?"* — Every `apply` has organization-wide blast radius, lock contention becomes severe with multiple teams, and `plan`/`apply` times grow with the total resource count regardless of which small piece actually changed.

---

## 3.4 Policy as Code (Sentinel/OPA) (Production Grade)

**Sentinel** (Terraform Cloud/Enterprise only) example — deny any Compute instance without required labels:

```python
import "tfplan/v2" as tfplan

mandatory_labels = ["environment", "owner", "cost-center"]

instances = filter tfplan.resource_changes as _, rc {
  rc.type is "google_compute_instance" and
  (rc.change.actions contains "create" or rc.change.actions contains "update")
}

labels_present = rule {
  all instances as _, i {
    all mandatory_labels as label {
      i.change.after.labels contains label
    }
  }
}

main = rule { labels_present }
```

**Open Policy Agent (OPA) / `conftest`** (works with any CI, not just TFC) — deny public GCS buckets:

```rego
package terraform.gcs

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "google_storage_bucket_iam_binding"
  resource.change.after.role == "roles/storage.objectViewer"
  resource.change.after.members[_] == "allUsers"
  msg := sprintf("Bucket IAM binding %s grants public access via allUsers", [resource.address])
}
```

```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
conftest test plan.json -p policy/
```

Policy-as-code shifts security review from a manual checklist to an automated, mandatory CI gate — a plan that would create a public bucket or an unlabeled resource simply cannot merge.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Policy-as-code moves governance from a *manual, human-reviewed checklist* (easy to skip under deadline pressure) to a *mandatory, automated gate* evaluated against the actual machine-readable plan JSON — meaning a policy violation is caught with certainty, not "if the reviewer happened to notice it."

**Trade-offs:** Sentinel is powerful but tied to Terraform Cloud/Enterprise (a paid feature); OPA/`conftest` is free and works with any CI system but requires you to build the plan-JSON pipeline yourself (`terraform show -json` → `conftest test`) rather than getting it built-in.

**Likely interview questions:**
- *"What's the difference between Sentinel and OPA/conftest for Terraform policy enforcement?"* — Sentinel is HashiCorp's proprietary policy language, natively integrated into TFC/TFE's run pipeline; OPA/conftest is open-source and cloud/tool-agnostic, requiring you to wire it into your own CI pipeline against the exported plan JSON.
- *"How would you prevent any Terraform plan from creating a publicly-readable GCS bucket, org-wide?"* — Write an OPA/Sentinel policy that inspects `resource_changes` for `google_storage_bucket_iam_binding`/`_member` resources granting a role to `allUsers` or `allAuthenticatedUsers`, and fail the plan check — enforced as a mandatory CI/policy-set gate.

---

## 3.5 Security Best Practices (Comprehensive Hardening)

```hcl
# Least-privilege custom IAM role instead of broad predefined roles
resource "google_project_iam_custom_role" "ci_deployer" {
  role_id     = "ciDeployer"
  title       = "CI Deployer"
  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.disks.create",
    "iam.serviceAccounts.actAs",
  ]
}

# Org policy constraints applied via Terraform
resource "google_org_policy_policy" "disable_sa_key_creation" {
  name   = "projects/${var.project_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/${var.project_id}"
  spec {
    rules { enforce = "TRUE" }
  }
}

resource "google_org_policy_policy" "restrict_public_ips" {
  name   = "projects/${var.project_id}/policies/compute.vmExternalIpAccess"
  parent = "projects/${var.project_id}"
  spec {
    rules { deny_all = "TRUE" }
  }
}

# Binary Authorization for GKE — only signed/verified images can deploy
resource "google_binary_authorization_policy" "policy" {
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.built_by_ci.name]
  }
}
```

Additional hardening checklist:
- Enable **VPC Service Controls** around sensitive projects to prevent data exfiltration.
- Enforce **Shielded VMs** (`shielded_instance_config { enable_secure_boot = true }`) by org policy.
- Rotate and avoid service account keys entirely — prefer **Workload Identity Federation** (CI/CD) and **Workload Identity** (GKE pods).
- Scan Terraform code in CI with `tfsec` / `checkov` for misconfigurations before merge (see 4.6).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** GCP security hardening in Terraform operates at two layers that reinforce each other: **preventive controls at the plan/policy level** (Sentinel/OPA blocking a bad plan before it's ever applied) and **preventive controls at the platform level** (Org Policy constraints that block the underlying API call itself, regardless of how it was invoked). Relying on only one layer leaves a gap — Org Policy alone doesn't stop a bad Terraform plan from being written; policy-as-code alone doesn't stop a `gcloud` command run outside Terraform entirely.

**Trade-offs:** Org Policy constraints are extremely powerful but organization-wide by default — an overly aggressive constraint (e.g., blanket-disabling all external IPs) can break legitimate use cases (a bastion host, a public load balancer's backend) unless scoped carefully with exceptions.

**Likely interview questions:**
- *"What's the difference between enforcing 'no public IPs' via Terraform code review versus via GCP Org Policy?"* — Code review/policy-as-code only stops it if the change goes through Terraform; Org Policy (`compute.vmExternalIpAccess`) blocks the underlying API call itself, closing the gap for changes made outside Terraform (Console, `gcloud`, other automation).
- *"Why prefer Workload Identity Federation over service account keys, from a security standpoint?"* — WIF eliminates long-lived, exportable credentials entirely — access is granted based on a verified external identity token with a short lifespan, removing the risk of a leaked key being reused indefinitely by an attacker.

---

## 3.6 Drift Detection & Remediation (Automated Solutions)

Drift = someone changed a GCP resource outside Terraform (Console click, `gcloud` command, another automation). Detect it with scheduled `plan -refresh-only` runs:

```yaml
# .github/workflows/drift-detection.yml
name: drift-detection
on:
  schedule:
    - cron: '0 6 * * *'
jobs:
  drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform plan -refresh-only -detailed-exitcode -out=drift.tfplan
        id: plan
        continue-on-error: true
      - name: Alert on drift
        if: steps.plan.outputs.exitcode == '2'
        run: |
          curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"⚠️ Terraform drift detected in prod!"}' \
            "${{ secrets.SLACK_WEBHOOK_URL }}"
```
`-detailed-exitcode` returns `0` = no changes, `1` = error, `2` = changes present (drift found).

**Remediation options:**
1. **Codify the drift**: if the manual change was legitimate, update the `.tf` file to match and `apply` (no-op against real world, just updates state expectation).
2. **Revert the drift**: run a normal `terraform apply` to force GCP back to the declared state.
3. **Prevent recurrence**: remove Console/`gcloud` write access for engineers on Terraform-managed projects; funnel all changes through CI. Use **Cloud Asset Inventory** feeds + Cloud Functions to auto-flag or auto-revert unauthorized changes in near-real-time for the most critical resources.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Drift happens because Terraform only knows about changes it initiates — any out-of-band change (Console click, another automation, an emergency `gcloud` fix during an incident) silently diverges real-world state from what Terraform's state file records, until the next `plan` (or scheduled `-refresh-only` check) surfaces the difference.

**Trade-offs:** Aggressive automated drift *remediation* (auto-reverting any detected drift) is risky for resources that legitimately need emergency out-of-band fixes during incidents (7.5) — many teams choose to alert on drift and require human judgment on whether to codify or revert it, rather than blindly auto-reverting everything.

**Likely interview questions:**
- *"How do you detect infrastructure drift without accidentally making changes?"* — `terraform plan -refresh-only -detailed-exitcode`, which only refreshes state from the real world and reports whether it differs from your `.tf` config, without proposing or applying any changes to the config side.
- *"An engineer manually fixed a firewall rule during an incident, causing drift. What's the right follow-up?"* — Decide whether the manual fix was the correct permanent state (then update the `.tf` file to match) or a temporary patch (then run a normal `apply` to revert it to the declared state) — never leave it as silent, undocumented drift.

---

## 3.7 NEW: Container Orchestration (GKE — the AWS ECS/EKS equivalent)

```hcl
resource "google_container_cluster" "primary" {
  name     = "prod-gke"
  location = "us-central1"

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.app_subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }
}

resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.primary.name
  location   = "us-central1"
  node_count = 3

  autoscaling {
    min_node_count = 3
    max_node_count = 10
  }

  node_config {
    machine_type = "n2-standard-4"
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    shielded_instance_config {
      enable_secure_boot = true
    }
  }
}

# Workload Identity binding: a GKE service account can act as a GCP service account
resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.app_sa.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:${var.project_id}.svc.id.goog[default/app-ksa]"
}
```

**GKE Autopilot** (fully managed nodes, closer to Fargate for EKS):
```hcl
resource "google_container_cluster" "autopilot" {
  name             = "prod-autopilot"
  location         = "us-central1"
  enable_autopilot = true
  network          = google_compute_network.vpc.id
  subnetwork       = google_compute_subnetwork.app_subnet.id
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** GKE Standard vs. Autopilot represents a fundamental trade-off between **control and operational overhead**: Standard gives you direct control over node pools, machine types, and OS-level configuration (closer to self-managed EKS node groups); Autopilot fully abstracts nodes away, managing scaling, sizing, and security hardening for you (closer to Fargate), at the cost of losing node-level customization and often paying a per-pod pricing premium.

**Trade-offs:** Workload Identity replaces the older, less secure pattern of mounting a service account key inside a pod — but requires correctly binding the Kubernetes service account to the GCP service account (`roles/iam.workloadIdentityUser`), a step that's easy to misconfigure and a common source of "permission denied" errors that look like an IAM problem but are actually a binding problem.

**Likely interview questions:**
- *"When would you choose GKE Autopilot over Standard?"* — When operational simplicity and reduced node-management overhead outweigh the need for fine-grained node customization — e.g., smaller platform teams, or workloads with unpredictable/spiky scaling needs where per-pod billing and automatic right-sizing add real value.
- *"How does Workload Identity improve on using a downloaded service account key inside a pod?"* — It lets a Kubernetes service account impersonate a GCP service account via short-lived, automatically-rotated tokens obtained through the metadata server, eliminating the need to store and mount a long-lived exportable key as a Kubernetes secret.

---

## 3.8 NEW: Serverless Deployment Patterns

**Cloud Run** (the direct Lambda/Fargate-serverless equivalent):
```hcl
resource "google_cloud_run_v2_service" "api" {
  name     = "api"
  location = "us-central1"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 20
    }
    containers {
      image = "us-central1-docker.pkg.dev/${var.project_id}/app/api:latest"
      resources {
        limits = { cpu = "1", memory = "512Mi" }
      }
      ports { container_port = 8080 }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  name     = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
```

**Cloud Functions (2nd gen)** for event-driven serverless:
```hcl
resource "google_cloudfunctions2_function" "process_upload" {
  name     = "process-upload"
  location = "us-central1"

  build_config {
    runtime     = "python312"
    entry_point = "handle_event"
    source {
      storage_source {
        bucket = google_storage_bucket.source.name
        object = google_storage_bucket_object.function_zip.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    available_memory   = "256M"
    timeout_seconds     = 60
  }

  event_trigger {
    trigger_region = "us-central1"
    event_type     = "google.cloud.storage.object.v1.finalized"
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.uploads.name
    }
  }
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Cloud Run and Cloud Functions both scale to zero, but they represent different abstraction levels: Cloud Run runs *any containerized service* (you bring the container, including custom runtimes/dependencies), while Cloud Functions (2nd gen, itself built on Cloud Run under the hood) is optimized for small, single-purpose, event-triggered code with less operational ceremony (no Dockerfile required for supported runtimes).

**Trade-offs:** Serverless's scale-to-zero is excellent for cost efficiency on spiky/idle workloads, but introduces **cold start latency** on the first request after idling — a real trade-off against always-on compute (GKE/Compute Engine) for latency-sensitive services, mitigated with `min_instance_count > 0` at the cost of paying for idle capacity.

**Likely interview questions:**
- *"When would you choose Cloud Run over Cloud Functions for a new service?"* — When you need a full custom container (specific OS packages, multiple processes, a non-supported language/runtime version) or an HTTP service with more complex routing/behavior than a single function handler naturally expresses.
- *"How do you avoid cold-start latency issues for a serverless GCP service handling user-facing traffic?"* — Set `min_instance_count` above zero to keep warm instances ready, at the cost of paying for idle capacity — a direct cost/latency trade-off configured per environment (e.g., 0 for dev, 2+ for prod).

---

## 3.9 NEW: API Integration & Automation

Automating cross-service GCP workflows entirely through Terraform-managed **Eventarc**, **Pub/Sub**, and **Cloud Scheduler**:

```hcl
resource "google_pubsub_topic" "order_events" {
  name = "order-events"
}

resource "google_cloud_scheduler_job" "nightly_report" {
  name      = "nightly-report"
  schedule  = "0 2 * * *"
  time_zone = "America/Chicago"

  http_target {
    uri         = google_cloud_run_v2_service.reporting.uri
    http_method = "POST"
    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }
}

resource "google_eventarc_trigger" "order_created" {
  name     = "order-created-trigger"
  location = "us-central1"

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.pubsub.topic.v1.messagePublished"
  }

  transport {
    pubsub {
      topic = google_pubsub_topic.order_events.id
    }
  }

  destination {
    cloud_run_service {
      service = google_cloud_run_v2_service.order_processor.name
      region  = "us-central1"
    }
  }

  service_account = google_service_account.eventarc_sa.email
}
```
This wires: Pub/Sub topic → Eventarc trigger → Cloud Run service, entirely declared in Terraform, with the scheduler independently able to invoke a reporting endpoint on a cron — a fully serverless, infrastructure-as-code automation chain.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Eventarc, Pub/Sub, and Cloud Scheduler together let you build **event-driven architectures entirely as declared infrastructure** rather than custom glue code — the "automation" lives in the wiring between managed services (a topic, a trigger, a target) instead of in a bespoke script that has to be separately deployed, monitored, and secured.

**Trade-offs:** Event-driven, fully-managed automation reduces operational burden significantly, but debugging a multi-hop chain (Pub/Sub → Eventarc → Cloud Run) is harder than tracing a single monolithic script — you need Cloud Trace/Logging correlation IDs threaded through each hop to reconstruct an end-to-end request path during an incident.

**Likely interview questions:**
- *"Why route a Pub/Sub message through Eventarc to Cloud Run instead of having Cloud Run pull directly from the subscription?"* — Eventarc standardizes event delivery (CloudEvents format), handles retry/dead-lettering consistently across many event sources beyond just Pub/Sub, and decouples the trigger configuration from the service's own code.
- *"How would you trigger a nightly batch job in a fully serverless GCP architecture, and authenticate it securely?"* — Cloud Scheduler's `http_target` invoking a Cloud Run service's HTTPS endpoint, authenticated via an OIDC token tied to a dedicated service account with only the minimal `roles/run.invoker` permission needed.

---

# SECTION 4: CI/CD & TESTING

## 4.1 CI/CD Pipeline Patterns (GitLab, GitHub, Jenkins)

**GitHub Actions** (using Workload Identity Federation — no service account keys):
```yaml
name: terraform-gcp
on:
  pull_request:
    paths: ["infra/**"]
  push:
    branches: [main]
    paths: ["infra/**"]

permissions:
  id-token: write
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    defaults:
      run: { working-directory: infra }
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123456789/locations/global/workloadIdentityPools/gh-pool/providers/gh-provider
          service_account: terraform-ci@my-project.iam.gserviceaccount.com
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform fmt -check -recursive
      - run: terraform validate
      - run: terraform plan -out=tfplan
      - uses: actions/upload-artifact@v4
        with: { name: tfplan, path: infra/tfplan }

  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/123456789/locations/global/workloadIdentityPools/gh-pool/providers/gh-provider
          service_account: terraform-ci@my-project.iam.gserviceaccount.com
      - uses: hashicorp/setup-terraform@v3
      - uses: actions/download-artifact@v4
        with: { name: tfplan, path: infra }
      - run: terraform apply -auto-approve tfplan
        working-directory: infra
```

**GitLab CI**:
```yaml
stages: [validate, plan, apply]

.terraform_base:
  image: hashicorp/terraform:1.7
  before_script:
    - terraform init

validate:
  stage: validate
  extends: .terraform_base
  script:
    - terraform fmt -check -recursive
    - terraform validate

plan:
  stage: plan
  extends: .terraform_base
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths: [tfplan]

apply:
  stage: apply
  extends: .terraform_base
  script:
    - terraform apply -auto-approve tfplan
  when: manual
  only: [main]
```

**Jenkins (declarative pipeline)**:
```groovy
pipeline {
  agent any
  environment {
    GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-terraform-sa')
  }
  stages {
    stage('Init')     { steps { sh 'terraform init' } }
    stage('Validate') { steps { sh 'terraform validate' } }
    stage('Plan')      { steps { sh 'terraform plan -out=tfplan' } }
    stage('Apply') {
      when { branch 'main' }
      steps {
        input message: 'Apply to production?'
        sh 'terraform apply -auto-approve tfplan'
      }
    }
  }
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** CI/CD for Terraform enforces the same `plan`-then-review-then-`apply` discipline as 1.2, but makes it *structural* rather than optional — a human can forget to run `plan` locally before `apply`, but a pipeline that requires a plan artifact to exist and be approved before the apply stage runs cannot be bypassed by habit or hurry.

**Trade-offs:** Workload Identity Federation-based auth (no static keys in CI secrets) is more secure but requires more upfront setup (configuring the identity pool/provider, trust relationships) than simply pasting a service account key into a CI secret — a one-time cost worth paying for any long-lived pipeline.

**Likely interview questions:**
- *"Why separate `plan` and `apply` into different CI jobs/stages rather than one combined step?"* — To insert a mandatory human review/approval gate between generating the diff and executing it, and to allow the exact reviewed plan artifact (not a freshly re-computed one) to be the thing that's applied, avoiding a time-of-check-to-time-of-use gap.
- *"How would you authenticate a GitHub Actions pipeline to GCP without storing a service account key as a secret?"* — Workload Identity Federation — configure a workload identity pool/provider trusting GitHub's OIDC tokens, and grant the CI's federated identity `roles/iam.workloadIdentityUser` on a dedicated service account, with no long-lived key ever created or stored.

---

## 4.2 Pre-Apply Checks & Validation (Comprehensive)

```bash
# Formatting & syntax
terraform fmt -check -recursive -diff
terraform validate

# Linting (catches style + provider-specific issues fmt/validate miss)
tflint --init
tflint --recursive

# Security scanning
tfsec .
checkov -d . --framework terraform

# Cost estimation (see 4.4)
infracost breakdown --path .

# Policy-as-code gate (see 3.4)
terraform show -json tfplan > plan.json
conftest test plan.json -p policy/
```

A typical merged pre-apply gate in CI: `fmt` → `validate` → `tflint` → `tfsec`/`checkov` → `plan` → `infracost` comment on PR → `conftest` policy check → manual approval → `apply`. Any failing step blocks the merge, catching cost, security, and correctness issues before they ever touch a real GCP project.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Pre-apply checks form a layered defense, each catching a different *class* of problem: `fmt`/`validate` catch syntax issues; `tflint` catches style and provider-specific correctness issues; `tfsec`/`checkov` catch security misconfigurations; `infracost` catches cost surprises; `conftest`/OPA catches organizational policy violations. No single tool covers all these classes, which is why a mature pipeline chains several.

**Trade-offs:** Running every check on every commit maximizes safety but slows PR feedback loops; a common compromise is running fast static checks on every push and reserving expensive/noisy checks (full security scans, cost estimation against a real API) for pre-merge or scheduled runs.

**Likely interview questions:**
- *"What's the difference between what `terraform validate` and `tflint` each catch?"* — `validate` only checks internal HCL syntax/consistency (e.g., referencing an undeclared variable); `tflint` additionally checks provider-specific best practices and deprecated/invalid field values that `validate` has no opinion on.
- *"How would you structure a CI gate so that a PR can't merge if it introduces a security misconfiguration?"* — Add a `tfsec`/`checkov` step that fails the build (non-zero exit code) on HIGH/CRITICAL findings, wired as a required status check in the repository's branch protection rules.

---

## 4.3 Testing Terraform (Unit, Integration, Contract)

**Unit-level (`terraform test`, plan-only, no real resources created)** — shown in 3.1.

**Integration testing with Terratest (Go)** — actually applies to a sandbox GCP project, asserts, then destroys:
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestGCSBucketModule(t *testing.T) {
    opts := &terraform.Options{
        TerraformDir: "../modules/gcs-bucket",
        Vars: map[string]interface{}{
            "project_id":  "my-sandbox-project",
            "bucket_name": "terratest-bucket-12345",
        },
    }
    defer terraform.Destroy(t, opts)
    terraform.InitAndApply(t, opts)

    bucketURL := terraform.Output(t, opts, "bucket_url")
    assert.Contains(t, bucketURL, "terratest-bucket-12345")
}
```
```bash
cd test && go test -v -timeout 30m
```

**Contract testing** for modules published to a private registry: consumers pin `source`/`version`, and the module repo's CI runs the full test suite (`terraform test` + Terratest + `tflint`) against every tagged release, guaranteeing that `v2.3.0` behaves as documented before any team upgrades to it.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** The testing pyramid applies to Terraform just as it does to application code: many fast, cheap unit/plan-based tests at the base, fewer slower integration tests (real `apply`) above that, and the fewest, slowest full end-to-end/contract tests at the top. Skipping straight to "just apply it in a sandbox and see" for everything is the Terraform equivalent of having only end-to-end tests in application code — slow feedback and expensive to maintain.

**Trade-offs:** Integration tests (Terratest) genuinely catch things plan-only tests cannot (a permission that's actually missing, a quota that's actually exceeded) — but they cost real money and time per run, and require rigorous cleanup discipline to avoid leaking orphaned sandbox resources.

**Likely interview questions:**
- *"Why might a Terraform module pass `terraform validate` and `terraform test` (plan-only) but still fail on a real `apply`?"* — Plan-only tests can't catch issues that only surface from real API calls — insufficient IAM permissions, quota limits, or GCP-side validation errors that don't show up until the actual `Create` RPC is attempted.
- *"How do you keep Terratest-based integration tests from leaving orphaned resources if a test fails?"* — Use `defer terraform.Destroy(t, opts)` immediately after `InitAndApply`, so cleanup runs even if an assertion later in the test fails or panics.

---

## 4.4 Cost Estimation & Monitoring (Infracost Deep Dive)

```bash
infracost breakdown --path . --format table
```
```yaml
# GitHub Actions: post cost diff as a PR comment
- name: infracost
  uses: infracost/actions/comment@v3
  with:
    path: infracost-plan.json
    behavior: update
```
```bash
infracost diff --path . --compare-to infracost-base.json
```

Example output shape (illustrative):
```
Project: infra/prod

 Name                                Monthly Qty  Unit Price  Monthly Cost
 google_compute_instance.app
 ├─ Instance usage (n2-standard-4)      730 hours     $0.194        $141.62
 └─ Standard boot disk (pd-ssd, 50GB)    50 GB          $0.17         $8.50

 google_sql_database_instance.prod
 └─ db-custom-4-16384 (REGIONAL)        730 hours     $0.657        $479.61

 OVERALL TOTAL                                                      $629.73
```

Pair Infracost with **GCP Budgets & Alerts** (also Terraform-managed) so estimated *and* actual spend are both governed as code:
```hcl
resource "google_billing_budget" "prod_budget" {
  billing_account = var.billing_account_id
  display_name    = "prod-monthly-budget"

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "5000"
    }
  }

  threshold_rules { threshold_percent = 0.5 }
  threshold_rules { threshold_percent = 0.9 }
  threshold_rules { threshold_percent = 1.0 }

  all_updates_rule {
    monitoring_notification_channels = [google_monitoring_notification_channel.slack.id]
  }
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Cost estimation tools like Infracost work by mapping planned resource *changes* (from `terraform plan`'s JSON output) to known cloud pricing data, computing a cost delta *before* anything is actually provisioned — shifting cost awareness from "surprise on next month's bill" to "visible in the PR that caused it," the same shift-left principle applied to security and correctness elsewhere in this guide.

**Trade-offs:** Static cost estimation can't account for usage-based costs that depend on runtime behavior (e.g., actual Cloud Run request volume, actual egress traffic) — it estimates the *provisioned capacity* cost accurately, but variable/usage-based costs still require actual billing data and budgets/alerts (6.6) as a complementary control.

**Likely interview questions:**
- *"What can Infracost estimate accurately, and what can't it?"* — It estimates costs tied directly to provisioned resource configuration (instance type, disk size, reserved capacity); it can't accurately predict usage-based costs that depend on runtime traffic/behavior, like actual Cloud Run invocation volume or network egress.
- *"How would you prevent a PR from silently introducing a large recurring cost increase?"* — Post an Infracost diff as a required PR comment/check, optionally failing the build if the delta exceeds a configured threshold, so cost impact is visible and reviewable before merge.

---

## 4.5 NEW: Testing Frameworks & Tooling

| Tool | Purpose | Layer |
|---|---|---|
| `terraform validate` | Syntax/internal consistency | Static |
| `tflint` | Style + provider-specific lint rules (e.g., deprecated GCP fields) | Static |
| `terraform test` | Native unit/plan-based assertions | Unit |
| Terratest | Real apply + assert + destroy in Go | Integration |
| `kitchen-terraform` | BDD-style integration tests (RSpec-like) | Integration |
| `tfsec` / `checkov` | Security misconfiguration scanning | Static security |
| `conftest` (OPA) | Custom policy assertions on plan JSON | Policy |
| Infracost | Cost delta per PR | Cost |

```hcl
# Example .tflint.hcl targeting GCP-specific rules
plugin "google" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

rule "google_compute_instance_invalid_machine_type" {
  enabled = true
}
```

A well-built pipeline runs the cheap/fast checks (`fmt`, `validate`, `tflint`) on every commit, and the expensive ones (Terratest against a real sandbox project) only on merge to `main` or nightly, to keep PR feedback loops fast.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Each tool in the testing/tooling table targets a distinct failure mode, and understanding *which layer* a given class of bug lives in is what lets you pick the right tool rather than reflexively reaching for "more tests." A missing required label is a policy problem (OPA/Sentinel), not a security problem (tfsec) or a correctness problem (validate) — using the wrong tool for the wrong class of check either misses the issue or produces noisy, irrelevant failures.

**Trade-offs:** Adopting the full tool matrix (validate, tflint, terraform test, Terratest, tfsec/checkov, conftest, Infracost) is comprehensive but represents real setup and maintenance overhead — smaller teams often start with just `fmt`/`validate`/`tflint`/`tfsec` and add the rest as the codebase and team size grow.

**Likely interview questions:**
- *"If you could only add two automated checks to a Terraform CI pipeline that currently has none, which would you pick and why?"* — `terraform validate`/`fmt` (near-zero cost, catches basic mistakes) and `tfsec`/`checkov` (catches security misconfigurations, historically the highest-impact class of Terraform-introduced incident) are a strong minimal starting pair.
- *"What's a `tflint` ruleset plugin, and why would you need one for GCP specifically?"* — A plugin (e.g., `tflint-ruleset-google`) that adds provider-specific lint rules beyond generic HCL style — for example, flagging a deprecated or invalid GCP machine type that core `tflint` has no knowledge of.

---

## 4.6 NEW: Automated Compliance & Policy Testing

Combine `checkov` (canned compliance rulesets: CIS GCP Benchmark, PCI-DSS, HIPAA) with custom `conftest`/OPA rules for org-specific policy:

```bash
checkov -d . --framework terraform --check CKV_GCP_29,CKV_GCP_62 --compact
```
- `CKV_GCP_29`: ensure GCS bucket has uniform bucket-level access.
- `CKV_GCP_62`: ensure GCS bucket has versioning enabled.

```yaml
# CI stage: fail build on any HIGH/CRITICAL finding
- name: Checkov scan
  run: checkov -d infra --framework terraform --compact --quiet --soft-fail-on LOW,MEDIUM
```

For continuous (post-deploy) compliance — not just pre-apply — pair with **Security Command Center** (GCP's native CSPM), which flags drift into non-compliant states (e.g., a firewall rule opened to `0.0.0.0/0` by someone with direct `gcloud` access) even outside the Terraform pipeline, closing the loop that static pre-apply scanning alone cannot cover.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Compliance scanning tools like Checkov encode well-known benchmarks (CIS GCP Benchmark, PCI-DSS, HIPAA) as pre-built rule sets, so teams don't have to independently research and hand-write every individual compliance requirement — but pre-built rules cover *generic* industry practice, while custom OPA/conftest rules capture *organization-specific* policy (your particular label schema, your particular allowed machine types) that no generic tool could know about.

**Trade-offs:** Pre-apply static compliance scanning (Checkov) only covers changes that go through Terraform; ongoing runtime compliance monitoring (Security Command Center) is needed to catch configuration drift into non-compliant states from any source, including changes made entirely outside Terraform.

**Likely interview questions:**
- *"What's the difference between Checkov's built-in checks and a custom conftest/OPA policy?"* — Checkov's built-in checks encode generic, widely-recognized security/compliance benchmarks applicable across most organizations; custom OPA policies encode your organization's specific, often idiosyncratic rules (e.g., a specific mandatory label schema) that no generic tool ships with by default.
- *"How do you catch a compliance violation that happens outside of any Terraform pipeline entirely?"* — Static pre-apply scanning can't see it; you need a continuously-running platform-level tool like Security Command Center that evaluates the actual live GCP configuration against policy, regardless of how it got that way.

---

# SECTION 5: REAL-WORLD SCENARIOS

## 5.1 Blue/Green Infrastructure Rollout (Zero-Downtime)

Using **Managed Instance Groups (MIGs)** with instance templates + a load balancer, swapping traffic via `create_before_destroy`:

```hcl
resource "google_compute_instance_template" "app_v2" {
  name_prefix  = "app-v2-"
  machine_type = "n2-standard-4"

  disk {
    source_image = "projects/my-project/global/images/app-image-v2"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = google_compute_network.vpc.id
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "app" {
  name               = "app-mig"
  base_instance_name = "app"
  region             = "us-central1"
  target_size        = 6

  version {
    instance_template = google_compute_instance_template.app_v2.id
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 3   # spin up 3 new (green) before killing old
    max_unavailable_fixed = 0   # never drop below target capacity
  }

  named_port {
    name = "http"
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.app.id
    initial_delay_sec = 60
  }
}

resource "google_compute_health_check" "app" {
  name = "app-health-check"
  http_health_check { port = 8080; request_path = "/healthz" }
}
```
Changing `instance_template` and re-applying triggers a rolling **blue→green** replacement: new (green) VMs boot, pass health checks, and only then are old (blue) VMs drained and removed — zero downtime, fully declarative.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Blue/green rollout via `max_surge`/`max_unavailable` on a Managed Instance Group works because Terraform's `create_before_destroy` lifecycle setting, combined with GCP's own rolling-update mechanics, ensures new ("green") capacity is verified healthy *before* old ("blue") capacity is removed — the zero-downtime guarantee comes from never dropping below the target serving capacity at any point during the transition, not from any special "blue/green" primitive (GCP MIGs don't have a distinct blue/green concept — it's expressed via surge/unavailable settings).

**Trade-offs:** `max_surge` above zero means paying for extra (temporarily doubled) capacity during rollouts; `max_unavailable_fixed = 0` guarantees no capacity drop but makes the rollout strictly dependent on new instances passing health checks — a broken new image will stall the rollout indefinitely rather than degrading service, which is the desired trade-off for production but can surprise teams expecting a faster (riskier) update.

**Likely interview questions:**
- *"How do you achieve a true zero-downtime rollout on GCP without a dedicated 'blue/green' Terraform resource type?"* — Configure the Managed Instance Group's `update_policy` with `max_surge_fixed` > 0 and `max_unavailable_fixed = 0`, so new instances are created and pass health checks before any old instances are removed.
- *"What happens if a new instance template's image is broken and fails health checks mid-rollout?"* — With `max_unavailable_fixed = 0`, GCP won't remove old healthy instances until new ones pass health checks — a broken image stalls the rollout (visible via `auto_healing_policies` and MIG status) rather than causing an outage, and can be rolled back by reverting the instance template.

---

## 5.2 Multi-Region Failover & HA (Complete Implementation)

```hcl
resource "google_compute_global_address" "app_ip" {
  name = "app-global-ip"
}

resource "google_compute_backend_service" "app" {
  name                  = "app-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_instance_group_manager.us_central1.instance_group
  }
  backend {
    group = google_compute_region_instance_group_manager.europe_west1.instance_group
  }

  health_checks = [google_compute_health_check.app.id]

  # Automatic failover: GCP routes to the next-healthiest region if one fails
  outlier_detection {
    consecutive_errors = 5
  }
}

resource "google_compute_url_map" "app" {
  name            = "app-url-map"
  default_service = google_compute_backend_service.app.id
}

resource "google_compute_target_http_proxy" "app" {
  name    = "app-http-proxy"
  url_map = google_compute_url_map.app.id
}

resource "google_compute_global_forwarding_rule" "app" {
  name       = "app-forwarding-rule"
  target     = google_compute_target_http_proxy.app.id
  port_range = "80"
  ip_address = google_compute_global_address.app_ip.address
}

# Regional Cloud SQL with cross-region read replica for HA/DR
resource "google_sql_database_instance" "primary" {
  name             = "prod-db-primary"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  settings {
    tier              = "db-custom-8-32768"
    availability_type = "REGIONAL"
  }
}

resource "google_sql_database_instance" "replica" {
  name                 = "prod-db-replica-europe"
  region               = "europe-west1"
  database_version     = "POSTGRES_15"
  master_instance_name = google_sql_database_instance.primary.name
  replica_configuration {
    failover_target = false
  }
  settings { tier = "db-custom-8-32768" }
}
```
A single **Global HTTP(S) Load Balancer** (anycast IP) fronts backends in two regions; GCP's outlier detection automatically stops routing to an unhealthy region without any manual DNS failover step.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** GCP's Global HTTP(S) Load Balancer uses a single **anycast IP** that Google's edge network routes to the nearest healthy backend — this is fundamentally different from DNS-based multi-region failover (common on other platforms), which relies on DNS TTL expiry and client re-resolution to redirect traffic, introducing propagation delay. Anycast + `outlier_detection` gives near-instant failover without waiting for any DNS cache to expire.

**Trade-offs:** The Global Load Balancer's simplicity (one IP, automatic regional failover) trades off against finer per-region traffic control that some DNS-based multi-region setups offer (e.g., weighted geo-routing with fine-grained percentage splits) — GCP does offer this via backend service traffic policies, but it's a more advanced configuration than the default nearest-healthy-region routing.

**Likely interview questions:**
- *"Why is GCP's Global Load Balancer failover faster than typical DNS-based multi-region failover?"* — It uses a single anycast IP with health-check-driven routing at Google's network edge, so failover happens at the network layer instantly, without waiting for DNS TTLs to expire and clients to re-resolve.
- *"How would you design a Cloud SQL setup for cross-region disaster recovery?"* — A regional primary with `REGIONAL` (HA) availability for intra-region failover, plus a cross-region read replica that can be promoted to a standalone primary (failover target) in a true regional outage — combined with automated backups and point-in-time recovery for additional protection.

---

## 5.3 Secure Team Onboarding (Automated Provisioning)

```hcl
variable "engineers" {
  type = map(object({
    email = string
    role  = string # "developer" | "sre" | "readonly"
  }))
}

locals {
  role_map = {
    developer = "roles/editor"
    sre       = "roles/owner"
    readonly  = "roles/viewer"
  }
}

resource "google_project_iam_member" "engineer_access" {
  for_each = var.engineers
  project  = var.project_id
  role     = local.role_map[each.value.role]
  member   = "user:${each.value.email}"
}

resource "google_service_account" "engineer_sa" {
  for_each     = { for k, v in var.engineers : k => v if v.role == "sre" }
  account_id   = "sre-${each.key}"
  display_name = "SRE service account for ${each.value.email}"
}
```
```yaml
# .tfvars-driven onboarding — a PR adding a new engineer to this map
# is reviewed, merged, and CI applies it automatically
engineers = {
  jsmith = { email = "jsmith@example.com", role = "developer" }
  agarcia = { email = "agarcia@example.com", role = "sre" }
}
```
Pairing this with Google Groups (assign IAM to a group, manage group membership in a HR/IdP-synced system) scales far better than per-user Terraform resources for large orgs — Terraform then only manages the group-to-role bindings, not individual employee churn.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Automating team onboarding via Terraform turns access provisioning into the same reviewed, auditable, versioned process as any other infrastructure change — a new engineer's access request becomes a PR with a clear diff (exactly which role, on which project) rather than an ad-hoc Console click that leaves no structured record of who approved it or why.

**Trade-offs:** Managing individual users directly in Terraform (`for_each` over a map of engineers) works well for small teams but scales poorly for large orgs with high turnover — at scale, Terraform should manage *group-to-role* bindings only, delegating individual membership churn to an IdP-synced Google Group, since re-`apply`-ing Terraform for every hire/departure becomes an operational bottleneck.

**Likely interview questions:**
- *"Why might managing individual engineer IAM bindings directly in Terraform become a problem at scale?"* — High employee turnover means frequent `.tfvars`/config changes just to keep membership current, creating pipeline noise unrelated to actual infrastructure changes; binding to Google Groups (synced from an IdP) instead lets Terraform manage stable group-to-role mappings while membership changes happen outside Terraform's change cadence.
- *"What's the benefit of a PR-based access request over a direct Console IAM grant?"* — It creates a reviewable, auditable record (who requested it, who approved it, exactly what permission) tied to version control history, rather than a Console action visible only in Cloud Audit Logs without the surrounding approval context.

---

## 5.4 Tagging Strategy & Compliance (Enforcement Rules)

GCP calls these **labels** (not "tags" like AWS — GCP does have a separate lightweight "tags" feature for firewall/network targeting, distinct from labels used for cost/ownership metadata).

```hcl
locals {
  mandatory_labels = {
    environment = var.environment
    owner       = var.team_email
    cost-center = var.cost_center
    managed-by  = "terraform"
  }
}

resource "google_compute_instance" "app" {
  name         = "app"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  labels       = local.mandatory_labels
  boot_disk { initialize_params { image = "debian-cloud/debian-12" } }
  network_interface { network = "default" }
}
```

Enforce via **Org Policy** + CI policy gate (3.4) rather than hoping every engineer remembers:
```rego
package terraform.labels

required := {"environment", "owner", "cost-center", "managed-by"}

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "google_compute_instance"
  provided := {k | rc.change.after.labels[k]}
  missing := required - provided
  count(missing) > 0
  msg := sprintf("%s is missing required labels: %v", [rc.address, missing])
}
```
Use labels downstream for **BigQuery billing export** cost breakdowns by `cost-center`, and for automated cleanup scripts (e.g., delete anything labeled `environment=dev` and older than 14 days via a scheduled Cloud Function).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Consistent labeling is what makes downstream automation (cost attribution, cleanup scripts, compliance reporting) possible at all — a label schema is only as useful as its *consistency*; a single unlabeled resource breaks a `GROUP BY cost_center` billing query or a "delete all dev resources older than 14 days" cleanup script silently skipping that resource.

**Trade-offs:** Enforcing mandatory labels via policy-as-code (rejecting any plan missing them) is stricter and more reliable than a README convention or code review reminder, but requires the policy tooling investment from 3.4/4.6 to actually be in place — without it, "mandatory" labels are really just a suggestion.

**Likely interview questions:**
- *"What's the difference between GCP 'labels' and GCP 'tags,' and when would you use each?"* — Labels are general-purpose key-value metadata used for cost attribution, organization, and filtering across most resource types; (network) tags are a narrower feature specifically used for targeting firewall rules and routes to particular Compute Engine instances — they're not interchangeable.
- *"How would you guarantee every resource in a GCP project has required cost-attribution labels, without relying on developers remembering?"* — A policy-as-code gate (OPA/Sentinel) that inspects the Terraform plan and fails the build if any resource is missing the mandatory label set, enforced as a required CI check rather than a manual review step.

---

## 5.5 Local Development Setup & IDE (Professional Setup)

```bash
# Recommended local toolchain
brew install terraform tflint tfsec infracost gcloud-cli
gcloud auth application-default login   # ADC for local plan/apply against a dev project

# .terraform-version (tfenv) for team-wide version consistency
echo "1.7.5" > .terraform-version
```

VS Code setup (`.vscode/settings.json`):
```json
{
  "editor.formatOnSave": true,
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  },
  "terraform.languageServer": { "enable": true }
}
```

Recommended extensions: **HashiCorp Terraform** (official LSP — real-time validation, autocomplete for `google` provider schema), **GitLens**, **Google Cloud Code** (integrated `gcloud`/GKE tooling alongside Terraform).

```bash
# Pre-commit hook to catch issues before they even reach CI
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.88.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_tfsec
EOF
pre-commit install
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Local dev environment consistency (pinned Terraform version via `tfenv`, shared lint/format config, pre-commit hooks) exists to catch the *cheapest* class of mistakes — formatting, obvious syntax errors, basic security misconfigurations — before they even reach a CI pipeline, saving both CI compute time and PR review cycles for issues that actually need human judgment.

**Trade-offs:** Pre-commit hooks add a small amount of friction to every local commit (a few extra seconds running `fmt`/`validate`/`tflint`) — a worthwhile trade for most teams, but one that can frustrate contributors if the hooks are slow or flaky, which is why the pre-commit checks should mirror (be a strict subset of) the fast CI checks, not duplicate the expensive ones.

**Likely interview questions:**
- *"Why use Application Default Credentials (`gcloud auth application-default login`) for local Terraform development instead of a service account key file?"* — ADC avoids creating and distributing a long-lived downloadable key for local use, ties access to the individual engineer's own (revocable, auditable) identity, and is automatically picked up by the Google Terraform provider without extra configuration.
- *"What's the purpose of pinning a Terraform CLI version with something like `tfenv` across a team?"* — To ensure every engineer (and CI) runs the exact same Terraform core version, preventing subtle behavior differences between versions from causing "works on my machine" plan/apply inconsistencies.

---

## 5.6 Migration Strategies & Refactoring (Phase-by-Phase)

**Phase 1 — Inventory & Import (weeks 1-2):**
```bash
gcloud asset search-all-resources --project=my-project --format=json > inventory.json
```
Write HCL skeletons for the highest-value/highest-risk resources first (production databases, load balancers), import them, verify zero-diff plans.

**Phase 2 — Modularize (weeks 3-4):** extract repeated patterns (every microservice's Cloud Run service + IAM binding) into a shared module; refactor root config to call it, using `moved` blocks to avoid destroy/recreate.

**Phase 3 — Guardrails (weeks 5-6):** add `prevent_destroy` on stateful resources, wire up CI plan/apply gates (4.1), add policy-as-code (3.4).

**Phase 4 — Decommission manual access (week 7+):** remove Console/`gcloud` write IAM roles from individual engineers on Terraform-managed projects; all changes now flow through PRs.

```hcl
# Example moved block during Phase 2 modularization
moved {
  from = google_cloud_run_v2_service.orders_api
  to   = module.orders_service.google_cloud_run_v2_service.api
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Phased migration to Terraform (inventory → import → modularize → guardrails → decommission manual access) mirrors general software migration best practice — never attempt a "big bang" cutover of your entire infrastructure management model at once. Each phase produces a stable, working intermediate state, so if something goes wrong, you're debugging one phase's worth of change, not the entire migration simultaneously.

**Trade-offs:** A phased migration takes considerably longer than attempting to import everything at once, but each incremental phase is independently verifiable (zero-diff `plan` after each import batch) — the time cost buys a dramatically lower risk of a migration-induced outage or silent misconfiguration.

**Likely interview questions:**
- *"Why import resources in small batches rather than all at once during a Terraform adoption project?"* — Each batch can be independently verified with a zero-diff `plan` before moving on; importing everything at once makes it much harder to isolate which specific resource's HCL doesn't match reality if the overall plan shows unexpected changes.
- *"What's the last step in migrating a legacy project to Terraform, and why is it often skipped?"* — Removing direct Console/`gcloud` write access from individual engineers so all future changes are forced through Terraform/CI — it's often skipped because it's organizationally uncomfortable, but without it, the project silently drifts back into unmanaged, undocumented changes over time.

---

## 5.7 Common Pitfalls & Solutions (Comprehensive)

| Pitfall | Solution |
|---|---|
| Bucket/global-name collisions (GCS bucket names are globally unique across *all* GCP projects) | Prefix with project ID or org-unique string; use `random_id` suffix for ephemeral envs |
| Forgetting to enable an API before referencing its resource | Always declare `google_project_service` + `depends_on` |
| One giant monolithic state | Split by layer/environment (3.3) |
| Hardcoded zone/region breaking DR | Parameterize via variables, use regional resources where possible |
| Secrets committed in `.tfvars` | Secret Manager + `.gitignore` on `*.tfvars` with real values |
| `count` causing cascading replacements | Switch to `for_each` with stable keys |
| No `plan` review before `apply` in CI | Enforce required PR approval + `plan` artifact promotion (4.1) |
| IAM drift from manual Console grants | Import existing bindings, restrict Console IAM edit access |

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Nearly every entry in a "common pitfalls" list traces back to one of a small number of root causes covered elsewhere in this guide: insufficient state isolation (3.3), missing lifecycle guards (1.10, 2.2), or a mismatch between Terraform's model and a genuinely global GCP namespace (GCS bucket names). Recognizing the *underlying category* of a pitfall (rather than memorizing each one individually) is what lets you anticipate novel pitfalls this list doesn't cover.

**Trade-offs:** Defending against every pitfall preemptively (aggressive `prevent_destroy`, strict `for_each` everywhere, mandatory policy gates on day one) adds ceremony that may not be justified for a small early-stage project — the practical approach is to add these guardrails as the project's blast radius and team size grow, not necessarily from day one.

**Likely interview questions:**
- *"Why are GCS bucket naming collisions a uniquely tricky pitfall compared to most other GCP resources?"* — GCS bucket names are globally unique across *all* GCP projects and customers, not just within your own project — a name that's free in your dev project might already be taken globally, unlike most resources which are only unique within their own project/region scope.
- *"What's a practical way to avoid `count`-driven cascading resource replacement?"* — Default to `for_each` with a stable key (a map or set) instead of `count` for any list of resources that might be reordered or have items removed from the middle, reserving `count` for simple 0-or-1 conditionals or truly interchangeable, unordered resource sets.

---

## 5.8 NEW: Disaster Recovery & Business Continuity

```hcl
# Automated Cloud SQL backups + cross-region replica (see 5.2) for RPO/RTO targets
resource "google_sql_database_instance" "primary" {
  name             = "prod-db"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  settings {
    tier = "db-custom-8-32768"
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      backup_retention_settings {
        retained_backups = 30
      }
    }
  }
}

# GCS bucket replication for DR of static assets/state
resource "google_storage_bucket" "assets_primary" {
  name     = "my-app-assets-us"
  location = "US"
  storage_class = "STANDARD"
}

resource "google_storage_transfer_job" "dr_replication" {
  description = "Replicate assets to DR region nightly"
  transfer_spec {
    gcs_data_source { bucket_name = google_storage_bucket.assets_primary.name }
    gcs_data_sink   { bucket_name = google_storage_bucket.assets_dr.name }
  }
  schedule {
    schedule_start_date { year = 2026; month = 1; day = 1 }
    start_time_of_day   { hours = 3; minutes = 0; seconds = 0; nanos = 0 }
  }
}
```
A DR runbook should also include a **Terraform-based recovery plan**: the entire prod stack must be re-`apply`-able into a brand-new GCP project from code alone within the target RTO — this is tested periodically via a full `apply` into a scratch project ("DR game day"), not assumed.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** DR planning distinguishes between **RPO** (Recovery Point Objective — how much data loss is acceptable, driven by backup/replication frequency) and **RTO** (Recovery Time Objective — how long recovery is allowed to take, driven by how quickly infrastructure and data can actually be restored) — Terraform's role is specifically in the RTO side (can the entire stack be re-`apply`-ed into a fresh project quickly), while backup/replication configuration (point-in-time recovery, cross-region replicas) addresses the RPO side.

**Trade-offs:** More frequent backups and lower-latency cross-region replication reduce RPO but increase both cost (storage, cross-region egress) and complexity (replication lag monitoring) — the right RPO/RTO targets should be driven by actual business requirements, not maximized by default, since near-zero RPO/RTO is achievable but often disproportionately expensive relative to the actual cost of an outage.

**Likely interview questions:**
- *"What's the difference between RPO and RTO, and which does a cross-region Cloud SQL read replica primarily address?"* — RPO is acceptable data loss (time since last consistent backup/replica); RTO is acceptable downtime during recovery. A cross-region read replica primarily improves RTO (faster failover, no restore-from-backup wait) and secondarily improves RPO if replication lag is low.
- *"Why is a periodic 'DR game day' (actually re-applying the full stack into a scratch project) important, beyond just having the Terraform code exist?"* — Untested DR procedures routinely fail in real incidents due to stale assumptions (missing manual steps, expired credentials, an undocumented dependency) — a game day validates that the *actual* recovery process works end-to-end within the target RTO, not just that the code theoretically could.

---

## 5.9 NEW: Performance Optimization

**Terraform execution performance:**
```bash
# Parallelism tuning (default 10) — raise for large graphs, lower to avoid API rate limits
terraform apply -parallelism=20

# Targeted apply during incident response (use sparingly)
terraform apply -target=google_compute_instance.app
```
```hcl
# Reduce plan/refresh time via data source caching — avoid data sources inside for_each
# loops that each make a separate API call when a single lookup would do.
data "google_compute_zones" "available" {
  region = "us-central1"
}
```

**Infrastructure performance** (GCP-side): use **regional Managed Instance Groups** with autoscaling based on custom Cloud Monitoring metrics, not just CPU:
```hcl
resource "google_compute_region_autoscaler" "app" {
  name   = "app-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.app.id

  autoscaling_policy {
    max_replicas    = 20
    min_replicas    = 3
    cooldown_period = 60

    metric {
      name   = "custom.googleapis.com/queue/depth"
      target = 100
      type   = "GAUGE"
    }
  }
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Terraform-execution performance (plan/apply speed) and infrastructure-runtime performance (application autoscaling) are two entirely separate concerns often conflated under "performance" — the former is about how fast *you* can iterate on infrastructure changes; the latter is about how well the *deployed infrastructure* responds to real traffic. Optimizing one doesn't address the other.

**Trade-offs:** Raising `-parallelism` speeds up Terraform's own execution but can trigger GCP API rate limits if pushed too high, especially against quota-constrained APIs — the right value is workload- and quota-dependent, not a universal constant; similarly, autoscaling on a custom metric (like queue depth) reacts more precisely to actual load than CPU-based autoscaling, but requires that custom metric to be reliably published to Cloud Monitoring in the first place.

**Likely interview questions:**
- *"Your `terraform plan` takes 10 minutes on a large configuration. What are your options to speed it up?"* — Increase `-parallelism` if the bottleneck is provider API round-trips (not exceeding quota), split the monolithic state into smaller layers (3.3) so each `plan` only touches a fraction of total resources, and avoid unnecessary data source lookups inside large `for_each` loops.
- *"Why might CPU-based autoscaling be insufficient for a queue-processing workload?"* — CPU usage doesn't necessarily correlate with actual backlog/urgency — a queue-processing service could have low CPU usage while backlog grows if each message is I/O-bound; autoscaling on a custom queue-depth metric responds to the metric that actually reflects load.

---

## 5.10 NEW: Monitoring, Alerting & Observability

```hcl
resource "google_monitoring_notification_channel" "slack" {
  display_name = "platform-alerts-slack"
  type         = "slack"
  labels       = { channel_name = "#platform-alerts" }
}

resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High 5xx rate - app backend"
  combiner      = "OR"

  conditions {
    display_name = "5xx ratio > 5%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.label.response_code_class=\"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.05
      duration        = "300s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.slack.id]
}

resource "google_monitoring_dashboard" "platform" {
  dashboard_json = jsonencode({
    displayName = "Platform Overview"
    gridLayout = {
      widgets = [
        {
          title = "Request Latency (p99)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_latencies\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}
```
Combine Cloud Monitoring (metrics/alerting) with **Cloud Trace** (distributed tracing) and **Cloud Logging** log-based metrics, all declared in Terraform so the entire observability stack ships alongside the infrastructure it monitors, versioned in the same PR.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Declaring observability (dashboards, alert policies, notification channels) in Terraform alongside the infrastructure it monitors means the monitoring configuration ships in the *same PR* as the infrastructure change that might need it — a new Cloud Run service and its error-rate alert policy are reviewed and deployed together, rather than the alert being an afterthought added (or forgotten) after an incident already occurred without one.

**Trade-offs:** Terraform-managed alert policies are versioned and reviewable, but iterating on alert *thresholds* (tuning to reduce false positives) via a full PR/plan/apply cycle is slower than adjusting a threshold directly in the Cloud Monitoring UI — many teams tolerate direct UI tuning for alert thresholds specifically, then periodically reconcile the tuned values back into Terraform to avoid permanent drift.

**Likely interview questions:**
- *"What's the benefit of declaring a Cloud Monitoring alert policy in Terraform instead of configuring it manually in the Console after deploying a service?"* — It guarantees the alert exists from day one (reviewed in the same PR as the service), is reproducible if the environment needs to be rebuilt, and is auditable/versioned rather than living only as an undocumented manual Console configuration.
- *"How would you correlate a Cloud Monitoring alert with the actual root cause during an incident?"* — Combine metrics (Cloud Monitoring, what/when) with distributed tracing (Cloud Trace, which request/service) and structured logs (Cloud Logging, why) — metrics alone tell you something is wrong, but tracing and logs are usually needed to pinpoint the actual cause.

---

# SECTION 6: ENTERPRISE OPERATIONS

## 6.1 Terraform Cloud/Enterprise Deep Dive

Building on 1.9, enterprise TFC/TFE usage centers on **workspaces-as-a-service**: each app/environment gets a TFC workspace tied to a VCS repo, with variables, policy sets, and run triggers configured centrally.

```hcl
# Managing TFC itself via the tfe provider (meta!)
terraform {
  required_providers {
    tfe = { source = "hashicorp/tfe" }
  }
}

resource "tfe_workspace" "prod_gke" {
  name              = "gcp-prod-gke"
  organization      = "my-org"
  working_directory = "envs/prod/gke"
  vcs_repo {
    identifier     = "my-org/infra"
    branch         = "main"
    oauth_token_id = var.vcs_oauth_token_id
  }
  auto_apply = false
}

resource "tfe_variable" "gcp_project" {
  key          = "TF_VAR_project_id"
  value        = "my-prod-project"
  category     = "terraform"
  workspace_id = tfe_workspace.prod_gke.id
}

resource "tfe_run_trigger" "network_to_gke" {
  workspace_id    = tfe_workspace.prod_gke.id
  sourceable_id   = tfe_workspace.prod_network.id
  sourceable_type = "workspace"
}
```
Run triggers ensure the GKE workspace automatically plans a new run whenever the upstream network workspace applies successfully — encoding the layered dependency from 3.3 directly into the platform rather than manual coordination.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Run triggers encode *cross-stack dependency* directly into the platform (TFC) rather than relying on humans remembering "if I change networking, I also need to re-run the GKE pipeline" — this closes a real gap in the hierarchical state pattern from 3.3, where remote-state consumption is passive (the consuming stack only picks up changes the *next* time it happens to run) unless something actively triggers that next run.

**Trade-offs:** Run triggers add implicit coupling between workspaces that isn't always obvious from looking at a single workspace's configuration alone — a chain of triggered runs across many workspaces can be harder to reason about than an explicit, manually-sequenced pipeline, especially during a complex multi-layer rollout where ordering matters precisely.

**Likely interview questions:**
- *"What problem do TFC run triggers solve that plain `terraform_remote_state` doesn't?"* — `terraform_remote_state`/`tfe_outputs` only reads the upstream state's *current* values whenever the consuming workspace happens to run; run triggers proactively kick off a new run in the dependent workspace as soon as the upstream workspace successfully applies, closing the propagation gap.
- *"What's a risk of relying heavily on chained run triggers across many workspaces?"* — A single upstream apply can cascade into many automatically-triggered downstream runs, making the full blast radius of one change harder to predict/review than an explicitly sequenced, manually-approved pipeline.

---

## 6.2 Governance & Policy Enforcement

```hcl
resource "tfe_policy_set" "gcp_guardrails" {
  name         = "gcp-guardrails"
  organization = "my-org"
  kind         = "sentinel"
  vcs_repo {
    identifier     = "my-org/policy-library"
    oauth_token_id = var.vcs_oauth_token_id
  }
  workspace_ids = [tfe_workspace.prod_gke.id, tfe_workspace.prod_network.id]
}

resource "tfe_policy_set_parameter" "max_instance_count" {
  key           = "max_instance_count"
  value         = "50"
  policy_set_id = tfe_policy_set.gcp_guardrails.id
}
```
Layer this with GCP **Organization Policy Constraints** (3.5) so governance is enforced at *two* levels: Sentinel/OPA blocks bad `plan`s before `apply`, and Org Policy blocks the underlying GCP API call itself even if something bypasses Terraform entirely (e.g., a `gcloud` command run by an admin).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Layering Sentinel/OPA (blocks bad *plans*) with GCP Org Policy (blocks bad *API calls* regardless of origin) creates defense in depth — the first layer catches issues early and gives fast, specific feedback in the PR/run; the second layer is the backstop that still holds even if something bypasses Terraform's pipeline entirely (a compromised credential running raw `gcloud`, for instance).

**Trade-offs:** Maintaining two separate policy systems (Sentinel/OPA rules and GCP Org Policy constraints) means keeping them conceptually aligned — a policy loosened in one system without the corresponding change in the other can create confusing inconsistencies (a plan that Sentinel would allow but that GCP's Org Policy silently rejects at apply time, or vice versa).

**Likely interview questions:**
- *"Why enforce a security rule at both the Sentinel/policy-set level and the GCP Org Policy level, rather than just picking one?"* — Sentinel/OPA only governs changes that flow through Terraform's plan/apply pipeline; Org Policy governs the underlying GCP API directly, so only having Sentinel leaves a gap for any change made outside Terraform, while only having Org Policy loses the fast, specific, PR-level feedback Sentinel provides.
- *"What parameters can a Sentinel policy set expose, and why is that useful?"* — Configurable values like `max_instance_count` that can differ per workspace (e.g., a higher cap for prod than staging) without needing to fork the policy code itself — the same policy logic, tuned per environment via parameters.

---

## 6.3 Organization & Access Control

```hcl
resource "tfe_team" "platform_admins" {
  name         = "platform-admins"
  organization = "my-org"
}

resource "tfe_team_access" "prod_admin" {
  team_id      = tfe_team.platform_admins.id
  workspace_id = tfe_workspace.prod_gke.id
  access       = "admin"
}

resource "tfe_team_access" "app_teams_plan_only" {
  team_id      = tfe_team.app_developers.id
  workspace_id = tfe_workspace.prod_gke.id
  access       = "plan"   # can see plans, cannot apply to prod
}
```
Mirror this on the GCP side with **Resource Manager folder hierarchy** — `Organization → Folders (per business unit) → Projects (per env)` — so IAM inheritance naturally scopes down, and a team's TFC workspace access lines up 1:1 with their actual GCP IAM grants (avoiding a workspace that *can* apply but whose underlying service account lacks the GCP permissions, or worse, the reverse).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Aligning TFC team/workspace access with GCP's own IAM/folder hierarchy avoids a subtle but dangerous class of misconfiguration: a TFC workspace access level that implies more (or less) capability than the underlying GCP service account actually has. If they drift out of alignment, you get either a workspace that *looks* restricted but whose service account can still do damage via direct `gcloud`, or a workspace that's blocked in TFC but whose credentials work fine elsewhere.

**Trade-offs:** Mirroring GCP's folder/project hierarchy in TFC's team/workspace structure adds administrative overhead (keeping two access-control systems in sync) but is the only way to guarantee that "what a team can do via Terraform" and "what a team can do at all" are the same statement — without that alignment, access reviews have to check both systems independently to get the real picture.

**Likely interview questions:**
- *"Why might a TFC workspace's access level not tell you the full story about what a team can actually do to GCP resources?"* — Because the actual enforcement happens at the GCP IAM level, via whatever service account the workspace uses to run `apply` — if that service account has broader permissions than the TFC workspace access level implies, a plan-only TFC user's *effective* GCP capability could still be broader than intended if they can influence what gets applied.
- *"How would you structure GCP Resource Manager folders to mirror your TFC team access model?"* — Organization → folders per business unit/team → projects per environment within each folder, with IAM inherited down the hierarchy, matching TFC's own team-to-workspace access grants one-to-one.

---

## 6.4 Advanced State Management

At enterprise scale, combine hierarchical state (3.3) with **state snapshots and programmatic access** for compliance auditing:

```bash
# Pull state via TFC API for external compliance scanning
curl -H "Authorization: Bearer $TFC_TOKEN" \
  https://app.terraform.io/api/v2/workspaces/ws-abc123/current-state-version \
  | jq -r '.data.attributes."hosted-state-download-url"' \
  | xargs curl -o state.json
```

```hcl
# Cross-workspace data sharing at scale via tfe_outputs (TFC-native, replaces
# manual terraform_remote_state wiring across dozens of workspaces)
data "tfe_outputs" "network" {
  organization = "my-org"
  workspace    = "gcp-prod-network"
}

resource "google_container_cluster" "primary" {
  network    = data.tfe_outputs.network.values.vpc_self_link
  subnetwork = data.tfe_outputs.network.values.gke_subnet_self_link
  # ...
  name     = "prod-gke"
  location = "us-central1"
}
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** `tfe_outputs` (TFC-native cross-workspace data sharing) solves the same problem as manually-configured `terraform_remote_state` (3.3, 1.4) but scales better across dozens of workspaces — it's managed through TFC's own API/permission model rather than requiring each consuming workspace to have separately-configured backend credentials pointing at another team's raw state storage location.

**Trade-offs:** Programmatic state access (pulling raw state JSON via the TFC API for compliance scanning) is powerful for auditing, but the raw state file may contain sensitive values (2.8) — any external tool consuming it for compliance purposes needs its own access controls and secure handling, not just read access to "make reporting easier."

**Likely interview questions:**
- *"What's the advantage of `tfe_outputs` over manually configuring `terraform_remote_state` with GCS backend config in every consuming workspace?"* — It uses TFC's own organization/workspace permission model directly, rather than requiring every consumer to have separate credentials/configuration pointing at the producer's raw backend storage location — simpler and more centrally governable at scale.
- *"What precaution should you take before pulling raw state JSON out of TFC for an external compliance tool?"* — Recognize that state may contain sensitive values in plaintext, and ensure the external tool's own access and storage of that pulled state is at least as tightly controlled as the original state backend.

---

## 6.5 Audit Logging & Compliance

Every Terraform-driven change to GCP shows up in **Cloud Audit Logs** (Admin Activity + Data Access logs) attributed to the CI service account — pair this with TFC's own **Audit Trails** API for a two-sided record: *what Terraform intended* (TFC run history) vs. *what GCP actually did* (Cloud Audit Logs).

```hcl
resource "google_project_iam_audit_config" "all_services" {
  project = var.project_id
  service = "allServices"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_logging_project_sink" "audit_to_bigquery" {
  name        = "audit-logs-to-bq"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/audit_logs"
  filter      = "logName:\"cloudaudit.googleapis.com\""
}
```
```bash
# TFC audit trail export (SIEM ingestion)
curl -H "Authorization: Bearer $TFC_TOKEN" \
  "https://app.terraform.io/api/v2/organization/audit-trail?since=2026-06-01"
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Cloud Audit Logs and TFC's own audit trail answer two different questions that both matter for a complete compliance picture: TFC's audit trail answers "what did someone *intend* to change, and did it go through approval" (the process record), while Cloud Audit Logs answer "what actually happened to the GCP resource" (the ground-truth record) — a compliance review that only checks one side can miss discrepancies between intent and reality.

**Trade-offs:** Enabling full `DATA_READ`/`DATA_WRITE` audit logging on all services generates a large volume of log data with real storage/BigQuery cost implications — most organizations scope Data Access audit logging to specifically sensitive services rather than enabling it universally, reserving `ADMIN_READ` (lower volume, high value) more broadly.

**Likely interview questions:**
- *"Why check both TFC's audit trail and GCP Cloud Audit Logs during a compliance review, instead of just one?"* — TFC's audit trail shows what changes were proposed/approved through the Terraform pipeline; Cloud Audit Logs show what actually happened at the GCP API level — checking both catches any discrepancy, such as an out-of-band change that never went through TFC at all.
- *"What's the difference between `ADMIN_READ`, `DATA_READ`, and `DATA_WRITE` audit log types, and why not enable all three everywhere by default?"* — `ADMIN_READ` covers reads of resource metadata/configuration (lower volume); `DATA_READ`/`DATA_WRITE` cover reads/writes of actual data within a resource (potentially very high volume) — enabling all three universally can generate significant log volume and cost, so it's typically scoped to genuinely sensitive services.

---

## 6.6 Cost Management at Scale

Combine per-PR Infracost checks (4.4) with org-wide **BigQuery billing export** for retrospective FinOps analysis, all declared in Terraform:

```hcl
resource "google_billing_account_iam_member" "billing_viewer" {
  billing_account_id = var.billing_account_id
  role                = "roles/billing.viewer"
  member              = "group:finops-team@example.com"
}

resource "google_bigquery_dataset" "billing_export" {
  dataset_id = "billing_export"
  location   = "US"
}

# Scheduled query rolling up cost by label (cost-center, from 5.4)
resource "google_bigquery_data_transfer_config" "cost_by_team" {
  display_name           = "monthly-cost-by-team"
  data_source_id         = "scheduled_query"
  schedule               = "every month 09:00"
  destination_dataset_id = google_bigquery_dataset.billing_export.dataset_id
  params = {
    query = <<-SQL
      SELECT labels.value AS cost_center, SUM(cost) AS total_cost
      FROM `billing_export.gcp_billing_export_v1`
      CROSS JOIN UNNEST(labels) AS labels
      WHERE labels.key = 'cost-center'
      GROUP BY cost_center
    SQL
  }
}
```
At scale, also enforce **budget-per-project** (5.4-style budgets, applied per team's project via a shared module) so overspend is caught at the team level, not discovered org-wide at month-end.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Infracost (4.4) estimates cost *before* a change is applied; BigQuery billing export analyzes *actual* incurred cost after the fact, broken down by the labels applied in 5.4 — together they form a closed loop: pre-apply estimation prevents obvious cost surprises, while post-apply analysis catches cost patterns (like actual traffic-driven usage costs) that static estimation structurally cannot predict.

**Trade-offs:** Per-team/per-project budgets (5.4-style, applied per project) catch overspend earlier and more precisely than a single org-wide budget, but require enough project-per-team isolation to be practical — an org where every team shares one giant project can't easily attribute or cap spend at the team level without relying entirely on label-based BigQuery queries after the fact.

**Likely interview questions:**
- *"Why doesn't pre-apply cost estimation (Infracost) alone give a complete FinOps picture?"* — It only estimates cost from provisioned configuration (instance sizes, reserved capacity); it can't predict usage-driven costs (actual request volume, actual data egress) that only become visible in real billing data after the resources are running and serving traffic.
- *"How would you attribute GCP spend to individual teams when everything lives in a shared organization?"* — Enforce mandatory cost-center labels (5.4) via policy, export billing data to BigQuery, and run scheduled queries grouping cost by label — combined with per-project or per-team budgets where project-level isolation is feasible.

---

## 6.7 Custom Workflows & Automation

**TFC Run Tasks** integrate external checks (e.g., a custom compliance service) directly into the plan/apply lifecycle:

```hcl
resource "tfe_organization_run_task" "custom_compliance" {
  organization = "my-org"
  url          = "https://compliance-checker.internal.example.com/tfc-run-task"
  name         = "custom-gcp-compliance-check"
  enabled      = true
}

resource "tfe_workspace_run_task" "prod_gke_check" {
  workspace_id      = tfe_workspace.prod_gke.id
  task_id           = tfe_organization_run_task.custom_compliance.id
  enforcement_level = "mandatory"
  stage             = "post_plan"
}
```
Combine with **Cloud Build** triggers for auxiliary automation (e.g., auto-tagging a release in Artifact Registry once `apply` succeeds), invoked via a TFC "notification" webhook configured on the workspace, closing the loop between infra changes and the broader software delivery pipeline.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Run Tasks extend TFC's policy enforcement model beyond what Sentinel/OPA can express as pure plan-JSON policy — they let an *external* service (a custom compliance checker, a change-management system) participate directly in the plan/apply lifecycle as a mandatory gate, which is useful for checks that require external context Sentinel/OPA can't see from the plan alone (e.g., "is there an approved change ticket for this deployment window").

**Trade-offs:** Run Tasks introduce an external service as a hard dependency in the apply pipeline — if that service is unavailable, applies can be blocked org-wide, so the external endpoint needs its own reliability/on-call ownership commensurate with being a critical-path dependency for all infrastructure changes.

**Likely interview questions:**
- *"When would you reach for a TFC Run Task instead of a Sentinel/OPA policy?"* — When the check requires external context the plan JSON alone doesn't contain — e.g., verifying an approved change-management ticket exists, or checking a live external system's state — rather than something derivable purely from the plan's resource changes.
- *"What's a risk of adding a mandatory Run Task to every workspace's pipeline?"* — The external Run Task service becomes a hard dependency for all applies — if it's down or slow, it can block infrastructure changes org-wide, so its own availability/SLA needs to be treated as critical-path infrastructure.

---

## 6.8 Disaster Recovery Plans

Enterprise DR extends 5.8 with **TFC/TFE itself** as a dependency to plan for: if TFC is unavailable, can you still `apply` emergency changes?

```bash
# Break-glass fallback: local apply against the same GCS-backed state
# (kept in sync even when using TFC's remote backend, via periodic state pulls)
terraform init -backend-config="bucket=my-org-tfstate-dr-fallback"
terraform apply -var-file=envs/prod.tfvars
```
Maintain a documented, tested **break-glass procedure**: a small, tightly access-controlled group holds credentials and a fallback local-backend configuration to apply critical fixes if the SaaS control plane (TFC) is down, while the GCP infrastructure itself continues running unaffected (Terraform is a control plane, not a runtime dependency — GCP resources keep running even if Terraform/TFC is completely offline).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** This is the practical consequence of recognizing Terraform (and TFC specifically) as a **control plane**, not a runtime dependency — GCP resources keep running fine even if TFC is completely unreachable; the risk is purely "can we make an *emergency change* if the control plane is down," which is exactly what a documented, tested break-glass fallback addresses.

**Trade-offs:** Maintaining a working local/GCS-backend fallback path *in addition to* the primary TFC-managed workflow means two configurations to keep in sync (or at least periodically validate) — most teams accept this overhead only for their most critical workspaces, not universally, given the added maintenance burden of a rarely-used path.

**Likely interview questions:**
- *"If Terraform Cloud has an outage, does that mean your GCP infrastructure stops working?"* — No — TFC is a control plane for making *changes*; already-provisioned GCP resources continue running independently. The risk is being unable to make emergency changes until TFC recovers, unless a break-glass fallback path exists.
- *"What does a 'break-glass' Terraform procedure typically involve?"* — A small, access-controlled group with credentials and a fallback local (or alternate remote) backend configuration pointing at the same underlying state, allowing a critical emergency `apply` to proceed even if the primary SaaS control plane (TFC) is unavailable.

---

## 6.9 Migration to Enterprise Edition

Moving from open-source Terraform (local/GCS backend) to TFC/TFE:

```bash
# 1. Create TFC workspace, set it to "CLI-driven" initially
terraform login

# 2. Update backend block
```
```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces { name = "gcp-prod-gke" }
  }
}
```
```bash
# 3. Migrate existing state into the new backend
terraform init -migrate-state

# 4. Once validated, switch workspace to VCS-driven for full CI/CD integration
```
Phased rollout: migrate **one non-critical workspace first** (e.g., `dev`), validate the run pipeline, policy sets, and team access model end-to-end, then roll out to `staging` and finally `prod` — never cut over every workspace simultaneously.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Migrating to TFC/TFE is itself a state-backend migration (like 1.6's backend switch), plus an added governance/workflow layer — the `terraform init -migrate-state` mechanics are identical to any other backend change; what's new is validating the *surrounding* process (policy sets, team access, run triggers) actually works as intended before trusting it with production workspaces.

**Trade-offs:** A phased rollout (dev workspace first, then staging, then prod) delays the org-wide benefits of TFC (centralized policy, audit trail) but dramatically reduces the risk of a botched migration affecting production — the same phased-adoption principle as 5.6's Terraform-adoption migration applied one level up, to migrating the *platform* Terraform runs on.

**Likely interview questions:**
- *"Why migrate one non-critical workspace to TFC before rolling out to production?"* — To validate the entire surrounding workflow (VCS integration, policy sets, team access levels, run triggers) works correctly end-to-end in a low-stakes environment before trusting it with a workspace where a misconfiguration could cause a production incident.
- *"What actually changes technically when you migrate a workspace from a GCS backend to a TFC `cloud` block?"* — The state storage/locking location moves to TFC (via `terraform init -migrate-state`), and — more significantly — `plan`/`apply` execution itself now happens remotely on TFC's infrastructure rather than locally or in your own CI runner, subject to whatever policy sets and approval workflow the workspace has configured.

---

# SECTION 7: EXPERT TROUBLESHOOTING & RECOVERY

## 7.1 Advanced Debugging Techniques

```bash
# Full trace of every provider RPC (extremely verbose — use narrowly)
TF_LOG=TRACE TF_LOG_PATH=trace.log terraform apply

# Isolate a single resource's plan behavior
terraform plan -target=google_container_cluster.primary

# Inspect the raw provider schema to check field names/types you're unsure of
terraform providers schema -json | jq '.provider_schemas."registry.terraform.io/hashicorp/google".resource_schemas.google_compute_instance'

# Graph the dependency graph to spot unexpected implicit dependencies
terraform graph | dot -Tsvg > graph.svg
```
When a `plan` shows a confusing forced-replacement, `terraform plan` output includes a `# forces replacement` comment next to the specific attribute — always read that line rather than guessing; it names the exact field (e.g., `zone` or `network` are often immutable on Compute resources).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Terraform's dependency graph is the mechanism that determines *execution order* — resources are created/updated/destroyed in an order derived from explicit (`depends_on`) and implicit (attribute reference) dependencies, walked as a directed acyclic graph. Visualizing it (`terraform graph`) is valuable precisely when a `plan`'s ordering or a `Cycle` error is confusing — it turns an abstract ordering problem into something you can literally look at.

**Trade-offs:** Full `TRACE`-level logging captures every provider RPC, which is exhaustive but often too noisy to read directly — effective use usually means grepping/filtering the trace log for a specific resource address or RPC name rather than reading it top to bottom.

**Likely interview questions:**
- *"What does `terraform plan` mean when it annotates a field with `# forces replacement`?"* — That changing this specific attribute requires destroying and recreating the resource (the field is immutable on the underlying GCP API) rather than being updatable in-place — always worth checking before applying a change to a stateful resource.
- *"How would you inspect the exact schema/fields available on a given resource type without checking documentation?"* — `terraform providers schema -json`, piped through `jq` to extract the specific resource's schema directly from the installed provider version — useful when documentation is ambiguous or you need to confirm behavior against the exact version pinned in your lock file.

---

## 7.2 State File Recovery & Repair

```bash
# GCS backend versioning (1.6) is your primary recovery mechanism
gsutil ls -a gs://my-org-tfstate-prod/app/prod/default.tfstate
gsutil cp gs://my-org-tfstate-prod/app/prod/default.tfstate#1234567890 ./recovered.tfstate

# Validate the recovered state before restoring
terraform show recovered.tfstate

# Restore it as the active state
gsutil cp recovered.tfstate gs://my-org-tfstate-prod/app/prod/default.tfstate
```

**Corrupted/inconsistent state repair:**
```bash
# Remove a resource Terraform thinks exists but doesn't (e.g., manually deleted)
terraform state rm google_compute_instance.ghost

# Re-import the real resource under the expected address
terraform import google_compute_instance.web projects/my-project/zones/us-central1-a/instances/web-server

# Full state reconciliation after suspected drift/corruption
terraform apply -refresh-only
terraform plan   # should now show no unexpected diffs
```
**Golden rule**: always `terraform state pull > backup-$(date +%s).json` before any manual state surgery (`state rm`, `state mv`, `import`) — these commands can't be undone otherwise.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** State recovery relies entirely on the backend's own durability/versioning features (GCS bucket versioning, 1.6) — this is why enabling versioning on the state bucket isn't optional hardening, it's the actual recovery mechanism for a corrupted or bad state write; without it, a bad `apply` that corrupts state has no automatic recovery path at all.

**Trade-offs:** Manual state surgery (`state rm`, `import`, editing) is powerful but inherently risky — every one of these commands can be effectively irreversible if done incorrectly, which is why taking a `state pull` backup immediately beforehand isn't excessive caution, it's the minimum safe practice.

**Likely interview questions:**
- *"Someone's `apply` corrupted the state file. How do you recover?"* — Pull a prior object generation from the GCS backend's version history (`gsutil ls -a` / `gsutil cp ... #<generation>`), validate it with `terraform show`, and restore it as the active state — this is exactly why state bucket versioning (1.6) is mandatory, not optional.
- *"What's the very first thing you should do before running `terraform state rm` or manually editing state?"* — `terraform state pull > backup.json` — capture a point-in-time backup, since state surgery commands have no built-in undo.

---

## 7.3 Provider Issues & Solutions

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Error: could not find image` on new provider version | Breaking change / renamed resource in a major version bump | Check the provider's `CHANGELOG.md`; pin `~>` to avoid unplanned major upgrades |
| Plan shows spurious diffs on every run (e.g., `metadata` field) for a resource nobody changed | API returns a normalized value different from your HCL (e.g., trailing newline, default fields) | Use `ignore_changes` in `lifecycle`, or match the exact API-normalized format |
| `Error: Provider produced inconsistent final plan` | Provider bug, often with computed values inside `for_each` | Upgrade provider version; file/search a GitHub issue on `terraform-provider-google` |
| Random `429 rate limit exceeded` errors from GCP APIs | Too much parallelism against a quota-limited API | Lower `-parallelism`, request quota increase |
| `google-beta` resource fails silently or field ignored | Used `google` provider instead of `google-beta` for a beta-only field | Add `provider = google-beta` explicitly on that resource |

```bash
# Downgrading/upgrading a specific provider version to bisect a regression
terraform init -upgrade
terraform providers lock -provider=hashicorp/google -provider-version=5.31.0
```

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Provider issues sit in a layer between your HCL and GCP's actual API — a provider bug (or an intentional breaking change in a new major version) can cause behavior that has nothing to do with anything you wrote, which is why the first troubleshooting instinct for a confusing error should be "check whether this is a known provider issue/changelog entry" rather than assuming your configuration is wrong.

**Trade-offs:** Aggressively pinning providers (avoiding upgrades) sidesteps regression risk but also means missing bug fixes and new resource/field support — the practical balance is upgrading deliberately (reading changelogs, testing in a non-prod workspace first) rather than either blindly auto-upgrading or never upgrading at all.

**Likely interview questions:**
- *"Your `plan` shows a spurious diff every single run on a field nobody is changing. What's likely happening, and how do you fix it?"* — The GCP API is likely returning a normalized/default value that differs slightly from what you wrote in HCL (e.g., a trailing character, a default sub-field); fix with a `lifecycle { ignore_changes = [...] }` on that specific attribute, or adjust your HCL to match the API's normalized form exactly.
- *"You see `429 rate limit exceeded` errors during a large apply. What are your options?"* — Lower `-parallelism` to reduce concurrent API calls, and/or request a quota increase for the specific API being rate-limited, since the underlying cause is too many concurrent requests against a quota-constrained GCP API, not a code error.

---

## 7.4 Performance Tuning

Beyond 5.9's `-parallelism` tuning, for very large configurations (1000+ resources):

```bash
# Skip provider version/lock re-resolution on repeated CI runs
terraform init -lockfile=readonly

# Use -target sparingly for faster iterative debugging (never for real applies)
terraform plan -target=module.gke_prod -target=module.networking

# Split extremely large root modules by layer (3.3) — the single biggest
# performance win, since plan/refresh time scales with resource count per state
```
Profiling a slow `plan`: `TF_LOG=TRACE` and grep for RPC timestamps to identify whether the bottleneck is GCP API latency (many resources being refreshed) vs. Terraform's own graph-walk overhead (deeply nested modules with excessive `for_each` fan-out).

### 🔍 Concept Deep Dive

**Why it matters conceptually:** As configurations grow, `plan`/`apply` time scales primarily with the number of resources actually being refreshed/evaluated in a single state — this is the direct, practical payoff of the state-splitting architecture from 3.3: it's not just a safety/blast-radius benefit, it's also the single biggest lever for keeping day-to-day Terraform operations fast at scale.

**Trade-offs:** `-target` is a legitimate emergency/debugging tool for narrowing a `plan`/`apply` to a specific resource, but using it routinely as a substitute for proper state architecture is a red flag — it bypasses Terraform's normal full-graph evaluation and can leave the broader plan silently stale/inconsistent if overused as a standard workflow rather than an exception.

**Likely interview questions:**
- *"Your Terraform configuration has grown to 1,000+ resources and `plan` now takes several minutes. What's the most impactful fix?"* — Split the monolithic state into smaller layers/components (3.3) — plan/refresh time scales with resource count per state, so this typically has a far bigger impact than tuning `-parallelism` alone.
- *"When is it appropriate to use `terraform apply -target=...`, and when is it a red flag?"* — Appropriate for genuine emergency/debugging scenarios needing a narrowly-scoped, fast apply; a red flag if it becomes a routine substitute for proper state splitting, since it bypasses full-graph evaluation and can leave the rest of the plan silently inconsistent with what's actually been applied.

---

## 7.5 Handling Production Incidents

**Incident: a bad `apply` is mid-flight and causing an outage.**
```bash
# 1. If safe, let it finish rather than killing it mid-write (partial applies
#    can leave state inconsistent with reality)
# 2. If truly must stop: Ctrl+C once (graceful), Terraform will attempt to
#    finish the current resource operation and mark the run interrupted
# 3. Immediately after, reconcile:
terraform plan -refresh-only
```

**Incident: a resource was deleted in prod and needs instant restoration.**
```bash
# Point-in-time restore for Cloud SQL (5.8's backup config makes this possible)
gcloud sql backups restore BACKUP_ID --restore-instance=prod-db

# Re-import the restored resource so Terraform state matches reality again
terraform import google_sql_database_instance.prod prod-db
```

**Incident: rollback of a bad instance template rollout (5.1 pattern).**
```hcl
# Revert instance_template reference to previous known-good image in git,
# re-apply — update_policy's max_surge/max_unavailable settings ensure the
# rollback is itself zero-downtime, identical mechanics to the original rollout
```
```bash
git revert <bad-commit-sha>
terraform plan -out=tfplan
terraform apply tfplan
```
Always keep an **incident channel + declared incident commander** running the above commands, with the `plan` output posted before any `apply`, even during an active incident — panic-applying without reviewing the diff is how one outage becomes two.

### 🔍 Concept Deep Dive

**Why it matters conceptually:** Incident response with Terraform requires balancing two competing pressures: the urgency to fix the outage *now*, and the discipline to still review a diff before applying, since a panic-driven, unreviewed emergency `apply` is itself a common cause of a *second* incident stacked on top of the first. The guidance throughout this section (finish rather than kill a mid-flight apply where possible, always `plan` before an emergency `apply`) exists specifically to prevent that compounding failure mode.

**Trade-offs:** Point-in-time database restore (Cloud SQL) buys fast recovery from accidental deletion, but always means *some* data loss (anything written between the last backup/log position and the restore point) — the acceptable loss window is exactly what your RPO target (5.8) should have already defined before the incident happened, not decided under pressure during it.

**Likely interview questions:**
- *"Should you kill a mid-flight `terraform apply` if you realize it's causing an outage?"* — Generally no, if it's safe to let it finish — killing it mid-write can leave state inconsistent with reality; if you must stop it, a single graceful interrupt (not a hard kill) lets Terraform attempt to complete the current resource operation cleanly, followed immediately by a `plan -refresh-only` to reconcile.
- *"A production resource was accidentally deleted. What are the recovery steps, in order?"* — Restore the underlying resource from its most recent backup/snapshot (e.g., Cloud SQL point-in-time restore) first, then `terraform import` the restored resource back under its expected Terraform address so state matches reality again — restoring reality before reconciling state, not the reverse.

---

## 7.6 Post-Incident Analysis & Prevention

**Post-incident review checklist:**
1. Pull the exact `plan`/`apply` logs from CI (or TFC run history, 6.4) for the incident window.
2. Correlate with Cloud Audit Logs (6.5) to confirm no out-of-band changes contributed.
3. Identify the specific guardrail that should have caught this: missing `prevent_destroy`? Missing policy-as-code rule (3.4)? Missing `max_unavailable_fixed = 0`?
4. Write the fix as code, not just a runbook note:

```hcl
# Example: after an incident where a Cloud SQL instance was accidentally
# destroyed by a careless `apply`, add prevent_destroy retroactively
resource "google_sql_database_instance" "prod" {
  # ...
  name             = "prod-db"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  settings { tier = "db-custom-8-32768" }

  lifecycle {
    prevent_destroy = true
  }
}
```
```rego
# And/or add an OPA policy so this class of mistake can never reach `apply` again
package terraform.prevent_prod_db_destroy

deny[msg] {
  rc := input.resource_changes[_]
  rc.type == "google_sql_database_instance"
  rc.change.actions[_] == "delete"
  contains(rc.address, "prod")
  msg := sprintf("Refusing to destroy production database: %s", [rc.address])
}
```
5. Share the postmortem broadly; track the guardrail as a tracked action item, not just a narrative — the measure of a good postmortem is that the *same* mistake becomes structurally impossible, not just "unlikely because people will be more careful."

### 🔍 Concept Deep Dive

**Why it matters conceptually:** A postmortem's value is measured by whether it produces a *structural* fix (a policy rule, a `prevent_destroy` lifecycle block, a required CI gate) rather than only a narrative/behavioral fix ("be more careful next time") — the former makes the same class of mistake mechanically impossible to repeat; the latter relies on human vigilance, which is exactly the failure mode that caused the incident in the first place.

**Trade-offs:** Turning every postmortem finding into an automated guardrail (a new policy rule, a new required check) adds cumulative process overhead over time — the judgment call is prioritizing guardrails for genuinely high-blast-radius mistakes (destroying production data) over lower-stakes ones, where a documented runbook note may be a proportionate enough response.

**Likely interview questions:**
- *"What's the difference between a good and a mediocre Terraform incident postmortem?"* — A mediocre postmortem ends with "the engineer should have reviewed the plan more carefully"; a good one ends with a specific code/policy change (a `prevent_destroy` block, an OPA rule blocking that class of plan) that makes the same mistake structurally impossible going forward, not just less likely.
- *"After an incident where `terraform apply` accidentally destroyed a production database, what two concrete follow-up actions would you take?"* — Add `lifecycle { prevent_destroy = true }` to the resource immediately, and add an OPA/Sentinel policy that blocks any plan containing a `delete` action against a resource identifiably tagged/named as production — one guardrail at the resource level, one at the pipeline level.

---

# Appendix: Quick Reference Cheat Sheet

```bash
# Core workflow
terraform init | validate | plan -out=tfplan | apply tfplan | destroy

# State
terraform state list / show / mv / rm / pull / push
terraform import <address> <gcp_resource_id>

# Debugging
TF_LOG=DEBUG terraform apply
terraform console
terraform graph | dot -Tsvg > graph.svg

# Testing & quality gates
terraform fmt -check -recursive && terraform validate
tflint --recursive
tfsec . / checkov -d .
terraform test
infracost breakdown --path .

# GCP-specific gotchas to always remember
# - Enable APIs before using their resources (google_project_service)
# - GCS bucket names are globally unique across ALL of GCP
# - Use google-beta provider for preview-only fields
# - Prefer Workload Identity Federation over service account keys everywhere
```

**End of Guide.**
