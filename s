#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Dependencies
#  pip install -U selenium==3.3.1
# Usage
#  curl -sSL https://raw.github.com/dosel/t/i/s | python
import time
import os

# Import the Selenium 2 namespace (aka "webdriver")
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

optId = os.environ.get('TEST_ID', '')
if optId != '':
    optId = "%s - " % (optId)

# http://selenium-python.readthedocs.io/api.html#desired-capabilities
# Create a desired capabilities object as a starting point.
browserName = os.environ.get('CAPS_BROWSER_NAME', 'chrome')
caps = {'browserName': browserName}
caps['platform'] = os.environ.get('CAPS_OS_PLATFORM', 'ANY')
caps['version'] = os.environ.get('CAPS_BROWSER_VERSION', '')
caps['tunnel-identifier'] = 'zalenium'
caps['name'] = optId
caps['build'] = browserName
caps['recordVideo'] = 'true'

sel_host = os.environ.get('SEL_HOST', 'localhost')
sel_port = os.environ.get('SEL_PORT', '4444')
sel_url = "http://%s:%s/wd/hub" % (sel_host, sel_port)
myselenium = os.environ.get('SELENIUM_URL', sel_url)
print ("%s%s - Will connect to selenium at %s" % (optId, browserName, myselenium))

# http://selenium-python.readthedocs.org/en/latest/getting-started.html#using-selenium-with-remote-webdriver
driver = webdriver.Remote(command_executor=myselenium, desired_capabilities=caps)
# time.sleep(0.5)

# Test: https://code.google.com/p/chromium/issues/detail?id=519952
pageurl = "http://www.google.com/adwords"
print ("%s%s - Opening page %s" % (optId, browserName, pageurl))
driver.get(pageurl)
# time.sleep(0.5)

print ("%s%s - Current title: %s" % (optId, browserName, driver.title))
print ("%s%s - Asserting 'Google Adwords' in driver.title" % (optId, browserName))
assert "Google AdWords" in driver.title

print ("%s%s - Close driver and clean up" % (optId, browserName))
driver.close()
# time.sleep(0.5)

print ("%s%s - All done. SUCCESS!" % (optId, browserName))
driver.quit()