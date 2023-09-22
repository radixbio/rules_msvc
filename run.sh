#!/usr/bin/env bash
set -x
vagrant up --provider=libvirt win-msvc15
vagrant scp win-msvc15:C:\\vagrant build/
docker build -f Dockerfile.wine -t wine:4.0 --build-arg WINE_VER=4.0 .
docker build -f Dockerfile -t msvc:15 --build-arg WINE_VER=4.0 --build-arg MSVC=15 .
#docker save msvc:15 out.tar
