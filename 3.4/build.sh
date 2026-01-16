#!/bin/bash

docker build -t gerrit-plugins-lfs:3.4 .
docker run -it -d --name gerrit-plugins-lfs gerrit-plugins-lfs:3.4
docker cp gerrit-plugins-lfs:/workspace/output/lfs.jar .
docker rm -f gerrit-plugins-lfs
