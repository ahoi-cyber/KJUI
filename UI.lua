-- =========================================================
-- ULTIMATE ROBLOX EXECUTOR-STYLE UI FRAMEWORK V2.2
-- New: Dynamic Island UI & Morphing Notification Bar
-- =========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Library = {
    Version = "2.2.0",
    Flags = {},
    ThemeObjects = {},
    CurrentTheme = "Dark",
    Themes = {
        Dark = {
            Main = Color3.fromRGB(24, 24, 28),
            Secondary = Color3.fromRGB(34, 34, 40),
            Tertiary = Color3.fromRGB(44, 44, 52),
            Stroke = Color3.fromRGB(60, 60, 70),
            Text = Color3.fromRGB(245, 245, 250),
            SubText = Color3.fromRGB(165, 165, 175),
            Accent = Color3.fromRGB(85, 170, 255),
            ToggleOn = Color3.fromRGB(75, 215, 135),
            ToggleOff = Color3.fromRGB(80, 80, 90)
        },
        Fluent = {
            Main = Color3.fromRGB(32, 32, 32),
            Secondary = Color3.fromRGB(43, 43, 43),
            Tertiary = Color3.fromRGB(55, 55, 55),
            Stroke = Color3.fromRGB(70, 70, 70),
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(96, 205, 255),
            ToggleOn = Color3.fromRGB(96, 205, 255),
            ToggleOff = Color3.fromRGB(90, 90, 90)
        },
        Ocean = {
            Main = Color3.fromRGB(18, 25, 38),
            Secondary = Color3.fromRGB(26, 36, 54),
            Tertiary = Color3.fromRGB(36, 50, 74),
            Stroke = Color3.fromRGB(52, 72, 105),
            Text = Color3.fromRGB(240, 248, 255),
            SubText = Color3.fromRGB(150, 175, 205),
            Accent = Color3.fromRGB(56, 189, 248),
            ToggleOn = Color3.fromRGB(52, 211, 153),
            ToggleOff = Color3.fromRGB(65, 85, 115)
        },
        Crimson = {
            Main = Color3.fromRGB(28, 20, 22),
            Secondary = Color3.fromRGB(40, 28, 31),
            Tertiary = Color3.fromRGB(54, 38, 42),
            Stroke = Color3.fromRGB(78, 52, 58),
            Text = Color3.fromRGB(252, 242, 244),
            SubText = Color3.fromRGB(185, 155, 160),
            Accent = Color3.fromRGB(244, 63, 94),
            ToggleOn = Color3.fromRGB(244, 63, 94),
            ToggleOff = Color3.fromRGB(88, 68, 72)
        }
    }
}

-- Biến toàn cục quản lý Dynamic Island trỏ từ Window
local ActiveDynamicIsland = nil

-- =========================================================
-- UTILITIES & MEMORY MANAGEMENT
-- =========================================================
local function GetSafeGuiParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if success and parent then return parent end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function Create(className, properties, children)
    local inst = Instance.new(className)
    for i, v in pairs(properties or {}) do
        inst[i] = v
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function BindTheme(instance, property, themeKey)
    table.insert(Library.ThemeObjects, {
        Instance = instance,
        Property = property,
        Key = themeKey
    })
    local currentPalette = Library.Themes[Library.CurrentTheme] or Library.Themes.Dark
    if currentPalette[themeKey] then
        instance[property] = currentPalette[themeKey]
    end
end

function Library:SetTheme(themeName)
    local palette = Library.Themes[themeName]
    if not palette then return end
    Library.CurrentTheme = themeName

    for i = #Library.ThemeObjects, 1, -1 do
        local obj = Library.ThemeObjects[i]
        if obj.Instance and obj.Instance.Parent then
            if palette[obj.Key] then
                TweenService:Create(obj.Instance, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                    [obj.Property] = palette[obj.Key]
                }):Play()
            end
        else
            table.remove(Library.ThemeObjects, i)
        end
    end
end

local function CreateRipple(button, accentColor)
    button.ClipsDescendants = true
    local mouseLocation = UserInputService:GetMouseLocation()
    local relX = mouseLocation.X - button.AbsolutePosition.X
    local relY = mouseLocation.Y - button.AbsolutePosition.Y - 36

    local circle = Create("Frame", {
        Parent = button,
        BackgroundColor3 = accentColor or Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.65,
        Position = UDim2.new(0, relX, 0, relY),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = button.ZIndex + 2
    }, {
        Create("UICorner", {CornerRadius = UDim.new(1, 0)})
    })

    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
    TweenService:Create(circle, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.45, function()
        if circle then circle:Destroy() end
    end)
end

local function MakeDraggable(topbarobject, object, connectionsList)
    local Dragging, DragInput, DragStart, StartPos

    local c1 = topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = object.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    local c2 = topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    local c3 = UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local delta = input.Position - DragStart
            TweenService:Create(object, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)

    if connectionsList then
        table.insert(connectionsList, c1)
        table.insert(connectionsList, c2)
        table.insert(connectionsList, c3)
    end
end

-- =========================================================
-- NOTIFICATION SYSTEM (MORPHING DYNAMIC ISLAND)
-- =========================================================
local NotifyGui = Create("ScreenGui", {
    Name = "UltimateUINotify_V2",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false
})
NotifyGui.Parent = GetSafeGuiParent()

