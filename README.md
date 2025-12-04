# 🚀 AWS Multi-Region WordPress Disaster Recovery Architecture


[![Deploy Multi-Region Infrastructure](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/deploy.yml/badge.svg)](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/deploy.yml)

[![Destroy Multi-Region Infrastructure](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/destroy.yml/badge.svg)](https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr/actions/workflows/destroy.yml)


**Production-Grade • Highly Available • Fault-Tolerant • Terraform & AWS**

This repository delivers a **real-world enterprise disaster recovery design** for running WordPress across **two AWS regions** using a fully automated, highly available, self-healing architecture.

All infrastructure is 100% managed using **Terraform**, following AWS **Well-Architected best practices**.

---

# 📘 **Table of Contents**

* [Architecture Overview](#architecture-overview)
* [Key Features](#key-features)
* [Design Principles](#design-principles)
* [Technology Stack](#technology-stack)
* [Infrastructure Components](#infrastructure-components)
* [Failover Strategy](#failover-strategy)
* [Terraform Structure](#terraform-structure)
* [Reviewer Setup (How to Deploy This Project in Your AWS Account)](#reviewer-setup-how-to-deploy-this-project-in-your-aws-account)
* [DR Failover Guide](#dr-failover-guide)
* [CloudWatch Monitoring and Alarms](#cloudwatch-monitoring-and-alarms)
* [Security Best Practices Used](#security-best-practices-used)
* [Cost Optimization](#cost-optimization)
* [Known Limitations and Trade-offs](#known-limitations-and-trade-offs)
* [License](#license)

---

# 🏗 **Architecture Overview**

This project deploys a multi-region, production-grade WordPress platform using:

* **Primary Region:** `us-east-1`
* **DR Region:** `ca-central-1`
* **Global routing:** **CloudFront + Route 53**
* **Containers:** ECS Fargate
* **Database:** RDS MySQL with cross-region read-replica
* **Media:** S3 + CloudFront
* **Failover:** CloudFront Origin Groups (primary ALB → DR ALB)
--- 

## 🏗 Multi-Region Architecture (ASCII Diagram)

```text
                               ┌──────────────┐
                               │   Route 53   │
                               └───────┬──────┘
                                       │
                            ┌──────────▼──────────┐
                            │     CloudFront      │
                            │     Origin Groups   │
                            └──────────┬──────────┘
                    (HTTP errors)      │       (Normal)
                         Failover      │        Flow
                          ▼            │         ▼
                ┌────────────────┐     │   ┌────────────────┐
                │    ALB (DR)    │◄────┘   │ ALB (Primary)  │
                └────────────────┘         └────────────────┘
                       │                            │
                   us-east-1                   ca-central-1
                     (DR)                       (Primary)
                       │                            │
                ┌────────────────┐          ┌────────────────┐
                │ ECS Fargate    │          │ ECS Fargate    │
                │     (0*)       │          │      (2)       │
                └────────────────┘          └────────────────┘
                       │                            │
                       └──────────────┬─────────────┘
                                      │
                                      |                                 
                            ┌─────────▼─────────┐
                            │   WordPress App   │
                            └─────────┬─────────┘
                                      │
                          ┌───────────▼───────────┐
                          │       RDS MySQL       │
                          └───────────┬───────────┘
                                      │
                    ┌─────────────────▼──────────────────┐
                    │    Primary Writer (us-east-1)      │
                    └─────────────────┬──────────────────┘
                                      │ Replication
                    ┌─────────────────▼──────────────────┐
                    │    Read Replica (ca-central-1)     │
                    └────────────────────────────────────┘


                Media Failover (Automatic through CloudFront)

                         ┌───────────────┐    Read    ┌───────────────┐
                         │  S3 Primary   │◄──────────►│     S3 DR     │
                         └───────────────┘            └───────────────┘
```

# ⭐ **Key Features**

### 🟢 High Availability & Automated Failover

* Multi-region ECS + ALB
* Cross-region database replication
* CloudFront origin failover with no DNS delay

### 🌍 Global Content Delivery

* S3 + CloudFront for media
* Uploads served from nearest edge location

### 🔒 Hardened Security

* TLS everywhere
* Secrets in AWS Secrets Manager
* IAM-role access for WordPress S3 integration
* Private subnets, VPC endpoints, strict SGs

### ⚙️ Fully Automated with Terraform

* Modular structure
* Remote state per environment
* Zero manual configuration

---

# 📐 **Design Principles**

| AWS Well-Architected Pillar | Implementation                                         |
| --------------------------- | ------------------------------------------------------ |
| **Reliability**             | Multi-region, auto failover, RDS replica               |
| **Security**                | HTTPS, IAM roles, secrets manager, least-privilege SGs |
| **Performance**             | CloudFront CDN, S3 media, Fargate                      |
| **Cost-Optimization**       | Warm standby DR, endpoints to reduce NAT traffic       |
| **Operational Excellence**  | Full IaC, zero manual provisioning                     |

---

# 🔧 **Technology Stack**

### **AWS Services**

* ECS Fargate
* RDS MySQL (Multi-Region)
* S3 (Primary + DR)
* CloudFront CDN
* ALB
* Route 53
* Secrets Manager
* VPC + Endpoints
* CloudWatch + Logs
* ACM (provided or auto-generated)

### **Application Stack**

* WordPress
* WP-CLI
* Amazon S3 / CloudFront plugin
* Hardened `wp-config.php`
* Custom Docker image

---

# 🧱 **Infrastructure Components**

### 🟦 **1. ECS Fargate WordPress**

* Stateless containers
* Auto-healing
* No EC2 management
* Custom Dockerfile:

  * WP installed via WP-CLI
  * S3 plugin auto-configured
  * Admin URL rewriting
  * HTTPS detection (for CloudFront/ALB)

---

### 🟩 **2. Application Load Balancer**

* HTTPS termination
* Health checks used by CloudFront failover
* Admin subdomain bypasses CloudFront and routes directly to the ALB

---

### 🟥 **3. CloudFront Distribution**

* Two origin groups:

  1. **ALB Primary → ALB DR**
  2. **S3 Primary → S3 DR**
* Default: application traffic
* Ordered: WordPress media uploads
* Full automatic failover
* TLS enabled using ACM

---

### 🟨 **4. RDS MySQL**

* Primary RDS
* DR region read-replica
* Manual promotion during primary region failure

---

### 🟫 **5. S3 Media Storage**

* Two buckets (Primary + DR)
* CloudFront reads from both
* WordPress writes to the primary bucket
* IAM roles remove need for S3 keys

---

### 🟪 **6. VPC + Networking**

* Private ECS subnets
* Public ALB subnets
* NAT Gateway minimized
* VPC Endpoints:

  * S3
  * ECR
  * Logs
  * Secrets Manager
  * CloudWatch

* Each region has its own isolated VPC to ensure true regional independence.

---

# 🌐 **Failover Strategy**

## **1. Application Failover (Fully Automatic)**

CloudFront Origin Group:

```
Primary ALB → DR ALB
```

Triggers failover on:

* 5xx errors
* Timeout
* ALB unreachable
* Security group or NACL issues

**Users experience zero downtime**.

---

## **2. Media Failover**

CloudFront S3 Origin Group:

```
Primary S3 → DR S3
```

Read failover is automatic.
Write failover is controlled at ECS task-level.

---

## **3. Database Failover (RDS → DR Region)**

### Default (manual):

* Amazon RDS MySQL (Primary Region)
* Cross-Region Read Replica (DR Region)
* AWS Secrets Manager per region (Primary secret, DR secret)
* ECS Tasks in each region automatically read the correct secret

---

## **4. ECS Failover**

### **Primary Region**
- Runs full production ECS service (ex: 2 tasks)
- Serves all user traffic under normal conditions

### **DR Region (Warm Standby)**
- ECS service is fully deployed but scaled down to 0 tasks.
- This keeps costs minimal while ensuring the infrastructure is ready.

### **Failover Process**
When the primary region becomes unavailable:

1. **CloudFront automatically fails over** to the DR ALB.
2. The DR ECS service is **manually scaled** (or via automation) from 0 to 2 tasks.
3. DR tasks start, register with the DR target group, and immediately begin serving traffic.

This architecture follows AWS Warm Standby DR pattern — a cost-efficient model where the secondary region remains ready but scaled down until failover.

---

# 📁 **Terraform Structure**

```bash
aws-disaster-recovery/
│
├── environments/
│   ├── global/
│   │   ├── iam/
│   │   ├── oac/  
│   │   ├── cdn_dns/
│   ├── primary/
│   │   ├── network_rds/
│   │   ├── s3/
│   │   ├── alb/
│   │   ├── ecs/     
│   └── dr/
│       ├── network/
│       ├── read_replica_rds/
│       ├── s3/
│       ├── alb/
│       └── ecs/
├── modules/
│   ├── acm/
│   ├── alb/
│   ├── cdn/
│   ├── ecs/
│   ├── iam/
│   ├── rds/
│   ├── s3/
│   ├── sg/
│   └── vpc
└── scripts/
    └── deployment-automation-scripts/
    │   ├── config.sh
    │   ├── deploy.sh
    │   ├── destroy.sh
    │   └── pull-docker-hub-to-ecr.sh
    └── runtime/
        ├── primary-ecr-image-uri
        └── dr-ecr-image-uri   
```
This structure prevents dependency cycles and allows independent region deployments.

---

## Cross-Stack Dependency Map

This project uses multiple Terraform stacks.  
A detailed diagram of how stack outputs flow between stacks is available here:

👉 [Cross-Stack Variable Flow](docs/cross-stack-flow.md)

--- 

# 📘 **Reviewer Setup (How to Deploy This Project in Your AWS Account)** 

This section explains exactly how to deploy and test the full multi-region WordPress DR architecture in your own AWS account, with no AWS access keys and no manual Terraform commands (after bootstrap).

The setup is intentionally simple and follows AWS + GitHub industry CI/CD patterns.
## ✅ 1. Requirements

You need:

✔ AWS account
with permissions to create IAM, VPC, ECS, RDS, S3, CloudFront, ALB, Route53.

✔ A Route53 hosted zone
for your domain (example: yourdomain.com).

✔ (Optional) ACM certificates
If you don’t provide them, the infrastructure will create them automatically.

## 🚀 2. Clone the Project

No fork needed:
```bash
git clone https://github.com/QaysAlnajjad/aws-multi-region-wordpress-dr.git
cd aws-multi-region-wordpress-dr
```

## 🟦 3. Deploy the Bootstrap Stack (ONE TIME ONLY)

This step enables GitHub Actions OIDC → AWS IAM, allowing GitHub to deploy in your AWS account without any access keys.

✔ What bootstrap creates:

|              Resource                      |                            Purpose                                   |
| ------------------------------------------ | -------------------------------------------------------------------- |
| AWS IAM OpenID Connect Provider (GitHub)   | Allow GitHub Actions to authenticate to AWS                          |
| GitHub Actions IAM role                    | This is assumed by the deploy/destroy workflows                      |
| Trust policy restricted to the repository  | security-hardening: only our repository can use this role            |
| AdministratorAccess policy                 | Full deploy/destroy capabilities (reviewer may restrict this later)  |

Step 3.1 — Authenticate to AWS locally

Either:
```bash
aws configure
```
or
```bash
export AWS_ACCESS_KEY_ID=xxxx
export AWS_SECRET_ACCESS_KEY=xxxx
export AWS_DEFAULT_REGION=us-east-1
```
Step 3.2 — Deploy bootstrap
```bash
terraform -chdir=environments/bootstrap init
terraform -chdir=environments/bootstrap apply
```
You will receive an output:
```bash
github_actions_role_arn = arn:aws:iam::<ACCOUNT-ID>:role/github-actions-terraform-role
```

## 🟩 4. Add the Role ARN to GitHub Actions Workflows

You do NOT need GitHub secrets.

Just open:
```bash
.github/workflows/deploy.yml  
.github/workflows/destroy.yml
```
Find:
```bash
role-to-assume: arn:aws:iam::<ACCOUNT-ID>:role/github-actions-terraform-role
```
Replace <ACCOUNT-ID> with your AWS account ID.

✔ This is all GitHub needs.
✔ No secrets.
✔ No PAT.
✔ No long-lived keys.
✔ Secure and industry-standard.

## 🟧 5. Configure Deployment Parameters

Open:
```bash
scripts/deployment-automation-scripts/config.sh
```
Edit values to match your AWS environment:
| Variable                        | Purpose                                                                              |
|---------------------------------|--------------------------------------------------------------------------------------|
| PRIMARY_REGION                  | AWS region for the primary deployment (e.g., us-east-1)                              | 
| DR_REGION                       | AWS region for the DR deployment (e.g., ca-central-1)                                |
| TF_STATE_BUCKET_NAME            | S3 bucket used for ALL Terraform remote state                                        |
| TF_STATE_BUCKET_REGION          | Region of the Terraform state bucket                                                 | 
| PRIMARY_DOMAIN                  | Root domain (e.g., example.com)                                                      |
| HOSTED_ZONE_ID                  | Route53 hosted zone ID for the domain                                                |
| PRIMARY_MEDIA_S3_BUCKET         | Name of primary S3 bucket for media                                                  |
| DR_MEDIA_S3_BUCKET              | Name of DR S3 media bucket                                                           |
| PRIMARY_ALB_SSL_CERTIFICATE_ARN | RN of primary ALB ACM certificate (empty = auto-create with ACM module)              |
| DR_ALB_SSL_CERTIFICATE_ARN      | ARN of DR ALB ACM certificate (empty = auto-create with ACM module)                  |
| CLOUDFRONT_SSL_CERTIFICATE_ARN  |ACM certificate ARN in us-east-1 for CloudFront (empty = auto-create with ACM module) |

If you leave any certificate ARN empty, Terraform automatically creates certificates for you.

## 🚀 6. Deploy the Multi-Region Infrastructure

From GitHub → Actions:

✔ Go to:

Deploy AWS Disaster Recovery → Run workflow

GitHub will automatically:

✓ Assume the IAM role you created

✓ Load config.sh

✓ Mirror the Docker image → ECR (Primary + DR)

✓ Deploy the Primary region

✓ Deploy the DR region

✓ Deploy CloudFront + Route53 global stack

✓ Output WordPress endpoints

Total time: 12–20 minutes


### ✓ 🐳 Docker Image Mirroring (Helper Script)

During deployment, the main script:

```bash
scripts/deployment-automation-scripts/deploy.sh
```
internally calls the helper script:
```bash
scripts/deployment-automation-scripts/pull-docker-hub-to-ecr.sh <aws-region> <environment>
```
This helper script is fully automated and:

1. Pulls the WordPress image from Docker Hub defined in config.sh (DOCKERHUB_IMAGE)
2. Ensures the ECR repository exists (ECR_REPO_NAME)
3. Tags and pushes the image to:
```bash
<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/ecs-wordpress-app:<TAG>
```
4. Writes the final ECR image URI to:
```bash
scripts/deployment-automation-scripts/runtime/primary-ecr-image-uri
scripts/deployment-automation-scripts/runtime/dr-ecr-image-uri
```
The ECS task definitions in both regions then read the correct image URI from these runtime files, so the reviewer does not need to manage image tags manually.

## 💣 7. Destroy the Infrastructure

From GitHub → Actions:

Destroy AWS Disaster Recovery → Run workflow

This destroys resources in the correct dependency order:

* ECS
* ALBs
* RDS
* VPC
* CloudFront + Route53
* Cleanup ECR pushed images
* Remove runtime state

This ensures a clean teardown with no orphaned resources.

---

# 🆘 **DR Failover Guide**

### Automatic:

✔ CloudFront routes traffic to DR ALB
✔ S3 read failover
✔ WordPress stays online

### Manual:

1. Promote DR RDS replica
2. Scale ECS tasks in DR region
3. Update S3 write origin (only if primary S3 is down)
4. Post-incident: re-establish replication. After the primary region is restored, the old primary RDS instance must be replaced and a new cross-region read replica must be created to re-establish multi-region replication.

---

# 📊 **CloudWatch Monitoring and Alarms**

This project implements centralized observability using Amazon CloudWatch.
Both the application (ECS) layer and the automation layer (Lambda) are instrumented with log groups and health-monitoring alarms.

✔ ECS Logging

Each ECS task writes logs to a dedicated CloudWatch Log Group:
* Log group name pattern:
"/ecs/<task-family-name>"
* Logs retained for 7 days
* Automatically created for each ECS task definition via Terraform

This provides container-level logs for debugging application issues, deployment behavior, or failover events.

✔ ECS Health Alarm (via ALB Target Group)

To ensure service health and detect issues early, a CloudWatch alarm is configured for the Application Load Balancer (ALB) Target Group:
* Alarm name: wordpress-health-alarm
* Metric: HealthyHostCount (AWS/ApplicationELB)
* Trigger:
  * Alarm fires when healthy container count drops below 2
  * Metric evaluated every 60 seconds
  * treat_missing_data = "breaching" ensures that missing ALB metrics during failure also trigger the alarm
* Dimensions:
  * TargetGroup ARN suffix
  * LoadBalancer ARN suffix
* Purpose:
 * Detects failing ECS tasks or unhealthy containers behind the ALB, enabling early detection of service degradation

✔ Lambda Execution Logging

The database-initialization Lambda function (wordpress-db-setup) includes full log coverage:
* Log group:
  * "/aws/lambda/wordpress-db-setup"
* Log retention: 7 days
* All Lambda execution output (including errors, DB setup output, Secrets Manager interactions) is logged
* Logs assist in debugging database bootstrap, credential provisioning, and RDS post-creation automation

Additionally, a Terraform null_resource triggers the Lambda function immediately after creation to ensure DB setup runs automatically.

---

# 🔐 **Security Best Practices Used**

* TLS 1.2+ enforced
* HTTPS for admin + frontend
* Private database
* Security Groups use least privilege
* Secrets stored in Secrets Manager
* IAM roles used instead of access keys
* S3 buckets private (CloudFront handles access)
* Apache SSL disabled inside container (ALB handles TLS)

---

# 💰 **Cost Optimization**

This architecture follows a Warm Standby DR model to significantly reduce multi-region cloud expenses.

Primary Region (Active) — Estimated Monthly Cost
| Component  | Service                              | Approx Monthly Cost       |
| ---------- |--------------------------------------|---------------------------|
| Compute    | ECS Fargate tasks (1–2 tasks)        | $40–$80                   |
| Database   | RDS MySQL (db.t3.medium)             | $120–$150                 |  
| Storage    | S3 buckets + backups                 | $5–$15                    |
| Networking | ALB + VPC Endpoints (No NAT Gateway) | $7-$20                    |
| Traffic    | CloudFront distribution              | $10-$30                   |
| Monitoring | CloudWatch metrics, logs & alarms    | $5-$10                    |

Total Primary Region:
👉 $187–$305 per month

DR Region (Warm Standby) — Estimated Monthly Cost
| Component       | Service                              | Cost Behavior           | Approx Monthly Cost       |
| --------------- |--------------------------------------|-------------------------|---------------------------|
| Compute         | ECS Fargate tasks                    | Scaled to 0 (normal)    | $0                        |
| Database        | RDS cross-region read replica        | reqiured                | $120–$150                 |  
| Storage         | S3 replication target                | Minimal                 | $3-$10                    |
| Networking      | ALB + VPC Endpoints (No NAT Gateway) | Low                     | $18-$30                   |
| Traffic         | CloudFront distribution              | Shared                  | $0                        |
| Logs/Monitoring | CloudWatch                           | Small volume            | $3-$6                     |
Note:
ECS tasks in the DR region are scaled to zero during normal operation.
They scale up to two tasks only during a failover event, so DR compute cost is effectively zero until activation.

Total DR Region:
👉 $145–$196 per month

Total Multi-Region Cost
Primary ($187–$305) + DR ($145–$196)
👉 Estimated Total: $332–$501 per month

---

# ⚠️ **Known Limitations and Trade-offs**

This project implements a realistic multi-region DR (Disaster Recovery) architecture using a Warm Standby strategy. While effective and cost-efficient, it includes several intentional trade-offs and limitations that are important to understand.

1. Manual RDS Failover (Replica Promotion)

* The cross-region RDS replica does not automatically become primary.
* In a region-wide failure, an operator must manually promote the read replica in the DR region.
* This introduces a small delay (RTO) until the database becomes writable again.

Trade-off:
Automatic failover reduces downtime but increases complexity and cost. Manual promotion is simpler and appropriate for warm-standby DR.

2. RDS Replication Lag (RPO > 0)

* Cross-region MySQL replication introduces replication lag of seconds to minutes depending on load.
* During failover, the DR region may lose very recent writes.

Trade-off:
Achieving zero data loss requires synchronous replication or multi-master setups, which are significantly more expensive.

3. ECS DR Cluster is Warm, Not Active

* ECS tasks in the DR region are scaled down to 0 (or minimal) until failover.
* A failover event requires scaling ECS services up, which adds delay before full recovery.

Trade-off:
Warm standby reduces cost by 50–70% compared to active-active multi-region setups.

4. Route 53 Failover Does Not Validate Database Layer

* Route 53 health checks validate the ALB/ECS layer, not database availability.
* If the ALB is healthy but RDS is not, application errors may still occur.

Trade-off:
End-to-end health checking requires custom Lambda health endpoints or multi-layer monitoring, which increases complexity.

5. Lambda Automation Runs Once (Bootstrap Only)

* The DB setup Lambda runs only during initial deployment.
* Schema migrations or future DB updates must be handled manually or using a CI/CD process.

Trade-off:
Automating migrations adds complexity (Liquibase, Flyway, custom pipelines), so bootstrap-only logic keeps the project simple.

6. S3 Replication Provides Eventual Consistency

* S3 Cross-Region Replication (CRR) is asynchronous.
* Media files may take seconds or minutes to appear in the DR region after upload.

Trade-off:
Fully synchronous replication for media storage is expensive and not supported natively by S3.

7. Failover Decision Is Operator-Driven

* This DR design intentionally avoids auto-failover to prevent false positives.
* Failover requires human confirmation.

Trade-off:
Auto-failover is fast but risks flipping regions due to transient issues. Warm-standby DR normally uses controlled manual failover.

8. No Fully Automated DR Drills

* Disaster Recovery drills (regional failure simulations) must be executed manually.
* Automated DR testing pipelines are not included.

Trade-off:
Automation adds complexity; manual testing remains common in warm standby setups.

9. DR ALB Always Running

* The DR region's ALB is always provisioned to allow immediate failover.
* This introduces a small fixed cost even when the region is idle.

Trade-off:
Keeping the ALB "cold" would save money but increases RTO (longer DR recovery time).

Summary

These trade-offs make the solution:
Reliable
Realistic
Cost-effective

Aligned with AWS Well-Architected DR patterns (Warm Standby)

But they also mean the system is not active-active and sacrifices some speed and automation in exchange for simplicity and affordability.

--- 

# 📄 **License**

This project is open for personal and educational use.

---
