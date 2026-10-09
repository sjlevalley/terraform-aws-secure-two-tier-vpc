# Staging Environment

This Terraform root deploys the staging version of the Secure Two-Tier VPC architecture. Staging is intended to validate changes before production while remaining cost-aware during development.

Staging extends the dev shape with private AWS service access through VPC endpoints and an optional AWS WAF module that can be enabled for pre-production testing.

## Architecture

```mermaid
flowchart TB
  user([Internet users])

  subgraph edge[DNS, certificate, and optional edge protection]
    direction LR
    r53[Route 53<br/>alias A record for staging hostname]
    acm[ACM certificate<br/>DNS validated]
    waf[AWS WAF<br/>optional, disabled by default]
    r53 -. validation CNAME records .-> acm
  end

  user -->|1. DNS lookup| r53
  user ==>|2. HTTPS 443| waf
  user -. HTTP 80 redirects to HTTPS .-> waf

  subgraph vpc[Staging VPC across two Availability Zones]
    igw[Internet Gateway]

    subgraph public[Public subnets]
      publicAlb[Public Application Load Balancer<br/>HTTPS listener and HTTP redirect]
      nat[NAT Gateway<br/>single by default]
    end

    subgraph private[Private subnets, no public IPs]
      webAsg[Web Auto Scaling Group<br/>Nginx on port 80]
      internalAlb[Internal Application Load Balancer<br/>HTTP 8080]
      appAsg[App Auto Scaling Group<br/>Flask/Gunicorn on port 8080]
    end

    subgraph endpoints[VPC endpoints]
      s3[S3 gateway endpoint]
      interfaces[SSM, SSM Messages, EC2 Messages,<br/>CloudWatch Logs, CloudWatch Metrics]
    end

    waf ==> igw
    igw ==> publicAlb
    publicAlb ==>|3. HTTP 80 inside the VPC| webAsg
    webAsg ==>|4. HTTP 8080 for /api| internalAlb
    internalAlb ==>|5. HTTP 8080| appAsg
    webAsg -. outbound bootstrap and AWS APIs .-> nat
    appAsg -. outbound bootstrap and AWS APIs .-> nat
    webAsg -. private AWS APIs .-> interfaces
    appAsg -. private AWS APIs .-> interfaces
    webAsg -. S3 .-> s3
    appAsg -. S3 .-> s3
  end

  acm --> publicAlb
  r53 -. alias target .-> publicAlb

  subgraph obs[Observability]
    cw[CloudWatch logs, metrics, alarms, dashboard]
    sns[SNS email alerts]
    s3[(Encrypted S3 ALB access logs)]
    cw --> sns
  end

  vpc -. telemetry .-> cw
  publicAlb & internalAlb -. access logs .-> s3
```

## Staging Characteristics

- Default VPC CIDR: `10.20.0.0/16`
- Resource prefix: `secure-two-tier-staging`
- Environment tag: `staging`
- NAT Gateway mode is explicit and currently expected to be `single`
- VPC endpoints are enabled by default for S3, SSM, SSM Messages, EC2 Messages, CloudWatch Logs, and CloudWatch Metrics
- AWS WAF module is available but disabled by default through `enable_waf = false`
- Public and internal Application Load Balancers
- Private web and app Auto Scaling Groups
- Route 53 alias record and ACM DNS validation
- CloudWatch logs, metrics, alarms, dashboard, and SNS email notification
- Encrypted S3 bucket for ALB access logs

## Running Staging

From this directory:

```bash
terraform init
terraform validate
terraform plan -var-file="staging.tfvars" -out=tfplan
terraform apply tfplan
```

Create `staging.tfvars` from the example file:

```bash
cp staging.tfvars.example staging.tfvars
```

Set environment-specific values:

```hcl
aws_region         = "us-east-1"
nat_gateway_mode   = "single"
vpc_cidr           = "10.20.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
instance_type      = "t3.micro"
app_port           = 8080

domain_name    = "staging.example.com"
hosted_zone_id = "REPLACE_WITH_ROUTE53_HOSTED_ZONE_ID"
alarm_email    = "REPLACE_WITH_TEST_ALERT_EMAIL"

enable_alb_access_logs         = true
alb_access_logs_retention_days = 90
enable_vpc_endpoints           = true
enable_waf                     = false
waf_rate_limit                 = 2000
waf_managed_rules_count_mode   = true
```

Do not commit `staging.tfvars`, `tfplan`, `.terraform/`, or Terraform state files.

## Validation

After deployment:

```bash
curl -I http://staging.example.com
curl --fail https://staging.example.com/health
curl --fail https://staging.example.com/api/
```

Expected behavior:

- HTTP redirects to HTTPS.
- `/health` responds from the web tier.
- `/api/` responds from the private application tier.

## Cleanup

Destroy from this directory only when you intend to remove staging:

```bash
terraform destroy -var-file="staging.tfvars"
```
