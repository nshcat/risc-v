import argparse

from shell import *


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="rvdbg",
        description="Interactive RISC-V debugger"
    )
    parser.add_argument('--port', type=str, help='serial port to use. Will cause the debugger to connect on startup.')
    args = parser.parse_args()
    sys.exit(Shell(port=args.port).cmdloop())

