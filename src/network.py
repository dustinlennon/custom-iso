#!/usr/bin/python3

import re
import yaml
import json
import subprocess
import shlex
import copy
from pathlib import Path

from docs import *
from opener import *
from parser import Parser


# test_args = shlex.split("--context tty --cmdline ./test/cmdline")
test_args = None


if __name__ == '__main__':

  parser  = Parser.build()
  args    = parser.parse_args(test_args)
  
  writer = Opener(args)

  # read netplan template
  netplan = yaml.safe_load(netplan_yaml)
  network = netplan['network']
  _wired  = network['ethernets'].pop('_')
  _wifi   = network['wifis'].pop('_')

  # extract kernel boot args information from cmdline
  cmd     = shlex.split(f"cat {writer.args.cmdline}")
  proc    = subprocess.run(cmd, capture_output = True)
  cmdline = proc.stdout.decode("utf8")
  tokens  = shlex.split(cmdline)
  
  rex_ssid = re.compile("wlan-ssid=(?P<ssid>.*)")
  rex_pwd  = re.compile("wlan-pwd=(?P<pwd>.*)")

  wlan = {}

  ssid = None
  for t in tokens:   
    mssid  = rex_ssid.match(t)
    mpwd   = rex_pwd.match(t)

    if mssid:
      ssid = mssid.group('ssid')
      wlan.setdefault(ssid)
    elif ssid and mpwd:
      pwd = mpwd.group('pwd')
      wlan[ssid] = pwd
      ssid = None

  _wifi['access-points'] = {
    k:{'password' : v} for k,v in wlan.items() if v
  }
 
  # network link data
  cmd = shlex.split("ip -j link")
  links = subprocess.run(cmd, capture_output = True)
  links = json.loads(links.stdout)

  # network default route
  cmd = shlex.split("ip -j route show default")
  default_route = subprocess.run(cmd, capture_output = True)
  default_route = json.loads(default_route.stdout)

  try:
    if writer.args.early:
      raise IndexError("early: no default route")
    default_ifname = default_route[0].get("dev", None)
  except IndexError:
    default_ifname = None

  # /netplan
  for dev in links:
    ifname = dev.get("ifname")

    if ifname.startswith("en"):
      key = 'ethernets'
      network[key][ifname] = copy.deepcopy(_wired)
    elif ifname.startswith("wl"):
      key = "wifis"
      network[key][ifname] = copy.deepcopy(_wifi)
    else:
      continue

    if ifname == default_ifname:
      network[key][ifname].pop('optional')

  # early:  
  #   /netplan.yml
  if writer.args.early:
    filename = "/netplan.yml"
    with writer(filename, "w") as f:
      yaml.dump(netplan, f, Dumper = yaml.Dumper)

  # late:  
  #   /etc/netplan/60-preconfigured.yaml
  #   /etc/systemd/resolved.conf.d
  #   /etc/systemd/network/*conf
  #   /etc/hostname
  else:
    # filename = "/etc/netplan/60-preconfigured.yaml"
    # with writer(filename, "w") as f:
    #   yaml.dump(netplan, f, Dumper = yaml.Dumper)

    filename = f"/etc/systemd/resolved.conf.d/10-mdns.conf"
    with writer(filename, "w") as f:
      f.write(resolve_conf)
    
    for dev in links:
      ifname    = dev.get("ifname")
      filename  = f"/etc/systemd/network/10-netplan-{ifname}.network.d/10-mdns.conf"
      dirname   = str(Path(filename).parent)

      if ifname.startswith("en") or ifname.startswith("wl"):
        with writer(filename, "w") as f:
          f.write(network_conf.format(ifname = ifname))
      else:
        continue

    filename = "/etc/hostname"
    if writer.args.hostname:
      with writer(filename, "w") as f:
        f.write(writer.args.hostname)