local NotifyTypes = {
    Success = {Color = Color3.fromRGB(75, 215, 135), Icon = "✓"},
    Warning = {Color = Color3.fromRGB(255, 185, 65),  Icon = "⚠"},
    Error   = {Color = Color3.fromRGB(244, 63, 94),   Icon = "✕"},
    Info    = {Color = Color3.fromRGB(85, 170, 255),  Icon = "ℹ"}
}

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local desc = options.Description or ""
    local duration = options.Duration or 3
    local nType = NotifyTypes[options.Type or "Info"] or NotifyTypes.Info
    local accentColor = options.Color or nType.Color
    local iconText = options.Icon or nType.Icon

    -- Nếu đang có Dynamic Island thu nhỏ, ta cho phép nó phình to ra hiển thị thông báo
    if ActiveDynamicIsland and ActiveDynamicIsland.IsCollapsed() then
        ActiveDynamicIsland.MorphShowNotification(title, desc, accentColor, iconText, duration)
        return
    end

    -- Nếu UI đang mở hoặc không dùng Dynamic Island, hiển thị thông báo góc phải như bình thường
    local FallbackContainer = NotifyGui:FindFirstChild("NotifyContainer")
    if not FallbackContainer then
        FallbackContainer = Create("Frame", {
            Name = "NotifyContainer",
            Parent = NotifyGui,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -20, 1, -20),
            Size = UDim2.new(0, 320, 1, -40),
            AnchorPoint = Vector2.new(1, 1)
        }, {
            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                VerticalAlignment = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 10)
            })
        })
    end

    local Holder = Create("Frame", {
        Parent = FallbackContainer,
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1
    })

    local theme = Library.Themes[Library.CurrentTheme] or Library.Themes.Dark
    local Card = Create("Frame", {
        Parent = Holder,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(1, 360, 0, 0),
        BackgroundColor3 = theme.Main,
        BackgroundTransparency = 0.04,
        ClipsDescendants = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Name = "Stroke", Color = accentColor, Thickness = 1.5, Transparency = 0.2}),
        Create("TextLabel", {
            Name = "Icon",
            Text = iconText,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = accentColor,
            BackgroundColor3 = theme.Secondary,
            Size = UDim2.new(0, 38, 0, 38),
            Position = UDim2.new(0, 12, 0.5, -20)
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        }),
        Create("TextLabel", {
            Name = "Title",
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -68, 0, 20),
            Position = UDim2.new(0, 60, 0, 10),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextLabel", {
            Name = "Desc",
            Text = desc,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = theme.SubText,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -68, 0, 30),
            Position = UDim2.new(0, 60, 0, 30),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true
        }),
        Create("Frame", {
            Name = "ProgressBar",
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -3),
            Size = UDim2.new(1, 0, 0, 3)
        })
    })

    TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()

    TweenService:Create(Card.ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 3)
    }):Play()

    task.spawn(function()
        task.wait(duration)
        if not Card or not Card.Parent then return end

        TweenService:Create(Card, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 360, 0, 0),
            BackgroundTransparency = 1
        }):Play()

        task.wait(0.35)
        Holder:Destroy()
    end)
end

