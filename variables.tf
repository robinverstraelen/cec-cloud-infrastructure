variable "region" {
  default = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS config profile with admin access to the student account"
  default     = "sue-aws-student-01"
}

variable "student_count" {
  description = "Number of individual student VMs"
  default     = 60
}

variable "group_count" {
  description = "Number of shared group VMs"
  default     = 20
}

variable "student_instance_type" {
  default = "t3a.small"
}

variable "group_instance_type" {
  default = "t3a.medium"
}

# While true, terraform keeps every VM stopped (pre-course testing phase).
# Flip to false and apply once before the course starts: the instance-state
# resources leave the state without touching the VMs, and terraform no longer
# manages power state at all (console starts/stops are never reverted).
variable "enforce_stopped" {
  type    = bool
  default = true
}

# Drop-outs: add keys like "student-17" here and apply to decommission just
# that VM (instance, EIP, key pair, IAM user, policy) without touching others.
variable "decommissioned_vms" {
  type    = set(string)
  default = []
}

locals {
  all_vms = merge(
    { for i in range(1, var.student_count + 1) :
      format("student-%02d", i) => {
        instance_type = var.student_instance_type
        class         = "student"
      }
    },
    { for i in range(1, var.group_count + 1) :
      format("group-%02d", i) => {
        instance_type = var.group_instance_type
        class         = "group"
      }
    },
  )

  vms = { for k, v in local.all_vms : k => v if !contains(var.decommissioned_vms, k) }
}
