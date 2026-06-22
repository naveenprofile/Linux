# Complete Docker & Terraform Learning Guide
## Beginner to Advanced with Practical Code Examples

---

## MODULE 1: CONTAINERIZATION FUNDAMENTALS

### 1.1 What is Containerization?

Containerization is a lightweight virtualization technology that packages an application with all its dependencies (code, runtime, system tools, libraries) into a single unit called a container. Containers share the host OS kernel but have isolated file systems, processes, and networks.

**Key Differences:**

| Aspect | Bare Metal | Virtual Machines | Containers |
|--------|-----------|------------------|-----------|
| **Resource Usage** | 100% | 70-80% | 5-15% |
| **Boot Time** | Minutes | 30-60 seconds | Milliseconds |
| **Isolation** | Process-level | Hardware-level | OS-level |
| **Size** | N/A | 1-20GB | 10-500MB |
| **Density** | 1-2 per server | 5-15 per server | 100-500 per server |

### 1.2 Evolution of Virtualization

1. **Bare Metal Era (1990s)**: Direct hardware access, single OS per server
2. **Hypervisor Era (2000s)**: VMware, Hyper-V - multiple VMs per server
3. **Container Era (2010s)**: Docker - lightweight, fast deployment
4. **Modern Era (2020s)**: Kubernetes orchestration, serverless computing

### 1.3 Why Docker?

**Problems Docker Solves:**
- **Dependency Hell**: "Works on my machine" problem
- **Slow Deployment**: Minutes to hours vs. seconds
- **Resource Waste**: VMs consume too much overhead
- **Inconsistency**: Different environments cause bugs
- **Scaling Issues**: Difficult to scale applications quickly

**Real-World Scenario:**
```
Developer Machine (Linux):
✓ Works perfectly with Node.js v16 and PostgreSQL 12

Production Server (Windows):
✗ Different Node.js version
✗ Different PostgreSQL version
✗ Different system libraries
✗ Application crashes

Solution: Docker packages everything in a container
```

### 1.4 Container Ecosystem

```
┌─────────────────────────────────────────┐
│         Container Ecosystem             │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Container Runtime (CRI)       │  │
│  │  ├─ containerd                   │  │
│  │  ├─ CRI-O                        │  │
│  │  └─ Docker                       │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Orchestration Layer           │  │
│  │  ├─ Kubernetes                   │  │
│  │  ├─ Docker Swarm                 │  │
│  │  └─ Nomad                        │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │    Container Registries          │  │
│  │  ├─ Docker Hub                   │  │
│  │  ├─ AWS ECR                      │  │
│  │  ├─ GCP GCR                      │  │
│  │  └─ Harbor (Private)             │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

### 1.5 OCI (Open Container Initiative)

OCI is a governance structure for standardizing container formats:
- **Image-spec**: How to build and package containers
- **Runtime-spec**: How to run containers
- **Distribution-spec**: How to distribute container images

**Benefits:**
- Vendor-neutral standards
- Multiple implementations (Docker, Podman, CRI-O)
- Interoperability between tools

### 1.6 Docker Alternatives

**Podman**
```bash
# Podman is a drop-in replacement for Docker
# Advantages: Rootless containers, no daemon dependency
podman run -it ubuntu bash
```

**Containerd**
- Lightweight container runtime
- Used by Kubernetes
- Smaller footprint than Docker

**CRI-O**
- Kubernetes-specific container runtime
- Optimized for K8s workloads

---

## MODULE 2: DOCKER ARCHITECTURE

### 2.1 Docker Architecture Components

```
┌──────────────────────────────────────────────────┐
│           DOCKER HOST MACHINE                    │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │  Docker Client (CLI)                       │ │
│  │  $ docker run, docker pull, docker build   │ │
│  └────────────────┬─────────────────────────┘ │
│                   │ (REST API)                 │
│                   │                            │
│  ┌────────────────▼─────────────────────────┐ │
│  │  Docker Daemon (dockerd)                 │ │
│  │  ├─ Image Management                     │ │
│  │  ├─ Container Management                 │ │
│  │  ├─ Network Management                   │ │
│  │  └─ Storage Management                   │ │
│  └────────────────┬──────────────────────┬─┘ │
│                   │                      │    │
│  ┌────────────────▼────┐  ┌──────────────▼──┐│
│  │  Docker Engine      │  │  containerd     ││
│  │  ├─ OCI Runtime     │  │  (Low-level     ││
│  │  └─ Execution       │  │   runtime)      ││
│  └─────────────────────┘  └─────────────────┘│
│                                               │
│  ┌────────────────────────────────────────┐  │
│  │  Containers                            │  │
│  │  ├─ Container 1 (isolated process)     │  │
│  │  ├─ Container 2 (isolated process)     │  │
│  │  └─ Container 3 (isolated process)     │  │
│  └────────────────────────────────────────┘  │
│                                               │
└──────────────────────────────────────────────┘

        ▼
    ┌──────────────────┐
    │  Docker Registry │
    │  (Hub/Private)   │
    └──────────────────┘
```

### 2.2 Key Components Explained

**Docker Client**
- Command-line interface users interact with
- Sends commands to Docker Daemon via REST API
- Examples: `docker run`, `docker pull`, `docker build`

**Docker Daemon**
- Runs as a background service
- Manages containers, images, networks, and storage
- Listens on Unix socket or network socket

**Docker REST API**
- Communication protocol between client and daemon
- TCP port 2375 (unsecured) / 2376 (secured)
- Can be used programmatically

**Docker Registry**
- Central repository for Docker images
- Docker Hub (public), ECR (AWS), GCR (Google), Harbor (private)

### 2.3 Image vs Container

**Image**: Blueprint/template (immutable)
**Container**: Running instance of an image (mutable)

```
Analogy:
Image = Class Definition in Programming
Container = Object/Instance created from class
```

### 2.4 Basic Commands

```bash
# Check Docker version and info
docker version
docker info

# Output example:
# Client: Docker Engine - Community
#  Version:           20.10.21
#  API version:       1.41
# 
# Server: Docker Engine - Community
#  Engine:
#   Version:          20.10.21
```

---

## MODULE 3: DOCKER INSTALLATION

### 3.1 Linux Installation

**CentOS/RHEL:**
```bash
# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker  # Start on boot

# Verify installation
sudo docker run hello-world
```

**Ubuntu/Debian:**
```bash
# Update package manager
sudo apt update

# Install dependencies
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Start service
sudo systemctl start docker
sudo systemctl enable docker
```

### 3.2 User Access (Running without sudo)

```bash
# Add current user to docker group
sudo usermod -aG docker $USER

# Apply new group membership
newgrp docker

# Verify (no sudo needed)
docker run hello-world

# ⚠️ SECURITY NOTE: This grants equivalent to root access
# Only add trusted users to docker group
```

### 3.3 Service Management

```bash
# Check Docker daemon status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Stop Docker
sudo systemctl stop docker

# Enable on startup
sudo systemctl enable docker

# Disable autostart
sudo systemctl disable docker

# View Docker logs
sudo journalctl -u docker -n 50  # Last 50 lines
sudo journalctl -u docker -f     # Follow logs
```

### 3.4 Post-Installation Setup

```bash
# Install Docker Compose (as of Docker 20.10+, use: docker compose)
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose
docker compose version

# Tab completion for bash
sudo curl -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker
```

---

## MODULE 4: DOCKER IMAGES

### 4.1 What is a Docker Image?

A Docker image is a lightweight, standalone executable package that contains:
- Application code
- Runtime environment
- System tools and libraries
- Environment variables
- Metadata (entry points, exposed ports)

**Image Structure:**
```
┌─────────────────────────────────┐
│      Nginx Image Layer 5        │ ← read-only (app code)
├─────────────────────────────────┤
│      Base Image Layer 4         │ ← read-only (dependencies)
├─────────────────────────────────┤
│      Layer 3                    │ ← read-only
├─────────────────────────────────┤
│      Layer 2                    │ ← read-only
├─────────────────────────────────┤
│      Base OS (Ubuntu)           │ ← read-only
└─────────────────────────────────┘
        (Union Filesystem)
```

### 4.2 Image Layers and Caching

Each Dockerfile instruction creates a layer:

```dockerfile
FROM ubuntu:20.04              # Layer 1 (base image)
RUN apt-get update             # Layer 2
RUN apt-get install -y nginx   # Layer 3
COPY app.conf /etc/nginx/      # Layer 4
RUN chmod 755 /etc/nginx/      # Layer 5
CMD ["nginx", "-g", "daemon off;"]  # Configuration
```

**Layer Caching Benefits:**
```bash
# First build: 5 minutes (builds all layers)
docker build -t myapp:v1 .

