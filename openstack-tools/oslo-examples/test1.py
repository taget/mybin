
class BBase(object):
    def __init_(self):
        pass

class Base(BBase):

    def __init__(self, coe):
        self.coe = coe
        super(Base, self).__init__()

    def get_coe(self):
        print self.coe


class C(Base):

    def __init__(self):
        cc = super(C, self)
        import ipdb
        ipdb.set_trace()
        super(C, self).__init__("swarm")


c = C()
c.get_coe()
