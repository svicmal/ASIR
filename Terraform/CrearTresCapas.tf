terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "servicios" {
  cidr_block       = "172.27.0.0/16"

  tags = {
    Name = "servicios"
  }
}
# Subred Pública
resource "aws_subnet" "subnet_pub" {
  vpc_id                  = aws_vpc.servicios.id
  cidr_block              = "172.27.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true 
  
  tags = {
    Name = "subnet-pub"
  }
}
# Subred Privada
resource "aws_subnet" "subnet_priv" {
  vpc_id                  = aws_vpc.servicios.id
  cidr_block              = "172.27.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false 
  
  tags = {
    Name = "subnet-priv"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.servicios.id

  tags = {
    Name = "gw"
  }
}

# Estoy no se que es
resource "aws_eip" "lb" {
  
  domain   = "vpc"
}
# Nat gateway que lo crea pero hace algo raro
resource "aws_nat_gateway" "gw_nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.subnet_pub.id

  tags = {
    Name = "gw NAT"
  } 
}
# Tabla de la subred pública
resource "aws_route_table" "tabla_pub" {
  vpc_id = aws_vpc.servicios.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
# Tabla de la subred privada 
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.servicios.id
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw_nat.id
}
# Asociaciones
resource "aws_route_table_association" "subnet_pub_association" {
  subnet_id      = aws_subnet.subnet_pub.id
  route_table_id = aws_route_table.tabla_pub.id
}
resource "aws_route_table_association" "subnet_priv_association" {
  subnet_id      = aws_subnet.subnet_priv.id
  route_table_id = aws_route_table.private_route_table.id
}
















# Instancias 



# Servidores de aplicaciones
# El userdata lo tendría que hacer con ansible o luego le hago un trigger y lo mando ???
resource "aws_launch_configuration" "terramino" {
  name_prefix     = "learn-terraform-aws-asg-"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.gs-php.id]

  lifecycle {
    create_before_destroy = true
  }
}
# Grupo de autoescalado
resource "aws_autoscaling_group" "terramino" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.terramino.name
  vpc_zone_identifier  = module.servicios.public_subnets
}
# Balanceador de carga 
resource "aws_lb" "terramino" {
  name               = "learn-asg-terramino-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.gs-php.id]
  subnets            = module.subnet_priv.public_subnets
}
# De aquí hasta los grupos de seguridad no tengo ni idea
resource "aws_lb_listener" "terramino" {
  load_balancer_arn = aws_lb.terramino.arn
  port              = "9000"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terramino.arn
  }
}
 resource "aws_lb_target_group" "terramino" {
   name     = "learn-asg-terramino"
   port     = 9000
   protocol = "TCP"
   vpc_id   = module.servicios.vpc_id
 }

resource "aws_autoscaling_attachment" "terramino" {
  autoscaling_group_name = aws_autoscaling_group.terramino.id
  alb_target_group_arn   = aws_lb_target_group.terramino.arn
}

# grupo de seguridad

resource "aws_security_group" "gs-nginx" {
  name        = "gs-nginx"
  description = "Example Security Group for HTTP and SSH"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # HTTP
  }
 
 ingress {
    from_port = 9000
    to_port   = 9000 
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # PHP                            
  }
 
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"  # Permitir todo el tráfico saliente
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "gs-php" {
  name        = "gs-php"
  description = "Example Security Group for HTTP and SSH"
 
  ingress {
    from_port = 22
    to_port   = 22   
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH  
  }
 
  ingress {
    from_port = 9000 
    to_port   = 9000 
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # PHP
  }  

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # MYsql
  } 

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"  # Permitir todo el tráfico saliente
    cidr_blocks = ["0.0.0.0/0"]
  }
}  