# Second build (no changes): 2 seconds (uses cache)
docker build -t myapp:v2 .

# Change only last instruction: 3 seconds (rebuilds only affected layers)
```

**Caching Strategy:**
```dockerfile
# ❌ BAD: Installing deps every build
FROM ubuntu:20.04
COPY . /app
RUN apt-get update && apt-get install -y python3

# ✓ GOOD: Install deps first (they rarely change)
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3
COPY . /app
```

### 4.3 Image Operations

```bash
# Pull image from registry
docker pull nginx:1.21
docker pull ubuntu:20.04

# List all images
docker images
docker images --no-trunc      # Show full image IDs
docker images --digests       # Show digests

# Get image information
docker inspect nginx:latest
# Returns JSON with config, size, layers, etc.

# View image history (layers)
docker history nginx:latest
# Shows each layer, size, and command

# Tag an image
docker tag nginx:latest myregistry/nginx:v1.0

# Remove image
docker rmi nginx:latest
docker rmi $(docker images -q)  # Remove all images

# Image digest (unique identifier)
docker images --digests
# nginx latest sha256:abcd1234... 
```

### 4.4 Image Optimization

**Reduce Image Size:**

```dockerfile
# ❌ Large image (~1.5GB)
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    python3
COPY app.py /
CMD ["python3", "app.py"]

# ✓ Small image (~150MB) - using Alpine
FROM python:3.9-alpine
RUN apk add --no-cache gcc musl-dev
COPY app.py /
CMD ["python3", "app.py"]

# ✓ Optimal (~50MB) - Multi-stage build
FROM python:3.9 AS builder
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.9-slim
COPY --from=builder /root/.local /root/.local
COPY app.py /
ENV PATH=/root/.local/bin:$PATH
CMD ["python3", "app.py"]
```

---

## MODULE 5: DOCKER CONTAINERS

### 5.1 Container Lifecycle

```
┌─────────┐
│  CREATE │  (docker create)
└────┬────┘
     │
┌────▼─────┐
│   START  │  (docker start)
└────┬─────┘
     │
┌────▼──────┐
│   PAUSE   │  (docker pause) ← Optional
└────┬──────┘
     │
┌────▼────────┐
│  UNPAUSE    │  (docker unpause) ← Optional
└────┬────────┘
     │
┌────▼─────┐
│   STOP   │  (docker stop)
└────┬─────┘
     │
┌────▼──────┐
│  RESTART  │  (docker restart)
└────┬──────┘
     │
┌────▼────┐
│  DELETE │  (docker rm)
└──────────┘

Alternative: KILL (immediate termination)
```

### 5.2 Container Commands

```bash
# Create and run container
docker run nginx
docker run -it ubuntu bash          # Interactive terminal
docker run -d nginx                 # Detached (background)
docker run --name myapp nginx       # Named container
docker run --rm ubuntu echo "hi"    # Auto-remove after exit

# List containers
docker ps                           # Running containers
docker ps -a                        # All containers
docker ps -q                        # Container IDs only

# Container lifecycle management
docker stop container_id            # Graceful stop (SIGTERM)
docker start container_id           # Start stopped container
docker restart container_id         # Stop then start
docker kill container_id            # Force stop (SIGKILL)
docker rm container_id              # Delete container

# Container inspection
docker logs container_id            # View container output
docker logs -f container_id         # Follow logs (tail)
docker inspect container_id         # Detailed info (JSON)
docker top container_id             # Running processes
docker stats container_id           # Resource usage

# Execute commands in running container
docker exec container_id ls /       # One-time command
docker exec -it container_id bash   # Interactive shell
docker exec -u root container_id whoami  # As specific user

# Copy files
docker cp file.txt container_id:/path    # Host to container
docker cp container_id:/file.txt .       # Container to host

# Container commit (create image from container)
docker commit container_id myimage:v1
```

### 5.3 Run Options

```bash
# Network options
docker run -p 8080:80 nginx              # Port mapping (host:container)
docker run --expose 3000 app             # Expose port (no mapping)
docker run --network mynet app           # Connect to network
docker run --network host nginx          # Use host network

# Volume options
docker run -v /host:/container nginx     # Bind mount
docker run -v myvol:/data app            # Named volume
docker run --tmpfs /tmp app              # Temporary filesystem

# Resource limits
docker run --memory 512m app             # Memory limit
docker run --cpus 2 app                  # CPU limit
docker run --memory-swap 1g app          # Swap memory

# Environment variables
docker run -e DB_HOST=localhost app      # Set variable
docker run --env-file .env app           # Load from file

# Restart policy
docker run --restart always app          # Always restart
docker run --restart unless-stopped app  # Restart unless manually stopped
docker run --restart on-failure:3 app    # Restart max 3 times on failure

# User and permissions
docker run -u 1000 app                   # Run as user ID 1000
docker run --cap-drop ALL app            # Drop capabilities
docker run --cap-add NET_ADMIN app       # Add capability

# Advanced options
docker run --hostname myhost app         # Set hostname
docker run -w /app app                   # Set working directory
docker run --read-only app               # Read-only filesystem
docker run --label version=1.0 app       # Add labels
```

---

## MODULE 6: DOCKER NETWORKING

### 6.1 Network Drivers

**Bridge Network (Default)**
```
┌─────────────────────────────────────┐
│         Host Machine               │
│  ┌──────────────────────────────┐ │
│  │   Docker Bridge (docker0)    │ │
│  │   IP: 172.17.0.1            │ │
│  │  ┌──────────┬──────────┐    │ │
│  │  │Container │Container │    │ │
│  │  │    1     │    2     │    │ │
│  │  │172.17.0.2│172.17.0.3│   │ │
│  │  └──────────┴──────────┘    │ │
│  └──────────────────────────────┘ │
└─────────────────────────────────────┘
```

```bash
# Default bridge network
docker run nginx                          # Automatically uses docker0

# Custom bridge network (better for DNS)
docker network create mybridge
docker run --network mybridge nginx
docker run --network mybridge app

# Container-to-container communication
docker network connect mybridge container1
docker exec container1 ping container2     # Works by name!
```

**Host Network**
```bash
# Container shares host's network namespace
docker run --network host nginx
# Container uses host's IP directly (172.x.x.x)
# No port translation needed
# ⚠️ Security risk: no network isolation
```

**None Network**
```bash
# Container has no network access
docker run --network none app
# Only loopback interface (127.0.0.1)
```

**Overlay Network (Multi-host)**
```bash
# For Docker Swarm/Kubernetes
docker network create -d overlay myoverlay
# Allows container communication across multiple hosts
```

### 6.2 Network Commands

```bash
# List networks
docker network ls

# Inspect network
docker network inspect bridge      # See connected containers

# Create network
docker network create mynet
docker network create -d bridge mybridgenet
docker network create -d overlay myoverlay

# Connect/Disconnect
docker network connect mynet container_id
docker network disconnect mynet container_id

# Remove network
docker network rm mynet
```

### 6.3 Port Mapping

```bash
# Map single port
docker run -p 8080:80 nginx         # 8080 on host → 80 in container

# Map multiple ports
docker run -p 8080:80 -p 443:443 nginx

# Map all ports
docker run -P nginx                 # Maps all EXPOSE ports

# Bind to specific IP
docker run -p 192.168.1.10:8080:80 nginx

# Dynamic port mapping
docker run -p 80 nginx              # Host chooses random port
docker port container_id            # See port mappings
```

### 6.4 DNS and Service Discovery

```bash
# Within custom bridge network, containers resolve by name
docker network create mynet
docker run --name db --network mynet postgres
docker run --network mynet myapp
# From myapp container: ping db ✓ (works)

# Embedded DNS server at 127.0.0.11:53
# Container /etc/resolv.conf:
# nameserver 127.0.0.11
```

---

## MODULE 7: DOCKER STORAGE

### 7.1 Storage Types

**Volumes (Managed by Docker)**

```bash
# Create volume
docker volume create myvol

# List volumes
docker volume ls

# Inspect volume
docker volume inspect myvol
# Location: /var/lib/docker/volumes/myvol/_data

# Run container with volume
docker run -v myvol:/data nginx

# Volume sharing between containers
docker run -v myvol:/shared container1
docker run -v myvol:/shared container2
# Both containers access same data

# Remove volume
docker volume rm myvol
docker volume prune                 # Remove unused volumes
```

**Advantages:**
- Docker manages storage location
- Works on multiple hosts (with drivers)
- Safer than bind mounts
- Easier to backup

**Bind Mounts (Direct host path)**

```bash
# Mount host directory
docker run -v /host/path:/container/path nginx

