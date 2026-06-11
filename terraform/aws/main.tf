provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = var.ubuntu_ami_ssm_parameter
}

locals {
  name = var.project
  azs  = var.availability_zones
  deploy_ssh_authorized_keys = compact([
    var.deploy_ssh_public_key,
    var.agent_ssh_public_key
  ])

  deploy_user_cloud_config = yamlencode({
    users = [
      "default",
      {
        name                = var.deploy_username
        groups              = "users"
        shell               = "/bin/bash"
        lock_passwd         = true
        ssh_authorized_keys = local.deploy_ssh_authorized_keys
      }
    ]
  })

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${local.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = "${local.name}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${local.name}-public-a"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = {
    for index, cidr in var.private_subnet_cidrs : index => cidr
  }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = local.azs[tonumber(each.key)]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${local.name}-private-${each.key}"
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-rds-subnets"
  subnet_ids = values(aws_subnet.private)[*].id

  tags = merge(local.tags, {
    Name = "${local.name}-rds-subnets"
  })
}

resource "aws_security_group" "ec2" {
  name        = "${local.name}-ec2-sg"
  description = "Allow SSH from the internet"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-ec2-sg"
  })
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Allow PostgreSQL only from EC2"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL from EC2 security group"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-rds-sg"
  })
}

resource "aws_key_pair" "this" {
  key_name   = "${local.name}-ec2-key"
  public_key = var.ssh_public_key

  tags = local.tags
}

resource "aws_instance" "this" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.this.key_name
  user_data                   = "#cloud-config\n${local.deploy_user_cloud_config}"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = merge(local.tags, {
    Name = "${local.name}-ec2"
  })
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${local.name}-ec2-eip"
  })
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}

resource "aws_db_instance" "postgres" {
  identifier                   = "${local.name}-postgres"
  username                     = var.db_username
  password                     = var.db_password
  engine                       = "postgres"
  engine_version               = var.postgres_major_version
  instance_class               = var.db_instance_class
  allocated_storage            = var.db_allocated_storage
  storage_type                 = "gp2"
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.rds.id]
  publicly_accessible          = false
  multi_az                     = false
  backup_retention_period      = 0
  deletion_protection          = false
  skip_final_snapshot          = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false

  tags = merge(local.tags, {
    Name = "${local.name}-postgres"
  })
}
