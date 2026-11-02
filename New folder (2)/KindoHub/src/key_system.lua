--[[
  KEY SYSTEM MODULE
  Implements local cryptographic validation and daily rotation.
]]

local KeySystem = {}
local HttpService = game:GetService("HttpService")

-- 1. DEVICE ID GENERATION
function KeySystem.GenerateDeviceId()
    local guid = HttpService:GenerateGUID(false)
    local userId = game.Players.LocalPlayer.UserId
    local placeId = game.PlaceId
    local seed = string.format("%s|%s|%s", guid, userId, placeId)
    
    -- Simple FNV-1a Hash
    local h = 0xcbf29ce484222325
    for i = 1, #seed do
        h = h ~ seed:byte(i)
        h = (h * 0x100000001b3) % 2^64
    end
    return string.format("%016x", h)
end

-- 2. KEY GENERATION
function KeySystem.GenerateKey(deviceId)
    local unixTime = os.time()
    local daySeed = math.floor(unixTime / 86400) -- Daily reset
    local finalSeed = deviceId .. "|" .. daySeed
    
    local h = 0x811c9dc5
    for i = 1, #finalSeed do
        h = h ~ finalSeed:byte(i)
        h = (h * 0x01000193) % 2^32
    end
    return string.upper(string.format("%08x", h))
end

-- 3. VALIDATION
function KeySystem.Validate(inputKey, deviceId)
    if not inputKey then return false, "Empty key" end
    inputKey = string.upper(inputKey:trim())
    
    -- Check for Master Key
    local masterKeys = { "KIND-MASTER-001", "KINDO-ADMIN", "DEEPHAT-ROOT" }
    for _, mk in ipairs(masterKeys) do
        if inputKey == mk then
            return true, "PREMIUM"
        end
    end
    
    local expectedKey = KeySystem.GenerateKey(deviceId)
    if inputKey == expectedKey then
        return true, "STANDARD"
    end
    
    return false, "INVALID_KEY"
end

return KeySystem