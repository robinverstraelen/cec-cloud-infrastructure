data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "tls_private_key" "vm" {
  for_each  = local.vms
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vm" {
  for_each   = local.vms
  key_name   = "${each.key}-key"
  public_key = tls_private_key.vm[each.key].public_key_openssh
}

resource "aws_instance" "vm" {
  for_each               = local.vms
  ami                    = data.aws_ami.ubuntu_2404.id
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.student_subnet.id
  key_name               = aws_key_pair.vm[each.key].key_name
  vpc_security_group_ids = [aws_security_group.lab.id]

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_tokens = "required"
    # hop limit 2 so containers/pods on the VM can still reach IMDS
    http_put_response_hop_limit = 2
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name  = each.key
    Owner = aws_iam_user.vm[each.key].name
    Class = each.value.class
  }

  lifecycle {
    # New Canonical AMI releases must not replace the running fleet.
    ignore_changes = [ami]
  }
}

resource "aws_eip" "vm" {
  for_each = local.vms
  instance = aws_instance.vm[each.key].id
  domain   = "vpc"

  tags = {
    Name = "${each.key}-eip"
  }
}

resource "aws_ec2_instance_state" "stopped" {
  for_each    = var.enforce_stopped ? local.vms : {}
  instance_id = aws_instance.vm[each.key].id
  state       = "stopped"

  # Associate the EIP before stopping the instance.
  depends_on = [aws_eip.vm]
}