# Read-only mount
docker run -v /host/path:/container/path:ro nginx

# Windows paths
docker run -v C:\Users\myapp:/data nginx

# Relative paths
docker run -v $(pwd):/app nginx    # Current directory
```

**tmpfs Mounts (Temporary filesystem)**

```bash
# Store temporary data in memory
docker run --tmpfs /tmp nginx

# With size limit
docker run --tmpfs /tmp:size=512m nginx

# Use cases:
# - Temporary caches
# - Sensitive data (no disk persistence)
# - High-speed data
```

### 7.2 Real-World Scenario: Database with Persistent Storage

```bash
# Create volume for database
docker volume create postgres-data

# Run PostgreSQL with volume
docker run -d \
  --name postgres-db \
  -e POSTGRES_PASSWORD=secret \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:13

# Data persists even after container deletion
docker stop postgres-db
docker rm postgres-db

# Recreate container - data still exists
docker run -d \
  --name postgres-db \
  -e POSTGRES_PASSWORD=secret \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:13

# Backup volume
docker run --rm \
  -v postgres-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/postgres-backup.tar.gz -C /data .

# Restore volume
docker run --rm \
  -v postgres-data:/data \
  -v $(pwd):/backup \
  ubuntu bash -c "cd /data && tar xzf /backup/postgres-backup.tar.gz"
```

---

## MODULE 8: DOCKERFILE

### 8.1 Dockerfile Instructions

```dockerfile
# Syntax: instruction ARGUMENTS

# 1. FROM - Must be first
FROM ubuntu:20.04
# Sets base image for all subsequent instructions

# 2. LABEL - Metadata
LABEL maintainer="devops@example.com"
LABEL version="1.0"
LABEL description="Node.js application"

# 3. ENV - Environment variables
ENV NODE_ENV=production
ENV APP_PORT=3000

# 4. WORKDIR - Set working directory
WORKDIR /app
# Creates directory if doesn't exist
# Subsequent instructions run from this directory

# 5. RUN - Execute commands during build
RUN apt-get update && apt-get install -y \
    curl \
    git \
    node-modules

# 6. COPY - Copy from host to image
COPY package.json .
COPY src/ ./src/

# 7. ADD - Like COPY but can download and extract
ADD https://example.com/archive.tar.gz /tmp/
ADD local.tar.gz /opt/           # Auto-extracts

# 8. EXPOSE - Document exposed ports
EXPOSE 3000 8080
# Does NOT publish ports, just documentation

# 9. VOLUME - Mount point for volumes
VOLUME ["/data", "/logs"]

# 10. USER - Run subsequent commands as user
RUN useradd -m appuser
USER appuser
# Containers run with this user

# 11. HEALTHCHECK - Container health monitoring
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# 12. CMD - Default command (can be overridden)
CMD ["node", "app.js"]

# 13. ENTRYPOINT - Primary command (not overridden by default)
ENTRYPOINT ["node"]
CMD ["app.js"]
# Run as: node app.js (default)
# Run as: docker run container new-script.js → node new-script.js

# 14. ARG - Build-time variables
ARG BUILD_VERSION=1.0
# Used: docker build --build-arg BUILD_VERSION=2.0 .
```

### 8.2 Complete Dockerfile Example

```dockerfile
# Multi-stage build for Node.js application
# Stage 1: Build
FROM node:16-alpine AS builder

LABEL maintainer="devops@example.com"
LABEL description="Node.js application builder"

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Stage 2: Runtime
FROM node:16-alpine

LABEL version="1.0.0"

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy dependencies from builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Copy application code
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Default command
CMD ["node", "app.js"]
```

### 8.3 Best Practices

**❌ Bad Practices:**
```dockerfile
# 1. Single large layer - hard to rebuild
RUN apt-get update && apt-get install -y \
    python3 pip git curl wget vim nano && \
    pip install Django requests && \
    git clone ... && \
    ... lots more

# 2. Caching issues - dependencies change on every COPY
COPY . /app
RUN pip install -r requirements.txt

# 3. Multiple services in one container
RUN apt-get install -y nginx && \
    apt-get install -y supervisor && \
    apt-get install -y postgresql-client

