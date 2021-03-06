#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function
import sys
reload(sys) # Python2.5 初始化后会删除 sys.setdefaultencoding 这个方法，我们需要重新载入
sys.setdefaultencoding('utf-8')


import os
try:
    from urllib import urlencode
except ImportError:
    from urllib.parse import urlencode

try:
    import urllib2 as wdf_urllib
    from cookielib import CookieJar
except ImportError:
    import urllib.request as wdf_urllib
    from http.cookiejar import CookieJar

import re
import time
import xml.dom.minidom
import json
import sys
import math
import subprocess
import ssl
import threading
from threading import Timer


DEBUG = True

CMD_LIST = ('','h', 'help', 'w', 'l', 'timer', 'q', 't')
MSG_TO_SEND  = "我要看唐探11568533"
#MSG_TO_SEND  = "苟富贵，勿相忘"
TIME_LIST =(time.mktime(time.strptime('2016-01-18 11:00:00','%Y-%m-%d %H:%M:%S')),
            time.mktime(time.strptime('2016-01-19 11:00:00','%Y-%m-%d %H:%M:%S')),
            time.mktime(time.strptime('2016-01-20 11:00:00','%Y-%m-%d %H:%M:%S')),
           )

# this list will be run until now > time in list
TIME_LIST = (
#            time.mktime(time.strptime('2016-01-19 9:50:00','%Y-%m-%d %H:%M:%S')),
#            time.mktime(time.strptime('2016-01-19 11:00:00','%Y-%m-%d %H:%M:%S')),
#            time.mktime(time.strptime('2016-01-20 11:00:00','%Y-%m-%d %H:%M:%S')),
           )
# this list will only run once when now == time in list
ONE_TIME = (
#            time.mktime(time.strptime('2016-01-20 10:59:59','%Y-%m-%d %H:%M:%S')),
#            time.mktime(time.strptime('2016-01-19 11:00:00','%Y-%m-%d %H:%M:%S')),
#            time.mktime(time.strptime('2016-01-20 11:00:00','%Y-%m-%d %H:%M:%S')),
           )

MSG_I_UNDERSTAND = {
                    u"你好": "你好！我是乔总的秘书，有什么吩咐，试着说，\"帮助我\" \"求求你\"",
                    "hello": "你好！我是乔总的秘书，有什么吩咐，试着说，\"帮助我\" \"求求你\"",
                    u"求求你": "好的，如果有急事请给我的主人打电话吧 156 118 00665！",
                    u"帮助我":"回复\"请你吃饭\"等友好的语言您将会得到乔总的亲切接待",
                    }


MAX_GROUP_NUM = 35  # 每组人数
INTERFACE_CALLING_INTERVAL = 16  # 接口调用时间间隔, 值设为13时亲测出现"操作太频繁"
MAX_PROGRESS_LEN = 50

QRImagePath = os.path.join(os.getcwd(), 'qrcode.jpg')

tip = 0
uuid = ''

base_uri = ''
redirect_uri = ''

skey = ''
wxsid = ''
wxuin = ''
pass_ticket = ''
deviceId = 'e000000000000001'

_r = 0

BaseRequest = {}

ContactList = []
ContactList_detail = {}
User_detail = {}
My = []
SyncKey = ''
SyncKey_List = []

#threading_group
tg = {}

# new msg comming ?

New_msg = False

try:
    xrange
    range = xrange
except:
    # python 3
    pass


def getRequest(url, data=None):
    try:
        data = data.encode('utf-8')
    except:
        pass
    finally:
        return wdf_urllib.Request(url=url, data=data)

def getUUID():
    global uuid

    url = 'https://login.weixin.qq.com/jslogin'
    params = {
        'appid': 'wx782c26e4c19acffb',
        'fun': 'new',
        'lang': 'zh_CN',
        '_': int(time.time()),
    }

    request = getRequest(url=url, data=urlencode(params))
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')

    # print(data)

    # window.QRLogin.code = 200; window.QRLogin.uuid = "oZwt_bFfRg==";
    regx = r'window.QRLogin.code = (\d+); window.QRLogin.uuid = "(\S+?)"'
    pm = re.search(regx, data)

    code = pm.group(1)
    uuid = pm.group(2)

    if code == '200':
        return True

    return False


