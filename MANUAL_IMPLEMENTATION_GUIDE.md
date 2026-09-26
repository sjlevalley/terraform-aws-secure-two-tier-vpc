# Manual Implementation Guide: Production-Style Two-Tier Application

This guide turns the current lab into a functional and substantially hardened two-tier application while keeping the implementation work manual. Complete the phases in order and run the validation checkpoint after every phase.

## Target architecture

```text
Internet
   |
AWS WAF
   |
Public Application Load Balancer (HTTPS)
   |
Web Auto Scaling Group (Nginx, private subnets)
   |
Internal Application Load Balancer (HTTP 8080)
   |
App Auto Scaling Group (sample service, private subnets)

Supporting services:
- ACM and Route 53 for TLS and DNS
- Systems Manager for administration (no SSH)
- CloudWatch Logs, metrics, alarms, and dashboards
- NAT gateways or VPC endpoints for controlled outbound connectivity
```

The two load balancers have different jobs. The public ALB is the only internet-facing resource. The internal ALB gives Nginx a stable private endpoint while app instances are replaced or scaled.

## Before starting

1. Run all Terraform commands from `environments/dev`.
2. Confirm the active AWS account and region before applying anything.
3. Review AWS pricing for ALBs, NAT gateways, interface endpoints, WAF, CloudWatch, and public IPv4 addresses. These changes make the lab substantially more expensive.
4. Decide whether this is a production-style build or a short-lived practice build:
   - Production-style: one NAT gateway per Availability Zone.
   - Lower-cost lab: one NAT gateway, accepting an Availability Zone dependency, or use VPC endpoints and a prebuilt AMI.
5. Obtain a domain you control if you want browser-trusted HTTPS. ACM DNS validation requires control of the domain's DNS records.
6. Keep secrets out of `*.tfvars`, user data, Terraform outputs, and state. Use Systems Manager Parameter Store or Secrets Manager for secrets.

After every phase run:

