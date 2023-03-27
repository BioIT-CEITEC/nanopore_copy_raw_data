#!/bin/bash

if [ "$1" == "cpu" ]; then
    wget https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy-cpu_6.4.6_linux64.tar.gz
    tar -xf ont-guppy-cpu_6.4.6_linux64.tar.gz
elif [ "$1" == "gpu" ]; then
    wget https://mirror.oxfordnanoportal.com/software/analysis/ont-guppy_6.4.6_linux64.tar.gz
    tar -xf ont-guppy_6.4.6_linux64.tar.gz
else
    echo "Usage: $0 cpu|gpu"
    exit 1
fi