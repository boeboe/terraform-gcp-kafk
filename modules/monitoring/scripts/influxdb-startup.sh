#!/bin/bash
yum -y install wget

wget https://dl.influxdata.com/influxdb/releases/influxdb-1.8.10.x86_64.rpm
yum -y localinstall influxdb-1.8.10.x86_64.rpm

systemctl enable influxd
systemctl start influxd

sleep 5

influx -execute "CREATE DATABASE telegraf_db"
influx -execute "CREATE USER telegraf_user WITH PASSWORD 'password'"
influx -execute "GRANT ALL ON telegraf_db TO telegraf_user"
influx -execute 'CREATE RETENTION POLICY "one_year" ON "telegraf_db" DURATION 365d REPLICATION 1'
