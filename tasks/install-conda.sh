#!/bin/bash -l

set -e

mkdir -p $1
cd $1

# Install conda
wget "https://repo.anaconda.com/miniconda/Miniconda3-$2.sh" -O miniconda.sh
bash miniconda.sh -b -u -p .
rm miniconda.sh
bin/conda init bash
