#!/bin/sh
# install grafana and configure service
yum install -y https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.0.3-1.x86_64.rpm
service grafana-server start
/sbin/chkconfig --add grafana-server
# install required grafana plugins
grafana-cli plugins install smartmakers-trafficlight-panel
grafana-cli plugins install snuids-trafficlights-panel
grafana-cli plugins install michaeldmoore-annunciator-panel
grafana-cli plugins install vonage-status-panel