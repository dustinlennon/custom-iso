import sys
import os

from typing import Optional

from twisted.logger import (
  FileLogObserver,
  FilteringLogObserver,
  globalLogBeginner,
  ILogObserver,
  Logger,
  LogLevelFilterPredicate,
  LogLevel
)

from twisted.python.compat import currentframe

from iso.formatter import formatEvent

#
# Initialize logging
#

def initialize_logging(
    default_loglevel : LogLevel,
    ns_map : dict
  ) -> ILogObserver:

  filter = LogLevelFilterPredicate(default_loglevel)
  for ns,level in ns_map.items():
    filter.setLogLevelForNamespace(ns, level)
  
  observer = FilteringLogObserver(
    FileLogObserver(sys.stdout, formatEvent),
    [ filter ]
  )
  
  globalLogBeginner.beginLoggingTo([observer], redirectStandardIO = False)

  return observer


#
# ContextLogger
#

class ContextLogger(Logger):
  def emit(
    self, level: LogLevel, format: Optional[str] = None, **kwargs: object
  ) -> None:
    if level < LogLevel.info:
      kwargs['log_frame'] = currentframe(2)
      kwargs['log_cwd']   = os.getcwd()

    try:
      super().emit(level, format, **kwargs)
    finally:
      kwargs.pop('log_frame', None)
