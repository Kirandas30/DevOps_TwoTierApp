#!/bin/bash

FRONTEND_IP=$(terraform output -raw frontend_public_ip)
echo "Frontend Application URL: http://$FRONTEND_IP"
curl http://$FRONTEND_IP
