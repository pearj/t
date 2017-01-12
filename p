#!/usr/bin/env bash

# One-liner Zalenium & Docker-selenium (dosel) installer
#-- With love by team-tip

# set -e: exit asap if a command exits with a non-zero status
set -e

# In OSX install gtimeout through
#   brew install coreutils
function mtimeout() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        gtimeout "$@"
    else
        timeout "$@"
    fi
}

function please_install_gnu_grep() {
    echo "GNU grep is not installed, please install with:"
    echo "  brew tap homebrew/dupes"
    echo "  brew install grep --with-default-names"
    echo ""
    exit 16
}

# In OSX install GNU grep through
#   brew tap homebrew/dupes
#   brew install grep --with-default-names
#   /usr/local/Cellar/grep/*/bin/grep --version
function set_mgrep() {
    if [ "$(uname -s)" != 'Darwin' ]; then
        M_GREP="grep"
    else
        if grep --version >/dev/null; then
            if grep --version | grep GNU >/dev/null; then
                # All good here, we can use this default grep.
                M_GREP="grep"
            else
                # Looks like BSD grep is installed so try GNU
                if /usr/local/Cellar/grep/*/bin/grep --version >/dev/null; then
                    # Found GNU grep installed
                    M_GREP="/usr/local/Cellar/grep/*/bin/grep"
                else
                    # Will need to install GNU grep
                    please_install_gnu_grep
                fi
            fi
        else
            # No grep found in the path, try Cellar
            if /usr/local/Cellar/grep/*/bin/grep --version >/dev/null; then
                # Found GNU grep installed
                M_GREP="/usr/local/Cellar/grep/*/bin/grep"
            else
                # Will need to install GNU grep
                please_install_gnu_grep
            fi
        fi
    fi
}
export -f set_mgrep
set_mgrep

# In OSX install GNU gsort through
#   brew install coreutils
function set_msort() {
    if [ "$(uname -s)" = 'Darwin' ]; then
        M_SORT="gsort"
    else
        M_SORT="sort"
    fi
}
export -f set_msort
set_msort

# Actively waits for Zalenium to fully starts
# you can copy paste this in your Jenkins scripts
WaitZaleniumStarted()
{
    set_mgrep

    DONE_MSG="Zalenium is now ready!"
    while ! docker logs zalenium | ${M_GREP} "${DONE_MSG}" >/dev/null; do
        echo -n '.'
        sleep 0.2
    done
}
export -f WaitZaleniumStarted

EnsureCleanEnv()
{
    CONTAINERS=$(docker ps -a -f name=zalenium_ -q | wc -l)
    if [ ${CONTAINERS} -gt 0 ]; then
        echo "Removing exited docker-selenium containers..."
        docker rm -f $(docker ps -a -f name=zalenium_ -q)
    fi
}

