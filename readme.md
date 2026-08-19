# CEC Cloud Infrastructure

Lab VMs for the Cloud & Edge Computing course: 50 student VMs (`t3a.small`) and
20 group VMs (`t3a.medium`), all in one VPC. Each VM gets an Elastic IP (stable
across stop/start), an SSH key pair, and an IAM console user that can
start/stop/reboot only its own VM.

State lives in S3 (`sue-aws-student-01-tfstate`), never in git.

## Prerequisites

An AWS profile named `sue-aws-student-01` in `~/.aws/config` with administrator
credentials for the account, or pass your own profile with
`-var aws_profile=<their-profile>`.

## Deploy

```sh
terraform init
terraform plan
terraform apply
terraform output -json > outputs.json
python3 format.py   # -> students_access_info.txt + group_credentials.json
```

The generated credential files are gitignored — never commit them.

## Power-state lifecycle

VMs are created **stopped** (`enforce_stopped = true`) for the pre-course test
phase. Once the environment is signed off, set `enforce_stopped = false` and
apply once: terraform stops managing power state entirely, so starting/stopping
VMs in the console is never reverted.

## Decommissioning a drop-out

Add the VM key to `decommissioned_vms` (e.g. in a `*.tfvars` file):

```hcl
decommissioned_vms = ["student-17"]
```

`terraform plan` must show destroys only for `["student-17"]`-suffixed
resources; then `terraform apply`. No other VM is touched.

## Notes

- Extra ingress ports can be added to the `lab-ssh-access` security group via
  the console; applies won't revert them (rules are separate resources).
- The AMI (Ubuntu 24.04) is looked up at plan time but `ignore_changes = [ami]`
  prevents fleet replacement when Canonical publishes new images.
