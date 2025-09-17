
from twisted.internet import defer
from twisted.logger import LogLevel

from iso.pipe_factory import PipeFactory, eb_crash, cb_log_result, cb_exit

class DirectoryHash(object):
  cmds = [
    """ /usr/bin/find {basedir} -type f -not -path "*/__pycache__/*" -print """,
    """ /usr/bin/xargs -I% {hasher} %""",
    """ /usr/bin/sort """,
    """ {hasher} """
  ]

  @classmethod
  def md5(cls, basedir, reactor = None) -> defer.Deferred:
    return cls.hash(basedir, "/usr/bin/md5sum")

  @classmethod
  def sha256(cls, basedir, reactor = None) -> defer.Deferred:
    return cls.hash(basedir, "/usr/bin/sha256sum")

  @classmethod
  def hash(cls, basedir, hasher, reactor = None) -> defer.Deferred:
    kw = dict(basedir = basedir, hasher = hasher )
    cmds = [ cmd.format(**kw) for cmd in cls.cmds ]    

    if reactor is None:
      reactor = globals()['reactor']   

    return PipeFactory(reactor, cmds).run()

#
# main
#
if __name__ == '__main__':
  from iso.context_logger import initialize_logging, ContextLogger
  from twisted.internet import reactor, interfaces

  observer = initialize_logging(LogLevel.debug, {})

  logger = ContextLogger()
  logger.observer = observer

  d3 = DirectoryHash.md5('./vmfs')
  d3.addCallback(cb_log_result, logger, level = LogLevel.info, format = "directory hash (md5): {result}")
  d3.addErrback(eb_crash)

  d4 = DirectoryHash.sha256('./vmfs')
  d4.addCallback(cb_log_result, logger, level = LogLevel.info, format = "directory hash (sha256): {result}")
  d4.addErrback(eb_crash)

  dl = defer.DeferredList([d3, d4])
  dl.addCallbacks(cb_exit, eb_crash, (reactor,))

  reactor.run()
