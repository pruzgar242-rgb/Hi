-- ================================================================
--  RuzHub Mmv And Mm2  v8.0 (WindUI Section+Tab fix)
--  Tabs: Main | ESP | Farm | Crosshair | Sky | Op | Extra
--  Config: Save / Load / Auto-load on start
-- ================================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")

local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================================================================
--  GLOBALS (tüm fonksiyonlar aynen devam ediyor)
-- ================================================================
local goldCD       = false
local normalCD     = false
local BULLET_SPEED = 250
local KNIFE_SPEED  = 65
local MAX_VELOCITY = 200
local BASE_GLITCH  = 200
local autoPingPred = false
local fovValue     = 70
local lowGraphics  = false
local highGraphics = false
local droppedGunEspEnabled = true
local stretchEnabled = false
local stretchConn    = nil
local stretchValue   = 50

local crosshairActive = false
local crosshairSpin   = false
local activeCursorId  = "11770890197"
local crosshairImg    = nil
local spinConn        = nil

local skyboxActive    = false

local espEnabled  = false
local espConn     = nil
local rolesData   = {}
local lastEspTick = 0
local espSettings = { Murderer=true, Sheriff=true, Hero=true, Innocent=true, Self=true }
local ESP_COLORS  = {
    Murderer = Color3.fromRGB(255,40,40),
    Sheriff  = Color3.fromRGB(40,130,255),
    Hero     = Color3.fromRGB(255,215,0),
    Innocent = Color3.fromRGB(0,220,0),
}

local speedEnabled   = false
local speedConn      = nil
local antiFling      = false
local antiFlingConn  = nil
local flickCD        = false
local wallhopCD      = false
local flingBusy      = false
local currentTarget  = nil

local CURSOR_TEXTURE = "rbxassetid://5159914132"
local KNIFE_TEXTURE  = "rbxassetid://9695655416"

-- ================================================================
--  CONFIG SYSTEM (aynen)
-- ================================================================
local CONFIG_FILE = "RuzHub_config.json"

local function SerializeColor(c)
    return { r = math.round(c.R*255), g = math.round(c.G*255), b = math.round(c.B*255) }
end
local function DeserializeColor(t)
    return Color3.fromRGB(t.r or 255, t.g or 255, t.b or 255)
end

local function SaveConfig()
    if not writefile then Notify("Config: writefile not supported."); return end
    local cfg = {
        version       = "8.0",
        BULLET_SPEED  = BULLET_SPEED,
        KNIFE_SPEED   = KNIFE_SPEED,
        MAX_VELOCITY  = MAX_VELOCITY,
        BASE_GLITCH   = BASE_GLITCH,
        autoPingPred  = autoPingPred,
        fovValue      = fovValue,
        lowGraphics   = lowGraphics,
        highGraphics  = highGraphics,
        stretchEnabled = stretchEnabled,
        stretchValue  = stretchValue,
        crosshairActive = crosshairActive,
        crosshairSpin = crosshairSpin,
        activeCursorId = activeCursorId,
        skyboxActive  = skyboxActive,
        espEnabled    = espEnabled,
        droppedGunEspEnabled = droppedGunEspEnabled,
        espSettings   = espSettings,
        ESP_COLORS    = {
            Murderer = SerializeColor(ESP_COLORS.Murderer),
            Sheriff  = SerializeColor(ESP_COLORS.Sheriff),
            Hero     = SerializeColor(ESP_COLORS.Hero),
            Innocent = SerializeColor(ESP_COLORS.Innocent),
        },
        speedEnabled  = speedEnabled,
        antiFling     = antiFling,
    }
    local ok, err = pcall(function()
        writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(cfg))
    end)
    if ok then Notify("Config saved!") else Notify("Save failed: " .. tostring(err)) end
end

local function LoadConfig()
    if not readfile then Notify("Config: readfile not supported."); return nil end
    if not isfile(CONFIG_FILE) then return nil end
    local ok, result = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(result) == "table" then return result end
    return nil
end

local function ApplyConfig(cfg)
    if not cfg then return end
    if cfg.BULLET_SPEED  then BULLET_SPEED  = cfg.BULLET_SPEED  end
    if cfg.KNIFE_SPEED   then KNIFE_SPEED   = cfg.KNIFE_SPEED   end
    if cfg.MAX_VELOCITY  then MAX_VELOCITY  = cfg.MAX_VELOCITY  end
    if cfg.BASE_GLITCH   then BASE_GLITCH   = cfg.BASE_GLITCH   end
    if cfg.autoPingPred  ~= nil then autoPingPred  = cfg.autoPingPred  end
    if cfg.fovValue      then fovValue      = cfg.fovValue; Camera.FieldOfView = fovValue end
    if cfg.stretchValue  then stretchValue  = cfg.stretchValue  end
    if cfg.activeCursorId then activeCursorId = cfg.activeCursorId end
    if cfg.crosshairSpin ~= nil then crosshairSpin = cfg.crosshairSpin end
    if cfg.droppedGunEspEnabled ~= nil then droppedGunEspEnabled = cfg.droppedGunEspEnabled end
    if cfg.espSettings then
        for k, v in pairs(cfg.espSettings) do espSettings[k] = v end
    end
    if cfg.ESP_COLORS then
        for k, v in pairs(cfg.ESP_COLORS) do
            if ESP_COLORS[k] then ESP_COLORS[k] = DeserializeColor(v) end
        end
    end
    Notify("Config loaded!")
end

-- ================================================================
--  WINDUI
-- ================================================================
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"
))()
WindUI:SetTheme("Crimson")

local function Notify(content)
    WindUI:Notify({ Title="RuzHub", Content=tostring(content), Duration=3, Icon="bell" })
end

