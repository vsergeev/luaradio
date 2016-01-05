#!/bin/sh

set -e

gcc -O3 -c -Wall -Werror -fpic minivolk.c
gcc -shared -o minivolk.so minivolk.o
