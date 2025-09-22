
import io
import textwrap
from pathlib import Path
from parser import Parser

class IoContext:
  def __init__(self, filename, *args, **kw):
    self.filename = filename
    self.args = args
    self.kw = kw

class DiskContext(IoContext):
  def __enter__(self):
    dirname = Path(self.filename).parent
    dirname.mkdir(parents = True, exist_ok = True)

    self._f = open(self.filename, *self.args, **self.kw)
    return self._f
  
  def __exit__(self, exc_type, exc_value, tb):
    self._f.close()

class TtyContext(IoContext):
  def __enter__(self):
    self._f = io.StringIO()
    return self._f
  
  def __exit__(self, exc_type, exc_value, tb):
    output = self._f.getvalue()
    msg = f"### {self.filename}\n{output}"

    self._f.close()
    msg = textwrap.dedent(msg)
    print(msg)

class Opener:
  def __init__(self, pargs):

    if pargs.context == 'disk':
      self._context = DiskContext
    elif pargs.context == 'tty':
      self._context = TtyContext
    else:
      parser.error("invalid 'context' value")

    self._args = pargs

  @property
  def args(self):
    return self._args

  def __call__(self, filename, *args, **kw):
    filename = Path(self.args.mount) / filename.strip("/")
    return self._context(filename, *args, **kw)

__all__ = [
  'DiskContext',
  'TtyContext',
  'Opener'
]

if __name__ == '__main__':
  parser = Parser.build()
  args = parser.parse_args()

  writer = Opener(args)

  with writer("test.out", "w") as f:
    f.write("hello world")
