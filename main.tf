provider "aws" {
  region = var.aws_region
}

#Configuração do Terraform State
terraform {
  backend "s3" {
    bucket = "terraform-state-soat"
    key    = "rds-producao-db/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-state-soat-locking"
    encrypt        = true
  }
}

#Security Group DB
resource "aws_security_group" "security_group_db_producao" {
  name_prefix = "security-group-producao-db"
  description = "SG RDS - Producao"
  vpc_id      = var.vpc_soat

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.security_group_load_balancer]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    infra   = "vpc-soat"
    Name    = "security-group-producao-db"
    service = "producao"
  }
}

# DB Subnet group
resource "aws_db_subnet_group" "db_rds_subnet_group_producao" {
  name = "subnet-group-producao-db"
  subnet_ids = [
    var.subnet_a_id,
    var.subnet_b_id
  ]

  tags = {
    Name    = "DB Subnet Group - Producao"
    infra   = "subnet-group-producao"
    service = "producao"
  }
}

resource "aws_db_instance" "postgresql_producao_db" {
  identifier             = "producao"
  allocated_storage      = 20
  db_name                = "producao"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.t3.micro"
  skip_final_snapshot    = true
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_rds_subnet_group_producao.name
  vpc_security_group_ids = [aws_security_group.security_group_db_producao.id]

  tags = {
    Name    = "producao-db"
    infra   = "producao-db"
    service = "producao"
  }
}
