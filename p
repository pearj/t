#!/usr/bin/env bash

# One-liner Zalenium & Docker-selenium (dosel) installer
#-- With love by team-tip

# set -e: exit asap if a command exits with a non-zero status
set -e

# In OSX install gtimeout through `brew install coreutils`
function mtimeout() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        gtimeout "$@"
    else
        timeout "$@"
    fi
}

# Actively waits for Zalenium to fully starts
# you can copy paste this in your Jenkins scripts
WaitZaleniumStarted()
{
    DONE_MSG="Zalenium is now ready!"
    while ! docker logs zalenium | grep "${DONE_MSG}" >/dev/null; do
        echo -n '.'
        sleep 0.2
    done
}
export -f WaitZaleniumStarted

StartZalenium()
{
    CONTAINERS=$(docker ps -a -f name=zalenium -q | wc -l)
    if [ ${CONTAINERS} -gt 0 ]; then
        echo "Removing exited docker-selenium containers..."
        docker rm -f $(docker ps -a -f name=zalenium -q)
    fi

    echo "Starting Zalenium in docker..."

    #TODO: if linux:
    #TODO: if xxxx exists in the hosts the share it
    # mkdir -p ./videos
    # -v ./videos:/home/seluser/videos \
    # --timeZone
    docker run -d -t --name zalenium \
      -p 4444:4444 -p 5555:5555 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /usr/bin/docker:/usr/bin/docker \
      -v /lib/x86_64-linux-gnu/libsystemd-journal.so.0:/lib/x86_64-linux-gnu/libsystemd-journal.so.0:ro \
      -v /lib/x86_64-linux-gnu/libcgmanager.so.0:/lib/x86_64-linux-gnu/libcgmanager.so.0:ro \
      -v /lib/x86_64-linux-gnu/libnih.so.1:/lib/x86_64-linux-gnu/libnih.so.1:ro \
      -v /lib/x86_64-linux-gnu/libnih-dbus.so.1:/lib/x86_64-linux-gnu/libnih-dbus.so.1:ro \
      -v /lib/x86_64-linux-gnu/libdbus-1.so.3:/lib/x86_64-linux-gnu/libdbus-1.so.3:ro \
      -v /lib/x86_64-linux-gnu/libgcrypt.so.11:/lib/x86_64-linux-gnu/libgcrypt.so.11:ro \
      -v /usr/lib/x86_64-linux-gnu/libapparmor.so.1:/usr/lib/x86_64-linux-gnu/libapparmor.so.1:ro \
      -v /usr/lib/x86_64-linux-gnu/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7:ro \
      dosel/zalenium \
      start --chromeContainers 0 \
            --firefoxContainers 0 \
            --maxDockerSeleniumContainers 8 \
            --screenWidth 1920 --screenHeight 1080 \
            --timeZone "$(cat /etc/timezone)" \
            --videoRecordingEnabled false \
            --sauceLabsEnabled false

    if ! mtimeout --foreground "2m" bash -c WaitZaleniumStarted; then
        echo "Zalenium failed to start after 2 minutes, failing..."
        docker logs zalenium
        exit 4
    fi

    echo "Zalenium in docker started!"
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

function usage() {
    echo "Usage:"
    echo ""
    echo "$0"
    echo -e "\t -h --help"
    echo -e "\t -s -> Starts Zalenium after downloading."
    echo -e "\t -u ."
    echo -e "\t --firefoxContainers -> Number of Firefox containers created on startup. Default is 1 when parameter is absent."
    echo -e "\t --maxDockerSeleniumContainers -> Max number of docker-selenium containers running at the same time. Default is 10 when parameter is absent."
    echo -e "\t --sauceLabsEnabled -> Determines if the Sauce Labs node is started. Defaults to 'true' when parameter absent."
    echo -e "\t --videoRecordingEnabled -> Sets if video is recorded in every test. Defaults to 'true' when parameter absent."
    echo -e "\t --screenWidth -> Sets the screen width. Defaults to 1900"
    echo -e "\t --screenHeight -> Sets the screen height. Defaults to 1880"
    echo -e "\t --timeZone -> Sets the time zone in the containers. Defaults to \"Europe/Berlin\""
    echo ""
    echo -e "\t stop"
    echo ""
    echo -e "\t Examples:"
    echo -e "\t - Starting Zalenium with 2 Chrome containers and without Sauce Labs"
    echo -e "\t start --chromeContainers 2 --sauceLabsEnabled false"
    echo -e "\t - Starting Zalenium screen width 1440 and height 810, time zone \"America/Montreal\""
    echo -e "\t start --screenWidth 1440 --screenHeight 810 --timeZone \"America/Montreal\""
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

	if ! docker-compose --version >/dev/null 2>&1; then
		echo "--INFO: docker-compose is not installed"
	else
		# Grab docker-compose version, e.g. "1.9.0"
		DOCKER_COMPOSE_VERSION=$(docker-compose --version | grep -Po '(?<=version )([a-z0-9\.]+)')
		# Check supported docker-compose range of versions, e.g. > 1.7.0
		if ! VersionGt "${DOCKER_COMPOSE_VERSION}" "1.7.0"; then
			echo "Current docker-compose version '${DOCKER_COMPOSE_VERSION}' is not supported by Zalenium"
			if [ "${upgrade_if_needed}" == "true" ]; then
				echo "Will upgarde docker-compose because you passed the 'upd' argument"
				#InstallDockerCompose
			else
				echo "Docker-compose version >= 1.7.1 is required"
				exit 14
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

#----------
# Defaults
#----------
upgrade_if_needed="false"
we_have_sudo="true"
start_it="false"

# Overwrite defaults in certain peculiar environments
if [ ! -z ${TOOLCHAIN_LOOKUP_REGISTRY} ]; then
	upgrade_if_needed="true"
	we_have_sudo="false"
fi

#---------------------
# Parse CLI arguments
#---------------------
while [ "$1" != "" ]; do
    # PARAM="$(echo $1)"
    PARAM="$1"
    case ${PARAM} in
        -h | --help)
            usage
            exit 0
            ;;
        --upgrade_if_needed)
            upgrade_if_needed="true"
            ;;
        --upd)
            upgrade_if_needed="true"
            ;;
        upd)
            upgrade_if_needed="true"
            ;;
        -u)
            upgrade_if_needed="true"
            ;;
        u)
            upgrade_if_needed="true"
            ;;
        no-sudo)
            we_have_sudo="false"
            ;;
        --no-sudo)
            we_have_sudo="false"
            ;;
        --start)
            start_it="true"
            ;;
        start)
            start_it="true"
            ;;
        -s)
            start_it="true"
            ;;
        s)
            start_it="true"
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 10
            ;;
    esac
    shift 1
done

if [ "${upgrade_if_needed}" == "true" ]; then
	checking_and_or_updating="Checking and updating"
else
	checking_and_or_updating="Checking"
fi

CheckDependencies
PullDependencies

if [ "${start_it}" == "true" ]; then
	StartZalenium
fi
