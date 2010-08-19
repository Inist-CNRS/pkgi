#!/bin/sh

if [ ! $# -eq 1 ] ; then
  echo "Usage $0 [Numero de version]"
  exit 1
fi

if [ -w tags/$1 ] ; then
  echo "Warning: version $1 already exists. Aborting ..."
  exit 2
fi

# divers nettoyages avant de commencer
rm -rf /tmp/pkgi/
rm -rf /tmp/tags/
OLDDIR=`pwd`
cd /tmp/

# recuperation des tags
echo "Récupération des tags"
svn co --quiet --depth=immediates https://subversion.cru.fr/pkgi/tags

# creation du tag 
echo "Création du tag $1"
svn cp --quiet https://subversion.cru.fr/pkgi/trunk tags/$1
echo $1 > tags/$1/version
svn rm --quiet tags/$1/makerelease.sh
svn commit tags/$1 -q -m "Version $1"

# création du lien symbolique vers la dernière version
echo "Création du tag latest"
svn rm --quiet tags/latest
svn commit tags/latest --quiet -m "Retire le lien vers la dernière version"
svn cp --quiet tags/$1 tags/latest
svn commit tags/latest --quiet -m "Mise à jour du lien vers la nouvelle version ($1)"

# generation du tar.gz
echo "Génération de pkgi-$1.tar.gz"
svn export --quiet tags/$1 pkgi
tar czf $OLDDIR/pkgi-$1.tar.gz pkgi/

# divers nettoyages
echo "Nettoyages"
rm -rf /tmp/pkgi/
rm -rf /tmp/tags/

echo "Release $1 générée"
