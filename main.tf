# Create a VPC
resource "aws_vpc" "isaac_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.isaac_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev-public"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.isaac_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "dev-private"
  }
}

resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.isaac_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  subnet_id = aws_subnet.public-subnet.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.isaac_vpc.id
  tags = {
    Name = "dev-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet-gw.id
}

resource "aws_route_table_association" "public-associatn" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_security_group" "security-group" {
  name        = "dev-security-group"
  description = "dev security group"
  vpc_id      = aws_vpc.isaac_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "terra-auth" {
  key_name   = "terra-auth-key"
  public_key = file("~/.ssh/terra-keygen.pub")
}

resource "aws_instance" "dev_node" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.terra-auth.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  subnet_id              = aws_subnet.public-subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }
}