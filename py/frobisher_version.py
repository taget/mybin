#!/usr/bin/python

import rpm
import yum
import os
import sys

# rpm list we need to check
rpmlist = ['kernel',
           'libvirt',
           'qemu',
           'kimchi',
           'SLOF',
           'perf',
           'ksm',
           'qemu-common',
           'qemu-guest-agent',
           'qemu-img',
           'qemu-kvm',
           'qemu-kvm-tools',
           'qemu-system-ppc'
]

#repo id we defined in /etc/yum.repos.d/mcp.repo
repofile = '/etc/yum.repos.d/mcp.repo'
repoid = 'frobiser'

if __name__ == '__main__':
	os.system("yum repoinfo frobiser")
	ts = rpm.TransactionSet()
	mi = ts.dbMatch()
	hm = []
	# get installed rpm list, save to hm
	for h in mi:
		if h['name'] in rpmlist:
			hm.append(h)

	# get pkgs frpm frobiser repo, save to pkgs
	yb = yum.YumBase()
	pkgs = yb.pkgSack.returnPackages(repoid=repoid)
	ret = True
	# get current kernel version
	uname_version = os.uname()[2].strip('.ppc64')
	for pkg in pkgs:
		if pkg.name == 'kernel':
			if not (pkg.version + '-' + pkg.release) == \
                                   uname_version:
				print "kernel not match"
				print "current kernel: %s" % uname_version
				print "repo kernel: %s-%s" % \
                                       (pkg.version, pkg.release)
				ret = False
			else:
				print "kernel match"
			continue
		for h in hm:
			if pkg.name == h.name:
				if pkg.version != h.version or \
				pkg.release != h.release:
					print "%s: not match " % (pkg.name)
					print "current %s: %s-%s" % \
                                              (h.name, h.version, h.release)
					print "repo %s: %s-%s" % \
                                              (pkg.name, pkg.version, pkg.release)  
					ret = False
				else:
					print "%s -- match" % (pkg.name)
			else:
				continue
	if ret:
		print "frobisher version match completely!"
		exit(0)
	else:
		print '''frobisher version not match completely!
			run: yum groupremove pbuild
			     yum groupinstall pbuild 
			     and reboot machine!'''
		exit(1)

