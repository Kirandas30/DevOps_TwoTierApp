                               INTRODUCTION
With the increasing demand for automated deployment pipelines and scalable cloud architectures, DevOps practices have become an integral part of software delivery. This project aims to integrate Infrastructure as Code (IaC) using Terraform, Containerization using Docker, and CI/CD Automation using Jenkins to deploy a simple 2-tier application architecture on AWS.
The project will automate:
Infrastructure provisioning (VPC, Subnets, EC2 Instances),


Application deployment (Dockerized frontend and backend),


Solution testing (Instance communication, Application availability)
                                        PROBLEM STATEMENT
The goal of this project is to design a DevOps automation pipeline that provisions AWS infrastructure, deploys a 2-tier application (frontend and backend), and validates the deployment through automated tests.
The system should:
Provision AWS resources using Terraform to create a Public VPC with a Public and Private Subnet.


Launch two EC2 instances—Frontend (Public subnet) and Backend (Private subnet)—ensuring intra-VPC communication.


Automate application deployment using Bash scripts and Terraform provisioners.


Containerize the application components (frontend & backend) and manage their lifecycle via Docker.


Execute an automated testing phase to validate that the deployed application is functioning as expected.


Build a Jenkins CI/CD pipeline to integrate the entire process in a streamlined workflow.
                                                           PROJECT OVERVIEW
Stage 1: Infrastructure Provisioning (Create_Infra)
Use Terraform to define AWS resources including:


A Virtual Private Cloud (VPC).


Two Subnets: PUBLIC and PRIVATE.


Internet Gateway and NAT Gateway for routing.


Route Tables to control traffic flow.


Security Groups for controlled SSH and HTTP access.


Two EC2 Instances: FRONTEND (Public Subnet) and BACKEND (Private Subnet).


Use Terraform provisioners to send necessary deployment scripts (frontend.sh and backend.sh) to respective instances.


Ensure both instances can communicate internally within the VPC.


Stage 2: Application Deployment (Deploy_Apps)
Create a simple 2-tier application:


Backend: MySQL Database running in a Docker container.


Frontend: A Node.js-based form interface to capture user input.


Dockerize both application components and push them to DockerHub.


Use Terraform provisioners to run deployment scripts on respective EC2 instances:


backend.sh will install Docker, pull the MySQL container, and initialize the database.


frontend.sh will install Docker, pull the frontend container, and run the application.


Verify that the frontend can communicate with the backend instance across subnets.


Stage 3: Testing and Validation (Test_Solution)
Fetch the public IP/DNS of the FRONTEND instance via Terraform outputs.


Use automated CURL requests to validate application availability.


Perform manual testing:


Access the frontend web form, submit data.


SSH into the BACKEND instance and verify the data entry in the MySQL database.


Capture screenshots of frontend submission and backend DB verification as proof of successful deployment.


CI/CD Pipeline Integration using Jenkins
A Jenkins pipeline will orchestrate the 3 stages:


Stage 1: Run Create_Infra.sh to provision infrastructure.


Stage 2: Execute Deploy_Apps.sh to deploy applications on instances.


Stage 3: Run Test_Solution.sh to validate deployment.


Terraform state management and AWS credentials will be handled via Jenkins credentials.
Project Folder Structure: 

devops-project/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── frontend.sh
│   ├── backend.sh
│   ├── create_infra.sh
│   ├── deploy_apps.sh
│   └── test_solution.sh
├── app/
│   ├── frontend/
│   │   ├── Dockerfile
│   │   ├── app.js
│   │   ├── package.json
│   │   └── index.html
│   └── backend/
│       └── db-sql.sql
└── Jenkinsfile

 => Terraform Configuration

Stage 1: Create_Infra

main.tf

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

variable.tf

variable "aws_region" {
  default = "eu-north-1"
}
variable "key_pair_name" {
  description = "Name of the Key Pair"
  default     = "MyKeyPair"
}

