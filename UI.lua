-- =========================================================
-- ULTIMATE ROBLOX EXECUTOR-STYLE UI FRAMEWORK V1.1
-- =========================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Library = {
    Themes = {
        Dark = {
            Main = Color3.fromRGB(28, 28, 32),
            Secondary = Color3.fromRGB(38, 38, 44),
            Stroke = Color3.fromRGB(60, 60, 68),
            Text = Color3.fromRGB(255, 255, 255),
            Accent = Color3.fromRGB(85, 170, 255),
            ToggleOn = Color3.fromRGB(85, 255, 127),
            ToggleOff = Color3.fromRGB(90, 90, 98)
        }
    }
}

-- Utility: Lấy vùng chứa GUI an toàn cho cả Studio & Executor
local function GetSafeGuiParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if success and parent then return parent end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Utility: Tạo UI nhanh
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

-- Utility: Kéo thả UI
local function MakeDraggable(topbarobject, object)
    local Dragging, DragInput, DragStart, StartPos
    topbarobject.InputBegan:Connect(function(input)
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
    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            local delta = input.Position - DragStart
            object.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
end

-- =========================================================
-- NOTIFICATION SYSTEM (FIXED)
-- =========================================================
local NotifyGui = Create("ScreenGui", {
    Name = "UltimateUINotify",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false
})
NotifyGui.Parent = GetSafeGuiParent()

local NotifyLayout = Create("Frame", {
    Name = "NotifyContainer",
    Parent = NotifyGui,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.new(0, 310, 1, -40),
    AnchorPoint = Vector2.new(1, 1)
}, {
    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 10)
    })
})

local NotifyTypes = {
    Success = {Color = Color3.fromRGB(85, 255, 127), Icon = "✓"},
    Warning = {Color = Color3.fromRGB(255, 185, 65),  Icon = "⚠"},
    Error   = {Color = Color3.fromRGB(255, 85, 85),  Icon = "✕"},
    Info    = {Color = Color3.fromRGB(85, 170, 255), Icon = "ℹ"}
}

function Library:Notify(options)
    options = options or {}
    local title = options.Title or "Notification"
    local desc = options.Description or ""
    local duration = options.Duration or 3
    local nType = NotifyTypes[options.Type or "Info"] or NotifyTypes.Info
    local accentColor = options.Color or nType.Color
    local iconText = options.Icon or nType.Icon

    local Holder = Create("Frame", {
        Parent = NotifyLayout,
        Size = UDim2.new(1, 0, 0, 68),
        BackgroundTransparency = 1
    })

    local Card = Create("Frame", {
        Parent = Holder,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(1, 350, 0, 0),
        BackgroundColor3 = Library.Themes.Dark.Main,
        BackgroundTransparency = 0.05,
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
            BackgroundColor3 = Library.Themes.Dark.Secondary,
            Size = UDim2.new(0, 36, 0, 36),
            Position = UDim2.new(0, 12, 0.5, -20)
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        }),
        Create("TextLabel", {
            Name = "Title",
            Text = title,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Library.Themes.Dark.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -65, 0, 20),
            Position = UDim2.new(0, 58, 0, 10),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Create("TextLabel", {
            Name = "Desc",
            Text = desc,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(200, 200, 200),
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -65, 0, 28),
            Position = UDim2.new(0, 58, 0, 30),
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

        TweenService:Create(Card, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 350, 0, 0),
            BackgroundTransparency = 1
        }):Play()

        TweenService:Create(Card.Stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
        TweenService:Create(Card.Title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(Card.Desc, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(Card.Icon, TweenInfo.new(0.3), {TextTransparency = 1, BackgroundTransparency = 1}):Play()

        task.wait(0.35)
        TweenService:Create(Holder, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, 0)
        }):Play()
        task.wait(0.2)
        Holder:Destroy()
    end)
end

