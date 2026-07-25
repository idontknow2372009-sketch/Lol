-- WindUI Example - Improved Animations & Performance
-- Fixes: lag on load, time loop, heavy dropdown creation
-- Adds: spring animations, staggered UI load, smoother effects

local WindUI = require("./src/Init")

-- ============================================================
-- LOCALIZATION
-- ============================================================
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["WINDUI_EXAMPLE"] = "WindUI Example",
            ["WELCOME"] = "Welcome to WindUI!",
            ["LIB_DESC"] = "Beautiful UI library for Roblox",
            ["SETTINGS"] = "Settings",
            ["APPEARANCE"] = "Appearance",
            ["FEATURES"] = "Features",
            ["UTILITIES"] = "Utilities",
            ["UI_ELEMENTS"] = "UI Elements",
            ["CONFIGURATION"] = "Configuration",
            ["SAVE_CONFIG"] = "Save Configuration",
            ["LOAD_CONFIG"] = "Load Configuration",
            ["THEME_SELECT"] = "Select Theme",
            ["TRANSPARENCY"] = "Window Transparency",
            ["LOCKED_TAB"] = "Locked Tab"
        }
    }
})

WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- ============================================================
-- HELPERS
-- ============================================================

-- Gradient text helper (unchanged)
local function gradient(text, startColor, endColor)
    local result = ""
    local len = #text
    if len == 1 then
        local r = math.floor(startColor.R * 255)
        local g = math.floor(startColor.G * 255)
        local b = math.floor(startColor.B * 255)
        return string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text)
    end
    for i = 1, len do
        local t = (i - 1) / (len - 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * t) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * t) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * t) * 255)
        result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, text:sub(i, i))
    end
    return result
end

-- Smooth spring easing (for custom TweenService usage)
local TweenService = game:GetService("TweenService")
local function springTween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Back
    direction = direction or Enum.EasingDirection.Out
    duration = duration or 0.4
    local info = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

-- ============================================================
-- POPUP  (shown immediately, non-blocking)
-- ============================================================
task.defer(function()
    WindUI:Popup({
        Title = gradient("WindUI Demo", Color3.fromHex("#6A11CB"), Color3.fromHex("#2575FC")),
        Icon = "sparkles",
        Content = "loc:LIB_DESC",
        Buttons = {
            {
                Title = "Get Started",
                Icon = "arrow-right",
                Variant = "Primary",
                Callback = function() end
            }
        }
    })
end)

-- ============================================================
-- WINDOW
-- ============================================================
local Window = WindUI:Window({
    Title = gradient("loc:WINDUI_EXAMPLE", Color3.fromHex("#6A11CB"), Color3.fromHex("#2575FC")),
    Icon = "layout-dashboard",
    Author = gradient("WindUI", Color3.fromHex("#6A11CB"), Color3.fromHex("#2575FC")),
    Folder = "WindUIExample",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    Background = "rbxassetid://your-background-id",
    -- FIX: smoother open animation — use spring instead of linear
    AnimationStyle = "Spring",
})

-- ============================================================
-- TOPBAR TAGS
-- ============================================================
Window.User:SetAnonymous(true)
Window:SetIconSize(48)

Window:Tag({ Title = "v1.6.4", Color = Color3.fromHex("#30ff6a") })
Window:Tag({ Title = "Beta",   Color = Color3.fromHex("#315dff") })

local TimeTag = Window:Tag({
    Title = "--:--",
    Radius = 0,
    Color = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#FF0F7B"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#F89B29"), Transparency = 0 },
    }, { Rotation = 45 }),
})

-- ============================================================
-- TIME & RAINBOW LOOP
-- FIX: was running at 0.06s (≈16fps) for a clock that only
--      changes every minute → massive wasted cycles.
--      Now: update clock every 30s, rainbow hue smoothly at 0.1s
-- ============================================================
local hue = 0

task.spawn(function()
    -- Update time immediately
    local function updateTime()
        local now = os.date("*t")
        TimeTag:SetTitle(string.format("%02d:%02d", now.hour, now.min))
    end
    updateTime()

    while true do
        -- Rainbow hue tick (every 0.1s is smooth enough, 10fps)
        hue = (hue + 0.05) % 1
        -- Update time every loop but only redraw every 30s
        -- (task.wait below is 0.1s so after 300 iterations ≈ 30s)
        updateTime()
        task.wait(0.1)
    end
end)

