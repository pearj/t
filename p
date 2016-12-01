#!/usr/bin/env bash

# One-liner Zalenium & Docker-selenium (dosel) installer
#-- With love by team-tip

# set -e: exit asap if a command exits with a non-zero status
set -e

#--------------------------------------------------------
# Grab params
#--------------------------------------------------------
if [ "$1" == "upd" ] || [ "$2" == "upd" ]; then
	upgrade_if_needed="true"
else
	upgrade_if_needed="false"
fi

if [ "$1" == "no-sudo" ] || [ "$2" == "no-sudo" ]; then
	we_have_sudo="false"
else
	we_have_sudo="true"
fi

# Overwrite defaults in certain peculiar environments
if [ ! -z ${TOOLCHAIN_LOOKUP_REGISTRY} ]; then
	upgrade_if_needed="true"
	we_have_sudo="false"
fi

if [ "${upgrade_if_needed}" == "true" ]; then
	checking_and_or_updating="Checking and updating"
else
	checking_and_or_updating="Checking"
fi
#--------------------------------------------------------

function Main() {
	CheckDependencies
	PullDependencies
}

# In OSX install gtimeout through `brew install coreutils`
function mtimeout() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        gtimeout "$@"
    else
        timeout "$@"
    fi
}

function InstallDockerCompose() {
	DOCKER_COMPOSE_VERSION="1.9.0"
	PLATFORM=`uname -s`-`uname -m`
	url="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${PLATFORM}"
	curl -ssL "${url}" >docker-compose
	chmod +x docker-compose

	if [ "${we_have_sudo}" == "true" ]; then
		sudo rm -f /usr/bin/docker-compose
		sudo rm -f /usr/local/bin/docker-compose
		sudo mv docker-compose /usr/local/bin
		docker-compose --version
	else
		./docker-compose --version
	fi
}

# VersionGt tell if the 1st argument version is greater than the 2nd
#   VersionGt "1.12.3" "1.11"   #=> exit 0
#   VersionGt "1.12.3" "1.12"   #=> exit 0
#   VersionGt "1.12.3" "1.13"   #=> exit 1
#   VersionGt "1.12.3" "1.12.3" #=> exit 1
function VersionGt() {
	test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

function CheckDependencies() {
	# TODO: Only check upon new Zalenium versions
	echo -n "${checking_and_or_updating} dependencies... "

	if ! which test >/dev/null; then
		echo "Please install test, e.g. brew install test"
		exit 1
	fi

	if ! which printf >/dev/null; then
		echo "Please install printf, e.g. brew install printf"
		exit 2
	fi

	if ! sort --version >/dev/null; then
		echo "Please install sort, e.g. brew install sort"
		exit 3
	fi

	if ! grep --version >/dev/null; then
		echo "Please install grep, e.g. brew install grep"
		exit 4
	fi

	if ! wc --version >/dev/null; then
		echo "Please install wc, e.g. brew install wc"
		exit 5
	fi

	if ! head --version >/dev/null; then
		echo "Please install head, e.g. brew install head"
		exit 6
	fi

	if ! perl --version >/dev/null; then
		echo "Please install perl, e.g. brew install perl"
		exit 7
	fi

	if ! wget --version >/dev/null; then
		echo "Please install wget, e.g. brew install wget"
		exit 8
	fi

	if ! timeout --version >/dev/null; then
		if [ "$(uname -s)" = 'Darwin' ]; then
			if ! gtimeout --version >/dev/null; then
				echo "Please install gtimeout, e.g. brew install coreutils"
				exit 9
			fi
		else
			echo "Please install GNU timeout"
			exit 10
		fi
	fi

	if ! docker --version >/dev/null; then
		echo "Please install docker, e.g. brew install docker"
		exit 11
	fi

	# Grab docker version, e.g. "1.12.3"
	DOCKER_VERSION=$(docker --version | grep -Po '(?<=version )([a-z0-9\.]+)')
	# Check supported docker range of versions, e.g. > 1.11.0
	if ! VersionGt "${DOCKER_VERSION}" "1.11.0"; then
		echo "Current docker version '${DOCKER_VERSION}' is not supported by Zalenium"
		echo "Docker version >= 1.11.1 is required"
		exit 12
	fi

	# Note it doesn't matter if the container named `grid` exists
	# `docker ps` will only fail if docker is not running
	if ! docker ps -q --filter=name=grid >/dev/null; then
		echo "Docker is installed but doesn't seem to be running properly."
		echo "Make sure docker commands like 'docker ps' work."
		exit 13
	fi

	if ! docker-compose --version >/dev/null; then
		echo "--INFO: docker-compose is not installed"
	else
		# Grab docker-compose version, e.g. "1.9.0"
		DOCKER_COMPOSE_VERSION=$(docker-compose --version | grep -Po '(?<=version )([a-z0-9\.]+)')
		# Check supported docker-compose range of versions, e.g. > 1.8.0
		if ! VersionGt "${DOCKER_COMPOSE_VERSION}" "1.8.0"; then
			echo "Current docker-compose version '${DOCKER_COMPOSE_VERSION}' is not supported by Zalenium"
			if [ "${upgrade_if_needed}" == "true" ]; then
				echo "Will upgarde docker-compose because you passed the 'upd' argument"
				InstallDockerCompose
			else
				echo "Docker version >= 1.8.1 is required"
				exit 13
			fi
		fi
	fi

	echo "Done ${checking_and_or_updating} dependencies."
}

function PullDependencies() {
	# Retry pulls up to 3 times as networks are known to be unreliable

	# https://github.com/zalando-incubator/zalenium
	docker pull dosel/zalenium:latest || \
	docker pull dosel/zalenium:latest || \
	docker pull dosel/zalenium:latest

	# https://github.com/elgalu/docker-selenium
	docker pull elgalu/selenium:latest || \
	docker pull elgalu/selenium:latest || \
	docker pull elgalu/selenium:latest
}

Main