-- ================================================================
--  DRAG HELPER (aynen)
-- ================================================================
local function MakeDraggable(frame)
    local pd, ps, pp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            pd=true; ps=i.Position; pp=frame.Position
        end
    end)
    frame.InputChanged:Connect(function(i)
        if not pd then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-ps
            frame.Position=UDim2.new(pp.X.Scale,pp.X.Offset+d.X,pp.Y.Scale,pp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then pd=false end
    end)
end

-- ================================================================
--  MOBILE SLIDER POPUP (aynen)
-- ================================================================
local function OpenSliderPopup(title, minVal, maxVal, defaultVal, step, onApply, onReset)
    local uid = "RuzSlider_"..title:gsub("%s+","_")
    local ex  = game.CoreGui:FindFirstChild(uid)
    if ex then ex:Destroy(); return end
    local sg = Instance.new("ScreenGui", game.CoreGui)
    sg.Name=uid; sg.ResetOnSpawn=false; sg.DisplayOrder=55
    local frame=Instance.new("Frame",sg)
    frame.Size=UDim2.new(0,300,0,175); frame.Position=UDim2.new(0.5,-150,0.35,0)
    frame.BackgroundColor3=Color3.fromRGB(10,10,10); frame.BackgroundTransparency=0.08
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
    local fs=Instance.new("UIStroke",frame); fs.Color=Color3.fromRGB(220,38,38); fs.Thickness=1.5
    local hdr=Instance.new("TextLabel",frame)
    hdr.Size=UDim2.new(1,-44,0,36); hdr.Position=UDim2.new(0,12,0,0); hdr.BackgroundTransparency=1
    hdr.Text="RuzHub — "..title; hdr.TextColor3=Color3.fromRGB(255,255,255)
    hdr.Font=Enum.Font.GothamBold; hdr.TextSize=14; hdr.TextXAlignment=Enum.TextXAlignment.Left
    local xBtn=Instance.new("TextButton",frame)
    xBtn.Size=UDim2.new(0,28,0,28); xBtn.Position=UDim2.new(1,-34,0,4)
    xBtn.BackgroundColor3=Color3.fromRGB(180,30,30); xBtn.Text="X"; xBtn.TextColor3=Color3.new(1,1,1)
    xBtn.Font=Enum.Font.GothamBold; xBtn.TextSize=13
    Instance.new("UICorner",xBtn).CornerRadius=UDim.new(0,6)
    xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    local currentVal=defaultVal
    local valLbl=Instance.new("TextLabel",frame)
    valLbl.Size=UDim2.new(1,0,0,22); valLbl.Position=UDim2.new(0,0,0,38); valLbl.BackgroundTransparency=1
    valLbl.Text=title..":  "..tostring(currentVal); valLbl.TextColor3=Color3.fromRGB(210,210,210)
    valLbl.Font=Enum.Font.Gotham; valLbl.TextSize=13
    local track=Instance.new("Frame",frame)
    track.Size=UDim2.new(1,-30,0,10); track.Position=UDim2.new(0,15,0,72)
    track.BackgroundColor3=Color3.fromRGB(45,45,45)
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local r0=(currentVal-minVal)/(maxVal-minVal)
    local fill=Instance.new("Frame",track); fill.Size=UDim2.new(r0,0,1,0)
    fill.BackgroundColor3=Color3.fromRGB(220,38,38)
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local handle=Instance.new("TextButton",track)
    handle.Size=UDim2.new(0,26,0,26); handle.Position=UDim2.new(r0,-13,0.5,-13)
    handle.BackgroundColor3=Color3.fromRGB(255,255,255); handle.Text=""
    Instance.new("UICorner",handle).CornerRadius=UDim.new(1,0)
    local function updateFromX(sx)
        local rel=math.clamp((sx-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        currentVal=math.round(minVal+rel*(maxVal-minVal))
        if step and step>0 then currentVal=math.round(currentVal/step)*step end
        local r2=(currentVal-minVal)/(maxVal-minVal)
        fill.Size=UDim2.new(r2,0,1,0); handle.Position=UDim2.new(r2,-13,0.5,-13)
        valLbl.Text=title..":  "..tostring(currentVal)
    end
    local dragging=false
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; updateFromX(i.Position.X) end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then updateFromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    local btnRow=Instance.new("Frame",frame)
    btnRow.Size=UDim2.new(1,-20,0,36); btnRow.Position=UDim2.new(0,10,0,126); btnRow.BackgroundTransparency=1
    local applyBtn=Instance.new("TextButton",btnRow)
    applyBtn.Size=UDim2.new(0.48,0,1,0); applyBtn.BackgroundColor3=Color3.fromRGB(20,160,20)
    applyBtn.Text="Apply"; applyBtn.TextColor3=Color3.new(1,1,1); applyBtn.Font=Enum.Font.GothamBold; applyBtn.TextSize=13
    Instance.new("UICorner",applyBtn).CornerRadius=UDim.new(0,6)
    applyBtn.MouseButton1Click:Connect(function() onApply(currentVal); Notify(title.." set to "..currentVal) end)
    local resetBtn=Instance.new("TextButton",btnRow)
    resetBtn.Size=UDim2.new(0.48,0,1,0); resetBtn.Position=UDim2.new(0.52,0,0,0)
    resetBtn.BackgroundColor3=Color3.fromRGB(160,20,20); resetBtn.Text="Reset"
    resetBtn.TextColor3=Color3.new(1,1,1); resetBtn.Font=Enum.Font.GothamBold; resetBtn.TextSize=13
    Instance.new("UICorner",resetBtn).CornerRadius=UDim.new(0,6)
    resetBtn.MouseButton1Click:Connect(function() onReset(); sg:Destroy() end)
    MakeDraggable(frame)
end

-- ================================================================
--  LOW GRAPHICS STAR (aynen)
-- ================================================================
local lgStarGui=Instance.new("ScreenGui",game.CoreGui)
lgStarGui.Name="RuzLGStar"; lgStarGui.ResetOnSpawn=false; lgStarGui.DisplayOrder=40
local lgStarLbl=Instance.new("TextLabel",lgStarGui)
lgStarLbl.Size=UDim2.new(0,28,0,28); lgStarLbl.Position=UDim2.new(1,-34,0,4)
lgStarLbl.BackgroundTransparency=1; lgStarLbl.Text="★"
lgStarLbl.TextColor3=Color3.fromRGB(255,215,0); lgStarLbl.Font=Enum.Font.GothamBold
lgStarLbl.TextSize=22; lgStarLbl.Visible=false

-- ================================================================
--  PREDICTION PART (aynen)
-- ================================================================
local predPart=Instance.new("Part")
predPart.Name="RuzPredPart"; predPart.Size=Vector3.new(0.5,0.5,0.5)
predPart.Anchored=true; predPart.CanCollide=false; predPart.Transparency=1; predPart.Parent=Workspace

-- ================================================================
--  GUN MARKER (aynen)
-- ================================================================
local gunMarker=nil
local function ClearGunMarker() if gunMarker then gunMarker:Destroy(); gunMarker=nil end end
local function PlaceGunMarker(pos)
    ClearGunMarker()
    local p=Instance.new("Part"); p.Name="RuzGunMarker"; p.Size=Vector3.new(1.5,0.15,1.5)
    p.Anchored=true; p.CanCollide=false; p.CastShadow=false; p.Material=Enum.Material.Neon
    p.Color=Color3.fromRGB(50,255,80); p.Transparency=0.25; p.CFrame=CFrame.new(pos); p.Parent=Workspace
    task.spawn(function()
        while p and p.Parent do
            for t=0,1,0.05 do if not(p and p.Parent) then break end
                p.Transparency=0.25+0.5*math.sin(t*math.pi); task.wait(0.03)
            end
        end
    end)
    gunMarker=p
end

-- ================================================================
--  GUN DROP ESP (aynen)
-- ================================================================
local activeHL=nil; local activeBB=nil
local gunHLColor=Color3.fromRGB(255,215,0)

local function ClearGunESP()
    if activeHL then activeHL:Destroy(); activeHL=nil end
    if activeBB then activeBB:Destroy(); activeBB=nil end
end

local function ApplyGunESP(gunDrop)
    if not droppedGunEspEnabled then return end
    ClearGunESP()
    local hl=Instance.new("Highlight"); hl.Adornee=gunDrop; hl.FillColor=gunHLColor
    hl.OutlineColor=Color3.fromRGB(255,255,255); hl.FillTransparency=0.35
    hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=gunDrop; activeHL=hl
    local handle=gunDrop:FindFirstChild("Handle") or (gunDrop:IsA("Model") and gunDrop.PrimaryPart) or gunDrop:FindFirstChildWhichIsA("BasePart")
    if not handle and gunDrop:IsA("BasePart") then handle=gunDrop end
    if handle then
        PlaceGunMarker(handle.Position+Vector3.new(0,0.1,0))
        local bb=Instance.new("BillboardGui"); bb.Adornee=handle; bb.Size=UDim2.new(0,130,0,36)
        bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.MaxDistance=300; bb.Parent=handle
        local bg=Instance.new("Frame",bb); bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0)
        bg.BackgroundTransparency=0.4
        Instance.new("UICorner",bg).CornerRadius=UDim.new(0,6)
        local bgS=Instance.new("UIStroke",bg); bgS.Color=gunHLColor; bgS.Thickness=1.5
        local lbl=Instance.new("TextLabel",bg); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text="GUN ON MAP"; lbl.TextColor3=gunHLColor; lbl.Font=Enum.Font.GothamBlack; lbl.TextSize=13
        activeBB=bb
    elseif gunDrop:IsA("Model") then
        PlaceGunMarker(gunDrop:GetModelCFrame().Position+Vector3.new(0,0.1,0))
    end
end

local function FindGunDrop() return Workspace:FindFirstChild("GunDrop",true) end
local function OnGunFound(gd) if droppedGunEspEnabled then ApplyGunESP(gd) end; Notify("Gun dropped on the map!") end
local function OnGunRemoved() ClearGunESP(); ClearGunMarker() end

local watchedFolders={}
local function WatchFolder(folder)
    if watchedFolders[folder] then return end; watchedFolders[folder]=true
    folder.ChildAdded:Connect(function(obj)
        if obj.Name=="GunDrop" then task.wait(0.1); OnGunFound(obj) end
        if obj:IsA("Model") or obj:IsA("Folder") then WatchFolder(obj) end
    end)
    folder.ChildRemoved:Connect(function(obj) if obj.Name=="GunDrop" then OnGunRemoved() end end)
    for _,c in ipairs(folder:GetChildren()) do
        if c:IsA("Model") or c:IsA("Folder") then WatchFolder(c) end
    end
end
WatchFolder(Workspace)
Workspace.ChildAdded:Connect(function(obj)
    if obj:IsA("Model") or obj:IsA("Folder") then WatchFolder(obj) end
    if obj.Name=="GunDrop" then task.wait(0.1); OnGunFound(obj) end
end)
task.spawn(function() task.wait(1.5); local ex=FindGunDrop(); if ex then OnGunFound(ex) end end)

local function WatchSheriff(p)
    local function hook(char)
        if not char then return end
        local hum=char:WaitForChild("Humanoid",5); if not hum then return end
        hum.Died:Connect(function()
            if p.Backpack:FindFirstChild("Gun") or char:FindFirstChild("Gun") then
                task.delay(0.8,function() local gd=FindGunDrop(); if gd then OnGunFound(gd) end end)
            end
        end)
    end
    if p.Character then hook(p.Character) end
    p.CharacterAdded:Connect(hook)
end
for _,p in ipairs(Players:GetPlayers()) do if p~=player then task.spawn(WatchSheriff,p) end end
Players.PlayerAdded:Connect(function(p) if p~=player then WatchSheriff(p) end end)

-- ================================================================
--  ROLE ESP (aynen)
-- ================================================================
local function GetRole(p)
    local role="Innocent"; local pData=rolesData[p.Name]
    if pData then
        local r=tostring(pData.Role or pData.role or pData.Team or ""):lower()
        if r:find("murd") then role="Murderer"
        elseif r:find("sheriff") or r:find("gun") then role="Sheriff"
        elseif r:find("hero") then role="Hero" end
    end
    return role
end
local function ApplyHL(char,color)
    local hl=char:FindFirstChild("RuzHub_ESP") or Instance.new("Highlight")
    hl.Name="RuzHub_ESP"; hl.Parent=char; hl.FillColor=color
    hl.FillTransparency=0.70; hl.OutlineColor=Color3.fromRGB(255,255,255)
    hl.OutlineTransparency=0.15; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
end
local function RemoveHL(char) local hl=char:FindFirstChild("RuzHub_ESP"); if hl then hl:Destroy() end end
local function ClearAllESP()
    for _,p in ipairs(Players:GetPlayers()) do if p.Character then RemoveHL(p.Character) end end
    rolesData={}; lastEspTick=0
end
local function StartESP()
    local remote=ReplicatedStorage:FindFirstChild("GetCurrentPlayerData",true)
    if not remote or not remote:IsA("RemoteFunction") then Notify("ESP remote not found!"); espEnabled=false; return end
    if espConn then espConn:Disconnect(); espConn=nil end
    espConn=RunService.Heartbeat:Connect(function()
        if not espEnabled then return end
        if tick()-lastEspTick>0.5 then
            local ok,data=pcall(function() return remote:InvokeServer() end)
            if ok and type(data)=="table" then rolesData=data end
            lastEspTick=tick()
        end
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local role=GetRole(p); local show=espSettings[role]
                if p==player and not espSettings.Self then show=false end
                if show then ApplyHL(p.Character,ESP_COLORS[role]) else RemoveHL(p.Character) end
            end
        end
    end)
end
local function StopESP() if espConn then espConn:Disconnect(); espConn=nil end; task.delay(0.1,ClearAllESP) end
local function SetESP(on) espEnabled=on; if on then StartESP() else StopESP() end end

-- ================================================================
--  WEAPON HELPERS (aynen)
-- ================================================================
local function HasKnife(p)
    return p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife"))
end
local function HasGun(p)
    return p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun"))
end

-- ================================================================
--  TARGET FINDER (aynen)
-- ================================================================
local function FindBestTarget()
    local myChar=player.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local myHasKnife=HasKnife(player); local myHasGun=HasGun(player)
    local best,bestDist=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            local c=p.Character; local hum=c:FindFirstChildOfClass("Humanoid")
            if not(hum and hum.Health>0) then continue end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local theyHaveKnife=HasKnife(p); local theyHaveGun=HasGun(p)
            local dist=(hrp.Position-myHRP.Position).Magnitude; local valid=false
            if myHasKnife then if theyHaveKnife then valid=true end
            elseif myHasGun then if theyHaveGun or theyHaveKnife then valid=true end
            else
                if theyHaveKnife then valid=true; dist=dist-1000 end
                if theyHaveGun then valid=true end
            end
            if valid and dist<bestDist then bestDist=dist; best=c end
        end
    end
    if not best then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local c=p.Character; local hum=c:FindFirstChildOfClass("Humanoid"); local hrp=c:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health>0 and hrp then
                    local dist=(hrp.Position-myHRP.Position).Magnitude
                    if dist<bestDist then bestDist=dist; best=c end
                end
            end
        end
    end
    return best
end

-- ================================================================
--  PREDICTION LOOP (aynen)
-- ================================================================
RunService.RenderStepped:Connect(function()
    local tgt=FindBestTarget(); currentTarget=tgt; if not tgt then return end
    local myChar=player.Character; local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local torso=tgt:FindFirstChild("UpperTorso") or tgt:FindFirstChild("Torso") or tgt:FindFirstChild("HumanoidRootPart")
    local hum=tgt:FindFirstChildOfClass("Humanoid"); if not torso then return end
    local aimPos=torso.Position; local dist=(aimPos-myHRP.Position).Magnitude; local tt=dist/BULLET_SPEED
    if autoPingPred then
        local ok,ping=pcall(function() return player:GetNetworkPing() end)
        if ok and ping then tt=tt+ping*0.5 end
    end
    local vel=torso.AssemblyLinearVelocity
    if hum then
        local state=hum:GetState()
        if state==Enum.HumanoidStateType.Freefall or state==Enum.HumanoidStateType.Jumping then
            vel=Vector3.new(vel.X,vel.Y*0.35,vel.Z)
        end
    end
    predPart.CFrame=CFrame.new(aimPos+vel*tt)
end)

-- ================================================================
--  AUTO KILL (aynen)
-- ================================================================
local function AutoKill()
    local char=player.Character; if not char then return end
    local myHRP=char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local gun=player.Backpack:FindFirstChild("Gun") or char:FindFirstChild("Gun")
    if not gun then Notify("No gun in inventory!"); return end
    if not currentTarget then Notify("No target found."); return end
    if gun.Parent~=char then char.Humanoid:EquipTool(gun); task.wait(0) end
    local tPos=predPart.CFrame.Position; local origin=myHRP.Position+Vector3.new(0,1.0,0)
    pcall(function() gun:WaitForChild("Shoot"):FireServer(CFrame.new(origin,tPos),CFrame.new(tPos)) end)
end

-- ================================================================
--  KNIFE THROW (aynen)
-- ================================================================
local function ThrowKnife()
    local char=player.Character; if not char then return end
    local myHRP=char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local knife=player.Backpack:FindFirstChild("Knife") or char:FindFirstChild("Knife")
    if not knife then Notify("No knife in inventory!"); return end
    if knife.Parent~=char then char.Humanoid:EquipTool(knife); task.wait(0) end
    local tgtChar=currentTarget
    if not tgtChar then
        local nd=math.huge
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=player and p.Character then
                local hrp=p.Character:FindFirstChild("HumanoidRootPart"); local hum=p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health>0 then
                    local d=(hrp.Position-myHRP.Position).Magnitude; if d<nd then nd=d; tgtChar=p.Character end
                end
            end
        end
    end
    if not tgtChar then Notify("No target found!"); return end
    local tHRP=tgtChar:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
    local torso=tgtChar:FindFirstChild("UpperTorso") or tgtChar:FindFirstChild("Torso") or tHRP
    local vel=tHRP.AssemblyLinearVelocity; local dist=(torso.Position-myHRP.Position).Magnitude; local extra=0
    if autoPingPred then local ok,ping=pcall(function() return player:GetNetworkPing() end); extra=ok and ping or 0 end
    local predPos=torso.Position+Vector3.new(vel.X,0,vel.Z)*(dist/KNIFE_SPEED+extra*0.5)
    pcall(function()
        knife:WaitForChild("Events"):WaitForChild("KnifeThrown"):FireServer(CFrame.new(myHRP.Position,predPos),CFrame.new(predPos))
    end)
end

local function SmartShoot() if HasKnife(player) then ThrowKnife() else AutoKill() end end

-- ================================================================
--  FLICK (aynen)
-- ================================================================
local function DoSmartFlick()
    if flickCD then return end
    local char=player.Character; if not char then return end
    local myHRP=char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    flickCD=true
    local isShiftLock=UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter
    if not isShiftLock then
        local s=myHRP.CFrame; local t=s*CFrame.Angles(0,math.pi,0)
        for i=1,4 do myHRP.CFrame=s:Lerp(t,i/4); RunService.RenderStepped:Wait() end
    else
        local camCF=Camera.CFrame; local look=camCF.LookVector
        local nl=Vector3.new(-look.X,look.Y,-look.Z); local tgt=CFrame.lookAt(camCF.Position,camCF.Position+nl)
        for i=1,5 do Camera.CFrame=camCF:Lerp(tgt,i/5); RunService.RenderStepped:Wait() end
    end
    task.wait(0.15); flickCD=false
end

-- ================================================================
--  WALL HOP (aynen)
-- ================================================================
local function DoWallHop()
    if wallhopCD then return end
    local char=player.Character; if not char then return end
    local myHRP=char:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    wallhopCD=true
    local isSL=UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter
    local _,origYaw,_=myHRP.CFrame:ToEulerAnglesYXZ(); local origCamCF=Camera.CFrame; local STEPS=7
    if not isSL then
        local ty=origYaw-math.pi/2
        for i=1,STEPS do
            local e=1-(1-i/STEPS)^2
            myHRP.CFrame=CFrame.new(myHRP.Position)*CFrame.fromEulerAnglesYXZ(0,origYaw+(ty-origYaw)*e,0)
            RunService.RenderStepped:Wait()
        end
    else
        local ol=Vector3.new(origCamCF.LookVector.X,0,origCamCF.LookVector.Z).Unit
        local tl=Vector3.new(origCamCF.RightVector.X,0,origCamCF.RightVector.Z).Unit
        for i=1,STEPS do
            local e=1-(1-i/STEPS)^2
            Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position+ol:Lerp(tl,e).Unit)
            RunService.RenderStepped:Wait()
        end
    end
    local v=myHRP.AssemblyLinearVelocity; myHRP.AssemblyLinearVelocity=Vector3.new(v.X,55,v.Z)
    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end); task.wait(0.12)
    if not isSL then
        local _,cy,_=myHRP.CFrame:ToEulerAnglesYXZ()
        for i=1,5 do
            local e=1-(1-i/5)^2
            myHRP.CFrame=CFrame.new(myHRP.Position)*CFrame.fromEulerAnglesYXZ(0,cy+(origYaw-cy)*e,0)
            RunService.RenderStepped:Wait()
        end
    else
        local ol=Vector3.new(origCamCF.LookVector.X,0,origCamCF.LookVector.Z).Unit
        local cl=Vector3.new(Camera.CFrame.LookVector.X,0,Camera.CFrame.LookVector.Z).Unit
        for i=1,5 do
            local e=1-(1-i/5)^2
            Camera.CFrame=CFrame.lookAt(Camera.CFrame.Position,Camera.CFrame.Position+cl:Lerp(ol,e).Unit)
            RunService.RenderStepped:Wait()
        end
    end
    task.wait(0.10); wallhopCD=false