def showQRImage():
    global tip

    url = 'https://login.weixin.qq.com/qrcode/' + uuid
    params = {
        't': 'webwx',
        '_': int(time.time()),
    }

    request = getRequest(url=url, data=urlencode(params))
    response = wdf_urllib.urlopen(request)

    tip = 1

    f = open(QRImagePath, 'wb')
    f.write(response.read())
    f.close()

    if sys.platform.find('darwin') >= 0:
        subprocess.call(['open', QRImagePath])
    elif sys.platform.find('linux') >= 0:
        subprocess.call(['xdg-open', QRImagePath])
    else:
        os.startfile(QRImagePath)

    print('请使用微信扫描二维码以登录')


def waitForLogin():
    global tip, base_uri, redirect_uri

    url = 'https://login.weixin.qq.com/cgi-bin/mmwebwx-bin/login?tip=%s&uuid=%s&_=%s' % (
        tip, uuid, int(time.time()))

    request = getRequest(url=url)
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')

    # print(data)

    # window.code=500;
    regx = r'window.code=(\d+);'
    pm = re.search(regx, data)

    code = pm.group(1)

    if code == '201':  # 已扫描
        print('成功扫描,请在手机上点击确认以登录')
        tip = 0
    elif code == '200':  # 已登录
        print('正在登录...')
        print(data)
        regx = r'window.redirect_uri="(\S+?)";'
        pm = re.search(regx, data)
        redirect_uri = pm.group(1) + '&fun=new'
        base_uri = redirect_uri[:redirect_uri.rfind('/')]

        # closeQRImage
        if sys.platform.find('darwin') >= 0:  # for OSX with Preview
            os.system("osascript -e 'quit app \"Preview\"'")
    elif code == '408':  # 超时
        pass
    # elif code == '400' or code == '500':

    return code


def login():
    global skey, wxsid, wxuin, pass_ticket, BaseRequest, _r

    request = getRequest(url=redirect_uri)
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')

    # print(data)

    '''
        <error>
            <ret>0</ret>
            <message>OK</message>
            <skey>xxx</skey>
            <wxsid>xxx</wxsid>
            <wxuin>xxx</wxuin>
            <pass_ticket>xxx</pass_ticket>
            <isgrayscale>1</isgrayscale>
        </error>
    '''

    doc = xml.dom.minidom.parseString(data)
    root = doc.documentElement

    for node in root.childNodes:
        if node.nodeName == 'skey':
            skey = node.childNodes[0].data
        elif node.nodeName == 'wxsid':
            wxsid = node.childNodes[0].data
        elif node.nodeName == 'wxuin':
            wxuin = node.childNodes[0].data
        elif node.nodeName == 'pass_ticket':
            pass_ticket = node.childNodes[0].data

    # print('skey: %s, wxsid: %s, wxuin: %s, pass_ticket: %s' % (skey, wxsid,
    # wxuin, pass_ticket))

    if not all((skey, wxsid, wxuin, pass_ticket)):
        return False

    BaseRequest = {
        u'Uin': int(wxuin),
        u'Sid': wxsid,
        u'Skey': skey,
        u'DeviceID': deviceId,
    }

    _r = int(float(time.time())/1000)

    return True


