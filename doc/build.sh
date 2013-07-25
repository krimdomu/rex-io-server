#!/bin/sh

VER=$1

carton install

mkdir rex-io-server-$VER
mkdir rex-io-server-$VER/doc
cp -R {bin,db,lib,t,local} rex-io-server-$VER
cp doc/rex-io-server.init rex-io-server-$VER/doc

tar czf rex-io-server-$VER.tar.gz rex-io-server-$VER

rm -rf rex-io-server-$VER
