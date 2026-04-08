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
    -- Create a fresh pipe for each client session
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
        local len = pipe.readDword()
        if not len then break end

        local code = pipe.readString(len)
        if not code then break end

        print("[ceremote] Exec: " .. code:sub(1, 80) .. (code:len() > 80 and "..." or ""))
        local output = captureExec(code)

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