def webwxinit():

    url = base_uri + \
        '/webwxinit?pass_ticket=%s&skey=%s&r=%s' % (
            pass_ticket, skey, int(time.time()))
    params = {
        'BaseRequest': BaseRequest
    }

    request = getRequest(url=url, data=json.dumps(params))
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    data = response.read()

    if DEBUG:
        f = open(os.path.join(os.getcwd(), 'webwxinit.json'), 'wb')
        f.write(data)
        f.close()

    data = data.decode('utf-8', 'replace')

    # print(data)

    global ContactList, My, SyncKey, SyncKey_List
    dic = json.loads(data)
    ContactList = dic['ContactList']
    My = dic['User']

    SyncKeyList = []
    SyncKey_List = dic['SyncKey']
    for item in dic['SyncKey']['List']:
        SyncKeyList.append('%s_%s' % (item['Key'], item['Val']))
    SyncKey = '|'.join(SyncKeyList)

    ErrMsg = dic['BaseResponse']['ErrMsg']
    if DEBUG:
        print("Ret: %d, ErrMsg: %s" % (dic['BaseResponse']['Ret'], ErrMsg))

    Ret = dic['BaseResponse']['Ret']
    if Ret != 0:
        return False

    return True


def webwxgetotccontact():

    url = base_uri + '/webwxbatchgetcontact?type=ex&r=%s&pass_ticket=%s' % (int(time.time()), pass_ticket)
    params = {
        'BaseRequest': BaseRequest,
        "Count": 1,
        "List": [{"UserName": u"@@f2748eacce47b073bc298687bfccd8ae46db9a90e4d0d72db57fac48e41c6543", "EncryChatRoomId": ""}]
        }
    print(url)
    print(params)
    json_obj = json.dumps(params)#.encode('utf-8')#ensure_ascii=False防止中文乱码
    #request = wdf_urllib.Request(url=url, data=json_obj)
    #print(json_obj)
    request = getRequest(url=url, data=json_obj)
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    print (response.read())
    #data = response.read().decode('utf-8', 'replace')
    #print(data)

def webwxgetcontact(all=False):

    url = base_uri + '/webwxgetcontact?pass_ticket=%s&skey=%s&r=%s' % (pass_ticket, skey, int(time.time()))

    request = getRequest(url=url)
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    data = response.read()

    if DEBUG:
        f = open(os.path.join(os.getcwd(), 'webwxgetcontact.json'), 'wb')
        f.write(data)
        f.close()

    # print(data)
    data = data.decode('utf-8', 'replace')
    dic = json.loads(data)
    MemberList = dic['MemberList']

    if all is True:
        return MemberList

    # 倒序遍历,不然删除的时候出问题..
    SpecialUsers = ["newsapp", "fmessage", "filehelper", "weibo", "qqmail", "tmessage", "qmessage", "qqsync", "floatbottle", "lbsapp", "shakeapp", "medianote", "qqfriend", "readerapp", "blogapp", "facebookapp", "masssendapp",
                    "meishiapp", "feedsapp", "voip", "blogappweixin", "weixin", "brandsessionholder", "weixinreminder", "wxid_novlwrv3lqwv11", "gh_22b87fa7cb3c", "officialaccounts", "notification_messages", "wxitil", "userexperience_alarm"]
    for i in range(len(MemberList) - 1, -1, -1):
        Member = MemberList[i]
        if Member['VerifyFlag'] & 8 != 0:  # 公众号/服务号
            MemberList.remove(Member)
        elif Member['UserName'] in SpecialUsers:  # 特殊账号
            MemberList.remove(Member)
        elif Member['UserName'].find('@@') != -1:  # 群聊
            MemberList.remove(Member)
#        elif Member['UserName'] == My['UserName']:  # 自己
#            MemberList.remove(Member)

    return MemberList


def createChatroom(UserNames):
    # MemberList = []
    # for UserName in UserNames:
        # MemberList.append({'UserName': UserName})
    MemberList = [{'UserName': UserName} for UserName in UserNames]

    url = base_uri + \
        '/webwxcreatechatroom?pass_ticket=%s&r=%s' % (
            pass_ticket, int(time.time()))
    params = {
        'BaseRequest': BaseRequest,
        'MemberCount': len(MemberList),
        'MemberList': MemberList,
        'Topic': '',
    }

    request = getRequest(url=url, data=json.dumps(params))
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')

    # print(data)

    dic = json.loads(data)
    ChatRoomName = dic['ChatRoomName']
    MemberList = dic['MemberList']
    DeletedList = []
    for Member in MemberList:
        if Member['MemberStatus'] == 4:  # 被对方删除了
            DeletedList.append(Member['UserName'])

    ErrMsg = dic['BaseResponse']['ErrMsg']
    if DEBUG:
        print("Ret: %d, ErrMsg: %s" % (dic['BaseResponse']['Ret'], ErrMsg))

    return ChatRoomName, DeletedList


