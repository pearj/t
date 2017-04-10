## Zalenium one-liner installer

    curl -sSL https://raw.githubusercontent.com/dosel/t/i/p | bash

## Install and start

    curl -sSL https://raw.githubusercontent.com/dosel/t/i/p | bash -s start

## Install and start with latest Selenium 3

    curl -sSL https://raw.githubusercontent.com/dosel/t/i/p | bash -s 3 start

## Install and start with latest Selenium 2

    curl -sSL https://raw.githubusercontent.com/dosel/t/i/p | bash -s 2 start

## Install and start a specific version

    curl -sSL https://raw.githubusercontent.com/dosel/t/i/p | bash -s 3.0.1a start

## Tiny smoke python selenium test

    pip install --user --upgrade selenium==3.3.1
    curl -sSL https://raw.github.com/dosel/t/i/s | python

## Cleanup

    curl -sSL https://raw.githubusercontent.com/dosel/t/i/p | bash -s stop
