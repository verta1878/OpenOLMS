#!/bin/sh
set -e
cd "$(dirname "$0")/../src"
fpc -O3 -Xs olms.pas && mv -f olms ../olms
fpc -O3 -Xs config.pas && mv -f config ../config
echo "Built: olms, config (Linux x86-64)"
