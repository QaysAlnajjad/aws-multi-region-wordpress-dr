# AWS ECS WordPress Infrastructure with Terraform

A production-ready, scalable WordPress deployment on AWS using ECS Fargate, RDS MySQL, Application Load Balancer, and CloudFront CDN.

## 🏗️ Architecture

- **Compute**: ECS Fargate (serverless containers)
- **Network**: VPC with public/private subnets, NAT Gateway, VPC endpoints
- **Database**: RDS MySQL in private subnets
- **Load Balancer**: Application Load Balancer
- **CDN**: CloudFront with S3 for user uploads and ALB for WordPress application
- **Security**: Private networking, controlled internet access via NAT Gateway and network firewall

## 🚀 Quick Start

### Configuration
1. **Configure S3 state bucket:**
   ```bash
   # Set TF_STATE_BUCKET environment variable or GitHub secret
   # REQUIRED: Set your own unique bucket name via TF_STATE_BUCKET
   # Example: "mycompany-terraform-state-wordpress"
   ```
2. **Configure RDS variables:**
   ```bash
   # Edit RDS configuration
   nano environments/2-rds/rds.tfvars
   # Replace: YOUR_DB_ADMIN_USERNAME, YOUR_DB_USERNAME, YOUR_KEY
   ```
3. **Configure WordPress media S3 bucket name:**
   ```bash
   # Edit S3 bucket name (must be globally unique)
   nano environments/4-storage-cdn/storage-cdn.tfvars
   # Update: s3_bucket_name_config
   ```
4. **Configure domain settings:**
   ```bash
   # Edit domain configuration
   nano environments/4-storage-cdn/storage-cdn.tfvars
   # Update: primary_domain, ssl_certificate_arn, hosted_zone_id
   ```

**Note**: The deployment uses a pre-built WordPress Docker image from Docker Hub for faster deployment.

### Automated Deployment (Recommended)
1. **Fork this repository**
2. **Set `test` branch as default branch** (required for GitHub Actions visibility)
3. **Configure GitHub Secrets:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `TF_STATE_BUCKET`: Your unique S3 bucket name for Terraform state
4. **Push to `test` branch** → Automatic deployment starts (~30-35 minutes)
5. **Monitor progress** in GitHub Actions tab

