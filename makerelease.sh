#!/bin/sh

if [ ! $# -eq 1 ] ; then
  echo "Usage $0 [Numero de version]"
  exit 1
fi

if [ -w tags/$1 ] ; then
  echo "Warning: version $1 already exists. Aborting ..."
  exit 2
fi

# recuperation des tags
svn co -q --depth=immediates https://subversion.cru.fr/pkgi/tags

# creation du tag
svn cp -q https://subversion.cru.fr/pkgi/trunk tags/$1
echo $1 > tags/$1/version
svn rm tags/$1/makerelease.sh
svn commit tags/$1 -q -m "Version $1"

# generation du tar.gz
svn export -q tags/$1 pkgi
tar czf pkgi-$1.tar.gz pkgi/

# divers nettoyages
rm -rf pkgi/
rm -rf tags/

echo "Release $1 generee"
echo "- le tag $1 a ete cree"
echo "- l'archive pkgi-$1.tar.gz a ete cree"