```powershell
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

Only run `terraform apply tfplan` after reviewing the plan. Delete `tfplan` afterward; plan files can contain sensitive values.

## Phase 1: Make subnet addressing derive from the VPC CIDR

### Goal

Changing `vpc_cidr` must not leave the subnet CIDRs fixed under `10.0.0.0/16`.

### Files

- `modules/network/main.tf`
- `modules/network/variables.tf`

### Steps

1. Replace the four hard-coded subnet CIDRs with `cidrsubnet` expressions derived from `var.vpc_cidr`.
2. Use a consistent subnet size. With the current `/16` VPC, `cidrsubnet(var.vpc_cidr, 8, n)` creates `/24` subnets.
3. Reserve stable subnet numbers, for example:
   - public A: subnet number 1
   - public B: subnet number 2
   - private web/app A: subnet number 11
   - private web/app B: subnet number 12
4. Add variable validation so `vpc_cidr` is valid IPv4 CIDR syntax. If this module is specifically designed for a `/16`, validate that assumption or document it; otherwise ensure the selected `newbits` works for every accepted VPC range.
5. Add explicit private route tables and associate each private subnet. Initially they need only the automatically created local VPC route. This removes dependence on the VPC's implicit main route table.

### Verify

- Plan once with `10.0.0.0/16` and confirm the effective subnet ranges do not change unexpectedly.
- Plan with a disposable alternative such as `10.20.0.0/16` and confirm every subnet is inside that range.
- Restore the intended CIDR before applying. Changing an existing VPC CIDR/subnet layout can force replacement.

## Phase 2: Harden every EC2 instance at launch

### Goal

Require IMDSv2 and encrypted storage before adding more instances or launch templates.

### Files

- `modules/compute/main.tf`
- `modules/compute/variables.tf`

### Steps

1. Add a `metadata_options` block to both EC2 resources:
   - metadata endpoint enabled
   - metadata tokens required
   - hop limit 1 for these non-container workloads
   - instance tags disabled unless the application explicitly needs them
2. Add a `root_block_device` block to both resources:
   - `encrypted = true`
   - use `gp3`
   - set an intentional size such as 8 or 10 GiB
   - set `delete_on_termination = true`
3. Use the AWS-managed EBS key for the lab. For stronger key control, create a customer-managed KMS key, enable rotation, define least-privilege key policy access, and pass its ARN into the compute module.
4. Add `user_data_replace_on_change = true` while the project still uses individual `aws_instance` resources. This makes bootstrap changes deterministic rather than leaving old instances configured differently.

### Verify

- In the plan, confirm `http_tokens = "required"`.
- After apply, check EC2 instance metadata options show `IMDSv2 required`.
- Check each root EBS volume reports `Encrypted: Yes`.

## Phase 3: Add IAM roles and Systems Manager access

### Goal

Manage instances without SSH keys or inbound port 22.

### Suggested module

Create `modules/instance-identity` containing:

- one EC2 assume-role policy
- one instance role (or separate web and app roles if their permissions will differ)
- the `AmazonSSMManagedInstanceCore` managed policy attachment
- CloudWatch permissions added in Phase 9
- an instance profile consumed by compute/launch templates

### Steps

1. Create an IAM role whose trust policy allows only the EC2 service to assume it.
2. Attach `AmazonSSMManagedInstanceCore`.
3. Create an IAM instance profile for the role.
4. Pass the profile name to each instance using `iam_instance_profile`.
5. Do not add SSH ingress or create a key pair.
6. Choose the connectivity model:
   - Simple production-style path: private subnet default routes through NAT gateways.
   - No-general-internet path: interface VPC endpoints for `ssm` and `ssmmessages`, plus any endpoints needed by your logging/configuration design. An S3 gateway endpoint is useful for S3 access and has no endpoint hourly charge.
7. If using interface endpoints, create an endpoint security group that allows inbound TCP 443 from the web and app security groups. Enable private DNS on the endpoints.

### Verify

- In Systems Manager Fleet Manager, wait for every instance to appear as a managed node.
- Start a Session Manager session.
- Confirm no security group allows inbound port 22.

## Phase 4: Run a real application service on port 8080

### Goal

The app tier must return a health response and an application response.

### Files

- Move bootstrap scripts out of inline Terraform heredocs into files such as:
  - `modules/compute/templates/app-user-data.sh.tftpl`
  - `modules/compute/templates/web-user-data.sh.tftpl`

### Steps

1. Implement a small service for the exercise. Python, Node.js, Go, or Java is acceptable. It must:
   - bind to `0.0.0.0:8080`, not only localhost
   - return HTTP 200 from `/health`
   - return a recognizable response from `/api`, preferably including the instance hostname
   - avoid returning credentials, environment secrets, or instance metadata
2. Create a dedicated unprivileged Linux service account.
3. Store the application under `/opt/two-tier-app` with restrictive ownership.
4. Create a `systemd` unit with automatic restart and a short restart delay.
5. Enable and start the service from app user data.
6. Make bootstrap fail fast (`set -euo pipefail`) and send its output to a log that will later be shipped to CloudWatch.
7. Do not retrieve application secrets until IAM and private connectivity are working.

### Verify

From a web instance through Session Manager:

```bash
curl --fail http://APP_PRIVATE_IP:8080/health
curl --fail http://APP_PRIVATE_IP:8080/api
```

Both commands must succeed. From outside the VPC, the app private address must remain unreachable.

## Phase 5: Create the stable internal app endpoint

### Goal

Nginx must not depend on app instance IP addresses, which change during replacement and scaling.

### Suggested module

Create `modules/load-balancing` or separate `modules/public-alb` and `modules/internal-alb` modules.

### Steps

1. Create an internal Application Load Balancer across both private subnets.
2. Create an app target group:
   - protocol HTTP
   - port 8080
   - target type `instance`
   - health check path `/health`
   - success code `200`
3. Create an internal listener on port 8080 forwarding to the app target group.
4. Add an internal-ALB security group:
   - ingress TCP 8080 only from the web security group
   - egress TCP 8080 only to the app security group
5. Change the app security group:
   - remove direct ingress from the web security group
   - allow TCP 8080 only from the internal-ALB security group
6. Temporarily register both existing app instances with the target group. Phase 8 will replace these attachments with an Auto Scaling Group attachment.
7. Pass the internal ALB DNS name into the web user-data template.
8. Configure Nginx to proxy `/api/` to the internal ALB on port 8080. Preserve forwarding headers and configure sensible connect/read timeouts.
9. Add a local Nginx health endpoint such as `/health` that returns 200 without depending on the app tier.

### Verify

- Both app targets report healthy.
- From a web instance, `curl --fail http://INTERNAL_ALB_DNS:8080/health` succeeds.
- Loading `http://WEB_PUBLIC_IP/api/` returns the app response through Nginx.
- Direct internet access to port 8080 fails.

## Phase 6: Put the web tier behind a public ALB

### Goal

The public ALB becomes the only internet entry point; web instances become private targets.

### Steps

1. Create a public-ALB security group:
   - temporarily allow inbound TCP 80 from `0.0.0.0/0`
   - add TCP 443 in Phase 7
   - allow outbound TCP 80 only to the web security group
2. Create an internet-facing ALB across both public subnets.
3. Create a web target group:
   - protocol HTTP
   - port 80
   - target type `instance`
   - health check path `/health`
4. Create an HTTP listener forwarding to the web target group temporarily.
5. Change the web security group:
   - remove HTTP ingress from `0.0.0.0/0`
   - allow TCP 80 only from the public-ALB security group
