#!/usr/bin/env python3
"""CE Remote Client - Send Lua commands to Cheat Engine via named pipe.

Usage:
  client.py "print('hello')"          # One-liner (sync, main thread)
  client.py --async "AOBScan(...)"    # Run on background thread
  client.py -f script.lua             # Execute file (sync)
  client.py -f script.lua --async     # Execute file (async)
  client.py                           # Interactive REPL (sync)
  client.py --async                   # Interactive REPL (async)
"""

import struct, sys

PIPE_PATH = r"\\.\pipe\ceremote"

MODE_SYNC = 0   # Main thread (safe for GUI)
MODE_ASYNC = 1  # Background thread (non-blocking)


def send_command(pipe, code: str, mode: int = MODE_SYNC) -> str:
    encoded = code.encode("utf-8")
    pipe.write(struct.pack("<B", mode))
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
    args = [a for a in sys.argv[1:] if a != "--async"]
    mode = MODE_ASYNC if "--async" in sys.argv else MODE_SYNC

    try:
        pipe = open(PIPE_PATH, "r+b", buffering=0)
    except FileNotFoundError:
        print(f"ERROR: Cannot connect to {PIPE_PATH}")
        print("Make sure server.lua is running in Cheat Engine.")
        sys.exit(1)

    if args:
        if args[0] == "-f":
            with open(args[1], "r") as f:
                code = f.read()
        else:
            code = " ".join(args)
        result = send_command(pipe, code, mode)
        if result != "(no output)":
            print(result)
    else:
        mode_label = "async" if mode == MODE_ASYNC else "sync"
        print(f"CE Remote REPL [{mode_label}] (type 'exit' to quit)")
        while True:
            try:
                code = input("ce> ")
            except (EOFError, KeyboardInterrupt):
                break
            if code.strip().lower() in ("exit", "quit"):
                break
            if not code.strip():
                continue
            result = send_command(pipe, code, mode)
            if result != "(no output)":
                print(result)

    pipe.close()


if __name__ == "__main__":
    main()
