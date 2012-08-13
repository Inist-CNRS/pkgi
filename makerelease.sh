#!/bin/bash

if [ ! $# -eq 1 ] ; then
  echo "Usage $0 [Numero de version]"
  exit 1
fi
VERSION=$1

git fetch --tags
if [ "`git tag -l | grep $VERSION`" != "" ] ; then
  echo "Warning: version $VERISON already exists. Aborting ..."
  exit 2
fi

echo $VERSION > version
git commit -m "Version $VERSION" ./version
git push

git tag -d latest
git push origin :latest
git tag -a -m "Version $VERSION" latest
git tag -a -m "Version $VERSION" $VERSION
git push --tags

echo "Version $VERSION générée (disponible sur github)"
