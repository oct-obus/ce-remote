# CE Remote

Execute Lua scripts in a running Cheat Engine instance from the command line.

Uses Windows named pipes for IPC — the server runs inside CE as a Lua script, and the Python client connects from any terminal.

## Setup

1. Open Cheat Engine and go to **Lua Engine** (Ctrl+Alt+L)
2. Load and execute `server.lua`
3. You should see: `CE Remote Server starting on \\.\pipe\ceremote`

## Usage

```bash
# Interactive REPL
python client.py

# One-liner
python client.py "print(getAddress('myprocess.exe'))"

# Execute a script file
python client.py -f myscript.lua
```

### Example session

```
CE Remote REPL (type 'exit' to quit)
ce> return 2+2
4
ce> print(getAddressList().Count)
42
ce> exit
```

## Stopping the server

```bash
python stop.py
```

Or from the REPL: run `_G._ceRemoteStop = true`

Re-running `server.lua` in CE also auto-stops any previous instance.

## How it works

- **server.lua** creates a named pipe (`\\.\pipe\ceremote`) and listens in a background thread
- **client.py** connects to the pipe and sends Lua code with a length-prefixed protocol
- The server executes the code via `loadstring()`, captures `print()` output and return values, then sends the result back
- After a client disconnects, the pipe is recreated for the next connection

## Testing

Run the included test script to verify everything works:

```bash
python client.py -f test.lua
```

Expected output:
```
=== CE Remote Test ===
[1] Lua eval:  2+2 = 4
[2] CE version: 7.5
[3] Attached PID: 12345
    Process: myprocess.exe
[4] Table entries: 42
[5] First dword at base: 0x5A4D
[6] 100k iterations: 12ms
=== All tests passed ===
```

## Requirements

- Cheat Engine 7.x+
- Python 3.6+
- Windows (named pipes are a Windows IPC mechanism)