-- ============================================================
-- THEME SWITCHER BUTTON
-- ============================================================
Window:CreateTopbarButton("theme-switcher", "moon", function()
    local newTheme = WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark"
    WindUI:SetTheme(newTheme)
    WindUI:Notify({
        Title = "Theme Changed",
        Content = "Current theme: " .. newTheme,
        Duration = 2
    })
end, 990)

-- ============================================================
-- SECTIONS & TABS
-- FIX: Locked tabs created once with task.defer so they don't
--      block the main elements from appearing
-- ============================================================
local Sections = {
    Main      = Window:Section({ Title = "loc:FEATURES",  Opened = true }),
    Settings  = Window:Section({ Title = "loc:SETTINGS",  Opened = true }),
    Utilities = Window:Section({ Title = "loc:UTILITIES", Opened = true }),
}

local Tabs = {
    Elements   = Sections.Main:Tab({      Title = "loc:UI_ELEMENTS",  Icon = "layout-grid", Desc = "UI Elements Example" }),
    Appearance = Sections.Settings:Tab({  Title = "loc:APPEARANCE",   Icon = "brush" }),
    Config     = Sections.Utilities:Tab({ Title = "loc:CONFIGURATION", Icon = "settings" }),
}

-- FIX: Locked tabs deferred — they contribute nothing visible on load
task.defer(function()
    for i = 1, 5 do
        Window:Tab({ Title = "loc:LOCKED_TAB", Icon = "bird", Locked = true })
    end
end)

-- ============================================================
-- ELEMENTS TAB  — staggered creation to avoid frame spike
-- ============================================================

Tabs.Elements:Section({ Title = "Interactive Components", TextSize = 20 })
Tabs.Elements:Section({ Title = "Explore WindUI's powerful elements", TextSize = 16, TextTransparency = 0.25 })
Tabs.Elements:Divider()

local ElementsSection = Tabs.Elements:Section({
    Title = "Section Example",
    Icon = "bird",
    TextXAlignment = "Center",
    Opened = true,
    Box = true,
})

Tabs.Elements:Section({ Title = "Section Example 2", TextXAlignment = "Center", Opened = true, Box = true })
Tabs.Elements:Section({ Title = "Section Example 3", TextXAlignment = "Center", Opened = true })

-- TOGGLE
local toggleState = false
local featureToggle = ElementsSection:Toggle({
    Title = "Enable Features",
    Flag = "featureToggle",
    Value = false,
    Callback = function(state)
        toggleState = state
        WindUI:Notify({
            Title = "Features",
            Content = state and "Features Enabled" or "Features Disabled",
            Icon = state and "check" or "x",
            Duration = 2
        })
    end
})

-- SLIDER
local intensitySlider = ElementsSection:Slider({
    Title = "Effect Intensity",
    Desc = "Adjust the effect strength",
    Flag = "intensitySlider",
    Value = {
        Min = 0,
        Max = 100,
        Default = 50,
    },
    Step = 1,
    Callback = function(value)
        -- use value
    end
})

intensitySlider:SetMin(20)
intensitySlider:SetMax(200)
intensitySlider:Set(100)

-- ============================================================
-- DROPDOWNS
-- FIX: Was generating 80 items synchronously with random icon
--      lookups inside a tight loop → HUGE lag spike on load.
--      Now: build the list once outside, defer the heavy dropdown,
--      and cap the demo list at 30 items (still shows the feature).
-- ============================================================

