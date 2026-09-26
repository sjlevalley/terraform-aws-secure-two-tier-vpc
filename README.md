# Secure Two-Tier VPC

## Scenario

A company needs a small two-tier application environment that separates internet-facing web servers from private application servers. The design must span two Availability Zones and use security-group references so access continues to work as instances are replaced.

## Build requirements

- Create one VPC with public and private subnets in two Availability Zones.
- Provide internet access to the public subnets.
- Deploy a small web-tier EC2 instance in each public subnet.
- Deploy a small application-tier EC2 instance in each private subnet.
- Allow inbound HTTP to the web tier from the internet.
- Allow the application port to the private tier only from the web tier's security group.
- Do not assign public IPv4 addresses to application-tier instances.
- Add useful outputs such as VPC ID, subnet IDs, and web-instance addresses.

## Practice goals

- VPCs, subnets, route tables, and internet gateways
- Multi-AZ resource layout
- Security-group references instead of broad CIDR rules
- Variables, locals, outputs, and repeated resources

## Completion checks

- Both web instances can be reached on HTTP.
- Internet clients cannot directly reach the application instances.
- The web tier can reach the configured application port.
- `terraform fmt`, `terraform validate`, and `terraform plan` succeed.

## Cost and cleanup

Use small instance types and destroy the environment when practice is complete. Avoid adding a NAT gateway unless you intentionally want to practice private-subnet outbound access, because it incurs hourly and data-processing charges.

## Terraform layout

For a step-by-step path from this lab to a functional, production-style design, see [MANUAL_IMPLEMENTATION_GUIDE.md](MANUAL_IMPLEMENTATION_GUIDE.md).

Reusable infrastructure is stored in `modules/`:

- `modules/network` creates the VPC, subnets, Internet Gateway, and public routes.
- `modules/security-groups` creates the web and application security groups.
- `modules/compute` creates the web and application EC2 instances.

The `environments/dev` directory is the Terraform root for the development environment. Run Terraform commands from that directory:

```bash
cd environments/dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Copy `dev.tfvars.example` to `dev.tfvars` when you need environment-specific values. Do not commit the copied `dev.tfvars` file.
