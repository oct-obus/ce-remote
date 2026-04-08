-- CE Remote Execute Server (runs inside Cheat Engine)
-- Creates a named pipe that accepts Lua code and returns results.
-- Usage: Execute this script in CE's Lua Engine window.
--        Then use client.py from CLI to send commands.

local PIPE_NAME = "ceremote"

local function captureExec(code)
  local outputLines = {}
  local oldPrint = print
  print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
      parts[#parts + 1] = tostring(select(i, ...))
    end
    outputLines[#outputLines + 1] = table.concat(parts, "\t")
  end

  local fn, err = loadstring(code)
  if fn then
    local results = {pcall(fn)}
    local ok = table.remove(results, 1)
    if ok then
      if #results > 0 then
        local parts = {}
        for _, v in ipairs(results) do
          parts[#parts + 1] = tostring(v)
        end
        outputLines[#outputLines + 1] = table.concat(parts, "\t")
      end
    else
      outputLines[#outputLines + 1] = "RUNTIME ERROR: " .. tostring(results[1])
    end
  else
    outputLines[#outputLines + 1] = "PARSE ERROR: " .. tostring(err)
  end

  print = oldPrint
  return table.concat(outputLines, "\n")
end

-- Clean up previous instance
if _G._ceRemoteStop then
  _G._ceRemoteStop = true
  sleep(200)
end

_G._ceRemoteStop = false

print("CE Remote Server starting on \\\\.\\pipe\\" .. PIPE_NAME)

createThread(function()
  while not _G._ceRemoteStop do
    local pipe = createPipe(PIPE_NAME, 65536, 65536)
    if not pipe or not pipe.valid then
      print("[ceremote] ERROR: Failed to create pipe")
      sleep(1000)
    else
      pipe.acceptConnection()

      if _G._ceRemoteStop then
        pipe.destroy()
        break
      end

      print("[ceremote] Client connected")

      while pipe.Connected do
        -- Protocol: byte(mode) + dword(len) + string(code)
        -- mode: 0 = synchronize (main thread, safe for GUI), 1 = async (background thread)
        local mode = pipe.readByte()
        if not mode then break end

        local len = pipe.readDword()
        if not len then break end

        local code = pipe.readString(len)
        if not code then break end

        local modeStr = mode == 1 and "async" or "sync"
        print(string.format("[ceremote:%s] Exec: %s%s", modeStr,
          code:sub(1, 70), code:len() > 70 and "..." or ""))

        local output

        if mode == 1 then
          -- Async: run directly in this thread (background)
          output = captureExec(code)
        else
          -- Sync: run on main thread via synchronize()
          local done = false
          synchronize(function()
            output = captureExec(code)
            done = true
          end)
          -- Wait for main thread to execute it
          while not done do sleep(10) end
        end

        pipe.writeDword(#output)
        pipe.writeString(output)
      end

      print("[ceremote] Client disconnected")
      pipe.destroy()
    end
  end

  _G._ceRemoteStop = nil
  print("[ceremote] Server stopped")
end)
