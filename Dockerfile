# Mark A. Ziesemer, www.ziesemer.com - 2025-12-25

ARG \
	OS_DISTRO_BASE="debian:trixie-slim" \
	OS_DISTRO_DISP="Debian Trixie" \
	PYTHON_VER_MAJ_MIN=3.14 \
	PYTHON_VER_MIC=2 \
	FAST_BUILD \
	BUILD_NOGIL=true

FROM ${OS_DISTRO_BASE} AS build-env

ENV \
	DEBIAN_FRONTEND=noninteractive \
	DEBFULLNAME="Builder" \
	DEBEMAIL="builder@localhost" \
	LOGNAME="builder" \
	USER="builder"
WORKDIR /build

COPY --parents build/./scripts/ .

RUN BUILD_DEPS="$(./scripts/build-deps.sh)" \
	&& apt-get update \
	&& apt-get -y install --no-install-recommends \
		${BUILD_DEPS} \
		# - Needed only for building. \
		ca-certificates \
		# - devscripts needed for debuild. \
		wget dh-make devscripts \
		# - Not necessary, handy for debugging. \
		git vim less \
	&& apt-get -y upgrade \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# - This section not necessary, handy for debugging.
RUN git clone 'https://github.com/ziesemer/maz-bash-prompt' \
	&& cat <<'EOF' >> /root/.bashrc

export LS_OPTIONS='--color=auto'
eval "$(export SHELL; dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'

. <(/build/maz-bash-prompt/maz-bash-prompt.sh)
EOF

# Re-declare build args here to avoid invalidating earlier layers.
ARG \
	PYTHON_VER_MAJ_MIN \
	PYTHON_VER_MIC

ENV \
	PYTHON_VER_MAJ_MIN="${PYTHON_VER_MAJ_MIN}" \
	PYTHON_VERSION="${PYTHON_VER_MAJ_MIN}.${PYTHON_VER_MIC}" \
	PYTHON_PREFIX="/opt/python/python${PYTHON_VER_MAJ_MIN}/"

RUN wget -q "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" \
	&& tar -xf "Python-${PYTHON_VERSION}.tgz" \
	&& mv "Python-${PYTHON_VERSION}" "python-${PYTHON_VERSION}"

WORKDIR /build/python-${PYTHON_VERSION}

ARG \
	FAST_BUILD \
	BUILD_NOGIL=true
ENV FAST_BUILD="${FAST_BUILD}" \
	BUILD_NOGIL="${BUILD_NOGIL}"

RUN dh_make --createorig --yes -s -p python${PYTHON_VER_MAJ_MIN}_${PYTHON_VERSION}

ARG OS_DISTRO_DISP
RUN cat <<EOF > debian/control
Source: python${PYTHON_VER_MAJ_MIN}
Section: interpreters
Priority: optional
Maintainer: Mark A. Ziesemer <online@mark.ziesemer.com>
Build-Depends: debhelper (>= 12), debhelper-compat (= 13), $(./scripts/build-deps.sh --comma)
Standards-Version: 4.5.0

Package: python${PYTHON_VER_MAJ_MIN}
Architecture: any
Depends: \${shlibs:Depends}, \${misc:Depends}
Description: Python ${PYTHON_VER_MAJ_MIN} interpreter
 This package provides a custom-built Python ${PYTHON_VER_MAJ_MIN} for ${OS_DISTRO_DISP}, installed in ${PYTHON_PREFIX}.

Package: python${PYTHON_VER_MAJ_MIN}t
Architecture: any
Depends: python${PYTHON_VER_MAJ_MIN} (= \${binary:Version}), \${shlibs:Depends}, \${misc:Depends}
Description: Free-threaded Python ${PYTHON_VER_MAJ_MIN} interpreter
 This package provides the free-threaded (nogil) binaries for a custom-built Python ${PYTHON_VER_MAJ_MIN} for ${OS_DISTRO_DISP}, installed in ${PYTHON_PREFIX}.
EOF

COPY build/debian/rules debian/rules

RUN chmod +x debian/rules \
	&& debuild -ePYTHON_PREFIX -ePYTHON_VER_MAJ_MIN -eFAST_BUILD -eBUILD_NOGIL -us -uc

RUN mkdir -p /build/debs \
	&& cp -pv --reflink=auto /build/*.deb /build/debs

WORKDIR /build
CMD ["/bin/bash"]

FROM scratch
COPY --from=build-env /build/debs /