*For technical details about the CI/CD workflows, see [DevOps & CI/CD Automation](#-devops--cicd-automation) section.*

### Cleanup (Automated)
1. **Destroy WordPress infrastructure:**
   - Go to Actions tab → "Destroy WordPress Infrastructure" → Run workflow → Type "destroy"

### Manual Deployment
#### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0 installed
1. **Deploy infrastructure:**
   ```bash
   chmod +x deploy.sh
   ./deploy.sh
   ```

### Cleanup (Manual)
```bash
# Destroy WordPress Infrastructure
chmod +x destroy.sh
./destroy.sh
```

### Access WordPress
- **Site URL**: https://www.yourdomain.com
- **Admin Panel**: https://www.yourdomain.com/wp-admin
- **Username**: admin
- **Password**: admin123

## 📁 Project Structure

```
├── environments/          # Environment-specific configurations
│   ├── 1-infrastructure/  # VPC, subnets, NAT Gateway, network firewall
│   ├── 2-rds/             # Database configuration 
│   ├── 3-alb/             # Load balancer setup
│   ├── 4-storage-cdn/     # S3 and CloudFront
│   ├── 5-ecs/             # Container orchestration
├── modules/               # Reusable Terraform modules
│   ├── alb/               # Application Load Balancer module
│   ├── ecs/               # ECS Fargate service, task definitions, CloudWatch logs and alarms
│   ├── infrastructure/    # VPC, subnets, NAT Gateway, route tables, network firewall
│   ├── rds/               # RDS MySQL with Lambda setup automation
│   ├── sg/                # Centralized Security Groups module
│   └── storage-cdn/       # S3 buckets, CloudFront distributions, Route 53
├── scripts/               # Lambda function and deployment scripts
│   ├── lambda/
│   │   ├── db-setup.zip              (Lambda deployment package for WordPress database setup)
│   │   ├── lambda_function.py        (Source code)
│   │   └── requirements.txt          (Dependencies)
│   └── bastion_host_setup.tpl        (Backup solution of RDS setup)
├── deploy.sh              # Deployment script
├── destroy.sh             # Cleanup script

```

## 🛡️ Security Features

- All containers run in private subnets
- Controlled internet access via NAT Gateway and Network Firewall for Docker pulls
- Database in private subnets only
- VPC endpoints for AWS service access
- Secrets managed via AWS Secrets Manager
- Individual IAM roles per service (least privilege)
- Centralized security group management
- CloudFront prefix list restrictions for ALB access

## 📊 Monitoring & Alerting

- **CloudWatch Logs**: ECS task logs and Lambda function logs with 7-day retention
- **CloudWatch Alarms**: Monitors ECS service health via ALB HealthyHostCount metrics (reflects actual service availability)
- **Automatic Detection**: Alerts when healthy hosts drop below threshold (< 2 hosts)
- **Responsive Detection**: 1-minute evaluation period with ~2-4 minute total detection time

## 🌍 Regional Architecture Strategy

### **Optimized Multi-Region Setup**
- **Primary**: `us-east-1` (Virginia) - Production workload
- **DR**: `ca-central-1` (Canada) - Disaster recovery
- **Backend**: `eu-central-1` (Frankfurt) - Terraform state management

### **Benefits of This Setup:**
✅ **Faster RDS Replication**: us-east-1 → ca-central-1 (~20ms vs ~100ms to EU)  
✅ **Faster S3 Replication**: Same continent advantage  
✅ **Disaster Separation**: Backend in EU survives North American disasters  
✅ **Cost Optimization**: Lower data transfer costs within North America  
✅ **Compliance Ready**: Canada for DR, EU for governance  

## 🏛️ Architectural Decisions

### **SSL/TLS Termination Strategy**
- **CloudFront**: Handles HTTPS termination and SSL certificate management
- **ALB**: Uses HTTP (port 80) for cost efficiency and simplified certificate management
- **Security**: ALB security groups restrict access to CloudFront IP ranges only
- **Traffic Flow**: `User →[HTTPS]→ CloudFront →[HTTP]→ ALB →[HTTP]→ ECS`

### **Internet-Facing ALB Design**
The ALB is configured as internet-facing (rather than internal) for operational benefits:

**Failover Readiness:**
- Enables potential Route 53 health checks and DNS failover if CloudFront fails
- Allows direct ALB access for emergency situations
- Provides foundation for implementing CloudFront backup strategies
- *Note: These capabilities are not currently configured but can be added when needed*

**Operational Flexibility:**
- Facilitates debugging and health monitoring
- Enables load testing directly against ALB
- Supports future HTTPS listener addition for direct access scenarios (Could add SSL certificate and HTTPS listener)

**Security Maintained:**
- Security groups restrict ALB access to CloudFront prefix lists only (pl-3b927c52)
- No direct public access possible without explicit security group changes
- CloudFront provides DDoS protection and WAF capabilities

### **Traffic Separation Strategy**
The architecture implements enterprise-grade traffic separation for enhanced security and functionality:

**Public Traffic (via CloudFront):**
- **Route**: `User →[HTTPS]→ CloudFront →[Origin Groups]→ ALB →[HTTP]→ ECS`
- **Methods**: GET, HEAD, OPTIONS (read-only operations)
- **Users**: Website visitors browsing content
- **Benefits**: Automatic DR failover, global CDN caching, DDoS protection
- **Limitation**: CloudFront origin groups don't support POST/PUT methods

**Administrative Traffic (Direct ALB):**
- **Route**: `Admin →[HTTP]→ ALB →[HTTP]→ ECS`
- **Methods**: All HTTP methods (POST, PUT, DELETE for content management)
- **Users**: WordPress administrators and content creators
- **Access**: Direct ALB DNS name (e.g., `wordpress-alb-xxx.region.elb.amazonaws.com/wp-admin`)
- **Benefits**: Full WordPress functionality, enhanced security isolation

**Why This Approach:**
✅ **Enterprise Standard**: Most production WordPress sites separate admin and public traffic  
✅ **Security Enhancement**: Admin access bypasses public CDN, reducing attack surface  
✅ **Functional Completeness**: Admins get full WordPress capabilities without CloudFront limitations  
✅ **DR Compatibility**: Public traffic gets automatic failover, admin access available via DR ALB during disasters  
✅ **Performance Optimization**: Public content cached globally, admin operations direct to application  

**Access Patterns:**
- **99% of traffic**: Regular visitors via CloudFront (automatic DR failover)
- **1% of traffic**: Administrators via direct ALB (manual DR failover if needed)

## 🔄 DevOps & CI/CD Automation

![Deploy Status](https://github.com/QaysAlnajjad/terraform-aws-wordpress-infrastructure/workflows/Deploy%20WordPress%20Infrastructure/badge.svg)
![Infrastructure](https://img.shields.io/badge/Infrastructure-Terraform-blue)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-green)
![AWS](https://img.shields.io/badge/Cloud-AWS-orange)

### 🚀 Automated CI/CD Pipeline

This section provides **technical documentation** for developers and DevOps teams. For user instructions, see [Quick Start](#-quick-start).

This project implements a complete **Infrastructure as Code** pipeline with automated deployment and controlled teardown processes.

#### **Pipeline Architecture**
```
Developer → GitHub → GitHub Actions → Terraform → AWS Infrastructure
```

#### **Workflow Automation**

**📦 Automatic Deployment** (`.github/workflows/deploy-wordpress-infrastructure.yml`)
- **Trigger**: Push to `test` branch
- **Duration**: ~30-35 minutes
- **Process**: 
  1. AWS credentials configuration
  2. Terraform setup and validation
  3. Sequential infrastructure deployment
  4. Resource validation and health checks

**🗑️ Controlled Destruction** (`.github/workflows/destroy-wordpress-infrastructure.yml`)
- **Trigger**: Manual workflow dispatch
- **Safety**: Requires "destroy" confirmation input
- **Process**: Reverse-order infrastructure teardown
- **Cost Control**: Prevents accidental resource charges


#### **DevOps Features**

✅ **Infrastructure as Code**: Complete Terraform automation  
✅ **State Management**: S3 backend with versioning  
✅ **Security**: AWS credentials via GitHub secrets  
✅ **Cost Optimization**: S3 Intelligent Tiering, ECS Fargate serverless compute, Lambda functions  
✅ **Monitoring**: CloudWatch integration

#### **💰 Cost Optimization**

**S3 Intelligent Tiering for WordPress Media:**
- **Automatic cost optimization** for WordPress media uploads
- **Up to 68% storage cost savings** through automatic tier transitions
- **Minimal performance impact** - instant retrieval for frequent/infrequent access, milliseconds delay for archive tiers
- **Monitoring-based transitions**:
  - Frequent access: Standard storage
  - Infrequent access (30+ days): IA storage  
  - Archive access (90+ days): Archive Instant Access
  - Deep archive (180+ days): Deep Archive Access
- **Perfect for WordPress**: Images/videos have varying access patterns over time  

#### **Pipeline Benefits**

- **Zero-Touch Deployment**: Push code → Infrastructure deployed
- **Consistent Environments**: Same deployment process every time
- **Fast Feedback**: 30-35 minute deployment cycle
- **Cost Control**: Manual destroy workflows prevent accidental charges
- **Team Collaboration**: Shared state management

### 🛠️ Local Development Support

**Manual Deployment Scripts**
```bash
./deploy.sh    # Infrastructure deployment
./destroy.sh   # Infrastructure cleanup
```

**Terraform Validation**
```bash
terraform fmt -recursive    # Code formatting
terraform validate          # Syntax validation
terraform plan              # Deployment preview
```

## 📝 Manual Deployment

For step-by-step deployment:

1. **Infrastructure Layer:**
   ```bash
   cd environments/1-infrastructure
   terraform init && terraform apply -var-file="infrastructure.tfvars"
   ```

2. **Database Layer:**
   ```bash
   cd ../2-rds
   terraform init && terraform apply -var-file="rds.tfvars"
   ```

3. **Load Balancer:**
   ```bash
   cd ../3-alb
   terraform init && terraform apply -var-file="alb.tfvars"
   ```

4. **Storage & CDN:**
   ```bash
   cd ../4-storage-cdn
   terraform init && terraform apply -var-file="storage-cdn.tfvars"
   ```

5. **Container Service:**
   ```bash
   cd ../5-ecs
   terraform init && terraform apply -var-file="ecs.tfvars"
   ```

### Cleanup
```bash
chmod +x destroy.sh
./destroy.sh
```

## 🎨 Key Features

- **Multi-Environment Support**: Modular design for easy environment replication
- **Advanced Terraform Patterns**: Uses `merge()`, `flatten()`, and `for_each` for complex data structures
- **Automated Database Setup**: Lambda functions for WordPress database initialization
- **Production-Ready**: Implements AWS best practices and security standards
- **State Management**: S3 backend with versioning for team collaboration
- **Dual Domain Support**: Tested with both Route 53-registered and externally registered domains (delegated to Route 53).

## 🤖 AI Assistance

This project leveraged AI assistance for specific components:
- **WordPress Configuration**: wp-config.php setup and environment variable integration
- **Docker Implementation**: Container entrypoint script and Dockerfile optimization
- **Database Automation**: MySQL setup scripts and Lambda function development

The core infrastructure design, Terraform modules, and architectural decisions were human-driven.

## 🤝 Contributing

This is a portfolio project demonstrating AWS infrastructure automation with Terraform.