-- =========================================================
-- WINDOW & COMPONENT CREATION
-- =========================================================
function Library:CreateWindow(options)
    local titleText = options.Title or "Ultimate UI"
    local theme = Library.Themes[options.Theme or "Dark"]
    local isToggled = true

    local ScreenGui = Create("ScreenGui", {
        Name = titleText,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })
    ScreenGui.Parent = GetSafeGuiParent()

    local OpenButton = Create("TextButton", {
        Name = "OpenUI", Parent = ScreenGui, Size = UDim2.new(0, 45, 0, 45),
        Position = UDim2.new(0, 20, 0.5, -22.5), BackgroundColor3 = theme.Secondary,
        Text = "UI", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.Accent,
        Visible = false, AutoButtonColor = false, ZIndex = 999
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = theme.Stroke, Thickness = 1})
    })
    MakeDraggable(OpenButton, OpenButton)

    local Main = Create("Frame", {
        Name = "Main", Parent = ScreenGui, Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200), BackgroundColor3 = theme.Main, ClipsDescendants = true
    }, {
        Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
        Create("UIStroke", {Color = theme.Stroke, Thickness = 1}),
        Create("Frame", {
            Name = "Topbar", Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = theme.Secondary, BorderSizePixel = 0
        }, {
            Create("UICorner", {CornerRadius = UDim.new(0, 8)}),
            Create("Frame", {Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = theme.Secondary, BorderSizePixel = 0}),
            Create("TextLabel", {
                Name = "Title", Text = titleText, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = theme.Text,
                Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
            }),
            Create("TextButton", {
                Name = "MinimizeButton", Text = "-", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = theme.Text,
                Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -70, 0.5, -15), BackgroundTransparency = 1
            }),
            Create("TextButton", {
                Name = "CloseButton", Text = "×", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.fromRGB(255, 85, 85),
                Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -35, 0.5, -15), BackgroundTransparency = 1
            })
        }),
        Create("Frame", {
            Name = "Sidebar", Size = UDim2.new(0, 150, 1, -40), Position = UDim2.new(0, 0, 0, 40), BackgroundColor3 = theme.Secondary, BorderSizePixel = 0
        }, {
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)})
        }),
        Create("Frame", {
            Name = "ContentContainer", Size = UDim2.new(1, -150, 1, -40), Position = UDim2.new(0, 150, 0, 40), BackgroundTransparency = 1
        })
    })

    MakeDraggable(Main.Topbar, Main)

    local function ToggleUI(state)
        isToggled = state
        Main.Visible = isToggled
        OpenButton.Visible = not isToggled
    end

    Main.Topbar.MinimizeButton.MouseButton1Click:Connect(function()
        ToggleUI(false)
    end)

    Main.Topbar.CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    OpenButton.MouseButton1Click:Connect(function()
        ToggleUI(true)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            ToggleUI(not isToggled)
        end
    end)

    local WindowObj = {
        CurrentTab = nil,
        Tabs = {}
    }

    function WindowObj:CreateTab(tabOptions)
        local tabName = tabOptions.Name or "Tab"
        
        local TabButton = Create("TextButton", {
            Name = tabName, Parent = Main.Sidebar, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1,
            Text = tabName, Font = Enum.Font.GothamSemibold, TextSize = 14, TextColor3 = Color3.fromRGB(150, 150, 150), TextXAlignment = Enum.TextXAlignment.Left,
        }, {
            Create("UIPadding", {PaddingLeft = UDim.new(0, 10)}),
            Create("UICorner", {CornerRadius = UDim.new(0, 6)})
        })

        local TabContent = Create("ScrollingFrame", {
            Name = tabName, Parent = Main.ContentContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Visible = false, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0)
        }, {
            Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)}),
            Create("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 15)})
        })

        TabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContent.UIListLayout.AbsoluteContentSize.Y + 20)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, tb in pairs(WindowObj.Tabs) do
                tb.Content.Visible = false
                TweenService:Create(tb.Button, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150, 150, 150), BackgroundTransparency = 1}):Play()
            end
            TabContent.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {TextColor3 = theme.Accent, BackgroundTransparency = 0.9}):Play()
        end)

        if not WindowObj.CurrentTab then
            WindowObj.CurrentTab = tabName
            TabContent.Visible = true
            TabButton.TextColor3 = theme.Accent
            TabButton.BackgroundTransparency = 0.9
        end

        local TabObj = {Content = TabContent, Button = TabButton}
        table.insert(WindowObj.Tabs, TabObj)

        function TabObj:CreateButton(btnOptions)
            local btnName = btnOptions.Name or "Button"
            local callback = btnOptions.Callback or function() end

            local Button = Create("TextButton", {
                Parent = TabContent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = theme.Secondary,
                Text = btnName, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Text, AutoButtonColor = false
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("UIStroke", {Color = theme.Stroke, Thickness = 1})
            })

            Button.MouseEnter:Connect(function() TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}):Play() end)
            Button.MouseLeave:Connect(function() TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = theme.Secondary}):Play() end)
            Button.MouseButton1Down:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1), {Size = UDim2.new(0.98, 0, 0, 38)}):Play()
            end)
            Button.MouseButton1Up:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 40)}):Play()
                callback()
            end)
        end

        function TabObj:CreateToggle(tglOptions)
            local tglName = tglOptions.Name or "Toggle"
            local state = tglOptions.Default or false
            local callback = tglOptions.Callback or function() end

            local Toggle = Create("TextButton", {
                Parent = TabContent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = theme.Secondary, Text = "", AutoButtonColor = false
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("UIStroke", {Color = theme.Stroke, Thickness = 1}),
                Create("TextLabel", {
                    Text = tglName, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Text,
                    Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
                }),
                Create("Frame", {
                    Name = "Switch", Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -55, 0.5, -10),
                    BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff,
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
                    Create("Frame", {
                        Name = "Indicator", Size = UDim2.new(0, 16, 0, 16), Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
                })
            })

            local function FireToggle()
                state = not state
                local Switch = Toggle.Switch
                TweenService:Create(Switch, TweenInfo.new(0.3), {BackgroundColor3 = state and theme.ToggleOn or theme.ToggleOff}):Play()
                TweenService:Create(Switch.Indicator, TweenInfo.new(0.3), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                callback(state)
            end

            Toggle.MouseButton1Click:Connect(FireToggle)
        end

        function TabObj:CreateSlider(sldOptions)
            local sldName = sldOptions.Name or "Slider"
            local min = sldOptions.Min or 0
            local max = sldOptions.Max or 100
            local default = sldOptions.Default or min
            local callback = sldOptions.Callback or function() end

            local Slider = Create("Frame", {
                Parent = TabContent, Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = theme.Secondary
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("UIStroke", {Color = theme.Stroke, Thickness = 1}),
                Create("TextLabel", {
                    Text = sldName, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Text,
                    Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
                }),
                Create("TextLabel", {
                    Name = "Value", Text = tostring(default), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Accent,
                    Size = UDim2.new(0, 50, 0, 30), Position = UDim2.new(1, -65, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, BackgroundTransparency = 1
                }),
                Create("TextButton", {
                    Name = "SliderArea", Size = UDim2.new(1, -30, 0, 10), Position = UDim2.new(0, 15, 0, 35),
                    BackgroundColor3 = theme.Main, Text = "", AutoButtonColor = false
                }, {
                    Create("UICorner", {CornerRadius = UDim.new(1, 0)}),
                    Create("Frame", {
                        Name = "Fill", Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = theme.Accent
                    }, {Create("UICorner", {CornerRadius = UDim.new(1, 0)})})
                })
            })

            local SliderArea = Slider.SliderArea
            local Fill = SliderArea.Fill
            local ValueLabel = Slider.Value
            local Dragging = false

            local function UpdateSlider(input)
                local percent = math.clamp((input.Position.X - SliderArea.AbsolutePosition.X) / SliderArea.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * percent)
                TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
                ValueLabel.Text = tostring(value)
                callback(value)
            end

            SliderArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    UpdateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
        end

        function TabObj:CreateDropdown(dropOptions)
            local dropName = dropOptions.Name or "Dropdown"
            local options = dropOptions.Options or {}
            local default = dropOptions.Default or options[1]
            local callback = dropOptions.Callback or function() end
            local isOpen = false

            local Dropdown = Create("TextButton", {
                Parent = TabContent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = theme.Secondary, Text = "", AutoButtonColor = false, ClipsDescendants = true
            }, {
                Create("UICorner", {CornerRadius = UDim.new(0, 6)}),
                Create("UIStroke", {Color = theme.Stroke, Thickness = 1}),
                Create("TextLabel", {
                    Name = "Title", Text = dropName .. " : " .. tostring(default), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Text,
                    Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 15, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1
                }),
                Create("TextLabel", {
                    Name = "Icon", Text = "▼", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = theme.Text,
                    Size = UDim2.new(0, 20, 0, 40), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1
                }),
                Create("ScrollingFrame", {
                    Name = "Container", Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 45), BackgroundTransparency = 1,
                    ScrollBarThickness = 2, CanvasSize = UDim2.new(0,0,0,0)
                }, {
                    Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)})
                })
            })

            local Container = Dropdown.Container
            local ListLayout = Container.UIListLayout

            local function ToggleDropdown()
                isOpen = not isOpen
                local targetHeight = isOpen and math.clamp(#options * 30, 0, 120) or 0
                local targetDropHeight = isOpen and (50 + targetHeight) or 40
                
                TweenService:Create(Dropdown, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, 0, 0, targetDropHeight)}):Play()
                TweenService:Create(Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = UDim2.new(1, -20, 0, targetHeight)}):Play()
                Dropdown.Icon.Rotation = isOpen and 180 or 0
            end

            Dropdown.MouseButton1Click:Connect(ToggleDropdown)

            for i, opt in pairs(options) do
                local OptBtn = Create("TextButton", {
                    Parent = Container, Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = theme.Main,
                    Text = opt, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = theme.Text, AutoButtonColor = false
                }, {Create("UICorner", {CornerRadius = UDim.new(0, 4)})})

                OptBtn.MouseButton1Click:Connect(function()
                    Dropdown.Title.Text = dropName .. " : " .. opt
                    callback(opt)
                    ToggleDropdown()
                end)
            end
            
            ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Container.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
            end)
        end

        function TabObj:CreateLabel(lblOptions)
            Create("TextLabel", {
                Parent = TabContent, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
                Text = lblOptions.Text or "Label", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = theme.Text, TextXAlignment = Enum.TextXAlignment.Left
            }, {Create("UIPadding", {PaddingLeft = UDim.new(0, 5)})})
        end

        return TabObj
    end

    return WindowObj
end

return Library
