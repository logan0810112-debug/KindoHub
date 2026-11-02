local KeySystem = {}
local HttpService = game:GetService("HttpService")

function KeySystem.GenerateDeviceId()
    local guid = HttpService:GenerateGUID(false)
    local userId = game.Players.LocalPlayer.UserId
    local placeId = game.PlaceId
    local seed = string.format("%s|%s|%s", guid, userId, placeId)
    
    local h = 0xcbf29ce484222325
    for i = 1, #seed do
        h = h ~ seed:byte(i)
        h = (h * 0x100000001b3) % 2^64
    end
    return string.format("%016x", h)
end

function KeySystem.GenerateKey(deviceId)
    local unixTime = os.time()
    local daySeed = math.floor(unixTime / 86400)
    local finalSeed = deviceId .. "|" .. daySeed
    
    local h = 0x811c9dc5
    for i = 1, #finalSeed do
        h = h ~ finalSeed:byte(i)
        h = (h * 0x01000193) % 2^32
    end
    return string.upper(string.format("%08x", h))
end

function KeySystem.Validate(inputKey, deviceId)
    if not inputKey then return false, "EMPTY" end
    inputKey = string.upper(inputKey:trim())
    
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
    
    return false, "INVALID"
end

_G.KindoKeySystem = KeySystem
return KeySystem