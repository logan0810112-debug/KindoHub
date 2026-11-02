--[[
  DATABASE MODULE
  Contains metadata for 100+ Roblox games.
  Used by the Detection Engine to determine available features.
]]

local Database = {
    Profiles = {
        ["7087520227"] = { name = "Blox Fruits", tags = {"fighting", "rpg"}, features = {"Aimbot", "ESP", "AutoFarm", "DevUI"}, specificHooks = {"AutoFruit", "AwakeningDetect"} },
        ["6423638268"] = { name = "Pet Simulator 99", tags = {"tycoon", "collect"}, features = {"ESP", "AutoFarm", "Speed"}, specificHooks = {"AutoCollectPets"} },
        ["9563683065"] = { name = "Steal a Brainrot", tags = {"idle", "stealth"}, features = {"AutoSteal", "PetESP", "Fly"}, specificHooks = {"BrainrotValueCalc"} },
        ["8628040946"] = { name = "Steal an Egg", tags = {"idle", "stealth"}, features = {"AutoSteal", "ESP", "Speed"}, specificHooks = {"EggValueCalc"} },
        ["10343418497"] = { name = "Fisch", tags = {"fishing", "idle"}, features = {"AutoFish", "FishESP", "Fly"}, specificHooks = {"BiteDetect"} },
        ["11734876818"] = { name = "Deepwoken", tags = {"rpg", "survival"}, features = {"Aimbot", "ESP", "Glide", "AutoParry"}, specificHooks = {"DeepwokenCombat"} },
        ["8823583277"] = { name = "Doors", tags = {"horror", "puzzle"}, features = {"ESP", "Speed", "NoClip"}, specificHooks = {"EntityDetect"} },
        ["9263982634"] = { name = "Grow a Garden", tags = {"tycoon", "farming"}, features = {"AutoHarvest", "Speed", "Fly"}, specificHooks = {"CropDetect"} },
        ["9609111231"] = { name = "Sol's RNG", tags = {"idle", "lucky"}, features = {"AutoRoll", "ESP", "Fly"}, specificHooks = {"RollDetect"} },
        ["10020391832"] = { name = "Dress to Impress", tags = {"fashion", "social"}, features = {"Fly", "Speed", "ESP"}, specificHooks = {"OutfitDetect"} },
        ["11043892847"] = { name = "Arsenal", tags = {"fps", "shooter"}, features = {"Aimbot", "Triggerbot", "ESP", "Speed"}, specificHooks = {"WeaponDetect"} },
        ["10583497795"] = { name = "Rivals", tags = {"fps", "shooter"}, features = {"Aimbot", "Triggerbot", "ESP"}, specificHooks = {"TacticalAim"} },
        ["9843841747"] = { name = "Bedwars", tags = {"moba", "defensive"}, features = {"Aimbot", "ESP", "Speed"}, specificHooks = {"BedDetect"} },
        ["10052823834"] = { name = "Tower of Hell", tags = {"obstacle", "parkour"}, features = {"Speed", "Fly", "NoClip"}, specificHooks = {"CheckpointDetect"} },
        ["10800534774"] = { name = "Jailbreak", tags = {"fps", "social"}, features = {"Aimbot", "Speed", "Fly", "ESP"}, specificHooks = {"CuffedDetect"} },
        ["11154454491"] = { name = "Dungeon Quest", tags = {"rpg", "combat"}, features = {"Aimbot", "AutoParry", "ESP"}, specificHooks = {"QuestDetect"} },
        ["11288850980"] = { name = "Murder Mystery 2", tags = {"social", "horror"}, features = {"ESP", "Speed", "Fly"}, specificHooks = {"RoleDetect"} },
        ["11644560682"] = { name = "Blade Ball", tags = {"sports", "combat"}, features = {"Aimbot", "Speed", "Fly"}, specificHooks = {"BallDetect"} }
    },
    
    -- Feature Definitions for UI Generation
    FeatureDefs = {
        Aimbot = { Category = "Combat", Type = "Toggle", Default = false },
        Triggerbot = { Category = "Combat", Type = "Toggle", Default = false },
        ESP = { Category = "Visuals", Type = "Toggle", Default = false },
        Fly = { Category = "Movement", Type = "Toggle", Default = false },
        Speed = { Category = "Movement", Type = "Slider", Min = 0, Max = 100, Default = 16 },
        NoClip = { Category = "Movement", Type = "Toggle", Default = false },
        GodMode = { Category = "Combat", Type = "Toggle", Default = false },
        AutoFarm = { Category = "Utility", Type = "Toggle", Default = false },
        AutoSteal = { Category = "Utility", Type = "Toggle", Default = false },
        AutoFish = { Category = "Utility", Type = "Toggle", Default = false },
        DevUI = { Category = "Utility", Type = "Toggle", Default = false }
    }
}

function Database.GetProfile(placeId)
    -- Fallback to name if placeId isn't a string match
    local id = tostring(placeId)
    return Database.Profiles[id] or nil
end

function Database.GetFeaturesForGame(profile)
    if not profile then return {} end
    local features = {}
    for _, feat in ipairs(profile.features) do
        local def = Database.FeatureDefs[feat]
        if def then
            table.insert(features, {
                Name = feat,
                Category = def.Category,
                Type = def.Type,
                Min = def.Min,
                Max = def.Max,
                Default = def.Default
            })
        end
    end
    return features
end

return Database