from klein import Klein
from twisted.web import server

class Base(object):
  klein = Klein()

#
# Welcome
#
class Welcome(Base):
  greeting : str

  @Base.klein.route("/welcome")
  def welcome(self, request: server.Request):
    self.logger.debug("called 'welcome'")
    return self.greeting
