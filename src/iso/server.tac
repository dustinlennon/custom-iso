#
# UtilityService
#   - apt install pipenv
#
"""
PIPENV_PIPFILE=/home/dnlennon/Workspace/Sandbox/custom-iso/Pipfile \
sudo -E pipenv \
run twistd -ny src/iso/server.tac
"""

from twisted.application import service, strports
from twisted.web import resource, server

from iso.adapters import *
from iso.utility_service import UtilityService

utility_service = UtilityService()

application = service.Application('utility', uid = 1, gid = 1)
serviceCollection = service.IServiceCollection(application)

site = server.Site(resource.IResource(utility_service))
strports.service("tcp:80", site).setServiceParent(application)
  
