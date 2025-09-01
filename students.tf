variable "instance_count_student" {
  description = "Number of EC2 instances to launch"
  default     = 50
}

provider "aws" {
  region = "eu-west-1"
}

resource "random_password" "student_password" {
  count  = var.instance_count_student
  length = 16
  special = true
}

resource "aws_vpc" "student_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "student-vpc"
  }
}

resource "aws_subnet" "student_subnet" {
  vpc_id     = aws_vpc.student_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"  # Adjust region/AZ
}

resource "aws_security_group" "ssh_access" {
  name        = "lab-ssh-access"
  description = "Allow SSH from anywhere (lab/demo only!)"
  vpc_id      = aws_vpc.student_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate SSH key pair for each VM
resource "tls_private_key" "student_key" {
  count     = var.instance_count_student
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "student_key" {
  count      = var.instance_count_student
  key_name   = "student-key-${count.index + 1}"
  public_key = tls_private_key.student_key[count.index].public_key_openssh
}

resource "aws_instance" "lab_vm" {
  count         = var.instance_count_student
  subnet_id     = aws_subnet.student_subnet.id
  ami           = "ami-0b016d1e12e0375a8"
  instance_type = "t3a.small"
  hibernation = true
  associate_public_ip_address = true
  key_name      = aws_key_pair.student_key[count.index].key_name
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true    # enable encryption required for hibernation
  }
  tags = {
    Name  = "student-lab-${count.index + 1}"
    Owner = aws_iam_user.student[count.index].name
  }
}

# IAM user setup omitted here for brevity; use previous code section for full permissions


# Create IAM roles/policies for each VM
resource "aws_iam_user" "student" {
  count = var.instance_count_student
  name  = "student-${count.index + 1}"
}

resource "aws_iam_user_login_profile" "student" {
  count     = var.instance_count_student
  user      = aws_iam_user.student[count.index].name
  pgp_key   = "keybase:nathankey"
  password_reset_required = true
}


resource "aws_iam_policy" "student_vm_policy" {
  count = var.instance_count_student
  name  = "student-${count.index + 1}-ec2-control"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
          "ec2:DescribeInstances"
        ],
        Resource = [
          aws_instance.lab_vm[count.index].arn
        ]
      },
    {
      Effect = "Allow",
      Action = "ec2:DescribeInstances",
      Resource = "*"
    }
    ]
  })
}

resource "aws_iam_policy" "allow_change_password" {
  name = "AllowChangeOwnPassword"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:ChangePassword"
        ],
        Resource = "arn:aws:iam::*:user/$${aws:username}"
      }
    ]
  })
}


resource "aws_iam_user_policy_attachment" "student_vm_access" {
  count      = var.instance_count_student
  user       = aws_iam_user.student[count.index].name
  policy_arn = aws_iam_policy.student_vm_policy[count.index].arn
}

resource "aws_iam_user_policy_attachment" "attach_change_password" {
  count      = var.instance_count_student
  user       = aws_iam_user.student[count.index].name
  policy_arn = aws_iam_policy.allow_change_password.arn
}

resource "aws_iam_access_key" "student" {
  count   = var.instance_count_student
  user    = aws_iam_user.student[count.index].name
}

output "lab_vm_access_info" {
  sensitive = true
  value = [
    for idx in range(var.instance_count_student) : {
      instance_name = aws_instance.lab_vm[idx].tags["Name"]
      public_ip     = aws_instance.lab_vm[idx].public_ip
      ssh_private_key = tls_private_key.student_key[idx].private_key_pem
      aws_iam_user    = aws_iam_user.student[idx].name
      aws_console_password = aws_iam_user_login_profile.student[idx].encrypted_password
    }
  ]
}