# 4. Running as root
# No USER instruction, runs as root
```

**✓ Good Practices:**
```dockerfile
# 1. Separate concerns, leverage caching
FROM python:3.9-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies first (rarely change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code (changes often)
COPY . .

# Run as non-root user
RUN useradd -m appuser
USER appuser

EXPOSE 8000
CMD ["python", "app.py"]
```

---

## MODULE 9: BUILDING IMAGES

### 9.1 Build Commands

```bash
# Basic build
docker build -t myapp:v1 .
# -t: tag the image
# .: Dockerfile location (current directory)

# Build with multiple tags
docker build -t myapp:v1 -t myapp:latest .

# Build with build arguments
docker build --build-arg BUILD_VERSION=2.0 -t myapp:v2 .

# Build with no cache
docker build --no-cache -t myapp:v1 .

# Build with custom Dockerfile
docker build -f Dockerfile.prod -t myapp:prod .

# Build with specific build context
docker build -f docker/Dockerfile -t myapp:v1 .

# View build details
docker build --progress=plain -t myapp:v1 .
```

### 9.2 Image Tagging Strategy

```bash
# Semantic versioning
docker tag myapp:v1 myapp:1.0.0
docker tag myapp:v1 myapp:latest

# Registry tagging
docker tag myapp:v1 docker.io/username/myapp:v1
docker tag myapp:v1 gcr.io/myproject/myapp:v1
docker tag myapp:v1 myregistry.azurecr.io/myapp:v1

# Push to registries
docker push docker.io/username/myapp:v1
docker push gcr.io/myproject/myapp:v1
docker push myregistry.azurecr.io/myapp:v1
```

### 9.3 Build Context and Optimization

```bash
# Dockerfile
FROM node:16-alpine

WORKDIR /app

# COPY . . copies everything from build context
COPY . .

RUN npm install
```

**.dockerignore file (like .gitignore)**
```
node_modules/
npm-debug.log
.git
.gitignore
.env
.env.local
coverage/
dist/
build/
.DS_Store
.vscode/
__pycache__/
*.pyc
```

```bash
# Build ignores files listed in .dockerignore
docker build -t myapp:v1 .
# Only relevant files are copied into container
```

---

## MODULE 10: DOCKER REGISTRY

### 10.1 Docker Hub

```bash
# Login to Docker Hub
docker login
# Prompts for username and password
# Credentials stored in ~/.docker/config.json

# Pull image from Docker Hub
docker pull ubuntu:20.04
docker pull nginx
docker pull myusername/myapp:v1

# Push image to Docker Hub
docker tag myapp:v1 myusername/myapp:v1
docker push myusername/myapp:v1

# Logout
docker logout
```

### 10.2 Private Registries

**AWS Elastic Container Registry (ECR)**
```bash
# Authenticate with ECR
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789.dkr.ecr.us-east-1.amazonaws.com

# Tag image for ECR
docker tag myapp:v1 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1

# Push to ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1

# Pull from ECR
docker pull 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1
```

**Google Container Registry (GCR)**
```bash
# Configure Docker authentication
gcloud auth configure-docker

# Tag image for GCR
docker tag myapp:v1 gcr.io/my-project-id/myapp:v1

# Push to GCR
docker push gcr.io/my-project-id/myapp:v1

# Pull from GCR
docker pull gcr.io/my-project-id/myapp:v1
```

**Harbor (Private Registry)**
```bash
# Login to Harbor
docker login harbor.example.com -u admin -p password

# Tag and push
docker tag myapp:v1 harbor.example.com/myproject/myapp:v1
docker push harbor.example.com/myproject/myapp:v1

# Pull
docker pull harbor.example.com/myproject/myapp:v1
```

### 10.3 Self-Hosted Registry

```bash
# Run Docker Registry container
docker run -d \
  -p 5000:5000 \
  --name registry \
  -v registry-data:/var/lib/registry \
  registry:2

# Tag and push to local registry
docker tag myapp:v1 localhost:5000/myapp:v1
docker push localhost:5000/myapp:v1

# Pull from local registry
docker pull localhost:5000/myapp:v1
```

---

## MODULE 11: DOCKER COMPOSE

### 11.1 Docker Compose Fundamentals

Docker Compose lets you define multi-container applications in a single YAML file.

**Basic Structure:**
```yaml
version: '3.9'                    # Compose file format version

services:                         # Define services (containers)
  web:                           # Service name
    image: nginx:latest
    container_name: web_container
    ports:
      - "80:80"
    networks:
      - mynet
    depends_on:
      - db

  app:
    build: .                      # Build from Dockerfile
    container_name: app_container
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    ports:
      - "3000:3000"
    networks:
      - mynet
    depends_on:
      - db
    volumes:
      - ./src:/app/src

  db:
    image: postgres:13
    container_name: db_container
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - mynet

networks:                         # Define networks
  mynet:
    driver: bridge

volumes:                          # Define named volumes
  postgres_data:
```

### 11.2 Docker Compose Commands

```bash
# Start services
docker compose up                 # Foreground, show logs
docker compose up -d              # Background (detached)

# Build and start
docker compose up --build         # Rebuild images first

# Stop services
docker compose stop               # Graceful stop (SIGTERM)
docker compose down               # Stop and remove containers
docker compose down -v            # Stop, remove, and delete volumes

# View status
docker compose ps                 # Running services
docker compose top                # Processes in containers

# View logs
docker compose logs               # All services logs
docker compose logs -f app        # Follow logs of 'app' service
docker compose logs --tail=50 web # Last 50 lines of 'web' service

# Execute commands
docker compose exec app bash      # Shell in 'app' service
docker compose exec db psql -U user -d mydb  # Run psql

# Scale services
docker compose up -d --scale worker=3  # Run 3 instances of worker

# Remove services and volumes
docker compose down --rmi all -v  # Remove images, containers, volumes

# Build images
docker compose build              # Build all services
docker compose build app          # Build specific service

# Push images
docker compose push               # Push built images to registry
```

### 11.3 Real-World Example: Web + API + Database + Cache

```yaml
version: '3.9'

services:
  # Nginx Reverse Proxy
  proxy:
    image: nginx:alpine
    container_name: proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - web
      - api
    networks:
      - frontend
    restart: unless-stopped

  # Frontend Web Server
  web:
    image: node:16-alpine
    container_name: web_app
    build:
      context: ./frontend
      dockerfile: Dockerfile
    working_dir: /app
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - NODE_ENV=production
      - REACT_APP_API_URL=http://api:5000
    networks:
      - frontend
      - backend
    depends_on:
      - api
    restart: unless-stopped

  # Backend API Server
  api:
    image: python:3.9-slim
    container_name: api_server
    build:
      context: ./backend
      dockerfile: Dockerfile
    working_dir: /app
    ports:
      - "5000:5000"
    volumes:
      - ./backend:/app
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://dbuser:dbpass@postgres:5432/appdb
      - REDIS_URL=redis://cache:6379/0
    networks:
      - backend
    depends_on:
      - postgres
      - cache
    command: gunicorn --bind 0.0.0.0:5000 wsgi:app
    restart: unless-stopped

  # PostgreSQL Database
  postgres:
    image: postgres:13-alpine
    container_name: postgres_db
    environment:
      - POSTGRES_USER=dbuser
      - POSTGRES_PASSWORD=dbpass
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dbuser -d appdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  cache:
    image: redis:7-alpine
    container_name: redis_cache
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    networks:
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
```

---

## MODULE 12: ENVIRONMENT VARIABLES AND SECRETS

### 12.1 Environment Variables

```bash
# Pass single variable
docker run -e DB_HOST=localhost myapp

# Pass multiple variables
docker run -e DB_HOST=localhost -e DB_PORT=5432 -e DB_NAME=mydb myapp

# Load from file
docker run --env-file .env.local myapp

# View container environment
docker exec container_id env
```

**.env.local file:**
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mydb
DB_USER=dbuser
DB_PASSWORD=secretpass
REDIS_URL=redis://localhost:6379
LOG_LEVEL=info
```

**Docker Compose with Environment:**
```yaml
version: '3.9'

services:
  app:
    image: myapp:v1
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=mydb
    env_file:
      - .env
      - .env.local

  db:
    image: postgres:13
    env_file:
      - .env.db

services:
  app:
    environment:
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}
    # Uses variables from .env file or host environment
```

### 12.2 Docker Secrets (Swarm/Kubernetes)

```bash
# Create secret (Docker Swarm)
echo "my-secret-password" | docker secret create db_password -

# List secrets
docker secret ls

# Use secret in service
docker service create \
  --secret db_password \
  --name myapp \
  myapp:v1

# Access secret from application
cat /run/secrets/db_password
```

**Docker Compose with Secrets:**
```yaml
version: '3.9'

services:
  db:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password

  app:
    image: myapp:v1
    secrets:
      - db_password
      - api_key
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```

### 12.3 Best Practices

```bash
# ❌ DON'T: Hardcode secrets
ENV DB_PASSWORD=mysecretpass

# ❌ DON'T: Pass secrets as arguments
docker run myapp -p mysecretpass

# ✓ DO: Use secret files
docker run --secret db_password myapp

# ✓ DO: Use environment files
docker run --env-file .env.prod myapp

# ✓ DO: Use a secrets management system
# - HashiCorp Vault
# - AWS Secrets Manager
# - Google Cloud Secret Manager
# - Azure Key Vault
```

---

## MODULE 13: DOCKER LOGGING

### 13.1 Log Drivers

```bash
# Default: json-file driver
docker run -d nginx

# View logs
docker logs container_id
docker logs -f container_id              # Follow logs
docker logs --tail 100 container_id      # Last 100 lines
docker logs --since 2023-01-01T00:00:00Z # Since timestamp
docker logs -t container_id              # With timestamps
```

**Different Log Drivers:**

```bash
# JSON File (default)
docker run --log-driver json-file nginx

# Syslog
docker run --log-driver syslog \
  --log-opt syslog-address=udp://127.0.0.1:514 \
  --log-opt tag=myapp \
  myapp

# Journald (systemd)
docker run --log-driver journald myapp

# Fluentd
docker run --log-driver fluentd \
  --log-opt fluentd-address=localhost:24224 \
  --log-opt tag=docker.{{.Name}} \
  myapp

# AWS CloudWatch
docker run --log-driver awslogs \
  --log-opt awslogs-group=/ecs/myapp \
  --log-opt awslogs-region=us-east-1 \
  --log-opt awslogs-stream-prefix=ecs \
  myapp

# Splunk
docker run --log-driver splunk \
  --log-opt splunk-token=<splunk-token> \
  --log-opt splunk-url=https://splunk.example.com:8088 \
  myapp

# Datadog
docker run --log-driver datadog \
  --log-opt dd_service=myapp \
  --log-opt dd_source=docker \
  --log-opt dd_tags=env:prod \
  myapp
```

### 13.2 Log Rotation

```bash
# Configure log rotation
docker run --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  myapp

# max-size: 10m per log file
# max-file: Keep 3 files (oldest deleted)
```

**daemon.json configuration:**
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "labels": "service=myapp"
  }
}
```

### 13.3 Centralized Logging Stack

```yaml
version: '3.9'

services:
  # Elasticsearch - Log storage
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.14.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    ports:
      - "9200:9200"
    networks:
      - logging

  # Kibana - Log visualization
  kibana:
    image: docker.elastic.co/kibana/kibana:7.14.0
    container_name: kibana
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - logging

  # Filebeat - Log shipper
  filebeat:
    image: docker.elastic.co/beats/filebeat:7.14.0
    container_name: filebeat
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - logging
    depends_on:
      - elasticsearch

  # Application
  myapp:
    image: myapp:v1
    container_name: app
    ports:
      - "8000:8000"
    networks:
      - logging

networks:
  logging:

volumes:
  elasticsearch_data:
```

---

## MODULE 14: DOCKER MONITORING

### 14.1 Built-in Monitoring Commands

```bash
# View resource usage
docker stats
# Shows: CPU%, Memory usage, Network I/O, Block I/O

# Check specific container
docker stats container_id
docker stats --no-stream                # Single snapshot

# View running processes
docker top container_id

# Detailed container info
docker inspect container_id             # JSON output
docker inspect -f '{{.State.Status}}' container_id  # Format output

# View events
docker events                           # Real-time events
docker events --filter "type=container"
docker events --since 2023-01-01T00:00:00Z
```

### 14.2 Monitoring Stack with Prometheus + Grafana

```yaml
version: '3.9'

services:
  # Prometheus - Metrics collection
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring

  # cAdvisor - Container metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    ports:
      - "8080:8080"
    networks:
      - monitoring

  # Grafana - Visualization
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_SECURITY_ADMIN_USER=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    depends_on:
      - prometheus
    networks:
      - monitoring

  # Node Exporter - Host metrics
  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - monitoring

networks:
  monitoring:

volumes:
  prometheus_data:
  grafana_data:
```

**prometheus.yml:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'node'
    static_configs:
      - targets: ['node_exporter:9100']
```

---

## MODULE 15: DOCKER SECURITY

