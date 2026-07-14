# GCP IAM & Security — Complete Interview Reference Guide

> Console steps + gcloud commands + Terraform HCL + Concept Deep Dives + Interview Q&A for every topic.
> Target audience: 6–10 YOE GCP Cloud Engineer / DevOps Engineer / Platform Engineer interviews.

---

## Table of Contents

1. [Module 1: IAM Basics](#module-1-iam-basics)
2. [Module 2: IAM Identities](#module-2-iam-identities)
3. [Module 3: IAM Roles](#module-3-iam-roles)
4. [Module 4: IAM Policies](#module-4-iam-policies)
5. [Module 5: IAM Conditions](#module-5-iam-conditions)
6. [Module 6: Service Accounts](#module-6-service-accounts)
7. [Module 7: IAM Best Practices](#module-7-iam-best-practices)
8. [Module 8: Organization Policies](#module-8-organization-policies)
9. [Module 9: Resource Hierarchy](#module-9-resource-hierarchy)
10. [Module 10: Cloud Identity](#module-10-cloud-identity)
11. [Module 11: Security Command Center](#module-11-security-command-center-scc)
12. [Module 12: Cloud Audit Logs](#module-12-cloud-audit-logs)
13. [Module 13: Cloud Logging Security](#module-13-cloud-logging-security)
14. [Module 14: Cloud Monitoring Security](#module-14-cloud-monitoring-security)
15. [Module 15: VPC Security](#module-15-vpc-security)
16. [Module 16: Network Security](#module-16-network-security)
17. [Module 17: Encryption](#module-17-encryption)
18. [Module 18: Cloud KMS](#module-18-cloud-kms)
19. [Module 19: Secret Manager](#module-19-secret-manager)
20. [Module 20: Certificate Manager](#module-20-certificate-manager)
21. [Module 21: Identity-Aware Proxy (IAP)](#module-21-identity-aware-proxy-iap)
22. [Module 22: Workload Identity](#module-22-workload-identity)
23. [Module 23: Binary Authorization](#module-23-binary-authorization)
24. [Module 24: Shielded VM](#module-24-shielded-vm)
25. [Module 25: Confidential Computing](#module-25-confidential-computing)
26. [Module 26: VPC Service Controls](#module-26-vpc-service-controls)
27. [Module 27: Access Context Manager](#module-27-access-context-manager)
28. [Module 28: Security Health Analytics](#module-28-security-health-analytics)
29. [Module 29: DDoS Protection](#module-29-ddos-protection)
30. [Module 30: Compliance](#module-30-compliance)
31. [Module 31: Terraform Security](#module-31-terraform-security)
32. [Module 32: CI/CD Security](#module-32-cicd-security)
33. [Module 33: Interview Scenarios (Full Answers)](#module-33-interview-scenarios-full-answers)
34. [Quick-Reference: Highest-Priority Topics Cheat Sheet](#quick-reference-highest-priority-topics-cheat-sheet)

---

## Module 1: IAM Basics

### What is IAM?

IAM (Identity and Access Management) is GCP's system for controlling **who** (identity) can do **what** (role/permissions) **on which resource** (scope). Every access decision in GCP — Console, gcloud, API, client libraries — is evaluated against IAM policy at the point of the API call.

### Why IAM is Required

- Prevents unauthorized access to production systems and data.
- Enables separation of duties (e.g., dev team can deploy, but can't modify billing).
- Provides auditability — every permission grant is tied to an identity and is logged.
- Supports compliance requirements (SOC 2, HIPAA, PCI-DSS all require access control evidence).

### Authentication vs Authorization

| | Authentication | Authorization |
|---|---|---|
| Question answered | "Who are you?" | "What are you allowed to do?" |
| Mechanism in GCP | Google Sign-In, service account keys, Workload Identity, OIDC/SAML federation | IAM policy bindings (role ↔ member ↔ condition) |
| Failure result | 401 Unauthorized | 403 Permission Denied |

**Interview trap:** Candidates often conflate the two. Authentication proves identity; IAM policy (authorization) decides what that identity can touch. A user can be perfectly authenticated (valid Google identity) and still get a 403 if they have no role granting the needed permission.

### Principle of Least Privilege

Grant only the permissions required to perform a task, nothing more. In GCP this means:
- Prefer predefined roles over primitive roles (Owner/Editor/Viewer).
- Prefer custom roles with only the exact permissions needed over broad predefined roles when a team's job is narrow.
- Use conditional bindings to scope access by time, resource, or IP.
- Use short-lived credentials (impersonation, Workload Identity) instead of long-lived service account keys.

### Zero Trust Security

Zero Trust means "never trust, always verify" — no implicit trust based on network location (e.g., being inside the corporate VPN no longer grants trust). GCP's implementation of Zero Trust is **BeyondCorp Enterprise**, built on:
- Identity-Aware Proxy (IAP) — context-aware access per-request, not per-network.
- Access Context Manager — device posture, IP, and identity-based access levels.
- Continuous verification instead of one-time perimeter authentication.

**Interview answer:** "Zero Trust in GCP replaces the traditional VPN/firewall perimeter model. Instead of trusting a device because it's on the corporate network, IAP evaluates identity, device state, and context on every request via Access Context Manager access levels."

---

### IAM Components

```
Principal (identity) --[has]--> Role (bundle of permissions) --[on]--> Resource
                                        |
                                   Policy (the JSON binding all three together)
```

- **Identity** — a Google Account, Service Account, Google Group, or domain — "who".
- **Principal** — the identity string used in a binding, e.g. `user:jane@example.com`, `serviceAccount:sa@project.iam.gserviceaccount.com`, `group:devops@example.com`.
- **Resource** — anything with an IAM policy attached: organization, folder, project, bucket, VM, dataset, topic, etc.
- **Permission** — the smallest unit of access, formatted `service.resource.verb`, e.g. `storage.objects.get`, `compute.instances.start`. Permissions are never granted directly — only via roles.
- **Role** — a named collection of permissions (primitive, predefined, or custom).
- **Policy** — the actual JSON/YAML document attached to a resource that binds principals to roles (optionally with conditions).

#### gcloud: Inspect IAM components

```bash
# List all permissions contained in a role
gcloud iam roles describe roles/storage.objectViewer

# List effective permissions a principal has on a project (via Policy Analyzer / Policy Troubleshooter)
gcloud policy-troubleshoot iam \
  //cloudresourcemanager.googleapis.com/projects/my-project \
  --principal-email=jane@example.com \
  --permission=storage.objects.get
```


---

## Module 2: IAM Identities

| Identity Type | Description | Example Principal String |
|---|---|---|
| Google Account | Individual human user | `user:jane@example.com` |
| Service Account | Non-human identity used by apps/VMs/pipelines | `serviceAccount:app@project.iam.gserviceaccount.com` |
| Google Group | Collection of users/SAs, managed via Google Groups | `group:devops-team@example.com` |
| Cloud Identity | Google's IdP for managing users/groups without Workspace | domain-level, no billing |
| Workforce Identity Federation | Federate external IdP (Okta, Azure AD, on-prem SAML/OIDC) for **human** workforce access to GCP without Google accounts | `principal://iam.googleapis.com/locations/global/workforcePools/POOL/subject/SUBJECT` |
| Workload Identity Federation | Federate external identities (AWS, GitHub Actions, on-prem) for **workload/application** access without service account keys | `principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/subject/SUBJECT` |

### Console Steps — View Identities

1. Console → IAM & Admin → IAM → shows all principals with roles on the current project.
2. Console → IAM & Admin → Identity & Organization → shows Cloud Identity / Workspace domain.
3. Console → IAM & Admin → Workforce Identity Federation → configure external workforce pools.
4. Console → IAM & Admin → Workload Identity Federation → configure external workload pools.

### gcloud

```bash
# List all principals bound to roles on a project
gcloud projects get-iam-policy my-project --format=json

# Create a Workload Identity Pool (for GitHub Actions -> GCP, no keys)
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" \
  --display-name="GitHub Actions Pool"

gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" \
  --workload-identity-pool="github-pool" \
  --display-name="GitHub OIDC" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

### Terraform

```hcl
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description                = "WIF pool for GitHub Actions CI/CD"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id         = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = "assertion.repository_owner == 'my-github-org'"
}

# Allow a specific GitHub repo to impersonate a service account (keyless CI/CD)
resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci_deployer.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/my-github-org/my-repo"
}
```

### Concept Deep Dive

**Workforce Identity vs Workload Identity — the #1 confusion point:**
- **Workforce Identity Federation** = humans (your employees) logging into the GCP Console/gcloud using their corporate SSO (Okta/Azure AD) instead of a Google Account.
- **Workload Identity Federation** = applications/pipelines (GitHub Actions, AWS Lambda, on-prem CI) authenticating to GCP APIs without a downloaded JSON service account key.
- Both eliminate a category of long-lived, exportable credentials — the single biggest source of GCP credential-leak incidents historically.

**Interview Q&A:**

*Q: How would you let a GitHub Actions pipeline deploy to GCP without storing a service account key as a GitHub secret?*
A: Set up Workload Identity Federation — create a Workload Identity Pool + OIDC provider trusting `token.actions.githubusercontent.com`, restrict via `attribute_condition` to your repo/org, then grant `roles/iam.workloadIdentityUser` on the target service account to the specific `principalSet`. GitHub Actions' OIDC token is exchanged at runtime for short-lived GCP credentials — no key ever exists on disk or in secrets.

---

## Module 3: IAM Roles

### Primitive Roles (avoid in production)

| Role | Grants |
|---|---|
| `roles/owner` | Full control + can manage IAM + billing |
| `roles/editor` | Full control over resources, but not IAM/billing |
| `roles/viewer` | Read-only on almost everything |

**Why avoid:** These roles are extremely broad, apply across nearly every GCP service, and violate least privilege. `roles/owner` on a project effectively means "can do anything, including granting themselves more access, deleting the project, or exfiltrating all data." Predefined and custom roles should replace these in any real environment.

### Predefined Roles (examples)

| Role | Use Case |
|---|---|
| `roles/compute.admin` | Full control of Compute Engine resources |
| `roles/storage.admin` | Full control of Cloud Storage buckets/objects |
| `roles/compute.networkAdmin` | Manage VPCs, subnets, routes, firewall (not instances) |
| `roles/logging.admin` | Manage log sinks, buckets, retention |
| `roles/monitoring.admin` | Manage dashboards, alert policies, uptime checks |
| `roles/iam.securityAdmin` | Manage IAM policies without being able to touch resources themselves |
| `roles/iam.securityReviewer` | Read-only visibility into all IAM policies (great for auditors) |

### Custom Roles

Use when predefined roles are either too broad or don't quite match the job. Custom roles are project- or organization-scoped bundles of individual permissions.

**Console:** IAM & Admin → Roles → + Create Role → select permissions from the picker or via "Create role from selected permissions" after browsing an existing role.

**gcloud:**

```bash
# Create a custom role from a YAML definition
gcloud iam roles create devopsDeployer \
  --project=my-project \
  --title="DevOps Deployer" \
  --description="Deploy permissions without IAM/billing access" \
  --permissions=compute.instances.create,compute.instances.delete,compute.instances.get,compute.instances.list,compute.disks.create \
  --stage=GA

# Update a custom role (add a permission)
gcloud iam roles update devopsDeployer \
  --project=my-project \
  --add-permissions=compute.instances.setMetadata

# Delete (soft-delete, recoverable within 7 days)
gcloud iam roles delete devopsDeployer --project=my-project

# Undelete
gcloud iam roles undelete devopsDeployer --project=my-project
```

### Terraform

```hcl
resource "google_project_iam_custom_role" "devops_deployer" {
  role_id     = "devopsDeployer"
  title       = "DevOps Deployer"
  description = "Deploy permissions without IAM/billing access"
  permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.disks.create",
  ]
  stage = "GA"
}

resource "google_project_iam_member" "bind_custom_role" {
  project = "my-project"
  role    = google_project_iam_custom_role.devops_deployer.id
  member  = "group:devops-team@example.com"
}
```

### Best Practices for Roles

- Start from the closest predefined role, clone permissions into a custom role, then trim — don't build permission lists from scratch.
- Custom roles don't auto-update with new GCP permissions (predefined roles do) — you own the maintenance burden. Revisit periodically using `gcloud iam roles describe roles/X` diffs.
- Prefer **project-level** custom roles for team-specific needs; use **organization-level** custom roles only for patterns repeated across many projects.
- Use `gcloud iam list-testable-permissions` against a resource to discover the exact permission names available for a service.

**Interview Q&A:**

*Q: When would you use a custom role instead of a predefined role?*
A: When the closest predefined role grants either too much (violates least privilege) or too little (forces a second broader role) for a team's actual job — e.g., a team that only needs to restart VMs and read logs, not fully administer Compute Engine. I'd clone permissions from `roles/compute.instanceAdmin` and `roles/logging.viewer`, trim to the exact permission list, and ship as a custom role at the project level.

*Q: What's the operational cost of custom roles?*
A: They don't automatically pick up new permissions Google adds to a service over time — predefined roles do. That means custom roles need periodic review, or new API capabilities silently become unavailable to that role's holders even though the feature exists.

---

## Module 4: IAM Policies

### IAM Policy Structure

An IAM policy is a JSON document attached to a resource. It contains a list of **bindings**, each pairing a role with a set of members (and optionally a condition), plus an `etag` for optimistic concurrency and a `version` field (1, or 3 if conditions are used).

```json
{
  "version": 3,
  "bindings": [
    {
      "role": "roles/storage.objectViewer",
      "members": [
        "user:jane@example.com",
        "group:devops@example.com",
        "serviceAccount:app@my-project.iam.gserviceaccount.com"
      ]
    },
    {
      "role": "roles/storage.objectAdmin",
      "members": ["user:admin@example.com"],
      "condition": {
        "title": "expires-2026",
        "expression": "request.time < timestamp('2026-12-31T00:00:00Z')"
      }
    }
  ],
  "etag": "BwXhqYVz8Xk=",
  "version": 3
}
```

- **Bindings** — role-to-members mapping (the core unit).
- **Members** — the principals in a binding (users, groups, service accounts, domains, `allUsers`, `allAuthenticatedUsers`).
- **Roles** — what the members can do.
- **Conditions** — optional CEL expressions that further restrict when the binding is active (see Module 5).

### Console Steps

1. Go to the resource (e.g., Console → Cloud Storage → bucket → Permissions tab, or IAM & Admin → IAM for project-level).
2. Click **Grant Access**.
3. Enter principal, select role(s), optionally **Add Condition**.
4. Save.

### gcloud

```bash
# View a project's IAM policy
gcloud projects get-iam-policy my-project --format=json

# Add a binding (read-modify-write happens for you)
gcloud projects add-iam-policy-binding my-project \
  --member="user:jane@example.com" \
  --role="roles/storage.objectViewer"

# Remove a binding
gcloud projects remove-iam-policy-binding my-project \
  --member="user:jane@example.com" \
  --role="roles/storage.objectViewer"

# Set the full policy from a file (dangerous — overwrites everything, always fetch-modify-set)
gcloud projects get-iam-policy my-project --format=json > policy.json
# ... edit policy.json ...
gcloud projects set-iam-policy my-project policy.json
```

### Terraform — three binding strategies (know the difference!)

```hcl
# 1. google_project_iam_member — ADDITIVE, safest, manages a single member/role pair
resource "google_project_iam_member" "storage_viewer" {
  project = "my-project"
  role    = "roles/storage.objectViewer"
  member  = "user:jane@example.com"
}

# 2. google_project_iam_binding — AUTHORITATIVE for that role only; replaces the full member list for the role
resource "google_project_iam_binding" "storage_viewers" {
  project = "my-project"
  role    = "roles/storage.objectViewer"
  members = [
    "user:jane@example.com",
    "group:devops@example.com",
  ]
}

# 3. google_project_iam_policy — FULLY AUTHORITATIVE for the entire resource; replaces ALL bindings
data "google_iam_policy" "admin" {
  binding {
    role    = "roles/storage.objectViewer"
    members = ["user:jane@example.com"]
  }
}

resource "google_project_iam_policy" "project_policy" {
  project     = "my-project"
  policy_data = data.google_iam_policy.admin.policy_data
}
```

### Concept Deep Dive

**Critical interview trap — never mix `_member` and `_binding`/`_policy` for the same role.** `_member` is additive and safe to run alongside manually-granted or other Terraform-managed roles. `_binding` and `_policy` are authoritative: Terraform will **remove** any member not listed in its config on the next apply, including bindings created outside Terraform. Mixing them causes a perpetual state fight where each `apply` reverts the other's changes.

**Rule of thumb:** use `google_project_iam_member` in almost all real organizations (multiple teams/tools touching IAM). Reserve `_binding`/`_policy` for a single source of truth scenario, e.g., a fully Terraform-managed landing zone.

**Interview Q&A:**

*Q: What's the difference between `google_project_iam_member` and `google_project_iam_binding`?*
A: `_member` adds/removes exactly one member-role pair without touching other members on that role — safe when multiple teams manage IAM. `_binding` is authoritative for that specific role: it will delete any member on that role not declared in the Terraform config, even if another team or the Console added it manually.

*Q: How do you audit an IAM policy for drift (e.g., someone granted access manually)?*
A: `terraform plan` will show it as a diff needing removal if using `_binding`/`_policy`; with `_member` resources drift is invisible for other members' access, so pair `_member` usage with a Policy Analyzer / Cloud Asset Inventory export and periodic script diff against the Terraform-tracked state to catch out-of-band changes.

---

## Module 5: IAM Conditions

IAM Conditions let you attach a **CEL (Common Expression Language)** boolean expression to a role binding, so the grant is only active when the expression evaluates true.

### Common Condition Types

**Time-based access:**
```
request.time < timestamp("2026-12-31T00:00:00Z")
request.time.getHours("America/New_York") >= 9 && request.time.getHours("America/New_York") <= 17
```

**Resource-based access:**
```
resource.name.startsWith("projects/_/buckets/my-bucket/objects/reports/")
resource.type == "storage.googleapis.com/Object"
```

**IP-based access** — actually enforced via **Access Context Manager access levels** referenced inside a condition, not raw CIDR directly in IAM:
```
"origin.ip" == "203.0.113.5"   // not supported directly for IAM bindings — use Access Levels instead
```
(True IP-based restriction of GCP resources is typically done through Access Context Manager + VPC Service Controls / IAP, not raw IAM conditions — a common interview trick question.)

### Console Steps

1. IAM & Admin → IAM → Grant Access → after choosing role, click **+ Add Condition**.
2. Use the condition builder (dropdowns for time/resource/date) or the **Condition Editor** to write raw CEL.
3. Give the condition a title (mandatory) — save.

### gcloud

```bash
gcloud projects add-iam-policy-binding my-project \
  --member="user:contractor@example.com" \
  --role="roles/storage.objectViewer" \
  --condition='expression=request.time < timestamp("2026-12-31T00:00:00Z"),title=contractor-expiry,description=Contractor access expires end of 2026'
```

### Terraform

```hcl
resource "google_project_iam_member" "contractor_time_limited" {
  project = "my-project"
  role    = "roles/storage.objectViewer"
  member  = "user:contractor@example.com"

  condition {
    title       = "contractor-expiry"
    description = "Contractor access expires end of 2026"
    expression  = "request.time < timestamp(\"2026-12-31T00:00:00Z\")"
  }
}

# Resource-scoped: only objects under a prefix
resource "google_storage_bucket_iam_member" "reports_only" {
  bucket = google_storage_bucket.data.name
  role   = "roles/storage.objectViewer"
  member = "group:reporting-team@example.com"

  condition {
    title      = "reports-prefix-only"
    expression = "resource.name.startsWith(\"projects/_/buckets/my-bucket/objects/reports/\")"
  }
}
```

### Concept Deep Dive

Adding any condition bumps the policy to `version: 3`. Tools/clients that only speak `version: 1` policy will silently ignore conditional bindings if they fetch and reapply a policy without preserving `version: 3` — a subtle production bug source.

**Interview Q&A:**

*Q: How would you grant a contractor bucket access that automatically expires?*
A: Bind `roles/storage.objectViewer` with an IAM Condition using `request.time < timestamp(...)`. No cron job or manual revocation needed — the binding simply stops evaluating true after the expiry timestamp, though the binding entry itself still needs periodic cleanup since it isn't auto-deleted from the policy.

*Q: Can IAM Conditions restrict access by source IP address directly?*
A: Not directly — IAM Conditions don't have a native `origin.ip` attribute for arbitrary IAM bindings. IP/device/context-based restriction is done through **Access Context Manager** access levels, typically enforced via **VPC Service Controls** or **Identity-Aware Proxy**, not raw IAM condition CEL.

---

## Module 6: Service Accounts

Service accounts (SAs) are non-human identities used by applications, VMs, GKE workloads, and CI/CD pipelines to call GCP APIs.

### Types

| Type | Description |
|---|---|
| User-managed | Explicitly created by you (`xyz@project.iam.gserviceaccount.com`) — recommended for workloads |
| Google-managed (default) | Auto-created per-project (e.g., Compute Engine default SA, App Engine default SA) — **broad permissions by default, should be disabled/replaced** |
| Google-managed (service agent) | Created automatically for GCP services to act on your behalf internally (e.g., `service-PROJECTNUM@gcp-sa-*.iam.gserviceaccount.com`) — don't delete these |

### Service Account Keys — high risk, avoid where possible

Keys are long-lived, exportable JSON credentials. If leaked (committed to git, exposed in a public bucket), they grant standing access until manually revoked. Prefer these alternatives, in order:
1. **Attached service account** on the compute resource (VM/GKE node/Cloud Run) — no key needed, credentials come from the metadata server.
2. **Workload Identity** (GKE) or **Workload Identity Federation** (external/CI) — no key needed.
3. **Impersonation** (`--impersonate-service-account`) for human operators who occasionally need SA privileges — short-lived token, no key.
4. Only as a last resort: a downloaded JSON key, with mandatory rotation and Secret Manager storage (never in source control).

### Best Practices

- Disable unused keys before deleting (reversible) — `gcloud iam service-accounts keys disable`.
- Rotate keys regularly if keys must be used at all; better — eliminate keys entirely via Workload Identity Federation.
- Enable the Org Policy constraint `iam.disableServiceAccountKeyCreation` to block key creation org-wide except where explicitly exempted.
- Enable `iam.disableServiceAccountKeyUpload` to prevent uploading externally-generated keys.

### Service Account Operations

**Attach** (to a VM at creation):
```bash
gcloud compute instances create my-vm \
  --service-account=app-sa@my-project.iam.gserviceaccount.com \
  --scopes=cloud-platform
```

**Detach / change** (must stop instance first):
```bash
gcloud compute instances stop my-vm
gcloud compute instances set-service-account my-vm \
  --service-account=new-sa@my-project.iam.gserviceaccount.com \
  --scopes=cloud-platform
gcloud compute instances start my-vm
```

**Impersonation** (human operator borrows SA identity for one action, no key downloaded):
```bash
# Grant yourself impersonation rights (someone with iam.serviceAccountTokenCreator does this for you)
gcloud iam service-accounts add-iam-policy-binding app-sa@my-project.iam.gserviceaccount.com \
  --member="user:jane@example.com" \
  --role="roles/iam.serviceAccountTokenCreator"

# Use impersonation for a command
gcloud storage ls gs://my-bucket --impersonate-service-account=app-sa@my-project.iam.gserviceaccount.com
```

**Permissions on the SA resource itself** (who can act as / manage the SA):
- `roles/iam.serviceAccountUser` — attach the SA to a resource (e.g., deploy a Cloud Run service running as this SA).
- `roles/iam.serviceAccountTokenCreator` — impersonate / mint short-lived tokens or signed JWTs for the SA.
- `roles/iam.serviceAccountAdmin` — full lifecycle management (create/delete/disable) of the SA object, but not impersonation.
- `roles/iam.serviceAccountKeyAdmin` — manage keys specifically.

### Console Steps

1. IAM & Admin → Service Accounts → Create Service Account.
2. Fill name/ID/description → grant project roles (optional at creation) → done.
3. To manage keys: click the SA → Keys tab → Add Key (avoid) or Manage Key exposure.
4. To grant impersonation: click the SA → Permissions tab → Grant Access → assign `roles/iam.serviceAccountTokenCreator` to the human/group.

### Terraform

```hcl
resource "google_service_account" "app_sa" {
  account_id   = "app-sa"
  display_name = "Application Service Account"
  description  = "Used by the payments-api Cloud Run service"
}

# Grant project-level roles TO the service account (what it can do)
resource "google_project_iam_member" "app_sa_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
  ])
  project = "my-project"
  role    = each.value
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# Grant a human the right to impersonate/act-as the SA (who can use it)
resource "google_service_account_iam_member" "allow_impersonation" {
  service_account_id = google_service_account.app_sa.name
  role                = "roles/iam.serviceAccountTokenCreator"
  member              = "user:jane@example.com"
}

# Attach to a Cloud Run service
resource "google_cloud_run_v2_service" "payments_api" {
  name     = "payments-api"
  location = "us-central1"
  template {
    service_account = google_service_account.app_sa.email
    containers {
      image = "gcr.io/my-project/payments-api:latest"
    }
  }
}

# Org Policy: block new SA key creation
resource "google_org_policy_policy" "disable_sa_key_creation" {
  name   = "projects/my-project/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/my-project"
  spec {
    rules { enforce = "TRUE" }
  }
}
```

### Concept Deep Dive

**"Act As" vs "impersonate" — a frequent interview mix-up.** `roles/iam.serviceAccountUser` lets a principal *attach* an SA to a new resource they're deploying (the SA never leaves that resource). `roles/iam.serviceAccountTokenCreator` lets a principal directly *mint tokens as* the SA — effectively become the SA in an active session. The Token Creator role is more powerful and dangerous; granting it broadly is a common audit finding.

**Interview Q&A:**

*Q: How would you eliminate the need for a service account key on a VM entirely?*
A: Attach the service account directly to the VM at creation with `--service-account` and appropriate `--scopes=cloud-platform`; the metadata server (`http://metadata.google.internal`) then serves short-lived access tokens automatically to any process on the VM. No key file is ever created, stored, or rotated.

*Q: A developer says they need "Editor" on a service account to deploy through it. What do they actually need?*
A: They need `roles/iam.serviceAccountUser` on that specific service account (to attach it to a Cloud Run/Cloud Function/VM deploy) plus deploy permissions on the target service — not Editor on the project, and not ownership of the service account itself.

---

## Module 7: IAM Best Practices

- **Least Privilege** — always start from the narrowest role that accomplishes the task.
- **No Owner Role** in production projects — reserve for emergency break-glass accounts only, ideally with an alert on use.
- **Avoid Editor Role** — it's nearly as broad as Owner across most services; use scoped predefined/custom roles instead.
- **Group-Based Access** — bind roles to Google Groups, not individual users. Onboarding/offboarding becomes a group-membership change, not an IAM policy edit, and it's auditable through Cloud Identity group history.
- **Temporary Access** — use IAM Conditions with expiry timestamps, or Privileged Access Manager (PAM) for just-in-time elevation, instead of standing broad grants.
- **Audit IAM Changes** — Admin Activity audit logs capture every `SetIamPolicy` call automatically (always on, can't be disabled) — alert on unexpected bindings, especially Owner/Editor grants or grants to `allUsers`.

### gcloud — auditing IAM at scale

```bash
# Find all principals with Owner or Editor across the org (requires Cloud Asset Inventory)
gcloud asset search-all-iam-policies \
  --scope=organizations/ORG_ID \
  --query="policy:roles/owner OR policy:roles/editor"

# Find bindings granted to allUsers or allAuthenticatedUsers (public exposure)
gcloud asset search-all-iam-policies \
  --scope=organizations/ORG_ID \
  --query="policy:allUsers OR policy:allAuthenticatedUsers"
```

### Terraform — enforce group-based access pattern

```hcl
resource "google_project_iam_member" "devops_group" {
  project = "my-project"
  role    = "roles/compute.admin"
  member  = "group:devops-team@example.com"   # group, not individuals
}
```

**Interview Q&A:**

*Q: How do you detect if someone has granted `allUsers` access to a sensitive resource?*
A: Use Cloud Asset Inventory's `search-all-iam-policies` with a query filtering on `allUsers`/`allAuthenticatedUsers`, or configure a Security Command Center finding for public bucket/dataset exposure, and set up a Cloud Function triggered off the audit log `SetIamPolicy` event to auto-alert or auto-revoke.

---

## Module 8: Organization Policies

Organization Policies (Org Policies) restrict **what configurations are allowed**, independent of IAM. IAM controls "who can act"; Org Policy controls "what actions/configurations are even possible," regardless of who's asking — even an Owner can't violate an enforced Org Policy without an explicit exception.

### Hierarchy & Inheritance

```
Organization
   ↓ (inherits down)
 Folder
   ↓
 Project
   ↓
 Resource
```

Policies set at a higher level are inherited by default. Lower levels can override (unless the policy is set to non-overridable at a higher level).

### Common Constraints

| Constraint | Purpose |
|---|---|
| `compute.vmExternalIpAccess` | Disable/restrict external IPs on VMs |
| `compute.trustedImageProjects` | Restrict VM images to approved projects |
| `gcp.resourceLocations` | Restrict resource creation to specific regions |
| `compute.disableSerialPortAccess` | Disable serial port access (prevents a common exfiltration/debug vector) |
| `iam.disableServiceAccountKeyCreation` | Block SA key creation |
| `iam.allowedPolicyMemberDomains` | Restrict IAM bindings to specific domains only |

### Console Steps

1. Console → IAM & Admin → Organization Policies.
2. Select the resource scope (org/folder/project) in the resource picker at top.
3. Click a constraint (e.g., "Restrict VM External IP Access") → Manage Policy → Add a rule → Enforce = On → set scope/exceptions → Save.

### gcloud

```bash
# List available constraints
gcloud org-policies list --project=my-project

# Restrict VM external IPs (deny all)
cat > policy.yaml << EOF
name: projects/my-project/policies/compute.vmExternalIpAccess
spec:
  rules:
  - denyAll: true
EOF
gcloud org-policies set-policy policy.yaml

# Restrict resource creation to a region
gcloud resource-manager org-policies enable-enforce \
  constraints/gcp.resourceLocations --project=my-project
```

### Terraform

```hcl
# Disable external IPs on all VMs in the project
resource "google_org_policy_policy" "no_external_ip" {
  name   = "projects/my-project/policies/compute.vmExternalIpAccess"
  parent = "projects/my-project"
  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

# Restrict VM images to an approved project
resource "google_org_policy_policy" "trusted_images" {
  name   = "projects/my-project/policies/compute.trustedImageProjects"
  parent = "projects/my-project"
  spec {
    rules {
      values {
        allowed_values = ["projects/my-approved-image-project"]
      }
    }
  }
}

# Restrict regions to us-central1 / us-east1 only
resource "google_org_policy_policy" "restrict_locations" {
  name   = "projects/my-project/policies/gcp.resourceLocations"
  parent = "projects/my-project"
  spec {
    rules {
      values {
        allowed_values = ["in:us-locations"]
      }
    }
  }
}
```

### Concept Deep Dive — IAM vs Org Policy (classic interview question)

| | IAM | Org Policy |
|---|---|---|
| Controls | Who can perform an action | What actions/configs are allowed to exist |
| Applies to | Specific principals | All principals uniformly, including Owners |
| Example | "Jane can create VMs" | "No VM anywhere in this project may have an external IP, no matter who creates it" |

**Interview Q&A:**

*Q: A project Owner is still able to create a VM with a public IP even though you want to prevent that entirely. What's wrong?*
A: IAM alone can't prevent this — Owner has `compute.instances.create` with all sub-permissions. You need an **Organization Policy** on `compute.vmExternalIpAccess` set to `denyAll`, which is enforced regardless of IAM role, including for Owners (short of an explicit policy exception).

---

## Module 9: Resource Hierarchy

```
Organization
   ↓
 Folder (optional, nestable)
   ↓
 Project
   ↓
 Resources (VMs, buckets, etc.)
```

- **IAM policies** and **Organization Policies** both inherit down the hierarchy.
- A principal's **effective** IAM permissions on a resource = union of policies at every ancestor level (project + all parent folders + org) — IAM inheritance is always additive, never restrictive.
- Org Policy inheritance can be blocked by explicitly overriding at a lower level (unless the higher-level policy is locked).

### gcloud

```bash
# View the resource hierarchy ancestry of a project
gcloud projects get-ancestors my-project

# List folders under an org
gcloud resource-manager folders list --organization=ORG_ID

# Move a project into a folder
gcloud projects move my-project --folder=FOLDER_ID
```

### Terraform

```hcl
resource "google_folder" "engineering" {
  display_name = "Engineering"
  parent       = "organizations/ORG_ID"
}

resource "google_folder" "prod" {
  display_name = "Production"
  parent       = google_folder.engineering.name
}

resource "google_project" "app_prod" {
  project_id = "app-prod-123"
  name       = "App Production"
  folder_id  = google_folder.prod.folder_id
  billing_account = "XXXXXX-XXXXXX-XXXXXX"
}

# Grant a role at the folder level -> inherited by every project inside
resource "google_folder_iam_member" "eng_viewer" {
  folder = google_folder.engineering.name
  role   = "roles/viewer"
  member = "group:engineering-all@example.com"
}
```

### Concept Deep Dive

**Interview Q&A:**

*Q: If a user has `roles/viewer` at the Organization level and `roles/storage.admin` at the Project level, what's their effective access on a bucket in that project?*
A: Both — IAM inheritance is purely additive. They get the union: Viewer (read-only) org-wide, plus full Storage Admin specifically on that project's buckets. There's no "override" or "narrowing" concept in IAM inheritance the way there is in Org Policy.

*Q: Why use Folders instead of just flat Projects under the Org?*
A: Folders let you apply IAM and Org Policy once at a logical grouping (e.g., per business unit, per environment like prod/non-prod) and have it inherit to every project inside, instead of repeating bindings/policies per project. It also scopes billing/security boundaries and delegated folder-admin responsibilities cleanly.

---

## Module 10: Cloud Identity

Cloud Identity is Google's free (or premium) identity service — the underlying user/group directory GCP IAM principals are drawn from, independent of Workspace (Gmail/Docs).

### Capabilities

- **User Management** — create/manage user accounts under your verified domain without needing Workspace mailboxes.
- **Groups** — the foundation for group-based IAM access (Module 7).
- **SSO** — federate Cloud Identity with an external IdP (Okta, Azure AD, ADFS) via SAML so users log in with corporate credentials.
- **MFA** — enforce 2-Step Verification / security keys org-wide via Admin Console.

### Console Steps

1. admin.google.com (Cloud Identity Admin Console, separate from Cloud Console) → Users → Add User.
2. Groups → Create Group → add members → set group as a Google Group principal usable in IAM.
3. Security → SSO with third-party IdP → configure SAML metadata / IdP entity ID / SSO URL / certificate.
4. Security → 2-Step Verification → Enforce for all users / specific OUs.

**Note:** Most Cloud Identity administration happens outside the GCP Console proper, in the Google Admin Console — a detail interviewers sometimes probe.

### MFA / 2-Step Verification — Detailed Walkthrough

MFA enforcement in Cloud Identity is managed per **Organizational Unit (OU)**, not per individual user, letting you roll out enforcement incrementally (e.g., admins first, then all staff).

**Console steps (Admin Console, admin.google.com):**
1. Directory → Organizational Units → create/select an OU (e.g., "Engineering").
2. Security → Authentication → 2-Step Verification.
3. Select the target OU from the org unit picker (top-left tree).
4. Turn **Allow users to turn on 2-Step Verification** ON, then separately **Enforce 2-Step Verification starting** (immediately, or a future date to give users a grace period).
5. Under **Methods**, restrict to phishing-resistant methods only (Security Keys / Google Prompt) rather than allowing SMS, if higher assurance is required — SMS is phishable via SIM-swap.
6. Save. Enforcement propagates within a few minutes to hours depending on org size.

**Admin SDK API (for automation — no dedicated `gcloud` command exists for 2SV enforcement; it's managed via the Admin SDK Directory API, not Cloud Resource Manager):**

```bash
# Check a user's 2SV enrollment status
curl -X GET \
  -H "Authorization: Bearer $(gcloud auth print-access-token --scopes=https://www.googleapis.com/auth/admin.directory.user.readonly)" \
  "https://admin.googleapis.com/admin/directory/v1/users/jane@example.com?fields=isEnrolledIn2Sv,isEnforcedIn2Sv"
```

```hcl
# Terraform: googleworkspace provider manages OU-level 2SV enforcement
# (separate provider from the core google/google-beta providers)
terraform {
  required_providers {
    googleworkspace = {
      source = "hashicorp/googleworkspace"
    }
  }
}

resource "googleworkspace_org_unit" "engineering" {
  name         = "Engineering"
  parent_org_unit_path = "/"
  description  = "Engineering org unit — MFA enforced"
}

# 2SV enforcement itself is typically set via the Admin Console UI or Admin SDK;
# googleworkspace_user resources can at least confirm/report is2SvEnrolled per user
# for drift-detection / compliance-reporting purposes.
data "googleworkspace_user" "jane" {
  primary_email = "jane@example.com"
}

output "jane_2sv_enrolled" {
  value = data.googleworkspace_user.jane.is_enrolled_in_2sv
}
```

**Interview Q&A:**

*Q: Why enforce MFA at the OU level instead of individually per user?*
A: OU-level enforcement lets you stage rollout (pilot group → all staff) without touching individual user settings, inherits automatically to new users added to that OU, and gives a single audit point to verify coverage — checking "is 2SV enforced on this OU" instead of validating hundreds of individual accounts.

*Q: Why prefer Security Keys/Google Prompt over SMS for 2-Step Verification?*
A: SMS-based codes are vulnerable to SIM-swap and SS7 interception attacks — an attacker can socially engineer a carrier into porting the victim's number. Security keys (FIDO2/WebAuthn) and Google Prompt are phishing-resistant because they're bound to the physical device or cryptographic key, not the phone number.

**Interview Q&A:**

*Q: How do IAM Groups relate to Cloud Identity?*
A: Google Groups used as IAM principals (`group:name@domain.com`) are managed through Cloud Identity/Workspace, not through IAM & Admin in the GCP Console itself. IAM only references the group; group membership lifecycle (add/remove users) happens in the Admin Console or via Cloud Identity Groups API — which is why group-based IAM decouples access changes from Terraform/IAM policy edits entirely.

---

## Module 11: Security Command Center (SCC)

SCC is GCP's centralized security and risk management platform — a single pane for asset inventory, vulnerabilities, threats, and misconfigurations across an organization.

### Features

- **Vulnerability Scanning** — Web Security Scanner (App Engine/Compute web apps), container/OS vulnerability scanning via Artifact Analysis integration.
- **Threat Detection** — Event Threat Detection watches audit/VPC/DNS logs for indicators like brute force SSH, malware domains, IAM anomalies, crypto-mining patterns.
- **Compliance** — built-in dashboards mapping findings to CIS Benchmarks, PCI-DSS, NIST, ISO 27001.
- **Findings** — the core unit: a specific issue (e.g., "Public bucket ACL", "Overprivileged service account") with severity, category, and affected asset.
- **Security Health Analytics** — automated misconfiguration scanner (its own module below).

### Console Steps

1. Console → Security → Security Command Center → Overview (requires Standard or Premium tier enabled at the Org level).
2. Findings tab → filter by category/severity/asset.
3. Settings → enable/disable specific detectors (Security Health Analytics, Event Threat Detection, Web Security Scanner, Container Threat Detection).

### gcloud

```bash
# List findings
gcloud scc findings list organizations/ORG_ID \
  --filter="state=\"ACTIVE\" AND severity=\"HIGH\""

# List assets
gcloud scc assets list organizations/ORG_ID \
  --filter="security_center_properties.resource_type=\"google.cloud.storage.Bucket\""
```

### Terraform

```hcl
resource "google_scc_notification_config" "high_severity_alerts" {
  config_id    = "high-severity-findings"
  organization = "ORG_ID"
  description  = "Notify on high severity SCC findings"
  pubsub_topic = google_pubsub_topic.scc_findings.id

  streaming_config {
    filter = "severity=\"HIGH\" OR severity=\"CRITICAL\""
  }
}

resource "google_pubsub_topic" "scc_findings" {
  name = "scc-findings-topic"
}
```

**Interview Q&A:**

*Q: How would you get real-time alerts when a Critical-severity finding appears in SCC?*
A: Configure a `google_scc_notification_config` streaming Pub/Sub export filtered on severity, then subscribe a Cloud Function or Cloud Run service to that topic to route into Slack/PagerDuty/email — SCC findings themselves don't push notifications natively without this export step.

---

## Module 12: Cloud Audit Logs

Every GCP project automatically generates four audit log streams:

| Type | Contents | Enabled by default? |
|---|---|---|
| **Admin Activity** | API calls that modify configuration/metadata (e.g., `SetIamPolicy`, `compute.instances.insert`) | Always on, cannot be disabled, free |
| **Data Access** | Reads/writes of user data (e.g., `storage.objects.get`) | Off by default (except BigQuery) — must be explicitly enabled, incurs cost |
| **Policy Denied** | Requests denied due to a security policy (e.g., VPC-SC, Org Policy) | Always on |
| **System Event** | GCP-internal actions not from a user (e.g., live migration) | Always on, cannot be disabled |

### Console Steps

1. Console → IAM & Admin → Audit Logs.
2. Select a service (e.g., Cloud Storage) → check boxes for Admin Read / Data Read / Data Write → Save (this enables Data Access logs, which are off by default due to volume/cost).
3. View logs: Console → Logging → Logs Explorer → filter `logName:"cloudaudit.googleapis.com"`.

### gcloud

```bash
# Enable Data Access audit logs for all services via policy
cat > audit-policy.yaml << EOF
auditConfigs:
- service: allServices
  auditLogConfigs:
  - logType: ADMIN_READ
  - logType: DATA_READ
  - logType: DATA_WRITE
EOF
gcloud projects get-iam-policy my-project --format=json > policy.json
# merge audit-policy.yaml into policy.json's auditConfigs, then:
gcloud projects set-iam-policy my-project policy.json

# Query: who deleted a Compute Engine VM?
gcloud logging read \
  'logName="projects/my-project/logs/cloudaudit.googleapis.com%2Factivity"
   AND protoPayload.methodName="v1.compute.instances.delete"' \
  --project=my-project --limit=20 --format=json
```

### Terraform — enable Data Access logs

```hcl
resource "google_project_iam_audit_config" "all_services" {
  project = "my-project"
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
```

### Retention & Export

- Admin Activity / System Event / Policy Denied: retained **400 days** by default in the `_Required` log bucket (immutable, can't be deleted or have retention shortened).
- Data Access: retained **30 days** by default in `_Default` bucket (configurable, can be routed elsewhere).
- For long-term retention/compliance, export via a **log sink** to BigQuery (for querying) or a locked GCS bucket (for immutable archive, pair with a retention policy + Bucket Lock).

```hcl
resource "google_logging_project_sink" "audit_to_bq" {
  name        = "audit-logs-to-bigquery"
  destination = "bigquery.googleapis.com/projects/my-project/datasets/audit_logs"
  filter      = "logName:\"cloudaudit.googleapis.com\""
  unique_writer_identity = true
}

resource "google_bigquery_dataset_iam_member" "sink_writer" {
  dataset_id = google_bigquery_dataset.audit_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.audit_to_bq.writer_identity
}
```

### Concept Deep Dive — Audit Investigation Walkthrough

**Interview scenario: "Audit who deleted a Compute Engine VM."**
1. Logs Explorer query: `protoPayload.methodName="v1.compute.instances.delete"`.
2. Inspect `protoPayload.authenticationInfo.principalEmail` for the actor.
3. Inspect `protoPayload.requestMetadata.callerIp` for source IP.
4. Cross-reference `protoPayload.authorizationInfo` to confirm which IAM permission/role authorized the call.
5. If the actor was a service account, trace back further: was it invoked via impersonation? Check `protoPayload.authenticationInfo.serviceAccountDelegationInfo` for the human who impersonated it.

**Interview Q&A:**

*Q: Why are Data Access logs off by default when Admin Activity logs aren't?*
A: Data Access logs capture every single read/write of user data (e.g., every GCS object read) — at scale this is extremely high volume and directly billed as regular logging ingestion. Admin Activity logs only capture configuration-changing API calls, which are comparatively rare and are core to security accountability, so Google makes them free and mandatory.

---

## Module 13: Cloud Logging Security

- **Log Router** — the ingestion pipeline that evaluates every log entry against **sinks** (routing rules) and delivers matching entries to destinations (Cloud Logging bucket, BigQuery, GCS, Pub/Sub, Splunk via Pub/Sub).
- **Log Buckets** — storage containers for logs within Cloud Logging itself (`_Required` and `_Default` exist per project automatically; custom buckets can be created for isolation/retention control).
- **Log Views** — sub-bucket-level IAM scoping; lets you grant a team visibility into only a filtered subset of a bucket's logs (e.g., only their service's logs) without granting access to the whole bucket.
- **CMEK for Logging** — encrypt log buckets with a customer-managed key instead of Google-default encryption, for compliance requirements.
- **Log Analytics** — SQL-based analysis directly over a log bucket (linked BigQuery-like querying) without needing a separate export.

### gcloud

```bash
# Create a custom log bucket with 365-day retention and CMEK
gcloud logging buckets create security-logs \
  --location=us-central1 \
  --retention-days=365 \
  --cmek-kms-key-name=projects/my-project/locations/us-central1/keyRings/log-ring/cryptoKeys/log-key

# Create a log view scoped to one service
gcloud logging views create payments-only \
  --bucket=security-logs --location=us-central1 \
  --log-filter='resource.labels.service_name="payments-api"'

# Grant a team access to only that view
gcloud logging views add-iam-policy-binding payments-only \
  --bucket=security-logs --location=us-central1 \
  --member="group:payments-team@example.com" \
  --role="roles/logging.viewAccessor"
```

### Terraform

```hcl
resource "google_logging_project_bucket_config" "security_logs" {
  project        = "my-project"
  location       = "us-central1"
  bucket_id      = "security-logs"
  retention_days = 365
  cmek_settings {
    kms_key_name = google_kms_crypto_key.log_key.id
  }
}

resource "google_logging_log_view" "payments_only" {
  name        = "payments-only"
  bucket      = google_logging_project_bucket_config.security_logs.id
  filter      = "resource.labels.service_name=\"payments-api\""
}
```

### Log Analytics — SQL Queries Over Log Buckets

Log Analytics lets you run SQL directly against a log bucket's contents without exporting to BigQuery first. It requires the bucket to be **upgraded to Log Analytics** (one-time, reversible-in-name-only — the linked BigQuery dataset persists).

**Console steps:**
1. Logging → Log Buckets → select bucket → **Upgrade to use Log Analytics** (creates a linked, read-only BigQuery dataset view automatically).
2. Logging → Log Analytics → write SQL against the `_AllLogs` view, or the bucket-specific linked table.

**gcloud — enable Log Analytics on a bucket:**

```bash
gcloud logging buckets update security-logs \
  --location=us-central1 \
  --enable-analytics
```

**Example SQL query — find all IAM policy changes in the last 7 days:**

```sql
SELECT
  timestamp,
  proto_payload.audit_log.authentication_info.principal_email AS actor,
  proto_payload.audit_log.method_name AS method,
  proto_payload.audit_log.resource_name AS resource
FROM
  `my-project.security_logs._AllLogs`
WHERE
  proto_payload.audit_log.method_name = "SetIamPolicy"
  AND timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
ORDER BY
  timestamp DESC
```

**Example SQL query — count firewall denies by source IP (finding scan/attack patterns):**

```sql
SELECT
  json_payload.disallowed_conn_state.src_ip AS source_ip,
  COUNT(*) AS deny_count
FROM
  `my-project.security_logs._AllLogs`
WHERE
  log_id = "compute.googleapis.com/firewall"
  AND json_payload.disposition = "DENIED"
GROUP BY
  source_ip
ORDER BY
  deny_count DESC
LIMIT 20
```

### Terraform — enable Log Analytics

```hcl
resource "google_logging_project_bucket_config" "security_logs_analytics" {
  project          = "my-project"
  location         = "us-central1"
  bucket_id        = "security-logs"
  retention_days   = 365
  enable_analytics = true   # links a queryable BigQuery-backed dataset automatically
}
```

**Interview Q&A:**

*Q: When would you use Log Analytics instead of exporting logs to BigQuery via a sink?*
A: Log Analytics gives ad-hoc SQL querying directly on the log bucket with no separate export/sink pipeline, extra storage cost, or duplication — useful for occasional investigative queries. A dedicated sink to BigQuery is better when you need long-term structured analytics, joins with other business data, scheduled queries/dashboards, or retention independent of the Logging bucket's own retention settings.

---

## Module 14: Cloud Monitoring Security

- **Alert Policies** — condition-based rules (metric threshold, log-based metric, uptime failure) that trigger notifications.
- **Notification Channels** — email, SMS, PagerDuty, Slack (via webhook), Pub/Sub.
- **Uptime Checks** — synthetic probes against an endpoint from multiple global locations.
- **Dashboards** — visualizations; security-relevant dashboards typically chart IAM policy changes, failed auth attempts, firewall denies.

### Terraform — alert on IAM policy changes (security-relevant example)

```hcl
resource "google_monitoring_notification_channel" "security_email" {
  display_name = "Security Team"
  type         = "email"
  labels = { email_address = "security@example.com" }
}

resource "google_logging_metric" "iam_policy_changes" {
  name   = "iam_policy_change_count"
  filter = "protoPayload.methodName=\"SetIamPolicy\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "google_monitoring_alert_policy" "iam_change_alert" {
  display_name = "IAM Policy Changed"
  combiner     = "OR"
  conditions {
    display_name = "SetIamPolicy called"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/iam_policy_change_count\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.security_email.id]
}
```

**Interview Q&A:**

*Q: How would you get alerted the moment someone grants Owner role on a project?*
A: A log-based metric filtering `protoPayload.methodName="SetIamPolicy" AND protoPayload.serviceData.policyDelta.bindingDeltas.role="roles/owner"`, feeding a Monitoring alert policy with a threshold of >0 over a short window, notifying a security channel — this closes the loop from raw audit log to real-time page.

### Uptime Checks — Detailed

Synthetic probes hit an endpoint (HTTP/HTTPS/TCP) from multiple global points-of-presence on a schedule (1, 5, 10, or 15 min), independent of any traffic your app actually receives — catches outages even during low-traffic windows.

**Console steps:**
1. Monitoring → Uptime Checks → Create Uptime Check.
2. Protocol (HTTPS), Resource Type (URL / App Engine / Cloud Run / Instance), hostname/path, check frequency, regions to probe from.
3. Response validation: expected status code, optional response content match (string present in body).
4. Alerting: attach directly to a new or existing alert policy for "uptime check failed."

**gcloud:**

```bash
gcloud monitoring uptime create app-uptime-check \
  --resource-type=uptime-url \
  --resource-labels=host=app.example.com \
  --protocol=https --path=/healthz \
  --period=1 --timeout=10
```

**Terraform:**

```hcl
resource "google_monitoring_uptime_check_config" "app_uptime" {
  display_name = "app-uptime-check"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = "my-project"
      host       = "app.example.com"
    }
  }
}

resource "google_monitoring_alert_policy" "uptime_failure_alert" {
  display_name = "App Uptime Check Failing"
  combiner     = "OR"
  conditions {
    display_name = "Uptime check failed"
    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.security_email.id]
}
```

**Security-relevant angle:** uptime checks aren't purely an availability tool — a sudden new "failing" check on an internal-only endpoint can indicate a firewall rule or IAP policy was accidentally tightened, and conversely, an uptime check unexpectedly *succeeding* against an endpoint that should require auth can indicate an IAP/IAM misconfiguration exposing it publicly.

### Dashboards — Security-Relevant Example

**Console steps:**
1. Monitoring → Dashboards → Create Dashboard.
2. Add widgets: a **Scorecard** or **Line chart** on the `iam_policy_change_count` log-based metric (from above), a chart on firewall `DENIED` count via a similar log-based metric, and an **Alert chart** widget pulling in active alert policy status.

**Terraform:**

```hcl
resource "google_monitoring_dashboard" "security_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Security Overview"
    gridLayout = {
      widgets = [
        {
          title = "IAM Policy Changes (24h)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"logging.googleapis.com/user/iam_policy_change_count\""
                  aggregation = { alignmentPeriod = "3600s", perSeriesAligner = "ALIGN_COUNT" }
                }
              }
            }]
          }
        },
        {
          title = "Uptime Check Pass Rate"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\""
                  aggregation = { alignmentPeriod = "300s", perSeriesAligner = "ALIGN_FRACTION_TRUE" }
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

**Interview Q&A:**

*Q: How would uptime checks help you catch a security misconfiguration, not just an outage?*
A: An uptime check against an internal-only admin endpoint that unexpectedly starts **passing** without authentication is a strong signal an IAP binding or firewall rule was loosened; conversely a check on a public health endpoint that suddenly starts **failing** can indicate an overly aggressive Cloud Armor rule or firewall change blocking legitimate traffic. Pairing uptime checks with alerting turns them into a lightweight continuous config-verification signal, not just an SLA measurement.

---

## Module 15: VPC Security

### Firewall Rules

VPC firewall rules are stateful, apply at the network level (not per-subnet), and evaluate by **priority** (lower number = higher priority, 0–65535, default 1000).

Key fields: direction (ingress/egress), action (allow/deny), priority, target (by network tag or service account), source/destination (CIDR range, tag, or SA), protocol/port.

```bash
# Deny all ingress by default (implicit deny already exists, but explicit is clearer for review)
gcloud compute firewall-rules create deny-all-ingress \
  --network=my-vpc --direction=INGRESS --action=DENY --rules=all --priority=65534

# Allow SSH only from IAP's range, tagged instances only
gcloud compute firewall-rules create allow-iap-ssh \
  --network=my-vpc --direction=INGRESS --action=ALLOW \
  --rules=tcp:22 --source-ranges=35.235.240.0/20 --target-tags=ssh-allowed --priority=1000

# Allow internal app-to-db traffic scoped by service account, not just CIDR
gcloud compute firewall-rules create allow-app-to-db \
  --network=my-vpc --direction=INGRESS --action=ALLOW \
  --rules=tcp:5432 \
  --target-service-accounts=db-sa@my-project.iam.gserviceaccount.com \
  --source-service-accounts=app-sa@my-project.iam.gserviceaccount.com
```

### Terraform

```hcl
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "deny-all-ingress"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 65534
  deny { protocol = "all" }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "allow-iap-ssh"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]   # IAP's fixed TCP forwarding range
  target_tags   = ["ssh-allowed"]
}

resource "google_compute_firewall" "allow_app_to_db" {
  name      = "allow-app-to-db"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
  target_service_accounts = [google_service_account.db_sa.email]
  source_service_accounts = [google_service_account.app_sa.email]
}
```

### Concept Deep Dive — Tags vs Service Accounts as firewall targets

Tags are simple strings, mutable by anyone with `compute.instances.setTags`, and not tied to identity — easy to misconfigure or spoof by tagging an unintended VM. Service-account-scoped firewall rules bind to the VM's actual identity, which requires `iam.serviceAccountUser` to attach, making it a stronger, IAM-backed security boundary. **Best practice in mature environments: prefer service-account targeting over network tags** for anything security-sensitive.

**Interview Q&A:**

*Q: Why prefer service-account-based firewall targeting over tag-based?*
A: Tags are just string labels — anyone with permission to edit a VM's metadata can add/remove them, potentially placing an unintended VM inside a sensitive rule's scope. Service accounts are IAM-governed identities; attaching a different SA to a VM requires `roles/iam.serviceAccountUser`, so SA-scoped firewall rules inherit IAM's access control instead of being freely mutable.

---

## Module 16: Network Security

| Service | Purpose |
|---|---|
| **Cloud Armor** | WAF + DDoS protection at the load balancer edge — L7 rules (OWASP CRS, geo-blocking, rate limiting, bot management) |
| **Cloud IDS** | Managed intrusion detection (built on Palo Alto tech) — mirrors traffic for signature-based threat detection |
| **Cloud NAT** | Outbound-only internet access for private (no external IP) instances, without exposing them to inbound internet |
| **Private Google Access** | Lets VMs without external IPs reach Google APIs (storage, BigQuery, etc.) over Google's internal network |
| **Private Service Connect (PSC)** | Privately consume/publish services (yours or a vendor's) via internal IP, without VPC peering or internet exposure |

### gcloud — Cloud NAT (very common interview setup)

```bash
gcloud compute routers create nat-router --network=my-vpc --region=us-central1

gcloud compute routers nats create nat-config \
  --router=nat-router --region=us-central1 \
  --nat-all-subnet-ip-ranges \
  --auto-allocate-nat-external-ips
```

### Terraform — Cloud NAT + Cloud Armor

```hcl
resource "google_compute_router" "nat_router" {
  name    = "nat-router"
  network = google_compute_network.vpc.id
  region  = "us-central1"
}

resource "google_compute_router_nat" "nat_config" {
  name                               = "nat-config"
  router                             = google_compute_router.nat_router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_security_policy" "waf_policy" {
  name = "waf-policy"

  rule {
    action   = "deny(403)"
    priority = 1000
    match {
      expr { expression = "evaluatePreconfiguredExpr('sqli-stable')" }
    }
    description = "Block SQL injection"
  }

  rule {
    action   = "throttle"
    priority = 2000
    match {
      versioned_expr = "SRC_IPS_V1"
      config { src_ip_ranges = ["*"] }
    }
    rate_limit_options {
      conform_action = "allow"
      exceed_action  = "deny(429)"
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limit to 100 req/min per IP"
  }

  rule {
    action      = "allow"
    priority    = 2147483647
    match { versioned_expr = "SRC_IPS_V1"; config { src_ip_ranges = ["*"] } }
    description = "Default allow"
  }
}
```

**Interview Q&A:**

*Q: How do private (no external IP) GKE nodes pull images from a public registry or reach Google APIs?*
A: Either **Private Google Access** (enabled per-subnet) for reaching `*.googleapis.com` over Google's internal network, or **Cloud NAT** for genuinely external destinations — the two are complementary: Private Google Access avoids the public internet entirely for Google services, Cloud NAT handles everything else outbound.

### Cloud IDS — Detailed

Cloud IDS creates a managed **peered network** that mirrors traffic from your VPC to a Palo Alto Networks-based threat detection engine, generating findings (which flow into SCC) for known malware signatures, C2 traffic, spyware, and other network-layer threats — a detection-only control (it doesn't block, unlike Cloud Armor); pair it with firewall rules or Cloud Armor for actual prevention.

**Console steps:**
1. Network Security → Cloud IDS → Create Endpoint.
2. Choose the VPC network and zone, select a mirroring **peer network CIDR range** (dedicated /29 range reserved for the IDS peering — must not overlap existing subnets).
3. Choose a **threat severity level** to report on (Informational through Critical).
4. Create a **Packet Mirroring policy** pointing relevant subnets/tags at the IDS endpoint as the mirror collector.

**gcloud:**

```bash
# Create the IDS endpoint
gcloud ids endpoints create my-ids-endpoint \
  --network=my-vpc --zone=us-central1-a \
  --severity=INFORMATIONAL

# Create a packet mirroring policy pointing traffic at the endpoint
gcloud compute packet-mirrorings create mirror-to-ids \
  --region=us-central1 --network=my-vpc \
  --collector-ilb=my-ids-endpoint-ilb \
  --mirrored-subnets=my-subnet
```

**Terraform:**

```hcl
resource "google_cloud_ids_endpoint" "my_ids" {
  name     = "my-ids-endpoint"
  location = "us-central1-a"
  network  = google_compute_network.vpc.id
  severity = "INFORMATIONAL"
}

resource "google_compute_packet_mirroring" "mirror_to_ids" {
  name    = "mirror-to-ids"
  region  = "us-central1"
  network {
    url = google_compute_network.vpc.id
  }
  collector_ilb {
    url = google_cloud_ids_endpoint.my_ids.endpoint_forwarding_rule
  }
  mirrored_resources {
    subnetworks {
      url = google_compute_subnetwork.my_subnet.id
    }
  }
}
```

**Interview Q&A:**

*Q: Does Cloud IDS block malicious traffic, or only detect it?*
A: Detect only — Cloud IDS mirrors a copy of your traffic to the inspection engine and generates findings/alerts (surfaced in SCC), but it does not sit inline and cannot drop packets itself. Actual blocking requires acting on those findings via firewall rule updates, Cloud Armor policies, or an automated response pipeline (e.g., a Cloud Function triggered off IDS findings that updates a firewall deny rule).

---

## Module 17: Encryption

| State | Default in GCP | Options |
|---|---|---|
| **At Rest** | Always on, Google-managed keys (AES-256), transparent, no config needed | Customer-managed (CMEK) or customer-supplied (CSEK) for more control |
| **In Transit** | Encrypted automatically between GCP data centers and for most client connections (TLS) | Enforce via `require-ssl` flags, HTTPS-only load balancers, mTLS in service mesh |
| **In Use** | Not encrypted by default — data is plaintext in memory during processing | **Confidential Computing** (Module 25) encrypts memory during processing |

### Key Management Options

| Type | Who holds the key | Use case |
|---|---|---|
| **Google-managed** | Google, fully automatic | Default, zero-config, fine for most workloads |
| **CMEK** (Customer-Managed Encryption Keys) | You, via Cloud KMS | Compliance needs control over key rotation/revocation; you can disable the key to instantly deny access to all data encrypted with it |
| **CSEK** (Customer-Supplied Encryption Keys) | You, supplied per-request, not stored by Google at all | Maximum control (Google never persists the key); operationally heavier — you must supply the key on every access |

```bash
# CMEK example: encrypt a GCS bucket with a Cloud KMS key
gcloud kms keyrings create my-ring --location=us-central1
gcloud kms keys create my-key --location=us-central1 --keyring=my-ring --purpose=encryption

gcloud storage buckets create gs://my-cmek-bucket \
  --default-encryption-key=projects/my-project/locations/us-central1/keyRings/my-ring/cryptoKeys/my-key
```

**Interview Q&A:**

*Q: What's the practical security benefit of CMEK over Google-managed default encryption?*
A: With CMEK, you control the key's IAM permissions and lifecycle — you can **disable or destroy the key** to instantly and cryptographically deny access to all data encrypted under it (a "kill switch"), independent of the underlying storage service's own access controls. It also satisfies compliance requirements mandating customer key ownership/rotation control.

---

## Module 18: Cloud KMS

Cloud KMS manages cryptographic keys used for CMEK, application-level encryption, and signing.

### Structure

```
Key Ring (regional container, immutable location once created)
   └── Crypto Key (a named key, has a rotation policy)
         └── Key Versions (each rotation creates a new version; old versions kept for decrypting old data)
```

### gcloud

```bash
gcloud kms keyrings create app-ring --location=us-central1

gcloud kms keys create app-key \
  --location=us-central1 --keyring=app-ring \
  --purpose=encryption --rotation-period=90d --next-rotation-time=2026-10-01T00:00:00Z

# Grant encrypt/decrypt to an application service account
gcloud kms keys add-iam-policy-binding app-key \
  --location=us-central1 --keyring=app-ring \
  --member="serviceAccount:app-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# Encrypt / decrypt via CLI (for app-level envelope encryption)
gcloud kms encrypt --location=us-central1 --keyring=app-ring --key=app-key \
  --plaintext-file=secret.txt --ciphertext-file=secret.enc

gcloud kms decrypt --location=us-central1 --keyring=app-ring --key=app-key \
  --ciphertext-file=secret.enc --plaintext-file=secret-decrypted.txt
```

### Terraform

```hcl
resource "google_kms_key_ring" "app_ring" {
  name     = "app-ring"
  location = "us-central1"
}

resource "google_kms_crypto_key" "app_key" {
  name            = "app-key"
  key_ring        = google_kms_key_ring.app_ring.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true   # protect against accidental deletion — destroying a key permanently loses data
  }
}

resource "google_kms_crypto_key_iam_member" "app_sa_encrypt_decrypt" {
  crypto_key_id = google_kms_crypto_key.app_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.app_sa.email}"
}
```

### Concept Deep Dive

**Key rotation doesn't re-encrypt existing data.** Rotating a Cloud KMS key creates a new key *version* used for future encryption; data encrypted under older versions still requires those versions to remain enabled for decryption. "Destroying" a key version (not just disabling) is irreversible and permanently loses access to anything encrypted solely with it — a very common "what happens if..." interview trap.

**Interview Q&A:**

*Q: If you rotate a CMEK key, does previously encrypted data automatically get re-encrypted with the new key version?*
A: No. Rotation only affects future encrypt operations. Old data remains encrypted under the prior key version, which must stay enabled (not destroyed) for that data to remain decryptable. Full re-encryption under the new version requires reading and rewriting the data explicitly.

---

## Module 19: Secret Manager

Stores API keys, passwords, certificates, and other secrets as versioned, IAM-controlled, encrypted (via Google-managed or CMEK) objects — replaces storing secrets in code, environment variables, or config files.

### gcloud

```bash
# Create a secret and its first version
echo -n "supersecretpassword" | gcloud secrets create db-password \
  --data-file=- --replication-policy=automatic

# Add a new version (rotation)
echo -n "newpassword" | gcloud secrets versions add db-password --data-file=-

# Access a specific version
gcloud secrets versions access latest --secret=db-password

# Grant access
gcloud secrets add-iam-policy-binding db-password \
  --member="serviceAccount:app-sa@my-project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Terraform

```hcl
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_v1" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password   # pass in via -var, never hardcode in .tf
}

resource "google_secret_manager_secret_iam_member" "app_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_sa.email}"
}
```

### Integration with GKE (mounted as a volume via CSI driver)

```yaml
# SecretProviderClass (requires Secret Manager CSI driver add-on enabled on the cluster)
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: db-password-spc
spec:
  provider: gcp
  parameters:
    secrets: |
      - resourceName: "projects/my-project/secrets/db-password/versions/latest"
        path: "db-password"
```

### Integration with Cloud Run

```bash
gcloud run deploy payments-api \
  --image=gcr.io/my-project/payments-api \
  --set-secrets=DB_PASSWORD=db-password:latest \
  --service-account=app-sa@my-project.iam.gserviceaccount.com
```

**Interview Q&A:**

*Q: How would you rotate a database password used by a running GKE workload with zero downtime?*
A: Add a new Secret Manager version (`versions add`), update the Secret Manager CSI SecretProviderClass rotation config (`rotationPollInterval`) so mounted secret files auto-refresh, or trigger a rolling pod restart to remount `latest`; combine with the DB itself supporting dual passwords briefly (old + new both valid) during the cutover window to avoid a hard failure moment.

---

## Module 20: Certificate Manager

Manages SSL/TLS certificates for load balancers.

| Type | Managed by | Renewal |
|---|---|---|
| Google-managed certificates | Google, auto-provisioned via DNS/HTTP validation | Automatic |
| Self-managed certificates | You (uploaded PEM cert+key, e.g. from an external CA) | Manual |

### gcloud

```bash
# Google-managed certificate
gcloud certificate-manager certificates create my-cert \
  --domains="app.example.com" --global

# Self-managed (upload your own cert/key)
gcloud certificate-manager certificates create my-cert-self \
  --certificate-file=cert.pem --private-key-file=key.pem --global
```

### Terraform

```hcl
resource "google_certificate_manager_certificate" "app_cert" {
  name = "app-cert"
  managed {
    domains = ["app.example.com"]
  }
}

resource "google_certificate_manager_certificate_map" "app_cert_map" {
  name = "app-cert-map"
}

resource "google_certificate_manager_certificate_map_entry" "app_entry" {
  name         = "app-entry"
  map          = google_certificate_manager_certificate_map.app_cert_map.name
  certificates = [google_certificate_manager_certificate.app_cert.id]
  hostname     = "app.example.com"
}

# Attach to HTTPS load balancer proxy
resource "google_compute_target_https_proxy" "https_proxy" {
  name            = "app-https-proxy"
  url_map         = google_compute_url_map.app_urlmap.id
  certificate_map = "//certificatemanager.googleapis.com/${google_certificate_manager_certificate_map.app_cert_map.id}"
}
```

**Interview Q&A:**

*Q: Google-managed cert provisioning is stuck in "Provisioning" state — what would you check?*
A: DNS validation — confirm the domain's A/AAAA record actually points at the load balancer's reserved external IP, and that there's no CAA record blocking Google's CA. Managed certs won't issue until Google can validate domain ownership via the live DNS record pointing at the LB.

---

## Module 21: Identity-Aware Proxy (IAP)

IAP enforces access control at the application layer — authenticating and authorizing every request based on identity and context, regardless of network location. It's the core building block of GCP's Zero Trust / BeyondCorp model.

### Capabilities

- **Secure Web Applications** — put IAP in front of an HTTPS load balancer; only IAM-authorized users can reach the app, no VPN needed.
- **SSH/RDP Through Browser / IAP Desktop** — tunnel to VMs without external IPs or open firewall ports (uses IAP TCP forwarding on the fixed range `35.235.240.0/20`).
- **TCP Forwarding** — generalizes the above to any TCP-based admin protocol.
- **Access Control** — grant `roles/iap.httpsResourceAccessor` (web) or `roles/iap.tunnelResourceAccessor` (SSH/TCP) per-resource, optionally combined with Access Context Manager conditions for device/context checks.

### gcloud

```bash
# Enable IAP for a backend service, then grant access
gcloud iap web add-iam-policy-binding \
  --resource-type=backend-services --service=my-backend-service \
  --member="group:app-users@example.com" --role="roles/iap.httpsResourceAccessor"

# SSH to a VM with no external IP, via IAP tunnel
gcloud compute ssh my-vm --zone=us-central1-a --tunnel-through-iap
```

### Terraform

```hcl
resource "google_iap_web_backend_service_iam_member" "app_access" {
  project             = "my-project"
  web_backend_service = google_compute_backend_service.app_backend.name
  role                = "roles/iap.httpsResourceAccessor"
  member              = "group:app-users@example.com"
}

resource "google_compute_firewall" "allow_iap_tunnel" {
  name      = "allow-iap-tcp"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }
  source_ranges = ["35.235.240.0/20"]
}
```

**Interview Q&A:**

*Q: How does IAP let you SSH into a VM with no external IP and no open firewall to the internet?*
A: IAP's TCP forwarding tunnels the SSH session through Google's infrastructure from a fixed, well-known IAP source range (`35.235.240.0/20`). You only need a firewall rule allowing TCP:22 from that specific range, and `roles/iap.tunnelResourceAccessor` IAM on the VM — the VM never needs a public IP or a broader open port.

---

## Module 22: Workload Identity (GKE)

Lets Kubernetes Service Accounts (KSAs) act as Google Service Accounts (GSAs) **without any exported key**, replacing the old (deprecated, insecure) pattern of mounting SA key JSON files as Kubernetes Secrets.

### How it works

1. Enable Workload Identity on the GKE cluster (binds the cluster to `PROJECT_ID.svc.id.goog`).
2. Create a GSA with the permissions the workload needs.
3. Bind the KSA to the GSA via `roles/iam.workloadIdentityUser`.
4. Annotate the KSA with the GSA email.
5. Pods using that KSA transparently get GSA credentials from the metadata server proxy — no key file anywhere.

### gcloud

```bash
# Enable Workload Identity on cluster creation
gcloud container clusters create my-cluster \
  --workload-pool=my-project.svc.id.goog

# Create GSA
gcloud iam service-accounts create gke-app-sa

# Bind KSA -> GSA
gcloud iam service-accounts add-iam-policy-binding gke-app-sa@my-project.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:my-project.svc.id.goog[my-namespace/my-ksa]"
```

```bash
# Kubernetes side
kubectl create serviceaccount my-ksa -n my-namespace
kubectl annotate serviceaccount my-ksa -n my-namespace \
  iam.gke.io/gcp-service-account=gke-app-sa@my-project.iam.gserviceaccount.com
```

### Terraform

```hcl
resource "google_container_cluster" "primary" {
  name     = "my-cluster"
  location = "us-central1"
  workload_identity_config {
    workload_pool = "my-project.svc.id.goog"
  }
  # ... other required cluster config ...
}

resource "google_service_account" "gke_app_sa" {
  account_id = "gke-app-sa"
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.gke_app_sa.name
  role                = "roles/iam.workloadIdentityUser"
  member              = "serviceAccount:my-project.svc.id.goog[my-namespace/my-ksa]"
}

resource "google_project_iam_member" "gke_app_sa_permissions" {
  project = "my-project"
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gke_app_sa.email}"
}
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-ksa
  namespace: my-namespace
  annotations:
    iam.gke.io/gcp-service-account: gke-app-sa@my-project.iam.gserviceaccount.com
---
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: my-namespace
spec:
  serviceAccountName: my-ksa
  containers:
  - name: app
    image: gcr.io/my-project/my-app
```

### Best Practices

- Never fall back to mounting SA key JSON as a Kubernetes Secret — defeats the entire purpose and reintroduces long-lived credential risk.
- Use a **1:1 or narrow** KSA-to-GSA mapping per workload/namespace rather than one shared GSA for the whole cluster — limits blast radius.
- Combine with GKE **Autopilot** or Binary Authorization for defense in depth.

**Interview Q&A:**

*Q: Why is Workload Identity preferred over mounting a service account key as a Kubernetes Secret?*
A: Kubernetes Secrets are base64-encoded, not encrypted by default at the etcd layer unless you've enabled application-layer encryption, and a leaked key has no expiry. Workload Identity issues short-lived tokens dynamically via the metadata server proxy, tied to the pod's KSA identity — no static credential exists to leak, rotate, or accidentally commit.

---

## Module 23: Binary Authorization

Enforces that only **verified, signed** container images can be deployed to GKE/Cloud Run — blocks deployment of unscanned, unsigned, or untrusted images even if someone has `kubectl` access.

### Concepts

- **Attestations** — a signed statement that an image passed a specific check (e.g., "passed vulnerability scan," "built by CI pipeline X"), created using a KMS key.
- **Attestors** — the identity/key that verifies and creates attestations.
- **Deployment Policies** — cluster-level rules requiring one or more attestations before an image can run.

### gcloud

```bash
# Enable Binary Authorization on a cluster
gcloud container clusters update my-cluster --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE

# Create a note + attestor backed by a KMS key
gcloud container binauthz attestors create ci-attestor \
  --attestation-authority-note=ci-note \
  --attestation-authority-note-project=my-project

gcloud container binauthz attestors public-keys add \
  --attestor=ci-attestor --keyversion=1 \
  --keyversion-key=ci-key --keyversion-keyring=binauthz-ring --keyversion-location=us-central1

# Sign an image after it passes CI checks
gcloud container binauthz attestations sign-and-create \
  --artifact-url=us-central1-docker.pkg.dev/my-project/repo/app@sha256:... \
  --attestor=ci-attestor --keyversion=1 \
  --keyversion-key=ci-key --keyversion-keyring=binauthz-ring --keyversion-location=us-central1
```

### Terraform

```hcl
resource "google_binary_authorization_attestor" "ci_attestor" {
  name = "ci-attestor"
  attestation_authority_note {
    note_reference = google_container_analysis_note.ci_note.name
    public_keys {
      id = "ci-key"
      pkix_public_key {
        public_key_pem      = file("attestor-pubkey.pem")
        signature_algorithm = "RSA_PSS_2048_SHA256"
      }
    }
  }
}

resource "google_binary_authorization_policy" "policy" {
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.ci_attestor.name]
  }
  cluster_admission_rules {
    cluster            = "us-central1-a.my-cluster"
    evaluation_mode     = "REQUIRE_ATTESTATION"
    enforcement_mode    = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    require_attestations_by = [google_binary_authorization_attestor.ci_attestor.name]
  }
}
```

**Interview Q&A:**

*Q: How does Binary Authorization stop a compromised CI/CD pipeline from deploying a malicious image straight to prod?*
A: Even if someone bypasses the pipeline and tries `kubectl apply` or `gcloud run deploy` directly, GKE/Cloud Run consults the Binary Authorization policy at admission time and rejects any image lacking the required cryptographic attestation — the attestation can only be created by holders of the KMS signing key used by the legitimate, trusted CI stage (e.g., "passed vuln scan"), so a rogue deploy of an unscanned image is blocked regardless of how it was submitted.

---

## Module 24: Shielded VM

Hardens Compute Engine VMs against rootkits/bootkits and firmware-level attacks using three features, all default-on for new VMs on supported images:

| Feature | Protects Against |
|---|---|
| **Secure Boot** | Unsigned/unauthorized boot loaders and kernel-level malware — verifies digital signature of each boot component |
| **vTPM (virtual Trusted Platform Module)** | Provides a hardware-root-of-trust equivalent for key generation/attestation without physical TPM hardware |
| **Integrity Monitoring** | Compares boot measurements against a trusted baseline at each boot; surfaces discrepancies via Cloud Monitoring |

### gcloud

```bash
gcloud compute instances create secure-vm \
  --shielded-secure-boot \
  --shielded-vtpm \
  --shielded-integrity-monitoring \
  --image-family=debian-12 --image-project=debian-cloud
```

### Terraform

```hcl
resource "google_compute_instance" "secure_vm" {
  name         = "secure-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network = "default"
  }
}
```

**Interview Q&A:**

*Q: How would you detect if a VM's boot integrity was compromised by a rootkit?*
A: Enable Integrity Monitoring on a Shielded VM — it compares the VM's measured boot sequence against an established baseline on every boot and reports mismatches as findings in Cloud Monitoring/SCC, letting you catch bootkit-level tampering that traditional in-OS antivirus wouldn't see.

---

## Module 25: Confidential Computing

Encrypts data **in use** (in memory, during processing) using hardware-based Trusted Execution Environments (AMD SEV / Intel TDX depending on machine type), not just at rest and in transit.

- **Confidential VM** — a Compute Engine VM where memory is encrypted with a key generated and held by the hardware itself, inaccessible even to the hypervisor/Google.
- **Confidential GKE Nodes** — GKE node pools running on Confidential VM instances, extending memory encryption to containerized workloads.
- **Use case** — regulated workloads (healthcare, finance) processing sensitive data where even cloud-provider-level memory access must be precluded, or secure multi-party computation.

### gcloud

```bash
gcloud compute instances create confidential-vm \
  --confidential-compute \
  --maintenance-policy=TERMINATE \
  --zone=us-central1-a --machine-type=n2d-standard-4 \
  --image-family=debian-12 --image-project=debian-cloud

# Confidential GKE node pool
gcloud container node-pools create confidential-pool \
  --cluster=my-cluster --zone=us-central1-a \
  --machine-type=n2d-standard-4 --enable-confidential-nodes
```

### Terraform

```hcl
resource "google_compute_instance" "confidential_vm" {
  name         = "confidential-vm"
  machine_type = "n2d-standard-4"
  zone         = "us-central1-a"

  confidential_instance_config {
    enable_confidential_compute = true
  }
  scheduling {
    on_host_maintenance = "TERMINATE"   # required — confidential VMs can't live-migrate
  }
  boot_disk {
    initialize_params { image = "debian-cloud/debian-12" }
  }
  network_interface { network = "default" }
}
```

**Interview Q&A:**

*Q: Why can't Confidential VMs live-migrate during host maintenance like normal VMs?*
A: Live migration requires transferring the VM's in-memory state to another host. Since Confidential VM memory is encrypted with a key tied to that specific hardware's TEE and never exposed outside it, that state can't be safely extracted and moved — so Confidential VMs must be configured with `on_host_maintenance = TERMINATE` and simply restart on another host instead.

---

## Module 26: VPC Service Controls

Creates a **service perimeter** around GCP resources (projects) to prevent data exfiltration — even from someone with valid IAM credentials, if they're outside the trusted context (e.g., copying a BigQuery dataset to a personal project, or accessing from an untrusted network).

### Core Concepts

- **Service Perimeters** — a boundary around a set of projects; API calls to protected services (BigQuery, GCS, etc.) from outside the perimeter are blocked, even with valid IAM permissions.
- **Access Levels** — (via Access Context Manager) define trusted conditions (IP range, device policy, identity) that can be granted an exception to cross the perimeter.
- **Restricted Services** — the specific list of APIs enforced by the perimeter (e.g., `storage.googleapis.com`, `bigquery.googleapis.com`).

### gcloud

```bash
gcloud access-context-manager perimeters create data_perimeter \
  --title="Data Perimeter" \
  --resources=projects/PROJECT_NUMBER \
  --restricted-services=storage.googleapis.com,bigquery.googleapis.com \
  --policy=ACCESS_POLICY_ID
```

### Terraform

```hcl
resource "google_access_context_manager_service_perimeter" "data_perimeter" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/servicePerimeters/data_perimeter"
  title  = "Data Perimeter"

  status {
    resources           = ["projects/${var.project_number}"]
    restricted_services  = ["storage.googleapis.com", "bigquery.googleapis.com"]
    access_levels        = [google_access_context_manager_access_level.trusted.name]
  }
}
```

### Concept Deep Dive — VPC-SC vs IAM (frequent confusion)

**IAM** governs *who* can call an API. **VPC Service Controls** governs *where from* / *under what context* that call is even allowed to reach the API boundary — it's a network-and-context-level perimeter that operates independently of, and in addition to, IAM. A fully-authorized IAM principal (even Owner) will still be blocked by VPC-SC if they're outside an allowed access level and try to, say, exfiltrate a BigQuery dataset to an external project.

**Interview Q&A:**

*Q: An engineer with `roles/bigquery.dataViewer` tries to export a dataset to a personal Gmail-linked project and gets blocked, despite having correct IAM permissions. Why?*
A: This is exactly what VPC Service Controls prevents — the destination project is outside the service perimeter, so the exfiltration is blocked at the network/context layer regardless of IAM correctness. IAM answers "can Jane read this dataset"; VPC-SC answers "can this dataset ever leave this trusted boundary" — two independent, additive layers of control.

---

## Module 27: Access Context Manager

Defines **Access Levels** — reusable, named conditions based on context (not just identity) — consumed by IAP, VPC Service Controls, and (indirectly) IAM Conditions.

### Components

- **Context-Aware Access** — combine identity + device + network signals into a single access decision.
- **Device Policies** — require managed/encrypted/screen-locked devices (via Endpoint Verification) before granting access.
- **IP Restrictions** — allow only specific corporate CIDR ranges.
- **Identity Restrictions** — combine with specific groups/domains.

### gcloud

```bash
gcloud access-context-manager levels create corp_trusted \
  --policy=ACCESS_POLICY_ID \
  --title="Corp Trusted" \
  --basic-level-spec=level-spec.yaml
```

```yaml
# level-spec.yaml
- ipSubnetworks:
  - "203.0.113.0/24"
  members:
  - "group:employees@example.com"
  requireScreenlock: true
```

### Terraform

```hcl
resource "google_access_context_manager_access_level" "trusted" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/accessLevels/corp_trusted"
  title  = "Corp Trusted"

  basic {
    conditions {
      ip_subnetworks   = ["203.0.113.0/24"]
      members          = ["group:employees@example.com"]
      require_screen_lock = true
    }
  }
}
```

### Device Policies — Detailed (Endpoint Verification)

Device-level signals require the **Endpoint Verification** Chrome extension (or a managed MDM like Chrome Enterprise / Workspace Endpoint Management) reporting device posture back to Google, which Access Context Manager then evaluates in a `device_policy` block — this is what lets an access level require "corporate-managed, encrypted, screen-locked laptop," not just a trusted IP range.

**Console steps:**
1. Ensure Endpoint Verification is deployed org-wide (Admin Console → Devices → Endpoint Verification → force-install the Chrome extension via policy for managed Chrome browsers/ChromeOS).
2. Security → Access Context Manager → edit or create an access level → **Add Condition** → **Device Policy** section.
3. Configure: require **Screen Lock**, require **Disk Encryption**, minimum **OS version** per platform (Windows/Mac/Linux/iOS/Android), require **corporate-owned** device (not BYOD), optionally require a specific approved list of device management URNs.

**gcloud (YAML device policy spec):**

```yaml
# device-policy-level-spec.yaml
- members:
  - "group:employees@example.com"
  devicePolicy:
    requireScreenlock: true
    requireCorpOwned: true
    allowedEncryptionStatuses:
    - ENCRYPTED
    osConstraints:
    - osType: DESKTOP_MAC
      minimumVersion: "13.0.0"
    - osType: DESKTOP_WINDOWS
      minimumVersion: "10.0.19041"
```

```bash
gcloud access-context-manager levels update corp_trusted \
  --policy=ACCESS_POLICY_ID \
  --basic-level-spec=device-policy-level-spec.yaml
```

**Terraform:**

```hcl
resource "google_access_context_manager_access_level" "corp_managed_device" {
  parent = "accessPolicies/${var.access_policy_id}"
  name   = "accessPolicies/${var.access_policy_id}/accessLevels/corp_managed_device"
  title  = "Corp Managed Device"

  basic {
    conditions {
      members = ["group:employees@example.com"]
      device_policy {
        require_screen_lock              = true
        require_corp_owned                = true
        allowed_encryption_statuses       = ["ENCRYPTED"]
        os_constraints {
          os_type         = "DESKTOP_MAC"
          minimum_version = "13.0.0"
        }
        os_constraints {
          os_type         = "DESKTOP_WINDOWS"
          minimum_version = "10.0.19041"
        }
      }
    }
  }
}
```

**Interview Q&A:**

*Q: A user is on the corporate VPN (trusted IP range) but on their personal, unencrypted laptop. Should Access Context Manager grant access if the level requires both IP and device trust?*
A: No — Access Level conditions within a single `basic` block are combined with AND logic by default, so both the IP subnet condition and the `device_policy` conditions (encryption, corp-owned) must all evaluate true. Being on the trusted network alone is insufficient; this is precisely the Zero Trust principle of not granting implicit trust from network location alone.

*Q: What has to be deployed org-wide before device-policy-based Access Levels can actually work?*
A: The Endpoint Verification Chrome extension (or equivalent MDM reporting) must be installed and actively reporting device posture — without it, Access Context Manager has no device signal to evaluate and device-based conditions can't be enforced, only identity/IP-based ones.

**Interview Q&A:**

*Q: How do Access Levels tie IAP, IAM, and VPC Service Controls together into one Zero Trust model?*
A: Access Levels are defined once in Access Context Manager and then referenced by multiple enforcement points: IAP checks them before proxying application traffic, VPC Service Controls checks them before allowing a perimeter crossing, and IAM Conditions can reference them for conditional bindings — a single "corp-trusted-device" definition drives consistent context-aware enforcement across the whole access stack instead of being redefined per-service.

---

## Module 28: Security Health Analytics

An automated, built-in SCC detector that continuously scans for common misconfigurations without any manual scan trigger.

### Example Detections

| Category | Example Finding |
|---|---|
| Public Buckets | GCS bucket with `allUsers`/`allAuthenticatedUsers` granted |
| Weak Firewall Rules | Firewall allowing `0.0.0.0/0` on sensitive ports (22, 3389, 3306) |
| Default Service Accounts | Compute Engine default SA still attached with broad `Editor` role |
| Public IPs | VM/SQL instance with a public IP and no restricting firewall |
| Missing Encryption | Resources not using CMEK where required by policy |
| API Key Exposure | Unrestricted API keys (no application/API restrictions) |

### Console Steps

1. Security Command Center → Findings → filter `category:"PUBLIC_BUCKET_ACL"` (or similar).
2. Click a finding → view remediation steps and affected asset link.
3. Settings → Security Health Analytics → toggle individual detectors on/off per module category.

**Interview Q&A:**

*Q: A finding flags "Default service account has Editor role." What's the risk and remediation?*
A: The Compute Engine default SA is auto-attached to VMs unless explicitly overridden, and historically carries the broad `roles/editor` grant — any workload on that VM inherits near-project-wide access. Remediation: create a dedicated, least-privilege SA per workload, reattach it to running VMs (`set-service-account`), and remove or restrict the default SA's project-level Editor binding.

---

## Module 29: DDoS Protection

GCP provides multi-layer DDoS protection, automatically for L3/L4 at the network edge, with additional L7 controls via Cloud Armor.

- **Cloud Armor Standard** — included with any external HTTP(S) Load Balancer; always-on network-layer DDoS defense.
- **Cloud Armor Managed Protection Plus** — adds L7 WAF rules, named IP allow/deny lists, and Adaptive Protection.
- **Global Load Balancer** — Google's globally distributed anycast edge absorbs volumetric attacks before they reach a single region.
- **Rate Limiting** — per-client request throttling rules within a Cloud Armor security policy (shown in Module 16 Terraform example).
- **Adaptive Protection** — ML-based anomaly detection that auto-suggests (or auto-applies) mitigating rules during an active L7 attack based on traffic baselines.

### gcloud

```bash
gcloud compute security-policies create adaptive-ddos-policy \
  --description="Adaptive protection enabled"

gcloud compute security-policies update adaptive-ddos-policy \
  --enable-layer7-ddos-defense
```

**Interview Q&A:**

*Q: How would you protect an internet-facing API from a Layer 7 application DDoS attack (not just volumetric)?*
A: Put it behind a Global External HTTPS Load Balancer with a Cloud Armor security policy: enable Adaptive Protection for ML-driven anomaly detection, add explicit rate-limiting rules per client IP, and layer preconfigured WAF rules (OWASP CRS) to block malicious request patterns — volumetric L3/L4 is absorbed by Google's edge automatically, while L7-specific abuse needs these Cloud Armor policy layers.

---

## Module 30: Compliance

GCP maintains third-party audited compliance certifications; your responsibility is configuring resources to meet the **controls** relevant to each framework (shared responsibility model).

| Framework | Focus |
|---|---|
| **ISO 27001** | Information security management system (ISMS) — broad, foundational |
| **SOC 1** | Financial reporting controls |
| **SOC 2** | Security, availability, confidentiality, processing integrity, privacy — most commonly requested by enterprise customers |
| **PCI DSS** | Payment card data handling |
| **HIPAA** | US healthcare data (requires signing a BAA with Google) |
| **GDPR** | EU personal data protection — data residency, right to erasure, processing agreements |

### Practical Interview Angle

Interviewers rarely want a recitation of framework names — they want to know **how you'd configure GCP to satisfy a specific control**, e.g.:
- *HIPAA*: sign the BAA, use only HIPAA-eligible services, enable CMEK + audit logging + VPC-SC around PHI data stores.
- *PCI DSS*: network segmentation via VPC + firewall rules isolating cardholder data environment, restrict to `gcp.resourceLocations`, enable Data Access audit logs on payment-processing projects, quarterly access reviews via IAM Recommender.
- *GDPR*: use `gcp.resourceLocations` Org Policy to enforce EU-only resource creation, enable CMEK for EU data residency of keys too, configure data retention/deletion via lifecycle policies.

**Interview Q&A:**

*Q: How would you technically enforce that a customer's data never leaves the EU, to satisfy GDPR data residency?*
A: Org Policy constraint `gcp.resourceLocations` restricted to EU regions, combined with a VPC Service Controls perimeter around the relevant projects to prevent any API-level copy/export outside that boundary, plus CMEK keys also created in an EU KMS location so even the encryption key material stays in-region.

---

## Module 31: Terraform Security

### Service Account Authentication for Terraform itself

Never run Terraform with a human's personal credentials for shared/production infra. Use a dedicated Terraform-runner service account, ideally invoked via Workload Identity Federation from CI (no key).

```hcl
provider "google" {
  project = "my-project"
  region  = "us-central1"
  # No credentials block needed if running via:
  # - GOOGLE_APPLICATION_CREDENTIALS pointing at WIF-issued short-lived creds, or
  # - gcloud auth application-default login with impersonation
}
```

```bash
# Local dev: impersonate the Terraform SA instead of using its key
gcloud auth application-default login --impersonate-service-account=terraform-sa@my-project.iam.gserviceaccount.com
```

### Remote State Security (GCS Backend)

```hcl
terraform {
  backend "gcs" {
    bucket = "my-org-tfstate"
    prefix = "envs/prod"
  }
}
```

Secure the state bucket itself:
```bash
gcloud storage buckets create gs://my-org-tfstate --uniform-bucket-level-access
gcloud storage buckets update gs://my-org-tfstate --versioning   # recover from bad applies
```

```hcl
resource "google_storage_bucket" "tfstate" {
  name                        = "my-org-tfstate"
  location                    = "US"
  uniform_bucket_level_access = true
  versioning { enabled = true }
  encryption {
    default_kms_key_name = google_kms_crypto_key.tfstate_key.id   # CMEK on state — state often contains sensitive values
  }
  public_access_prevention = "enforced"
}

resource "google_storage_bucket_iam_member" "tf_runner_only" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:terraform-sa@my-project.iam.gserviceaccount.com"
}
```

### Secret Management in Terraform

- **Never** hardcode secrets in `.tf` files or commit `.tfvars` containing them.
- Pass via `-var` at apply time from a CI secret store, or better: reference Secret Manager directly and let Terraform read (not write) the value:

```hcl
data "google_secret_manager_secret_version" "db_password" {
  secret = "db-password"
}

resource "google_sql_user" "app_user" {
  instance = google_sql_database_instance.main.name
  name     = "app"
  password = data.google_secret_manager_secret_version.db_password.secret_data
}
```
- Mark sensitive outputs: `output "db_password" { value = ...; sensitive = true }` — prevents accidental display in `plan`/`apply` logs (state file itself is still plaintext, hence securing the backend bucket matters).

### IAM Resources — Least Privilege for the Terraform SA Itself

Ironically, a common audit finding is the Terraform runner SA holding `roles/owner` "to avoid permission errors." Instead:
```hcl
resource "google_project_iam_member" "tf_runner_scoped" {
  for_each = toset([
    "roles/compute.admin",
    "roles/iam.securityAdmin",     # can manage IAM bindings, but can't grant itself Owner without also holding that
    "roles/storage.admin",
  ])
  project = "my-project"
  role    = each.value
  member  = "serviceAccount:terraform-sa@my-project.iam.gserviceaccount.com"
}
```

**Interview Q&A:**

*Q: Your Terraform state file is stored in GCS. What are the specific security risks and mitigations?*
A: State can contain plaintext sensitive values (passwords, keys) even with `sensitive = true` outputs, since that flag only masks CLI output, not the state file itself. Mitigate with: uniform bucket-level access + IAM restricted to the Terraform SA only, bucket versioning for recovery, CMEK encryption on the bucket, `public_access_prevention = enforced`, and ideally splitting genuinely sensitive resources into a separate state with tighter access than the general infra state.

---

## Module 32: CI/CD Security

### GitHub Secrets vs Workload Identity Federation

Storing a GCP service account key as a GitHub Actions secret is the legacy pattern — still common, but inferior to WIF (Module 2) because the key is long-lived and exportable even though GitHub encrypts it at rest.

```yaml
# GitHub Actions — keyless auth via WIF (preferred)
jobs:
  deploy:
    permissions:
      id-token: write   # required for OIDC
      contents: read
    steps:
      - uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/PROJECT_NUM/locations/global/workloadIdentityPools/github-pool/providers/github-provider'
          service_account: 'ci-deployer@my-project.iam.gserviceaccount.com'
      - uses: google-github-actions/deploy-cloudrun@v2
        with:
          service: payments-api
          image: gcr.io/my-project/payments-api:${{ github.sha }}
```

### GitLab CI Variables (masked/protected)

```yaml
# .gitlab-ci.yml
deploy:
  stage: deploy
  script:
    - gcloud auth login --cred-file=$GCP_WIF_CREDENTIAL_CONFIG   # via GitLab OIDC + WIF, not a stored key
    - gcloud run deploy payments-api --image=gcr.io/my-project/payments-api:$CI_COMMIT_SHA
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/PROJECT_NUM/locations/global/workloadIdentityPools/gitlab-pool/providers/gitlab-provider
```

If a raw key must be used (legacy pipelines): mark the GitLab CI/CD variable **Protected** (only exposed on protected branches/tags) and **Masked** (redacted from job logs).

### Workload Identity Federation for CI/CD — Best Practice Summary

1. Scope the `attribute_condition` tightly (specific repo, specific branch/environment, not just org-wide).
2. Grant the CI service account only the roles needed for that specific pipeline's deploy target — not project-wide Editor.
3. Use separate WIF providers/pools per environment (dev/staging/prod) so a compromised dev pipeline can't deploy to prod.

### Artifact Registry Authentication

```bash
# Configure Docker to auth to Artifact Registry via gcloud credential helper (no key)
gcloud auth configure-docker us-central1-docker.pkg.dev

# CI pipeline pulls/pushes using the WIF-derived identity automatically
docker push us-central1-docker.pkg.dev/my-project/repo/app:latest
```

```hcl
resource "google_artifact_registry_repository_iam_member" "ci_pusher" {
  repository = google_artifact_registry_repository.app_repo.name
  location   = "us-central1"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:ci-deployer@my-project.iam.gserviceaccount.com"
}
```

**Interview Q&A:**

*Q: Your org has 20 microservice repos, each with its own GitHub Actions deploy pipeline. How do you scope WIF so a compromise of one repo's pipeline can't deploy to another service?*
A: One Workload Identity Pool per environment tier (or per trust boundary) with `attribute_condition` filtering `assertion.repository`, and a dedicated, narrowly-scoped deployer service account **per microservice** rather than one shared CI service account — each repo's OIDC token can only impersonate its own service account, and each service account only holds deploy permissions for its own Cloud Run service/GKE namespace, not the others.

---

## Module 33: Interview Scenarios (Full Answers)

**1. Grant a developer read-only access to a single GCS bucket.**
> Bind `roles/storage.objectViewer` at the **bucket** level (not project level) to the developer: `gsutil iam ch user:dev@example.com:roles/storage.objectViewer gs://my-bucket` or `google_storage_bucket_iam_member`. Scoping at the bucket avoids granting visibility into every other bucket in the project. If they need to list objects but not read contents, note `objectViewer` includes both get and list — split further with a custom role if listing-only is required.

**2. Allow a VM to access Cloud Storage without using service account keys.**
> Attach a service account to the VM at creation (`--service-account`, `--scopes=cloud-platform`), grant that SA `roles/storage.objectViewer` (or narrower) on the target bucket. The VM's metadata server automatically serves short-lived access tokens to any process on it — no key file involved.

**3. Prevent accidental deletion of production resources.**
> Layer several controls: Terraform `lifecycle { prevent_destroy = true }` on critical resources; IAM — restrict `*.delete` permissions to a narrow break-glass role, not general Editor/Owner; Org Policy where applicable; enable deletion protection flags natively supported by some resources (e.g., Cloud SQL `deletion_protection = true`, GKE cluster protection); require deletions to go through a reviewed CI/CD pipeline (PR approval) rather than direct console/gcloud access for prod.

**4. Audit who deleted a Compute Engine VM.**
> Query Admin Activity audit logs in Logs Explorer: `protoPayload.methodName="v1.compute.instances.delete"`, inspect `protoPayload.authenticationInfo.principalEmail` and `requestMetadata.callerIp`. Admin Activity logs are always-on and can't be disabled, so this is always available (see Module 12).

**5. Restrict VM creation to specific regions.**
> Organization Policy constraint `gcp.resourceLocations` set to `allowed_values = ["in:us-locations"]` (or specific regions) at the project/folder/org level — enforced regardless of IAM role.

**6. Secure Terraform state stored in Cloud Storage.**
> Uniform bucket-level access, IAM scoped to the Terraform runner SA only, versioning enabled, CMEK encryption, `public_access_prevention = enforced`. See Module 31.

**7. Rotate secrets used by CI/CD pipelines.**
> Store the secret in Secret Manager, add a new version on rotation (`secrets versions add`), update consumers to reference `latest` (or a specific version pinned then bumped), and eliminate static CI secrets entirely where possible by moving auth to Workload Identity Federation (nothing to rotate because nothing is stored).

**8. Protect applications from DDoS attacks using Cloud Armor.**
> Put the app behind a Global External HTTPS Load Balancer (gets always-on network-layer DDoS protection automatically), attach a Cloud Armor security policy with rate-limiting rules, preconfigured WAF rules (OWASP CRS) for L7 attack patterns, and enable Adaptive Protection for ML-based anomaly detection during active attacks. See Modules 16 and 29.

**9. Implement least-privilege access for a DevOps team.**
> Create a custom role (or combination of predefined roles) matching their actual job — e.g., compute/GKE/CI deploy permissions, but not IAM/billing admin. Bind to a Google Group, not individuals. Use IAM Conditions for any temporary/elevated access needs instead of standing broad grants. Periodically review with IAM Recommender / Policy Analyzer to trim unused permissions.

**10. Secure GKE workloads using Workload Identity instead of service account keys.**
> Enable Workload Identity on the cluster (`--workload-pool`), create a narrowly-scoped GSA per workload, bind the KSA to the GSA via `roles/iam.workloadIdentityUser`, annotate the KSA — pods get short-lived, automatically-rotated credentials with zero exported key material. See Module 22 for full walkthrough.

---

## Quick-Reference: Highest-Priority Topics Cheat Sheet

For 6–10 YOE interviews, these are asked most often — know these cold:

| Topic | One-Line Answer If Asked Cold |
|---|---|
| **IAM roles** | Primitive (broad, avoid) → Predefined (scoped per service) → Custom (exact permission list, no auto-updates) |
| **Service accounts + impersonation** | Prefer attached SA / Workload Identity / impersonation over exported keys; `serviceAccountUser` (attach) ≠ `serviceAccountTokenCreator` (impersonate) |
| **IAM policies + Conditions** | Bindings = role+members(+condition); use `_member` (additive) not `_binding`/`_policy` (authoritative) in Terraform unless you own the whole resource's IAM |
| **Resource hierarchy** | Org → Folder → Project → Resource; IAM inheritance is always additive; Org Policy can restrict even Owners |
| **Cloud Audit Logs** | Admin Activity = always-on/free; Data Access = off by default, must enable; query via `protoPayload.methodName` |
| **Cloud KMS + Secret Manager** | KMS = envelope encryption/CMEK keys with rotation; Secret Manager = versioned app secrets with IAM-scoped access; rotation doesn't retroactively re-encrypt old data |
| **VPC firewall rules** | Stateful, priority-ordered; prefer service-account targeting over network tags for security-sensitive rules |
| **Workload Identity (GKE)** | KSA ↔ GSA binding via `iam.workloadIdentityUser`, no exported key, replaces mounted key Secrets |
| **Organization Policies** | Controls "what configs are possible," not "who can act" — IAM can't override an enforced Org Policy |
| **Terraform IAM + security** | Dedicated least-privilege runner SA (ideally via WIF, not a key), secured GCS backend (CMEK + versioning + restricted IAM), never hardcode secrets in `.tf` |

---

*End of guide. Structure mirrors your other reference docs — Console + gcloud + Terraform + Concept Deep Dive + Interview Q&A per topic — ready to extend with more scenario walkthroughs or a companion Q&A-only rapid-fire drill file if useful.*