def deleteMember(ChatRoomName, UserNames):
    url = base_uri + \
        '/webwxupdatechatroom?fun=delmember&pass_ticket=%s' % (pass_ticket)
    params = {
        'BaseRequest': BaseRequest,
        'ChatRoomName': ChatRoomName,
        'DelMemberList': ','.join(UserNames),
    }

    request = getRequest(url=url, data=json.dumps(params))
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')

    # print(data)

    dic = json.loads(data)
    ErrMsg = dic['BaseResponse']['ErrMsg']
    Ret = dic['BaseResponse']['Ret']
    if DEBUG:
        print("Ret: %d, ErrMsg: %s" % (Ret, ErrMsg))

    if Ret != 0:
        return False

    return True


def addMember(ChatRoomName, UserNames):
    url = base_uri + \
        '/webwxupdatechatroom?fun=addmember&pass_ticket=%s' % (pass_ticket)
    params = {
        'BaseRequest': BaseRequest,
        'ChatRoomName': ChatRoomName,
        'AddMemberList': ','.join(UserNames),
    }

    request = getRequest(url=url, data=json.dumps(params))
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')

    # print(data)

    dic = json.loads(data)
    MemberList = dic['MemberList']
    DeletedList = []
    for Member in MemberList:
        if Member['MemberStatus'] == 4:  # 被对方删除了
            DeletedList.append(Member['UserName'])

    ErrMsg = dic['BaseResponse']['ErrMsg']
    if DEBUG:
        print("Ret: %d, ErrMsg: %s" % (dic['BaseResponse']['Ret'], ErrMsg))

    return DeletedList


# use this to keep alive with server
# selector:6 new msg comming.
# ..
def syncCheck():
    url = base_uri + '/synccheck?'
#    url = "https://webpush.weixin.qq.com/cgi-bin/mmwebwx-bin/synccheck?"
    global _r
    _r = _r + 1
    r_time =int(float(time.time())/1000)
    params = {
        'skey': BaseRequest['Skey'],
        'sid': BaseRequest['Sid'],
        'uin': BaseRequest['Uin'],
        'deviceId': BaseRequest['DeviceID'],
        'synckey': SyncKey,
        'f': 'json',
        'r' : r_time,
        '_': _r
    }

#    print(url)
#    print(params)
#    print('++body======+')
#    print(body)
#
    request = getRequest(url=url + urlencode(params))
#    print(request.get_full_url())
    try:
        response = wdf_urllib.urlopen(request)
        data = response.read().decode('utf-8', 'replace')
    except Exception:
        print("EOF error!")
        pass

    # window.synccheck={retcode:"0",selector:"2"}
    # FIXME(eliqiao):
    # data is unicode string
#    print(data)
    json_obj = json.loads(data)
    print(json_obj)
#    print(json_obj['retcode'])
    if json_obj['retcode'] != '0':
        raise
    else:
        if json_obj['selector'] == '0':
            return False
        else:
            # FIXME (eliqiao) there is one case that selector = 3, what's mean？
            return json_obj['selector']

    return False


def log_msg(msg, f=None, date=None):

    now_time = time.strftime("%H:%M:%S", time.localtime())

    if f:
        file_name = f
    else:
        if date is not None:
            timeArray = time.localtime(date)
        else:
            timeArray = time.localtime()
        file_name = time.strftime("%Y-%m-%d", timeArray)

    with open(file_name, 'a') as fh:
        fh.write(now_time + ':' + msg)

