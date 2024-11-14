#!/bin/bash -l

set -e
mkdir -p $1

curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$1" sh