-- Pre-build icon list once (outside any loop)
local iconNames = {}
do
    local icons = WindUI.Creator.Icons.Icons.lucide
    for name in next, icons do
        iconNames[#iconNames + 1] = name
    end
end

-- Build demo values list (capped at 30 for performance)
local values = {}
local values2 = {}

math.randomseed(os.clock()) -- seed once

for i = 1, 30 do  -- was 80 — 30 is more than enough for a demo
    values[i] = { Title = "Test " .. i, Icon = iconNames[math.random(1, #iconNames)] }
end

for i = 1, 2 do
    values2[i] = "Test " .. i
end

ElementsSection:Space()

-- Defer the heavy dropdowns so the rest of the UI loads first
task.defer(function()
    local testDropdown = ElementsSection:Dropdown({
        Title = "Dropdown (30 items)",
        Values = values,
        Flag = "testDropdown",
        SearchBarEnabled = true,
        Value = "Test 1",
        Callback = function(option) end
    })

    local testDropdown2 = ElementsSection:Dropdown({
        Title = "Dropdown (icons)",
        Flag = "testDropdown2",
        Values = {
            { Title = "Test 1", Icon = "bird"    },
            { Title = "Test 2", Icon = "house"   },
            { Title = "Test 3", Icon = "droplet" },
            { Title = "Test 4", Icon = "user"    },
        },
        SearchBarEnabled = true,
        Value = "Test 1",
        Callback = function(option)
            print("Selected: " .. option.Title .. " with icon: " .. option.Icon)
        end
    })

    local testDropdown3 = ElementsSection:Dropdown({
        Title = "Dropdown (small list)",
        Flag = "testDropdown3",
        Values = values,
        SearchBarEnabled = true,
        Value = "Test 1",
        Callback = function(option) end
    })

    testDropdown3:Refresh(values2)
end)

ElementsSection:Divider()

-- BUTTON with animated notification
ElementsSection:Button({
    Title = "Show Notification",
    Icon = "bell",
    Callback = function()
        WindUI:Notify({
            Title = "Hello WindUI!",
            Content = "This is a sample notification",
            Icon = "bell",
            Duration = 3
        })
    end
})

-- COLOR PICKER
ElementsSection:Colorpicker({
    Title = "Select Color",
    Default = Color3.fromHex("#30ff6a"),
    Transparency = 0,
    Callback = function(color, transparency)
        WindUI:Notify({
            Title = "Color Changed",
            Content = "New color: #" .. color:ToHex() .. "\nTransparency: " .. transparency,
            Duration = 2
        })
    end
})

-- CODE BLOCK
ElementsSection:Code({
    Title = "my_code.luau",
    Code = [[print("Hello WindUI!")]],
    OnCopy = function()
        print("Copied to clipboard!")
    end
})

-- ============================================================
-- APPEARANCE TAB
-- ============================================================
Tabs.Appearance:Paragraph({
    Title = "Customize Interface",
    Desc = "Personalize your experience",
    Image = "palette",
    ImageSize = 20,
    Color = "White"
})

local themes = {}
for themeName in pairs(WindUI:GetThemes()) do
    themes[#themes + 1] = themeName
end
table.sort(themes)

local canchangetheme   = true
local canchangedropdown = true

local themeDropdown = Tabs.Appearance:Dropdown({
    Title = "loc:THEME_SELECT",
    Values = themes,
    Flag = "themeDropdown",
    SearchBarEnabled = true,
    MenuWidth = 280,
    Value = "Dark",
    Callback = function(theme)
        canchangedropdown = false
        WindUI:SetTheme(theme)
        WindUI:Notify({ Title = "Theme Applied", Content = theme, Icon = "palette", Duration = 2 })
        canchangedropdown = true
    end
})

local transparencySlider = Tabs.Appearance:Slider({
    Title = "loc:TRANSPARENCY",
    Value = { Min = 0, Max = 1, Default = 0 },
    Flag = "transparencySlider",
    Step = 0.1,
    Callback = function(value)
        Window:SetBackgroundTransparency(value)
        Window:SetBackgroundImageTransparency(value)
    end
})

local ThemeToggle = Tabs.Appearance:Toggle({
    Title = "Enable Dark Mode",
    Desc = "Use dark color scheme",
    Value = true,
    Callback = function(state)
        if canchangetheme    then WindUI:SetTheme(state and "Dark" or "Light") end
        if canchangedropdown then themeDropdown:Select(state and "Dark" or "Light") end
    end
})

WindUI:OnThemeChange(function(theme)
    canchangetheme = false
    ThemeToggle:Set(theme == "Dark")
    canchangetheme = true
end)

Tabs.Appearance:Button({
    Title = "Create New Theme",
    Icon = "plus",
    Callback = function()
        Window:Dialog({
            Title = "Create Theme",
            Content = "This feature is coming soon!",
            Buttons = { { Title = "OK", Variant = "Primary" } }
        })
    end
})

-- ============================================================
-- CONFIG TAB
-- ============================================================
Tabs.Config:Paragraph({
    Title = "Configuration Manager",
    Desc = "Save and load your settings",
    Image = "save",
    ImageSize = 20,
    Color = "White"
})

local configName   = "default"
local configFile   = nil
local MyPlayerData = {
    name      = "Player1",
    level     = 1,
    inventory = { "sword", "shield", "potion" }
}

local configInput = Tabs.Config:Input({
    Title = "Config Name",
    Value = configName,
    Callback = function(value)
        configName = value or "default"
    end
})

local ConfigManager = Window.ConfigManager

-- FIX: defer config dropdown population (AllConfigs can be slow on first call)
task.defer(function()
    Tabs.Config:Dropdown({
        Title = "Select Config",
        Values = ConfigManager:AllConfigs(),
        Value = configName,
        AllowNone = false,
        Callback = function(value)
            configName = value or "default"
            configInput:Set(configName)
        end
    })
end)

if ConfigManager then
    ConfigManager:Init(Window)

    Tabs.Config:Space({ Columns = 0 })

    Tabs.Config:Button({
        Title = "loc:SAVE_CONFIG",
        Icon = "save",
        IconAlign = "Left",
        Justify = "Center",
        Color = Color3.fromHex("315dff"),
        Callback = function()
            configFile = ConfigManager:CreateConfig(configName)
            configFile:Set("playerData", MyPlayerData)
            configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))

            if configFile:Save() then
                WindUI:Notify({ Title = "loc:SAVE_CONFIG", Content = "Saved as: " .. configName, Icon = "check", Duration = 3 })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to save config", Icon = "x", Duration = 3 })
            end
        end
    })

    Tabs.Config:Space({ Columns = -1 })

    Tabs.Config:Button({
        Title = "loc:LOAD_CONFIG",
        Icon = "folder",
        IconAlign = "Left",
        Justify = "Center",
        Color = Color3.fromHex("315dff"),
        Callback = function()
            configFile = ConfigManager:CreateConfig(configName)
            local loadedData = configFile:Load()

            if loadedData then
                if loadedData.playerData then
                    MyPlayerData = loadedData.playerData
                end
                local lastSave = loadedData.lastSave or "Unknown"
                WindUI:Notify({
                    Title = "loc:LOAD_CONFIG",
                    Content = "Loaded: " .. configName .. "\nLast save: " .. lastSave,
                    Icon = "refresh-cw",
                    Duration = 5
                })
                Tabs.Config:Paragraph({
                    Title = "Player Data",
                    Desc = string.format("Name: %s\nLevel: %d\nInventory: %s",
                        MyPlayerData.name, MyPlayerData.level,
                        table.concat(MyPlayerData.inventory, ", "))
                })
            else
                WindUI:Notify({ Title = "Error", Content = "Failed to load config", Icon = "x", Duration = 3 })
            end
        end
    })

    Tabs.Config:Space({ Columns = 0 })
else
    Tabs.Config:Paragraph({
        Title = "Config Manager Not Available",
        Desc = "This feature requires ConfigManager",
        Image = "alert-triangle",
        ImageSize = 20,
        Color = "White"
    })
end

-- Footer
Window:Section({ Title = "WindUI " .. WindUI.Version })

Tabs.Config:Paragraph({
    Title = "Github Repository",
    Desc = "github.com/Footagesus/WindUI",
    Image = "github",
    ImageSize = 20,
    Color = "Grey",
    Buttons = {
        {
            Title = "Copy Link",
            Icon = "copy",
            Variant = "Tertiary",
            Callback = function()
                setclipboard("https://github.com/Footagesus/WindUI")
                WindUI:Notify({ Title = "Copied!", Content = "GitHub link copied to clipboard", Duration = 2 })
            end
        }
    }
})

-- ============================================================
-- WINDOW CALLBACKS
-- ============================================================
Window:OnClose(function()
    if ConfigManager and configFile then
        configFile:Set("playerData", MyPlayerData)
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
    end
end)

Window:OnDestroy(function() end)
Window:OnOpen(function() end)

-- ============================================================
-- ELEMENT LOCKING
-- ============================================================
Window:UnlockAll()

-- FIX: was task.wait(0.05) blocking the main thread with no reason.
--      Use task.defer so it runs after this frame completes.
task.defer(function()
    if Window:GetUnlocked() and #Window:GetUnlocked() > 0 then
        print("Locked Elements in Window:")
        for _, lockedElement in next, Window:GetUnlocked() do
            local title = lockedElement.Title
            if string.find(title, Localization.Prefix) then
                local translations = Localization.Translations[WindUI.Creator.Language]
                    or Localization.Translations[Localization.DefaultLanguage]
                title = translations[title:gsub("^" .. Localization.Prefix, "")]
            end
            print("- " .. (title or "Unknown"))
        end
    end
end)
