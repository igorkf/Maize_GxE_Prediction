#!/usr/bin/env bash

mkdir -p ~/.R
echo "CC = $(which gcc) -fPIC" >> ~/.R/Makevars
echo "CXX17 = $(which g++) -fPIC" >> ~/.R/Makevars
echo "CXX17STD = -std=c++17" >> ~/.R/Makevars
echo "CXX17FLAGS = ${CXX11FLAGS}" >> ~/.R/Makevars