-- =========================================================
-- WINDOW & DYNAMIC ISLAND CREATION
-- =========================================================
function Library:CreateWindow(options)
    options = options or {}
    local titleText = options.Title or "Ultimate UI"
    local subtitleText = options.Subtitle or "v" .. Library.Version
    Library.CurrentTheme = options.Theme or "Dark"
    local theme = Library.Themes[Library.CurrentTheme] or Library.Themes.Dark

    local useIntro = options.Intro ~= false
    local introLogo = options.IntroLogo or ""
    local introAutoContinue = options.IntroAutoContinue or false

    local isToggled = true
    local introFinished = not useIntro
    local blurEnabled = options.Blur ~= false
    local baseScale = 1
    local Connections = {}

    local BlurEffect = Instance.new("BlurEffect")
    BlurEffect.Name = "UltimateUI_Blur"
    BlurEffect.Size = useIntro and 24 or (blurEnabled and 12 or 0)
    pcall(function() BlurEffect.Parent = Lighting end)

    local ScreenGui = Create("ScreenGui", {
        Name = titleText,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        ResetOnSpawn = false
    })
    ScreenGui.Parent = GetSafeGuiParent()

    -- =========================================================
    -- DYNAMIC ISLAND (ĐẢO ĐỘNG) Ở CHÍNH GIỮA CẠNH TRÊN MÀN HÌNH
    -- =========================================================
    local DynamicIsland = Create("TextButton", {
        Name = "DynamicIsland",
        Parent = ScreenGui,
        Size = UDim2.new(0, 126, 0, 32),
        Position = UDim2.new(0.5, 0, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(15, 15, 18),
        Text = "",
        Visible = false,
        AutoButtonColor = false,
        ZIndex = 999,
        ClipsDescendants = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
        Create("UIStroke", {Color = Color3.fromRGB(45, 45, 52), Thickness = 1.2}),
        
        -- Nội dung thu gọn (Icon + Chữ "UI")
        Create("Frame", {
            Name = "CollapsedContent",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = true
        }, {
            Create("TextLabel", {
                Text = "⚡",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                Size = UDim2.new(0, 30, 1, 0),
                Position = UDim2.new(0, 6, 0, 0),
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(85, 170, 255)
            }),
            Create("TextLabel", {
                Text = titleText,
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Size = UDim2.new(1, -36, 1, 0),
                Position = UDim2.new(0, 34, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(245, 245, 250)
            })
        }),

        -- Nội dung mở rộng (Dùng khi có Notification giãn rộng)
        Create("Frame", {
            Name = "ExpandedContent",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false
        }, {
            Create("TextLabel", {
                Name = "ExpIcon",
                Text = "ℹ",
                Font = Enum.Font.GothamBold,
                TextSize = 16,
                Size = UDim2.new(0, 34, 0, 34),
                Position = UDim2.new(0, 12, 0, 10),
                TextColor3 = Color3.fromRGB(85, 170, 255),
                BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 8)})
            }),
            Create("TextLabel", {
                Name = "ExpTitle",
                Text = "Title",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                Size = UDim2.new(1, -60, 0, 18),
                Position = UDim2.new(0, 54, 0, 9),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }),
            Create("TextLabel", {
                Name = "ExpDesc",
                Text = "Description",
                Font = Enum.Font.Gotham,
                TextSize = 11,
                Size = UDim2.new(1, -60, 0, 24),
                Position = UDim2.new(0, 54, 0, 26),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                BackgroundTransparency = 1,
                TextColor3 = Color3.fromRGB(180, 180, 190)
            })
        })
    })

    -- Main Window
    local Main = Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        Size = UDim2.new(0, 640, 0, 420),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = not useIntro,
        ClipsDescendants = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)})
    })
    BindTheme(Main, "BackgroundColor3", "Main")

    local MainStroke = Create("UIStroke", {Parent = Main, Thickness = 1.2})
    BindTheme(MainStroke, "Color", "Stroke")

    local MainScale = Create("UIScale", {Parent = Main, Scale = useIntro and 0.85 or 1})

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    if viewport.Y < 500 then
        baseScale = 0.78
        if not useIntro then MainScale.Scale = baseScale end
    end

    -- =========================================================
    -- iPHONE INTRO SEQUENCE
    -- =========================================================
    if useIntro then
        local IntroOverlay = Create("Frame", {
            Name = "iOSIntroOverlay",
            Parent = ScreenGui,
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(8, 8, 10),
            BackgroundTransparency = 0.04,
            ZIndex = 2000,
            ClipsDescendants = true
        })

        local AmbientGlow = Create("Frame", {
            Parent = IntroOverlay,
            Size = UDim2.new(0, 420, 0, 220),
            Position = UDim2.new(0.5, 0, 0.45, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.Accent,
            BackgroundTransparency = 1,
            ZIndex = 2001
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)})
        })

        local BootLogo = Create("TextLabel", {
            Parent = IntroOverlay,
            Text = introLogo,
            Font = Enum.Font.GothamBold,
            TextSize = 64,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 1,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 100, 0, 100),
            Position = UDim2.new(0.5, 0, 0.43, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 2002
        })

        local BootBarBg = Create("Frame", {
            Parent = IntroOverlay,
            Size = UDim2.new(0, 180, 0, 4),
            Position = UDim2.new(0.5, 0, 0.56, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(55, 55, 62),
            BackgroundTransparency = 1,
            ZIndex = 2002
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)})
        })

        local BootBarFill = Create("Frame", {
            Parent = BootBarBg,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            ZIndex = 2003
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)})
        })

        local HelloLabel = Create("TextLabel", {
            Parent = IntroOverlay,
            Text = "Hello",
            Font = Enum.Font.GothamBold,
            TextSize = 54,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 1,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 0, 75),
            Position = UDim2.new(0.5, 0, 0.44, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 2002
        })

        local WelcomeSub = Create("TextLabel", {
            Parent = IntroOverlay,
            Text = "Chào mừng đến với " .. titleText,
            Font = Enum.Font.Gotham,
            TextSize = 15,
            TextColor3 = Color3.fromRGB(185, 185, 195),
            TextTransparency = 1,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 0, 26),
            Position = UDim2.new(0.5, 0, 0.53, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ZIndex = 2002
        })

        local UnlockBtn = Create("TextButton", {
            Parent = IntroOverlay,
            Text = "Nhấn để bắt đầu",
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextTransparency = 1,
            BackgroundColor3 = Color3.fromRGB(45, 45, 55),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 190, 0, 42),
            Position = UDim2.new(0.5, 0, 0.82, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            AutoButtonColor = false,
            Visible = false,
            ZIndex = 2004
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
            Create("UIStroke", {Name = "Stroke", Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 1})
        })

        local HomeBar = Create("Frame", {
            Parent = IntroOverlay,
            Size = UDim2.new(0, 140, 0, 5),
            Position = UDim2.new(0.5, 0, 0.95, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            ZIndex = 2004
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)})
        })

        local unlocking = false
        local function FinishIntroAndOpenMain()
            if unlocking then return end
            unlocking = true
            introFinished = true

            TweenService:Create(IntroOverlay, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {
                Position = UDim2.new(0, 0, -1, 0),
                BackgroundTransparency = 1
            }):Play()

            if BlurEffect then
                TweenService:Create(BlurEffect, TweenInfo.new(0.5), {
                    Size = blurEnabled and 12 or 0
                }):Play()
            end

            task.wait(0.25)
            Main.Visible = true
            MainScale.Scale = baseScale * 0.85
            TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Scale = baseScale
            }):Play()

            task.delay(0.4, function()
                if IntroOverlay then IntroOverlay:Destroy() end
            end)
        end

        UnlockBtn.MouseButton1Click:Connect(FinishIntroAndOpenMain)

        task.spawn(function()
            TweenService:Create(BootLogo, TweenInfo.new(0.45, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
            task.wait(0.25)
            TweenService:Create(BootBarBg, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            TweenService:Create(BootBarFill, TweenInfo.new(1.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                Size = UDim2.new(1, 0, 1, 0)
            }):Play()
            task.wait(1.45)

            TweenService:Create(BootLogo, TweenInfo.new(0.35), {
                TextTransparency = 1,
                Position = UDim2.new(0.5, 0, 0.38, 0)
            }):Play()
            TweenService:Create(BootBarBg, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            TweenService:Create(BootBarFill, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            task.wait(0.35)

            UnlockBtn.Visible = true
            TweenService:Create(AmbientGlow, TweenInfo.new(0.8), {BackgroundTransparency = 0.88}):Play()
            TweenService:Create(WelcomeSub, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
            TweenService:Create(UnlockBtn, TweenInfo.new(0.5), {
                BackgroundTransparency = 0.25,
                TextTransparency = 0
            }):Play()
            TweenService:Create(UnlockBtn.Stroke, TweenInfo.new(0.5), {Transparency = 0.65}):Play()
            TweenService:Create(HomeBar, TweenInfo.new(0.5), {BackgroundTransparency = 0.25}):Play()

            local greetings = {"Hello", "Xin chào", "こんにちは", "Bonjour", "Hola"}
            local idx = 1

            if introAutoContinue then
                task.delay(3.2, FinishIntroAndOpenMain)
            end

            while not unlocking and IntroOverlay.Parent do
                HelloLabel.Text = greetings[idx]
                HelloLabel.Position = UDim2.new(0.5, 0, 0.46, 0)
                TweenService:Create(HelloLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                    Position = UDim2.new(0.5, 0, 0.43, 0)
                }):Play()

                task.wait(1.25)
                if unlocking then break end

                TweenService:Create(HelloLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    TextTransparency = 1,
                    Position = UDim2.new(0.5, 0, 0.40, 0)
                }):Play()
                task.wait(0.32)

                idx = (idx % #greetings) + 1
            end
        end)
    end

    -- Topbar
    local Topbar = Create("Frame", {
        Name = "Topbar",
        Parent = Main,
        Size = UDim2.new(1, 0, 0, 44),
        BorderSizePixel = 0
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 10)})
    })
    BindTheme(Topbar, "BackgroundColor3", "Secondary")

    local TopbarFix = Create("Frame", {
        Parent = Topbar,
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BorderSizePixel = 0
    })
    BindTheme(TopbarFix, "BackgroundColor3", "Secondary")

    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        Parent = Topbar,
        Text = titleText,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1
    })
    BindTheme(TitleLabel, "TextColor3", "Text")

    local SubtitleLabel = Create("TextLabel", {
        Name = "Subtitle",
        Parent = Topbar,
        Text = "|  " .. subtitleText,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.new(0, 16 + TitleLabel.TextBounds.X + 10, 0, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1
    })
    BindTheme(SubtitleLabel, "TextColor3", "SubText")

    local MinimizeButton = Create("TextButton", {
        Name = "MinimizeButton",
        Parent = Topbar,
        Text = "—",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -76, 0.5, -16),
        BackgroundTransparency = 0.2,
        AutoButtonColor = false
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    BindTheme(MinimizeButton, "BackgroundColor3", "Tertiary")
    BindTheme(MinimizeButton, "TextColor3", "Text")

    local CloseButton = Create("TextButton", {
        Name = "CloseButton",
        Parent = Topbar,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 95, 95),
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -38, 0.5, -16),
        BackgroundTransparency = 0.2,
        AutoButtonColor = false
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 6)})
    })
    BindTheme(CloseButton, "BackgroundColor3", "Tertiary")

    -- Sidebar (Tabs)
    local Sidebar = Create("ScrollingFrame", {
        Name = "Sidebar",
        Parent = Main,
        Size = UDim2.new(0, 165, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    }, {
        Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6)}),
        Create("UIPadding", {
            PaddingTop = UDim.new(0, 12),
            PaddingBottom = UDim.new(0, 12),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10)
        })
    })
    BindTheme(Sidebar, "BackgroundColor3", "Secondary")

    local ContentContainer = Create("Frame", {
        Name = "ContentContainer",
        Parent = Main,
        Size = UDim2.new(1, -165, 1, -44),
        Position = UDim2.new(0, 165, 0, 44),
        BackgroundTransparency = 1
    })

    MakeDraggable(Topbar, Main, Connections)

    local function ToggleUI(state)
        if not introFinished then return end
        isToggled = state
        if isToggled then
            DynamicIsland.Visible = false
            Main.Visible = true
            MainScale.Scale = baseScale * 0.85
            TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Scale = baseScale
            }):Play()
            if BlurEffect then
                TweenService:Create(BlurEffect, TweenInfo.new(0.3), {Size = blurEnabled and 12 or 0}):Play()
            end
        else
            TweenService:Create(MainScale, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Scale = baseScale * 0.85
            }):Play()
            if BlurEffect then
                TweenService:Create(BlurEffect, TweenInfo.new(0.22), {Size = 0}):Play()
            end
            task.delay(0.2, function()
                if not isToggled then
                    Main.Visible = false
                    DynamicIsland.Visible = true
                end
            end)
        end
    end

    -- Logic điều khiển Dynamic Island Morphing
    local isMorphing = false
    local function MorphShowNotification(title, desc, accentColor, iconText, duration)
        if isMorphing then return end
        isMorphing = true

        local collapsed = DynamicIsland.CollapsedContent
        local expanded = DynamicIsland.ExpandedContent

        expanded.ExpTitle.Text = title
        expanded.ExpDesc.Text = desc
        expanded.ExpIcon.Text = iconText
        expanded.ExpIcon.TextColor3 = accentColor

        -- Hiệu ứng phình to Dynamic Island (Morphing)
        TweenService:Create(DynamicIsland, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 320, 0, 64)
        }):Play()

        collapsed.Visible = false
        expanded.Visible = true

        task.delay(duration, function()
            if not DynamicIsland or not DynamicIsland.Parent then return end
            -- Thu nhỏ lại dạng viên thuốc ban đầu
            TweenService:Create(DynamicIsland, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 126, 0, 32)
            }):Play()
            expanded.Visible = false
            collapsed.Visible = true
            isMorphing = false
        end)
    end

    ActiveDynamicIsland = {
        IsCollapsed = function() return not isToggled end,
        MorphShowNotification = MorphShowNotification
    }

    DynamicIsland.MouseButton1Click:Connect(function()
        ToggleUI(true)
    end)

    local WindowObj = {
        CurrentTab = nil,
        Tabs = {},
        Connections = Connections
    }

    function WindowObj:Destroy()
        for _, conn in ipairs(Connections) do
            if conn.Connected then conn:Disconnect() end
        end
        if BlurEffect then BlurEffect:Destroy() end
        if ScreenGui then ScreenGui:Destroy() end
        ActiveDynamicIsland = nil
    end

    function WindowObj:SetScale(percent)
        baseScale = math.clamp(percent / 100, 0.5, 1.5)
        TweenService:Create(MainScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Scale = baseScale
        }):Play()
    end

    function WindowObj:SetBlur(enabled)
        blurEnabled = enabled
        if BlurEffect and isToggled and introFinished then
            TweenService:Create(BlurEffect, TweenInfo.new(0.3), {Size = blurEnabled and 12 or 0}):Play()
        end
    end

    MinimizeButton.MouseButton1Click:Connect(function() ToggleUI(false) end)
    CloseButton.MouseButton1Click:Connect(function() WindowObj:Destroy() end)

    local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            ToggleUI(not isToggled)
        end
    end)
    table.insert(Connections, keyConn)

    -- =========================================================
    -- TAB & COMPONENTS SYSTEM
    -- =========================================================
    function WindowObj:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        local tabName = tabOptions.Name or "Tab"
        local tabIcon = tabOptions.Icon or "•"

        local TabButton = Create("TextButton", {
            Name = tabName,
            Parent = Sidebar,
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            Text = tabIcon .. "   " .. tabName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false
        }, {
            Create("UIPadding", {PaddingLeft = UDim.new(0, 12)}),
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })
        BindTheme(TabButton, "BackgroundColor3", "Tertiary")
        BindTheme(TabButton, "TextColor3", "SubText")

        local ActiveBar = Create("Frame", {
            Parent = TabButton,
            Size = UDim2.new(0, 3, 0, 18),
            Position = UDim2.new(0, -12, 0.5, -9),
            BackgroundTransparency = 1
        }, {
            Create("UICorner", {CornerRadius = UDim.new(1, 0)})
        })
        BindTheme(ActiveBar, "BackgroundColor3", "Accent")

        local TabContent = Create("ScrollingFrame", {
            Name = tabName,
            Parent = ContentContainer,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        }, {
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
            Create("UIPadding", {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 15),
                PaddingLeft = UDim.new(0, 16),
                PaddingRight = UDim.new(0, 16)
            })
        })
        BindTheme(TabContent, "ScrollBarImageColor3", "Accent")

        TabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContent.UIListLayout.AbsoluteContentSize.Y + 25)
        end)

        local function ActivateTab()
            local curTheme = Library.Themes[Library.CurrentTheme]
            for _, tb in pairs(WindowObj.Tabs) do
                tb.Content.Visible = false
                TweenService:Create(tb.Button, TweenInfo.new(0.25), {
                    TextColor3 = curTheme.SubText,
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(tb.ActiveBar, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
            end
            TabContent.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.25), {
                TextColor3 = curTheme.Accent,
                BackgroundTransparency = 0.2
            }):Play()
            TweenService:Create(ActiveBar, TweenInfo.new(0.25), {BackgroundTransparency = 0}):Play()
        end

        TabButton.MouseButton1Click:Connect(ActivateTab)

        local TabObj = {Content = TabContent, Button = TabButton, ActiveBar = ActiveBar}
        table.insert(WindowObj.Tabs, TabObj)

        if not WindowObj.CurrentTab then
            WindowObj.CurrentTab = tabName
            ActivateTab()
        end

        function TabObj:CreateSection(sectionTitle)
            local Section = Create("Frame", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1
            })
            local lbl = Create("TextLabel", {
                Parent = Section,
                Text = string.upper(sectionTitle or "SECTION"),
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 4, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            })
            BindTheme(lbl, "TextColor3", "Accent")
            return Section
        end

        function TabObj:CreateButton(btnOptions)
            btnOptions = btnOptions or {}
            local btnName = btnOptions.Name or "Button"
            local descText = btnOptions.Description
            local iconText = btnOptions.Icon or "⚡"
            local callback = btnOptions.Callback or function() end
            local isLoading = false

            local height = descText and 54 or 42
            local Button = Create("TextButton", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, height),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            BindTheme(Button, "BackgroundColor3", "Secondary")

            local stroke = Create("UIStroke", {Parent = Button, Thickness = 1})
            BindTheme(stroke, "Color", "Stroke")

            local IconBox = Create("TextLabel", {
                Parent = Button,
                Text = iconText,
                Font = Enum.Font.GothamBold,
                TextSize = 15,
                Size = UDim2.new(0, 28, 0, 28),
                Position = UDim2.new(0, 12, 0.5, -14),
                BackgroundTransparency = 0.2
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
            BindTheme(IconBox, "BackgroundColor3", "Tertiary")
            BindTheme(IconBox, "TextColor3", "Accent")

            local TitleLbl = Create("TextLabel", {
                Parent = Button,
                Text = btnName,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Size = UDim2.new(1, -60, 0, 20),
                Position = descText and UDim2.new(0, 50, 0, 8) or UDim2.new(0, 50, 0.5, -10),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            })
            BindTheme(TitleLbl, "TextColor3", "Text")

            if descText then
                local DescLbl = Create("TextLabel", {
                    Parent = Button,
                    Text = descText,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    Size = UDim2.new(1, -60, 0, 16),
                    Position = UDim2.new(0, 50, 0, 29),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1
                })
                BindTheme(DescLbl, "TextColor3", "SubText")
            end

            Button.MouseEnter:Connect(function()
                local cur = Library.Themes[Library.CurrentTheme]
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = cur.Tertiary}):Play()
            end)
            Button.MouseLeave:Connect(function()
                local cur = Library.Themes[Library.CurrentTheme]
                TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = cur.Secondary}):Play()
            end)

            local BtnController = {}
            function BtnController:SetLoading(state)
                isLoading = state
                IconBox.Text = isLoading and "⏳" or iconText
                TitleLbl.Text = isLoading and (btnName .. " (Đang xử lý...)") or btnName
            end

            Button.MouseButton1Click:Connect(function()
                if isLoading then return end
                local cur = Library.Themes[Library.CurrentTheme]
                CreateRipple(Button, cur.Accent)
                task.spawn(function()
                    pcall(callback, BtnController)
                end)
            end)

            return BtnController
        end

        function TabObj:CreateToggle(tglOptions)
            tglOptions = tglOptions or {}
            local tglName = tglOptions.Name or "Toggle"
            local descText = tglOptions.Description
            local state = tglOptions.Default or false
            local flag = tglOptions.Flag or tglName
            local callback = tglOptions.Callback or function() end

            Library.Flags[flag] = state
            local height = descText and 54 or 42

            local Toggle = Create("TextButton", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, height),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            BindTheme(Toggle, "BackgroundColor3", "Secondary")

            local stroke = Create("UIStroke", {Parent = Toggle, Thickness = 1})
            BindTheme(stroke, "Color", "Stroke")

            local TitleLbl = Create("TextLabel", {
                Parent = Toggle,
                Text = tglName,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Size = UDim2.new(1, -75, 0, 20),
                Position = descText and UDim2.new(0, 15, 0, 8) or UDim2.new(0, 15, 0.5, -10),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            })
            BindTheme(TitleLbl, "TextColor3", "Text")

            if descText then
                local DescLbl = Create("TextLabel", {
                    Parent = Toggle,
                    Text = descText,
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    Size = UDim2.new(1, -75, 0, 16),
                    Position = UDim2.new(0, 15, 0, 29),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1
                })
                BindTheme(DescLbl, "TextColor3", "SubText")
            end

            local Switch = Create("Frame", {
                Name = "Switch",
                Parent = Toggle,
                Size = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(1, -58, 0.5, -11),
                BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff
            }, {
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })

            local Indicator = Create("Frame", {
                Name = "Indicator",
                Parent = Switch,
                Size = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }, {
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })

            local ToggleController = {}
            function ToggleController:Set(newState)
                state = newState
                Library.Flags[flag] = state
                local cur = Library.Themes[Library.CurrentTheme]
                TweenService:Create(Switch, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                    BackgroundColor3 = state and cur.ToggleOn or cur.ToggleOff
                }):Play()
                TweenService:Create(Indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                    Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                }):Play()
                pcall(callback, state)
            end

            Toggle.MouseButton1Click:Connect(function()
                ToggleController:Set(not state)
            end)

            return ToggleController
        end

        function TabObj:CreateSlider(sldOptions)
            sldOptions = sldOptions or {}
            local sldName = sldOptions.Name or "Slider"
            local min = sldOptions.Min or 0
            local max = sldOptions.Max or 100
            local step = sldOptions.Step or 1
            local default = math.clamp(sldOptions.Default or min, min, max)
            local suffix = sldOptions.Suffix or ""
            local flag = sldOptions.Flag or sldName
            local callback = sldOptions.Callback or function() end

            Library.Flags[flag] = default

            local Slider = Create("Frame", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 58)
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            BindTheme(Slider, "BackgroundColor3", "Secondary")

            local stroke = Create("UIStroke", {Parent = Slider, Thickness = 1})
            BindTheme(stroke, "Color", "Stroke")

            local TitleLbl = Create("TextLabel", {
                Parent = Slider,
                Text = sldName,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Size = UDim2.new(1, -90, 0, 28),
                Position = UDim2.new(0, 15, 0, 4),
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1
            })
            BindTheme(TitleLbl, "TextColor3", "Text")

            local ValueBox = Create("TextBox", {
                Name = "ValueBox",
                Parent = Slider,
                Text = tostring(default) .. suffix,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                Size = UDim2.new(0, 64, 0, 22),
                Position = UDim2.new(1, -78, 0, 7),
                ClearTextOnFocus = true
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 5)})
            })
            BindTheme(ValueBox, "BackgroundColor3", "Tertiary")
            BindTheme(ValueBox, "TextColor3", "Accent")

            local SliderArea = Create("TextButton", {
                Name = "SliderArea",
                Parent = Slider,
                Size = UDim2.new(1, -30, 0, 8),
                Position = UDim2.new(0, 15, 0, 40),
                Text = "",
                AutoButtonColor = false
            }, {
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            BindTheme(SliderArea, "BackgroundColor3", "Main")

            local initPercent = (default - min) / (max - min)
            local Fill = Create("Frame", {
                Name = "Fill",
                Parent = SliderArea,
                Size = UDim2.new(initPercent, 0, 1, 0)
            }, {
                Create("UICorner", {CornerRadius = UDim.new(1, 0)})
            })
            BindTheme(Fill, "BackgroundColor3", "Accent")

            local function RoundToStep(val)
                local stepped = min + math.floor(((val - min) / step) + 0.5) * step
                local decimals = tostring(step):match("%.(%d+)")
                if decimals then
                    stepped = tonumber(string.format("%." .. #decimals .. "f", stepped))
                end
                return math.clamp(stepped, min, max)
            end

            local SliderController = {}
            function SliderController:Set(val)
                local cleanVal = RoundToStep(val)
                local percent = (cleanVal - min) / (max - min)
                Library.Flags[flag] = cleanVal
                TweenService:Create(Fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(percent, 0, 1, 0)
                }):Play()
                ValueBox.Text = tostring(cleanVal) .. suffix
                pcall(callback, cleanVal)
            end

            local Dragging = false
            local function UpdateFromInput(input)
                local percent = math.clamp((input.Position.X - SliderArea.AbsolutePosition.X) / SliderArea.AbsoluteSize.X, 0, 1)
                local rawVal = min + (max - min) * percent
                SliderController:Set(rawVal)
            end

            SliderArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    UpdateFromInput(input)
                end
            end)

            local sEnd = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)

            local sMove = UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end)
            table.insert(Connections, sEnd)
            table.insert(Connections, sMove)

            ValueBox.FocusLost:Connect(function()
                local num = tonumber(ValueBox.Text:match("[-%d%.]+"))
                if num then
                    SliderController:Set(num)
                else
                    ValueBox.Text = tostring(Library.Flags[flag]) .. suffix
                end
            end)

            return SliderController
        end

        function TabObj:CreateDropdown(dropOptions)
            dropOptions = dropOptions or {}
            local dropName = dropOptions.Name or "Dropdown"
            local options = dropOptions.Options or {}
            local multi = dropOptions.Multi or false
            local searchable = dropOptions.Searchable ~= false
            local flag = dropOptions.Flag or dropName
            local callback = dropOptions.Callback or function() end
            local isOpen = false

            local selected = multi and {} or (dropOptions.Default or options[1] or "None")
            if multi and type(dropOptions.Default) == "table" then
                for _, v in ipairs(dropOptions.Default) do selected[v] = true end
            end
            Library.Flags[flag] = selected

            local function GetSelectedString()
                if not multi then return tostring(selected) end
                local list = {}
                for _, opt in ipairs(options) do
                    if selected[opt] then table.insert(list, opt) end
                end
                return #list > 0 and table.concat(list, ", ") or "None"
            end

            local Dropdown = Create("Frame", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 42),
                ClipsDescendants = true
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 8)})
            })
            BindTheme(Dropdown, "BackgroundColor3", "Secondary")

            local stroke = Create("UIStroke", {Parent = Dropdown, Thickness = 1})
            BindTheme(stroke, "Color", "Stroke")

            local HeaderBtn = Create("TextButton", {
                Parent = Dropdown,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
                Text = ""
            })

            local TitleLbl = Create("TextLabel", {
                Name = "Title",
                Parent = HeaderBtn,
                Text = dropName .. " :  " .. GetSelectedString(),
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Size = UDim2.new(1, -45, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                BackgroundTransparency = 1
            })
            BindTheme(TitleLbl, "TextColor3", "Text")

            local Arrow = Create("TextLabel", {
                Parent = HeaderBtn,
                Text = "▼",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                Size = UDim2.new(0, 24, 0, 42),
                Position = UDim2.new(1, -32, 0, 0),
                BackgroundTransparency = 1
            })
            BindTheme(Arrow, "TextColor3", "SubText")

            local SearchBox
            local topOffset = 46
            if searchable then
                SearchBox = Create("TextBox", {
                    Parent = Dropdown,
                    PlaceholderText = "🔍 Tìm kiếm...",
                    Text = "",
                    Font = Enum.Font.Gotham,
                    TextSize = 13,
                    Size = UDim2.new(1, -24, 0, 28),
                    Position = UDim2.new(0, 12, 0, 46),
                    ClearTextOnFocus = false
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                    Create("UIPadding", {PaddingLeft = UDim.new(0, 10)})
                })
                BindTheme(SearchBox, "BackgroundColor3", "Main")
                BindTheme(SearchBox, "TextColor3", "Text")
                BindTheme(SearchBox, "PlaceholderColor3", "SubText")
                topOffset = 80
            end

            local Container = Create("ScrollingFrame", {
                Name = "Container",
                Parent = Dropdown,
                Size = UDim2.new(1, -24, 0, 115),
                Position = UDim2.new(0, 12, 0, topOffset),
                BackgroundTransparency = 1,
                ScrollBarThickness = 2,
                CanvasSize = UDim2.new(0, 0, 0, 0)
            }, {
                Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)})
            })
            BindTheme(Container, "ScrollBarImageColor3", "Accent")

            local OptionButtons = {}

            local function UpdateDropdownHeight()
                if not isOpen then
                    TweenService:Create(Dropdown, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                        Size = UDim2.new(1, 0, 0, 42)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.25), {Rotation = 0}):Play()
                else
                    local visibleCount = 0
                    for _, btn in ipairs(OptionButtons) do
                        if btn.Visible then visibleCount = visibleCount + 1 end
                    end
                    local listHeight = math.clamp(visibleCount * 32, 32, 128)
                    Container.Size = UDim2.new(1, -24, 0, listHeight)
                    TweenService:Create(Dropdown, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                        Size = UDim2.new(1, 0, 0, topOffset + listHeight + 10)
                    }):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.25), {Rotation = 180}):Play()
                end
            end

            local function RebuildOptions()
                for _, b in ipairs(OptionButtons) do b:Destroy() end
                table.clear(OptionButtons)

                for _, opt in ipairs(options) do
                    local isSel = multi and selected[opt] or (selected == opt)
                    local OptBtn = Create("TextButton", {
                        Name = tostring(opt),
                        Parent = Container,
                        Size = UDim2.new(1, 0, 0, 28),
                        Text = (isSel and "✓  " or "     ") .. tostring(opt),
                        Font = isSel and Enum.Font.GothamBold or Enum.Font.Gotham,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false
                    }, {
                        Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                        Create("UIPadding", {PaddingLeft = UDim.new(0, 8)})
                    })
                    BindTheme(OptBtn, "BackgroundColor3", isSel and "Tertiary" or "Main")
                    BindTheme(OptBtn, "TextColor3", isSel and "Accent" or "Text")

                    OptBtn.MouseButton1Click:Connect(function()
                        if multi then
                            selected[opt] = not selected[opt]
                            Library.Flags[flag] = selected
                            TitleLbl.Text = dropName .. " :  " .. GetSelectedString()
                            RebuildOptions()
                            pcall(callback, selected)
                        else
                            selected = opt
                            Library.Flags[flag] = selected
                            TitleLbl.Text = dropName .. " :  " .. GetSelectedString()
                            RebuildOptions()
                            isOpen = false
                            UpdateDropdownHeight()
                            pcall(callback, selected)
                        end
                    end)
                    table.insert(OptionButtons, OptBtn)
                end
                Container.CanvasSize = UDim2.new(0, 0, 0, #OptionButtons * 32)
            end

            RebuildOptions()

            if SearchBox then
                SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local query = string.lower(SearchBox.Text)
                    for _, btn in ipairs(OptionButtons) do
                        btn.Visible = string.find(string.lower(btn.Name), query, 1, true) ~= nil
                    end
                    UpdateDropdownHeight()
                end)
            end

            HeaderBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                UpdateDropdownHeight()
            end)

            local DropController = {}
            function DropController:Refresh(newOptions, newDefault)
                options = newOptions or {}
                if newDefault then selected = newDefault end
                TitleLbl.Text = dropName .. " :  " .. GetSelectedString()
                RebuildOptions()
                UpdateDropdownHeight()
            end
            return DropController
        end

        function TabObj:CreateTextButton(tbOptions)
            tbOptions = tbOptions or {}
            local text = tbOptions.Text or "TextButton"
            local bgColor = tbOptions.BackgroundColor
            local txtColor = tbOptions.TextColor
            local callback = tbOptions.Callback or function() end

            local TBtn = Create("TextButton", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 38),
                Text = text,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                AutoButtonColor = false
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 8)})
            })

            if bgColor then TBtn.BackgroundColor3 = bgColor else BindTheme(TBtn, "BackgroundColor3", "Accent") end
            if txtColor then TBtn.TextColor3 = txtColor else BindTheme(TBtn, "TextColor3", "Text") end

            TBtn.MouseButton1Click:Connect(function()
                CreateRipple(TBtn, Color3.fromRGB(255, 255, 255))
                pcall(callback)
            end)
            return TBtn
        end

        function TabObj:CreateLabel(lblOptions)
            lblOptions = lblOptions or {}
            local text = lblOptions.Text or "Label"

            local LblFrame = Create("Frame", {
                Parent = TabContent,
                Size = UDim2.new(1, 0, 0, 34)
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)})
            })
            BindTheme(LblFrame, "BackgroundColor3", "Secondary")

            local Label = Create("TextLabel", {
                Parent = LblFrame,
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = text,
                RichText = true,
                Font = Enum.Font.Gotham,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            BindTheme(Label, "TextColor3", "Text")

            local LabelController = {}
            function LabelController:SetText(newText)
                Label.Text = tostring(newText)
            end
            return LabelController
        end

        return TabObj
    end

    return WindowObj
end

return Library