def getMsg(only_friend=True, log_to_file=False):
    url = base_uri + '/webwxsync?'

    global SyncKey_List
    r = int(time.time())
    params = {
        'sid': BaseRequest['Sid'],
        'skey': BaseRequest['Skey'],
        'pass_ticket': pass_ticket,
    }

#    print(params)

    body = {
        'BaseRequest': BaseRequest,
        'SyncKey': SyncKey_List,
        'rr': -r
    }
#    print(body)
    request = getRequest(url=url + urlencode(params), data=json.dumps(body))
#    print(request.get_full_url())

    try:
        response = wdf_urllib.urlopen(request)
        data = response.read().decode('utf-8', 'replace')
    #
    #FIXME there will be SSL EOF exception
    except Exception:
        msg_to_file = u'EOF error!\n'
        pass

    json_obj = json.loads(data)
    Baseresp = json_obj['BaseResponse']

    msg_to_file = ""

    if Baseresp['Ret'] != 0:
        msg_to_file = u"接受消息异常!\n"
        if log_to_file:
            log_msg(msg_to_file)
        else:
            print(msg_to_file)
        return

    msg_count = json_obj['AddMsgCount']
    if msg_count > 0:
        msg_to_file = u"收到[%d]条消息:\n" % msg_count

    msg_list = json_obj['AddMsgList']
    sync_key = json_obj['SyncKey']
#    print(sync_key)
    # NOTE(eliqiao): update SyncKey_List to indicate you have read this MSG.
    SyncKey_List = sync_key

    for msg in msg_list:
        ret_msg = True
        from_user_name = msg['FromUserName']
        nick_name = None
        print(msg['FromUserName'])
        if msg['FromUserName'] in User_detail:
            nick_name = User_detail[msg['FromUserName']]
        else:
            if from_user_name != My['UserName']:
                msg_to_file += u"忽略了来自%s的消息，可能它是公众号或者群\n" % msg['FromUserName']
                ret_msg = False

        # text message
        # 1 text message/location
        # 3 image
        # 34 voice
        # 10000 money
        # 51 自己给自己发的同步消息？
        print(msg['MsgType'])
        if msg['MsgType'] == 1:
            msg_to_file += u"%s说: %s\n" % (nick_name, msg['Content'])
            if msg['Content'] in MSG_I_UNDERSTAND and ret_msg:
                sendMsg(My['UserName'], nick_name, MSG_I_UNDERSTAND[msg['Content']])
                msg_to_file += u"回复%s了:%s" % (nick_name, MSG_I_UNDERSTAND[msg['Content']])
            #FIXME follow logic is not correct
      #      else:
      #          if nick_name != My['UserName']:
      #              sendMsg(My['UserName'], nick_name, "收到！")
        # Money
        elif msg['MsgType'] == 10000:
            msg_to_file += u"收到%s发来的红包" % (nick_name or from_user_name)
            sendMsg(My['UserName'], My['NickName'], "收到红包")
            #TODO(eliqiao): reminder and send message to rush for money
            print(msg)
        elif msg['MsgType'] == 51:
            pass
        elif msg['MsgType'] == 3:
            msg_to_file += u"%s发了张图片\n" % nick_name
            pass
        else:
            msg_to_file += u"%s可能说了段语音\n" % nick_name
            print(msg)

    if log_to_file:
        if len(msg_to_file) > 0:
            log_msg(msg_to_file)
    else:
        print(msg_to_file)

def run_sync():

    while True:
        if syncCheck():
            getMsg(log_to_file=True)
        time.sleep(5)

def run_job(tm, name, msg=None, user_list=[], interval=10, sleep_interval=60):

    def send_to_users(msg):
        for u in user_list:
            sendMsg(My['UserName'], u, msg)

    while True:
        now = time.time()
        time_str =  time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(now))
        if msg == None:
            msg = "Yes?"
        #msg = "%s -[%s]" % (msg, time_str)
        if name == 'always':
            if now <= tm:
                secs = tm - now
                msg_append = " %f秒后" % secs
                msgs = msg + msg_append
                send_to_users(msgs)
                time.sleep(sleep_interval)
            else:
                return
        if name == 'one':
            if now <= tm:
                # this could be 0.02?
                time.sleep(interval)
            else:
                # send 45 time
                for i in range(45):
                    send_to_users(msg)
                    #time.sleep(0.01)
                return

