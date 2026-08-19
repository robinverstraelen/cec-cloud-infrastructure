resource "aws_vpc" "student_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "student-vpc"
  }
}

resource "aws_subnet" "student_subnet" {
  vpc_id            = aws_vpc.student_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "student-subnet"
  }
}

resource "aws_internet_gateway" "student_igw" {
  vpc_id = aws_vpc.student_vpc.id

  tags = {
    Name = "student-igw"
  }
}

resource "aws_route_table" "student_rt" {
  vpc_id = aws_vpc.student_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.student_igw.id
  }

  tags = {
    Name = "student-rt"
  }
}

resource "aws_route_table_association" "student_rta" {
  subnet_id      = aws_subnet.student_subnet.id
  route_table_id = aws_route_table.student_rt.id
}

# Ingress/egress are separate rule resources (not inline blocks) so extra
# ports opened via the console during the course are not reverted by applies.
resource "aws_security_group" "lab" {
  name        = "lab-ssh-access"
  description = "Lab VM access (course lab; world-open on purpose)"
  vpc_id      = aws_vpc.student_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.lab.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "app_ports" {
  security_group_id = aws_security_group.lab.id
  ip_protocol       = "tcp"
  from_port         = 3000
  to_port           = 3010
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.lab.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
