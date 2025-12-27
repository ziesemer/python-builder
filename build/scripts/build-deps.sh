#!/usr/bin/env bash

# Mark A. Ziesemer, www.ziesemer.com - 2025-12-25

set -euo pipefail

SEP=' '

_setArgs(){
	while [ "${1:-}" != '' ]; do
		case "$1" in
			'--comma')
				SEP=','
				;;
		esac
		shift
	done
}

_setArgs

ALL_PACKAGES=()

add_packages() {
	ALL_PACKAGES+=("$@")
}

# - https://devguide.python.org/getting-started/setup-building/index.html#install-dependencies
add_packages build-essential gdb lcov pkg-config
add_packages libbz2-dev libffi-dev libgdbm-dev libgdbm-compat-dev liblzma-dev
add_packages libncurses5-dev libreadline6-dev libsqlite3-dev libssl-dev
add_packages liblzma-dev tk-dev uuid-dev zlib1g-dev libmpdec-dev libzstd-dev
add_packages inetutils-inetd

# - https://docs.python.org/3.14/using/configure.html
add_packages libexpat1-dev

# - Support for dtrace.
add_packages systemtap-sdt-dev

# - https://docs.python.org/3/whatsnew/changelog.html#id120
#   - gh-99108: Python’s hashlib now unconditionally uses the vendored HACL* library for Blake2.
#       Python no longer accepts libb2 as an optional dependency for Blake2.

if [[ "$SEP" == ',' ]]; then
	(IFS=','; echo "${ALL_PACKAGES[*]}")
else
	echo "${ALL_PACKAGES[*]}"
fi
