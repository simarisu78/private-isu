#!/bin/bash

set -e
cd `dirname $0`
sudo cp ../mysql/mysql.conf.d/slowlog.cnf /etc/mysql/mysql.conf.d/slowlog.cnf
sudo cp ../nginx/conf.d/defaults.conf /etc/nginx/conf.d/defaults.conf