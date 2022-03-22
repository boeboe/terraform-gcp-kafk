#!/bin/bash
yum -y install wget
yum -y install fontconfig
yum -y install freetype*
yum -y install urw-fonts

wget https://dl.grafana.com/oss/release/grafana-8.4.4-1.x86_64.rpm
yum -y localinstall grafana-8.4.4-1.x86_64.rpm

systemctl enable grafana-server.service
systemctl start grafana-server

bash -c 'while [[ "$(curl -u admin:admin -s -o /dev/null -w ''%{http_code}'' localhost:3000)" != "200" ]]; do sleep 5; done'

curl -X PUT -H "Content-Type: application/json" -d '{
  "oldPassword": "admin",
  "newPassword": "password",
  "confirmNew": "password"
}' http://admin:admin@localhost:3000/api/user/password