StartZalenium()
{
    CONTAINERS=$(docker ps -a -f name=zalenium -q | wc -l)
    if [ ${CONTAINERS} -gt 0 ]; then
        echo "Removing exited docker-selenium containers..."
        docker rm -f $(docker ps -a -f name=zalenium -q)
    fi

    # Set Zalenium config
    #  e.g. DOCKER_VER_MAJ_MIN=1.11
    #  e.g. DOCKER_VER_MAJ_MIN=1.12
    #  e.g. DOCKER_VER_MAJ_MIN=1.13
    DOCKER_VER_MAJ_MIN=$(docker --version | ${M_GREP} -Po '(?<=version )([a-z0-9]+\.[a-z0-9]+)')
    Z_DOCKER_OPTS=""
    Z_START_OPTS=""

    if [ -f /usr/bin/docker ]; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /usr/bin/docker:/usr/bin/docker"
    else
        # This should only be necessary in docker native for OSX
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -e DOCKER=${DOCKER_VER_MAJ_MIN}"
    fi

    if [ -f /etc/timezone ]; then
        Z_START_OPTS="${Z_START_OPTS} --timeZone \"$(cat /etc/timezone)\""
        # TODO: else: Figure out how to get timezone in OSX
    fi

    if ls /lib/x86_64-linux-gnu/libsystemd-journal.so.0 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /lib/x86_64-linux-gnu/libsystemd-journal.so.0:/lib/x86_64-linux-gnu/libsystemd-journal.so.0:ro"
    fi

    if ls /lib/x86_64-linux-gnu/libcgmanager.so.0 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /lib/x86_64-linux-gnu/libcgmanager.so.0:/lib/x86_64-linux-gnu/libcgmanager.so.0:ro"
    fi

    if ls /lib/x86_64-linux-gnu/libnih.so.1 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /lib/x86_64-linux-gnu/libnih.so.1:/lib/x86_64-linux-gnu/libnih.so.1:ro"
    fi

    if ls /lib/x86_64-linux-gnu/libnih-dbus.so.1 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /lib/x86_64-linux-gnu/libnih-dbus.so.1:/lib/x86_64-linux-gnu/libnih-dbus.so.1:ro"
    fi

    if ls /lib/x86_64-linux-gnu/libdbus-1.so.3 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /lib/x86_64-linux-gnu/libdbus-1.so.3:/lib/x86_64-linux-gnu/libdbus-1.so.3:ro"
    fi

    if ls /lib/x86_64-linux-gnu/libgcrypt.so.11 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /lib/x86_64-linux-gnu/libgcrypt.so.11:/lib/x86_64-linux-gnu/libgcrypt.so.11:ro"
    fi

    if ls /usr/lib/x86_64-linux-gnu/libapparmor.so.1 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /usr/lib/x86_64-linux-gnu/libapparmor.so.1:/usr/lib/x86_64-linux-gnu/libapparmor.so.1:ro"
    fi

    if ls /usr/lib/x86_64-linux-gnu/libltdl.so.7 >/dev/null 2>&1; then
        Z_DOCKER_OPTS="${Z_DOCKER_OPTS} -v /usr/lib/x86_64-linux-gnu/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7:ro"
    fi

    echo "Starting Zalenium in docker..."
    docker run -d -t --name zalenium \
      -p 4444:4444 -p 5555:5555 ${Z_DOCKER_OPTS} \
      -e BUILD_URL \
      -e SAUCE_USERNAME \
      -e SAUCE_ACCESS_KEY \
      -e TESTINGBOT_SECRET \
      -e TESTINGBOT_KEY \
      -e BROWSER_STACK_USER \
      -e BROWSER_STACK_KEY \
      -v /var/run/docker.sock:/var/run/docker.sock \
      dosel/zalenium:${zalenium_tag} \
      start --chromeContainers 1 \
            --firefoxContainers 1 \
            --maxDockerSeleniumContainers 8 \
            --screenWidth 1920 --screenHeight 1080 ${Z_START_OPTS} \
            --videoRecordingEnabled false \
            --sauceLabsEnabled false \
            --browserStackEnabled false \
            --testingBotEnabled false \
            --startTunnel false

    if ! mtimeout --foreground "2m" bash -c WaitZaleniumStarted; then
        echo "Zalenium failed to start after 2 minutes, failing..."
        docker logs zalenium
        exit 4
    fi

    # Below export is useless if this is run in a separate shell
    export SEL_HOST=$(docker inspect -f='{{.NetworkSettings.IPAddress}}' zalenium)
    export SEL_PORT="4444"
    export SELENIUM_URL="http://${SEL_HOST}:${SEL_PORT}/wd/hub"

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
    test "$(printf '%s\n' "$@" | ${M_SORT} -V | head -n 1)" != "$1";
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
        echo "Please install test"
        echo "  brew install coreutils"
        exit 1
    fi

    if ! which printf >/dev/null; then
        echo "Please install printf"
        echo "  brew install coreutils"
        exit 2
    fi

    if ! ${M_SORT} --version >/dev/null; then
        echo "Please install ${M_SORT} (GNU sort)"
        echo "  brew install coreutils"
        exit 3
    fi

    if ! ${M_GREP} --version >/dev/null; then
        please_install_gnu_grep
    fi

    if ! which wc >/dev/null; then
        echo "Please install wc"
        echo "  brew install coreutils"
        exit 5
    fi

    if ! which head >/dev/null; then
        echo "Please install head"
        echo "  brew install coreutils"
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

    if ! mtimeout --version >/dev/null; then
        echo "Please install GNU timeout"
        echo "  brew install coreutils"
        exit 10
    fi

    if ! docker --version >/dev/null; then
        echo "Please install docker, e.g. brew install docker"
        exit 11
    fi

    # Grab docker version, e.g. "1.12.3"
    DOCKER_VERSION=$(docker --version | ${M_GREP} -Po '(?<=version )([a-z0-9\.]+)')
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
        DOCKER_COMPOSE_VERSION=$(docker-compose --version | ${M_GREP} -Po '(?<=version )([a-z0-9\.]+)')
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

    if ! ls /var/run/docker.sock >/dev/null; then
        echo "ERROR: Zalenium needs /var/run/docker.sock but couldn't find it!"
        exit 15
    fi

    echo "Done ${checking_and_or_updating} dependencies."
}

function PullDependencies() {
    # Retry pulls up to 3 times as networks are known to be unreliable

    # https://github.com/zalando/zalenium
    docker pull dosel/zalenium:${zalenium_tag} || \
    docker pull dosel/zalenium:${zalenium_tag} || \
    docker pull dosel/zalenium:${zalenium_tag}

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
stop_it="false"
zalenium_tag="latest"

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
        --stop)
            stop_it="true"
            ;;
        stop)
            stop_it="true"
            ;;
        3)
            echo "Checking last pushed Zalenium for Selenium 3 ..."
            zalenium_tag=$(curl -sSL 'https://registry.hub.docker.com/v2/repositories/dosel/zalenium/tags' | jq -r '."results"[]["name"]' | ${M_GREP} -E "^3.*" | head -1)
            echo "Will use Zalenium tag: ${zalenium_tag}"
            ;;
        2)
            echo "Checking last pushed Zalenium for Selenium 2 ..."
            zalenium_tag=$(curl -sSL 'https://registry.hub.docker.com/v2/repositories/dosel/zalenium/tags' | jq -r '."results"[]["name"]' | ${M_GREP} -E "^2.*" | head -1)
            echo "Will use Zalenium tag: ${zalenium_tag}"
            ;;
        3*)
            zalenium_tag="$1"
            echo "Will use Zalenium tag: ${zalenium_tag}"
            ;;
        2*)
            zalenium_tag="$1"
            echo "Will use Zalenium tag: ${zalenium_tag}"
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 10
            ;;
    esac
    shift 1
done

if [ "${stop_it}" == "true" ]; then
    echo "Stopping..."
    docker stop zalenium >/dev/null 2>&1 || true
    docker rm zalenium >/dev/null 2>&1 || true
    EnsureCleanEnv
    echo "Zalenium stopped!"
    exit 0
fi

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