end

-- ================================================================
--  BOMB RETRIEVER (aynen)
-- ================================================================
task.spawn(function()
    while true do task.wait(2)
        pcall(function()
            ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("FakeBomb")
            ReplicatedStorage.Remotes.Extras.ReplicateToy:InvokeServer("GoldBomb")
        end)
    end
end)

-- ================================================================
--  JUMP ENGINE (aynen)
-- ================================================================
local function ExecuteJump(bombName,isGold)
    local char=player.Character; if not char then return end
    local bomb=player.Backpack:FindFirstChild(bombName) or char:FindFirstChild(bombName)
    if not bomb then Notify("No "..bombName.." found!"); return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if bomb.Parent~=char then char.Humanoid:EquipTool(bomb); task.wait() end
    pcall(function() bomb.Remote:FireServer(CFrame.new(hrp.Position+hrp.CFrame.LookVector*1.5+Vector3.new(0,-3,0)),50) end)
    char.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,62,hrp.AssemblyLinearVelocity.Z)
    if isGold then task.spawn(function() goldCD=true; task.wait(4); goldCD=false end)
    else task.spawn(function() normalCD=true; task.wait(21); normalCD=false end) end
end

-- ================================================================
--  SPEED GLITCH (aynen)
-- ================================================================
local function SetupSpeedGlitch(char)
    local hum=char:WaitForChild("Humanoid")
    if speedConn then speedConn:Disconnect() end
    speedConn=RunService.RenderStepped:Connect(function()
        if not speedEnabled then hum.WalkSpeed=16; return end
        local state=hum:GetState()
        local inAir=state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall
        hum.WalkSpeed=(inAir and hum.MoveDirection.Magnitude>0) and BASE_GLITCH or 16
    end)
end
player.CharacterAdded:Connect(SetupSpeedGlitch)
if player.Character then task.spawn(SetupSpeedGlitch,player.Character) end

-- ================================================================
--  STRETCH (aynen)
-- ================================================================
local function SetStretch(on)
    stretchEnabled=on
    if on then
        if stretchConn then stretchConn:Disconnect() end
        stretchConn=RunService.RenderStepped:Connect(function()
            Camera.CFrame=Camera.CFrame*CFrame.new(0,0,0,1,0,0,0,stretchValue/100,0,0,0,1)
        end)
    else
        if stretchConn then stretchConn:Disconnect(); stretchConn=nil end
    end
end

local function OpenStretchSlider()
    OpenSliderPopup("Stretch Resolution",10,100,stretchValue,5,
        function(v) stretchValue=v; if stretchEnabled then SetStretch(true) end; Notify("Stretch: "..v.."%") end,
        function() stretchValue=50; if stretchEnabled then SetStretch(true) end; Notify("Stretch reset to 50%") end
    )
end

-- ================================================================
--  GRAB GUN (aynen)
-- ================================================================
local function DoGrabGun()
    local gd=Workspace:FindFirstChild("GunDrop",true); if not gd then Notify("No gun on map!"); return end
    local char=player.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local targetPos
    if gd:IsA("BasePart") then targetPos=gd.Position
    else local part=gd:FindFirstChild("Handle") or gd:FindFirstChildWhichIsA("BasePart") or gd.PrimaryPart
        targetPos=part and part.Position or gd:GetModelCFrame().Position end
    if not targetPos then Notify("Gun position not found!"); return end
    local oldCF=hrp.CFrame; hrp.CFrame=CFrame.new(targetPos+Vector3.new(0,2,0)); task.wait(0.2); hrp.CFrame=oldCF
    Notify("Teleported to gun!")
end

-- ================================================================
--  ANTI-FLING (aynen)
-- ================================================================
local function SetAntiFling(on)
    antiFling=on
    if on then
        if antiFlingConn then antiFlingConn:Disconnect() end
        antiFlingConn=RunService.Heartbeat:Connect(function()
            if not antiFling then return end
            local c=player.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel=hrp.AssemblyLinearVelocity
                if vel.Magnitude>MAX_VELOCITY then hrp.AssemblyLinearVelocity=vel.Unit*MAX_VELOCITY end
            end
        end)
    else if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn=nil end end
end

-- ================================================================
--  FLING ENGINE (aynen)
-- ================================================================
getgenv().RuzOldPos=nil; getgenv().RuzFPDH=Workspace.FallenPartsDestroyHeight