6. Move web instances into private subnets and set `associate_public_ip_address = false`.
7. Register the current web instances with the target group. Phase 8 will replace direct attachments with an Auto Scaling Group attachment.
8. Replace the `web_public_ips` and `web_public_dns` outputs with the public ALB DNS name.

Moving instances between subnets forces replacement. Review the plan carefully.

### Verify

- Both web targets report healthy.
- The public ALB DNS name serves `/` and `/api/`.
- Web and app instances have no public IPv4 addresses.
- Only the ALB security group accepts internet traffic.

## Phase 7: Add HTTPS with ACM and DNS

### Goal

Encrypt client-to-ALB traffic and redirect all plaintext requests.

### Variables

Add variables such as:

- `domain_name`
- `hosted_zone_id`
- optionally `certificate_arn` if certificate lifecycle is managed outside this stack

### Steps

1. Request an ACM public certificate in the same region as the ALB.
2. Prefer DNS validation. If Route 53 hosts the zone, create the validation records in Terraform and wait for certificate validation.
3. Add an HTTPS listener on port 443 using the certificate and a current TLS 1.2-or-newer ELB security policy supported by your clients.
4. Change the HTTP listener to return a permanent redirect to HTTPS rather than forwarding traffic.
5. Add a Route 53 alias `A` record pointing the application hostname to the public ALB.
6. Keep TLS termination at the public ALB for this exercise. Traffic inside the VPC remains HTTP; add end-to-end TLS only if the threat model or compliance requirements demand it.

### Verify

```bash
curl -I http://app.example.com
curl --fail https://app.example.com/health
curl --fail https://app.example.com/api/
```

- HTTP returns a redirect to HTTPS.
- HTTPS has a trusted certificate matching the hostname.
- Do not test production TLS by disabling certificate verification.

## Phase 8: Replace individual instances with launch templates and Auto Scaling Groups

### Goal

Maintain at least one web and app instance per Availability Zone and replace unhealthy instances automatically.

### Suggested module

Replace `modules/compute` with reusable launch-template/ASG resources, or split it into `modules/web-tier` and `modules/app-tier`.

### Steps

1. Create one launch template for the web tier and one for the app tier.
2. Move these settings into each launch template:
   - AMI and instance type
   - security groups
   - IAM instance profile
   - IMDSv2 requirement
   - encrypted root volume
   - user data using `base64encode(templatefile(...))`
   - tags for instances and volumes
3. Create a web Auto Scaling Group across both private subnets:
   - minimum 2
   - desired 2
   - maximum 4 for the lab
   - attach the web target group ARN
   - enable ELB health checks
   - set a health-check grace period long enough for bootstrap
4. Create an app Auto Scaling Group with equivalent capacities and attach the app target group ARN.
5. Add target-tracking policies. Start with average CPU around 50% or a tested request-count-per-target threshold. Tune from observed workload data rather than treating the initial value as universal.
6. Add instance refresh configuration so launch-template changes roll out gradually.
7. Set termination policies and minimum healthy percentage so a rollout does not remove an entire tier.
8. Remove the old `aws_instance` resources and direct target-group attachments only after the ASG targets are healthy.

### Safe migration sequence

1. Create launch templates and ASGs alongside existing instances.
2. Wait for ASG targets to become healthy.
3. Confirm requests reach new instances.
4. Remove the old instances and direct attachments in a later apply.

### Verify

- Each target group has two healthy instances across two AZs.
- Terminate one lab instance manually and confirm its ASG replaces it.
- Confirm the replacement becomes healthy and receives requests.
- Confirm no instance has a public IP.

## Phase 9: Add centralized logs, metrics, alarms, and a dashboard

### Goal

Detect failures without logging into instances.

### Steps

1. Create CloudWatch log groups explicitly with retention, such as 14 days for the lab. Do not allow infinite retention by accident.
2. Extend the instance role with only the CloudWatch Agent permissions it needs. The AWS-managed `CloudWatchAgentServerPolicy` is convenient for the lab; a custom least-privilege policy is preferable for production.
3. Install and configure the CloudWatch agent in both launch templates.
4. Collect at minimum:
   - web: Nginx access/error logs, bootstrap log, system log
   - app: application/systemd log, bootstrap log, system log
   - memory and disk metrics if useful
5. Enable public and internal ALB access logs to dedicated, encrypted S3 storage if request-level audit history is required. Add lifecycle retention.
6. Create alarms for:
   - public and internal target group unhealthy host count
   - ALB 5xx responses
   - high target response time
   - ASG capacity below desired capacity
   - sustained CPU, memory, or disk pressure
7. Send alarm actions to an SNS topic with an intentional subscriber. Do not commit personal email addresses into a reusable module.
8. Create a small dashboard showing request count, latency, 4xx/5xx, healthy hosts, ASG capacity, and instance utilization.

### Verify

