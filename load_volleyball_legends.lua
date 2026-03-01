--[[
  LOADER — Cole só isto. Script principal vem do GitHub.
  Coloque a URL Raw do hitbox_script.lua em SCRIPT_URL abaixo.
]]

local SCRIPT_URL = "https://raw.githubusercontent.com/RevengeGuizera/Volleyball/refs/heads/main/hitbox_script.lua"

local G = game
local function L()
  local H = "Http"
  local Ge = H .. "Get"
  local Ga = H .. "Get" .. "Async"
  if type(G[Ge]) == "function" then return G[Ge](G, SCRIPT_URL, true) end
  if type(G[Ga]) == "function" then return G[Ga](G, SCRIPT_URL, true) end
  if type(HttpGet) == "function" then return HttpGet(SCRIPT_URL) end
  local ok, Sv = pcall(function() return G:GetService("HttpService") end)
  if ok and Sv and type(Sv.GetAsync) == "function" then
    local ok2, body = pcall(function() return Sv:GetAsync(SCRIPT_URL) end)
    if ok2 and body then return body end
  end
  return nil
end

local content = L()
if not content or #content < 100 then
  warn("[VL] URL falhou. Confira SCRIPT_URL e o executor.")
  return
end

-- Ambiente com game, GetService, Instance, etc. para o script não dar "Execute com executor que suporte Roblox"
local env
if getfenv then
  env = getfenv(1)
else
  env = {}
  for k, v in pairs(_G) do env[k] = v end
  env._G = env
end
env.game = env.game or G
env.script = env.script or script

local fn, loadErr = loadstring(content, "Main")
if not fn then
  warn("[VL] Erro: " .. tostring(loadErr))
  return
end

local ok, err
if setfenv then
  setfenv(fn, env)
  ok, err = pcall(fn)
else
  -- Fallback para executores sem setfenv: injeta _ENV no código (Lua 5.2+)
  local wrapped = "local _ENV = ...\n" .. content
  local fn2, err2 = loadstring(wrapped, "Main")
  if fn2 then
    ok, err = pcall(fn2, env)
  else
    ok, err = pcall(fn)
  end
end

if not ok and err then warn("[VL] " .. tostring(err)) end
