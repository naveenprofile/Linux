# GCP Cloud Storage - Complete Comprehensive Guide

## Table of Contents
1. [Cloud Storage Basics](#1-cloud-storage-basics)
2. [Storage Classes](#2-storage-classes)
3. [Bucket Management](#3-bucket-management)
4. [Access Control & Security](#4-access-control--security)
5. [Object Management](#5-object-management)
6. [Versioning & Retention](#6-versioning--retention)
7. [Lifecycle Management](#7-lifecycle-management)
8. [Advanced Security](#8-advanced-security)
9. [Data Transfer](#9-data-transfer)
10. [Monitoring & Logging](#10-monitoring--logging)
11. [Performance Optimization](#11-performance-optimization)
12. [Real-World Scenarios](#12-real-world-scenarios)
13. [Interview Q&A](#13-interview-qa)
14. [Best Practices & Cost Optimization](#14-best-practices--cost-optimization)

---

## 1. Cloud Storage Basics

### What is GCP Cloud Storage?

Google Cloud Storage (GCS) is a unified, massively scalable object storage service for storing unstructured data. It's built on the same infrastructure that powers Google's search, Gmail, and YouTube.

**Key Characteristics:**
- **Object-based storage** (not block or file)
- **Global namespace** - bucket names must be unique across all GCP accounts
- **High availability** - 99.95% SLA for multi-region, 99.9% for dual-region, 99.9% for regional
- **Atomic operations** - updates are atomic at the object level
- **RESTful API** and native support for JSON, XML protocols

### Storage Models Comparison

| Feature | Block Storage | File Storage | Object Storage |
|---------|---------------|--------------|----------------|
| Access Pattern | Block-level | File-level (NFS/SMB) | HTTP/API |
| Protocol | iSCSI, FC | NFS, SMB | REST, SOAP, XML |
| Use Case | Databases, VMs | Shared file systems | Backups, archives, media |
| Performance | Very fast | Good | Good for scale |
| Scalability | Limited | Limited | Unlimited |
| Example in GCP | Persistent Disk | Filestore | Cloud Storage |

### Buckets and Objects

**Bucket:** Top-level container for storing objects
- Must have globally unique name
- Region/multi-region location
- Storage class
- Various metadata and policies

**Object:** Individual file stored in a bucket
- Has a key (path/name)
- Associated metadata (content-type, size, created date, etc.)
- Can be up to 5 TB in size
- Versioning support

### Console Navigation

**Creating via Console:**
1. Go to: Google Cloud Console → Cloud Storage → Buckets
2. Click "Create Bucket"
3. Enter bucket name (must be globally unique, 3-63 characters, lowercase)
4. Choose location type:
   - **Region**: Single geographic region (best for latency)
   - **Dual-region**: Two geographically close regions (redundancy)
   - **Multi-region**: Large geographic area (highest availability)
5. Select storage class
6. Choose access control method (Uniform or Fine-grained)
7. Set encryption (Google-managed or Customer-managed)
8. Click "Create"

---

## 2. Storage Classes

### Storage Classes Detailed

#### Standard Storage
```
Ideal for: Frequent access, hot data, development/testing
Cost: Highest per GB storage, lowest retrieval cost
SLA: 99.95% (multi-region)
Use Cases:
  - Websites content delivery
  - Real-time analytics
  - Mobile/desktop applications
  - Development/testing data
```

**gcloud command:**
```bash
gsutil mb -c STANDARD -l us-central1 gs://my-standard-bucket
```

**Terraform:**
```hcl
resource "google_storage_bucket" "standard" {
  name          = "my-standard-bucket-${data.google_client_config.current.project}"
  location      = "US"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}
```

#### Nearline Storage
```
Ideal for: Infrequent access (~1x/month), backups, archival
Cost: Low storage cost, higher retrieval cost
30-day minimum storage
SLA: 99.0% (single region), 99.9% (multi-region)
Use Cases:
  - Backup data
  - Monthly analytics exports
  - Disaster recovery
```

**gcloud command:**
```bash
gsutil mb -c NEARLINE -l us-central1 gs://my-nearline-bucket
```

#### Coldline Storage
```
Ideal for: Rare access (~1x/90 days), long-term archives
Cost: Lowest storage cost, expensive retrieval
90-day minimum storage
SLA: 99.0% (single region), 99.9% (multi-region)
Use Cases:
  - Compliance archives
  - Year-end backups
  - Infrequently accessed records
```

**gcloud command:**
```bash
gsutil mb -c COLDLINE -l us-central1 gs://my-coldline-bucket
```

#### Archive Storage
```
Ideal for: Rare access (~1x/year), long-term retention
Cost: Lowest storage cost, highest retrieval cost
365-day minimum storage
SLA: 99.95% (only for multi-region)
Use Cases:
  - Long-term compliance storage
  - Historical backups
  - Legal holds
```

**gcloud command:**
```bash
gsutil mb -c ARCHIVE -l us gs://my-archive-bucket
```

### Cost Analysis Example

```
Storing 1 TB for 12 months:

STANDARD:     $0.020/GB × 12 = $240/month = $2,880/year
NEARLINE:     $0.010/GB × 12 = $120/month = $1,440/year (+ retrieval $0.01/GB = $10)
COLDLINE:     $0.004/GB × 12 = $48/month  = $576/year  (+ retrieval $0.02/GB = $20)
ARCHIVE:      $0.0012/GB × 12 = $14.40/month = $172.80/year (+ retrieval $0.05/GB = $50)

If accessed once per month:
- Nearline saves: $2,880 - ($1,440 + 120 retrieval) = $1,320/year
- Coldline saves: $2,880 - ($576 + 240 retrieval) = $2,064/year
```

---

## 3. Bucket Management

### Creating Buckets

#### Via Console (Step-by-step)
1. Open Google Cloud Console
2. Navigate to: Cloud Storage > Buckets
3. Click "Create"
4. Fill in:
   - **Bucket name**: `my-app-data-prod` (must be unique globally)
   - **Location type**: Choose Region, Dual-region, or Multi-region
   - **Location**: Select specific location
   - **Storage class**: Select based on access patterns
   - **Access control**: Choose Uniform or Fine-grained
   - **Encryption**: Google-managed or Customer-managed keys
   - **Labels**: Add metadata tags for organization
5. Click "Create"

#### Via gcloud CLI

```bash
# Basic bucket creation
gsutil mb gs://my-bucket

# With specific options
gsutil mb -c STANDARD -l us-central1 -b on gs://my-bucket

# Flags explained:
# -c : Storage class (STANDARD, NEARLINE, COLDLINE, ARCHIVE)
# -l : Location
# -b : Uniform bucket-level access (on/off)

# Create with labels
gsutil mb -L "env=prod,team=data,cost-center=1234" gs://my-bucket

# Enable versioning while creating
gsutil versioning set on gs://my-bucket
```

#### Via Terraform

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

variable "project_id" {
  type = string
}

variable "region" {
  type = string
  default = "us-central1"
}

# Production bucket with all features
resource "google_storage_bucket" "prod_bucket" {
  name          = "my-app-prod-${var.project_id}"
  location      = var.region
  storage_class = "STANDARD"
  project       = var.project_id

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Versioning
  versioning {
    enabled = true
  }

  # Lifecycle rules
  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Retention policy
  retention_policy {
    retention_days = 365
  }

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }

  # Labels
  labels = {
    environment = "production"
    team        = "platform"
    cost_center = "engineering"
  }

  # CORS configuration
  cors {
    origin          = ["https://example.com"]
    method          = ["GET", "HEAD", "DELETE"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }

  # Website configuration (if serving as static website)
  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  depends_on = [google_kms_crypto_key_iam_member.bucket_crypto_key_user]
}

# Customer-managed encryption key
resource "google_kms_key_ring" "bucket_keyring" {
  name       = "bucket-keyring"
  location   = var.region
  project    = var.project_id
}

resource "google_kms_crypto_key" "bucket_key" {
  name           = "bucket-key"
  key_ring       = google_kms_key_ring.bucket_keyring.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# Service account for accessing bucket
resource "google_service_account" "bucket_sa" {
  account_id = "bucket-access-sa"
  project    = var.project_id
}

# IAM binding
resource "google_storage_bucket_iam_member" "bucket_access" {
  bucket = google_storage_bucket.prod_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.bucket_sa.email}"
}

resource "google_kms_crypto_key_iam_member" "bucket_crypto_key_user" {
  crypto_key_id = google_kms_crypto_key.bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.bucket_sa.email}"
}

# Outputs
output "bucket_name" {
  value = google_storage_bucket.prod_bucket.name
}

output "service_account_email" {
  value = google_service_account.bucket_sa.email
}
```

### Bucket Naming Conventions

**Rules:**
- 3-63 characters in length
- Start with number or letter
- Contain only lowercase letters, numbers, hyphens, underscores, and periods
- Cannot start or end with hyphen
- Cannot contain consecutive hyphens
- Globally unique across all GCP projects

**Best Practices:**
```
❌ Bad:
  - MyBucket (capitals not allowed)
  - my-bucket--prod (consecutive hyphens)
  - my_bucket_2024 (underscores acceptable but avoid mixing)

✓ Good:
  - my-app-data-prod
  - org-project-backups-eu
  - logs-2024-archive
  - mycompany-storage-v2
```

### Bucket Labels

Labels are key-value metadata for organizing and cost tracking.

```bash
# Add labels via gcloud
gsutil label ch -l "environment:prod,team:analytics,cost-center:1234" gs://my-bucket

# View labels
gsutil label get gs://my-bucket

# Remove label
gsutil label ch -d "environment" gs://my-bucket
```

**Terraform:**
```hcl
labels = {
  environment     = "production"
  team            = "data-platform"
  cost_center     = "1234"
  backup_required = "true"
  criticality     = "high"
}
```

### Bucket Locations

#### Regional Bucket
```
Characteristics:
- Data stored in single region
- Best latency for applications in that region
- Lower cost than multi-region
- Data replication within region only

Use Case:
- Data locality requirements (data residency laws)
- Compliance (GDPR, HIPAA)
- Cost optimization when latency not critical
```

**Create:**
```bash
gsutil mb -l us-central1 gs://my-regional-bucket
```

#### Dual-Region Bucket
```
Characteristics:
- Data stored in two nearby regions
- Automatic failover between regions
- Similar latency to regional
- Moderate cost increase for redundancy

Options:
- eur4: Finland + Netherlands
- nam4: South Carolina + Iowa

Use Case:
- Business-critical applications
- Active-active configurations
- Disaster recovery
```

**Create:**
```bash
gsutil mb -l eur4 gs://my-dual-region-bucket
```

#### Multi-Region Bucket
```
Characteristics:
- Data replicated across multiple regions within continent
- Highest availability (99.95% SLA)
- Highest cost
- Geographic redundancy

Options:
- US: Multiple US regions
- EU: Multiple EU regions
- ASIA: Multiple Asia regions

Use Case:
- Global applications
- Maximum availability requirements
- Public data distribution
```

**Create:**
```bash
gsutil mb -l us gs://my-multiregion-bucket
```

### Listing and Deleting Buckets

```bash
# List all buckets
gsutil ls

# List buckets with details
gsutil ls -L

# List specific bucket contents
gsutil ls -r gs://my-bucket

# Delete empty bucket
gsutil rb gs://my-bucket

# Force delete bucket with contents (dangerous!)
gsutil -m rm -r gs://my-bucket

# Delete bucket via gcloud
gcloud storage buckets delete gs://my-bucket --region=us-central1
```

**Terraform:**
```hcl
# Delete bucket (note: must be empty or force_destroy = true)
resource "google_storage_bucket" "temp_bucket" {
  name          = "temp-bucket-${var.project_id}"
  location      = "US"
  force_destroy = true  # Delete even if contains objects
}
```

---

## 4. Access Control & Security

### IAM Roles

#### Basic IAM Roles

| Role | Permissions | Use Case |
|------|-------------|----------|
| roles/storage.admin | Full access to buckets and objects | Admin/DevOps |
| roles/storage.objectViewer | Read-only access to objects | Data consumers |
| roles/storage.objectCreator | Upload objects only | CI/CD pipelines |
| roles/storage.objectAdmin | Manage objects (CRUD) | Application service accounts |
| roles/storage.legacyBucketReader | Deprecated bucket-level reader | Legacy systems (avoid) |
| roles/storage.legacyBucketWriter | Deprecated bucket-level writer | Legacy systems (avoid) |

#### Predefined vs Custom Roles

**Predefined Roles:**
```bash
# List available roles
gcloud iam roles list --filter="storage"

# Grant role to service account
gcloud storage buckets add-iam-policy-binding gs://my-bucket \
  --member=serviceAccount:my-sa@project.iam.gserviceaccount.com \
  --role=roles/storage.objectViewer
```

**Custom Role:**
```hcl
resource "google_project_iam_custom_role" "storage_operator" {
  role_id     = "storageOperator"
  title       = "Storage Operator"
  description = "Custom role for storage operations"
  
  permissions = [
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
  ]
}
```

### Bucket-Level Permissions

```bash
# Check who has access to bucket
gsutil iam ch gs://my-bucket

# View IAM policy
gcloud storage buckets get-iam-policy gs://my-bucket

# Grant object viewer role
gcloud storage buckets add-iam-policy-binding gs://my-bucket \
  --member=user:john@company.com \
  --role=roles/storage.objectViewer \
  --condition=None
```

**Terraform:**
```hcl
# Grant IAM role at bucket level
resource "google_storage_bucket_iam_member" "bucket_viewer" {
  bucket = google_storage_bucket.prod_bucket.name
  role   = "roles/storage.objectViewer"
  member = "user:john@company.com"
}

resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.prod_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:my-app@project.iam.gserviceaccount.com"
}

# Grant object-level access
resource "google_storage_object_access_control" "public_rule" {
  bucket = google_storage_bucket.prod_bucket.name
  object = "public-file.txt"
  role   = "READER"
  entity = "allUsers"
}
```

### Uniform Bucket-Level Access (UBLA)

**Concept:**
Enforces uniform IAM policies instead of object-level ACLs. Google recommends this approach.

**Enable UBLA:**
```bash
# Via gcloud
gsutil uniformbucketlevelaccess set on gs://my-bucket

# Check status
gsutil uniformbucketlevelaccess get gs://my-bucket
```

**Terraform:**
```hcl
resource "google_storage_bucket" "secure_bucket" {
  name          = "secure-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}
```

**Benefits:**
- Simpler to manage (one policy per bucket)
- Better security (prevents accidental public access)
- Easier to audit
- Recommended by Google Security

### ACLs (Access Control Lists) - Legacy

**Note:** Deprecated when using UBLA. Only use for fine-grained object-level access.

```bash
# View ACLs for object
gsutil acl ch -u john@company.com:R gs://my-bucket/file.txt

# Make object public (not recommended)
gsutil acl ch -u AllUsers:R gs://my-bucket/file.txt

# Grant owner access
gsutil acl ch -u jane@company.com:O gs://my-bucket/file.txt

# Remove access
gsutil acl ch -d john@company.com gs://my-bucket/file.txt
```

### Service Accounts

Service Accounts are special accounts for applications to authenticate.

**Create Service Account:**
```bash
# Via gcloud
gcloud iam service-accounts create my-app-sa \
  --display-name="My Application Service Account"

# Get service account email
gcloud iam service-accounts list --filter="displayName:my-app-sa"

# Create and download key
gcloud iam service-accounts keys create sa-key.json \
  --iam-account=my-app-sa@project.iam.gserviceaccount.com
```

**Terraform:**
```hcl
resource "google_service_account" "app_sa" {
  account_id   = "my-app-sa"
  display_name = "My Application Service Account"
  project      = var.project_id
}

# Grant access to bucket
resource "google_storage_bucket_iam_member" "app_access" {
  bucket = google_storage_bucket.prod_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app_sa.email}"
}

# Create key for service account
resource "google_service_account_key" "app_key" {
  service_account_id = google_service_account.app_sa.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

output "service_account_email" {
  value = google_service_account.app_sa.email
}
```

**Using Service Account in Application:**
```python
from google.cloud import storage
from google.oauth2 import service_account

credentials = service_account.Credentials.from_service_account_file(
    'sa-key.json'
)

client = storage.Client(credentials=credentials)
bucket = client.bucket('my-bucket')
blob = bucket.blob('path/to/file.txt')
blob.upload_from_filename('local-file.txt')
```

---

## 5. Object Management

### Upload Objects

#### Via Console
1. Open Google Cloud Console
2. Navigate to Cloud Storage > Buckets
3. Click bucket name
4. Click "Upload files" or "Upload folder"
5. Select files from local system
6. Files upload automatically

#### Via gcloud/gsutil

```bash
# Upload single file
gsutil cp local-file.txt gs://my-bucket/

# Upload with custom name
gsutil cp local-file.txt gs://my-bucket/custom-name.txt

# Upload directory
gsutil -m cp -r ./local-dir gs://my-bucket/

# Upload with metadata
gsutil -h "Content-Type:application/json" \
  -h "Cache-Control:public, max-age=3600" \
  cp file.json gs://my-bucket/

# Parallel uploads (faster)
gsutil -m cp -r large-dir gs://my-bucket/

# Upload with progress
gsutil cp -P large-file.tar.gz gs://my-bucket/
```

#### Terraform - Upload Objects

```hcl
# Upload single file
resource "google_storage_object" "file" {
  name       = "config/settings.json"
  bucket     = google_storage_bucket.prod_bucket.name
  source     = "${path.module}/files/settings.json"
  depends_on = [google_storage_bucket.prod_bucket]
}

# Upload with content-type
resource "google_storage_object" "json_file" {
  name        = "data/export.json"
  bucket      = google_storage_bucket.prod_bucket.name
  content     = jsonencode({
    version = "1.0"
    data    = "example"
  })
  content_type = "application/json"
}

# Upload with caching
resource "google_storage_object" "cached_asset" {
  name                = "assets/logo.png"
  bucket              = google_storage_bucket.prod_bucket.name
  source              = "${path.module}/files/logo.png"
  cache_control       = "public, max-age=86400"
  content_disposition = "inline"
  content_type        = "image/png"
}
```

#### Python Upload Example

```python
from google.cloud import storage
from pathlib import Path

def upload_file(bucket_name, source_file, destination_blob):
    """Upload a file to bucket"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(destination_blob)
    
    blob.upload_from_filename(source_file)
    print(f"File {source_file} uploaded to {bucket_name}/{destination_blob}")

def upload_folder(bucket_name, source_dir, destination_prefix=""):
    """Upload entire folder"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    
    for file_path in Path(source_dir).rglob('*'):
        if file_path.is_file():
            relative_path = file_path.relative_to(source_dir)
            destination = f"{destination_prefix}/{relative_path}".lstrip('/')
            
            blob = bucket.blob(destination)
            blob.upload_from_filename(str(file_path))
            print(f"Uploaded: {destination}")

def upload_with_metadata(bucket_name, local_file, blob_name, metadata):
    """Upload with custom metadata"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    
    blob.metadata = metadata
    blob.upload_from_filename(local_file)
    print(f"Uploaded with metadata: {blob_name}")

# Usage
upload_file('my-bucket', 'local-file.txt', 'remote-file.txt')
upload_folder('my-bucket', './local-dir', 'backups')
upload_with_metadata('my-bucket', 'config.json', 'configs/app.json', 
                    {'env': 'prod', 'version': '1.0'})
```

### Download Objects

```bash
# Download single object
gsutil cp gs://my-bucket/file.txt ./

# Download to specific location
gsutil cp gs://my-bucket/file.txt ~/Downloads/

# Download multiple objects
gsutil -m cp gs://my-bucket/*.txt ./

# Download entire folder
gsutil -m cp -r gs://my-bucket/folder ./

# Download with progress
gsutil cp -P gs://my-bucket/large-file.tar.gz ./
```

**Python:**
```python
from google.cloud import storage

def download_file(bucket_name, blob_name, local_file):
    """Download a file from bucket"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(local_file)
    print(f"Downloaded {blob_name} to {local_file}")

def download_folder(bucket_name, prefix, local_dir):
    """Download all objects with prefix"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    
    for blob in bucket.list_blobs(prefix=prefix):
        local_path = f"{local_dir}/{blob.name}"
        Path(local_path).parent.mkdir(parents=True, exist_ok=True)
        blob.download_to_filename(local_path)
        print(f"Downloaded: {blob.name}")

# Usage
download_file('my-bucket', 'file.txt', './file.txt')
download_folder('my-bucket', 'backups/', './local-backups')
```

### Delete Objects

```bash
# Delete single object
gsutil rm gs://my-bucket/file.txt

# Delete multiple objects
gsutil -m rm gs://my-bucket/*.txt

# Delete with pattern
gsutil -m rm gs://my-bucket/folder/*.log

# Delete recursively
gsutil -m rm -r gs://my-bucket/folder

# Dry run (shows what would be deleted)
gsutil -m rm -r --dryrun gs://my-bucket/old-data
```

**Python:**
```python
def delete_object(bucket_name, blob_name):
    """Delete single object"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.delete()
    print(f"Deleted {blob_name}")

def delete_objects_with_prefix(bucket_name, prefix):
    """Delete all objects with prefix"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    
    for blob in bucket.list_blobs(prefix=prefix):
        blob.delete()
        print(f"Deleted {blob.name}")

# Usage
delete_object('my-bucket', 'temp-file.txt')
delete_objects_with_prefix('my-bucket', 'logs/2024-01/')
```

### Copy/Move Objects

```bash
# Copy within bucket
gsutil cp gs://my-bucket/file.txt gs://my-bucket/file-backup.txt

# Copy between buckets
gsutil cp gs://source-bucket/file.txt gs://dest-bucket/file.txt

# Copy with parallel (fast)
gsutil -m cp gs://source-bucket/* gs://dest-bucket/

# Move (copy then delete)
gsutil cp gs://source-bucket/file.txt gs://dest-bucket/ && \
  gsutil rm gs://source-bucket/file.txt

# Rename object (within same bucket)
gsutil mv gs://my-bucket/old-name.txt gs://my-bucket/new-name.txt
```

**Python:**
```python
def copy_object(source_bucket, source_blob, dest_bucket, dest_blob):
    """Copy object between buckets"""
    client = storage.Client()
    source = client.bucket(source_bucket).blob(source_blob)
    dest = client.bucket(dest_bucket).blob(dest_blob)
    
    client.copy_blob(source, dest)
    print(f"Copied {source_blob} to {dest_bucket}/{dest_blob}")

def move_object(source_bucket, source_blob, dest_bucket, dest_blob):
    """Move object (copy and delete)"""
    copy_object(source_bucket, source_blob, dest_bucket, dest_blob)
    client = storage.Client()
    client.bucket(source_bucket).blob(source_blob).delete()
    print(f"Moved {source_blob} to {dest_bucket}/{dest_blob}")

# Usage
copy_object('source-bucket', 'file.txt', 'dest-bucket', 'file.txt')
move_object('bucket1', 'file.txt', 'bucket2', 'file.txt')
```

---

## 6. Versioning & Retention

### Object Versioning

Versioning allows you to keep multiple versions of objects and recover deleted files.

**Enable Versioning:**
```bash
# Enable via gsutil
gsutil versioning set on gs://my-bucket

# Check status
gsutil versioning get gs://my-bucket

# Disable versioning
gsutil versioning set off gs://my-bucket
```

**Terraform:**
```hcl
resource "google_storage_bucket" "versioned" {
  name          = "versioned-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  versioning {
    enabled = true
  }
}
```

**How Versioning Works:**

```bash
# Upload file
gsutil cp file.txt gs://my-bucket/file.txt
# Version: 1 (generation: 1234567890)

# Upload new version
gsutil cp file-v2.txt gs://my-bucket/file.txt
# Version: 2 (generation: 1234567891)

# Upload another version
gsutil cp file-v3.txt gs://my-bucket/file.txt
# Version: 3 (generation: 1234567892)

# List all versions
gsutil ls -L gs://my-bucket/file.txt
# Shows all generations

# Retrieve specific version
gsutil cp "gs://my-bucket/file.txt#1234567890" ./file-old.txt

# Download oldest version
gsutil ls -L gs://my-bucket/file.txt | head -n 2
```

**Python - Version Management:**
```python
def list_object_versions(bucket_name, blob_name):
    """List all versions of object"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    
    for generation in bucket.list_blobs(match_glob=blob_name):
        print(f"Generation: {generation.generation}, "
              f"Updated: {generation.updated}")

def restore_object_version(bucket_name, blob_name, generation):
    """Restore specific version of object"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name, generation=generation)
    
    # Copy old version to current
    new_blob = bucket.blob(blob_name)
    client.copy_blob(blob, bucket, new_blob.name)
    print(f"Restored generation {generation}")

# Usage
list_object_versions('my-bucket', 'important-file.txt')
restore_object_version('my-bucket', 'important-file.txt', '1234567890')
```

### Recover Deleted Files

With versioning enabled, deleted files can be recovered:

```bash
# Delete file (soft delete with versioning)
gsutil rm gs://my-bucket/file.txt

# List all versions including delete markers
gsutil ls -L gs://my-bucket/file.txt

# Restore by copying old version
gsutil cp "gs://my-bucket/file.txt#1234567890" gs://my-bucket/file.txt

# Or copy to different location
gsutil cp "gs://my-bucket/file.txt#1234567890" gs://my-bucket/file-restored.txt
```

### Generations and Metagenerations

**Generation:** Unique identifier for each version of object
- Assigned at object creation
- Incremented with each update
- Never reused

**Metageneration:** Version of object's metadata
- Changes when metadata is updated (ACL, cache-control, etc.)
- Separate from object content generation

```bash
# View generation and metageneration
gsutil stat gs://my-bucket/file.txt

# Output includes:
# Generation:        1234567890
# Metageneration:    2

# Use generation in conditional operations
gsutil -h "x-goog-if-generation-match:1234567890" \
  cp file.txt gs://my-bucket/file.txt
```

---

## 7. Lifecycle Management

Automatically manage object transitions and deletions based on rules.

### Lifecycle Rules Configuration

```bash
# Create lifecycle policy JSON
cat > lifecycle.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "NEARLINE"
        },
        "condition": {
          "age": 30,
          "matchesPrefix": ["data/logs/"]
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "COLDLINE"
        },
        "condition": {
          "age": 90,
          "matchesPrefix": ["data/logs/"]
        }
      },
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "ARCHIVE"
        },
        "condition": {
          "age": 365
        }
      },
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "age": 2555,
          "isLive": false
        }
      }
    ]
  }
}
EOF

# Apply lifecycle policy
gsutil lifecycle set lifecycle.json gs://my-bucket

# View current lifecycle policy
gsutil lifecycle get gs://my-bucket
```

### Terraform Lifecycle Rules

```hcl
resource "google_storage_bucket" "lifecycle_bucket" {
  name          = "lifecycle-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  # Keep 3 previous versions only
  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }

  # Move to NEARLINE after 30 days
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Move to COLDLINE after 90 days
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Move to ARCHIVE after 365 days
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Delete non-current versions after 90 days
  lifecycle_rule {
    condition {
      age    = 90
      is_live = false
    }
    action {
      type = "Delete"
    }
  }

  # Delete all objects matching pattern after 1 year
  lifecycle_rule {
    condition {
      age = 365
      matches_prefix = ["temp/", "cache/"]
    }
    action {
      type = "Delete"
    }
  }
}

# Cost optimization: Archive old backups
resource "google_storage_bucket" "backup_bucket" {
  name          = "backup-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 730  # 2 years
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  lifecycle_rule {
    condition {
      age = 2555  # 7 years (compliance requirement)
    }
    action {
      type = "Delete"
    }
  }
}
```

### Real-World Lifecycle Example

```json
{
  "lifecycle": {
    "rule": [
      {
        "description": "Development logs - keep 7 days then delete",
        "action": { "type": "Delete" },
        "condition": {
          "age": 7,
          "matchesPrefix": ["logs/dev/"]
        }
      },
      {
        "description": "Production logs - archive after 30 days",
        "action": {
          "type": "SetStorageClass",
          "storageClass": "COLDLINE"
        },
        "condition": {
          "age": 30,
          "matchesPrefix": ["logs/prod/"]
        }
      },
      {
        "description": "Delete temporary builds",
        "action": { "type": "Delete" },
        "condition": {
          "age": 14,
          "matchesPrefix": ["builds/temp/"]
        }
      },
      {
        "description": "Keep only latest 5 database backups",
        "action": { "type": "Delete" },
        "condition": {
          "num_newer_versions": 5
        }
      },
      {
        "description": "Archive deleted versions after 30 days",
        "action": {
          "type": "SetStorageClass",
          "storageClass": "ARCHIVE"
        },
        "condition": {
          "age": 30,
          "isLive": false
        }
      }
    ]
  }
}
```

---

## 8. Advanced Security

### Encryption Options

#### Google-Managed Encryption Keys (GMEK)
Default encryption. Google manages all keys.

```bash
# Default (no action needed)
gsutil mb gs://my-bucket

# Verify GMEK is enabled
gsutil encryption get gs://my-bucket
```

#### Customer-Managed Encryption Keys (CMEK)

Using Cloud KMS to manage encryption keys.

```bash
# Create KMS key ring
gcloud kms keyrings create bucket-keyring \
  --location=us-central1

# Create encryption key
gcloud kms keys create bucket-key \
  --location=us-central1 \
  --keyring=bucket-keyring \
  --purpose=encryption

# Create bucket with CMEK
gsutil mb -c STANDARD -l us-central1 gs://cmek-bucket

# Encrypt bucket with KMS key
gcloud storage buckets update gs://cmek-bucket \
  --kms-key=projects/my-project/locations/us-central1/keyRings/bucket-keyring/cryptoKeys/bucket-key

# Grant service account permission to use key
gcloud kms keys add-iam-policy-binding bucket-key \
  --location=us-central1 \
  --keyring=bucket-keyring \
  --member=serviceAccount:service-account@project.iam.gserviceaccount.com \
  --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
```

**Terraform CMEK:**
```hcl
# Create KMS key ring and key
resource "google_kms_key_ring" "bucket_keyring" {
  name       = "bucket-keyring"
  location   = "us-central1"
  project    = var.project_id
}

resource "google_kms_crypto_key" "bucket_key" {
  name            = "bucket-key"
  key_ring        = google_kms_key_ring.bucket_keyring.id
  rotation_period = "7776000s"  # 90 days
  labels = {
    environment = "production"
  }
}

# Enable automatic rotation
resource "google_kms_crypto_key_version" "bucket_key_version" {
  crypto_key = google_kms_crypto_key.bucket_key.id
}

# Create bucket with CMEK
resource "google_storage_bucket" "cmek_bucket" {
  name          = "cmek-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"
  project       = var.project_id

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }

  depends_on = [
    google_kms_crypto_key_iam_member.bucket_sa
  ]
}

# Grant service account KMS permissions
resource "google_kms_crypto_key_iam_member" "bucket_sa" {
  crypto_key_id = google_kms_crypto_key.bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.bucket_sa.email}"
}

output "kms_key_name" {
  value = google_kms_crypto_key.bucket_key.id
}
```

#### Customer-Supplied Encryption Keys (CSEK)

Application manages encryption keys.

```python
from google.cloud import storage
import base64
import os

# Generate 256-bit encryption key
encryption_key = base64.b64encode(os.urandom(32)).decode('utf-8')

client = storage.Client()
bucket = client.bucket('my-bucket')

# Upload with CSEK
blob = bucket.blob('secret-file.txt')
blob.upload_from_filename(
    'local-file.txt',
    encryption_key=encryption_key
)

# Download with same key
blob = bucket.blob('secret-file.txt')
downloaded_data = blob.download_as_bytes(
    encryption_key=encryption_key
)
```

**Security Note:** CSEK requires managing keys in application - complex and risky.

### Signed URLs

Generate time-limited URLs for accessing objects without credentials.

```bash
# Create signed URL (1 hour)
gcloud storage objects generate-signed-url gs://my-bucket/file.txt \
  --duration=1h

# Create signed URL with custom name
gcloud storage objects generate-signed-url gs://my-bucket/confidential.pdf \
  --duration=24h \
  --response-header-disposition="attachment;filename=report.pdf"
```

**Python:**
```python
from google.cloud import storage
from datetime import timedelta

def generate_signed_url(bucket_name, blob_name, expiration_hours=1):
    """Generate signed URL"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    
    url = blob.generate_signed_url(
        version="v4",
        expiration=timedelta(hours=expiration_hours),
        method="GET"
    )
    
    return url

def generate_signed_upload_url(bucket_name, blob_name, expiration_hours=1):
    """Generate signed URL for uploads"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    
    url = blob.generate_signed_url(
        version="v4",
        expiration=timedelta(hours=expiration_hours),
        method="PUT"
    )
    
    return url

# Usage
download_url = generate_signed_url('my-bucket', 'report.pdf', 24)
upload_url = generate_signed_upload_url('my-bucket', 'upload-here.txt', 1)
```

### Public vs Private Buckets

**Private Bucket (Recommended):**
```hcl
resource "google_storage_bucket" "private_bucket" {
  name          = "private-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  # Block all public access
  uniform_bucket_level_access = true

  # All objects are private
  public_access_prevention = "enforced"
}
```

**Public Bucket (Use with caution):**
```hcl
resource "google_storage_bucket" "public_bucket" {
  name          = "public-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  # Only for non-sensitive data
  uniform_bucket_level_access = true
}

# Make specific objects public
resource "google_storage_object_access_control" "public_object" {
  bucket = google_storage_bucket.public_bucket.name
  object = "public-doc.pdf"
  role   = "READER"
  entity = "allUsers"
}
```

---

## 9. Data Protection

### Retention Policies

Prevents deletion or modification of objects for compliance.

```bash
# Set retention policy (in seconds)
# 1 year = 31,536,000 seconds
gsutil retention set 31536000 gs://my-bucket

# View retention policy
gsutil retention get gs://my-bucket

# Unlock retention (only project owner)
gsutil retention lock gs://my-bucket
```

**Terraform:**
```hcl
resource "google_storage_bucket" "retention_bucket" {
  name          = "retention-bucket-${var.project_id}"
  location      = "US"
  storage_class = "STANDARD"

  # 1 year retention in seconds
  retention_policy {
    retention_days = 365
  }
}
```

### Bucket Lock

Locks the retention policy to prevent modification.

```bash
# Lock bucket retention policy
gsutil retention lock gs://my-bucket

# Cannot be unlocked - permanent
```

**Important:** Once locked, cannot be changed by anyone including project owner.

### Soft Delete

Allows recovering objects deleted within 7 days (new feature).

```bash
# Check soft delete setting
gcloud storage buckets describe gs://my-bucket \
  --format="value(softDeletePolicy)"

# Configure via Console only (or wait for gcloud support)
```

### Object Holds

Prevent deletion of specific objects regardless of retention policy.

```bash
# Set legal hold on object
gsutil hold set gs://my-bucket/file.txt

# Release legal hold
gsutil hold release gs://my-bucket/file.txt

# Check hold status
gsutil hold get gs://my-bucket/file.txt
```

**Python:**
```python
def set_object_hold(bucket_name, blob_name):
    """Set legal hold on object"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    
    blob.event_based_hold = True
    blob.patch()

def release_object_hold(bucket_name, blob_name):
    """Release legal hold"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    
    blob.event_based_hold = False
    blob.patch()
```

---

## 10. Data Transfer

### gsutil - Command Line Tool

Most common method for manual transfers.

```bash
# Parallel transfers for speed
gsutil -m cp -r ./large-dir gs://my-bucket/

# Show progress
gsutil -P cp large-file.tar.gz gs://my-bucket/

# Composite uploads (parallel for large files)
gsutil -o "GSUtil:parallel_composite_upload_threshold=150M" \
  cp large-file.tar.gz gs://my-bucket/

# Resume interrupted transfers
gsutil cp -r gs://source-bucket gs://dest-bucket

# Synchronize directories
gsutil -m rsync -r -d ./local-dir gs://my-bucket/sync-dir
```

### gcloud storage (Newer Alternative)

```bash
# Upload
gcloud storage cp local-file.txt gs://my-bucket/

# Download
gcloud storage cp gs://my-bucket/file.txt ./

# Copy between buckets
gcloud storage cp gs://source-bucket/file gs://dest-bucket/

# Recursive operations
gcloud storage cp -r ./dir gs://my-bucket/
```

### Storage Transfer Service

Managed service for large-scale data transfers.

**Use Cases:**
- Transfer from AWS S3
- Transfer from on-premises
- Scheduled periodic transfers
- High-volume migrations

```hcl
resource "google_storage_transfer_job" "s3_migration" {
  description = "S3 to GCS Migration"
  project     = var.project_id

  transfer_spec {
    aws_s3_data_source {
      bucket_name = "my-s3-bucket"
      path        = "data/"
      aws_access_key {
        access_key_id     = var.aws_access_key_id
        secret_access_key = var.aws_secret_access_key
      }
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.destination.name
    }
  }

  schedule {
    schedule_start_date {
      year  = 2024
      month = 1
      day   = 1
    }
    schedule_end_date {
      year  = 2025
      month = 12
      day   = 31
    }
    repeat_interval = "86400s"  # Daily
  }
}

# On-premises to GCS
resource "google_storage_transfer_job" "on_prem_migration" {
  description = "On-Premises to GCS"
  project     = var.project_id

  transfer_spec {
    http_data_source {
      list_url = "https://example.com/file-list"
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.destination.name
    }
  }
}
```

### Transfer Appliance

Physical device for transferring petabytes of data.

**Process:**
1. Request Transfer Appliance
2. Google ships to your location
3. Connect to network and load data
4. Ship back to Google
5. Data loaded into GCS

**Best for:** 1 PB+ of data

---

## 11. Monitoring & Logging

### Cloud Monitoring

Monitor bucket and object metrics.

```bash
# View metrics via gcloud
gcloud monitoring metrics-descriptors list \
  --filter="metric.type:storage"

# Query bucket size
gcloud monitoring time-series list \
  --filter='resource.type="gcs_bucket" AND metric.type="storage.googleapis.com/storage/total_bytes"'
```

**Terraform - Create Monitoring Alert:**
```hcl
resource "google_monitoring_alert_policy" "bucket_size_alert" {
  display_name = "GCS Bucket Size Alert"
  combiner     = "OR"

  conditions {
    display_name = "Bucket exceeds 100GB"
    condition_threshold {
      filter          = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${google_storage_bucket.prod_bucket.name}\" AND metric.type=\"storage.googleapis.com/storage/total_bytes\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 100000000000  # 100GB

      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification"
  type         = "email"
  labels = {
    email_address = "admin@example.com"
  }
}
```

### Cloud Logging

Track all operations on buckets and objects.

```bash
# View bucket access logs
gcloud logging read "resource.type=gcs_bucket AND resource.labels.bucket_name=my-bucket" \
  --limit 50 \
  --format json

# View object operations
gcloud logging read "protoPayload.resourceName=~\"storage.googleapis.com.*my-bucket\"" \
  --limit 50

# Create log sink to BigQuery
gcloud logging sinks create gcs-logs-bq \
  bigquery.googleapis.com/projects/my-project/datasets/gcs_logs \
  --log-filter='resource.type="gcs_bucket"'
```

### Audit Logs

Track who accessed what and when.

```bash
# Enable audit logging in IAM policy
gcloud projects get-iam-policy my-project \
  --flatten="auditConfigs" \
  --filter="service=storage.googleapis.com"

# View audit logs
gcloud logging read "protoPayload.methodName=storage.buckets.get" \
  --limit 10 \
  --format json
```

**Terraform - Enable Audit Logging:**
```hcl
resource "google_project_iam_audit_config" "storage_audit" {
  project = var.project_id
  service = "storage.googleapis.com"
  
  audit_log_config {
    log_type = "ADMIN_WRITE"
  }
  
  audit_log_config {
    log_type = "DATA_READ"
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
```

---

## 12. Real-World Scenarios

### Scenario 1: Data Lake Architecture

**Requirements:**
- Ingest daily logs from multiple sources
- Store for 2 years
- Query recent data (< 30 days) frequently
- Archive old data

**Solution:**

```hcl
# Bronze layer - raw data (STANDARD)
resource "google_storage_bucket" "bronze_layer" {
  name          = "data-lake-bronze-${var.project_id}"
  location      = "us-central1"
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  versioning {
    enabled = true
  }

  labels = {
    layer    = "bronze"
    data_age = "raw"
  }
}

# Silver layer - processed data (STANDARD)
resource "google_storage_bucket" "silver_layer" {
  name          = "data-lake-silver-${var.project_id}"
  location      = "us-central1"
  storage_class = "STANDARD"

  lifecycle_rule {
    condition {
      age = 60
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    layer    = "silver"
    data_age = "processed"
  }
}

# Gold layer - business ready (STANDARD)
resource "google_storage_bucket" "gold_layer" {
  name          = "data-lake-gold-${var.project_id}"
  location      = "us-central1"
  storage_class = "STANDARD"

  labels = {
    layer    = "gold"
    data_age = "refined"
  }
}
```

### Scenario 2: Backup and Disaster Recovery

**Requirements:**
- Daily database backups
- Keep last 7 days in STANDARD
- Keep 30 days in NEARLINE
- Keep 2 years in ARCHIVE
- Disaster recovery test monthly

**Solution:**

```hcl
resource "google_storage_bucket" "backup_bucket" {
  name          = "company-backups-${var.project_id}"
  location      = "us"  # Multi-region for HA
  storage_class = "STANDARD"

  # Keep last 7 backups in STANDARD
  lifecycle_rule {
    condition {
      num_newer_versions = 7
      is_live            = false
    }
    action {
      type = "Delete"
    }
  }

  # Move to NEARLINE after 7 days
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Move to COLDLINE after 30 days
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Move to ARCHIVE after 90 days (2-year requirement)
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Delete after 2 years
  lifecycle_rule {
    condition {
      age = 730
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }

  retention_policy {
    retention_days = 365  # Minimum 1 year
  }

  labels = {
    backup_type = "database"
    criticality = "high"
  }
}

# Secondary backup location for DR
resource "google_storage_bucket" "backup_bucket_dr" {
  name          = "company-backups-dr-${var.project_id}"
  location      = "eu"  # Different continent
  storage_class = "STANDARD"
  # Same lifecycle as primary
}

# Backup service account
resource "google_service_account" "backup_sa" {
  account_id   = "backup-service"
  display_name = "Backup Service Account"
}

# Grant permissions
resource "google_storage_bucket_iam_member" "backup_write" {
  bucket = google_storage_bucket.backup_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.backup_sa.email}"
}
```

### Scenario 3: Static Website Hosting

**Requirements:**
- Host static HTML/CSS/JS files
- CDN caching
- HTTPS only
- Custom domain

**Solution:**

```hcl
resource "google_storage_bucket" "website" {
  name          = "my-website-${var.project_id}"
  location      = "US"  # Multi-region for low latency
  storage_class = "STANDARD"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  uniform_bucket_level_access = true

  cors {
    origin          = ["https://example.com"]
    method          = ["GET", "HEAD"]
    response_header = ["Content-Type", "Cache-Control"]
    max_age_seconds = 3600
  }

  labels = {
    environment = "production"
    type        = "website"
  }
}

# Make bucket public for website
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload files
resource "google_storage_object" "index" {
  name        = "index.html"
  bucket      = google_storage_bucket.website.name
  source      = "${path.module}/files/index.html"
  content_type = "text/html"
  cache_control = "public, max-age=3600"
}

resource "google_storage_object" "styles" {
  name        = "styles.css"
  bucket      = google_storage_bucket.website.name
  source      = "${path.module}/files/styles.css"
  content_type = "text/css"
  cache_control = "public, max-age=86400"
}

# Cloud CDN backend bucket
resource "google_compute_backend_bucket" "website_backend" {
  name            = "website-backend"
  bucket_name     = google_storage_bucket.website.name
  enable_cdn      = true
  protocol        = "HTTPS"

  cdn_policy {
    cache_mode        = "CACHE_ALL_STATIC"
    negative_caching  = true
    negative_caching_policy = [
      {
        code = 404
        ttl  = 120
      },
      {
        code = 410
        ttl  = 120
      }
    ]
  }
}

# Load balancer for CDN
resource "google_compute_url_map" "website" {
  name            = "website-lb"
  default_service = google_compute_backend_bucket.website_backend.id
}

resource "google_compute_ssl_certificate" "website" {
  name            = "website-cert"
  managed {
    domains = ["example.com"]
  }
}

resource "google_compute_target_https_proxy" "website" {
  name             = "website-https-proxy"
  url_map          = google_compute_url_map.website.id
  ssl_certificates = [google_compute_ssl_certificate.website.id]
}

# Outputs
output "bucket_url" {
  value = google_storage_bucket.website.url
}

output "website_ip" {
  value = google_compute_global_address.website.address
}
```

### Scenario 4: Machine Learning Model Storage

**Requirements:**
- Store trained models with versions
- Keep training history
- Organize by experiment
- Quick access for serving

**Solution:**

```hcl
resource "google_storage_bucket" "ml_models" {
  name          = "ml-models-${var.project_id}"
  location      = "us-central1"
  storage_class = "STANDARD"

  # Organize by: experiments/{exp_id}/models/{model_version}
  
  versioning {
    enabled = true
  }

  lifecycle_rule {
    # Keep only last 5 model versions
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    # Archive old experiments after 90 days
    condition {
      age              = 90
      matches_prefix   = ["experiments/"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    application = "ml-platform"
    data_type   = "models"
  }
}

# Metadata bucket for experiment configs
resource "google_storage_bucket" "ml_metadata" {
  name          = "ml-metadata-${var.project_id}"
  location      = "us-central1"
  storage_class = "STANDARD"

  # Store config JSONs, metrics, etc.
  labels = {
    application = "ml-platform"
    data_type   = "metadata"
  }
}

# Service account for ML pipeline
resource "google_service_account" "ml_pipeline_sa" {
  account_id   = "ml-pipeline"
  display_name = "ML Pipeline Service Account"
}

# Grant access to read/write models
resource "google_storage_bucket_iam_member" "ml_read_write" {
  bucket = google_storage_bucket.ml_models.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ml_pipeline_sa.email}"
}

# Grant access to metadata
resource "google_storage_bucket_iam_member" "ml_metadata_access" {
  bucket = google_storage_bucket.ml_metadata.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ml_pipeline_sa.email}"
}
```

**Model Management Python Code:**

```python
from google.cloud import storage
import json
from datetime import datetime

class MLModelManager:
    def __init__(self, project_id):
        self.client = storage.Client(project=project_id)
        self.models_bucket = self.client.bucket('ml-models')
        self.metadata_bucket = self.client.bucket('ml-metadata')

    def save_model(self, experiment_id, model_version, model_bytes, metrics):
        """Save trained model with metadata"""
        timestamp = datetime.now().isoformat()
        
        # Save model
        model_path = f"experiments/{experiment_id}/models/v{model_version}/model.pkl"
        model_blob = self.models_bucket.blob(model_path)
        model_blob.upload_from_string(model_bytes)
        
        # Save metrics and config
        metadata = {
            "experiment_id": experiment_id,
            "version": model_version,
            "timestamp": timestamp,
            "metrics": metrics,
            "model_path": model_path
        }
        
        metadata_path = f"experiments/{experiment_id}/v{model_version}_metadata.json"
        metadata_blob = self.metadata_bucket.blob(metadata_path)
        metadata_blob.upload_from_string(json.dumps(metadata, indent=2))
        
        return metadata

    def list_experiments(self):
        """List all experiments"""
        experiments = set()
        for blob in self.models_bucket.list_blobs(prefix="experiments/"):
            parts = blob.name.split('/')
            if len(parts) > 1:
                experiments.add(parts[1])
        return list(experiments)

    def get_latest_model(self, experiment_id):
        """Get latest model version"""
        prefix = f"experiments/{experiment_id}/models/"
        models = list(self.models_bucket.list_blobs(prefix=prefix))
        
        if not models:
            return None
            
        latest = max(models, key=lambda b: b.updated)
        return latest

    def download_model(self, experiment_id, version):
        """Download specific model version"""
        model_path = f"experiments/{experiment_id}/models/v{version}/model.pkl"
        blob = self.models_bucket.blob(model_path)
        return blob.download_as_bytes()

# Usage
manager = MLModelManager('my-project')

# Save model
model_metrics = {
    "accuracy": 0.95,
    "precision": 0.93,
    "recall": 0.97
}
manager.save_model("exp-001", 1, model_bytes, model_metrics)

# List experiments
experiments = manager.list_experiments()

# Get latest model
latest = manager.get_latest_model("exp-001")
```

---

## 13. Interview Q&A

### Basic Level

**Q1: What is the difference between Cloud Storage and Cloud Filestore?**

Cloud Storage is object storage (unstructured data, accessed via REST API), while Cloud Filestore is managed NFS file storage (structured, accessed like traditional file system). Use Cloud Storage for backups, archives, logs. Use Filestore for shared file systems, databases.

**Q2: Explain the global namespace for bucket names.**

Bucket names must be globally unique across ALL GCP projects and even other cloud providers. Once a bucket name is used, no one else can use it. Names are 3-63 characters, lowercase, no underscores.

**Q3: What are storage classes and which would you use for logs that are accessed once per month?**

Storage classes optimize cost based on access patterns:
- STANDARD: Frequently accessed
- NEARLINE: Monthly access (~$0.01/GB vs $0.02)
- COLDLINE: Quarterly access
- ARCHIVE: Yearly/backup

For monthly logs, use NEARLINE - saves ~50% on storage with higher retrieval costs.

**Q4: How do you enable versioning on a bucket?**

```bash
gsutil versioning set on gs://my-bucket
```

Versioning creates generations (versions) of each object. Enable to recover deleted files. Each version takes storage space.

**Q5: Explain ACLs vs IAM. Which should you use?**

- **ACLs:** Object-level access control. Legacy, fine-grained, complex to manage.
- **IAM:** Bucket-level access via roles. Modern, simpler, recommended by Google.

Use Uniform Bucket-Level Access (UBLA) to enforce IAM only and disable ACLs.

### Intermediate Level

**Q6: You have 100TB of data in Standard storage. It's rarely accessed but compliance requires keeping it for 5 years. How would you optimize costs?**

Use lifecycle management to auto-transition:
1. After 30 days → NEARLINE (saves ~50%)
2. After 90 days → COLDLINE (saves ~80%)
3. After 365 days → ARCHIVE (saves ~99%)

This reduces monthly cost from ~$2000 (Standard) to ~$25 (Archive).

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "SetStorageClass", "storageClass": "NEARLINE"},
        "condition": {"age": 30}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "COLDLINE"},
        "condition": {"age": 90}
      },
      {
        "action": {"type": "SetStorageClass", "storageClass": "ARCHIVE"},
        "condition": {"age": 365}
      },
      {
        "action": {"type": "Delete"},
        "condition": {"age": 1825}  // 5 years
      }
    ]
  }
}
```

**Q7: Design a bucket structure for a data lake with bronze, silver, and gold layers.**

```
data-lake-bronze/      # STANDARD, all raw data
  ├── source-1/
  ├── source-2/
  └── lifecycle: 30d→NEARLINE, 90d→COLDLINE

data-lake-silver/      # STANDARD, cleaned data
  ├── processed/
  └── lifecycle: 60d→NEARLINE, 180d→COLDLINE

data-lake-gold/        # STANDARD, ready-to-use
  ├── analytics/
  └── versioning: enabled
```

**Q8: How do you securely transfer 50TB of data from AWS S3 to GCS?**

Options:
1. **Storage Transfer Service** (recommended): Managed service, parallel transfers, scheduled, monitors progress
2. **gsutil**: CLI tool, for smaller volumes
3. **DataFlow**: For ETL while transferring

```terraform
resource "google_storage_transfer_job" "s3_to_gcs" {
  # Configure transfer specification
  transfer_spec {
    aws_s3_data_source {
      bucket_name = "my-s3-bucket"
      aws_access_key { ... }
    }
    gcs_data_sink {
      bucket_name = "my-gcs-bucket"
    }
  }
}
```

**Q9: Explain the difference between CMEK and CSEK encryption.**

- **CMEK (Customer-Managed Encryption Keys):** Google manages encryption/decryption, but you manage KMS keys. Better security, easier management. Recommended.
- **CSEK (Customer-Supplied Encryption Keys):** You manage keys completely. Complex, risky if key is lost.

For production, use CMEK with Cloud KMS.

**Q10: You need to recover a file deleted 15 days ago. You didn't have versioning enabled. Can you recover it?**

No, you cannot recover it. Versioning must be enabled BEFORE deletion. Without versioning:
- Deleted objects are permanently gone
- No way to recover

Enable versioning immediately for critical buckets.

### Advanced Level

**Q11: Design a multi-region backup strategy for a mission-critical database with RTO=4 hours and RPO=1 hour.**

```terraform
# Primary region - STANDARD for RPO
resource "google_storage_bucket" "backup_primary" {
  name          = "backup-primary-${var.project_id}"
  location      = "us"  # Multi-region
  storage_class = "STANDARD"

  versioning { enabled = true }
  
  lifecycle_rule {
    condition { age = 7 }
    action { type = "SetStorageClass", "storageClass" = "NEARLINE" }
  }
}

# Secondary region - for RTO failover
resource "google_storage_bucket" "backup_secondary" {
  name          = "backup-secondary-${var.project_id}"
  location      = "eu"  # Different continent
  storage_class = "STANDARD"
}

# Cross-region replication via Transfer Service
resource "google_storage_transfer_job" "replication" {
  description = "Primary to Secondary Replication"
  
  transfer_spec {
    gcs_data_source {
      bucket_name = google_storage_bucket.backup_primary.name
    }
    gcs_data_sink {
      bucket_name = google_storage_bucket.backup_secondary.name
    }
  }

  # Hourly sync to meet RPO
  schedule {
    repeat_interval = "3600s"  # 1 hour
  }
}
```

**Q12: Implement a data governance solution tracking who accessed what data and when.**

```terraform
# Enable audit logging
resource "google_project_iam_audit_config" "storage_audit" {
  project = var.project_id
  service = "storage.googleapis.com"
  
  audit_log_config {
    log_type = "DATA_READ"
    exempted_members = []
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Stream logs to BigQuery for analysis
resource "google_logging_project_sink" "storage_audit_sink" {
  name        = "storage-audit-sink"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/audit_logs"
  
  filter = "resource.type=\"gcs_bucket\" AND protoPayload.methodName=~\"storage\\.\"" 
}

# BigQuery table for analysis
resource "google_bigquery_table" "audit_logs" {
  dataset_id = google_bigquery_dataset.audit_dataset.dataset_id
  table_id   = "storage_access_logs"
  
  schema = jsonencode([
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
    },
    {
      name        = "principal"
      type        = "STRING"
      mode        = "NULLABLE"
    },
    {
      name        = "resource"
      type        = "STRING"
      mode        = "NULLABLE"
    },
    {
      name        = "method"
      type        = "STRING"
      mode        = "NULLABLE"
    },
    {
      name        = "status"
      type        = "STRING"
      mode        = "NULLABLE"
    }
  ])
}
```

SQL queries for analysis:
```sql
-- Most accessed objects
SELECT resource, COUNT(*) as access_count
FROM `project.dataset.storage_access_logs`
WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
GROUP BY resource
ORDER BY access_count DESC;

-- Access by user
SELECT principal, COUNT(*) as access_count
FROM `project.dataset.storage_access_logs`
WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY principal;

-- Failed access attempts
SELECT timestamp, principal, resource, method
FROM `project.dataset.storage_access_logs`
WHERE status NOT IN ('OK', '200')
ORDER BY timestamp DESC;
```

**Q13: You're migrating from on-premises HDFS. Design the migration strategy and implementation.**

```python
from google.cloud import storage
import os
from concurrent.futures import ThreadPoolExecutor
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HDFStoGCSMigration:
    def __init__(self, bucket_name, project_id, max_workers=10):
        self.client = storage.Client(project=project_id)
        self.bucket = self.client.bucket(bucket_name)
        self.max_workers = max_workers

    def migrate_directory(self, hdfs_path, gcs_prefix):
        """Migrate entire HDFS directory to GCS"""
        
        # Step 1: Inventory
        files_to_migrate = []
        for root, dirs, files in os.walk(hdfs_path):
            for file in files:
                local_path = os.path.join(root, file)
                relative_path = os.path.relpath(local_path, hdfs_path)
                gcs_path = f"{gcs_prefix}/{relative_path}"
                files_to_migrate.append((local_path, gcs_path))
        
        logger.info(f"Found {len(files_to_migrate)} files to migrate")
        
        # Step 2: Parallel upload
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = []
            for local_path, gcs_path in files_to_migrate:
                future = executor.submit(self._upload_file, local_path, gcs_path)
                futures.append(future)
            
            # Wait for completion and collect results
            for i, future in enumerate(futures):
                try:
                    future.result()
                    if (i + 1) % 100 == 0:
                        logger.info(f"Migrated {i + 1}/{len(files_to_migrate)} files")
                except Exception as e:
                    logger.error(f"Error uploading: {e}")

    def _upload_file(self, local_path, gcs_path):
        """Upload single file with retry logic"""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                blob = self.bucket.blob(gcs_path)
                blob.upload_from_filename(local_path)
                logger.debug(f"Uploaded: {gcs_path}")
                return True
            except Exception as e:
                if attempt < max_retries - 1:
                    logger.warning(f"Retry {attempt + 1} for {gcs_path}: {e}")
                else:
                    logger.error(f"Failed to upload {gcs_path}: {e}")
                    return False

    def verify_migration(self, gcs_prefix):
        """Verify all files migrated"""
        count = sum(1 for _ in self.bucket.list_blobs(prefix=gcs_prefix))
        logger.info(f"Verification: {count} objects in {gcs_prefix}")

# Usage
migrator = HDFStoGCSMigration('my-bucket', 'my-project')
migrator.migrate_directory('/hdfs/data/warehouse', 'warehouse')
migrator.verify_migration('warehouse')
```

**Q14: You have a compliance requirement to retain all data for 10 years but delete immediately upon request. Design the solution.**

```terraform
resource "google_storage_bucket" "compliance_archive" {
  name          = "compliance-archive-${var.project_id}"
  location      = "us"  # Multi-region for durability
  storage_class = "ARCHIVE"

  # 10-year retention
  retention_policy {
    retention_days = 3650
  }

  # Protect from accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  labels = {
    compliance = "true"
    data_subject_to_deletion_rights = "true"
  }
}

# Deletion request tracking table
resource "google_bigquery_table" "deletion_requests" {
  dataset_id = google_bigquery_dataset.compliance.dataset_id
  table_id   = "deletion_requests"
  
  schema = jsonencode([
    { name = "request_id", type = "STRING", mode = "REQUIRED" },
    { name = "subject_id", type = "STRING", mode = "REQUIRED" },
    { name = "data_subjects", type = "STRING", mode = "REPEATED" },
    { name = "requested_date", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "fulfilled_date", type = "TIMESTAMP", mode = "NULLABLE" },
    { name = "status", type = "STRING", mode = "REQUIRED" },
    { name = "gcs_paths", type = "STRING", mode = "REPEATED" }
  ])
}
```

**Important:** Retention Policy prevents deletion for specified period. For GDPR right-to-be-forgotten, implement:
1. Encryption with CMEK (you control keys)
2. Delete KMS key for that data (renders data unreadable, not technically deleted)
3. Log deletion in audit trail

```python
def implement_right_to_be_forgotten(subject_id):
    """Implement GDPR right-to-be-forgotten"""
    # 1. Find all objects for subject
    bucket = storage.Client().bucket('compliance-archive')
    blobs = bucket.list_blobs(prefix=f"subjects/{subject_id}/")
    
    # 2. If on retention, cannot delete - must disable KMS key instead
    # 3. Log deletion request
    # 4. Schedule KMS key deletion after retention period
    
    # For data outside retention:
    for blob in blobs:
        blob.delete()  # Soft delete (can recover if versioning)
```

**Q15: Design a solution for real-time data ingestion (millions of events/second) with GCS as destination.**

```terraform
# High-throughput ingestion bucket
resource "google_storage_bucket" "ingestion" {
  name          = "real-time-ingestion-${var.project_id}"
  location      = "us-central1"  # Near processing
  storage_class = "STANDARD"

  # Partition objects for parallel processing
  # Pattern: gs://bucket/data/year=2024/month=01/day=15/hour=12/file-*.parquet
}

# Pub/Sub to organize events
resource "google_pubsub_topic" "events" {
  name = "events-topic"
}

# Dataflow for ingestion
resource "google_dataflow_job" "ingest_events" {
  name              = "ingest-events"
  template_gcs_path = "gs://dataflow-templates/latest/Pub_Sub_to_GCS_Avro"
  
  parameters = {
    inputTopic        = google_pubsub_topic.events.id
    outputDirectory   = "gs://${google_storage_bucket.ingestion.name}/data/"
    outputFilenamePrefix = "events"
    outputFilenameSuffix = ".parquet"
    windowDuration    = "60"  # 1 minute windows
  }
}

# Partitioning for BigQuery external table
resource "google_bigquery_table" "events_external" {
  dataset_id = google_bigquery_dataset.data.dataset_id
  table_id   = "events_external"
  
  external_data_configuration {
    source_uris = [
      "gs://${google_storage_bucket.ingestion.name}/data/year=*/month=*/day=*/hour=*/*.parquet"
    ]
    
    source_format = "PARQUET"
    
    hive_partitioning_options {
      mode = "AUTO"
    }
  }
}
```

---

## 14. Best Practices & Cost Optimization

### Security Best Practices

1. **Always use Uniform Bucket-Level Access**
   ```terraform
   uniform_bucket_level_access = true
   ```

2. **Enable encryption with CMEK**
   ```terraform
   encryption {
     default_kms_key_name = google_kms_crypto_key.key.id
   }
   ```

3. **Use Service Accounts for applications**
   - Don't use user credentials
   - Apply principle of least privilege
   - Rotate keys regularly

4. **Enable audit logging**
   ```terraform
   resource "google_project_iam_audit_config" "storage_audit" {
     service = "storage.googleapis.com"
     audit_log_config { log_type = "DATA_READ" }
   }
   ```

5. **Implement VPC Service Controls**
   - Prevent data exfiltration
   - Control who can access buckets

6. **Monitor public access**
   ```bash
   gsutil iam ch gs://my-bucket
   gcloud storage buckets get-iam-policy gs://my-bucket
   ```

### Cost Optimization Strategies

**1. Use appropriate storage class based on access patterns**

```
Access Pattern          | Recommended Class | Cost Saving
Daily access            | STANDARD          | Baseline
Monthly access          | NEARLINE          | 50%
Quarterly access        | COLDLINE          | 80%
Annual archive          | ARCHIVE           | 99%
```

**2. Implement lifecycle policies**

Move old data through classes automatically. Don't leave everything in STANDARD.

**3. Use deletion lifecycle rules**

Remove temporary data automatically:
```terraform
lifecycle_rule {
  condition {
    age              = 30
    matches_prefix   = ["tmp/", "cache/"]
  }
  action {
    type = "Delete"
  }
}
```

**4. Delete old versions**

```terraform
lifecycle_rule {
  condition {
    num_newer_versions = 5
  }
  action {
    type = "Delete"
  }
}
```

**5. Compress before uploading**

```bash
tar -czf data.tar.gz large-data/
gsutil cp data.tar.gz gs://my-bucket/

# Saves transfer time and storage
```

**6. Use regional buckets**

Multi-region has premium. Use regional buckets if data locality is acceptable:

```
Multi-region:   $0.020/GB/month
Dual-region:    $0.024/GB/month  
Regional:       $0.020/GB/month
```

**7. Monitor and alert on costs**

```hcl
resource "google_monitoring_alert_policy" "bucket_cost" {
  display_name = "High GCS Costs"
  
  conditions {
    display_name = "Monthly cost > $1000"
    # Configure alert based on billing data
  }
}
```

**8. Use object tags for cost allocation**

```bash
gsutil label ch -l "cost-center:1234,project:analytics" gs://my-bucket
```

### Performance Best Practices

1. **Use parallel uploads/downloads**
   ```bash
   gsutil -m cp -r ./large-dir gs://my-bucket/
   ```

2. **Enable composite uploads for large files**
   ```bash
   gsutil -o "GSUtil:parallel_composite_upload_threshold=150M" \
     cp large-file.tar.gz gs://my-bucket/
   ```

3. **Use regional buckets for latency-sensitive apps**

4. **Implement CDN caching for frequently accessed objects**
   ```terraform
   cache_control = "public, max-age=86400"
   ```

5. **Batch operations**
   ```python
   # Better: Multiple objects in one API call
   # Avoid: Loop with individual requests
   ```

### Data Management Best Practices

1. **Enable versioning for critical data**
2. **Use retention policies for compliance**
3. **Organize with meaningful prefix structure**
   ```
   gs://bucket/department/project/year/month/day/
   ```

4. **Add labels for organization and cost tracking**
5. **Document bucket purposes and policies**
6. **Regular audit of access patterns**
7. **Archive old data systematically**

---

## Additional Resources

- [GCP Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [gsutil Command Reference](https://cloud.google.com/storage/docs/gsutil)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest)
- [Cloud Storage Pricing Calculator](https://cloud.google.com/products/calculator)
- [GCP Security Best Practices](https://cloud.google.com/docs/enterprise-best-practices)

---

**Last Updated:** 2024
**Version:** 2.0
