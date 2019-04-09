#!/bin/bash

git config --global user.email $GEMAIL
git config --global user.name $GNAME

# Setting permissions on docker.sock
chown dev: /var/run/docker.sock

service ssh restart
