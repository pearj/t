#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Dependencies
#  pip install -U selenium==3.3.1
# Usage
#  curl -sSL https://raw.github.com/dosel/t/i/s | python
import time
import os
import datetime

# Import the Selenium 2 namespace (aka "webdriver")
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

# http://selenium-python.readthedocs.io/api.html#desired-capabilities
# Create a desired capabilities object as a starting point.
browserName = os.environ.get('CAPS_BROWSER_NAME', 'chrome')
browserVersion = os.environ.get('CAPS_BROWSER_VERSION', '')

# Group tests by `build`
buildId = "%s%s" % (os.environ.get('JOB_NAME', ''), os.environ.get('BUILD_NUMBER', ''))
if buildId == '':
    buildId = 'zalenium-build'

# Within `build` identify one test by `name`
nameId = os.environ.get('TEST_ID', 'test-adwords')

# Have a long Id for the log outpus
longId = "%s - %s - %s%s" % (buildId, nameId, browserName, browserVersion)

width = os.environ.get('SCREEN_WIDTH','1024')
height = os.environ.get('SCREEN_HEIGHT','768')

# Build the capabilities
caps = {'browserName': browserName}
caps['platform'] = os.environ.get('CAPS_OS_PLATFORM', 'ANY')
caps['version'] = browserVersion
# caps['tunnelIdentifier'] = os.environ.get('TUNNEL_ID', 'zalenium')
caps['tunnel-identifier'] = os.environ.get('TUNNEL_ID', 'zalenium')
caps['screenResolution'] = "%sx%s" % (width, height)
caps['name'] = nameId
caps['build'] = buildId
caps['recordVideo'] = 'true'

sel_host = os.environ.get('SEL_HOST', 'localhost')
sel_port = os.environ.get('SEL_PORT', '4444')
sel_url = "http://%s:%s/wd/hub" % (sel_host, sel_port)
myselenium = os.environ.get('SELENIUM_URL', sel_url)
print ("%s %s - Will connect to selenium at %s" % (datetime.datetime.utcnow(), longId, myselenium))

# http://selenium-python.readthedocs.org/en/latest/getting-started.html#using-selenium-with-remote-webdriver
driver = webdriver.Remote(command_executor=myselenium, desired_capabilities=caps)
# time.sleep(0.5)

# Test: https://code.google.com/p/chromium/issues/detail?id=519952
pageurl = "http://www.google.com/adwords"
print ("%s %s - Opening page %s" % (datetime.datetime.utcnow(), longId, pageurl))
driver.get(pageurl)

# Set location top left and size to max allowed on the container
driver.set_window_position(0, 0)
driver.set_window_size(width, height)

print ("%s %s - Current title: %s" % (datetime.datetime.utcnow(), longId, driver.title))
print ("%s %s - Asserting 'Google Adwords' in driver.title" % (datetime.datetime.utcnow(), longId))
assert "Google AdWords" in driver.title

print ("%s %s - Close driver and clean up" % (datetime.datetime.utcnow(), longId))
driver.close()

print ("%s %s - All done. SUCCESS!" % (datetime.datetime.utcnow(), longId))
driver.quit()