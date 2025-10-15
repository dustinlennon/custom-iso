from pathlib import Path
import sys
import syslog

dotnetwork_file   = sys.argv[1]
dropin_path       = Path("/etc/systemd/network") / f"{dotnetwork_file}.d"
dotconf_path      = dropin_path / "10-mdns.conf"

content = """
[Network]
MulticastDNS=yes
""".lstrip()

syslog.syslog(
  syslog.LOG_INFO,
  f"mkdir {dropin_path}"
)
dropin_path.mkdir(parents = True, exist_ok = True)

syslog.syslog(
  syslog.LOG_INFO,
  f"creating {dotconf_path}"
)
with open(dotconf_path, "w") as f:
  f.write( content )
