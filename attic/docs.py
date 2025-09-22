network_conf = r'''
[Network]
MulticastDNS=yes
DNS=8.8.8.8
DNS=8.8.4.4
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

  wifis:
    _:
      dhcp4: true
      optional: true
      access-points: {}
'''.lstrip()

__all__ = [
  'network_conf',
  'resolve_conf',
  'netplan_yaml'
]
