#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Dependencies
#  pip install -U selenium
# Usage
#  curl -sSL https://raw.github.com/dosel/t/i/s | python
import time
import os

# Import the Selenium 2 namespace (aka "webdriver")
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

# http://selenium-python.readthedocs.io/api.html#desired-capabilities
# Create a desired capabilities object as a starting point.
caps = DesiredCapabilities.FIREFOX.copy()
caps['platform'] = os.environ.get('CAPS_OS_PLATFORM', '')
caps['version'] = os.environ.get('CAPS_BROWSER_VERSION', '')

sel_host = os.environ.get('SEL_HOST', 'localhost')
sel_port = os.environ.get('SEL_PORT', '4444')
sel_url = "http://%s:%s/wd/hub" % (sel_host, sel_port)
myselenium = os.environ.get('SELENIUM_URL', sel_url)
print ("Will connect to selenium at %s" % myselenium)

# http://selenium-python.readthedocs.org/en/latest/getting-started.html#using-selenium-with-remote-webdriver
driver = webdriver.Remote(command_executor=myselenium, desired_capabilities=caps)
# time.sleep(0.5)

# Test: https://code.google.com/p/chromium/issues/detail?id=519952
pageurl = "http://www.google.com/adwords"
print ("Opening page %s" % pageurl)
driver.get(pageurl)
# time.sleep(0.5)

print ("Current title: %s" % driver.title)
print ("Asserting 'Google Adwords' in driver.title")
assert "Google AdWords" in driver.title

print ("Close driver and clean up")
driver.close()
# time.sleep(0.5)

print ("All done. SUCCESS!")
driver.quit()