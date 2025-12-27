# Python Builder

## Summary

Framework for easily and relatively quickly creating optimized and fully-featured [CPython](https://github.com/python/cpython) Python builds, supporting the latest [Python](https://www.python.org/) versions (3.13, 3.14+) / backports across Debian and Debian-based Linux operating systems including Ubuntu and Raspberry Pi OS.

This is a Docker-based framework for creating builds.
I do not have plans to provide binary output builds at this time.

OS-provided support benefits are utilized where possible, but this project aims to remain as much of a standard / vanilla build of the [original Python source](https://github.com/python/cpython) as possible.
This includes no unexplained patching of the source tree, etc., and no patching at all of the source tree at this time.

Support for [free-threaded Python](https://docs.python.org/3/howto/free-threading-python.html) (no-gil / `python3t`) is optionally provided as a secondary installable package with only the additional needed binaries that appends upon the primary.

Packages are configured to install to `/opt/python/python${PYTHON_VER_MAJ_MIN}/`, e.g. `/opt/python/python3.14/`.

While I've built some of my own Python builds from source since at least Python 3.7 (2018), this is the first that I've tried to formalize this process with these efforts here.
As such, this project and any builds produced from it should be considered experimental.

### Feedback

Any feedback or recommendations to further improve this process are welcome - though especially from anyone involved in upstream packaging (Python, Debian, or Ubuntu maintainers).

Aspects specific to Docker and debuild are probably the most likely areas that could benefit from further efforts.

I'm especially hoping for any improvements that allow for further simplification of this process, and am **not** looking to grow into some of the additional complexities I've observed across most of the [referenced efforts](#referenced-efforts) I included below.

## Features

| Feature | Here | [Python<br/>Source<br/>Default](https://docs.python.org/3/using/configure.html) | [Ubuntu 25.10<br/>Questing Quokka<br/>Python 3.13](https://launchpad.net/ubuntu/questing/+source/python3.13) | [Debian 13<br/>Trixie<br/>Python 3.13](https://packages.debian.org/trixie/python3) |
| --- | --- | --- | --- | --- |
| [`--enable-optimizations`](https://docs.python.org/3/using/configure.html#cmdoption-enable-optimizations)<br/>(Profile Guided Optimizations / PGO) | ✅ | ❌ | ❌ | ❌ |
| [`--with-lto`](https://docs.python.org/3/using/configure.html#cmdoption-with-lto)<br/>(Link Time Optimization / LTO) | ✅ | ❌ | ❌ | ❌ |
| [`--with-system-expat`](https://docs.python.org/3/using/configure.html#cmdoption-with-system-expat))<br/>([Expat XML parser](https://libexpat.github.io/)) | ✅ | ❌ | ✅ | ✅ |
| [`--with-system-libmpdec`](https://docs.python.org/3/using/configure.html#cmdoption-with-system-libmpdec) | ✅ | ✅ | ❌ | ❌ |
| [`--with-dtrace`](https://docs.python.org/3/using/configure.html#cmdoption-with-dtrace) | ✅ | ❌ | ✅ | ✅ |
| [`--enable-shared`](https://docs.python.org/3/using/configure.html#cmdoption-enable-shared) | ❌ | ❌ | ✅ | ✅ |

* Ubuntu 25.10 (Questing Quokka) [Python 3.14](https://launchpad.net/ubuntu/questing/+source/python3.14) (universe) is configured the same as [Python 3.13](https://launchpad.net/ubuntu/questing/+source/python3.13) (main) in respect to the above options.

1. `--with-system-libmpdec` is the Python default since 3.13.
2. DTrace: See also, [Instrumenting CPython with DTrace and SystemTap](https://docs.python.org/3/howto/instrumentation.html).
3. Shared: May revisit, though I haven't seen a need to override this yet.
(`libpythonMAJOR.MINOR.a` and `python.o` are still built and provided.)

The configuration information details (installation paths, configuration variables, etc.) for any Python 3 build can be obtained by running [`sysconfig`](https://docs.python.org/3/library/sysconfig.html#command-line-usage):

```sh
python3 -m sysconfig
```

`CONFIG_ARGS` is likely the most significant for at least any initial comparative reference.

### Dynamically Shared Linked Libraries

I had spent considerable time looking at the different configurations surrounding the use of dynamically-shared linked libraries / dynamic depdendencies (`*.so` files).
Specifically, seeing what [`ldd`](https://manpages.debian.org/trixie/manpages/ldd.1.en.html) reported for each `python3` binary.

* It is important to review not only each `python3` binary, but also each library `.so` file under `lib\python3.*\lib-dynload\` - as each of these then link to further dependencies.
* Adding a `Modules/Setup.local` (next to [`Modules/Setup`](https://github.com/python/cpython/blob/main/Modules/Setup)) can be used to modify various module build options, force them to be built as static vs. shared, or completely disable them, etc.

The build options used here do *not* make use of any of these configuration options, but uses the defaults provided by CPython.

## Build Arguments

* `OS_DISTRO_BASE`:
	* For example, `debian:trixie-slim`.
	* Used to direct which Docker base image to use for the build environment.
* `OS_DISTRO_DISP`:
	* For example, `Debian Trixie`.
	* Used only as the display name to include in the built package description.
* `PYTHON_VER_MAJ_MIN`:
	* For example, `3.14`.
	* Used to direct which Python version to build.
* `PYTHON_VER_MIC`:
	* For example, `2` - as in `3.14.2`.
	* Used to direct which micro / patch version of the above Python version to build.
* `FAST_BUILD`.  Defaults to unset.  If set to `true`:
	* Updates `OPTIMIZATION_FLAGS`:
		* Removes `--enable-optimizations`.
		* Removes `--with-lto`.
		* Adds `--disable-test-modules`.
	* Skips `dh_auto_test`.
* `BUILD_NOGIL`.  Defaults to `true`.  If set to `false`:
	* Skips running separate configure, build, and install steps for a free-threaded Python version.

## Sample Build Times

| [build args](#build-arguments) | Type | Laptop Time | Raspberry Pi 5 Time |
| --- | --- | ---: | ---: |
| `FAST_BUILD=true`<br/>`BUILD_NOGIL=false` | `--no-cache` | 2m:52s | 5m:33s |
| `FAST_BUILD=true`<br/>`BUILD_NOGIL=false`<br/>`PYTHON_VER_MIC=1` | Build another micro version, following the above. | 2m:04s | 3m:47s |
| *(empty)* | Default, full, optimized build, following the above. | 24m:17s | 57m:16s |
| `PYTHON_VER_MIC=1` | Default, full, optimized build of another micro version, following the above. | 21:04s | 56m:55s |

These times:

* Are provided only as a rough approximation of build time requirements.
They are unaveraged, taken from a single run, and measured without experimental controls or adherence to scientific methodology, and should *not* be treated as precise or reproducible benchmarks.
* Were taken on 2025-12-27.
* Assume that the needed Docker base images are already pulled.
Metrics started after running [`docker builder prune -a`](https://docs.docker.com/reference/cli/docker/builder/prune/).

The [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/) is:

* A model B 16 GB Rev 1.1 e04171.
* Using a Samsung 512 GB Pro Ultimate C10/V30/U3/A2 microSDXC memory card ([MB-MY512SA/AM](https://www.samsung.com/us/computing/memory-storage/memory-cards/pro-ultimate-adapter-microsdxc-512gb-mb-my512sa-am/)).
* Running [Raspberry Pi OS](https://www.raspberrypi.com/software/operating-systems/) Debian Trixie (13) 64-bit.

## References

### Referenced Efforts

This effort is inspired by a combination of:

* <https://packages.debian.org/stable/python3>
	* Still publishing only Python 3.13 as of 2025-12-25, when Python 3.14 was released as of 2025-10-07, for example.
* <https://launchpad.net/ubuntu/+source/python3.14>
	* As of 2025-12-25, for Ubuntu 25.10 (Questing Quokka), only has 3.14.0, where 3.14.1 was published on 2025-12-02 and 3.14.2 was published on 2025-12-05.
* <https://github.com/pascallj/python3.13-backport>
	* Latest is only publishing for Debian 12 bookworm, and only for Python 3.13 (not Python 3.14).
	* Has not been updated since 2025-02-10.
* <https://github.com/deadsnakes/py3.14>
	* <https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa>
	* Looks to only be providing releases for Ubuntu LTS versions (22.04 / jammy, 24.04 / noble).

### Build References

* <https://devguide.python.org/getting-started/setup-building/index.html>
* <https://docs.python.org/3/using/configure.html>
* <https://docs.docker.com/build/>
* <https://manpages.debian.org/stable/dh-make/dh_make.1.en.html>
* <https://manpages.debian.org/stable/devscripts/debuild.1.en.html>

### Python Versions

* <https://devguide.python.org/versions/>

## Author

Mark Ziesemer, CISSP, CCSP, CSSLP

* 🌐 <https://www.ziesemer.com>
* 🔗 <https://www.linkedin.com/in/ziesemer/>
