  local library = {
    flags = {}
  }
  library.Flags = library.flags
  
  --// Dependences --//
  local CoreGui = game:GetService("CoreGui")
  local TweenService = game:GetService("TweenService")
  local UserInputService = game:GetService("UserInputService")
  local RunService = game:GetService("RunService")
  
  local ViewportSize = workspace.CurrentCamera.ViewportSize
  
  local Mouse = game.Players.LocalPlayer:GetMouse()
  
  local Utilities = {}

  --// Compatibility //--
  local request = syn and syn.request or http and http.request or http_request or request or httprequest
  local getcustomasset = getcustomasset or getsynasset
  local isfolder = isfolder or syn_isfolder or is_folder
  local makefolder = makefolder or make_folder or createfolder or create_folder
  --//

  local DropIndex = 9999
  
  function Utilities:Create(Inst, Properties, Childs)
  local Instance = Instance.new(Inst)
  local Properties = Properties or {}
  local Childs = Childs or {}
  
  local BlacklistedProps = {
      BorderSizePixel = 0,
      Text = "",
      BackgroundColor3 = Color3.fromRGB(255, 255, 255)
  }
  
  for blprop, v in pairs(BlacklistedProps) do
      pcall(function()
          Instance[blprop] = v
      end)
  end
  
  for prop, v in pairs(Properties) do
      Instance[prop] = v
  end
  
  for _, child in pairs(Childs) do
      child.Parent = Instance
  end
  
  return Instance
  end

  function Utilities:Round(Number, Increment)
    Increment = 1 / Increment

    return math.round(Number * Increment) / Increment
