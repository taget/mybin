#!/usr/bin/python

import urllib2
from urllib2 import Request, urlopen, URLError, HTTPError  
import time
import sys
import os

import thread
import threading
from HTMLParser import HTMLParser

from htmlentitydefs import name2codepoint
      
class MyHTMLparser(HTMLParser):
	"""
	"""
	def __init__(self):
		self.file_list = []
		HTMLParser.__init__(self)
	def handle_starttag(self, tag, attrs):
		print "Start tag:", tag
		for attr in attrs:
			print "     attr:", attr
		# get a href = xxx
		# put xxx to a file list
		if tag == 'a' :#and attrs[0][1].find("log"):
			if attrs[0][1].find("html"):
				self.file_list.append(attrs[0][1])
			
	def handle_endtag(self, tag):
		print "End tag  :", tag
		
	def handle_data(self, data):
		print "Data     :", data

	def handle_comment(self, data):
		print "Comment  :", data
		
	def handle_entityref(self, name):
		c = unichr(name2codepoint[name])
		print "Named ent:", c
		
	def handle_charref(self, name):
		if name.startswith('x'):
			c = unichr(int(name[1:], 16))
		else:
			c = unichr(int(name))
		print "Num ent  :", c
		
	def handle_decl(self, data):
		print "Decl     :", data
		
	def getresult(self):
		"""
		return a file_list 
		"""
		return self.file_list
   
def test():  
	request = 'http://ltcphx.austin.ibm.com/meetings/kvmscrum/2013/'
	try:
		response = urllib2.urlopen(request)
		data = response.read()
	except HTTPError, e:  
		print("The server couldn't fulfill the request.")
		print('Error code: ', e.code)
		return
	except URLError, e:  
		print('We failed to reach a server.')  
		print('Reason: ', e.reason)
		return 
	#print data
	parser = MyHTMLparser()
	parser.feed(data)
	file_list =  parser.getresult()
	
	for f in file_list:
		try:
			file_path = request + f
			print file_path
			reponse = urllib2.urlopen(file_path)
			print reponse.read()
		except HTTPError, e:
			print e.reason
	return data
   

if __name__ == '__main__':
    #a = Plugin()
    #a.form()
    #time.sleep(2)
	test()
