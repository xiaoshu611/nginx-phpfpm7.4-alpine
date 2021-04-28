#!/bin/bash

wget https://wesociastg.blob.core.chinacloudapi.cn/wesocial-uat/gocron-node-v1.5.3-linux-amd64.tar.gz \
	&& tar -zxvf gocron-node-v1.5.3-linux-amd64.tar.gz && rm -rf gocron-node-v1.5.3-linux-amd64.tar.gz \
	&& mv gocron-node-linux-amd64/gocron-node /usr/bin/gocron-node && rm -rf gocron-linux-amd64

supervisord -c /etc/supervisord.conf