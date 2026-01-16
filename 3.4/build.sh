#!/bin/bash

docker build gerrit-plugins-lfs:3.4 .
docker run --name gerrit-plugins-lfs gerrit-plugins-lfs:3.4
docker cp gerrit-plugins-lfs:/workspace/output/lfs.jar .
docker rm gerrit-plugins-lfs