variable "key_pair_path" {
  description = "Path to the Private Key (.pem file)"
  default     = "~/Downloads/MyKeyPair.pem"
}
output.tf
output "frontend_public_ip" {
  description = "Public IP of the Frontend EC2 Instance"
  value       = aws_instance.frontend.public_ip
}
output "backend_private_ip" {
  description = "Private IP of the Backend EC2 Instance"
  value  = aws_instance.backend.private_ip
}
Create_infra.sh
#!/bin/bash
terraform init
terraform plan -out=tfplan
terraform apply -auto-approve tfplan




frontend.sh


#!/bin/bash
BACKEND_IP=$1
sudo apt-get update -y
sudo apt-get install -y docker.io
docker run -d -p 80:3000 -e DB_HOST=$BACKEND_IP -e DB_USER=root -e DB_PASS=1234 kirandas30/frontend-app:latest


backend.sh
#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y docker.io
docker run -d --name mydb -e MYSQL_ROOT_PASSWORD=1234 -p 3306:3306 mysql:5.7
sleep 30
docker exec -i mydb mysql -u root -p1234 < /home/ubuntu/db-sql.sql

 




Stage 2: Deploy_Apps


Deploy_apps.sh
#!/bin/bash

FRONTEND_IP=$(terraform output -raw frontend_public_ip)
BACKEND_IP=$(terraform output -raw backend_private_ip)

ssh -o StrictHostKeyChecking=no -i ~/Downloads/MyKeyPair.pem ubuntu@$BACKEND_IP 'bash ~/backend.sh'
ssh -o StrictHostKeyChecking=no -i ~/Downloads/MyKeyPair.pem ubuntu@$FRONTEND_IP "bash ~/frontend.sh $BACKEND_IP"

Stage 3: Test_Solution

Test_Solution.sh

#!/bin/bash
FRONTEND_IP=$(terraform output -raw frontend_public_ip)
echo "Frontend Application URL: http://$FRONTEND_IP"
curl http://$FRONTEND_IP


=> Application Configuration

      =>FRONTEND


Dockerfile

FROM node:14
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["node", "app.js"]

app.js

const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const app = express();

app.use(bodyParser.urlencoded({ extended: true }));

const db = mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: 'userdb'
});

db.connect((err) => {
    if (err) throw err;
    console.log('Connected to MySQL');
});

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

app.post('/submit', (req, res) => {
    const { name, email } = req.body;
    db.query('INSERT INTO users (name, email) VALUES (?, ?)', [name, email], (err, result) => {
        if (err) throw err;
        res.send('Data Stored Successfully!');
    });
});

app.listen(3000, () => {
    console.log('Server running on port 3000');
});

Package.json


{
  "name": "frontend",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.17.1",
    "mysql": "^2.18.1",
    "body-parser": "^1.19.0"
  }
}

Index.html

<!DOCTYPE html>
<html>
<head>
    <title>User Form</title>
</head>
<body>
    <h2>Enter User Details</h2>
    <form action="/submit" method="post">
        Name: <input type="text" name="name"><br><br>
        Email: <input type="email" name="email"><br><br>
        <input type="submit" value="Submit">
    </form>
</body>
</html>

  => BACKEND

db-sql.sql

CREATE DATABASE userdb;
USE userdb;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);


Jenkinsfile (CI/CD Pipeline)

pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }
    stages {
        stage('Create Infra') {
            steps {
                sh './terraform/create_infra.sh'
            }
        }
        stage('Deploy Apps') {
            steps {
                sh './terraform/deploy_apps.sh'
            }
        }
        stage('Test Solution') {
            steps {
                sh './terraform/test_solution.sh'
            }
        }
    }
}










CONCLUSION

This project successfully automated the deployment of a two-tier application architecture on AWS using Terraform, Docker, Bash scripting, and Jenkins CI/CD pipeline. By structuring the workflow into three distinct stages—Create_Infra, Deploy_Apps, and Test_Solution—the project ensured modular, scalable, and efficient deployment of frontend and backend applications on separate EC2 instances within a secured VPC setup. The frontend enabled user input through a web form, storing data in a MySQL database running on a backend container, validating end-to-end functionality. Through containerization and Infrastructure as Code (IaC) practices, the project achieved automated provisioning, deployment, and testing, ensuring reliability, scalability, and a streamlined DevOps workflow that can be extended to complex production environments.





