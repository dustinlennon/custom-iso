#!/usr/bin/python3

import os
import jinja2
import subprocess
import shlex

env = jinja2.Environment(
  loader = jinja2.FileSystemLoader("./templates")
)
template = env.get_template("network-config.sh.j2")

# tar -C src -cz . | base64 -
cmd_tar = shlex.split("tar -C src -cz network.py netplan.yml access_points.yml")
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