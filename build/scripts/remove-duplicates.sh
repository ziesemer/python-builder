#!/usr/bin/env bash

# Mark A. Ziesemer, www.ziesemer.com - 2025-12-25

set -euo pipefail

cd "$SRC"
find . -xtype f,l -print0 | while IFS= read -rd '' f; do
	if [ -e "$DST/$f" ] || [ -L "$DST/$f" ]; then
		rm -v "$DST/$f"
	fi
done