### 15.1 Namespaces (Isolation)

Namespaces provide process-level isolation:

```bash
# PID Namespace - Process isolation
docker run --pid=container:other_container myapp  # Share PID namespace
docker run --pid=host myapp                       # Use host PID namespace

# Network Namespace - Network isolation
docker run --network=bridge myapp     # Default - isolated network
docker run --network=host myapp       # Share host network

# IPC Namespace - Inter-process communication
docker run --ipc=private myapp        # Isolated IPC
docker run --ipc=host myapp           # Share host IPC

# UTS Namespace - Hostname/domain isolation
docker run --hostname myhost myapp

# Mount Namespace - Filesystem isolation
docker run -v /host:/container myapp  # Mount host directory

# User Namespace - User mapping
docker run --userns=host myapp        # Map to host users
```

### 15.2 Cgroups (Resource Limits)

```bash
# Memory limit
docker run --memory=512m myapp        # Max 512 MB
docker run --memory-swap=1g myapp     # Max 1 GB (including swap)
docker run --memory-reservation=256m myapp  # Soft limit

# CPU limits
docker run --cpus=2 myapp             # Max 2 CPU cores
docker run --cpus=0.5 myapp           # Max 50% of 1 core
docker run --cpu-shares=512 myapp     # Relative weight

# Disk I/O limits
docker run --device-read-bps /dev/sda:1mb myapp   # Read limit
docker run --device-write-bps /dev/sda:1mb myapp  # Write limit
```

### 15.3 Capabilities (Linux Security)

```bash
# Drop dangerous capabilities
docker run --cap-drop=ALL \
  --cap-add=NET_BIND_SERVICE \
  --cap-add=CHOWN \
  myapp

# Run as read-only
docker run --read-only myapp

# Tmpfs for /tmp and /run
docker run --tmpfs /tmp --tmpfs /run myapp
```

**Dockerfile Security:**
```dockerfile
# ✓ Good practice
FROM alpine:3.14

# Run as non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

USER appuser

# Don't store secrets
ENV API_KEY="will_be_injected_at_runtime"

# Read-only filesystem
RUN chmod 555 /

# Security labels
LABEL security.privileged=false

# Capabilities
# RUN setcap -r /usr/bin/ping
```

### 15.4 Image Security

**Vulnerability Scanning with Trivy:**
```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan image
trivy image nginx:latest

# Output includes:
# - CVE details
# - Severity levels
# - Remediation recommendations

# Scan with JSON output
trivy image -f json nginx:latest > results.json
```

**Image Signing with Notary:**
```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Sign and push image
docker push myregistry/myapp:v1
# Prompts for signing key

# Verify signature
docker pull myregistry/myapp:v1
# Checks signature before pulling
```

### 15.5 Secure Dockerfile Template

```dockerfile
# Multi-stage: smaller final image
FROM node:16-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --only=production

# Runtime stage
FROM node:16-alpine

# Security: Run as non-root
RUN addgroup -g 1001 nodejs && \
    adduser -D -u 1001 -G nodejs appuser

WORKDIR /app

# Copy dependencies
COPY --from=builder --chown=appuser:nodejs /build/node_modules ./node_modules

# Copy app code
COPY --chown=appuser:nodejs . .

# Switch to non-root
USER appuser

# No secrets in image
ENV NODE_ENV=production

# Don't run as PID 1
RUN npm install -g dumb-init

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error()})"

# Expose port
EXPOSE 3000

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
```

---

## MODULE 16: DOCKER SWARM

### 16.1 Swarm Architecture

```
┌─────────────────────────────────────────────┐
│          Docker Swarm Cluster               │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────┐                  │
│  │  Manager Node (1)    │ ← Leader         │
│  │  ├─ Raft Store      │                  │
│  │  ├─ Orchestrator    │                  │
│  │  └─ Task Scheduler  │                  │
│  └──────────────────────┘                  │
│                                             │
│  ┌──────────────────────┐                  │
│  │  Manager Node (2)    │                  │
│  └──────────────────────┘                  │
│                                             │
│  ┌──────────────────────┐                  │
│  │  Manager Node (3)    │                  │
│  └──────────────────────┘                  │
│                                             │
│  ┌─────────┬──────────┬──────────────┐    │
│  │ Worker  │  Worker  │    Worker    │    │
│  │ Node 1  │  Node 2  │    Node 3    │    │
│  └─────────┴──────────┴──────────────┘    │
│                                             │
│  Services → Tasks → Containers             │
│                                             │
└─────────────────────────────────────────────┘
```

### 16.2 Swarm Commands

```bash
# Initialize swarm (current node becomes manager)
docker swarm init

# Get join token for workers
docker swarm join-token worker

# Add worker to swarm
docker swarm join --token SWMTKN-1-xxx 192.168.1.100:2377

# List nodes
docker node ls

# List services
docker service ls

# Create service (replicate across workers)
docker service create --name web --replicas 3 -p 80:80 nginx

# Scale service
docker service scale web=5

# Update service
docker service update --image nginx:latest web

# View service details
docker service inspect web
docker service logs web              # Service logs

# Remove service
docker service rm web

# View task distribution
docker service ps web               # Shows tasks across nodes
```

### 16.3 Real-World Swarm Stack

```yaml
version: '3.9'

services:
  # Load balancer
  lb:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    deploy:
      mode: global                  # One instance per node
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    networks:
      - frontend

  # Web service
  web:
    image: myapp:v1
    deploy:
      replicas: 3                   # Run 3 instances
      labels:
        - "service=web"
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 1              # Update 1 at a time
        delay: 10s                  # Wait 10s between updates
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    environment:
      - DB_HOST=postgres
      - REDIS_HOST=cache
    networks:
      - frontend
      - backend
    depends_on:
      - postgres
      - cache

  # PostgreSQL
  postgres:
    image: postgres:13
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]  # Run on manager
      restart_policy:
        condition: on-failure
      resources:
        limits:
          cpus: '1'
          memory: 1G
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend

  # Cache
  cache:
    image: redis:7-alpine
    deploy:
      replicas: 1
      placement:
        constraints: [node.role == manager]  # Run on manager
      restart_policy:
        condition: on-failure
    volumes:
      - redis_data:/data
    networks:
      - backend

networks:
  frontend:
  backend:

volumes:
  postgres_data:
  redis_data:
```

---

## MODULE 17: ADVANCED DOCKER

### 17.1 Multi-Stage Builds

**Problem:** Final image includes build dependencies (large size)

**Solution:** Multi-stage builds

```dockerfile
# Stage 1: Build
FROM golang:1.17 AS builder
WORKDIR /app
COPY . .
RUN go build -o app .
# Size: 800MB (includes Go compiler, git, etc.)

# Stage 2: Runtime
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/app .
CMD ["./app"]
# Size: 50MB (only binary, no build tools)
```

**Java Example:**
```dockerfile
# Stage 1: Build
FROM maven:3.8-openjdk-11 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests
# Result: app.jar

# Stage 2: Runtime
FROM openjdk:11-jre-slim
WORKDIR /app
COPY --from=builder /app/target/app.jar .
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

**Node.js Example:**
```dockerfile
# Stage 1: Build dependencies
FROM node:16 AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: Build application
FROM node:16 AS builder
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Runtime
FROM node:16-alpine
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./
ENV NODE_ENV=production
EXPOSE 3000
CMD ["npm", "start"]
```

### 17.2 Health Checks

```dockerfile
# Basic health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# HTTP endpoint
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Database connectivity
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=5 \
    CMD pg_isready -U postgres -d mydb || exit 1

# Custom script
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD /app/healthcheck.sh || exit 1

# Multiple checks
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health && \
        curl -f http://localhost:8080/ready || exit 1
```

**healthcheck.sh:**
```bash
#!/bin/bash
set -e

# Check API
curl -f http://localhost:3000/health || exit 1

# Check database
pg_isready -h db -U user -d mydb || exit 1

# Check cache
redis-cli -h cache ping || exit 1

exit 0
```

### 17.3 Resource Limits

```bash
# Memory
docker run --memory=512m myapp            # Hard limit: 512MB
docker run --memory=512m --memory-swap=1g myapp  # Swap allowed
docker run --memory-reservation=256m myapp       # Soft limit

# CPU
docker run --cpus=2 myapp                # Max 2 cores
docker run --cpus=0.5 myapp              # Max 0.5 cores (50%)
docker run --cpu-shares=512 myapp        # Relative weight (default: 1024)

# I/O
docker run --device-read-bps /dev/sda:1mb myapp
docker run --device-write-bps /dev/sda:1mb myapp

# Docker Compose
version: '3.9'
services:
  app:
    image: myapp:v1
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

