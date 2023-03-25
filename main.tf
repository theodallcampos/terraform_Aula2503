provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon linux/images/hvm-ssd/*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_security_group" "sg_web" {
  name        = "sgweb${terraform.workspace}"
  description = "Mackenzie Security Group Web"
  vpc_id      = var.vpc

  dynamic "ingress" {
    for_each = local.ingress
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = ingress.value.protocol
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  }

  egress = [
    {
			description = "outgoing traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
			prefix_list_ids  = []
			security_groups = []
			self = false
    }
  ]
}

resource "aws_security_group" "sg_bd" {
  name        = "sgbd${terraform.workspace}"
  description = "Mackenzie Security Group Banco de Dados"
  vpc_id      = var.vpc

  dynamic "ingress" {
    for_each = local.ingress
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = ingress.value.protocol
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  }

  egress = [
    {
			description = "outgoing traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
			prefix_list_ids  = []
			security_groups = []
			self = false
    }
  ]
}

resource "aws_instance" "aws linux" {
      depends_on = [
        aws_security_group.sg_mack
    ]
  count = 5

  ami           = data.aws_ami.amazonlinux.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.mack_sg.id]  
  subnet_id = data.aws_ami.amazonlinux
  key_name = "aulamack"

  user_data = <<-EOF
        sudo apt-get update
				sudo apt-get install nginx
        echo "*** Instalacao nginx finalizada ok"
        sudo apt-get install mysql-server
        echo "*** Instalacao mysql finalizada ok"
				EOF

  root_block_device {
      volume_type = "gp3"
      volume_size = (terraform.workspace == "Dev") ? 10 : (terraform.workspace == "Hom") ? 20 : 50
   }

  tags = {
    Name = "mack-0${count.index}"
  }
}

resource "aws_instance" "ubuntu" {
      depends_on = [
        aws_security_group.sg_mack
    ]
  count = 5

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.mack_sg.id]  
  subnet_id = data.aws_ami.ubuntu
  key_name = "aulamack"

  user_data = <<-EOF
        sudo apt-get update
				sudo apt install httpd -y
        echo "*** Instalacao httpd finalizada ok"
				EOF

  root_block_device {
      volume_type = "gp3"
      volume_size = 20 
   }

  tags = {
    Name = "mack-0-0${count.index}"
  }
}

resource "aws_s3_bucket" "s3_mack" {
  bucket = "mack-aula2503-s3"
  acl    = "private"
}

locals {
  ingress = [{
    port        = 443
    description = "Port 443"
    protocol    = "tcp"
    },
    {
      port        = 80
      description = "Port 80"
      protocol    = "tcp"
  }]
  tags = {
    Name = "MyServer-${terraform.workspace}"
    Env  = terraform.workspace
  }
  }

  resource "aws_db_instance" "bd_mack" {
    allocated_storage = (terraform.workspace == "Dev") ? 20 : (terraform.workspace == "Hom") ? 30 : 50
    storage_type = var.storage_type
    engine = var.engine
    engine_version = var.engine_version
    instance_class = var.instance_class
    name = "rds-mysql-${terraform.workspace}"            
    username = var.username
    password = var.password
    port = var.port
    identifier = var.identifier
    parameter_group_name = var.parameter_group_name
    skip_final_snapshot = var.skip_final_snapshot
}
