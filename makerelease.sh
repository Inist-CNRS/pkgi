#!/bin/bash

if [ ! $# -eq 1 ] ; then
  echo "Usage $0 [Numero de version]"
  exit 1
fi
VERSION=$1

git pull --tags
if [ "`git tag -l | grep $VERSION`" != 0 ] ; then
  echo "Warning: version $VERISON already exists. Aborting ..."
  exit 2
fi

git tag -d latest
git push origin :latest
git tag -a -m "Version $VERSION" latest
git tag -a -m "Version $VERSION" $VERSION
git push --tags

echo "Version $VERSION générée (disponible sur github)"