def set_timer():
    print("will start timer after 0s")
    #NOTE(eliqiao) we will get a exception if we lost the authorize from wxserver
    #we need to notify master process to exit here
    Timer(0, run_sync,()).start()

def set_jobs():

    #user_list = ['Eli Qiao', '英特尔中国']
    user_list = ['英特尔中国']
    #user_list = ['吴德新']
    #user_list = ['Eli Qiao']
    for tm in TIME_LIST:
        print("set job for %f", tm)
        Timer(0, run_job, (tm, "always", MSG_TO_SEND, user_list, 1, 120)).start()

    for tm in ONE_TIME:
        print("set one time job for %f", tm)
        Timer(0, run_job, (tm, "one", MSG_TO_SEND, user_list, 0.02)).start()


def main():

    try:
#        ssl._create_default_https_context = ssl._create_unverified_context

        opener = wdf_urllib.build_opener(
            wdf_urllib.HTTPCookieProcessor(CookieJar()))
        wdf_urllib.install_opener(opener)
    except:
        raise
        pass

    if not getUUID():
        print('获取uuid失败')
        return

    showQRImage()
    time.sleep(1)

    while waitForLogin() != '200':
        pass

    os.remove(QRImagePath)

    if not login():
        print('登录失败')
        return

    if not webwxinit():
        print('初始化失败')
        return

    # setup a timer to add
    # set_timer()
    webwxgetotccontact()
    return
    MemberList = webwxgetcontact(all=True)

    MemberCount = len(MemberList)
    for m in MemberList:
        ContactList_detail[m['NickName'].encode('utf-8')] = m['UserName']
        User_detail[m['UserName']] = m['NickName'].encode('utf-8')
        if m['NickName'] == "OTC在职":
            print(m)


    # setup timers for run specify message sending task

    return

    set_jobs()

    print("输入命令")

    my_name = My["NickName"].encode('utf-8')
    l = raw_input(my_name + '@:')

    while cmd_line(l):
        l = raw_input(my_name + '@:')
        pass

    return
    #TODO(eliqiao): move follow logic to another method

    ChatRoomName = ''
    result = []
    d = {}
    for Member in MemberList:
        d[Member['UserName']] = (Member['NickName'].encode(
            'utf-8'), Member['RemarkName'].encode('utf-8'))
    print('开始查找...')
    group_num = int(math.ceil(MemberCount / float(MAX_GROUP_NUM)))
    for i in range(0, group_num):
        UserNames = []
        for j in range(0, MAX_GROUP_NUM):
            if i * MAX_GROUP_NUM + j >= MemberCount:
                break
            Member = MemberList[i * MAX_GROUP_NUM + j]
            UserNames.append(Member['UserName'])

        # 新建群组/添加成员
        if ChatRoomName == '':
            (ChatRoomName, DeletedList) = createChatroom(UserNames)
        else:
            DeletedList = addMember(ChatRoomName, UserNames)

        DeletedCount = len(DeletedList)
        if DeletedCount > 0:
            result += DeletedList

        # 删除成员
        deleteMember(ChatRoomName, UserNames)

        # 进度条
        progress_len = MAX_PROGRESS_LEN
        progress = '-' * progress_len
        progress_str = '%s' % ''.join(
            map(lambda x: '#', progress[:(progress_len * (i + 1)) / group_num]))
        print(''.join(
            ['[', progress_str, ''.join('-' * (progress_len - len(progress_str))), ']']))
        print('新发现你被%d人删除' % DeletedCount)
        for i in range(DeletedCount):
            if d[DeletedList[i]][1] != '':
                print(d[DeletedList[i]][0] + '(%s)' % d[DeletedList[i]][1])
            else:
                print(d[DeletedList[i]][0])

        if i != group_num - 1:
            print('正在继续查找,请耐心等待...')
            # 下一次进行接口调用需要等待的时间
            time.sleep(INTERFACE_CALLING_INTERVAL)
    # todo 删除群组

    print('\n结果汇总完毕,20s后可重试...')
    resultNames = []
    for r in result:
        if d[r][1] != '':
            resultNames.append(d[r][0] + '(%s)' % d[r][1])
        else:
            resultNames.append(d[r][0])

    print('---------- 被删除的好友列表(共%d人) ----------' % len(result))
    # 过滤emoji
    resultNames = map(lambda x: re.sub(r'<span.+/span>', '', x), resultNames)
    if len(resultNames):
        print('\n'.join(resultNames))
    else:
        print("无")
    print('---------------------------------------------')


