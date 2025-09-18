from zope.interface import Interface, implementer

from twisted.application import service
from twisted.python.failure import Failure
from twisted.internet import (
  defer,
  endpoints,
  protocol
)
from twisted.logger import LogLevel
from twisted.protocols import basic
from twisted.python import components
from twisted.web import server

from iso.callbacks import (
  cb_exit,
  cb_log_result,
  eb_crash
)

from iso.context_logger import (
  ContextLogger,
  initialize_logging
)

from iso.directory_hash import DirectoryHash
from iso.self_extractor import SelfExtractor

#
# Netcat Request
#   $ printf "md5 ./isofs\n" | nc -C localhost 8120
#

class NetcatRequestProtocol(basic.LineReceiver):
  def lineReceived(self, request):
    self.factory.logger.debug("received: {r}", r = request)

    d = self.factory.handle_request( request.decode() )
    d.addCallbacks(self._cb_request, self._eb_request)
    d.addCallbacks(self._cb_lose_connection, eb_crash)
    d.addCallback(cb_log_result, format = "finished lineReceived deferred")

  def _cb_request(self, value):
    self.transport.write(value + b"\n")

  def _cb_lose_connection(self, _):
    self.transport.loseConnection()

  def _eb_request(self, failure):
    self.factory.logger.error("{f}", f = str(failure))
    self.transport.write(b"unknown error\n")

class NetcatRequestFactory(protocol.ServerFactory):
  protocol  = NetcatRequestProtocol
  logger    = ContextLogger()

  def handle_request(self, request : str)  -> defer.Deferred:
    cmdargs = request.split(maxsplit = 1)
    cmd     = cmdargs[0].lower()
    args    = cmdargs[1:]
    method_name = f"cmd_{cmd}"
    d = defer.Deferred()

    try:
      m = getattr(self, method_name)
      d = m(*args)

    except AttributeError as e:
      d = defer.succeed(f"unsupported method: {cmd}".encode('utf8'))

    except TypeError as e:
      self.logger.info("{e}", e = str(e))
      d = defer.succeed(f"syntax error: {request}".encode('utf8'))

    except Exception as e:      
      d = defer.fail(e)

    return d

#
# DirectoryHash componentization
#
class IDirectoryHashFactory(Interface):
  def cmd_md5(self, dirname):
      """
      syntax: md5 dirname
      """

  def cmd_sha256(self, dirname):
      """
      syntax: sha256 dirname
      """

class IDirectoryHashService(Interface):
  def getDirectoryHashMD5(self, dirpath):
    pass

  def getDirectoryHashSHA256(self, dirpath):
    pass

@implementer(IDirectoryHashFactory)
class DirectoryHashFactoryFromService(NetcatRequestFactory):
  def __init__(self, service):
    self.service = service

  def cmd_md5(self, dirname):
    return self.service.getDirectoryHashMD5(dirname)

  def cmd_sha256(self, dirname):
    return self.service.getDirectoryHashSHA256(dirname)

#
# SelfExtractor componentization
#
class ISelfExtractorFactory(Interface):
  def cmd_pack(self, dirname):
    """
    syntax: pack dirname
    """

class ISelfExtractorService(Interface):
  def getSelfExtractor(self, dirpath):
    pass    

@implementer(ISelfExtractorFactory)
class SelfExtractorFromService(NetcatRequestFactory):
  def __init__(self, service):
    self.service = service

  def cmd_pack(self, dirpath):
    return self.service.getSelfExtractor(dirpath)

#
# register adapters
#
components.registerAdapter(DirectoryHashFactoryFromService, IDirectoryHashService, IDirectoryHashFactory)
components.registerAdapter(SelfExtractorFromService, ISelfExtractorService, ISelfExtractorFactory)

#
# IsoUtilityService
#   - This is the primary service we're providing.
#
@implementer(IDirectoryHashService, ISelfExtractorService)
class IsoUtilityService(service.Service):
  def __init__(self):
    self._transient = set()

  def getDirectoryHashMD5(self, dirpath) -> defer.Deferred:
    return DirectoryHash.md5(dirpath)

  def getDirectoryHashSHA256(self, dirpath) -> defer.Deferred:
    return DirectoryHash.sha256(dirpath)

  def getSelfExtractor(self, dirpath) -> defer.Deferred:
    self_extractor = SelfExtractor("./templates", "install.sh.j2")
    self._transient.add(self_extractor)

    d = self_extractor.generate(dirpath)
    d.addCallbacks(self._cb_object_cleanup, eb_crash, (self_extractor,))

    return d

  def _cb_object_cleanup(self, result, obj):
    self._transient.remove(obj)
    return result


#
# script/main
#
if __name__ == '__main__':
  from twisted.internet import reactor

  initialize_logging(LogLevel.debug, {})

  s = IsoUtilityService()

  endpoint = endpoints.serverFromString(reactor, "tcp:8120")
  endpoint.listen( IDirectoryHashFactory(s) )

  endpoint = endpoints.serverFromString(reactor, "tcp:8121")
  endpoint.listen( ISelfExtractorFactory(s) )


  reactor.run()
