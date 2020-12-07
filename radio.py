#!/usr/bin/env python2

import urllib2
import re
import httplib
import time
import os
from subprocess import call


test_mode = False

if test_mode:
	os.chdir(os.path.realpath(__file__))
	goz_test_file = "test.html"
	html = open(goz_test_file).read()
else:
	os.chdir(os.path.realpath(__file__))
	goz_url = "http://www.radiobeograd.rs/index.php?option=com_content&task=view&id=29671&Itemid=335"
	response = urllib2.urlopen(goz_url)
	html = response.read()


# print html
linkovi = list(set([i for i in re.findall(r'href="(?P<Str>download/Emisije/gozba/gozba\d+?\.mp3)"', html)]))
# print linkovi
# exit()

download_linkovi = []

for link in linkovi:
	conn = httplib.HTTPConnection("www.radiobeograd.rs")
	try:
		conn.request("HEAD", '/'+link)
		res = conn.getresponse()
		# print res.status, res.reason
		datum = time.strptime(res.getheader('last-modified'), "%a, %d %b %Y %H:%M:%S %Z")
		fajl = "gozba-%s.mp3" % time.strftime('%y-%m-%d', datum)

		download_linkovi.append(" wget -c http://www.radiobeograd.rs/%s -O dow/%s " % (link, fajl))

	except urllib2.URLError, e:
		print 1
		print e.code
		print e.read()

exec_str =  " && ".join(download_linkovi)
os.system(exec_str)