def BatGetcontact():
    pass

# 根据指定的Username发消息
def sendMsg(MyUserName, ToNickName, msg):

    if ToNickName not in ContactList_detail:
        if ToNickName == My["NickName"]:
            ToUserName = My['UserName']
        else:
            print("User [%s] not found" % ToNickName)
            return 1
    else:
        ToUserName = ContactList_detail[ToNickName]
    url = base_uri + '/webwxsendmsg?pass_ticket=%s' % (pass_ticket)
#    import ipdb
#    ipdb.set_trace()
    # we decode str to unicode since params are all unicode
    msg = msg.decode('utf-8')
    params = {
        u"BaseRequest": BaseRequest,
        u"Msg": {u"Type": 1, u"Content": msg, u"FromUserName": MyUserName, u"ToUserName": ToUserName},
    }
    json_obj = json.dumps(params,ensure_ascii=False)#.encode('utf-8')#ensure_ascii=False防止中文乱码
    request = wdf_urllib.Request(url=url, data=json_obj)
    request = getRequest(url=url, data=json_obj)
    request.add_header('ContentType', 'application/json; charset=UTF-8')
    response = wdf_urllib.urlopen(request)
    data = response.read().decode('utf-8', 'replace')
    #print(data)
    #print("Msg send to %s - %s", ToNickName, msg)


def cmd_line(line):

    print("-" * 80)
    def help():
        print("I am shell WX client(cool bee le!)")
        print("h: for help")
        print("q: for quit")
        print("w: for send msg")
        print("t: for testing")
        print("timer: for set a timer to send msg to some one")

    if line not in CMD_LIST:
        print("ERROR! command %s not supported" % line)
        help()
        return 1

    if line == 't':
        if syncCheck():
            getMsg()

    if line == 'h':
        help()
        return 1
    if line == 'q':
        print("bye ~")
        return 0
    if line == 'w': # sned msg
        name = raw_input("输入要发送的对象：")
        content = raw_input("输入要发送的内容：")
        sendMsg(My['UserName'], name, content)
        return 1
    if line == 'l':
        print("Friends list: ----------")
        for u in ContactList_detail:
            print(u)
    if line == 'timer':
        name = raw_input("输入要发送的对象：")
        content = raw_input("输入要发送的内容：")
        sendMsg(My['UserName'], name, content)
        return 1

    print("Try again!")
    return 1
# windows下编码问题修复
# http://blog.csdn.net/heyuxuanzee/article/details/8442718


class UnicodeStreamFilter:

    def __init__(self, target):
        self.target = target
        self.encoding = 'utf-8'
        self.errors = 'replace'
        self.encode_to = self.target.encoding

    def write(self, s):
        if type(s) == str:
            s = s.decode('utf-8')
        s = s.encode(self.encode_to, self.errors).decode(self.encode_to)
        self.target.write(s)

if sys.stdout.encoding == 'cp936':
    sys.stdout = UnicodeStreamFilter(sys.stdout)

if __name__ == '__main__':

    print('开始')
    main()
    print('结束')
