# Infrastructure Reference

**AWS, Docker, Kubernetes, and Terraform**

[← Back to Index](../index.md)

---

## Table of Contents

- [AWS](#aws)
  - [AWS Profiles](#aws-profiles)
  - [Multi-Role Profile System](#multi-role-profile-system-work-mac)
  - [Basic AWS Aliases](#basic-aws-aliases)
  - [AWS SSO Workflow](#aws-sso-workflow)
  - [Work-Specific Functions](#work-specific-functions)
  - [SSM Session Manager](#ssm-session-manager)
  - [Profile Management](#profile-management)
  - [Common Workflows](#aws-common-workflows)
  - [Security Best Practices](#security-best-practices)
  - [Troubleshooting](#aws-troubleshooting)
- [Docker](#docker)
  - [Docker Aliases](#docker-aliases)
  - [Docker Compose Aliases](#docker-compose-aliases)
  - [Common Workflows](#docker-common-workflows)
  - [Cleanup Commands](#cleanup-commands)
  - [Advanced Usage](#advanced-usage)
  - [Best Practices](#docker-best-practices)
  - [Troubleshooting](#docker-troubleshooting)
- [Kubernetes](#kubernetes)
  - [kubectl Aliases](#kubectl-aliases)
  - [K9s Terminal UI](#k9s-terminal-ui)
  - [Common Workflows](#kubernetes-common-workflows)
  - [Resource Management](#resource-management)
  - [Debugging](#debugging)
  - [Context Management](#context-management)
  - [Advanced Usage](#kubernetes-advanced-usage)
  - [Best Practices](#kubernetes-best-practices)
  - [Troubleshooting](#kubernetes-troubleshooting)
- [Terraform](#terraform)
  - [Terraform Aliases](#terraform-aliases)
  - [Work-Specific Aliases](#terraform-work-specific-aliases)
  - [Common Workflows](#terraform-common-workflows)
  - [Workspace Management](#workspace-management)
  - [State Management](#state-management)
  - [Advanced Usage](#terraform-advanced-usage)
  - [Best Practices](#terraform-best-practices)
  - [Security Considerations](#security-considerations)
  - [Troubleshooting](#terraform-troubleshooting)
- [Configuration](#configuration)

---

## AWS

**AWS CLI configuration, SSO workflow, and work-specific functions**

### AWS Profiles

**Default Profiles:**

| Machine          | Default Profile | Set By                      |
| ---------------- | --------------- | --------------------------- |
| **Personal Mac** | `personal`      | `home/_mixins/personal.nix` |
| **Work Mac**     | `example-corp`   | `home/_mixins/work.nix`     |

**Environment Variable:**

```bash
# Check current profile
echo $AWS_PROFILE

# Personal Mac
# Output: personal

# Work Mac
# Output: example-corp
```

---

### Multi-Role Profile System (Work Mac)

**Enhanced AWS profile management with multiple IAM roles per environment**

The work Mac includes a comprehensive multi-role system that supports:
- **Multiple profiles per project/environment** (e.g., `ti-dev`, `ti-dev-developer`)
- **Dynamic alias generation** from `accounts.json`
- **Role-based access control** (support, developer, admin, custom)
- **Profile discovery** (`awslist`, `awswhere`)
- **Session management** (`awscheck`, `awslogin`)

**Quick Example:**

```bash
# Switch to support role (read-only)
awsuse ti dev
# or
tidev

# Switch to developer role (write access)
awsuse ti dev developer
# or
tidev-developer

# List all available profiles
awslist

# Check session status
awscheck
```

**Complete Documentation:**
- **[AWS Multi-Role Guide](../../claudedocs/reference/aws/AWS-MULTI-ROLE.md)** - Full schema, examples, and best practices
- **[AWS Quick Reference](../../claudedocs/reference/aws/AWS-QUICK-REF.md)** - Command cheat sheet for daily use

---

### Basic AWS Aliases

Available on **all machines:**

| Alias        | Command                       | Description          |
| ------------ | ----------------------------- | -------------------- |
| `awsp`       | `export AWS_PROFILE=`         | Set AWS profile      |
| `awsprofile` | `echo $AWS_PROFILE`           | Show current profile |
| `awswho`     | `aws sts get-caller-identity` | Who am I?            |

**Examples:**

```bash
# Check who you are
awswho
# Output:
# {
#   "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#   "Account": "123456789012",
#   "Arn": "arn:aws:iam::123456789012:user/jimmy"
# }

# Show current profile
awsprofile
# Output: personal

# Switch profile
awsp production
echo $AWS_PROFILE
# Output: production
```

---

### AWS SSO Workflow

**Available only on work Mac** (when `MACHINE_MODE=work`)

**SSO Functions:**

| Function     | Command                               | Description          |
| ------------ | ------------------------------------- | -------------------- |
| `awslogin`   | `aws sso login --profile example-corp` | Login to AWS SSO     |
| `awslogout`  | Clear SSO cache                       | Logout from SSO      |
| `awsrefresh` | Re-login to SSO                       | Refresh credentials  |
| `awscheck`   | `aws sts get-caller-identity`         | Check session status |

**SSO Login Flow:**

```bash
# 1. Login to AWS SSO
awslogin
# Opens browser for authentication
# ✅ AWS SSO login successful

# 2. Verify login
awscheck
# Shows your identity

# 3. Use AWS CLI normally
aws s3 ls
aws ec2 describe-instances

# 4. When session expires (typically 8-12 hours)
awsrefresh
# Re-authenticates
```

**SSO Logout:**

```bash
# Logout and clear cached credentials
awslogout
# ✅ AWS SSO logged out

# This removes ~/.aws/sso/cache/* files
```

**Check Session Status:**

```bash
# Check if session is still valid
awscheck

# If valid:
# {
#   "UserId": "AROAXXXXXXXXX:jimmy@example-corp.com",
#   "Account": "123456789012",
#   "Arn": "arn:aws:sts::123456789012:assumed-role/..."
# }

# If expired:
# Error: The SSO session has expired
```

---

### Work-Specific Functions

**Only available when `MACHINE_MODE=work`**

**Environment Switching:**

| Alias     | Command                               | Description                |
| --------- | ------------------------------------- | -------------------------- |
| `awsdev`  | `export AWS_PROFILE=example-corp-dev`  | Switch to dev environment  |
| `awsprod` | `export AWS_PROFILE=example-corp-prod` | Switch to prod environment |

**Navigation Shortcuts:**

| Alias    | Command                      | Description            |
| -------- | ---------------------------- | ---------------------- |
| `vpn`    | `open -a 'Cisco AnyConnect'` | Open VPN client        |
| `cdwork` | `cd ~/Work`                  | Jump to work directory |
| `cdrepo` | `cd ~/Work/repositories`     | Jump to repositories   |

**Examples:**

```bash
# Switch to dev environment
awsdev
echo $AWS_PROFILE
# Output: example-corp-dev

aws s3 ls
# Lists S3 buckets in dev account

# Switch to prod environment
awsprod
echo $AWS_PROFILE
# Output: example-corp-prod

# Open VPN
vpn
# Launches Cisco AnyConnect

# Navigate to work repos
cdrepo
pwd
# Output: /Users/jimmy/Work/repositories
```

---

### SSM Session Manager

**Only available on work Mac**

Direct shell access to EC2 instances without SSH keys.

**SSM Function:**

```bash
ssm <instance-id>
```

**Usage:**

```bash
# Connect to EC2 instance
ssm i-0123456789abcdef0

# Starts interactive shell session
# sh-4.2$

# Exit with Ctrl+D or 'exit'
```

**Requirements:**

- AWS SSO session must be active (`awslogin`)
- Instance must have SSM agent running
- IAM role must allow SSM access
- Instance must be in AWS Systems Manager

**Find Instance IDs:**

```bash
# List all instances
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table

# Or use specific filters
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

**SSM Session Examples:**

```bash
# Basic connection
ssm i-0123456789abcdef0

# Run commands
sh-4.2$ whoami
ssm-user

sh-4.2$ sudo su -
[root@ip-10-0-1-123 ~]#

# Check logs
sh-4.2$ sudo journalctl -u myapp -f

# Exit session
sh-4.2$ exit
```

---

### Profile Management

**AWS Config File:**

Located at `~/.aws/config`:

```ini
[profile personal]
region = us-east-1
output = json

[profile example-corp]
sso_start_url = https://example-corp.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = us-east-1
output = json

[profile example-corp-dev]
role_arn = arn:aws:iam::111111111111:role/DevRole
source_profile = example-corp
region = us-east-1

[profile example-corp-prod]
role_arn = arn:aws:iam::222222222222:role/ProdRole
source_profile = example-corp
region = us-east-1
```

**Add New Profile:**

```bash
# Edit config
code ~/.aws/config

# Add profile
[profile myproject]
region = us-west-2
output = json

# Use profile
awsp myproject
aws s3 ls
```

**Region Override:**

```bash
# Override region for single command
aws ec2 describe-instances --region us-west-2

# Set default region for profile
aws configure set region us-west-2 --profile myproject
```

---

### AWS Common Workflows

**Daily Work Start:**

```bash
# 1. Open VPN
vpn
# Wait for connection

# 2. Login to AWS SSO
awslogin
# Authenticate in browser

# 3. Verify access
awscheck
# Shows identity

# 4. Switch to dev environment
awsdev

# 5. Navigate to work
cdrepo

# Ready to work!
```

**Switching Between Environments:**

```bash
# Working in dev
awsdev
aws s3 ls
# Shows dev buckets

# Need to check prod
awsprod
aws s3 ls
# Shows prod buckets

# Back to dev
awsdev
```

**Debugging EC2 Instance:**

```bash
# Login to SSO
awslogin

# Find instance
aws ec2 describe-instances --filters "Name=tag:Name,Values=web-server"

# Connect via SSM
ssm i-0123456789abcdef0

# Debug
sudo journalctl -u nginx -f
sudo systemctl status nginx

# Exit
exit
```

**Session Refresh (Expired Token):**

```bash
# Try to use AWS
aws s3 ls
# Error: The SSO session has expired

# Refresh
awsrefresh
# Re-authenticates

# Retry command
aws s3 ls
# Works!
```

---

### Security Best Practices

**1. Never Commit Credentials:**

```bash
# NEVER do this:
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

# ALWAYS use:
# - SSO for work
# - IAM roles for EC2/ECS
# - Temporary credentials
```

**2. Use SSO for Work:**

```bash
# Work accounts: ALWAYS use SSO
awslogin

# Personal account: Use IAM user or SSO
```

**3. Rotate Credentials:**

```bash
# SSO: Automatic rotation
# Personal: Rotate access keys every 90 days
aws iam create-access-key --user-name jimmy
aws iam delete-access-key --access-key-id OLD_KEY_ID
```

**4. Use MFA:**

```bash
# Enable MFA for all accounts
# SSO enforces MFA automatically
# IAM users: Enable in AWS Console
```

**5. Least Privilege:**

```bash
# Use separate profiles for different access levels
# dev: Read-only or limited write
# prod: Full access (limited users)

# Example:
awsdev    # Limited permissions
awsprod   # Full permissions (use carefully!)
```

---

### AWS Troubleshooting

**SSO Login Opens Wrong Browser:**

```bash
# Set default browser
export AWS_DEFAULT_SSO_BROWSER=/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome

# Or add to zsh.nix sessionVariables
```

**Session Expired Errors:**

```bash
# Error: The SSO session has expired

# Solution: Refresh credentials
awsrefresh
```

**Profile Not Found:**

```bash
# Error: Profile 'example-corp' not found

# Check config exists
cat ~/.aws/config | grep example-corp

# If missing, add to ~/.aws/config
code ~/.aws/config
```

**SSM Connection Failed:**

```bash
# Error: TargetNotConnected

# Check instance has SSM agent
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=i-0123456789abcdef0"

# Verify IAM role
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --query 'Reservations[*].Instances[*].IamInstanceProfile'
```

**Clear All Cached Credentials:**

```bash
# Logout from SSO
awslogout

# Remove all cached credentials
rm -rf ~/.aws/cli/cache/*
rm -rf ~/.aws/sso/cache/*

# Login again
awslogin
```

---

## Docker

**Docker and Docker Compose shortcuts and workflows**

### Docker Aliases

**Core Commands:**

| Alias  | Command         | Description             |
| ------ | --------------- | ----------------------- |
| `d`    | `docker`        | Docker command shortcut |
| `dps`  | `docker ps`     | List running containers |
| `dpsa` | `docker ps -a`  | List all containers     |
| `dimg` | `docker images` | List images             |

**Container Management:**

| Alias  | Command               | Description                             |
| ------ | --------------------- | --------------------------------------- |
| `drun` | `docker run -it --rm` | Run interactive container (auto-remove) |
| `dex`  | `docker exec -it`     | Execute command in container            |
| `drm`  | `docker rm`           | Remove container                        |
| `drmi` | `docker rmi`          | Remove image                            |

**Cleanup:**

| Alias    | Command                   | Description               |
| -------- | ------------------------- | ------------------------- |
| `dprune` | `docker system prune -af` | Remove all unused objects |

**Examples:**

```bash
# List running containers
dps
# CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS

# List all containers (including stopped)
dpsa

# List images
dimg
# REPOSITORY    TAG       IMAGE ID       CREATED        SIZE

# Run interactive Ubuntu container
drun ubuntu:latest bash
# Starts container, opens bash, removes when you exit

# Execute command in running container
dex my-container bash
# Opens bash shell in 'my-container'

# Remove stopped container
drm my-container

# Remove image
drmi ubuntu:latest

# Clean everything
dprune
# Removes all stopped containers, unused images, networks, cache
```

---

### Docker Compose Aliases

**Core Commands:**

| Alias   | Command                  | Description               |
| ------- | ------------------------ | ------------------------- |
| `dc`    | `docker compose`         | Docker Compose shortcut   |
| `dcu`   | `docker compose up -d`   | Start services (detached) |
| `dcd`   | `docker compose down`    | Stop and remove services  |
| `dlogs` | `docker compose logs -f` | Follow logs               |

**Examples:**

```bash
# Start all services in background
dcu
# Starting service1 ... done
# Starting service2 ... done

# View logs (follow mode)
dlogs
# Shows logs from all services

# View logs for specific service
dlogs api
# Shows logs from 'api' service only

# Stop all services
dcd
# Stopping service1 ... done
# Stopping service2 ... done
```

---

### Docker Common Workflows

**Start Development Environment:**

```bash
# Navigate to project
cd ~/Dev/my-app

# Start services
dcu

# View logs
dlogs api

# Follow specific service logs
dlogs -f web
```

**Debug Running Container:**

```bash
# List running containers
dps

# Open shell in container
dex my-api bash

# Inside container:
ls -la
cat /app/config.json
ps aux
exit
```

**Rebuild After Code Changes:**

```bash
# Stop services
dcd

# Rebuild images
dc build

# Start with new images
dcu

# Or combine:
dc down && dc build && dc up -d
```

**Quick Container Testing:**

```bash
# Run Python one-liner
drun python:3.13 python -c "print('Hello')"

# Run Node script
drun node:20 node -e "console.log('Hello')"

# Test Redis
drun redis:latest redis-cli ping
# Output: PONG
```

---

### Cleanup Commands

**Quick Cleanup:**

```bash
# Remove stopped containers
d container prune

# Remove unused images
d image prune

# Remove unused volumes
d volume prune

# Remove unused networks
d network prune
```

**Aggressive Cleanup:**

```bash
# Remove EVERYTHING unused
dprune
# This removes:
# - All stopped containers
# - All networks not used by at least one container
# - All images without at least one container
# - All build cache

# System cleanup (part of cleanup-all)
# Automatically runs during system cleanup
cleanup-all
```

**Cleanup Specific Resources:**

```bash
# Remove specific container
drm container-name

# Force remove running container
d rm -f container-name

# Remove specific image
drmi image-name

# Remove all stopped containers
d container prune -f

# Remove dangling images
d image prune -f

# Remove all unused images (not just dangling)
d image prune -af
```

---

### Advanced Usage

**Build and Push Images:**

```bash
# Build image
dc build api

# Tag image
d tag myapp:latest myregistry.com/myapp:v1.0

# Login to registry
d login myregistry.com

# Push image
d push myregistry.com/myapp:v1.0
```

**Inspect Containers:**

```bash
# View container details
d inspect my-container

# View container logs
d logs my-container

# Follow logs
d logs -f my-container

# Last 100 lines
d logs --tail 100 my-container

# View container resource usage
d stats
# Shows CPU, memory, network I/O live
```

**Network Management:**

```bash
# List networks
d network ls

# Inspect network
d network inspect bridge

# Create network
d network create my-network

# Connect container to network
d network connect my-network my-container

# Disconnect
d network disconnect my-network my-container
```

**Volume Management:**

```bash
# List volumes
d volume ls

# Inspect volume
d volume inspect my-volume

# Create volume
d volume create my-volume

# Remove volume
d volume rm my-volume

# Backup volume
d run --rm -v my-volume:/data -v $(pwd):/backup ubuntu tar czf /backup/volume-backup.tar.gz /data

# Restore volume
d run --rm -v my-volume:/data -v $(pwd):/backup ubuntu tar xzf /backup/volume-backup.tar.gz -C /
```

---

### Docker Best Practices

**1. Use .dockerignore:**

```
# .dockerignore
node_modules
.git
.env
*.log
.DS_Store
```

**2. Multi-Stage Builds:**

```dockerfile
# Build stage
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm ci --production
CMD ["node", "dist/index.js"]
```

**3. Use Docker Compose for Development:**

```bash
# Development
dcu

# Production (separate file)
dc -f docker-compose.prod.yml up -d
```

**4. Clean Up Regularly:**

```bash
# Weekly cleanup
dprune

# Or use system cleanup
cleanup-all
```

**5. Use Volumes for Persistence:**

```yaml
volumes:
  - postgres-data:/var/lib/postgresql/data # Named volume
  - ./src:/app/src # Bind mount for development
```

---

### Docker Troubleshooting

**Container Won't Start:**

```bash
# Check logs
dlogs service-name

# Check container status
dps -a

# Inspect container
d inspect container-name

# Check compose config
dc config
# Validates and displays compose file
```

**Port Already in Use:**

```bash
# Find what's using port
lsof -i :3000
# or
ports | grep 3000

# Kill process
kill -9 PID

# Or use different port in docker-compose.yml
ports:
  - "3001:3000"  # Host:Container
```

**Out of Disk Space:**

```bash
# Check disk usage
d system df
# Shows space used by images, containers, volumes

# Clean up
dprune

# More aggressive cleanup
d system prune -af --volumes
# ⚠️ This removes EVERYTHING including volumes!
```

---

## Kubernetes

**kubectl, k9s, and Kubernetes workflows**

### kubectl Aliases

**Core Commands:**

| Alias | Command            | Description        |
| ----- | ------------------ | ------------------ |
| `k`   | `kubectl`          | kubectl shortcut   |
| `kg`  | `kubectl get`      | Get resources      |
| `kd`  | `kubectl describe` | Describe resources |
| `kl`  | `kubectl logs`     | View logs          |

**Examples:**

```bash
# Get pods
kg pods
# or
k get pods

# Describe pod
kd pod my-pod
# or
k describe pod my-pod

# View logs
kl my-pod
# or
k logs my-pod

# Follow logs
kl -f my-pod
k logs -f my-pod
```

---

### K9s Terminal UI

**K9s** is a terminal-based UI for Kubernetes clusters.

**Launch K9s:**

| Alias | Command | Description |
| ----- | ------- | ----------- |
| `k9`  | `k9s`   | Launch K9s  |

```bash
k9
# Opens interactive terminal UI
```

**K9s Key Bindings:**

Once K9s is running:

| Key       | Action            |
| --------- | ----------------- |
| `:pods`   | View pods         |
| `:svc`    | View services     |
| `:deploy` | View deployments  |
| `:ns`     | View namespaces   |
| `/`       | Filter resources  |
| `d`       | Describe selected |
| `l`       | View logs         |
| `e`       | Edit resource     |
| `y`       | View YAML         |
| `Ctrl+d`  | Delete resource   |
| `Ctrl+k`  | Kill resource     |
| `?`       | Help              |
| `:q`      | Quit              |

---

### Kubernetes Common Workflows

**View Resources:**

```bash
# List pods
kg pods

# List pods in all namespaces
kg pods -A
k get pods --all-namespaces

# List specific resource
kg deployments
kg services
kg configmaps
kg secrets

# List with more details
kg pods -o wide

# Watch for changes
kg pods -w
```

**Get Pod Details:**

```bash
# Describe pod
kd pod my-pod

# View pod YAML
k get pod my-pod -o yaml

# View pod JSON
k get pod my-pod -o json
```

**View Logs:**

```bash
# View logs
kl my-pod

# Follow logs
kl -f my-pod

# Last 100 lines
kl --tail=100 my-pod

# Previous container (after crash)
kl -p my-pod

# Specific container in pod
kl my-pod -c container-name

# Multiple pods
kl -l app=my-app -f
```

**Execute Commands in Pods:**

```bash
# Open shell
k exec -it my-pod -- /bin/bash

# Or sh for alpine
k exec -it my-pod -- /bin/sh

# Run single command
k exec my-pod -- ls -la /app

# Specific container
k exec -it my-pod -c container-name -- /bin/bash
```

**Port Forwarding:**

```bash
# Forward local port to pod
k port-forward pod/my-pod 8080:80
# Access at localhost:8080

# Forward to service
k port-forward svc/my-service 8080:80

# Background
k port-forward pod/my-pod 8080:80 &

# Kill background port-forward
jobs
kill %1
```

---

### Resource Management

**Create Resources:**

```bash
# Apply configuration
k apply -f deployment.yaml

# Apply directory
k apply -f ./k8s/

# Create from stdin
cat <<EOF | k apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
EOF
```

**Update Resources:**

```bash
# Edit resource
k edit deployment my-deployment

# Scale deployment
k scale deployment my-deployment --replicas=3

# Set image
k set image deployment/my-deployment nginx=nginx:1.25

# Rollout restart
k rollout restart deployment my-deployment
```

**Delete Resources:**

```bash
# Delete pod
k delete pod my-pod

# Delete by file
k delete -f deployment.yaml

# Force delete (skip grace period)
k delete pod my-pod --force --grace-period=0

# Delete all pods with label
k delete pods -l app=my-app

# Delete namespace (and all resources)
k delete namespace my-namespace
```

---

### Debugging

**Check Pod Status:**

```bash
# Quick status
kg pods

# Detailed status
kd pod my-pod

# Events
k get events --sort-by=.metadata.creationTimestamp

# Filter events for pod
k get events --field-selector involvedObject.name=my-pod
```

**Common Issues:**

**CrashLoopBackOff:**

```bash
# Check logs
kl my-pod

# Check previous logs (after crash)
kl -p my-pod

# Describe pod (see events)
kd pod my-pod

# Check resource limits
kg pod my-pod -o yaml | grep -A 10 resources
```

**ImagePullBackOff:**

```bash
# Describe pod
kd pod my-pod
# Look for "Failed to pull image" error

# Check image exists
k get pod my-pod -o yaml | grep image:

# Check secrets (for private registries)
kg secrets
kd secret my-registry-secret
```

**Pending Pods:**

```bash
# Describe pod (shows why pending)
kd pod my-pod
# Common reasons:
# - Insufficient CPU/memory
# - No nodes available
# - PVC not bound

# Check node resources
k top nodes
k describe nodes
```

**Resource Usage:**

```bash
# Pod resource usage
k top pods

# Node resource usage
k top nodes

# Specific namespace
k top pods -n my-namespace

# All namespaces
k top pods -A
```

---

### Context Management

**View Contexts:**

```bash
# List contexts
k config get-contexts

# Show current context
k config current-context

# Show cluster info
k cluster-info
```

**Switch Context:**

```bash
# Switch to context
k config use-context my-cluster

# Switch namespace (within context)
k config set-context --current --namespace=my-namespace

# Or use kubens (if installed)
kubens my-namespace
```

---

### Kubernetes Advanced Usage

**Working with Namespaces:**

```bash
# Create namespace
k create namespace my-namespace

# Get resources in namespace
kg pods -n my-namespace

# Set default namespace
k config set-context --current --namespace=my-namespace

# Delete namespace
k delete namespace my-namespace
```

**ConfigMaps and Secrets:**

```bash
# Create ConfigMap from literal
k create configmap my-config --from-literal=key1=value1

# Create ConfigMap from file
k create configmap my-config --from-file=config.json

# View ConfigMap
kg configmap my-config -o yaml

# Create Secret
k create secret generic my-secret --from-literal=password=secret123

# Create Secret from file
k create secret generic my-secret --from-file=./secret.txt

# View Secret (base64 encoded)
kg secret my-secret -o yaml

# Decode Secret
k get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

**Rollouts:**

```bash
# Check rollout status
k rollout status deployment/my-deployment

# View rollout history
k rollout history deployment/my-deployment

# Rollback to previous version
k rollout undo deployment/my-deployment

# Rollback to specific revision
k rollout undo deployment/my-deployment --to-revision=2

# Pause rollout
k rollout pause deployment/my-deployment

# Resume rollout
k rollout resume deployment/my-deployment
```

---

### Kubernetes Best Practices

**1. Use Namespaces:**

```bash
# Separate environments
k create namespace dev
k create namespace staging
k create namespace prod

# Set context namespace
k config set-context --current --namespace=dev
```

**2. Use Labels:**

```bash
# Add meaningful labels
k label pod my-pod app=api env=prod version=v1.2.3

# Query by labels
kg pods -l app=api,env=prod
```

**3. Use K9s for Exploration:**

```bash
# Instead of multiple kubectl commands
k9

# Navigate visually
# View logs, describe, edit all from one UI
```

**4. Monitor Resource Usage:**

```bash
# Regular checks
k top nodes
k top pods -A

# Look for high usage
k top pods --sort-by=memory
k top pods --sort-by=cpu
```

---

### Kubernetes Troubleshooting

**kubectl Not Found:**

```bash
# Check installation
which kubectl

# If missing, rebuild
nix-rebuild
```

**Cannot Connect to Cluster:**

```bash
# Check context
k config current-context

# Check cluster info
k cluster-info

# Verify kubeconfig
cat ~/.kube/config

# Test connection
k get nodes
```

**Permission Denied:**

```bash
# Check current user
k auth whoami

# Check permissions
k auth can-i get pods
k auth can-i delete deployments

# Check all permissions
k auth can-i --list
```

---

## Terraform

**Terraform aliases, workflows, and best practices**

### Terraform Aliases

**Core Commands:**

| Alias | Command              | Description                  |
| ----- | -------------------- | ---------------------------- |
| `tf`  | `terraform`          | Terraform shortcut           |
| `tfi` | `terraform init`     | Initialize working directory |
| `tfp` | `terraform plan`     | Preview changes              |
| `tfa` | `terraform apply`    | Apply changes                |
| `tfv` | `terraform validate` | Validate configuration       |
| `tff` | `terraform fmt`      | Format Terraform files       |

**Examples:**

```bash
# Initialize Terraform
tfi
# Initializing provider plugins...
# Terraform has been successfully initialized!

# Validate configuration
tfv
# Success! The configuration is valid.

# Format files
tff
# main.tf
# variables.tf

# Plan changes
tfp
# Terraform will perform the following actions:
#   + resource "aws_instance" "web" { ... }
# Plan: 1 to add, 0 to change, 0 to destroy.

# Apply changes
tfa
# Do you want to perform these actions? yes
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

---

### Terraform Work-Specific Aliases

**Only available on work Mac** (when `MACHINE_MODE=work`)

**Workspace Aliases:**

| Alias    | Command                           | Description              |
| -------- | --------------------------------- | ------------------------ |
| `tfdev`  | `terraform workspace select dev`  | Switch to dev workspace  |
| `tfprod` | `terraform workspace select prod` | Switch to prod workspace |

**Examples:**

```bash
# Switch to dev workspace
tfdev
# Switched to workspace "dev"

# Plan dev changes
tfp

# Switch to prod workspace
tfprod
# Switched to workspace "prod"

# Plan prod changes (carefully!)
tfp
```

---

### Terraform Common Workflows

**Initialize New Terraform Project:**

```bash
# Create directory
mkdir ~/Dev/terraform/my-infrastructure
cd ~/Dev/terraform/my-infrastructure

# Create main.tf
cat > main.tf <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-example-bucket"
}
EOF

# Initialize
tfi

# Validate
tfv

# Format
tff

# Plan
tfp

# Apply
tfa
```

**Standard Change Workflow:**

```bash
# 1. Pull latest code
git pull

# 2. Initialize (get latest providers)
tfi -upgrade

# 3. Format code
tff

# 4. Validate
tfv

# 5. Plan changes
tfp -out=tfplan

# 6. Review plan
cat tfplan

# 7. Apply if looks good
tfa tfplan

# 8. Commit changes
ga terraform.tfstate
gcm "Update infrastructure"
gp
```

**Multi-Environment Workflow:**

```bash
# Dev environment
tfdev  # Switch workspace to dev
tfi    # Initialize
tfp    # Plan changes
tfa    # Apply

# Staging environment
tf workspace select staging
tfp
tfa

# Production environment (careful!)
tfprod  # Switch workspace to prod
tfp     # Review changes carefully
tfa     # Apply only if confident
```

---

### Workspace Management

**Workspace Commands:**

```bash
# List workspaces
tf workspace list
# Output:
#   default
# * dev
#   prod

# Show current workspace
tf workspace show
# Output: dev

# Create new workspace
tf workspace new staging

# Switch workspace
tf workspace select prod

# Delete workspace
tf workspace delete staging
```

**Workspace Best Practices:**

```bash
# Always check current workspace
tf workspace show

# Use workspace in resource names
resource "aws_s3_bucket" "example" {
  bucket = "myapp-${terraform.workspace}-bucket"
}

# Conditional resources by workspace
resource "aws_instance" "expensive" {
  count = terraform.workspace == "prod" ? 3 : 1
  # ...
}

# Workspace-specific variables
locals {
  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "t3.large"
  }
}

resource "aws_instance" "web" {
  instance_type = local.instance_type[terraform.workspace]
}
```

---

### State Management

**View State:**

```bash
# List resources in state
tf state list

# Show specific resource
tf state show aws_s3_bucket.example

# Pull current state
tf state pull > terraform.tfstate.backup
```

**Modify State:**

```bash
# Remove resource from state (doesn't delete resource)
tf state rm aws_s3_bucket.example

# Move resource in state (refactoring)
tf state mv aws_s3_bucket.old aws_s3_bucket.new

# Import existing resource
tf import aws_s3_bucket.example my-existing-bucket

# Replace resource (forces recreation)
tf apply -replace=aws_instance.web
```

**Remote State:**

```terraform
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"

    # Locking
    dynamodb_table = "terraform-locks"
  }
}
```

```bash
# Initialize with backend
tfi

# Reconfigure backend
tfi -reconfigure

# Migrate state to new backend
tfi -migrate-state
```

---

### Terraform Advanced Usage

**Plan with Variables:**

```bash
# Use variable file
tfp -var-file="prod.tfvars"

# Override variable
tfp -var="instance_count=5"

# Save plan
tfp -out=tfplan

# Apply saved plan
tfa tfplan
```

**Target Specific Resources:**

```bash
# Plan specific resource
tfp -target=aws_s3_bucket.example

# Apply specific resource
tfa -target=aws_s3_bucket.example

# Destroy specific resource
tf destroy -target=aws_s3_bucket.example
```

**Destroy Resources:**

```bash
# Destroy everything
tf destroy

# Destroy with auto-approve (dangerous!)
tf destroy -auto-approve

# Destroy specific resource
tf destroy -target=aws_s3_bucket.example
```

---

### Terraform Best Practices

**1. Always Format and Validate:**

```bash
# Before committing
tff
tfv
tfp

# Commit
ga .
gcm "Update infrastructure"
```

**2. Use Workspaces for Environments:**

```bash
# Create workspaces
tf workspace new dev
tf workspace new staging
tf workspace new prod

# Always verify current workspace
tf workspace show
```

**3. Use Remote State:**

```terraform
# Store state in S3
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

**4. Review Plans Before Applying:**

```bash
# Save plan
tfp -out=tfplan

# Review thoroughly
tf show tfplan

# Apply if safe
tfa tfplan
```

**5. Use Modules:**

```terraform
# modules/vpc/main.tf
module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"
  environment = terraform.workspace
}
```

**6. Lock Provider Versions:**

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Lock to 5.x
    }
  }
}
```

---

### Security Considerations

**1. Never Commit Secrets:**

```bash
# .gitignore
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars
*.auto.tfvars
```

**2. Use Variables for Secrets:**

```terraform
# variables.tf
variable "db_password" {
  type      = string
  sensitive = true
}

# Pass at runtime
tfp -var="db_password=$DB_PASSWORD"

# Or use environment variables
export TF_VAR_db_password="secret"
```

**3. Encrypt Remote State:**

```terraform
terraform {
  backend "s3" {
    bucket  = "terraform-state"
    encrypt = true  # Enable encryption
    # ...
  }
}
```

**4. Use Backend Locking:**

```terraform
terraform {
  backend "s3" {
    # ...
    dynamodb_table = "terraform-locks"  # Prevent concurrent runs
  }
}
```

---

### Terraform Troubleshooting

**State Locked:**

```bash
# Error: Error acquiring state lock

# View lock info
tf force-unlock <lock-id>

# Only if you're sure no other process is running!
```

**Provider Download Fails:**

```bash
# Clear plugin cache
rm -rf ~/.terraform.d/plugin-cache/*

# Re-initialize
tfi -upgrade
```

**State Out of Sync:**

```bash
# Refresh state
tf apply -refresh-only

# Review changes
tfp

# If resources were manually changed, import or remove
tf state rm aws_s3_bucket.example
tf import aws_s3_bucket.example my-bucket
```

**Workspace Not Found:**

```bash
# Error: Workspace "dev" doesn't exist

# Create workspace
tf workspace new dev

# Or select different workspace
tf workspace select default
```

---

## Configuration

### AWS Configuration

**Nix Configuration:**

**Personal Mac:** `home/_mixins/personal.nix`

```nix
home.sessionVariables = {
  MACHINE_MODE = "home";
  AWS_PROFILE = "personal";
};
```

**Work Mac:** `home/_mixins/work.nix`

```nix
home.sessionVariables = {
  MACHINE_MODE = "work";
  AWS_PROFILE = "example-corp";
};
```

**Shell Configuration:**

**File:** `home/jimmy/shell/zsh.nix`

**Basic aliases** (lines 223-225):

```bash
awsp = "export AWS_PROFILE=";
awsprofile = "echo $AWS_PROFILE";
awswho = "aws sts get-caller-identity";
```

**Work-specific functions** (lines 1141-1175) - See [Work-Specific Functions](#work-specific-functions)

### Docker Configuration

**Nix Configuration:**

**File:** `modules/darwin/homebrew.nix`

```nix
casks = [
  "docker"  # Docker Desktop
];
```

**Shell Configuration:**

**File:** `home/jimmy/shell/zsh.nix` (lines 186-201)

```bash
# Docker shortcuts
d = "docker";
dc = "docker compose";
dps = "docker ps";
dpsa = "docker ps -a";
dcu = "docker compose up -d";
dcd = "docker compose down";
dlogs = "docker compose logs -f";
dimg = "docker images";
drm = "docker rm";
drmi = "docker rmi";
dex = "docker exec -it";
drun = "docker run -it --rm";
dprune = "docker system prune -af";
```

### Kubernetes Configuration

**Nix Configuration:**

**File:** `modules/shared/packages.nix`

```nix
environment.systemPackages = with pkgs; [
  kubectl
  k9s
];
```

**Shell Configuration:**

**File:** `home/jimmy/shell/zsh.nix` (lines 213-217)

```bash
# Kubernetes shortcuts
k = "kubectl";
kg = "kubectl get";
kd = "kubectl describe";
kl = "kubectl logs";
k9 = "k9s";
```

**Oh-My-Zsh plugins** (line 28):

```bash
plugins = [
  # ...
  kubectl
  # ...
];
```

### Terraform Configuration

**Nix Configuration:**

**File:** `modules/shared/packages.nix`

```nix
environment.systemPackages = with pkgs; [
  terraform
];
```

**Shell Configuration:**

**File:** `home/jimmy/shell/zsh.nix`

**Terraform aliases** (lines 269-274):

```bash
tf = "terraform";
tfi = "terraform init";
tfp = "terraform plan";
tfa = "terraform apply";
tfv = "terraform validate";
tff = "terraform fmt";
```

**Plugin cache** (lines 324-325):

```bash
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
```

**Work-specific** (lines 1173-1174):

```bash
if [ "$MACHINE_MODE" = "work" ]; then
  alias tfdev="terraform workspace select dev"
  alias tfprod="terraform workspace select prod"
fi
```

---

## Links

**AWS:**

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS SSO Documentation](https://docs.aws.amazon.com/singlesignon/)
- [SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

**Docker:**

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

**Kubernetes:**

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [K9s Documentation](https://k9scli.io/)
- [kubectl Plugins](https://krew.sigs.k8s.io/plugins/)

**Terraform:**

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

**Related Documentation:**

- [Shell Reference](shell.md) - All shell aliases and functions
- [Languages Reference](languages.md) - Python and Node.js development
- [Tools Reference](tools.md) - VS Code and modern CLI tools