end
  
  function Utilities:Tween(Inst, Speed, Properties, Style, Direction)
  local Instance = Inst or error("#1 argument: instance expected.")
  local Speed = Speed or .125
  local Properties = typeof(Properties) == "table" and Properties or error("#3 argument: table expected, got: "..typeof(Properties))
  local Style = Style or Enum.EasingStyle.Linear
  local Direction = Direction or Enum.EasingDirection.Out
  
  local Tween = TweenService:Create(Instance, TweenInfo.new(Speed, Style, Direction), Properties)
  Tween:Play()
  
  return Tween
  end

  function Utilities:GetXY(GuiObject)
	local Max, May = GuiObject.AbsoluteSize.X, GuiObject.AbsoluteSize.Y
	local Px, Py = math.clamp(Mouse.X - GuiObject.AbsolutePosition.X, 0, Max), math.clamp(Mouse.Y - GuiObject.AbsolutePosition.Y, 0, May)
	return Px/Max, Py/May
  end

  function Utilities:GetMouse()
	return Vector2.new(UserInputService:GetMouseLocation().X + 1, UserInputService:GetMouseLocation().Y - 35)
  end

  if not isfolder("PPHUD") then
    makefolder("PPHUD")

    local Arrow = request({Url = "https://raw.githubusercontent.com/Rain-Design/PPHUD/main/Dropdown.png", Method = "GET"})
    writefile("PPHUD/Arrow.png", Arrow.Body)

    local Resize = request({Url = "https://raw.githubusercontent.com/Rain-Design/PPHUD/main/resize.png", Method = "GET"})
    writefile("PPHUD/Resize.png", Resize.Body)
  end
  --//
  
  --// Colors --//
  local Colors = {
      Primary = Color3.fromRGB(27, 25, 27),
      Secondary = Color3.fromRGB(42, 40, 42),
      Tertiary = Color3.fromRGB(74, 73, 74),
      Divider = Color3.fromRGB(46, 45, 46),
      AccentDivider = Color3.fromRGB(54, 54, 54),
      PrimaryText = Color3.fromRGB(211, 211, 211),
      SecondaryText = Color3.fromRGB(122, 122, 122),
      TertiaryText = Color3.fromRGB(158, 158, 158),
      Hovering = Color3.fromRGB(56, 53, 56),
      Accent = Color3.fromRGB(100, 190, 31),
      DarkerAccent = Color3.fromRGB(87, 167, 26),
      AccentText = Color3.fromRGB(235, 235, 235)
  }
  --//
  
  function library:Window(WindowArgs)
  WindowArgs.Text = WindowArgs.Text or "Window"
  
  local WindowTable = {}
  WindowTable.__index = WindowTable
  WindowTable._connections = {}

  local function trackInput(connection)
      if connection then
          table.insert(WindowTable._connections, connection)
      end
      return connection
  end
  
  self.Tabs = 0
  self.Hovering = false
  
  local SelectedTab = nil
  
  local Window = Utilities:Create("ScreenGui", {
      Name = "PPHUD",
      ZIndexBehavior = Enum.ZIndexBehavior.Global
  }, {
      Utilities:Create("Frame", {
          Name = "Main",
          Size = UDim2.new(0, 900, 0, 560),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255), -- Colors.Primary
          ClipsDescendants = true,
          Position = UDim2.new(0, 80, 0, 80)
      }, {
          Utilities:Create("UIGradient", {
              Color = ColorSequence.new({
                  ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 25, 27)),
                  ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 10, 12)),
              }),
              Offset = Vector2.new(0, 0.65),
              Rotation = 90
          }),
          Utilities:Create("Frame", {
              Name = "Containers",
              Size = UDim2.new(1, 0, 1, -50),
              BackgroundTransparency = 1,
              Position = UDim2.new(0, 0, 0, 26)
          }),
          Utilities:Create("Frame", {
              Name = "Bottom",
              Size = UDim2.new(1, 0, 0, 24),
              AnchorPoint = Vector2.new(.5, 1),
              Position = UDim2.new(.5, 0, 1, 0),
              BackgroundColor3 = Colors.Secondary,
              ZIndex = DropIndex + 5
          }, {
              Utilities:Create("Frame", {
                  Name = "Divider",
                  Size = UDim2.new(1, 0, 0, 1),
                  AnchorPoint = Vector2.new(.5, 0),
                  BackgroundColor3 = Colors.Divider,
                  Position = UDim2.new(.5, 0, 0, 0),
                  ZIndex = DropIndex + 5
              }),
              Utilities:Create("ImageLabel", {
                Name = "ResizeIcon",
                Size = UDim2.new(0, 10, 0, 10),
                BackgroundTransparency = 1,
                Image = getcustomasset("PPHUD/Resize.png"),
                AnchorPoint = Vector2.new(1, 1),
                Position = UDim2.new(1, 0, 1, 0),
                ZIndex = DropIndex + 5
              }, {
                Utilities:Create("TextButton", {
                    Name = "ResizeButton",
                    Size = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    ZIndex = DropIndex + 5
                })
              }),
              Utilities:Create("TextLabel", {
                  Name = "BottomText",
                  Text = WindowArgs.Text,
                  Size = UDim2.new(1, -10, 0, 24),
                  BackgroundTransparency = 1,
                  Position = UDim2.new(0, 8, 0, 0),
                  RichText = true,
                  TextXAlignment = Enum.TextXAlignment.Left,
                  TextSize = 13,
                  Font = Enum.Font.SourceSansBold,
                  TextColor3 = Colors.PrimaryText,
                  ZIndex = DropIndex + 5
              }, {
                Utilities:Create("TextButton", {
                    Name = "CloseConsole",
                    BackgroundTransparency = 1,
                    Text = "",
                    Size = UDim2.new(1, -10, 0, 24),
                    ZIndex = 11001
                })
              })
          }),
          Utilities:Create("Frame", {
              Name = "Topbar",
              AnchorPoint = Vector2.new(.5, 0),
              Position = UDim2.new(.5, 0, 0, 0),
              BackgroundColor3 = Colors.Secondary,
              Size = UDim2.new(1, 0, 0, 26)
          }, {
              Utilities:Create("Frame", {
                  Name = "Divider",
                  Size = UDim2.new(1, 0, 0, 1),
                  BackgroundColor3 = Colors.Divider,
                  AnchorPoint = Vector2.new(0.5, 1),
                  ZIndex = 2,
                  Position = UDim2.new(.5, 0, 1, 0)
              }),
              Utilities:Create("Frame", {
                  Name = "TabContainer",
                  Size = UDim2.new(1, 0, 0, 26),
                  BackgroundTransparency = 1,
                  ClipsDescendants = true
              }, {
                  Utilities:Create("UIListLayout", {
                      FillDirection = Enum.FillDirection.Horizontal
                  })
              })
          })
      })
  })

  trackInput(UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if Input.KeyCode == Enum.KeyCode.Q and not GameProcessed then
        Window.Main.Visible = not Window.Main.Visible
    end
  end))

  local Console = Utilities:Create("Frame", {
    Name = "Console",
    Size = UDim2.new(0, 500, 0, 300),
    Parent = Window.Main,
    AnchorPoint = Vector2.new(.5, .5),
    Visible = false,
    ZIndex = 11000,
    Position = UDim2.fromScale(.5, .5),
    BackgroundColor3 = Colors.Primary
  }, {
    Utilities:Create("UIStroke", {
        Color = Colors.Divider
    }),
    Utilities:Create("ScrollingFrame", {
        Name = "ConsoleContainer",
        Size = UDim2.new(0, 500, 0, 276),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 0, 0, 24),
        ScrollBarThickness = 0,
        BackgroundTransparency = 1,
        ZIndex = 11001
    }, {
        Utilities:Create("UIListLayout")
    }),
    Utilities:Create("Frame", {
        Name = "ConsoleTopbar", 
        AnchorPoint = Vector2.new(.5, 0),
        Position = UDim2.new(.5, 0, 0, 0),
        BackgroundColor3 = Colors.Secondary,
        ZIndex = 11001,
        Size = UDim2.new(1, 0, 0, 24)
    }, {
        Utilities:Create("TextLabel", {
            Name = "ConsoleText",
            Text = "Console",
            Size = UDim2.new(1, -10, 0, 24),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 13,
            Font = Enum.Font.SourceSansBold,
            TextColor3 = Colors.PrimaryText,
            ZIndex = 11001
        })
    })
  })

  local consoleContainer = Console:FindFirstChild("ConsoleContainer")
  if not consoleContainer then
    consoleContainer = Instance.new("ScrollingFrame")
    consoleContainer.Name = "ConsoleContainer"
    consoleContainer.Size = UDim2.new(1, 0, 1, -24)
    consoleContainer.Position = UDim2.new(0, 0, 0, 24)
    consoleContainer.BackgroundTransparency = 1
    consoleContainer.ScrollBarThickness = 0
    consoleContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    consoleContainer.CanvasSize = UDim2.new()
    consoleContainer.ZIndex = 11001
    consoleContainer.Parent = Console
    Instance.new("UIListLayout").Parent = consoleContainer
  end

  local scrollSize
  local listLayout = consoleContainer:FindFirstChildOfClass("UIListLayout")
  if listLayout then
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
      scrollSize = listLayout.AbsoluteContentSize.Y
      consoleContainer.CanvasPosition = Vector2.new(0, scrollSize)
    end)
  end

  local bottomText = Window.Main.Bottom.BottomText

  bottomText.MouseEnter:Connect(function()
    Utilities:Tween(bottomText, .125, {TextColor3 = Colors.Accent})
  end)

  bottomText.MouseLeave:Connect(function()
    Utilities:Tween(bottomText, .125, {TextColor3 = Colors.PrimaryText})
  end)

  bottomText.CloseConsole.MouseButton1Click:Connect(function()
    WindowTable:ToggleConsole()
  end)

  function WindowTable:ToggleConsole()
    Console.Visible = not Console.Visible
  end

  local coloredMessage = true
  function WindowTable:Message(consoleArgs)
    consoleArgs.Text = consoleArgs.Text or "Message"
    consoleArgs.Color = consoleArgs.Color or Colors.PrimaryText

    local holder = consoleContainer
    if not holder or not holder.Parent then
      holder = Console:FindFirstChild("ConsoleContainer")
    end
    if not holder then
      return
    end

    coloredMessage = not coloredMessage

    local currentDate = os.date("%X")

    local finalMessage = string.format("[%s] %s", currentDate, consoleArgs.Text)

    local Message = Utilities:Create("Frame", {
        Name = "ConsoleMessage",
        BackgroundColor3 = Colors.Divider,
        BackgroundTransparency = coloredMessage and 0 or 1,
        Size = UDim2.new(1, 0, 0, 23),
        ZIndex = 11002,
        Parent = holder
    }, {
        Utilities:Create("TextLabel", {
            Name = "MessageText",
            Text = finalMessage,
            Size = UDim2.new(1, 0, 0, 23),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 3, 0, 0),
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 13,
            Font = Enum.Font.SourceSansBold,
            TextColor3 = consoleArgs.Color,
            ZIndex = 11002
        })
    })
  end

  if syn and syn.protect_gui then
    syn.protect_gui(Window)
    Window.Parent = CoreGui
  elseif gethui then
    Window.Parent = gethui()
  else
    Window.Parent = CoreGui
  end

  local ResizeButton = Window.Main.Bottom.ResizeIcon.ResizeButton
  local TabContainer = Window.Main.Topbar.TabContainer
  local Containers = Window.Main.Containers

  local SizeX = Instance.new("NumberValue", Window.Main)
  SizeX.Name = "X"
  SizeX.Value = 900

  local SizeY = Instance.new("NumberValue", Window.Main)
  SizeY.Name = "Y"
  SizeY.Value = 560

  local function ResizeTabs()
    local TabSize = 1 / self.Tabs
    
    task.spawn(function()
      for _, v in pairs(TabContainer:GetChildren()) do
          if v.ClassName == "Frame" then
              v.Size = UDim2.new(TabSize, 0, 0, 26)
          end
      end
    end)
  end

  local function Resize()
    local MouseLocation = Utilities:GetMouse()
    local X = math.clamp(MouseLocation.X - Window.Main.AbsolutePosition.X, 500, 1100)
    local Y = math.clamp(MouseLocation.Y - Window.Main.AbsolutePosition.Y, 320, 700)
    
    SizeX.Value = X
    SizeY.Value = Y

    Utilities:Tween(Window.Main, .05, {Size = UDim2.new(0, X, 0, Y)})

    ResizeTabs()
  end

  ResizeButton.MouseButton1Down:Connect(function()
  local ResizeMove, ResizeKill
  
  Utilities:Tween(Window.Main.Bottom.ResizeIcon, .125, {ImageColor3 = Colors.Accent})

  ResizeMove = Mouse.Move:Connect(function()
    Resize()
  end)

  ResizeKill = UserInputService.InputEnded:Connect(function(UserInput)
    if UserInput.UserInputType == Enum.UserInputType.MouseButton1 then
        ResizeMove:Disconnect()
        ResizeKill:Disconnect()

        Utilities:Tween(Window.Main.Bottom.ResizeIcon, .125, {ImageColor3 = Color3.fromRGB(255, 255, 255)})
    end
  end)
  
    --TweenService:Create(Window.Mai, TweenInfo.new(0.09, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(Scale,0,0,14)}):Play()
  end)

  TabContainer.ChildAdded:Connect(function()
      self.Tabs = self.Tabs + 1
  
      ResizeTabs()
  end)

  local dragging = false
  local dragInput, mousePos, framePos

  Window.Main.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then
          dragging = true
          mousePos = input.Position
          framePos = Window.Main.Position
              
          input.Changed:Connect(function()
              if input.UserInputState == Enum.UserInputState.End then
                  dragging = false
              end
          end)
      end
  end)

  Window.Main.InputChanged:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement then
          dragInput = input
      end
  end)

  trackInput(UserInputService.InputChanged:Connect(function(input)
      if input == dragInput and dragging then
          local delta = input.Position - mousePos
          Window.Main.Position  = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
      end
  end))
  
  function WindowTable:Exit()
      for _, connection in ipairs(WindowTable._connections) do
          pcall(function()
              connection:Disconnect()
          end)
      end
      table.clear(WindowTable._connections)
      Window:Destroy()
  end
  
  function WindowTable:Toggle()
      Window.Enabled = not Window.Enabled
  end

  function WindowTable:Notify(data)
    data = data or {}
    local title = data.title or data.Title or "Notice"
    local content = data.content or data.Content or data.subtitle or data.Subtitle or ""
    self:Message({ Text = title .. (content ~= "" and (": " .. content) or "") })
  end

  function WindowTable:Save(name)
    name = name or "MM2Enhanced"
    if type(writefile) ~= "function" then
      return false
    end
    if type(makefolder) == "function" and not (isfolder and isfolder("MM2Enhanced")) then
      pcall(makefolder, "MM2Enhanced")
    end
    local HttpService = game:GetService("HttpService")
    local ok, encoded = pcall(function()
      return HttpService:JSONEncode(library.Flags)
    end)
    if not ok then
      return false
    end
    local path = "MM2Enhanced/" .. name .. ".json"
    local wrote = pcall(writefile, path, encoded)
    return wrote
  end

  function WindowTable:Load(name)
    name = name or "MM2Enhanced"
    if type(readfile) ~= "function" or type(isfile) ~= "function" then
      return false
    end
    local path = "MM2Enhanced/" .. name .. ".json"
    if not isfile(path) then
      return false
    end
    local HttpService = game:GetService("HttpService")
    local ok, decoded = pcall(function()
      return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(decoded) ~= "table" then
      return false
    end
    for flag, value in pairs(decoded) do
      library.Flags[flag] = value
    end
    return true
  end
  
  function WindowTable:Tab(TabArgs)
  TabArgs.Text = TabArgs.Text or "Tab"
  
  local TabTable = {}
  
  local Tab = Utilities:Create("Frame", {
      Name = "Tab",
      Parent = TabContainer,
      Size = UDim2.new(0, 200, 0, 26),
      BackgroundTransparency = 1,
  }, {
      Utilities:Create("Frame", {
          Name = "Divider",
          AnchorPoint = Vector2.new(.5, 1),
          Position = UDim2.new(.5, 0, 1, 0),
          Size = UDim2.new(1, 0, 0, 1),
          ZIndex = 3,
          BackgroundColor3 = Colors.Divider
      }),
      Utilities:Create("TextLabel", {
          Name = "TabText",
          BackgroundTransparency = 1,
          Size = UDim2.new(1, 0, 1, 0),
          Text = TabArgs.Text,
          RichText = true,
          Font = Enum.Font.SourceSansBold,
          TextColor3 = Colors.SecondaryText,
          TextSize = 14,
          ZIndex = 2
      }),
      Utilities:Create("TextButton", {
          Name = "TabButton",
          Size = UDim2.new(1, 0, 1, 0),
          BackgroundTransparency = 1
      })
  })

  ResizeTabs()

  local ContainerHolder = Utilities:Create("Frame", {
    Name = "ContainerHolder",
    Size = UDim2.new(1, 0, 1, 0),
    Parent = Containers,
    BackgroundTransparency = 1
  }, {
    Utilities:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal
    })
  })
  
  local Left = Utilities:Create("ScrollingFrame", {
      Name = "Left",
      BackgroundTransparency = 1,
      Visible = false,
      BackgroundColor3 = Color3.fromRGB(167, 54, 54),
      CanvasSize = UDim2.new(0, 0, 0, 0),
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      ClipsDescendants = false,
      ScrollBarThickness = 0,
      Parent = ContainerHolder,
      Size = UDim2.new(.5, 0, 1, -8)
      }, {
          Utilities:Create("UIListLayout"),
          Utilities:Create("UIPadding", {
              PaddingLeft = UDim.new(0, 8)
          })
  })
  
  local Right = Utilities:Create("ScrollingFrame", {
      Name = "Right",
      BackgroundTransparency = 1,
      Visible = false,
      BackgroundColor3 = Color3.fromRGB(45, 175, 62),
      CanvasSize = UDim2.new(0, 0, 0, 0),
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      ClipsDescendants = false,
      ScrollBarThickness = 0,
      Parent = ContainerHolder,
      Size = UDim2.new(.5, 0, 1, -8),
      Position = UDim2.new(0, 450, 0, 0)
      }, {
          Utilities:Create("UIListLayout"),
          Utilities:Create("UIPadding", {
              PaddingLeft = UDim.new(0, 6)
          })
  })
  
  Tab.MouseEnter:Connect(function()
      if SelectedTab == nil or SelectedTab ~= Tab then
          Utilities:Tween(Tab.Divider, .125, {BackgroundColor3 = Colors.Tertiary})
          Utilities:Tween(Tab.TabText, .125, {TextColor3 = Colors.PrimaryText})
      end
  end)
  
  Tab.MouseLeave:Connect(function()
      if SelectedTab == nil or Tab ~= SelectedTab then
          Utilities:Tween(Tab.Divider, .125, {BackgroundColor3 = Colors.Divider})
          Utilities:Tween(Tab.TabText, .125, {TextColor3 = Colors.SecondaryText})
      end
  end)
  
  function TabTable:Select()
  SelectedTab = Tab
  
  task.spawn(function()
      for _, v in pairs(Containers:GetChildren()) do
        if v.Name == "ContainerHolder" then
            if v.Left ~= Left then
                v.Left.Visible = false
                v.Right.Visible = false
            end
        end
      end
      
      for _, v in pairs(TabContainer:GetChildren()) do
          if v.ClassName == "Frame" and v ~= Tab then
              Utilities:Tween(v.Divider, .125, {BackgroundColor3 = Colors.Divider})
              Utilities:Tween(v.TabText, .125, {TextColor3 = Colors.SecondaryText})
          end
      end
  end)
  
  Left.Visible = true
  Right.Visible = true
  Utilities:Tween(Tab.Divider, .125, {BackgroundColor3 = Colors.DarkerAccent})
  Utilities:Tween(Tab.TabText, .125, {TextColor3 = Colors.AccentText})
  end
  
  Tab.TabButton.MouseButton1Click:Connect(function()
      TabTable:Select()
  end)

  if SelectedTab == nil then
      TabTable:Select()
  end
  
  function TabTable:Section(SectionArgs)
  SectionArgs.Text = SectionArgs.Text or "Section"
  SectionArgs.Side = SectionArgs.Side or "Left"

  local SectionTable = {}
  
  local Section = Utilities:Create("Frame", {
      Name = "Section",
      Parent = SectionArgs.Side == "Left" and Left or Right,
      BackgroundColor3 = Color3.fromRGB(167, 54, 54),
      BackgroundTransparency = 1,
      Size = UDim2.new(0, 436, 0, 36) -- +64
  }, {
      Utilities:Create("TextLabel", {
          Name = "SectionText",
          Size = UDim2.new(0, 436, 0, 26),
          Text = SectionArgs.Text,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextSize = 14,
          BackgroundTransparency = 1,
          TextColor3 = Colors.PrimaryText,
          RichText = true,
          Font = Enum.Font.SourceSansBold,
          ZIndex = 2
      }),
      Utilities:Create("Frame", {
          Name = "Divider",
          Position = UDim2.new(0, 0, 0, 28),
          Size = UDim2.new(0, 436, 0, 1),
          BackgroundColor3 = Colors.Divider
      }),
      Utilities:Create("Frame", {
        Name = "Container",
        Size = UDim2.new(0, 436, 0, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 38)
      }, {
        Utilities:Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder
        })
      })
  })

  local SectionY = 36

  SizeX:GetPropertyChangedSignal("Value"):Connect(function()
    local Size = SizeX.Value / 2 - 14
    Section.Size = UDim2.new(0, Size, 0, SectionY)
    Section.Divider.Size = UDim2.new(0, Size, 0, 1)
  end)

  local SectionContainer = Section.Container

  SectionContainer.ChildAdded:Connect(function()
    SectionY = SectionY + 21

    Section.Size = UDim2.new(0, 436, 0, SectionY)
    SectionContainer.Size = UDim2.new(0, 436, 0, SectionY)
  end)

  function SectionTable:Check(CheckArgs)
  CheckArgs.Text = CheckArgs.Text or "Check"
  CheckArgs.Flag = CheckArgs.Flag or nil
  CheckArgs.Default = CheckArgs.Default or false
  CheckArgs.Callback = CheckArgs.Callback or function() end

  local State = false
  
  local CheckTable = {}

  local Check = Utilities:Create("Frame", {
    Name = "Check",
    Parent = SectionContainer,
    Size = UDim2.new(0, 436, 0, 21),
    BackgroundTransparency = 1,
  }, {
    Utilities:Create("TextButton", {
        Name = "CheckButton",
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1
    }),
    Utilities:Create("Frame", {
        Name = "CheckFrame",
        Size = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1
    }, {
        Utilities:Create("TextLabel", {
            Name = "CheckText",
            Text = CheckArgs.Text,
            TextSize = 13,
            RichText = true,
            Font = Enum.Font.SourceSansBold,
            Size = UDim2.new(0, 14, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(0, 20, 0, 0),
            TextColor3 = Colors.PrimaryText,
            BackgroundTransparency = 1
        }),
        Utilities:Create("Frame", {
            Name = "CheckInner",
            AnchorPoint = Vector2.new(.5, .5),
            Position = UDim2.new(.5, 0, .5, 0),
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = Colors.Secondary
        }),
        Utilities:Create("UIStroke", {
            Color = Colors.Divider
        })
    })
  })

  local CheckButton = Check.CheckButton

  local TextBounds = Check.CheckFrame.CheckText.TextBounds
  local ButtonSize = TextBounds.X ~= "" and TextBounds.X + 20 or 14

  CheckButton.MouseEnter:Connect(function()
    if not State then
        Utilities:Tween(Check.CheckFrame.UIStroke, .125, {Color = Colors.Tertiary})
        Utilities:Tween(Check.CheckFrame.CheckInner, .125, {BackgroundColor3 = Colors.Hovering})
    end
  end)

  CheckButton.MouseLeave:Connect(function()
    if not State then
        Utilities:Tween(Check.CheckFrame.UIStroke, .125, {Color = Colors.Divider})
        Utilities:Tween(Check.CheckFrame.CheckInner, .125, {BackgroundColor3 = Colors.Secondary})
    end
  end)

  CheckButton.Size = UDim2.new(0, ButtonSize, 0, 14)

  function CheckTable:Set(bool)
    task.spawn(CheckArgs.Callback, bool)
    State = bool
    if CheckArgs.Flag ~= nil then
        library.Flags[CheckArgs.Flag] = bool
    end
    
    if State then
        Utilities:Tween(Check.CheckFrame.UIStroke, .125, {Color = Colors.Accent})
        Utilities:Tween(Check.CheckFrame.CheckInner, .125, {BackgroundColor3 = Colors.Accent})
    else
        Utilities:Tween(Check.CheckFrame.UIStroke, .125, {Color = Colors.Divider})
        Utilities:Tween(Check.CheckFrame.CheckInner, .125, {BackgroundColor3 = Colors.Secondary})
    end
  end

  CheckButton.MouseButton1Click:Connect(function()
    State = not State

    CheckTable:Set(State)
  end)

  if CheckArgs.Default then
    CheckTable:Set(true)
  elseif CheckArgs.Flag then
    library.Flags[CheckArgs.Flag] = false
  end

  return CheckTable
  end

  function SectionTable:Button(Info)
  Info.Text = Info.Text or "Button"
  Info.Callback = Info.Callback or function() end

  local Button = Utilities:Create("Frame", {
    Name = "Button",
    Parent = SectionContainer,
    Size = UDim2.new(0, 436, 0, 21),
    BackgroundTransparency = 1
  }, {
    Utilities:Create("Frame", {
        Name = "ButtonFrame",
        BackgroundColor3 = Colors.Secondary,
        Size = UDim2.new(0, 14, 0, 14)
    }, {
        Utilities:Create("UIStroke", {
            Color = Colors.Divider
        }),
        Utilities:Create("TextLabel", {
            Name = "ButtonText",
            Size = UDim2.new(1, 0, 1, 0),
            Text = Info.Text,
            RichText = true,
            Font = Enum.Font.SourceSansBold,
            BackgroundTransparency = 1,
            TextSize = 13,
            TextColor3 = Colors.PrimaryText
        }),
        Utilities:Create("TextButton", {
            Name = "ButtonButton",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1
        })
    })
  })

  local Hovering = false

  Button.ButtonFrame.MouseEnter:Connect(function()
    Hovering = true
    Utilities:Tween(Button.ButtonFrame, .125, {BackgroundColor3 = Colors.Hovering})
    Utilities:Tween(Button.ButtonFrame.UIStroke, .125, {Color = Colors.AccentDivider})
  end)

  Button.ButtonFrame.MouseLeave:Connect(function()
    Hovering = false
    Utilities:Tween(Button.ButtonFrame, .125, {BackgroundColor3 = Colors.Secondary})
    Utilities:Tween(Button.ButtonFrame.UIStroke, .125, {Color = Colors.Divider})
  end)

  local TextX = math.clamp(Button.ButtonFrame.ButtonText.TextBounds.X, 15, 1000)

  Button.ButtonFrame.Size = UDim2.new(0, TextX + 10, 0, 14)

  Button.ButtonFrame.ButtonButton.MouseButton1Down:Connect(function()
    Utilities:Tween(Button.ButtonFrame.UIStroke, .1, {Color = Colors.Accent})
    Utilities:Tween(Button.ButtonFrame.ButtonText, .1, {TextColor3 = Colors.AccentText})
  end)

  Button.ButtonFrame.ButtonButton.MouseButton1Up:Connect(function()
    Utilities:Tween(Button.ButtonFrame.ButtonText, .1, {TextColor3 = Colors.PrimaryText})
    if Hovering then
        Utilities:Tween(Button.ButtonFrame.UIStroke, .125, {Color = Colors.AccentDivider})
        else
        Utilities:Tween(Button.ButtonFrame.UIStroke, .125, {Color = Colors.Divider})
    end
  end)

  Button.ButtonFrame.ButtonButton.MouseButton1Click:Connect(function()
    task.spawn(Info.Callback)
  end)
  
  end

  function SectionTable:Slider(Info)
  Info.Text = Info.Text or "Slider"
  Info.Flag = Info.Flag or nil
  Info.Default = Info.Default or 10
  Info.Minimum = Info.Minimum or 5
  Info.Maximum = Info.Maximum or 20
  Info.Incrementation = Info.Incrementation or 1
  Info.Postfix = Info.Postfix or ""
  Info.Callback = Info.Callback or function() end

  if Info.Minimum > Info.Maximum then
    local ValueBefore = Info.Minimum
    Info.Minimum, Info.Maximum = Info.Maximum, ValueBefore
    end

    local DefaultValue = math.clamp(Info.Default, Info.Minimum, Info.Maximum)
    local Rounded = Utilities:Round(DefaultValue, Info.Incrementation)

    local DefaultScale = (Rounded - Info.Minimum) / (Info.Maximum - Info.Minimum)

    local StepFormat = "%d"
    local Step = Info.Incrementation

    for i = 1, 10 do
        if Step == 1 then break end
        
        StepFormat = '%.' .. i .. 'f'
        if StepFormat:format(Step) == tostring(Step) then
            break
        end
    end

  local Slider = Utilities:Create("Frame", {
    Name = "Slider",
    Parent = SectionContainer,
    Size = UDim2.new(0, 436, 0, 21),
    BackgroundTransparency = 1
  }, {
    Utilities:Create("Frame", {
        Name = "SliderOuter",
        BackgroundColor3 = Colors.Secondary,
        Size = UDim2.new(.6, 3, 0, 14)
    }, {
        Utilities:Create("UIStroke", {
            Color = Colors.AccentDivider
        }),
        Utilities:Create("Frame", {
            Name = "SliderInner",
            BackgroundColor3 = Colors.DarkerAccent,
            Size = UDim2.fromScale(DefaultScale, 1)
        }),
        Utilities:Create("TextLabel", {
            Name = "SliderValueText",
            Text = StepFormat:format(Rounded)..Info.Postfix,
            TextSize = 13,
            Font = Enum.Font.SourceSansBold,
            RichText = true,
            Size = UDim2.new(1, 0, 0, 14),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1
        }),
        Utilities:Create("TextButton", {
            Name = "SliderButton",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
        }),
        Utilities:Create("TextLabel", {
            Name = "SliderText",
            Text = Info.Text,
            TextSize = 13,
            Font = Enum.Font.SourceSansBold,
            RichText = true,
            Size = UDim2.new(1, 0, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = UDim2.new(1, 6, 0, 0),
            TextColor3 = Colors.PrimaryText,
            BackgroundTransparency = 1
        })
    })
  })

  SizeX:GetPropertyChangedSignal("Value"):Connect(function()
    local Size = SizeX.Value / 2 - 14
    Slider.Size = UDim2.new(0, Size, 0, 21)
  end)

  Slider.SliderOuter.MouseEnter:Connect(function()
    Utilities:Tween(Slider.SliderOuter.UIStroke, .125, {Color = Colors.Tertiary})
    Utilities:Tween(Slider.SliderOuter, .125, {BackgroundColor3 = Colors.Hovering})
  end)

  Slider.SliderOuter.MouseLeave:Connect(function()
    Utilities:Tween(Slider.SliderOuter.UIStroke, .125, {Color = Colors.AccentDivider})
    Utilities:Tween(Slider.SliderOuter, .125, {BackgroundColor3 = Colors.Secondary})
    Utilities:Tween(Slider.SliderOuter.SliderInner, .125, {BackgroundColor3 = Colors.DarkerAccent})
  end)

  Slider.SliderOuter.SliderButton.MouseButton1Down:Connect(function()
    Utilities:Tween(Slider.SliderOuter.SliderInner, .125, {BackgroundColor3 = Colors.Accent})
  end)

  Slider.SliderOuter.SliderButton.MouseButton1Up:Connect(function()
    Utilities:Tween(Slider.SliderOuter.SliderInner, .125, {BackgroundColor3 = Colors.DarkerAccent})
  end)

  local MinSize = 0
    local MaxSize = 1

    local SizeFromScale = (MinSize +  (MaxSize - MinSize)) * DefaultScale
    SizeFromScale = SizeFromScale - (SizeFromScale % 2)

    Slider.SliderOuter.SliderButton.MouseButton1Down:Connect(function()
        local MouseMove, MouseKill
        MouseMove = Mouse.Move:Connect(function()
            local Px = Utilities:GetXY(Slider.SliderOuter)
            local ScaledValue = Px * (Info.Maximum - Info.Minimum) + Info.Minimum
            local RoundedValue = Utilities:Round(ScaledValue, Info.Incrementation)
            local FinalValue = math.clamp(RoundedValue, Info.Minimum, Info.Maximum)
            local SizeX = (FinalValue - Info.Minimum) / (Info.Maximum - Info.Minimum)
            Utilities:Tween(Slider.SliderOuter.SliderInner, 0.09, {Size = UDim2.new(SizeX,0,1,0)})
            if Info.Flag then
                library.Flags[Info.Flag] = FinalValue
            end
            Slider.SliderOuter.SliderValueText.Text = StepFormat:format(FinalValue)..Info.Postfix
            task.spawn(Info.Callback, FinalValue)
        end)
        MouseKill = UserInputService.InputEnded:Connect(function(UserInput)
            if UserInput.UserInputType == Enum.UserInputType.MouseButton1 then
                MouseMove:Disconnect()
                MouseKill:Disconnect()
            end
        end)
    end)
  end

  function SectionTable:Label(Info)
    Info.Text = Info.Text or "Label"
    Info.Color = Info.Color or Colors.PrimaryText

    local LabelTable = {}

    local Label = Utilities:Create("Frame", {
        Name = "Label",
        Parent = SectionContainer,
        Size = UDim2.new(0, 436, 0, 21),
        BackgroundTransparency = 1
    }, {
        Utilities:Create("TextLabel", {
            Name = "LabelText",
            Text = Info.Text,
            TextColor3 = Info.Color,
            RichText = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 436, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextSize = 13,
            Font = Enum.Font.SourceSansBold
        })
    })

    function LabelTable:Set(str, color)
        str = str or Label.LabelText.Text
        color = color or Info.Color

        Label.LabelText.Text = str
        Label.LabelText.TextColor3 = color
    end

    return LabelTable
  end

  function SectionTable:Dropdown(Info)
    Info.Text = Info.Text or "Dropdown"
    Info.Flag = Info.Flag or nil
    Info.Multi = Info.Multi or false
    Info.Default = Info.Default or nil
    Info.List = Info.List or {}
    Info.ChangeText = Info.ChangeText or true

    local State = false

    local DropdownTable = {}
    DropdownTable.Index = DropIndex
    local DropdownY = 0

    local Dropdown = Utilities:Create("Frame", {
        Name = "Dropdown",
        BackgroundTransparency = 1,
        Parent = SectionContainer,
        Size = UDim2.new(0, 436, 0, 21)
    }, {
        Utilities:Create("Frame", {
            Name = "DropdownFrame",
            Size = UDim2.new(.6, 3, 0, 14),
            BackgroundColor3 = Colors.Secondary,
            ClipsDescendants = true,
            ZIndex = DropdownTable.Index
        }, {
            Utilities:Create("UIStroke", {
                Color = Colors.AccentDivider
            }),
            Utilities:Create("TextLabel", {
                Name = "DropdownText",
                BackgroundTransparency = 1,
                Text = Info.Text,
                Size = UDim2.new(1, 0, 0, 14),
                TextXAlignment = Enum.TextXAlignment.Left,
                RichText = true,
                Position = UDim2.new(0, 4, 0, 0),
                TextSize = 13,
                TextColor3 = Colors.TertiaryText,
                Font = Enum.Font.SourceSansBold,
                ZIndex = DropdownTable.Index
            }),
            Utilities:Create("TextButton", {
                Name = "DropdownButton",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                ZIndex = DropdownTable.Index
            }),
            Utilities:Create("Frame", {
                Name = "DropdownContainer",
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Position = UDim2.new(0, 0, 0, 14),
                ZIndex = DropdownTable.Index
            }, {
                Utilities:Create("UIListLayout")
            }),
            Utilities:Create("Frame", {
                Name = "GradientHolder",
                Size = UDim2.new(0, 20, 0, 14),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(1, -41, 0, 0),
                ZIndex = DropdownTable.Index
            }, {
                Utilities:Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Colors.Secondary),
                        ColorSequenceKeypoint.new(1, Colors.Secondary),
                    }),
                    Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    })
                })
            }),
            Utilities:Create("Frame", {
                Name = "DropdownImageContainer",
                Size = UDim2.new(0, 21, 0, 14),
                BackgroundColor3 = Colors.Tertiary,
                Position = UDim2.new(1, -21, 0, 0),
                ZIndex = DropdownTable.Index
            }, {
                Utilities:Create("UIStroke", {
                    Color = Colors.AccentDivider
                }),
                Utilities:Create("ImageLabel", {
                    Name = "DropdownImage",
                    Size = UDim2.new(0, 10, 0, 10),
                    BackgroundTransparency = 1,
                    Rotation = 0, -- 180
                    Image = getcustomasset("PPHUD/Arrow.png"),
                    AnchorPoint = Vector2.new(.5, .5),
                    Position = UDim2.new(.5, 0, .5, 0),
                    ZIndex = DropdownTable.Index
                })
            })
        })
    })

    SizeX:GetPropertyChangedSignal("Value"):Connect(function()
        local Size = SizeX.Value / 2 - 14
        Dropdown.Size = UDim2.new(0, Size, 0, 21)
      end)

    Dropdown.DropdownFrame.MouseEnter:Connect(function()
        if not State then
            Utilities:Tween(Dropdown.DropdownFrame, .125, {BackgroundColor3 = Colors.Hovering})
        end
    end)

    Dropdown.DropdownFrame.MouseLeave:Connect(function()
        if not State then
            Utilities:Tween(Dropdown.DropdownFrame, .125, {BackgroundColor3 = Colors.Secondary})
        end
    end)

    local DropdownContainer = Dropdown.DropdownFrame.DropdownContainer
    local DropdownImage = Dropdown.DropdownFrame.DropdownImageContainer.DropdownImage

    function DropdownTable:Toggle(bool)
        State = bool

        if State then
            Utilities:Tween(Dropdown.DropdownFrame, .2, {BackgroundColor3 = Colors.Secondary})
            DropdownContainer.Size = DropdownContainer.Size + UDim2.fromOffset(0, DropdownY)
            Dropdown.DropdownFrame.Size = Dropdown.DropdownFrame.Size + UDim2.fromOffset(0, DropdownY)
            DropdownImage.Rotation = 90
        else
            DropdownContainer.Size = DropdownContainer.Size - UDim2.fromOffset(0, DropdownY)
            Dropdown.DropdownFrame.Size = Dropdown.DropdownFrame.Size - UDim2.fromOffset(0, DropdownY)
            DropdownImage.Rotation = 0
        end
    end

    if Info.Default then
        task.spawn(Info.Callback, Info.Default)
        if Info.Flag then
            library[Info.Flag] = Info.Default
        end
        if Info.ChangeText then
            Dropdown.DropdownFrame.DropdownText.Text = Info.Default
        end
    end

    function DropdownTable:Select(v)
        task.spawn(Info.Callback, v)

        if Info.ChangeText then
            Dropdown.DropdownFrame.DropdownText.Text = v
        end
    end

    local MultiTable = {}

    local function OnPick(v)
        if Info.Multi then
            if not table.find(MultiTable, v.DropdownElementText.Text) then
                Utilities:Tween(v, .125, {BackgroundTransparency = .95})
                Utilities:Tween(v.DropdownElementText, .125, {TextColor3 = Colors.Accent})
                table.insert(MultiTable, v.DropdownElementText.Text)
            else
                Utilities:Tween(v, .125, {BackgroundTransparency = 1})
                Utilities:Tween(v.DropdownElementText, .125, {TextColor3 = Colors.PrimaryText})
                for i, e in pairs(MultiTable) do
                    if v.DropdownElementText.Text == e then
                        table.remove(MultiTable, i)
                    end
                end
            end
            task.spawn(Info.Callback, MultiTable)

            if Info.ChangeText then
                Dropdown.DropdownFrame.DropdownText.Text = ""
                for i, z in pairs(MultiTable) do
                    Dropdown.DropdownFrame.DropdownText.Text ..= i ~= #MultiTable and z..", " or z
                end
                if string.len(Dropdown.DropdownFrame.DropdownText.Text) == 0 then
                    Dropdown.DropdownFrame.DropdownText.Text = Info.Text
                end
            end
        else
            DropdownTable:Select(v.DropdownElementText.Text)
            DropdownTable:Toggle(false)
        end
    end

    function DropdownTable:Refresh(table)
        for _, v in pairs(DropdownContainer:GetChildren()) do
            if v.ClassName == "Frame" then
                v:Destroy()
                DropdownY = DropdownY - 14

                if State then
                    DropdownContainer.Size = DropdownContainer.Size - UDim2.fromOffset(0, 14)
                    Dropdown.DropdownFrame.Size = Dropdown.DropdownFrame.Size - UDim2.fromOffset(0, 14)
                end
            end
        end

        for _, v in pairs(table) do
            warn("Set", v)
            DropdownTable:Add(v)
        end
    end

    function DropdownTable:Add(str)
        DropdownY = DropdownY + 14

        if State then
            DropdownContainer.Size = DropdownContainer.Size + UDim2.fromOffset(0, 14)
            Dropdown.DropdownFrame.Size = Dropdown.DropdownFrame.Size + UDim2.fromOffset(0, 14)
        end

        local DropdownElement = Utilities:Create("Frame", {
            Name = "DropdownElement",
            Size = UDim2.new(1, 0, 0, 14),
            Parent = DropdownContainer,
            BackgroundTransparency = 1,
            ZIndex = DropdownTable.Index
        }, {
            Utilities:Create("TextLabel", {
                Name = "DropdownElementText",
                Text = str,
                Size = UDim2.new(1, 0, 1, 0),
                TextSize = 13,
                BackgroundTransparency = 1,
                RichText = true,
                TextColor3 = Colors.PrimaryText,
                Font = Enum.Font.SourceSansBold,
                ZIndex = DropdownTable.Index
            }),
            Utilities:Create("TextButton", {
                Name = "DropdownElementButton",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                ZIndex = DropdownTable.Index
            })
        })

        DropdownElement.MouseEnter:Connect(function()
            if not table.find(MultiTable, DropdownElement.DropdownElementText.Text) then
                Utilities:Tween(DropdownElement, .125, {BackgroundTransparency = .95})
                Utilities:Tween(DropdownElement.DropdownElementText, .125, {TextColor3 = Colors.Accent})
            end
        end)

        DropdownElement.MouseLeave:Connect(function()
            if not table.find(MultiTable, DropdownElement.DropdownElementText.Text) then
                Utilities:Tween(DropdownElement, .125, {BackgroundTransparency = 1})
                Utilities:Tween(DropdownElement.DropdownElementText, .125, {TextColor3 = Colors.PrimaryText})
            end
        end)

        DropdownElement.DropdownElementButton.MouseButton1Click:Connect(function()
            OnPick(DropdownElement)
        end)
    end

    for _, v in pairs(Info.List) do
        DropdownTable:Add(v)
    end

    Dropdown.DropdownFrame.DropdownButton.MouseButton1Click:Connect(function()
        State = not State

        DropdownTable:Toggle(State)
    end)

    DropIndex = DropIndex - 1

    return DropdownTable
  end

  function SectionTable:Input(Info)
    Info.Text = Info.Text or "Input"
    Info.Flag = Info.Flag or nil
    Info.Default = Info.Default or Info.Value or ""
    Info.Placeholder = Info.Placeholder or ""
    Info.Callback = Info.Callback or function() end

    local Box = Utilities:Create("Frame", {
        Name = "Input",
        Parent = SectionContainer,
        Size = UDim2.new(0, 436, 0, 21),
        BackgroundTransparency = 1
    }, {
        Utilities:Create("Frame", {
            Name = "InputFrame",
            Size = UDim2.new(.6, 3, 0, 14),
            BackgroundColor3 = Colors.Secondary
        }, {
            Utilities:Create("UIStroke", { Color = Colors.AccentDivider }),
            Utilities:Create("TextBox", {
                Name = "InputBox",
                Size = UDim2.new(1, -6, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(Info.Default),
                PlaceholderText = Info.Placeholder,
                TextSize = 13,
                Font = Enum.Font.SourceSansBold,
                TextColor3 = Colors.PrimaryText,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false
            }),
            Utilities:Create("TextLabel", {
                Name = "InputLabel",
                Text = Info.Text,
                Size = UDim2.new(1, 0, 0, 14),
                Position = UDim2.new(1, 6, 0, 0),
                BackgroundTransparency = 1,
                TextSize = 13,
                Font = Enum.Font.SourceSansBold,
                TextColor3 = Colors.PrimaryText,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        })
    })

    if Info.Flag then
        library.Flags[Info.Flag] = Info.Default
    end

    Box.InputFrame.InputBox.FocusLost:Connect(function()
        local text = Box.InputFrame.InputBox.Text
        if Info.Flag then
            library.Flags[Info.Flag] = text
        end
        task.spawn(Info.Callback, text)
    end)

    return Box
  end

  function SectionTable:Keybind(Info)
    Info.Text = Info.Text or "Keybind"
    Info.Flag = Info.Flag or nil
    Info.Default = Info.Default or Enum.KeyCode.Unknown
    Info.Callback = Info.Callback or function() end

    local function parseBind(value)
        if typeof(value) == "EnumItem" then
            return value
        end
        if type(value) == "string" then
            if Enum.UserInputType[value] then
                return Enum.UserInputType[value]
            end
            if Enum.KeyCode[value] then
                return Enum.KeyCode[value]
            end
        end
        return Enum.KeyCode.Unknown
    end

    local function bindLabel(bind)
        if typeof(bind) ~= "EnumItem" then
            return "None"
        end
        return bind.Name
    end

    local function inputMatchesBind(input, bind)
        if typeof(bind) ~= "EnumItem" then
            return false
        end
        if bind.EnumType == Enum.UserInputType then
            return input.UserInputType == bind
        end
        return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
    end

    local current = parseBind(Info.Default)
    local listening = false
    local listenAt = 0

    local Bind = Utilities:Create("Frame", {
        Name = "Keybind",
        Parent = SectionContainer,
        Size = UDim2.new(0, 436, 0, 21),
        BackgroundTransparency = 1
    }, {
        Utilities:Create("Frame", {
            Name = "BindFrame",
            Size = UDim2.new(0, 70, 0, 14),
            BackgroundColor3 = Colors.Secondary
        }, {
            Utilities:Create("UIStroke", { Color = Colors.AccentDivider }),
            Utilities:Create("TextLabel", {
                Name = "BindText",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = bindLabel(current),
                TextSize = 13,
                Font = Enum.Font.SourceSansBold,
                TextColor3 = Colors.PrimaryText
            }),
            Utilities:Create("TextButton", {
                Name = "BindButton",
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1
            })
        }),
        Utilities:Create("TextLabel", {
            Name = "BindLabel",
            Text = Info.Text,
            Size = UDim2.new(1, -80, 0, 14),
            Position = UDim2.new(0, 76, 0, 0),
            BackgroundTransparency = 1,
            TextSize = 13,
            Font = Enum.Font.SourceSansBold,
            TextColor3 = Colors.PrimaryText,
            TextXAlignment = Enum.TextXAlignment.Left
        })
    })

    if Info.Flag then
        library.Flags[Info.Flag] = bindLabel(current)
    end

    Bind.BindFrame.BindButton.MouseButton1Click:Connect(function()
        listening = true
        listenAt = os.clock()
        Bind.BindFrame.BindText.Text = "..."
    end)

    trackInput(UserInputService.InputBegan:Connect(function(input, processed)
        if listening then
            if input.KeyCode == Enum.KeyCode.Escape then
                listening = false
                Bind.BindFrame.BindText.Text = bindLabel(current)
                return
            end
            local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3
            local isKey = input.UserInputType == Enum.UserInputType.Keyboard
                and input.KeyCode ~= Enum.KeyCode.Unknown
            if isMouse then
                if input.UserInputType == Enum.UserInputType.MouseButton1 and (os.clock() - listenAt) < 0.15 then
                    return
                end
                current = input.UserInputType
            elseif isKey then
                current = input.KeyCode
            else
                return
            end
            Bind.BindFrame.BindText.Text = bindLabel(current)
            if Info.Flag then
                library.Flags[Info.Flag] = bindLabel(current)
            end
            listening = false
            pcall(Info.Callback, current)
            return
        end
        if processed then return end
        if inputMatchesBind(input, current) then
            task.spawn(Info.Callback, current)
        end
    end))

    return Bind
  end

  return SectionTable
  end
  
  return TabTable
  end
  
  return WindowTable
  end

  return library