- Generate a request and find it in the expected log stream.
- Stop the app service on one lab instance and verify health checks fail, the alarm changes state, and the ASG replaces the instance.
- Restore or allow replacement of the intentionally failed instance.

## Phase 10: Restrict security-group egress

### Goal

Replace blanket `0.0.0.0/0` egress with traffic needed by each component.

Do this late in the sequence because restrictive egress can break package installation, DNS, SSM, log shipping, certificate retrieval, and application startup.

### Intended security-group chain

| Source | Destination | Port | Purpose |
|---|---|---:|---|
| Internet | Public ALB SG | 443 | User HTTPS |
| Internet | Public ALB SG | 80 | HTTPS redirect only |
| Public ALB SG | Web SG | 80 | ALB to Nginx |
| Web SG | Internal ALB SG | 8080 | Nginx to app endpoint |
| Internal ALB SG | App SG | 8080 | Internal ALB to app |
| Web/App SG | Endpoint SG | 443 | Private AWS API access |

### Steps

1. Model security-group rules as separate Terraform resources so dependencies and descriptions are clear.
2. Remove blanket egress from ALB, web, and app groups.
3. Add only the SG-to-SG rules in the table.
4. If using NAT for software repositories or external APIs, remember that security groups cannot restrict destinations by DNS name. Use an egress proxy, Network Firewall, or another controlled egress design when domain-level policy is required.
5. Account for required AWS-service traffic through interface endpoints or AWS-managed prefix lists where supported.
6. Test SSM, CloudWatch, bootstrapping, health checks, `/`, and `/api/` before considering this complete.

### Verify

- Every allowed flow succeeds.
- Direct web-to-app traffic fails if the internal ALB is required in the design.
- App-to-internet traffic not explicitly required by the application fails.
- Terraform contains no unexplained `0.0.0.0/0` egress rule.

## Phase 11: Add AWS WAF to the public ALB

### Goal

Add managed layer-7 filtering and rate limiting at the internet boundary.

### Suggested module

Create `modules/waf` with a regional-scope web ACL and an ALB association.

### Steps

1. Create a regional WAF web ACL with default action `allow`.
2. Add the AWS managed common rule set in count mode first.
3. Add an IP reputation managed rule group in count mode.
4. Add a rate-based rule with a limit appropriate for the test workload.
5. Enable sampled requests, CloudWatch metrics, and WAF logging with redaction for sensitive headers or fields.
6. Associate the web ACL with only the public ALB.
7. Review counted requests and false positives.
8. Change managed rules from count to block only after observation and testing.

### Verify

- Normal `/`, `/health`, and `/api/` requests still work.
- WAF metrics and sampled requests appear.
- A safe test matching a selected rule is counted and, after enforcement is enabled, blocked.

## Phase 12: Final acceptance tests

Complete every check before calling the environment production-style:

- [ ] `terraform fmt -check -recursive` passes.
- [ ] `terraform validate` passes.
- [ ] A reviewed `terraform plan` contains no unexpected replacement or public exposure.
- [ ] The only public endpoint is the public ALB.
- [ ] HTTP redirects to HTTPS.
- [ ] The certificate is trusted and matches the DNS name.
- [ ] `/` is served by Nginx.
- [ ] `/api/` passes through Nginx and the internal ALB to an app instance.
- [ ] Both target groups have healthy targets in both AZs.
- [ ] Web and app instances have no public IPs.
- [ ] App port 8080 is not internet-accessible.
- [ ] No inbound SSH rule or EC2 key pair is needed.
- [ ] Session Manager works for both tiers.
- [ ] Root volumes are encrypted and IMDSv2 is required.
- [ ] Logs arrive in CloudWatch and have finite retention.
- [ ] Alarms have tested notification paths.
- [ ] ASGs replace unhealthy instances.
- [ ] WAF is associated and its rules were observed before blocking.
- [ ] Egress rules have documented purposes.
- [ ] Subnet CIDRs follow `vpc_cidr`.

## Recommended implementation order summary

1. CIDR derivation and explicit private route tables
2. IMDSv2 and EBS encryption
3. IAM instance profiles and Systems Manager connectivity
4. Functional app service
5. Internal app ALB and Nginx reverse proxy
6. Public web ALB and private web instances
7. ACM certificate, HTTPS, redirect, and DNS
8. Launch templates and Auto Scaling Groups
9. CloudWatch logs, metrics, alarms, and dashboards
10. Restricted egress
11. WAF in count mode, followed by tested blocking
12. Failure testing and final acceptance checks

## Cleanup

This design includes hourly and usage-based resources. When the practice session is over, run and review:

```powershell
terraform plan -destroy
terraform destroy
```

Then confirm that NAT gateways, load balancers, interface endpoints, WAF resources, CloudWatch log groups, S3 log buckets, Elastic IPs, and Route 53 records were either destroyed or intentionally retained.
