#!/bin/sh
set -e
cd "$(dirname "$0")/../src"
fpc -O3 -Xs olms.pas && mv -f olms ../olms
fpc -O3 -Xs config_demo.pas && mv -f config_demo ../config
echo "Built: olms, config (Linux x86-64)"
