import argparse

class Parser(argparse.ArgumentParser):
  @classmethod
  def build(cls) -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--early", action = "store_true", help="select the 'early' execution mode")
    parser.add_argument("--mount", metavar = "ROOT", default="/", help="set the effective root directory")
    parser.add_argument("--context", default="disk", help="output format", choices=['disk', 'tty'])
    parser.add_argument("--cmdline", default="/proc/cmdline", help="the file containing the kernel boot arguments")
    parser.add_argument("--hostname", default=None)

    return parser
  
if __name__ == '__main__':
  parser = Parser.build()
  args = parser.parse_args()
  print(args)
  
