import libvirt
import sys

conn = libvirt.openReadOnly(None)
if conn == None:
    print 'Failed to open connection to the hypervisor'
    sys.exit(1)


xml_str = conn.getCapabilities()
print xml_str

sys.exit(1)

# try to get dom

try:
    dom0 = conn.lookupByName("Domain-0")
except:
    print 'Failed to find the main domain'
    sys.exit(1)

print "Domain 0: id %d running %s" % (dom0.ID(), dom0.OSType())
print dom0.info()
