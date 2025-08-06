provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Frontend Security Group (Allow SSH + HTTP)
resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere (restrict to your IP for security)
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Backend Security Group (Allow MySQL from Frontend SG)
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow MySQL access from Frontend"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "MySQL from Frontend"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Frontend EC2 Instance (Public Subnet)
resource "aws_instance" "frontend" {
  ami                    = "ami-042b4708b1d05f512"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = "MyKeyPair"
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  provisioner "file" {
    source      = "./frontend.sh"
    destination = "/home/ubuntu/frontend.sh"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Downloads/MyKeyPair.pem")
    host        = self.public_ip
    timeout     = "5m"
    
  }
}

# Backend EC2 Instance (Private Subnet)
resource "aws_instance" "backend" {
  ami                    = "ami-042b4708b1d05f512"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_subnet.id
  key_name               = "MyKeyPair"
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Downloads/MyKeyPair.pem")
    host        = self.private_ip
    timeout     = "5m"
    retries     = 5
  }
}



