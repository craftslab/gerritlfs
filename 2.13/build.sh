#!/bin/bash

docker build -t gerrit-plugins-lfs:2.13 .
docker run --name gerrit-plugins-lfs gerrit-plugins-lfs:2.13
docker cp gerrit-plugins-lfs:/workspace/lfs-2.13/buck-out/gen/lfs.jar .
docker rm gerrit-plugins-lfs