### 17.4 Restart Policies

```bash
# no - Don't automatically restart
docker run --restart=no myapp

# always - Always restart if it stops
docker run --restart=always myapp

# unless-stopped - Always restart unless manually stopped
docker run --restart=unless-stopped myapp

# on-failure - Restart only on non-zero exit
docker run --restart=on-failure myapp
docker run --restart=on-failure:5 myapp  # Max 5 restarts

# Restart delay
docker run --restart=on-failure:3 \
  --restart-max-delay=30s myapp
```

### 17.5 Distroless Images

```dockerfile
# ❌ Large image with OS utilities
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3
COPY app.py /
CMD ["python3", "app.py"]
# Size: 300+ MB

# ✓ Distroless image - minimal runtime only
FROM python:3.9-slim
COPY app.py /
CMD ["python3", "app.py"]
# Size: 100-200 MB

# ✓ Distroless with multi-stage
FROM python:3.9 as builder
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM gcr.io/distroless/python3.9:nonroot
COPY --from=builder /root/.local /root/.local
COPY app.py /
ENV PATH=/root/.local/bin:$PATH
CMD ["/app.py"]
# Size: 50 MB
```

### 17.6 BuildKit (Faster Builds)

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in daemon.json
echo '{"features": {"buildkit": true}}' | tee /etc/docker/daemon.json

# Build with BuildKit
docker build -t myapp:v1 .

# View build progress
docker build --progress=plain -t myapp:v1 .

# Inline cache
docker build --cache-from registry/myapp:latest -t myapp:v1 .
```

---

## MODULE 18: DOCKER TROUBLESHOOTING

### 18.1 Common Issues and Solutions

**Container CrashLoop**

```bash
# 1. Check logs
docker logs container_id
docker logs -f container_id              # Follow

# 2. Restart policy keeps restarting
docker run --restart=on-failure:5 myapp

# 3. Application error
# Look at logs for specific errors (e.g., "port already in use")

# 4. Insufficient memory
docker run --memory=1g myapp
docker stats container_id

# Solution example:
# Error: Application exiting immediately
docker logs myapp
# Output: "Error: Cannot connect to database"
# Fix: Check database connectivity, ensure env vars are set
docker run -e DB_HOST=postgres -e DB_USER=user myapp
```

**Port Conflicts**

```bash
# 1. Find container using port
lsof -i :8080
netstat -tuln | grep 8080
docker ps --format "{{.ID}} {{.Ports}}"

# 2. Stop conflicting container
docker stop container_id

# 3. Use different port
docker run -p 8081:80 nginx

# 4. Check port mappings
docker port container_id
```

**Permission Issues**

```bash
# 1. Permission denied on volume
# Fix: Ensure volume ownership
docker exec container_id chown -R appuser:appuser /data

# 2. Cannot write to mounted volume
# Host file: rwx------
# Fix: Change permissions
chmod 777 /path/to/host/directory

# 3. Non-root user in Dockerfile
FROM ubuntu:20.04
RUN groupadd -g 1001 appuser && \
    useradd -m -u 1001 -g appuser appuser
USER appuser
```

**DNS Failures**

```bash
# 1. Container cannot resolve hostname
docker exec container_id nslookup other_container
# Should resolve when on same network

# 2. Fix: Connect to network
docker network connect mynet container_id

# 3. Check /etc/resolv.conf
docker exec container_id cat /etc/resolv.conf
# Should have: nameserver 127.0.0.11

# 4. Debug DNS
docker exec container_id nslookup 8.8.8.8
docker exec container_id ping google.com
```

**Volume Mount Problems**

```bash
# 1. Volume not mounting
docker run -v /nonexistent:/data myapp
# Creates empty volume instead of binding

# 2. Wrong mount point
docker inspect container_id | grep Mounts

# 3. Fix with absolute path
docker run -v $(pwd)/data:/data myapp

# 4. Check volume contents
docker volume inspect myvol
docker run --rm -v myvol:/data ubuntu ls /data
```

### 18.2 Troubleshooting Commands

```bash
# Detailed container inspection
docker inspect container_id | jq .           # JSON pretty print
docker inspect -f '{{.State.Status}}' container_id
docker inspect -f '{{.NetworkSettings.IPAddress}}' container_id

# View container events
docker events                                # All events
docker events --filter "type=container"     # Container events
docker events --filter "container=myapp"    # Specific container

# Real-time monitoring
docker stats                                # All containers
docker stats myapp                          # Specific container

# Execute and debug
docker exec -it container_id /bin/bash      # Interactive shell
docker exec container_id ps aux             # View processes

# Copy files for analysis
docker cp container_id:/var/log/app.log .   # Extract logs
docker cp app.log container_id:/tmp/        # Add files
```

### 18.3 Real-World Troubleshooting Scenarios

**Scenario 1: Application Not Starting**

```bash
# 1. Check logs
docker logs myapp
# Output: "Database connection refused"

# 2. Verify service is running
docker ps | grep database
# Not running!

# 3. Start dependent service first
docker run -d --name database postgres:13
docker run -d --link database myapp

# 4. Or use compose
docker compose up -d

# 5. Verify connectivity
docker exec myapp psql -h database -U user -d mydb
```

**Scenario 2: High Memory Usage**

```bash
# 1. Monitor memory
docker stats
# myapp using 1.5GB out of 2GB limit

# 2. Find memory leak
docker exec myapp top
# Check which processes consuming memory

# 3. Look at logs for errors
docker logs myapp | grep -i "memory\|error"

# 4. Restart container
docker restart myapp

# 5. Increase limit or fix application
docker run --memory=4g myapp
# OR fix memory leak in code
```

**Scenario 3: Slow Performance**

```bash
# 1. Check I/O performance
docker stats
# Check "IO Read/Write" columns

# 2. Check CPU usage
docker stats myapp
# CPUPercent column

# 3. Increase resources
docker run --cpus=2 --memory=2g myapp

# 4. Check if network is bottleneck
docker exec myapp iperf -c other_host

# 5. Optimize application
# - Use caching
# - Reduce database queries
# - Optimize images/assets
```

---

# TERRAFORM CONFIGURATION EXAMPLES

## TERRAFORM BASICS

Terraform is Infrastructure as Code (IaC) tool for provisioning Docker infrastructure, cloud resources, etc.

### 18.4 Basic Terraform Setup

**main.tf:**
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create Docker network
resource "docker_network" "main" {
  name   = "myapp-network"
  driver = "bridge"
}

# Create Docker volume
resource "docker_volume" "postgres_data" {
  name = "postgres_data"
}

# Run PostgreSQL container
resource "docker_container" "postgres" {
  name  = "postgres"
  image = docker_image.postgres.image_id
  
  # Network settings
  networks_advanced {
    name = docker_network.main.name
    ipv4_address = "172.20.0.2"
  }
  
  # Environment variables
  env = [
    "POSTGRES_DB=myapp",
    "POSTGRES_USER=dbuser",
    "POSTGRES_PASSWORD=${random_password.db_password.result}"
  ]
  
  # Volume mount
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }
  
  # Port mapping
  ports {
    internal = 5432
    external = 5432
  }
  
  # Health check
  healthchecks {
    test = [
      "CMD-SHELL",
      "pg_isready -U dbuser -d myapp"
    ]
    interval     = "10s"
    timeout      = "5s"
    start_period = "40s"
    retries      = 5
  }
  
  restart_policy {
    condition = "unless-stopped"
  }
}

# Run application container
resource "docker_container" "app" {
  name  = "myapp"
  image = docker_image.myapp.image_id
  
  # Network settings
  networks_advanced {
    name = docker_network.main.name
  }
  
  # Environment variables
  env = [
    "DATABASE_URL=postgresql://dbuser:${random_password.db_password.result}@postgres:5432/myapp",
    "NODE_ENV=production"
  ]
  
  # Port mapping
  ports {
    internal = 3000
    external = 3000
  }
  
  # Resource limits
  memory = 512
  
  # Dependencies
  depends_on = [docker_container.postgres]
  
  restart_policy {
    condition = "unless-stopped"
  }
}

# Pull Docker images
resource "docker_image" "postgres" {
  name         = "postgres:13"
  keep_locally = false
  
  pulls {
    image = "postgres:13"
  }
}

resource "docker_image" "myapp" {
  name         = "myapp:v1"
  keep_locally = false
  
  build {
    context      = "${path.module}/app"
    dockerfile   = "Dockerfile"
    tag          = ["myapp:v1"]
  }
}

# Generate random password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Output values
output "app_url" {
  value = "http://localhost:3000"
}

output "db_connection_string" {
  value     = "postgresql://dbuser:****@localhost:5432/myapp"
  sensitive = true
}
```

