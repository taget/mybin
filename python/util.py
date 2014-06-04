#
#
# @Eli Qiao @ 2014-05-25
#
#
#

import os,glob
import tarfile
import gzip
import string 
import shutil
import traceback
import time
import zipfile

class UtilException(Exception):
    def __init__(self, msg):
        self.msg = msg

# return str of system time
def get_systime():
    return str(time.time())

# remove a file    
def remove_file(path):
    if os.path.exists(path):
        os.remove(path)
        return True
    else:
        raise UtilException('%s is not exists ' % path)
# remove all file in a folder
def remove_files(folder):
    for the_file in os.listdir(folder):
        file_path = os.path.join(folder, the_file)
        remove_file(file_path)
# get FolderSize
def get_FolderSize(folder):
    try:
        total_size = os.path.getsize(folder)
        for item in os.listdir(folder):
            itempath = os.path.join(folder, item)
            if os.path.isfile(itempath):
                total_size += os.path.getsize(itempath)
            elif os.path.isdir(itempath):
                total_size += get_FolderSize(itempath)
        return total_size
    except:
        raise UtilException('%s is not exists ' % folder)
        
# linux
#src : src dir
#dst : dst dir
#zipname : zipfile name

def zip_dir(dirname, zipfilename):
    filelist = []
    if os.path.isfile(dirname):
        filelist.append(dirname)
    else :
        for root, dirs, files in os.walk(dirname):
            for name in files:
                filelist.append(os.path.join(root, name))
        
    zf = zipfile.ZipFile(zipfilename, "w", zipfile.zlib.DEFLATED)
    for tar in filelist:
        arcname = tar[len(dirname):]
        #print arcname
        zf.write(tar,arcname)
    zf.close()



def test():
    print "test"
    print get_FolderSize("/home/pi/images")
    #exit(0)
    try:
        zip_dir("/home/pi/images", "/home/pi/image.tgz")
    except UtilException as e:
        print e.msg
if __name__ == '__main__':
    test()
