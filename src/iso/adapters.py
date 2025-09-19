from zope.interface import implementer

from twisted.python import components
from twisted.web import resource

from iso.context_logger import ContextLogger

from iso.interfaces import *
from iso.klein_delegator import KleinDelegator
import iso.klein_mixins as mixins
from iso.netcat_request import NetcatRequestFactory


#
# Adapter from IDirectoryHashService 
#           to IDirectoryHashNetcatRequestFactory
#
@implementer(IDirectoryHashNetcatRequestFactory)
class DirectoryHashFactoryFromUtilityService(NetcatRequestFactory):
  def __init__(self, service):
    self.service = service

  def cmd_md5(self, dirname) -> defer.Deferred:
    return self.service.getDirectoryHashMD5(dirname)

  def cmd_sha256(self, dirname) -> defer.Deferred:
    return self.service.getDirectoryHashSHA256(dirname)

components.registerAdapter(
  DirectoryHashFactoryFromUtilityService,
  IDirectoryHashService,
  IDirectoryHashNetcatRequestFactory
)

#
# Adapter from ISelfExtractorService 
#           to ISelfExtractorNetcatRequestFactory
#
@implementer(ISelfExtractorNetcatRequestFactory)
class SelfExtractorFromUtilityService(NetcatRequestFactory):
  def __init__(self, service):
    self.service = service

  def cmd_pack(self, dirpath) -> defer.Deferred:
    return self.service.getSelfExtractor(dirpath)

components.registerAdapter(
  SelfExtractorFromUtilityService,
  ISelfExtractorService,
  ISelfExtractorNetcatRequestFactory
)

# Adapter from IUtilityService 
#           to resource.IResource
#
@implementer(resource.IResource)
class ResourceFromUtilityService(
    KleinDelegator,
    mixins.KWelcome,
    mixins.KDirectoryHash,
    mixins.KSelfExtractor
    ):
  
  def __init__(self, service):
    super().__init__(service)

components.registerAdapter(ResourceFromUtilityService, IUtilityService, resource.IResource)
