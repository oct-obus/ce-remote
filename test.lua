-- Quick test script for CE Remote
-- Run with: python client.py -f test_remote.lua

print("=== CE Remote Test ===")

-- 1. Basic Lua
print("[1] Lua eval:  2+2 = " .. tostring(2+2))

-- 2. CE version
print("[2] CE version: " .. getCEVersion())

-- 3. Process info
local pid = getOpenedProcessID()
if pid and pid ~= 0 then
  print("[3] Attached PID: " .. pid)
  print("    Process: " .. process)
else
  print("[3] No process attached")
end

-- 4. Address list
local count = getAddressList().Count
print("[4] Table entries: " .. count)

-- 5. Memory read (read 4 bytes from base of attached module)
if pid and pid ~= 0 then
  local base = getAddress(process)
  if base and base ~= 0 then
    local val = readInteger(base)
    print(string.format("[5] First dword at base: 0x%X", val or 0))
  else
    print("[5] Could not resolve module base")
  end
else
  print("[5] Skipped (no process)")
end

-- 6. Timing
local t = getTickCount()
for i = 1, 100000 do end
print(string.format("[6] 100k iterations: %dms", getTickCount() - t))

print("=== All tests passed ===")
