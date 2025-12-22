#!/bin/usr/env sh
curl --location https://github.com/raysan5/raylib/releases/download/5.5/raylib-5.5_linux_amd64.tar.gz --output raylib.tar.gz
tar xzf raylib.tar.gz  
mv raylib-5.5_linux_amd64 ./raylib
