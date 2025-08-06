#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y docker.io
docker run -d --name mydb -e MYSQL_ROOT_PASSWORD=1234 -p 3306:3306 mysql:5.7
sleep 30
docker exec -i mydb mysql -u root -p1234 < /home/ubuntu/db-sql.sql
