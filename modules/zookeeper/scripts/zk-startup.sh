#!/bin/bash
sudo su

echo ${id} > /var/lib/zookeeper/myid
chown zk:zk /var/lib/zookeeper/myid

systemctl enable zk
systemctl start zk
systemctl enable telegraf
systemctl start telegraf
