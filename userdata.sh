#!/bin/bash
dnf update -y
dnf install git -y
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
# newgrp docker
curl -SL https://github.com/docker/compose/releases/download/v2.38.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
cd /home/ec2-user
TOKEN=${git-token}
USER=${git-name}
git clone https://$TOKEN@github.com/$USER/Project_Bookstore_TF.git
cd Project_Bookstore_TF
docker build -t bookstore-api:latest .
docker-compose up -d
