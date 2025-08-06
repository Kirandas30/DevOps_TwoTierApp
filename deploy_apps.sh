#!/bin/bash

FRONTEND_IP=$(terraform output -raw frontend_public_ip)
BACKEND_IP=$(terraform output -raw backend_private_ip)

ssh -o StrictHostKeyChecking=no -i ~/Downloads/MyKeyPair.pem ubuntu@$BACKEND_IP 'bash ~/backend.sh'
ssh -o StrictHostKeyChecking=no -i ~/Downloads/MyKeyPair.pem ubuntu@$FRONTEND_IP "bash ~/frontend.sh $BACKEND_IP"

