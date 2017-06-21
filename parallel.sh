#!/usr/bin/env bash

# Usage
#  bash parallel.sh chrome 2
#  bash parallel.sh firefox 2
#  bash parallel.sh hybrid 2
#  VIDEO=true bash parallel.sh hybrid 2

set -e

echoerr() { printf "%s\n" "$*" >&2; }

# print error and exit
die () {
  echoerr "ERROR: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "3"
  errnum=${2-3}
  ( ps aux | grep -i "python x chrome" | grep -v grep | awk '{print $2}' | xargs kill >/dev/null 2>&1 ) || true
  ( ps aux | grep -i "python x firefox" | grep -v grep | awk '{print $2}' | xargs kill >/dev/null 2>&1 ) || true
  ( ps aux | grep parallel.sh | grep -v grep | awk '{print $2}' | xargs kill >/dev/null 2>&1 ) || true
  ( ps aux | grep -i "python x chrome" | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 ) || true
  ( ps aux | grep -i "python x firefox" | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 ) || true
  ( ps aux | grep parallel.sh | grep -v grep | awk '{print $2}' | xargs kill -9 >/dev/null 2>&1 ) || true
  exit $errnum
}

TEST_TYPE=$1
TOT_THREADS=$2

[ "${TEST_TYPE}" == "" ] && die "1st param must be one of 'chrome', 'firefox', 'hybrid'"

[ "${TOT_THREADS}" == "" ] && die "2nd param should be the amount of parallel tests to run!"
[ $((TOT_THREADS%2)) -eq 0 ] || die "The amount of threads needs to be an even number!"

function get_mock_port() {
  echo $(docker inspect -f='{{(index (index .NetworkSettings.Ports "8080/tcp") 0).HostPort}}' adwords_mock)
}

function mock_is_running() {
  docker inspect -f {{.State.Running}} adwords_mock | grep true
}

export MOCK_SERVER_PORT=8080

if mock_is_running >/dev/null 2>&1; then
  docker stop adwords_mock || true
fi

docker rm adwords_mock || true
docker run -d --name=adwords_mock -e MOCK_SERVER_PORT \
  -p $MOCK_SERVER_PORT:$MOCK_SERVER_PORT elgalu/google_adwords_mock

export MOCK_SERVER_HOST=`docker inspect -f='{{.NetworkSettings.IPAddress}}' adwords_mock`

if [ "${MOCK_SERVER_HOST}" == "" ]; then
  die "Failed to grab IP from adwords_mock"
fi

MOCK_URL="http://localhost:${MOCK_SERVER_PORT}/adwords"
echo "Mock server should be found at ${MOCK_URL}"

while ! curl -s "${MOCK_URL}"; do
  echo -n '.'
  sleep 0.2
done

if [ "${TEST_TYPE}" == "hybrid" ]; then
    LOOP_END_NUM=$(($TOT_THREADS/2-1))
else
    LOOP_END_NUM=$(($TOT_THREADS-1))
fi

echo "Mock server is running. Will now run ${1} threads. LOOP_END_NUM=${LOOP_END_NUM}"

for i in `seq 0 $LOOP_END_NUM`; do
    if [ "${TEST_TYPE}" == "chrome" ] || [ "${TEST_TYPE}" == "hybrid" ]; then
        (
            if [ "${TEST_TYPE}" == "hybrid" ]; then
                chrome_thread_num="$((i*2+1))"
            else
                chrome_thread_num="$((i+1))"
            fi

            for j in `seq 1 5`; do
                test_id_chrome=thread-${chrome_thread_num}_seq-$j
                TEST_ID=$test_id_chrome python x chrome || \
                TEST_ID=$test_id_chrome python x chrome || \
                    die "Test failed on chrome $test_id_chrome"
            done
        ) &
    fi

    if [ "${TEST_TYPE}" == "firefox" ] || [ "${TEST_TYPE}" == "hybrid" ]; then
        (
            if [ "${TEST_TYPE}" == "hybrid" ]; then
                firefox_thread_num="$((i*2+2))"
            else
                firefox_thread_num="$((i+1))"
            fi

            for j in `seq 1 5`; do
                test_id_firefox=thread-${firefox_thread_num}_seq-$j
                TEST_ID=$test_id_firefox python x firefox || \
                TEST_ID=$test_id_firefox python x firefox || \
                    die "Test failed on firefox $test_id_firefox"
            done
        ) &
    fi
done

wait
