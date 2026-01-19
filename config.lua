Config = {}

-- Item name in shared/items.lua
Config.ItemName = 'core_gps'

-- Marker settings
Config.MarkerSettings = {
    type = 1, -- Marker type
    scale = vector3(1.0, 1.0, 1.0),
    color = {r = 255, g = 100, b = 100, a = 200},
    bobUpAndDown = false,
    faceCamera = false,
    rotate = false,
    drawOnEnter = true
}

-- Blip settings for map icons
Config.BlipSettings = {
    sprite = 1, -- Blip sprite ID
    color = 1, -- Blip color
    scale = 0.8,
    display = 4,
    shortRange = false
}

-- Maximum number of markers per player
Config.MaxMarkers = 50