**variables.tf:**
```hcl
variable "app_name" {
  description = "Application name"
  type        = string
  default     = "myapp"
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "v1"
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "13"
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 3000
}

variable "app_memory" {
  description = "Application memory in MB"
  type        = number
  default     = 512
}
```

**outputs.tf:**
```hcl
output "application_container_id" {
  description = "Application container ID"
  value       = docker_container.app.id
}

output "application_url" {
  description = "Application URL"
  value       = "http://localhost:${docker_container.app.ports[0].external}"
}

output "database_container_id" {
  description = "Database container ID"
  value       = docker_container.postgres.id
}

output "database_host" {
  description = "Database host"
  value       = "postgres"
}

output "database_port" {
  description = "Database port"
  value       = docker_container.postgres.ports[0].external
}

output "network_id" {
  description = "Docker network ID"
  value       = docker_network.main.id
}

output "network_name" {
  description = "Docker network name"
  value       = docker_network.main.name
}
```

### 18.5 Complex Terraform Example: Multi-Container Stack

**main.tf (Advanced):**
```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "aws" {
  region = var.aws_region
}

# ===== NETWORKS =====
resource "docker_network" "frontend" {
  name   = "${var.app_name}-frontend"
  driver = "bridge"
}

resource "docker_network" "backend" {
  name   = "${var.app_name}-backend"
  driver = "bridge"
}

# ===== VOLUMES =====
resource "docker_volume" "postgres_data" {
  name = "${var.app_name}-postgres-data"
}

resource "docker_volume" "redis_data" {
  name = "${var.app_name}-redis-data"
}

# ===== SECURITY =====
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "random_password" "redis_password" {
  length  = 32
  special = true
}

# ===== DOCKER IMAGES =====
resource "docker_image" "postgres" {
  name         = "postgres:${var.postgres_version}"
  keep_locally = false

  pulls {
    image = "postgres:${var.postgres_version}"
  }
}

resource "docker_image" "redis" {
  name         = "redis:${var.redis_version}"
  keep_locally = false

  pulls {
    image = "redis:${var.redis_version}"
  }
}

resource "docker_image" "app" {
  name         = "${var.docker_registry}/${var.app_name}:${var.app_version}"
  keep_locally = var.keep_images_locally

  build {
    context      = var.app_build_context
    dockerfile   = var.app_dockerfile
    tag          = ["${var.docker_registry}/${var.app_name}:${var.app_version}"]
    label        = {
      "app"     = var.app_name
      "version" = var.app_version
      "env"     = var.environment
    }
    build_args = {
      BUILD_VERSION = var.app_version
      NODE_ENV      = var.environment
    }
  }
}

resource "docker_image" "nginx" {
  name         = "nginx:${var.nginx_version}"
  keep_locally = false

  pulls {
    image = "nginx:${var.nginx_version}"
  }
}

# ===== CONTAINERS =====

# PostgreSQL Database
resource "docker_container" "postgres" {
  name              = "${var.app_name}-postgres"
  image             = docker_image.postgres.image_id
  restart_policy    = "unless-stopped"
  must_run          = true
  publish_all_ports = false

  # Network settings
  networks_advanced {
    name         = docker_network.backend.name
    ipv4_address = var.postgres_ip
  }

  # Environment variables
  env = [
    "POSTGRES_DB=${var.db_name}",
    "POSTGRES_USER=${var.db_user}",
    "POSTGRES_PASSWORD=${random_password.db_password.result}",
    "POSTGRES_INITDB_ARGS=-c max_connections=100"
  ]

  # Volume mount
  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  # Port mapping (exposed only on localhost for security)
  ports {
    internal = 5432
    external = var.postgres_port
    ip       = "127.0.0.1"
  }

  # Resource limits
  memory = var.postgres_memory_limit

  # Health check
  healthchecks {
    test = [
      "CMD-SHELL",
      "pg_isready -U ${var.db_user} -d ${var.db_name}"
    ]
    interval     = "10s"
    timeout      = "5s"
    start_period = "40s"
    retries      = 5
  }

  # Logging
  log_driver = "json-file"
  log_opts = {
    "max-size" = "10m"
    "max-file" = "3"
  }

  labels {
    label "service" = "database"
    label "app"     = var.app_name
  }
}

# Redis Cache
resource "docker_container" "redis" {
  name              = "${var.app_name}-redis"
  image             = docker_image.redis.image_id
  restart_policy    = "unless-stopped"
  must_run          = true
  publish_all_ports = false

  # Network settings
  networks_advanced {
    name         = docker_network.backend.name
    ipv4_address = var.redis_ip
  }

  # Volume mount
  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  # Port mapping
  ports {
    internal = 6379
    external = var.redis_port
    ip       = "127.0.0.1"
  }

  # Resource limits
  memory = var.redis_memory_limit

  # Command with password
  command = [
    "redis-server",
    "--requirepass", random_password.redis_password.result,
    "--appendonly", "yes"
  ]

  # Health check
  healthchecks {
    test = ["CMD", "redis-cli", "ping"]
    interval     = "10s"
    timeout      = "3s"
    start_period = "5s"
    retries      = 3
  }

  # Logging
  log_driver = "json-file"
  log_opts = {
    "max-size" = "10m"
    "max-file" = "3"
  }

  labels {
    label "service" = "cache"
    label "app"     = var.app_name
  }
}

# Application Container
resource "docker_container" "app" {
  name              = "${var.app_name}-app"
  image             = docker_image.app.image_id
  restart_policy    = "unless-stopped"
  must_run          = true
  publish_all_ports = false

  # Network settings
  networks_advanced {
    name = docker_network.backend.name
  }
  networks_advanced {
    name = docker_network.frontend.name
  }

  # Environment variables
  env = concat(
    [
      "NODE_ENV=${var.environment}",
      "DATABASE_URL=postgresql://${var.db_user}:${random_password.db_password.result}@${var.app_name}-postgres:5432/${var.db_name}",
      "REDIS_URL=redis://:${random_password.redis_password.result}@${var.app_name}-redis:6379/0",
      "APP_VERSION=${var.app_version}",
      "LOG_LEVEL=${var.log_level}"
    ],
    var.additional_env_vars
  )

  # Port mapping
  ports {
    internal = var.app_internal_port
    external = var.app_external_port
  }

  # Resource limits
  memory              = var.app_memory_limit
  memory_swap         = var.app_memory_swap
  cpu_shares          = var.app_cpu_shares
  cpuset_cpus         = var.app_cpuset_cpus

  # Security options
  privileged = false
  cap_drop   = ["ALL"]
  cap_add    = ["NET_BIND_SERVICE"]

  # Read-only filesystem
  read_only = var.read_only_filesystem

  # Temporary filesystems
  tmpfs = {
    "/tmp"   = "size=512m"
    "/run"   = "size=512m"
  }

  # Logging
  log_driver = "json-file"
  log_opts = {
    "max-size" = "10m"
    "max-file" = "3"
    "labels"   = "service=app,env=${var.environment}"
  }

  # Health check
  healthchecks {
    test = [
      "CMD-SHELL",
      "curl -f http://localhost:${var.app_internal_port}/health || exit 1"
    ]
    interval     = "30s"
    timeout      = "10s"
    start_period = "40s"
    retries      = 3
  }

  # Mounts
  volumes {
    host_path      = abspath("${path.module}/logs")
    container_path = "/app/logs"
    read_only      = false
  }

  # Dependencies
  depends_on = [
    docker_container.postgres,
    docker_container.redis
  ]

  labels {
    label "service" = "application"
    label "app"     = var.app_name
    label "env"     = var.environment
  }
}

# Nginx Load Balancer
resource "docker_container" "nginx" {
  name              = "${var.app_name}-nginx"
  image             = docker_image.nginx.image_id
  restart_policy    = "unless-stopped"
  must_run          = true
  publish_all_ports = false

  # Network settings
  networks_advanced {
    name = docker_network.frontend.name
  }

  # Port mapping
  ports {
    internal = 80
    external = 80
  }
  ports {
    internal = 443
    external = 443
  }

  # Volume mounts
  volumes {
    host_path      = abspath("${path.module}/nginx.conf")
    container_path = "/etc/nginx/nginx.conf"
    read_only      = true
  }
  volumes {
    host_path      = abspath("${path.module}/ssl")
    container_path = "/etc/nginx/ssl"
    read_only      = true
  }

  # Resource limits
  memory = var.nginx_memory_limit

  # Health check
  healthchecks {
    test = ["CMD", "curl", "-f", "http://localhost/health"]
    interval     = "30s"
    timeout      = "3s"
    start_period = "10s"
    retries      = 3
  }

  # Logging
  log_driver = "json-file"
  log_opts = {
    "max-size" = "10m"
    "max-file" = "3"
  }

  # Dependencies
  depends_on = [docker_container.app]

  labels {
    label "service" = "load-balancer"
    label "app"     = var.app_name
  }
}

# ===== AWS RESOURCES (OPTIONAL) =====
# ECR Repository for storing Docker images
resource "aws_ecr_repository" "app" {
  count                   = var.create_aws_resources ? 1 : 0
  name                    = var.app_name
  image_tag_mutability    = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  count          = var.create_aws_resources ? 1 : 0
  repository     = aws_ecr_repository.app[0].name
  policy         = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

**variables.tf (Advanced):**
```hcl
# General
variable "app_name" {
  description = "Application name"
  type        = string
  validation {
    condition     = length(var.app_name) > 0 && length(var.app_name) < 32
    error_message = "App name must be between 1 and 31 characters."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "v1.0.0"
}

# Docker Build
variable "docker_registry" {
  description = "Docker registry URL"
  type        = string
  default     = "localhost"
}

variable "app_build_context" {
  description = "Docker build context path"
  type        = string
  default     = "./app"
}

variable "app_dockerfile" {
  description = "Dockerfile path"
  type        = string
  default     = "Dockerfile"
}

variable "keep_images_locally" {
  description = "Keep Docker images locally"
  type        = bool
  default     = true
}

# Database
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "13"
}

