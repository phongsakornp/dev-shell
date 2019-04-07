#!/bin/bash

git config --global user.email $GEMAIL
git config --global user.name $GNAME

service ssh restart
