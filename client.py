#!/usr/bin/env python3
"""CE Remote Client - Send Lua commands to Cheat Engine via named pipe.

Usage:
  client.py "print('hello')"          # One-liner
  client.py -f script.lua             # Execute file
  client.py                           # Interactive REPL
"""

import struct, sys

PIPE_PATH = r"\\.\pipe\ceremote"


def send_command(pipe, code: str) -> str:
    encoded = code.encode("utf-8")
    pipe.write(struct.pack("<I", len(encoded)))
    pipe.write(encoded)
    pipe.flush()

    raw_len = pipe.read(4)
    if len(raw_len) < 4:
        return "(connection lost)"
    resp_len = struct.unpack("<I", raw_len)[0]
    if resp_len == 0:
        return "(no output)"
    return pipe.read(resp_len).decode("utf-8", errors="replace")


def main():
    try:
        pipe = open(PIPE_PATH, "r+b", buffering=0)
    except FileNotFoundError:
        print(f"ERROR: Cannot connect to {PIPE_PATH}")
        print("Make sure server.lua is running in Cheat Engine.")
        sys.exit(1)

    if len(sys.argv) > 1:
        if sys.argv[1] == "-f":
            with open(sys.argv[2], "r") as f:
                code = f.read()
        else:
            code = " ".join(sys.argv[1:])
        result = send_command(pipe, code)
        if result != "(no output)":
            print(result)
    else:
        print("CE Remote REPL (type 'exit' to quit)")
        while True:
            try:
                code = input("ce> ")
            except (EOFError, KeyboardInterrupt):
                break
            if code.strip().lower() in ("exit", "quit"):
                break
            if not code.strip():
                continue
            result = send_command(pipe, code)
            if result != "(no output)":
                print(result)

    pipe.close()


if __name__ == "__main__":
    main()
