#!/bin/bash

sudo systemctl disable isu-ruby
sudo systemctl stop isu-ruby
sudo systemctl enable isu-go
sudo systemctl start isu-go