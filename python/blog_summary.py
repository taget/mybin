#!/usr/bin/env python
#encoding=utf-8
import re
import sys
import time
import urllib2
import string

from bs4 import BeautifulSoup


# url =
# https://www.ibm.com/developerworks/community/blogs/5144904d-5d75-45ed-9d2b-cf1754ee936a/?sortby=0&maxresults=30&lang=en
# class min-h4-padding min-entry lotusFirstCell entryContentContainerTD blogsWrapText
#  --class min-h4 <a id, href=> 标题 </a>
#  --lotusMeta min-blogdetail
#  -- -- <span role="listitem"
#  -- -- -- <time datetime="">
#  -- -- <span role="listitem"  访问量 </span>
# we need to get 标题  and 访问量              	


# Visits (221)
# return 221
def get_visit(str_visit):
	len_of_str = len(str_visit)
	tmp = str_visit[8 : len_of_str - 1]
	return int(tmp)

def get_summary(url):
	
	try:
		response = urllib2.urlopen(url)
		html_doc = response.read()
	except:
		print "invalid url"
		return
	blog_details = []
	
	soup = BeautifulSoup(html_doc)

	# get blogs entries
	blogs = soup.find_all("td", class_="min-h4-padding min-entry lotusFirstCell entryContentContainerTD blogsWrapText")
	
	icount  = 0
	total_visits = 0
	for blog in blogs:
		# blog name
		blog_info = blog.h4.a
		blog_name = blog_info.string.strip()
		blog_url = blog_info.get('href')
		blogdetail = blog.find_next("div", class_="lotusMeta min-blogdetail")
		# FIX me : stupid
		next1 = blogdetail.find_next("span",role="listitem")
		next2  = next1.find_next("span",role="listitem")
		visits  = next2.find_next("span",role="listitem")
		# in case we get a None
		if not visits.string:
			visits = visits.find_next("span",role="listitem")
		blog_visit = visits.string.strip()
		icount += 1
		ivisit = get_visit(blog_visit)
		total_visits += ivisit
		print "[%d] <%s>,%s,%s"%(icount, blog_name, blog_url,\
		                                 blog_visit)
		print "----------------------"
	print "total [%d] paper" % icount
	print "total visits [%d]" % total_visits
	print "average visits [%d]" % (total_visits/icount)
	#listitmes =  soup.find_all("span", role="listitem")
	
	#print listitmes[0]
	#for l in listitmes:
	#	print l

if __name__ == "__main__":
	url = raw_input("Please input target url: ")
	html = get_summary(url)
	#get_content(edit_url)
