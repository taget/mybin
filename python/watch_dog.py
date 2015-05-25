import sys
import time
import logging
import threading
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from watchdog.events import FileModifiedEvent

#
# A frame work to support watch some specify files, dirs
# for useage see register_nodify function
#

class MyEventHandler(FileSystemEventHandler):

    def __init__(self, file_list=[], watch_new=False, suffix=None, call_back=None, lock=None):
        super(FileSystemEventHandler, self).__init__()
        self.file_list = file_list
        self.watch_new = watch_new
        self.suffix = suffix
        self.call_back = call_back
        self.lock = lock

    def _process_call_back(self, path):
        if self.call_back is not None:
            if self.lock is not None:
                print "++++ process_call_back ++++: wait for lock"
                if self.lock.acquire():
                    print "++++ process_call_back ++++ : get lock"
                    self.call_back(path)
                    self.lock.release()
                    print "++++ process_call_back ++++ : release lock"
            else:
                self.call_back(path)

    def on_modified(self, event):
        # watch modified changes including new created files
        if isinstance(event, FileModifiedEvent):
            if event.src_path in self.file_list:
                print "---- on_modified ---- : %s " % event.src_path
                self._process_call_back(event.src_path)
            elif self.watch_new:
                if (self.suffix is None or
                        (self.suffix is not None and
                         event.src_path.endswith(self.suffix))):
                    print "---- on_created ---- : %s " % event.src_path
                    self.file_list.append(event.src_path)
                    self._process_call_back(event.src_path)

    def on_created(self, event):
        # This will be handled by on_modified
        # ignor this to avoid duplicated event.
        pass

    def on_deleted(self, event):
        pass


# register notify
# para: dir: dir to be watched
# para: file_list: file list to be watched, default is [], then will watch new
#       created file.
# para: call_back: call back function when changes was found.
# para: lock: lock semaphore
def register_notify(Dir, file_list=[], watch_new=False, suffix=None,
                    call_back=None, lock=None):
    event_handler = MyEventHandler(file_list=file_list, watch_new=watch_new,
                                   suffix=suffix, call_back=call_back,
                                   lock=lock)
    observer = Observer()
    observer.schedule(event_handler, Dir, recursive=False)
    observer.start()


# globle lock
mylock = threading.Lock()

class Enforcer(object):


    def __init__(self):
        self.Dir = "/home/taget/"
        self.test_content = ""

        # register new notify on /home/taget
        # new added file (*.log) will be watched.
        # call_back function is self.call_back
        register_notify(self.Dir, call_back=self.call_back, watch_new=True,
                        suffix=".log", lock=mylock)

        # register new notify on /home/taget
        # file to be watched is "a.policy"
        register_notify(self.Dir, file_list=["/home/taget/a.policy"],
                        call_back=self.call_back, lock=mylock)

    def call_back(self, file_name):
        print "++++call_back++++:"
        f = open(file_name)
        content = f.read()
        time.sleep(3)
        self.test_content = self.test_content + content
        f.close()

    def test(self):
        print "====testing====: wait lock"
        if mylock.acquire():
            print "====testing====: get lock"
            time.sleep(2)
            print "test_content is :: "
            print self.test_content
            mylock.release()
            print "====testing====: release lock"



if __name__ == "__main__":

    e = Enforcer()
    while True:
        e.test()
