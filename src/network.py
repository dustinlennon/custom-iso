#!/usr/bin/python3

import argparse
import yaml
import json
import subprocess
import shlex
import copy
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--rootfs", default="/")
parser.add_argument("--early", action = "store_true")

network_conf = r'''
[Network]
MulticastDNS=yes
'''.lstrip()

resolve_conf = r'''
[Resolve]
MulticastDNS=yes
'''.lstrip()

# pfix = lambda args, pth: Path(args.prefix) / pth
rfix = lambda args, pth: Path(args.rootfs) / pth.strip("/")

class Opener:
  def __init__(self, ns):
    self.ns = ns

  def __call__(self, file, *args, **kw):
    file     = rfix(self.ns, file)
    dirname  = Path(file).parent
    return self.Context(file, dirname, *args, **kw)

  class Context:
    def __init__(self, file, dirname : Path, *args, **kw):
      self.file = file
      self.dirname = dirname
      self.args = args
      self.kw = kw

    def __enter__(self):
      self.dirname.mkdir(parents = True, exist_ok = True)
      self._f = open(self.file, *self.args, **self.kw)
      return self._f
    
    def __exit__(self, exc_type, exc_value, tb):
      self._f.close()

if __name__ == '__main__':

  args = parser.parse_args()
  args.late = not args.early
  # args = parser.parse_args(
  #   shlex.split(
  #     "--rootfs rfs"
  #   )
  # )

  opener = Opener(args)

  # read netplan
  with open("netplan.yml", "r") as f:
    netplan = yaml.load(f, yaml.Loader)
  network = netplan['network']
  _wired  = network['ethernets'].pop('_')
  _wifi   = network['wifis'].pop('_')

  # read access_points
  with open("access_points.yml", "r") as f:
    access_points = yaml.load(f, yaml.Loader)
  _wifi.update(access_points)

  # network link data
  cmd = shlex.split("ip -j link")
  links = subprocess.run(cmd, capture_output = True)
  links = json.loads(links.stdout)

  # network default route
  cmd = shlex.split("ip -j route show default")
  default_route = subprocess.run(cmd, capture_output = True)
  default_route = json.loads(default_route.stdout)

  try:
    if args.early:
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

  if args.early:
    filename = "/netplan.yml"
    with opener(filename, "w") as f:
      yaml.dump(netplan, f, Dumper = yaml.Dumper)

  # /etc/systemd/resolved.conf.d
  # /etc/systemd/network/*conf
  if args.late:
    filename = f"/etc/systemd/resolved.conf.d/10-mdns.conf"
    with opener(filename, "w") as f:
      f.write(resolve_conf)
    
    for dev in links:
      ifname    = dev.get("ifname")
      filename  = f"/etc/systemd/network/10-netplan-{ifname}.network.d/10-mdns.conf"
      dirname   = str(Path(filename).parent)

      if ifname.startswith("en") or ifname.startswith("wl"):
        with opener(filename, "w") as f:
          f.write(network_conf.format(ifname = ifname))
      else:
        continue
