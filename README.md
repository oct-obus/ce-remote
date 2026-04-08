# CE Remote

Execute Lua scripts in a running Cheat Engine instance from the command line.

Uses Windows named pipes for IPC — the server runs inside CE as a Lua script, and the Python client connects from any terminal.

## Setup

1. Open Cheat Engine and go to **Lua Engine** (Ctrl+Alt+L)
2. Load and execute `server.lua`
3. You should see: `CE Remote Server starting on \\.\pipe\ceremote`

## Usage

```bash
# Interactive REPL (default: sync/main thread)
python client.py

# Interactive REPL (async/background thread)
python client.py --async

# One-liner
python client.py "print(getAddress('myprocess.exe'))"

# Execute a script file
python client.py -f myscript.lua

# Execute on background thread (for heavy scans, long loops)
python client.py --async -f heavy_scan.lua
```

### Sync vs Async

By default, scripts run on CE's **main thread** via `synchronize()`. This is required for anything that creates GUI elements (forms, panels, etc). Use `--async` to run on a background thread instead — better for long-running operations that would otherwise freeze CE's UI.

| Mode | Flag | Thread | Use for |
|------|------|--------|---------|
| sync | *(default)* | Main | GUI scripts, quick commands |
| async | `--async` | Background | AOB scans, loops, heavy work |

### Example commands

```bash
# Get the base address of a module
python client.py "print(string.format('0x%X', getAddress('myprocess.exe')))"

# Count table entries
python client.py "return getAddressList().Count"

# Read memory
python client.py "return string.format('0x%X', readInteger(0x00400000))"

# AOB scan (use async for large scans)
python client.py --async "local r = AOBScan('48 89 5C 24 08'); if r then print(stringlist_getString(r,0)); object_destroy(r) else print('not found') end"

# Toggle a cheat table entry by description
python client.py "local al=getAddressList(); for i=0,al.Count-1 do if al[i].Description=='God Mode' then al[i].Active=not al[i].Active; print('Toggled') end end"

# Run a GUI script on the main thread (default sync mode)
python client.py -f my_gui_tool.lua
```

### Interactive REPL

```
CE Remote REPL [sync] (type 'exit' to quit)
ce> return 2+2
4
ce> print(getAddressList().Count)
42
ce> print(getCEVersion())
7.5
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
