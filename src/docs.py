network_conf = r'''
[Network]
MulticastDNS=yes
'''.lstrip()

resolve_conf = r'''
[Resolve]
MulticastDNS=yes
'''.lstrip()

netplan_yaml = r'''
network:
  version: 2
  ethernets: 
    _:
      dhcp4: true
      optional: true
      link-local: [ ipv4 ]

  wifis:
    _:
      dhcp4: true
      optional: true
      link-local: [ ipv4 ]
      access-points: {}
'''.lstrip()

__all__ = [
  'network_conf',
  'resolve_conf',
  'netplan_yaml'
]