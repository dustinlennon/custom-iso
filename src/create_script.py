#!/usr/bin/python3

# This creates a self-extracting bash script containing the necessary python code
# required to execute network.py.  See ./templates/network-config.sh.j2.

import os
import jinja2
import subprocess
import shlex

env = jinja2.Environment(
  loader = jinja2.FileSystemLoader("./templates")
)
template = env.get_template("network-config.sh.j2")

# tar -C src -cz . | base64 -
files = ' '.join([
  'docs.py',
  'network.py',
  'opener.py',
  'parser.py'
])

cmd_tar = shlex.split(f"tar -C src -cz {files}")
cmd_b64 = shlex.split("base64 -")

proc_tar = subprocess.Popen(cmd_tar, stdout = subprocess.PIPE)
proc_b64 = subprocess.check_output(cmd_b64, stdin = proc_tar.stdout)
proc_tar.wait()

script = template.render(
  encoded_data = proc_b64.decode("utf8")
)

with open("network-config.sh", "w") as f:
  f.write(script)

os.chmod("network-config.sh", 0o755)