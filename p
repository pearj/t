#!/usr/bin/env bash

# With love by team-tip

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Checking dependencies..."

if ! which grep; then
    echo "Please install grep, e.g. brew install grep"
    exit 1
fi

if ! which wc; then
    echo "Please install wc, e.g. brew install wc"
    exit 1
fi

if ! which wget; then
    echo "Please install wget, e.g. brew install wget"
    exit 1
fi

if ! which java; then
    echo "Please install java"
    exit 2
fi

if ! which docker; then
    echo "Please install docker, e.g. brew install docker"
    exit 2
fi

# TODO: Check supported docker range of versions, e.g. >= 1.12.1
#

# Note it doesn't matter if the container named `grid` exists
# `docker ps` will only fail if docker is not running
if ! docker ps -q --filter=name=grid; then
    echo "Docker is installed but doesn't seem to be running properly."
    echo "Make sure docker commands like docker ps work."
    exit 3
fi

# Retry download up to 3 times as network issues tend to break this
docker pull elgalu/selenium:latest || \
docker pull elgalu/selenium:latest || \
docker pull elgalu/selenium:latest

# if [ ! -f "selenium-server-standalone-2.53.1.jar" ]; then
# 	echo "Downloading Selenium..."
# 	wget -nv "https://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.1.jar"
# fi

if [ ! -f "zalenium-0.3.0.jar" ]; then
	echo "Downloading Zalenium..."
	wget -nv "https://github.com/zalando-incubator/zalenium/releases/download/v0.3.0/zalenium-release-v0.3.0.tar.gz"
	echo "Uncompressing Zalenium..."
	tar xzf "zalenium-release-v0.3.0.tar.gz"
	rm "zalenium-release-v0.3.0.tar.gz"
	mv "zalenium-release-v0.3.0"/* .
	rmdir "zalenium-release-v0.3.0"
	ls "zalenium.sh" "zalenium-0.3.0.jar" "selenium-server-standalone-2.53.1.jar"
fi

# Small issue: old docker versions doesn't support docker images {name} -q
# TODO: deploy new version of Zalenium
#
rm zalenium.sh
wget -nv "https://raw.githubusercontent.com/zalando-incubator/zalenium/dockerized/scripts/zalenium.sh"
chmod +x zalenium.sh
sed -i -e 's/${project.build.finalName}/zalenium-0.3.0/g' zalenium.sh

echo -e "\nZalenium is ready. Start with:"
echo -e "\t./zalenium.sh start"
