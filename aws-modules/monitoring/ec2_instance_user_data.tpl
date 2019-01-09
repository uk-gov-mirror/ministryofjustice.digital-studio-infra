#!/bin/sh
yum install -y https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.0.3-1.x86_64.rpm
service grafana-server start
/sbin/chkconfig --add grafana-server