local function SkidFling(targetPlayer)
    if flingBusy then return end
    local char=player.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local myHRP=hum.RootPart; if not myHRP then return end
    local tChar=targetPlayer.Character; if not tChar then return end
    local tHum=tChar:FindFirstChildOfClass("Humanoid"); local tHRP=tHum and tHum.RootPart
    local tHead=tChar:FindFirstChild("Head"); local acc=tChar:FindFirstChildOfClass("Accessory")
    local aHandle=acc and acc:FindFirstChild("Handle")
    if myHRP.Velocity.Magnitude<50 then getgenv().RuzOldPos=myHRP.CFrame end
    if tHum and tHum.Sit then Notify(targetPlayer.Name.." is sitting, skipped."); return end
    local camSubj=tHead or aHandle or tHum
    if camSubj then Workspace.CurrentCamera.CameraSubject=camSubj end
    if not tChar:FindFirstChildWhichIsA("BasePart") then return end
    local function FPos(base,offset,ang)
        myHRP.CFrame=CFrame.new(base.Position)*offset*ang
        pcall(function() char:SetPrimaryPartCFrame(CFrame.new(base.Position)*offset*ang) end)
        myHRP.Velocity=Vector3.new(9e7,9e7*10,9e7); myHRP.RotVelocity=Vector3.new(9e8,9e8,9e8)
    end
    local function RunFling(basePart)
        local deadline=tick()+2.5; local angle=0
        repeat
            if not(myHRP and tHum) then break end
            local spd=basePart.Velocity.Magnitude
            if spd<40 then
                angle+=100
                FPos(basePart,CFrame.new(0,1.5,0)+tHum.MoveDirection*spd/1.25,CFrame.Angles(math.rad(angle),0,0)); task.wait()
                FPos(basePart,CFrame.new(0,-1.5,0)+tHum.MoveDirection*spd/1.25,CFrame.Angles(math.rad(angle),0,0)); task.wait()
                FPos(basePart,CFrame.new(0,1.5,0)+tHum.MoveDirection*spd/1.25,CFrame.Angles(math.rad(angle),0,0)); task.wait()
                FPos(basePart,CFrame.new(0,-1.5,0)+tHum.MoveDirection*spd/1.25,CFrame.Angles(math.rad(angle),0,0)); task.wait()
                FPos(basePart,CFrame.new(0,1.5,0),CFrame.Angles(math.rad(angle),0,0)); task.wait()
                FPos(basePart,CFrame.new(0,-1.5,0),CFrame.Angles(math.rad(angle),0,0)); task.wait()
            else
                local dir=tHum.MoveDirection; local ws=tHum.WalkSpeed
                FPos(basePart,CFrame.new(dir.X*ws*0.12,3,dir.Z*ws*0.12),CFrame.Angles(math.rad(90),0,0))
                myHRP.Velocity=Vector3.new(9e8,9e8,9e8); task.wait()
                FPos(basePart,CFrame.new(-dir.X*ws*0.06,-3,-dir.Z*ws*0.06),CFrame.Angles(0,0,0))
                myHRP.Velocity=Vector3.new(9e8,9e8,9e8); task.wait()
                FPos(basePart,CFrame.new(dir.X*ws*0.18,3,dir.Z*ws*0.18),CFrame.Angles(math.rad(90),0,0))
                myHRP.Velocity=Vector3.new(9e8,9e8,9e8); task.wait()
                FPos(basePart,CFrame.new(-dir.X*ws*0.06,-3,-dir.Z*ws*0.06),CFrame.Angles(0,0,0))
                myHRP.Velocity=Vector3.new(9e8,9e8,9e8); task.wait()
            end
        until tick()>deadline
    end
    flingBusy=true; Workspace.FallenPartsDestroyHeight=0/0
    local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,0,0); bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Parent=myHRP
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
    local basePart=tHRP or tHead or aHandle
    if basePart then RunFling(basePart) else Notify(targetPlayer.Name.." — no valid fling part.") end
    bv:Destroy(); hum:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
    Workspace.CurrentCamera.CameraSubject=hum
    if getgenv().RuzOldPos then
        local attempts=0
        repeat
            attempts+=1; myHRP.CFrame=getgenv().RuzOldPos*CFrame.new(0,0.5,0)
            pcall(function() char:SetPrimaryPartCFrame(getgenv().RuzOldPos*CFrame.new(0,0.5,0)) end)
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _,p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then p.Velocity=Vector3.new(); p.RotVelocity=Vector3.new() end
            end
            task.wait()
        until attempts>30 or (myHRP.Position-getgenv().RuzOldPos.p).Magnitude<25
        Workspace.FallenPartsDestroyHeight=getgenv().RuzFPDH; Notify("Returned to previous position.")
    end
    flingBusy=false
end

local function FlingMurderer()
    if flingBusy then Notify("Fling in progress..."); return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and HasKnife(p) then
            local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then Notify("Flinging: "..p.Name); task.spawn(SkidFling,p); return end
        end
    end
    Notify("No knife player found!")
end

local function FlingSheriff()
    if flingBusy then Notify("Fling in progress..."); return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and HasGun(p) then
            local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health>0 then Notify("Flinging: "..p.Name); task.spawn(SkidFling,p); return end
        end
    end
    Notify("No gun player found!")
end

-- ================================================================
--  GRAPHICS (aynen)
-- ================================================================
local origLightData={GlobalShadows=Lighting.GlobalShadows,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient}
local origPartData={}; local lgDescConn=nil

local function ApplyLGToInstance(v)
    if v:IsA("BasePart") then
        if not origPartData[v] then origPartData[v]={Material=v.Material,CastShadow=v.CastShadow} end
        v.Material=Enum.Material.SmoothPlastic; v.CastShadow=false
    end
    if v:IsA("Decal") or v:IsA("Texture") then
        if not origPartData[v] then origPartData[v]={Transparency=v.Transparency} end
        v.Transparency=1
    end
end

local function EnableLowGraphics()
    if highGraphics then
        highGraphics=false; Lighting.Brightness=origLightData.Brightness; Lighting.GlobalShadows=origLightData.GlobalShadows
        Lighting.Ambient=origLightData.Ambient; Lighting.OutdoorAmbient=origLightData.OutdoorAmbient
        for _,obj in pairs(Lighting:GetChildren()) do
            if obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then obj:Destroy() end
        end
    end
    lowGraphics=true
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    pcall(function() setfpscap(9999) end)
    Lighting.GlobalShadows=false; Lighting.Brightness=2
    for _,v in ipairs(Workspace:GetDescendants()) do pcall(function() ApplyLGToInstance(v) end) end
    if lgDescConn then lgDescConn:Disconnect() end
    lgDescConn=Workspace.DescendantAdded:Connect(function(v) task.wait(0.1); pcall(function() ApplyLGToInstance(v) end) end)
    lgStarLbl.Visible=true; Notify("Low Graphics ON")
end

local function DisableLowGraphics()
    lowGraphics=false; pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic end)
    Lighting.GlobalShadows=origLightData.GlobalShadows; Lighting.Brightness=origLightData.Brightness
    Lighting.Ambient=origLightData.Ambient; Lighting.OutdoorAmbient=origLightData.OutdoorAmbient
    if lgDescConn then lgDescConn:Disconnect(); lgDescConn=nil end
    for obj,data in pairs(origPartData) do
        if obj and obj.Parent then pcall(function() for k,v in pairs(data) do obj[k]=v end end) end
    end
    origPartData={}; lgStarLbl.Visible=false; Notify("Low Graphics OFF")
end

local function EnableHighGraphics()
    if lowGraphics then DisableLowGraphics() end
    highGraphics=true; pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level21 end)
    Lighting.GlobalShadows=true; Lighting.Brightness=3.5
    Lighting.Ambient=Color3.fromRGB(80,80,100); Lighting.OutdoorAmbient=Color3.fromRGB(100,110,130)
    local bloom=Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect",Lighting)
    bloom.Intensity=0.6; bloom.Size=24; bloom.Threshold=0.95
    local rays=Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect",Lighting)
    rays.Intensity=0.25; rays.Spread=1
    local cc=Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect",Lighting)
    cc.Saturation=0.2; cc.Contrast=0.1; cc.Brightness=0.05
    Notify("High Graphics ON")
end

local function DisableHighGraphics()
    highGraphics=false; pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic end)
    Lighting.Brightness=origLightData.Brightness; Lighting.GlobalShadows=origLightData.GlobalShadows
    Lighting.Ambient=origLightData.Ambient; Lighting.OutdoorAmbient=origLightData.OutdoorAmbient
    for _,obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect") then obj:Destroy() end
    end
    Notify("High Graphics OFF")
end

-- ================================================================
--  SKYBOX (aynen)
-- ================================================================
local SKYBOX_PRESETS={
    {name="Red",    id="98490421374360", color=Color3.fromRGB(200,50,50)  },
    {name="Pink",   id="95000769820905", color=Color3.fromRGB(220,100,180)},
    {name="Pink 2", id="82988835868087", color=Color3.fromRGB(200,80,160) },
    {name="Green",  id="5036205687",     color=Color3.fromRGB(50,180,80)  },
    {name="Black",  id="80807192441609", color=Color3.fromRGB(30,30,30)   },
    {name="Cosmic", id="77816282467771", color=Color3.fromRGB(80,40,160)  },
    {name="Yellow", id="2669948520",     color=Color3.fromRGB(220,190,40) },
}
local defaultSkyData=nil
local function SaveDefaultSky()
    local s=Lighting:FindFirstChildOfClass("Sky"); if s then
        defaultSkyData={SkyboxBk=s.SkyboxBk,SkyboxDn=s.SkyboxDn,SkyboxFt=s.SkyboxFt,SkyboxLf=s.SkyboxLf,SkyboxRt=s.SkyboxRt,SkyboxUp=s.SkyboxUp}
    end
end
SaveDefaultSky()

local function RestoreDefaultSky()
    for _,obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then obj:Destroy() end
    end
    if defaultSkyData then local s=Instance.new("Sky",Lighting); for k,v in pairs(defaultSkyData) do s[k]=v end end
    skyboxActive=false; Notify("Skybox restored.")
end

local function ApplySkyboxById(id)
    for _,obj in pairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then obj:Destroy() end
    end
    local sky=Instance.new("Sky",Lighting); sky.Name="RuzHub_CustomSky"
    local u="rbxassetid://"..tostring(id)
    sky.SkyboxBk=u; sky.SkyboxDn=u; sky.SkyboxFt=u; sky.SkyboxLf=u; sky.SkyboxRt=u; sky.SkyboxUp=u
    sky.SunTextureId=""; sky.MoonTextureId=""; sky.SunAngularSize=0; sky.StarCount=0
    Lighting.ClockTime=14; Lighting.Brightness=2; Lighting.GlobalShadows=false; Lighting.FogEnd=999999
    skyboxActive=true
end

