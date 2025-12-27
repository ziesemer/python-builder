#!/usr/bin/env bash

# Mark A. Ziesemer, www.ziesemer.com - 2025-12-27

set -euo pipefail

start_time=$(date +%s)

docker build \
	--output type=local,dest=./debs \
	.

	# --build-arg OS_DISTRO_BASE="debian:trixie-slim" \
	# --build-arg OS_DISTRO_DISP="Debian Trixie" \
	# --build-arg ARG PYTHON_VER_MAJ_MIN=3.14 \
	# --build-arg PYTHON_VER_MIC=2 \
	# --build-arg FAST_BUILD=true \
	# --build-arg BUILD_NOGIL=false \

end_time=$(date +%s)
elapsed=$(( end_time - start_time ))
echo "Elapsed time: ${elapsed} seconds"