variable "postgres_port" {
  description = "PostgreSQL port (host)"
  type        = number
  default     = 5432
  validation {
    condition     = var.postgres_port > 0 && var.postgres_port < 65536
    error_message = "Port must be between 1 and 65535."
  }
}

variable "postgres_ip" {
  description = "PostgreSQL container IP"
  type        = string
  default     = "172.20.0.2"
}

variable "postgres_memory_limit" {
  description = "PostgreSQL memory limit in MB"
  type        = number
  default     = 512
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "dbuser"
  sensitive   = true
}

# Redis
variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7-alpine"
}

variable "redis_port" {
  description = "Redis port (host)"
  type        = number
  default     = 6379
}

variable "redis_ip" {
  description = "Redis container IP"
  type        = string
  default     = "172.20.0.3"
}

variable "redis_memory_limit" {
  description = "Redis memory limit in MB"
  type        = number
  default     = 256
}

# Application
variable "app_internal_port" {
  description = "Application internal port"
  type        = number
  default     = 3000
}

variable "app_external_port" {
  description = "Application external port"
  type        = number
  default     = 3000
}

variable "app_memory_limit" {
  description = "Application memory limit in MB"
  type        = number
  default     = 512
}

variable "app_memory_swap" {
  description = "Application memory swap in MB"
  type        = number
  default     = 1024
}

variable "app_cpu_shares" {
  description = "Application CPU shares"
  type        = number
  default     = 1024
}

variable "app_cpuset_cpus" {
  description = "Application CPUs (e.g., '0,1')"
  type        = string
  default     = ""
}

variable "read_only_filesystem" {
  description = "Run container with read-only filesystem"
  type        = bool
  default     = false
}

variable "additional_env_vars" {
  description = "Additional environment variables"
  type        = list(string)
  default     = []
}

# Nginx
variable "nginx_version" {
  description = "Nginx version"
  type        = string
  default     = "alpine"
}

variable "nginx_memory_limit" {
  description = "Nginx memory limit in MB"
  type        = number
  default     = 128
}

# Logging
variable "log_level" {
  description = "Logging level"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be debug, info, warn, or error."
  }
}

# AWS (Optional)
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "create_aws_resources" {
  description = "Create AWS ECR repository"
  type        = bool
  default     = false
}
```

**terraform.tfvars (Production Example):**
```hcl
app_name      = "myapp"
environment   = "prod"
app_version   = "v2.0.0"
docker_registry = "123456789.dkr.ecr.us-east-1.amazonaws.com"

# Database
postgres_version    = "13-alpine"
postgres_port       = 5432
postgres_memory_limit = 1024
db_name             = "production_db"

# Redis
redis_version       = "7-alpine"
redis_memory_limit  = 512

# Application
app_internal_port   = 3000
app_external_port   = 3000
app_memory_limit    = 1024
app_memory_swap     = 2048
app_cpu_shares      = 2048

# Nginx
nginx_memory_limit  = 256

# Logging
log_level           = "warn"

# AWS
create_aws_resources = true

# Additional env vars
additional_env_vars = [
  "SENTRY_DSN=https://xxx@sentry.io/123456",
  "ENABLE_METRICS=true",
  "ENABLE_TRACING=true"
]
```

### 18.6 Terraform Workflow

```bash
# 1. Format and validate
terraform fmt                          # Format HCL files
terraform validate                     # Validate syntax

# 2. Initialize (first time)
terraform init

# 3. Plan changes
terraform plan                         # Review changes
terraform plan -out=tfplan            # Save plan to file

# 4. Apply changes
terraform apply                        # Interactive approval
terraform apply tfplan                # Apply saved plan
terraform apply -auto-approve         # Skip confirmation (CI/CD)

# 5. Inspect state
terraform show                         # Current state
terraform state list                  # Resources in state
terraform state show docker_container.app  # Specific resource

# 6. Outputs
terraform output                       # All outputs
terraform output app_url              # Specific output

# 7. Destroy
terraform destroy                      # Remove all resources
terraform destroy -auto-approve       # Skip confirmation

# 8. Debugging
terraform console                      # Interactive console
terraform graph                        # Dependency graph
TF_LOG=DEBUG terraform apply          # Debug logging
```

### 18.7 State Management

```bash
# Local state (default)
# State stored in terraform.tfstate

# Remote state (recommended for teams)
# backend.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "docker/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Initialize remote backend
terraform init

# Lock state during operations
# DynamoDB table prevents concurrent modifications

# Backup and recovery
terraform state pull > backup.tfstate
terraform state push backup.tfstate
```

---

## INTERVIEW PREPARATION

### Most Important Docker Concepts

1. **Docker Architecture**: Client-Server, Daemon, REST API, Registry
2. **Image vs Container**: Templates vs instances
3. **Layers**: Understanding image layers and caching
4. **Networking**: Bridge, Host, None, Overlay networks
5. **Storage**: Volumes vs Bind Mounts vs tmpfs
6. **Dockerfile**: Best practices, multi-stage builds
7. **Docker Compose**: Multi-container applications
8. **Security**: Namespaces, Cgroups, Capabilities, Non-root users
9. **Troubleshooting**: Logs, exec, inspect, stats
10. **Kubernetes Integration**: Container runtimes, Pod images, ConfigMaps, Secrets

### Common Interview Questions & Answers

**Q: What's the difference between a container and a VM?**
A: Containers are lightweight OS-level virtualization sharing the host kernel, while VMs are full OS instances with hypervisor-level isolation. Containers are faster to start, use fewer resources, and easier to deploy.

**Q: Explain Docker image layers and caching**
A: Each Dockerfile instruction creates a layer. Docker caches layers, so if nothing changes, it reuses the cache (fast builds). If a layer changes, all subsequent layers rebuild. Order instructions from least-changing to most-changing for optimal caching.

**Q: What's the difference between ENTRYPOINT and CMD?**
A: CMD sets the default command but can be overridden. ENTRYPOINT sets the primary command that always runs; CMD becomes arguments to ENTRYPOINT.

**Q: How do containers communicate?**
A: Containers on the same bridge network can communicate using service names as hostnames. Docker has embedded DNS resolution. Use custom networks for better DNS support.

**Q: Explain Docker security best practices**
A: Run as non-root user, drop unnecessary capabilities, use read-only filesystems, scan images for vulnerabilities, use secrets management instead of environment variables, implement resource limits.

---

## CONCLUSION

This comprehensive guide covers Docker fundamentals through advanced topics with practical examples. Combined with Terraform infrastructure-as-code, you can automate container deployment and management at scale.

**Key Takeaways:**
- Docker solves the "works on my machine" problem
- Images and containers are different (template vs instance)
- Use networks, volumes, and docker-compose for complex applications
- Security requires multiple layers (namespaces, capabilities, non-root users)
- Monitoring and logging are critical for production
- Terraform automates infrastructure provisioning
- Always follow best practices for production workloads

**Next Steps:**
1. Install Docker and practice with simple applications
2. Build multi-container applications with Docker Compose
3. Learn Kubernetes for orchestration at scale
4. Implement CI/CD pipelines with Docker
5. Master security and monitoring patterns

Good luck with your Docker learning journey!
```
