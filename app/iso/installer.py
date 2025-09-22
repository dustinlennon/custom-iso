import subprocess
import shlex
import jinja2
import os

env = jinja2.Environment(
  loader = jinja2.FileSystemLoader("./templates")
)

class IsoInstaller(object):
  _cache = dict()

  def __init__(self, path):
    self._encoded_fs = self._cache.get(path, self.encode_fs(path))

  @property
  def data(self):
    return self._encoded_fs

  @classmethod
  def encode_fs(cls, path):
    pipe_cmds = [
      f"tar -C {path} -cz .",
      "base64 -"
    ]

    procs = list()
    for i,cmd in enumerate(pipe_cmds):
      try:
        pipe = procs[i-1].stdout
      except IndexError:
        pipe = None

      proc = subprocess.Popen(shlex.split(cmd), stdout = subprocess.PIPE, stdin = pipe)
      procs.append(proc)

    result : subprocess.Popen = procs[-1]
    rc = result.wait()

    if rc != 0:
      raise subprocess.CalledProcessError('pipe failure: {err}')

    output = result.stdout.read().decode()   
    return output
  
  def refresh(self, path):
    self._encoded_fs = self.encode_fs(path)


if __name__ == '__main__':
  iso_installer = IsoInstaller("/home/dnlennon/Workspace/Sandbox/custom-iso/isofs")

  template = env.get_template("install.sh.j2")
  script = template.render(
    encoded_fs = iso_installer.data
  )

  print(script)
  with open("install.sh", "w") as f:
    f.write(script)
  os.chmod("install.sh", 0o755)
