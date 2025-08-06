#!/bin/bash
BACKEND_IP=$1
sudo apt-get update -y
sudo apt-get install -y docker.io
docker run -d -p 80:3000 -e DB_HOST=$BACKEND_IP -e DB_USER=root -e DB_PASS=1234 kirandas30/frontend-app:latest

