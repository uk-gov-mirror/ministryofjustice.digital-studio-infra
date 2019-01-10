#!/bin/sh
# install grafana and configure service
sudo yum install -y https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-5.0.3-1.x86_64.rpm
sudo service grafana-server start
/sbin/chkconfig --add grafana-server
# install required grafana plugins
sudo grafana-cli plugins install smartmakers-trafficlight-panel
sudo grafana-cli plugins install snuids-trafficlights-panel
sudo grafana-cli plugins install michaeldmoore-annunciator-panel
sudo grafana-cli plugins install vonage-status-panel