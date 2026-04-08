#!/usr/bin/env python3
"""Stop the CE Remote Server by sending a shutdown command."""

import struct, sys

PIPE_PATH = r"\\.\pipe\ceremote"
SHUTDOWN_CMD = "_G._ceRemoteStop = true"

try:
    pipe = open(PIPE_PATH, "r+b", buffering=0)
    encoded = SHUTDOWN_CMD.encode("utf-8")
    pipe.write(struct.pack("<B", 1))  # async mode
    pipe.write(struct.pack("<I", len(encoded)))
    pipe.write(encoded)
    pipe.flush()
    pipe.close()
    print("Server stopped.")
except FileNotFoundError:
    print("Server is not running.")
except Exception as e:
    print(f"Stopped (or already stopping): {e}")