-- ================================================================
--  SKYBOX PICKER UI (aynen)
-- ================================================================
local function OpenSkyboxPicker()
    local uid="RuzSkyboxPicker"; local ex=game.CoreGui:FindFirstChild(uid); if ex then ex:Destroy(); return end
    local sg=Instance.new("ScreenGui",game.CoreGui); sg.Name=uid; sg.ResetOnSpawn=false; sg.DisplayOrder=62
    local frame=Instance.new("Frame",sg); frame.Size=UDim2.new(0,310,0,420); frame.Position=UDim2.new(0.5,-155,0.04,0)
    frame.BackgroundColor3=Color3.fromRGB(10,10,10); frame.BackgroundTransparency=0.06
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
    local fs=Instance.new("UIStroke",frame); fs.Color=Color3.fromRGB(220,38,38); fs.Thickness=1.5
    local hdr=Instance.new("TextLabel",frame); hdr.Size=UDim2.new(1,-44,0,38); hdr.Position=UDim2.new(0,12,0,0)
    hdr.BackgroundTransparency=1; hdr.Text="RuzHub — Skybox Picker"; hdr.TextColor3=Color3.fromRGB(255,255,255)
    hdr.Font=Enum.Font.GothamBold; hdr.TextSize=14; hdr.TextXAlignment=Enum.TextXAlignment.Left
    local xBtn=Instance.new("TextButton",frame); xBtn.Size=UDim2.new(0,28,0,28); xBtn.Position=UDim2.new(1,-34,0,5)
    xBtn.BackgroundColor3=Color3.fromRGB(180,30,30); xBtn.Text="X"; xBtn.TextColor3=Color3.new(1,1,1)
    xBtn.Font=Enum.Font.GothamBold; xBtn.TextSize=13
    Instance.new("UICorner",xBtn).CornerRadius=UDim.new(0,6); xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    local idBox=Instance.new("TextBox",frame); idBox.Size=UDim2.new(1,-20,0,34); idBox.Position=UDim2.new(0,10,0,44)
    idBox.BackgroundColor3=Color3.fromRGB(25,25,25); idBox.Text=""; idBox.PlaceholderText="Enter custom Skybox ID, press Enter..."
    idBox.TextColor3=Color3.new(1,1,1); idBox.PlaceholderColor3=Color3.fromRGB(120,120,120)
    idBox.Font=Enum.Font.Gotham; idBox.TextSize=13; idBox.ClearTextOnFocus=false
    Instance.new("UICorner",idBox).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",idBox).Color=Color3.fromRGB(80,80,80)
    idBox.FocusLost:Connect(function(enter)
        if enter and idBox.Text~="" then ApplySkyboxById(idBox.Text); Notify("Custom skybox: "..idBox.Text); idBox.Text="" end
    end)
    local restoreBtn=Instance.new("TextButton",frame); restoreBtn.Size=UDim2.new(1,-20,0,28); restoreBtn.Position=UDim2.new(0,10,0,84)
    restoreBtn.BackgroundColor3=Color3.fromRGB(40,40,40); restoreBtn.Text="Restore Default Sky"
    restoreBtn.TextColor3=Color3.fromRGB(200,200,200); restoreBtn.Font=Enum.Font.GothamBold; restoreBtn.TextSize=12
    Instance.new("UICorner",restoreBtn).CornerRadius=UDim.new(0,6)
    restoreBtn.MouseButton1Click:Connect(function() RestoreDefaultSky(); sg:Destroy() end)
    local sep=Instance.new("Frame",frame); sep.Size=UDim2.new(1,-20,0,1); sep.Position=UDim2.new(0,10,0,118)
    sep.BackgroundColor3=Color3.fromRGB(60,60,60)
    local scroll=Instance.new("ScrollingFrame",frame); scroll.Size=UDim2.new(1,-14,1,-126); scroll.Position=UDim2.new(0,7,0,124)
    scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=4
    scroll.CanvasSize=UDim2.new(0,0,0,#SKYBOX_PRESETS*56)
    local uiList=Instance.new("UIListLayout",scroll); uiList.Padding=UDim.new(0,6); uiList.SortOrder=Enum.SortOrder.LayoutOrder
    for i,preset in ipairs(SKYBOX_PRESETS) do
        local row=Instance.new("TextButton",scroll); row.Size=UDim2.new(1,-8,0,48); row.BackgroundColor3=Color3.fromRGB(20,20,20)
        row.Text=""; row.AutoButtonColor=false; row.LayoutOrder=i
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        local rs=Instance.new("UIStroke",row); rs.Color=preset.color; rs.Thickness=1
        local colorBox=Instance.new("Frame",row); colorBox.Size=UDim2.new(0,34,0,34); colorBox.Position=UDim2.new(0,8,0.5,-17)
        colorBox.BackgroundColor3=preset.color
        Instance.new("UICorner",colorBox).CornerRadius=UDim.new(0,6)
        local nameLbl=Instance.new("TextLabel",row); nameLbl.Size=UDim2.new(1,-58,0,22); nameLbl.Position=UDim2.new(0,50,0,6)
        nameLbl.BackgroundTransparency=1; nameLbl.Text=preset.name; nameLbl.TextColor3=Color3.fromRGB(210,210,210)
        nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=14; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
        local idLbl=Instance.new("TextLabel",row); idLbl.Size=UDim2.new(1,-58,0,14); idLbl.Position=UDim2.new(0,50,1,-18)
        idLbl.BackgroundTransparency=1; idLbl.Text="ID: "..preset.id; idLbl.TextColor3=Color3.fromRGB(100,100,100)
        idLbl.Font=Enum.Font.Gotham; idLbl.TextSize=10; idLbl.TextXAlignment=Enum.TextXAlignment.Left
        row.MouseButton1Click:Connect(function()
            ApplySkyboxById(preset.id); Notify("Skybox: "..preset.name)
            for _,child in ipairs(scroll:GetChildren()) do
                if child:IsA("TextButton") then
                    local st=child:FindFirstChildOfClass("UIStroke"); if st then st.Thickness=1; st.Color=Color3.fromRGB(80,80,80) end
                    child.BackgroundColor3=Color3.fromRGB(20,20,20)
                end
            end
            rs.Thickness=2; rs.Color=Color3.fromRGB(220,38,38); row.BackgroundColor3=Color3.fromRGB(50,15,15); nameLbl.TextColor3=Color3.fromRGB(255,80,80)
        end)
    end
    MakeDraggable(frame)
end

-- ================================================================
--  CROSSHAIR DISPLAY (aynen)
-- ================================================================
local function UpdateCrosshairSpin()
    if spinConn then spinConn:Disconnect(); spinConn=nil end
    if crosshairSpin and crosshairImg and crosshairImg.Parent then
        spinConn=RunService.RenderStepped:Connect(function()
            if crosshairImg and crosshairImg.Parent and crosshairImg.Visible then
                crosshairImg.Rotation=crosshairImg.Rotation+4
            end
        end)
    else if crosshairImg then crosshairImg.Rotation=0 end end
end

local function SetupCrosshairDisplay()
    local old=game.CoreGui:FindFirstChild("RuzCrosshairDisplay"); if old then old:Destroy() end
    if spinConn then spinConn:Disconnect(); spinConn=nil end
    local sg=Instance.new("ScreenGui",game.CoreGui)
    sg.Name="RuzCrosshairDisplay"; sg.ResetOnSpawn=false; sg.DisplayOrder=25; sg.IgnoreGuiInset=true
    crosshairImg=Instance.new("ImageLabel",sg)
    crosshairImg.AnchorPoint=Vector2.new(0.5,0.5); crosshairImg.Position=UDim2.new(0.5,0,0.5,0)
    crosshairImg.Size=UDim2.new(0,42,0,42); crosshairImg.BackgroundTransparency=1
    crosshairImg.Image="rbxassetid://"..activeCursorId; crosshairImg.ZIndex=10; crosshairImg.Visible=false
    RunService.RenderStepped:Connect(function()
        if not(crosshairImg and crosshairImg.Parent) then return end
        local locked=UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter
        local pg=player:FindFirstChild("PlayerGui")
        if pg then local tb=pg:FindFirstChild("GameTopbar"); if tb and tb:FindFirstChild("Crosshair") then tb.Crosshair.Visible=false end end
        local show=crosshairActive and locked
        crosshairImg.Visible=show; UserInputService.MouseIconEnabled=not show
    end)
    UpdateCrosshairSpin()
end

-- ================================================================
--  CROSSHAIR PICKER UI (aynen)
-- ================================================================
local CURSORS={
    {name="Neon Cyan",       id="11770890197"},
    {name="Electric Purple", id="11770691141"},
    {name="Precision Dot",   id="10878218308"},
    {name="Aim Cross",       id="10891594349"},
    {name="Blue Spec",       id="11720475063"},
    {name="Circle Dot",      id="10831379335"},
    {name="Green Hit",       id="8375241602" },
}

local function OpenCursorPicker()
    local uid="RuzCursorPicker"; local ex=game.CoreGui:FindFirstChild(uid); if ex then ex:Destroy(); return end
    local sg=Instance.new("ScreenGui",game.CoreGui); sg.Name=uid; sg.ResetOnSpawn=false; sg.DisplayOrder=60
    local frame=Instance.new("Frame",sg); frame.Size=UDim2.new(0,300,0,460); frame.Position=UDim2.new(0.5,-150,0.04,0)
    frame.BackgroundColor3=Color3.fromRGB(10,10,10); frame.BackgroundTransparency=0.06
    Instance.new("UICorner",frame).CornerRadius=UDim.new(0,12)
    local fs=Instance.new("UIStroke",frame); fs.Color=Color3.fromRGB(220,38,38); fs.Thickness=1.5
    local hdr=Instance.new("TextLabel",frame); hdr.Size=UDim2.new(1,-44,0,38); hdr.Position=UDim2.new(0,12,0,0)
    hdr.BackgroundTransparency=1; hdr.Text="RuzHub — Cursor Picker"; hdr.TextColor3=Color3.fromRGB(255,255,255)
    hdr.Font=Enum.Font.GothamBold; hdr.TextSize=14; hdr.TextXAlignment=Enum.TextXAlignment.Left
    local xBtn=Instance.new("TextButton",frame); xBtn.Size=UDim2.new(0,28,0,28); xBtn.Position=UDim2.new(1,-34,0,5)
    xBtn.BackgroundColor3=Color3.fromRGB(180,30,30); xBtn.Text="X"; xBtn.TextColor3=Color3.new(1,1,1)
    xBtn.Font=Enum.Font.GothamBold; xBtn.TextSize=13
    Instance.new("UICorner",xBtn).CornerRadius=UDim.new(0,6); xBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    local idBox=Instance.new("TextBox",frame); idBox.Size=UDim2.new(1,-20,0,34); idBox.Position=UDim2.new(0,10,0,44)
    idBox.BackgroundColor3=Color3.fromRGB(25,25,25); idBox.Text=""; idBox.PlaceholderText="Enter custom Cursor ID, press Enter..."
    idBox.TextColor3=Color3.new(1,1,1); idBox.PlaceholderColor3=Color3.fromRGB(120,120,120)
    idBox.Font=Enum.Font.Gotham; idBox.TextSize=13; idBox.ClearTextOnFocus=false
    Instance.new("UICorner",idBox).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",idBox).Color=Color3.fromRGB(80,80,80)
    idBox.FocusLost:Connect(function(enter)
        if enter and idBox.Text~="" then
            activeCursorId=idBox.Text
            if crosshairActive and crosshairImg then crosshairImg.Image="rbxassetid://"..idBox.Text end
            Notify("Custom cursor applied!"); idBox.Text=""
        end
    end)
    local spinRow=Instance.new("Frame",frame); spinRow.Size=UDim2.new(1,-20,0,30); spinRow.Position=UDim2.new(0,10,0,84)
    spinRow.BackgroundTransparency=1
    local spinLbl=Instance.new("TextLabel",spinRow); spinLbl.Size=UDim2.new(1,-64,1,0); spinLbl.BackgroundTransparency=1
    spinLbl.Text="Spin Crosshair"; spinLbl.TextColor3=Color3.fromRGB(200,200,200)
    spinLbl.Font=Enum.Font.GothamBold; spinLbl.TextSize=13; spinLbl.TextXAlignment=Enum.TextXAlignment.Left
    local spinBtn=Instance.new("TextButton",spinRow); spinBtn.Size=UDim2.new(0,54,0,26); spinBtn.Position=UDim2.new(1,-54,0.5,-13)
    spinBtn.BackgroundColor3=crosshairSpin and Color3.fromRGB(30,160,30) or Color3.fromRGB(80,20,20)
    spinBtn.Text=crosshairSpin and "ON" or "OFF"; spinBtn.TextColor3=Color3.new(1,1,1)
    spinBtn.Font=Enum.Font.GothamBold; spinBtn.TextSize=12
    Instance.new("UICorner",spinBtn).CornerRadius=UDim.new(0,8)
    spinBtn.MouseButton1Click:Connect(function()
        crosshairSpin=not crosshairSpin
        spinBtn.BackgroundColor3=crosshairSpin and Color3.fromRGB(30,160,30) or Color3.fromRGB(80,20,20)
        spinBtn.Text=crosshairSpin and "ON" or "OFF"
        UpdateCrosshairSpin(); Notify("Crosshair Spin: "..(crosshairSpin and "ON" or "OFF"))
    end)
    local sep=Instance.new("Frame",frame); sep.Size=UDim2.new(1,-20,0,1); sep.Position=UDim2.new(0,10,0,120)
    sep.BackgroundColor3=Color3.fromRGB(60,60,60)
    local scroll=Instance.new("ScrollingFrame",frame); scroll.Size=UDim2.new(1,-14,1,-128); scroll.Position=UDim2.new(0,7,0,126)
    scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=4
    scroll.CanvasSize=UDim2.new(0,0,0,math.ceil(#CURSORS/2)*118+10)
    local grid=Instance.new("UIGridLayout",scroll)
    grid.CellSize=UDim2.new(0,128,0,110); grid.CellPadding=UDim2.new(0,8,0,8); grid.SortOrder=Enum.SortOrder.LayoutOrder
    for i,cursor in ipairs(CURSORS) do
        local isActive=(activeCursorId==cursor.id)
        local cell=Instance.new("TextButton",scroll); cell.Size=UDim2.new(0,128,0,110)
        cell.BackgroundColor3=isActive and Color3.fromRGB(55,15,15) or Color3.fromRGB(20,20,20)
        cell.Text=""; cell.AutoButtonColor=false; cell.LayoutOrder=i
        Instance.new("UICorner",cell).CornerRadius=UDim.new(0,8)
        local cs=Instance.new("UIStroke",cell); cs.Color=isActive and Color3.fromRGB(220,38,38) or Color3.fromRGB(50,50,50); cs.Thickness=isActive and 1.8 or 1.2
        local img=Instance.new("ImageLabel",cell); img.Size=UDim2.new(0,58,0,58); img.AnchorPoint=Vector2.new(0.5,0)
        img.Position=UDim2.new(0.5,0,0,8); img.BackgroundTransparency=1; img.Image="rbxassetid://"..cursor.id
        local nameLbl=Instance.new("TextLabel",cell); nameLbl.Size=UDim2.new(1,-6,0,28); nameLbl.Position=UDim2.new(0,3,1,-30)
        nameLbl.BackgroundTransparency=1; nameLbl.Text=cursor.name..(isActive and " ✓" or "")
        nameLbl.TextColor3=isActive and Color3.fromRGB(255,80,80) or Color3.fromRGB(200,200,200)
        nameLbl.Font=Enum.Font.GothamBold; nameLbl.TextSize=11; nameLbl.TextWrapped=true
        cell.MouseButton1Click:Connect(function()
            activeCursorId=cursor.id
            if crosshairActive and crosshairImg then crosshairImg.Image="rbxassetid://"..cursor.id end
            Notify("Cursor: "..cursor.name); sg:Destroy()
        end)
    end
    MakeDraggable(frame)
end

-- ================================================================
--  FLOATING BUTTON SYSTEM (aynen)
-- ================================================================
local btnGui=(function()
    local old=game.CoreGui:FindFirstChild("RuzHub_BtnLayer"); if old then old:Destroy() end
    local sg=Instance.new("ScreenGui",game.CoreGui)
    sg.Name="RuzHub_BtnLayer"; sg.ResetOnSpawn=false; sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=10
    return sg
end)()

local btnRefs={}

local function AddDragBtn(btn)
    local dragging,dStart,dPos
    btn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dStart=i.Position; dPos=btn.Position
        end
    end)
    btn.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-dStart; btn.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
end

local function NewBtn(key,pos,size,color,label)
    if btnRefs[key] then btnRefs[key].btn:Destroy(); btnRefs[key]=nil end
    local btn=Instance.new("TextButton",btnGui); btn.Name="RuzBtn_"..key; btn.Size=size; btn.Position=pos
    btn.BackgroundColor3=Color3.fromRGB(0,0,0); btn.BackgroundTransparency=0.6; btn.Text=""; btn.AutoButtonColor=false; btn.BorderSizePixel=0
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,size.Y.Offset*0.20)
    local stroke=Instance.new("UIStroke",btn); stroke.Color=color; stroke.Thickness=1.3; stroke.Transparency=0.5; stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    local lbl=Instance.new("TextLabel",btn); lbl.Name="Lbl"; lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
    lbl.Text=label; lbl.TextColor3=color; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=math.max(10,size.Y.Offset*0.14)
    lbl.TextYAlignment=Enum.TextYAlignment.Center; lbl.TextXAlignment=Enum.TextXAlignment.Center
    AddDragBtn(btn); btnRefs[key]={btn=btn,stroke=stroke,lbl=lbl}; return btnRefs[key]
end

local function AddSpinImg(ref,texId)
    local bSize=ref.btn.Size.Y.Offset; local imgSz=math.floor(bSize*0.55)
    local img=Instance.new("ImageLabel",ref.btn); img.Name="SpinImg"; img.Size=UDim2.new(0,imgSz,0,imgSz)
    img.Position=UDim2.new(0.5,-imgSz/2,0.5,-imgSz/2); img.BackgroundTransparency=1
    img.Image="rbxassetid://"..tostring(texId); ref.img=img
    ref.lbl.Size=UDim2.new(1,0,0.28,0); ref.lbl.Position=UDim2.new(0,0,0.72,0); ref.lbl.TextSize=math.max(9,bSize*0.12)
    task.spawn(function() while img and img.Parent do img.Rotation+=4; RunService.RenderStepped:Wait() end end)
    return img
end

local BIG=UDim2.new(0,88,0,88); local SMALL=UDim2.new(0,56,0,56)
local DP={
    GoldBomb=UDim2.new(0.5,-210,0.78,0), NormalBomb=UDim2.new(0.5,-110,0.78,0),
    Shoot=UDim2.new(0.5,-10,0.78,0),     ESP=UDim2.new(0.5,90,0.78,16),
    Flick=UDim2.new(0.5,154,0.78,16),    Speed=UDim2.new(0.5,-278,0.78,16),
    Stretch=UDim2.new(0.5,-214,0.78,16), GrabGun=UDim2.new(0.5,90,0.68,16),
    WallHop=UDim2.new(0.5,154,0.68,16),  FlingMurderer=UDim2.new(0.5,-278,0.68,16),
    FlingSheriff=UDim2.new(0.5,-214,0.68,16),
}

local function LoadGoldBomb(v)
    if not v then if btnRefs.GoldBomb then btnRefs.GoldBomb.btn:Destroy(); btnRefs.GoldBomb=nil end; return end
    NewBtn("GoldBomb",DP.GoldBomb,BIG,Color3.fromRGB(255,215,0),"GOLD\nJUMP")
    btnRefs.GoldBomb.btn.MouseButton1Click:Connect(function() if goldCD then Notify("Gold Bomb on cooldown.") else ExecuteJump("GoldBomb",true) end end)
end
local function LoadNormalBomb(v)
    if not v then if btnRefs.NormalBomb then btnRefs.NormalBomb.btn:Destroy(); btnRefs.NormalBomb=nil end; return end
    NewBtn("NormalBomb",DP.NormalBomb,BIG,Color3.fromRGB(0,170,255),"NORMAL\nJUMP")
    btnRefs.NormalBomb.btn.MouseButton1Click:Connect(function() if normalCD then Notify("Normal Bomb on cooldown.") else ExecuteJump("FakeBomb",false) end end)
end
local function LoadShoot(v)
    if not v then if btnRefs.Shoot then btnRefs.Shoot.btn:Destroy(); btnRefs.Shoot=nil end; return end
    local ref=NewBtn("Shoot",DP.Shoot,BIG,Color3.fromRGB(255,255,255),"SHOOT"); AddSpinImg(ref,5159914132)
    ref.btn.MouseButton1Click:Connect(SmartShoot)
end
local function LoadESP(v)
    if not v then if btnRefs.ESP then btnRefs.ESP.btn:Destroy(); btnRefs.ESP=nil end; return end
    NewBtn("ESP",DP.ESP,SMALL,Color3.fromRGB(10,140,30),"ESP\nOFF")
    btnRefs.ESP.btn.MouseButton1Click:Connect(function() SetESP(not espEnabled); Notify(espEnabled and "ESP ON" or "ESP OFF") end)
end
local function LoadFlick(v)
    if not v then if btnRefs.Flick then btnRefs.Flick.btn:Destroy(); btnRefs.Flick=nil end; return end
    NewBtn("Flick",DP.Flick,SMALL,Color3.fromRGB(180,50,255),"FLICK")
    btnRefs.Flick.btn.MouseButton1Click:Connect(DoSmartFlick)
end
local function LoadSpeed(v)
    if not v then if btnRefs.Speed then btnRefs.Speed.btn:Destroy(); btnRefs.Speed=nil end; return end
    NewBtn("Speed",DP.Speed,SMALL,Color3.fromRGB(0,140,120),"SPEED")
    btnRefs.Speed.btn.MouseButton1Click:Connect(function() speedEnabled=not speedEnabled; Notify(speedEnabled and "Speed ON" or "Speed OFF") end)
end
local function LoadStretch(v)
    if not v then if btnRefs.Stretch then btnRefs.Stretch.btn:Destroy(); btnRefs.Stretch=nil end; return end
    NewBtn("Stretch",DP.Stretch,SMALL,Color3.fromRGB(200,80,0),"STRETCH")
    btnRefs.Stretch.btn.MouseButton1Click:Connect(function() stretchEnabled=not stretchEnabled; SetStretch(stretchEnabled); Notify(stretchEnabled and "Stretch ON" or "Stretch OFF") end)
end
local function LoadGrabGun(v)
    if not v then if btnRefs.GrabGun then btnRefs.GrabGun.btn:Destroy(); btnRefs.GrabGun=nil end; return end
    NewBtn("GrabGun",DP.GrabGun,SMALL,Color3.fromRGB(200,120,0),"GRAB\nGUN")
    btnRefs.GrabGun.btn.MouseButton1Click:Connect(DoGrabGun)
end
local function LoadWallHop(v)
    if not v then if btnRefs.WallHop then btnRefs.WallHop.btn:Destroy(); btnRefs.WallHop=nil end; return end
    NewBtn("WallHop",DP.WallHop,SMALL,Color3.fromRGB(0,210,210),"WALL\nHOP")
    btnRefs.WallHop.btn.MouseButton1Click:Connect(DoWallHop)
end
local function LoadFlingMurderer(v)
    if not v then if btnRefs.FlingMurderer then btnRefs.FlingMurderer.btn:Destroy(); btnRefs.FlingMurderer=nil end; return end
    NewBtn("FlingMurderer",DP.FlingMurderer,SMALL,Color3.fromRGB(255,50,50),"FLING\nMURD")
    btnRefs.FlingMurderer.btn.MouseButton1Click:Connect(FlingMurderer)
end
local function LoadFlingSheriff(v)
    if not v then if btnRefs.FlingSheriff then btnRefs.FlingSheriff.btn:Destroy(); btnRefs.FlingSheriff=nil end; return end
    NewBtn("FlingSheriff",DP.FlingSheriff,SMALL,Color3.fromRGB(40,130,255),"FLING\nSHERIF")
    btnRefs.FlingSheriff.btn.MouseButton1Click:Connect(FlingSheriff)
end

-- ================================================================
--  HEARTBEAT SYNC (aynen)
-- ================================================================
RunService.Heartbeat:Connect(function()
    if btnRefs.GoldBomb   then btnRefs.GoldBomb.lbl.Text  =goldCD   and "WAIT..." or "GOLD\nJUMP"   end
    if btnRefs.NormalBomb then btnRefs.NormalBomb.lbl.Text =normalCD and "WAIT..." or "NORMAL\nJUMP" end
    if btnRefs.Shoot and btnRefs.Shoot.img then
        local hk=HasKnife(player); btnRefs.Shoot.img.Image=hk and KNIFE_TEXTURE or CURSOR_TEXTURE; btnRefs.Shoot.lbl.Text=hk and "THROW" or "SHOOT"
    end
    if btnRefs.ESP then
        local c=espEnabled and Color3.fromRGB(50,220,80) or Color3.fromRGB(10,140,30)
        btnRefs.ESP.lbl.Text=espEnabled and "ESP\nON" or "ESP\nOFF"; btnRefs.ESP.lbl.TextColor3=c; btnRefs.ESP.stroke.Color=c
    end
    if btnRefs.Flick then
        local locked=UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter
        local c=flickCD and Color3.fromRGB(255,120,0) or locked and Color3.fromRGB(120,200,255) or Color3.fromRGB(180,50,255)
        btnRefs.Flick.lbl.Text=flickCD and "WAIT..." or "FLICK"; btnRefs.Flick.lbl.TextColor3=c; btnRefs.Flick.stroke.Color=c
    end
    if btnRefs.WallHop then
        local locked=UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter
        local c=wallhopCD and Color3.fromRGB(255,120,0) or locked and Color3.fromRGB(0,255,220) or Color3.fromRGB(0,210,210)
        btnRefs.WallHop.lbl.Text=wallhopCD and "WAIT..." or "WALL\nHOP"; btnRefs.WallHop.lbl.TextColor3=c; btnRefs.WallHop.stroke.Color=c
    end
    if btnRefs.Speed then
        local c=speedEnabled and Color3.fromRGB(0,220,200) or Color3.fromRGB(0,140,120)
        btnRefs.Speed.lbl.Text=speedEnabled and "SPEED\nON" or "SPEED"; btnRefs.Speed.lbl.TextColor3=c; btnRefs.Speed.stroke.Color=c
    end
    if btnRefs.Stretch then
        local c=stretchEnabled and Color3.fromRGB(255,140,30) or Color3.fromRGB(200,80,0)
        btnRefs.Stretch.lbl.Text=stretchEnabled and "STRETCH\nON" or "STRETCH"; btnRefs.Stretch.lbl.TextColor3=c; btnRefs.Stretch.stroke.Color=c
    end
    if btnRefs.GrabGun then
        local gd=FindGunDrop(); local c=gd and Color3.fromRGB(255,215,0) or Color3.fromRGB(200,100,0)
        btnRefs.GrabGun.lbl.Text=gd and "GRAB\nGUN" or "NO\nGUN"; btnRefs.GrabGun.lbl.TextColor3=c; btnRefs.GrabGun.stroke.Color=c
    end
    if btnRefs.FlingMurderer then
        local hm=false; for _,p in ipairs(Players:GetPlayers()) do if p~=player and HasKnife(p) then hm=true; break end end
        local c=flingBusy and Color3.fromRGB(255,180,0) or hm and Color3.fromRGB(255,50,50) or Color3.fromRGB(200,20,20)
        btnRefs.FlingMurderer.lbl.Text=flingBusy and "FLING..." or hm and "FLING\nMURD" or "NO\nMURD"
        btnRefs.FlingMurderer.lbl.TextColor3=c; btnRefs.FlingMurderer.stroke.Color=c
    end
    if btnRefs.FlingSheriff then
        local hs=false; for _,p in ipairs(Players:GetPlayers()) do if p~=player and HasGun(p) then hs=true; break end end
        local c=flingBusy and Color3.fromRGB(255,180,0) or hs and Color3.fromRGB(40,130,255) or Color3.fromRGB(10,80,200)
        btnRefs.FlingSheriff.lbl.Text=flingBusy and "FLING..." or hs and "FLING\nSHERIF" or "NO\nSHERIF"
        btnRefs.FlingSheriff.lbl.TextColor3=c; btnRefs.FlingSheriff.stroke.Color=c
    end
end)

-- ================================================================
--  WINDUI WINDOW (DÜZELTİLMİŞ KISIM - Section+Tab yapısı)
-- ================================================================
WindUI:Popup({
    Title="RuzHub Mmv And Mm2", Icon="sparkles",
    Content="v8.0 loaded!\nConfig auto-loaded if found.",
    Buttons={{Title="Start",Icon="arrow-right",Variant="Primary",Callback=function() end}},
})

-- Ana pencere
local Window = WindUI:CreateWindow({
    Title="RuzHub", Icon="sparkles", Author="Mmv And Mm2", Folder="RuzHub",
    Size=UDim2.fromOffset(700,550), Theme="Crimson", Acrylic=false, HideSearchBar=false,
    OpenButton={
        Title="RuzHub", CornerRadius=UDim.new(1,0), StrokeThickness=2, Enabled=true, OnlyMobile=false,
        Color=ColorSequence.new(Color3.fromHex("#dc2626"),Color3.fromHex("#991b1b")),
    },
})

-- MAIN Section + Tab
local MainSection = Window:Section({Title="🔴 Main", Opened=true})
local MainTab = MainSection:Tab({Title="Main", Icon="zap"})

-- ESP Section + Tab
local EspSection = Window:Section({Title="👁️ ESP", Opened=true})
local EspTab = EspSection:Tab({Title="ESP", Icon="eye"})

-- FARM Section + Tab
local FarmSection = Window:Section({Title="💰 Farm", Opened=true})
local FarmTab = FarmSection:Tab({Title="Farm", Icon="repeat"})

-- CROSSHAIR Section + Tab
local XhairSection = Window:Section({Title="🎯 Crosshair", Opened=true})
local XhairTab = XhairSection:Tab({Title="Crosshair", Icon="crosshair"})

-- SKY Section + Tab
local SkySection = Window:Section({Title="☁️ Sky", Opened=true})
local SkyTab = SkySection:Tab({Title="Sky", Icon="sun"})

-- OP Section + Tab
local OpSection = Window:Section({Title="⚙️ Op", Opened=true})
local OpTab = OpSection:Tab({Title="Op", Icon="shield"})

-- EXTRA Section + Tab
local ExtraSection = Window:Section({Title="✨ Extra", Opened=true})
local ExtraTab = ExtraSection:Tab({Title="Extra", Icon="package"})

-- ================================================================
--  MAIN TAB İÇERİĞİ
-- ================================================================
MainTab:Paragraph({Title="Auto-Loaded Buttons", Desc="Gold Bomb, Normal Bomb and Shoot/Throw are active by default."})
MainTab:Toggle({Title="Show Gold Bomb",   Value=true,  Callback=function(v) LoadGoldBomb(v)   end})
MainTab:Toggle({Title="Show Normal Bomb", Value=true,  Callback=function(v) LoadNormalBomb(v) end})
MainTab:Toggle({Title="Show Shoot/Throw", Value=true,  Callback=function(v) LoadShoot(v)      end})
MainTab:Divider()
MainTab:Paragraph({Title="Optional Buttons", Desc="Toggle to add or remove buttons from screen."})
MainTab:Toggle({Title="Load ESP Button",      Value=false, Callback=function(v) LoadESP(v)           end})
MainTab:Toggle({Title="Load Flick",            Value=false, Callback=function(v) LoadFlick(v)         end})
MainTab:Toggle({Title="Load Grab Gun",         Value=false, Callback=function(v) LoadGrabGun(v)       end})
MainTab:Toggle({Title="Load Speed Glitch",     Value=false, Callback=function(v) LoadSpeed(v)         end})
MainTab:Toggle({Title="Load Stretch",          Value=false, Callback=function(v) LoadStretch(v)       end})
MainTab:Toggle({Title="Load Fling Murderer",   Value=false, Callback=function(v) LoadFlingMurderer(v) end})
MainTab:Toggle({Title="Load Fling Sheriff",    Value=false, Callback=function(v) LoadFlingSheriff(v)  end})
MainTab:Toggle({Title="Load Wall Hop",         Value=false, Callback=function(v) LoadWallHop(v)       end})
MainTab:Divider()
MainTab:Paragraph({Title="Config", Desc="Save all your settings to a file and load them next time."})
MainTab:Button({Title="Save Config",  Desc="Saves all settings to RuzHub_config.json", Callback=SaveConfig})
MainTab:Button({Title="Load Config",  Desc="Loads settings from RuzHub_config.json",   Callback=function() ApplyConfig(LoadConfig()) end})

-- ================================================================
--  ESP TAB İÇERİĞİ
-- ================================================================
EspTab:Toggle({Title="Enable ESP", Value=false, Callback=function(v) SetESP(v); Notify(v and "ESP ON" or "ESP OFF") end})
EspTab:Divider()
EspTab:Toggle({Title="Show Murderer",  Value=true, Callback=function(v) espSettings.Murderer=v end})
EspTab:Toggle({Title="Show Sheriff",   Value=true, Callback=function(v) espSettings.Sheriff=v  end})
EspTab:Toggle({Title="Show Hero",      Value=true, Callback=function(v) espSettings.Hero=v     end})
EspTab:Toggle({Title="Show Innocents", Value=true, Callback=function(v) espSettings.Innocent=v end})
EspTab:Toggle({Title="Show Self",      Value=true, Callback=function(v) espSettings.Self=v     end})
EspTab:Toggle({
    Title="Dropped Gun ESP", Desc="Highlight gun on map with label and marker", Value=true,
    Callback=function(v) droppedGunEspEnabled=v; if not v then ClearGunESP(); ClearGunMarker() end; Notify(v and "Gun ESP ON" or "Gun ESP OFF") end
})
EspTab:Divider()
EspTab:ColorPicker({Title="Murderer Color", Value=Color3.fromRGB(255,40,40),  Callback=function(v) ESP_COLORS.Murderer=v end})
EspTab:ColorPicker({Title="Sheriff Color",  Value=Color3.fromRGB(40,130,255), Callback=function(v) ESP_COLORS.Sheriff=v  end})
EspTab:ColorPicker({Title="Hero Color",     Value=Color3.fromRGB(255,215,0),  Callback=function(v) ESP_COLORS.Hero=v     end})
EspTab:ColorPicker({Title="Innocent Color", Value=Color3.fromRGB(0,220,0),    Callback=function(v) ESP_COLORS.Innocent=v end})

-- ================================================================
--  FARM TAB İÇERİĞİ (Coin farm kısmı daha önce tanımlandığı için aynen)
-- ================================================================
FarmTab:Paragraph({Title="Auto Coin Farm", Desc="Automatically collects coins.\nAvoids the murderer and stays safe."})
FarmTab:Toggle({
    Title="Auto Farm Coins", Desc="Teleports to safest coin every ~1.2 seconds", Value=false,
    Callback=function(v)
        autoFarmEnabled=v
        if v then StartAutoFarm(); Notify("Auto Farm ON!") else StopAutoFarm(); Notify("Auto Farm OFF") end
    end
})
FarmTab:Toggle({
    Title="Highlight Coins", Desc="Shows gold highlight on all coins through walls", Value=false,
    Callback=function(v)
        highlightCoins=v
        if v then StartHighlightLoop(); Notify("Coin Highlight ON")
        else
            if hlConn then hlConn:Disconnect(); hlConn=nil end
            for coin,hl in pairs(coinHighlights) do pcall(function() hl:Destroy() end) end
            coinHighlights={}; Notify("Coin Highlight OFF")
        end
    end
})
FarmTab:Divider()
FarmTab:Paragraph({Title="Farm Settings", Desc="0.5s = fast  /  3.0s = slow and safe"})
FarmTab:Button({
    Title="Farm Speed Slider", Desc="Adjust how often the farm collects",
    Callback=function()
        OpenSliderPopup("Farm Interval (x10=s)",5,50,math.round(FARM_INTERVAL*10),1,
            function(v) FARM_INTERVAL=v/10; Notify("Farm interval: "..FARM_INTERVAL.."s") end,
            function() FARM_INTERVAL=1.2; Notify("Farm interval reset to 1.2s") end)
    end
})
FarmTab:Button({
    Title="Safe Distance Slider", Desc="Min studs from murderer before collecting",
    Callback=function()
        OpenSliderPopup("Safe Distance",10,80,SAFE_DISTANCE,5,
            function(v) SAFE_DISTANCE=v; Notify("Safe distance: "..v.." studs") end,
            function() SAFE_DISTANCE=30; Notify("Safe distance reset to 30") end)
    end
})
FarmTab:Divider()
FarmTab:Paragraph({Title="Bomb Farm", Desc="Jump with bombs to reach coins in high areas."})
FarmTab:Button({Title="Gold Bomb Jump",   Desc="Instant gold bomb jump",   Callback=function() if goldCD then Notify("Cooldown!") else ExecuteJump("GoldBomb",true)  end end})
FarmTab:Button({Title="Normal Bomb Jump", Desc="Instant normal bomb jump", Callback=function() if normalCD then Notify("Cooldown!") else ExecuteJump("FakeBomb",false) end end})
FarmTab:Divider()
FarmTab:Paragraph({Title="Speed Farm", Desc="Move faster across the map to reach coins quicker."})
FarmTab:Toggle({
    Title="Speed Glitch", Desc="High air speed while jumping", Value=false,
    Callback=function(v) speedEnabled=v; Notify(v and "Speed Glitch ON" or "Speed Glitch OFF") end
})
FarmTab:Button({
    Title="Speed Glitch Slider", Desc="50–600",
    Callback=function()
        OpenSliderPopup("Speed Glitch",50,600,BASE_GLITCH,10,
            function(v) BASE_GLITCH=v end,
            function() BASE_GLITCH=200; Notify("Speed reset to 200") end)
    end
})
FarmTab:Divider()
FarmTab:Paragraph({Title="Cooldowns", Desc="Gold Bomb: 4s  |  Normal Bomb: 21s"})

-- ================================================================
--  CROSSHAIR TAB İÇERİĞİ
-- ================================================================
XhairTab:Paragraph({Title="Custom Crosshair", Desc="Shown only while ShiftLock is active. Spin option is inside the picker."})
XhairTab:Toggle({
    Title="Enable Custom Crosshair", Desc="Visible only when ShiftLock is on", Value=false,
    Callback=function(v)
        crosshairActive=v
        if v then SetupCrosshairDisplay(); Notify("Crosshair ON — enable ShiftLock!")
        else
            local old=game.CoreGui:FindFirstChild("RuzCrosshairDisplay"); if old then old:Destroy(); crosshairImg=nil end
            if spinConn then spinConn:Disconnect(); spinConn=nil end
            UserInputService.MouseIconEnabled=true; Notify("Crosshair OFF")
        end
    end
})
XhairTab:Button({Title="Open Cursor Picker", Desc="Visual grid + spin toggle — click to apply", Callback=OpenCursorPicker})
XhairTab:Divider()
XhairTab:Paragraph({Title="Crosshair Size", Desc="Adjust the crosshair display size (default 42px)."})
XhairTab:Button({
    Title="Crosshair Size Slider",
    Callback=function()
        local sz=crosshairImg and crosshairImg.Size.X.Offset or 42
        OpenSliderPopup("Crosshair Size",16,96,sz,4,
            function(v) if crosshairImg then crosshairImg.Size=UDim2.new(0,v,0,v) end; Notify("Size: "..v) end,
            function() if crosshairImg then crosshairImg.Size=UDim2.new(0,42,0,42) end; Notify("Size reset to 42") end)
    end
})

-- ================================================================
--  SKY TAB İÇERİĞİ
-- ================================================================
SkyTab:Paragraph({Title="Skybox Picker", Desc="Click a preset to apply instantly. Or enter a custom texture ID."})
SkyTab:Button({Title="Open Skybox Picker", Desc="Color preview list — click to apply instantly", Callback=OpenSkyboxPicker})
SkyTab:Button({Title="Restore Default Sky", Callback=RestoreDefaultSky})
SkyTab:Divider()
SkyTab:Paragraph({Title="Lighting", Desc="Modify game lighting and visual quality."})
SkyTab:Toggle({Title="Low Graphics (FPS Boost)",  Value=false, Callback=function(v) if v then EnableLowGraphics()  else DisableLowGraphics()  end end})
SkyTab:Toggle({Title="High Graphics (Beautiful)", Value=false, Callback=function(v) if v then EnableHighGraphics() else DisableHighGraphics() end end})
SkyTab:Button({
    Title="FOV Slider", Desc="Field of view 30–120",
    Callback=function()
        OpenSliderPopup("Field of View",30,120,fovValue,5,
            function(v) fovValue=v; Camera.FieldOfView=v end,
            function() fovValue=70; Camera.FieldOfView=70; Notify("FOV reset to 70") end)
    end
})

-- ================================================================
--  OP TAB İÇERİĞİ
-- ================================================================
OpTab:Paragraph({Title="Shoot & Throw", Desc="Prediction and combat settings."})
OpTab:Toggle({Title="Auto Ping Prediction", Desc="Adds ping offset to bullet/knife travel time", Value=false,
    Callback=function(v) autoPingPred=v; Notify(v and "Ping Pred ON" or "Ping Pred OFF") end})
OpTab:Button({
    Title="Bullet Speed Slider", Desc="Higher = more accurate at range (default 250)",
    Callback=function()
        OpenSliderPopup("Bullet Speed",100,500,BULLET_SPEED,10,
            function(v) BULLET_SPEED=v end,
            function() BULLET_SPEED=250; Notify("Bullet speed reset to 250") end)
    end
})
OpTab:Button({
    Title="Knife Speed Slider", Desc="Knife travel speed (default 65)",
    Callback=function()
        OpenSliderPopup("Knife Speed",30,150,KNIFE_SPEED,5,
            function(v) KNIFE_SPEED=v end,
            function() KNIFE_SPEED=65; Notify("Knife speed reset to 65") end)
    end
})
OpTab:Divider()
OpTab:Paragraph({Title="Fling", Desc="Fling knife or gun holders off the map."})
OpTab:Button({Title="Fling Murderer", Desc="Flings the player with a knife", Callback=FlingMurderer})
OpTab:Button({Title="Fling Sheriff",  Desc="Flings the player with a gun",   Callback=FlingSheriff})
OpTab:Toggle({Title="Anti-Fling", Desc="Caps your velocity so you cannot be launched", Value=false,
    Callback=function(v) SetAntiFling(v); Notify(v and "Anti-Fling ON" or "Anti-Fling OFF") end})
OpTab:Dropdown({Title="Velocity Cap", Values={"50","100","150","200","300","500"}, Value="200",
    Callback=function(v) MAX_VELOCITY=tonumber(v) or 200 end})
OpTab:Divider()
OpTab:Paragraph({Title="Movement", Desc="Flick, Wall Hop and Stretch controls."})
OpTab:Button({Title="Flick",    Desc="180 degree instant turn",     Callback=DoSmartFlick})
OpTab:Button({Title="Wall Hop", Desc="Sideways jump for wall hopping", Callback=DoWallHop})
OpTab:Toggle({Title="Stretch Resolution", Value=false,
    Callback=function(v) stretchEnabled=v; SetStretch(v); Notify(v and "Stretch ON" or "Stretch OFF") end})
OpTab:Button({Title="Stretch Resolution Slider", Desc="10% = very wide  /  100% = normal", Callback=OpenStretchSlider})

-- ================================================================
--  EXTRA TAB İÇERİĞİ
-- ================================================================
ExtraTab:Paragraph({Title="Extra Scripts", Desc="Universal scripts and additional tools."})
ExtraTab:Button({
    Title="Load Emotes GUI", Desc="7yd7 emote panel",
    Callback=function()
        local ok,err=pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))() end)
        Notify(ok and "Emotes GUI loaded!" or "Error: "..tostring(err))
    end
})
ExtraTab:Button({
    Title="Load Infinite Yield", Desc="Admin command script",
    Callback=function()
        local ok,err=pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end)
        Notify(ok and "Infinite Yield loaded!" or "Error: "..tostring(err))
    end
})
ExtraTab:Divider()
ExtraTab:Paragraph({Title="Config", Desc="Save and load all your RuzHub settings to a file."})
ExtraTab:Button({Title="Save Config", Desc="Saves to RuzHub_config.json", Callback=SaveConfig})
ExtraTab:Button({Title="Load Config", Desc="Loads from RuzHub_config.json", Callback=function() ApplyConfig(LoadConfig()) end})
ExtraTab:Button({
    Title="Delete Config", Desc="Removes the saved config file",
    Callback=function()
        if delfile then pcall(function() delfile(CONFIG_FILE) end); Notify("Config deleted.") else Notify("delfile not supported.") end
    end
})

-- ================================================================
--  AUTO-LOAD
-- ================================================================
task.wait(0.4)
LoadGoldBomb(true); LoadNormalBomb(true); LoadShoot(true)

task.spawn(function()
    task.wait(0.8)
    local cfg=LoadConfig()
    if cfg then ApplyConfig(cfg) end
end)

Notify("RuzHub v8.0 ready!")
print("[RuzHub] v8.0 loaded.")