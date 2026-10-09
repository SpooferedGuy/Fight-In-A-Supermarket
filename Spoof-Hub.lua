local Build = loadstring(game:HttpGet("https://raw.githubusercontent.com/SpooferedGuy/UI-Library-Spoof/main/Ui-Library.lua"))()
local UI = Build({
    Title = "Spoof Hub, by SpooferedGuy",
    ScriptName = "SpoofHub - Fight In A Supermarket",
})

local CombatTab = UI.CreateTab("Combat⚔️")
local FarmTab = UI.CreateTab("Farm⚡")
local ShopTab = UI.CreateTab("Shop🛒")
local PlayerTab = UI.CreateTab("Player👤")

-- ============ SERVIÇOS ============
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- ============ AUTO HIT ============
local running = false

local function getClosestPlayer()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myRoot = char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    
    local closest, shortest = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myRoot.Position).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = hrp
                end
            end
        end
    end
    return closest
end

local function loop()
    while running do
        task.wait(0.1)
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            local remote = tool:FindFirstChild("WeaponHitEvent")
            if remote then
                local hitbox = workspace:FindFirstChild("Spawners")
                    and workspace.Spawners:FindFirstChild("HittableSpawn")
                    and workspace.Spawners.HittableSpawn:FindFirstChild("Hittable")
                    and workspace.Spawners.HittableSpawn.Hittable:FindFirstChild("Hitbox")
                
                if hitbox then
                    pcall(function() remote:FireServer(hitbox) end)
                end
                
                local closest = getClosestPlayer()
                if closest then
                    pcall(function() remote:FireServer(closest) end)
                end
            end
        end
    end
end

CombatTab.AddToggle("Kill Aura", false, function(value)
        running = value
        if value then task.spawn(loop) end
    end)

-- AIMBOT RANGE
local aimbotRange = 100

-- SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- VARIÁVEIS DINÂMICAS
local char, root, humanoid

-- CONNECTION
local aimConnection = nil
local aimbotEnabled = false

-- ATUALIZA PERSONAGEM
local function updateCharacter(character)
    char = character
    root = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end

-- INICIAL
updateCharacter(player.Character or player.CharacterAdded:Wait())

-- RESPAWN FIX
player.CharacterAdded:Connect(function(character)
    updateCharacter(character)
end)

-- GET CLOSEST TARGET
local function getClosestAimbotTarget()
    if not root then return nil end
    
    local closestPlayer = nil
    local shortestDist = aimbotRange
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player 
        and p.Character 
        and p.Character:FindFirstChild("HumanoidRootPart") 
        and p.Character:FindFirstChildOfClass("Humanoid") 
        and p.Character.Humanoid.Health > 0 then
            
            local targetHRP = p.Character.HumanoidRootPart
            local dist = (root.Position - targetHRP.Position).Magnitude
            
            if dist < shortestDist then
                closestPlayer = p
                shortestDist = dist
            end
        end
    end
    
    return closestPlayer
end

-- START
local function startAimbot()
    if aimConnection then return end

    aimConnection = RunService.Heartbeat:Connect(function()
        if not aimbotEnabled or not root then return end

        local target = getClosestAimbotTarget()
        
        if target and target.Character then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            
            if targetHrp then
                root.CFrame = CFrame.lookAt(
                    root.Position,
                    Vector3.new(targetHrp.Position.X, root.Position.Y, targetHrp.Position.Z)
                )
            end
        end
    end)
end

-- STOP
local function stopAimbot()
    if aimConnection then
        aimConnection:Disconnect()
        aimConnection = nil
    end
end

-- TOGGLE
CombatTab.AddToggle("Hit aimbot", false, function(Value)
        aimbotEnabled = Value
        
        if Value then
            startAimbot()
        else
            stopAimbot()
        end
    end)

-- ============ SERVIÇOS ============
local VirtualUser = game:GetService("VirtualUser")

-- ============ ESTADO ============
local autoClickAtivo = false
local threadClick = nil

-- ============ AUTO CLICK ============
local function iniciarAutoClick()
    if threadClick then return end
    
    threadClick = task.spawn(function()
        while autoClickAtivo do
            VirtualUser:Button1Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            VirtualUser:Button1Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
        end
        threadClick = nil
    end)
end

local function pararAutoClick()
    autoClickAtivo = false
    if threadClick then
        pcall(function() task.cancel(threadClick) end)
        threadClick = nil
    end
end

-- ============ UI ============

CombatTab.AddToggle("Auto Click", false, function(value)
        autoClickAtivo = value
        if value then
            iniciarAutoClick()
        else
            pararAutoClick()
        end
    end)

-- ============ AUTO WALK CORRIGIDO ============

local PROFUNDIDADE = 15
local TAMANHO_PLATAFORMA = 10000
local OFFSET_ALTURA = 3
local DISTANCIA_PARAR = 3
local DISTANCIA_SUBIR = 6
local VELOCIDADE_SUBIR = 0.15
local INTERVALO_CLIQUE = 0.1

-- Estado
local autoWalkMode = nil -- "money", "hittable" ou nil
local plataforma = nil
local threadAtual = nil
local threadClicks = nil
local alvoAtual = nil
local estaEmBaixo = false
local subindo = false

-- Guarda a física original de cada parte
local originalCollision = {}

-- Guarda a altura da superfície
local surfaceY = nil

-- ============ BASE ============

local function getParts()
    local char = LocalPlayer.Character
    if not char then
        return nil, nil, nil
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    return char, humanoid, root
end

local function distanciaXZ(a, b)
    local dx = a.X - b.X
    local dz = a.Z - b.Z

    return math.sqrt(dx * dx + dz * dz)
end

-- ============ PLATAFORMA ============

local function criarPlataforma(hrp)
    if plataforma and plataforma.Parent then
        return
    end

    plataforma = Instance.new("Part")
    plataforma.Name = "SpoofHub_AutoWalkPlatform"
    plataforma.Size = Vector3.new(
        TAMANHO_PLATAFORMA,
        1,
        TAMANHO_PLATAFORMA
    )

    plataforma.Anchored = true
    plataforma.CanCollide = true
    plataforma.CanTouch = false
    plataforma.CanQuery = false
    plataforma.Transparency = 1

    plataforma.CFrame = CFrame.new(
        hrp.Position.X,
        hrp.Position.Y - PROFUNDIDADE - OFFSET_ALTURA,
        hrp.Position.Z
    )

    plataforma.Parent = workspace
end

local function removerPlataforma()
    if plataforma then
        pcall(function()
            plataforma:Destroy()
        end)

        plataforma = nil
    end
end

-- ============ NOCLIP SEGURO ============

local function aplicarNoclip(char)
    if not char or not char.Parent then
        return
    end

    originalCollision = {}

    for _, parte in ipairs(char:GetDescendants()) do
        if parte:IsA("BasePart") then
            originalCollision[parte] = parte.CanCollide
            parte.CanCollide = false
        end
    end
end

local function restaurarFisica(char)
    if not char then
        originalCollision = {}
        return
    end

    for parte, valorOriginal in pairs(originalCollision) do
        if parte and parte.Parent then
            pcall(function()
                parte.CanCollide = valorOriginal
            end)
        end
    end

    originalCollision = {}
end

-- ============ BUSCAR ALVO ============

local function acharMaisProximo(nome)
    local _, _, root = getParts()

    if not root then
        return nil
    end

    local maisPerto = nil
    local menorDist = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart")
            and obj.Name == nome
            and obj.Parent then

            local dist = distanciaXZ(
                obj.Position,
                root.Position
            )

            if dist < menorDist then
                menorDist = dist
                maisPerto = obj
            end
        end
    end

    return maisPerto
end

-- ============ CLICAR ============

local function pararCliques()
    if threadClicks then
        pcall(function()
            task.cancel(threadClicks)
        end)

        threadClicks = nil
    end
end

local function iniciarCliques()
    if threadClicks then
        return
    end

    threadClicks = task.spawn(function()
        while autoWalkMode == "hittable"
            and not estaEmBaixo do

            local camera = workspace.CurrentCamera

            if camera then
                pcall(function()
                    VirtualUser:Button1Down(
                        Vector2.new(0, 0),
                        camera.CFrame
                    )

                    VirtualUser:Button1Up(
                        Vector2.new(0, 0),
                        camera.CFrame
                    )
                end)
            end

            task.wait(INTERVALO_CLIQUE)
        end

        threadClicks = nil
    end)
end

-- ============ SUBIR ============

local function subir()
    if subindo or not estaEmBaixo then
        return
    end

    subindo = true

    local _, _, hrp = getParts()

    if hrp then
        hrp.CFrame = hrp.CFrame + Vector3.new(
            0,
            PROFUNDIDADE,
            0
        )

        estaEmBaixo = false
    end

    task.wait(VELOCIDADE_SUBIR)

    subindo = false
end

-- ============ DESCER ============

local function descer()
    if subindo or estaEmBaixo then
        return
    end

    subindo = true

    local _, _, hrp = getParts()

    if hrp then
        hrp.CFrame = hrp.CFrame - Vector3.new(
            0,
            PROFUNDIDADE,
            0
        )

        estaEmBaixo = true
    end

    task.wait(VELOCIDADE_SUBIR)

    subindo = false
end

-- ============ CAMINHAR ============

local function darUmPasso(part)
    local _, humanoid, root = getParts()

    if not humanoid or not root then
        return
    end

    if humanoid.Health <= 0 then
        return
    end

    if not part or not part.Parent then
        return
    end

    local alvoPos = Vector3.new(
        part.Position.X,
        root.Position.Y,
        part.Position.Z
    )

    if distanciaXZ(root.Position, alvoPos) <= DISTANCIA_PARAR then
        humanoid:MoveTo(root.Position)
        return
    end

    humanoid:MoveTo(alvoPos)
end

-- ============ RESTAURAR SUPERFÍCIE ============

local function voltarParaSuperficie()
    local _, humanoid, hrp = getParts()

    if not hrp then
        return
    end

    -- Se estava embaixo, simplesmente volta para a altura original.
    -- Não fazemos mais outro "descender", evitando ficar preso
    -- debaixo do mapa.
    if surfaceY then
        local diferencaY = surfaceY - hrp.Position.Y

        hrp.CFrame = hrp.CFrame + Vector3.new(
            0,
            diferencaY,
            0
        )
    end

    estaEmBaixo = false

    if humanoid then
        humanoid:MoveTo(hrp.Position)
    end
end

-- ============ LIMPEZA COMPLETA ============

local function limparAutoWalk()
    -- Primeiro impede novos loops
    autoWalkMode = nil

    -- Para os cliques
    pararCliques()

    -- Cancela o loop principal
    if threadAtual then
        pcall(function()
            task.cancel(threadAtual)
        end)

        threadAtual = nil
    end

    subindo = false
    alvoAtual = nil

    -- Volta para a superfície ANTES de remover a plataforma
    voltarParaSuperficie()

    -- Restaura exatamente a física original
    local char = LocalPlayer.Character

    if char then
        restaurarFisica(char)
    else
        originalCollision = {}
    end

    -- Agora remove a plataforma
    removerPlataforma()

    surfaceY = nil
    estaEmBaixo = false
end

-- ============ LOOP PRINCIPAL ============

local function iniciarAutoWalk(nomeAlvo, modo)
    -- Garante que não exista outro Auto Walk executando
    limparAutoWalk()

    local char, humanoid, hrp = getParts()

    if not char or not humanoid or not hrp then
        return
    end

    if humanoid.Health <= 0 then
        return
    end

    autoWalkMode = modo

    -- Guarda a altura REAL antes de descer
    surfaceY = hrp.Position.Y

    alvoAtual = nil
    estaEmBaixo = false
    subindo = false

    -- Cria a plataforma antes de descer
    criarPlataforma(hrp)

    -- Salva a física original
    aplicarNoclip(char)

    -- Desce
    hrp.CFrame = hrp.CFrame - Vector3.new(
        0,
        PROFUNDIDADE,
        0
    )

    estaEmBaixo = true

    threadAtual = task.spawn(function()
        while autoWalkMode == modo do
            task.wait(0.15)

            -- Verifica se o personagem ainda existe
            local currentChar, currentHumanoid, currentRoot = getParts()

            if not currentChar
                or not currentHumanoid
                or not currentRoot
                or currentHumanoid.Health <= 0 then

                break
            end

            -- Procura alvo
            if alvoAtual and not alvoAtual.Parent then
                alvoAtual = nil
            end

            local novoAlvo = acharMaisProximo(nomeAlvo)

            if novoAlvo then
                if not alvoAtual then
                    alvoAtual = novoAlvo
                else
                    local distAtual = distanciaXZ(
                        alvoAtual.Position,
                        currentRoot.Position
                    )

                    local distNovo = distanciaXZ(
                        novoAlvo.Position,
                        currentRoot.Position
                    )

                    if distNovo < distAtual then
                        alvoAtual = novoAlvo
                    end
                end
            end

            -- Sem alvo
            if not alvoAtual or not alvoAtual.Parent then
                if modo == "hittable" and not estaEmBaixo then
                    pararCliques()
                    descer()
                end

                continue
            end

            local dist = distanciaXZ(
                alvoAtual.Position,
                currentRoot.Position
            )

            -- =========================
            -- AUTO ATM / Hittable
            -- =========================
            if modo == "hittable" then

                if dist <= DISTANCIA_SUBIR then
                    -- Chegou perto
                    if estaEmBaixo then
                        subir()
                    end

                    iniciarCliques()

                    currentHumanoid:MoveTo(
                        currentRoot.Position
                    )

                else
                    -- Está longe
                    pararCliques()

                    if not estaEmBaixo then
                        descer()
                    end

                    darUmPasso(alvoAtual)
                end

            -- =========================
            -- AUTO MONEY
            -- =========================
            elseif modo == "money" then

                darUmPasso(alvoAtual)

                if dist <= DISTANCIA_PARAR then
                    alvoAtual = nil
                end
            end
        end

        -- Se o loop terminou por algum motivo,
        -- só limpa se ainda for o mesmo modo.
        if autoWalkMode == modo then
            limparAutoWalk()
        end
    end)
end

-- ============ UI ============

FarmTab.AddSection("Auto Walk")

FarmTab.AddToggle("Auto Money", false, function(value)
        if value then
            -- Desliga completamente o outro modo
            limparAutoWalk()

            iniciarAutoWalk(
                "MoneyHitbox",
                "money"
            )
        else
            -- Só limpa se Auto Money estiver ativo
            if autoWalkMode == "money" then
                limparAutoWalk()
            end
        end
    end)

FarmTab.AddToggle("Auto ATM", false, function(value)
        if value then
            -- Desliga completamente o outro modo
            limparAutoWalk()

            iniciarAutoWalk(
                "HittableHit",
                "hittable"
            )
        else
            -- Só limpa se Auto ATM estiver ativo
            if autoWalkMode == "hittable" then
                limparAutoWalk()
            end
        end
    end)

-- ============ COMBAT ESP HIGHLIGHT ============

local CombatESPEnabled = false

local CombatESPFolder = Instance.new("Folder")
CombatESPFolder.Name = "SpoofHub_CombatESP"
CombatESPFolder.Parent = game.CoreGui

local function removeCharacterESP(character)
    if not character then
        return
    end

    local highlight = character:FindFirstChild("SpoofHub_CombatHighlight")

    if highlight then
        pcall(function()
            highlight:Destroy()
        end)
    end
end

local function removeCombatESP()
    -- Remove highlights dos personagens
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            removeCharacterESP(player.Character)
        end
    end

    -- Limpa também qualquer objeto restante na pasta
    for _, obj in ipairs(CombatESPFolder:GetChildren()) do
        pcall(function()
            obj:Destroy()
        end)
    end
end

local function addCombatESP(character)
    if not CombatESPEnabled then
        return
    end

    if not character or not character.Parent then
        return
    end

    if character == LocalPlayer.Character then
        return
    end

    if not character:FindFirstChildOfClass("Humanoid") then
        return
    end

    -- Evita duplicados
    if character:FindFirstChild("SpoofHub_CombatHighlight") then
        return
    end

    pcall(function()
        local highlight = Instance.new("Highlight")

        highlight.Name = "SpoofHub_CombatHighlight"
        highlight.Adornee = character

        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)

        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0

        highlight.Parent = character
    end)
end

local function updateCombatESP()
    if not CombatESPEnabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            addCombatESP(player.Character)
        end
    end
end

local function setupPlayer(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function(character)
        -- Espera o personagem carregar
        task.wait(0.3)

        if CombatESPEnabled then
            addCombatESP(character)
        end
    end)
end

-- Toggle
CombatTab.AddToggle("ESP Highlight", false, function(Value)
    CombatESPEnabled = Value

    if Value then
        updateCombatESP()
    else
        removeCombatESP()
    end
end)

-- Jogadores que já estão no servidor
for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

-- Jogadores que entrarem depois
Players.PlayerAdded:Connect(function(player)
    setupPlayer(player)

    -- Caso o personagem já esteja disponível
    if CombatESPEnabled and player.Character then
        task.wait(0.3)
        addCombatESP(player.Character)
    end
end)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local BlueESPEnabled = false
local YellowESPEnabled = false
local HighestESPEnabled = false

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ShopESP"
ESPFolder.Parent = Workspace

--------------------------------------------------
-- AVISO NO TOPO DA TELA
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HighestPriceNotification"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Notification = Instance.new("TextLabel")
Notification.Name = "HighestPrice"
Notification.AnchorPoint = Vector2.new(0.5, 0)
Notification.Position = UDim2.new(0.5, 0, 0, 0)
Notification.Size = UDim2.fromOffset(300, 45)
Notification.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Notification.BackgroundTransparency = 0.15
Notification.BorderSizePixel = 0
Notification.TextColor3 = Color3.fromRGB(255, 60, 60)
Notification.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Notification.TextStrokeTransparency = 0
Notification.Font = Enum.Font.GothamBold
Notification.TextSize = 30
Notification.Text = ""
Notification.Visible = false
Notification.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Notification

--------------------------------------------------
-- CORES
--------------------------------------------------

local function isBlue(color)
	return color.B > color.R * 1.5
		and color.B > color.G * 0.95
end

local function isYellow(color)
	return color.R > color.B * 1.5
		and color.G > color.B * 1.5
		and color.R > 0.5
		and color.G > 0.5
end

--------------------------------------------------
-- PEGAR PREÇO
--------------------------------------------------

local function getPrice(text)
	local price = text:match("%$%s*([%d%.,]+)")

	if not price then
		return nil
	end

	price = price:gsub(",", "")

	return tonumber(price)
end

--------------------------------------------------
-- ESP NORMAL
--------------------------------------------------

local function createESP(label, color, category, index)

	if not label:IsA("TextLabel") then
		return
	end

	if label:FindFirstAncestor("ShopESP") then
		return
	end

	if not string.find(label.Text, "$", 1, true) then
		return
	end

	local part = label:FindFirstAncestorWhichIsA("BasePart")

	if not part then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = category .. "_" .. index
	billboard.Adornee = part
	billboard.Size = UDim2.fromOffset(40, 40)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 300
	billboard.Parent = ESPFolder

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label.Text
	text.TextColor3 = color
	text.Font = label.Font
	text.TextSize = 20
	text.TextScaled = false
	text.TextStrokeColor3 = label.TextStrokeColor3
	text.TextStrokeTransparency = label.TextStrokeTransparency
	text.Parent = billboard
end

--------------------------------------------------
-- ESP DO MAIOR PREÇO
--------------------------------------------------

local function createHighestESP(label, part)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HighestPriceESP"
	billboard.Adornee = part
	billboard.Size = UDim2.fromOffset(400, 100)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1000
	billboard.Parent = ESPFolder

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = label.Text
	text.TextColor3 = Color3.fromRGB(255, 0, 0)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 50
	text.TextStrokeColor3 = Color3.new(0, 0, 0)
	text.TextStrokeTransparency = 0
	text.Parent = billboard
end

--------------------------------------------------
-- ATUALIZA TEXTO DO TOPO
--------------------------------------------------

local function showHighestPrice(text)

	Notification.Text = "highest price: " .. text
	Notification.Visible = true

end

local function hideHighestPrice()

	Notification.Text = ""
	Notification.Visible = false

end

--------------------------------------------------
-- LIMPAR
--------------------------------------------------

local function clearESP()
	ESPFolder:ClearAllChildren()
end

--------------------------------------------------
-- ATUALIZAR
--------------------------------------------------

local function updateESP()

	clearESP()

	local index = 0

	local highestPrice = -math.huge
	local highestLabel = nil
	local highestPart = nil

	for _, object in ipairs(Workspace:GetDescendants()) do

		if object:IsA("TextLabel")
			and not object:FindFirstAncestor("ShopESP") then

			local price = getPrice(object.Text)

			if price then

				local part =
					object:FindFirstAncestorWhichIsA("BasePart")

				if part and price > highestPrice then

					highestPrice = price
					highestLabel = object
					highestPart = part

				end

				if BlueESPEnabled
					and isBlue(object.TextColor3) then

					index += 1

					createESP(
						object,
						object.TextColor3,
						"Blue",
						index
					)

				end

				if YellowESPEnabled
					and isYellow(object.TextColor3) then

					index += 1

					createESP(
						object,
						object.TextColor3,
						"Yellow",
						index
					)

				end

			end
		end
	end

	--------------------------------------------------
	-- MAIOR PREÇO
	--------------------------------------------------

	if HighestESPEnabled
		and highestLabel
		and highestPart then

		createHighestESP(
			highestLabel,
			highestPart
		)

		showHighestPrice(highestLabel.Text)

	else
		hideHighestPrice()
	end
end

--------------------------------------------------
-- ATUALIZA A CADA 5 SEGUNDOS
--------------------------------------------------

task.spawn(function()

	while true do

		task.wait(5)

		if BlueESPEnabled
			or YellowESPEnabled
			or HighestESPEnabled then

			updateESP()

		end

	end

end)

--------------------------------------------------
-- RAYFIELD
--------------------------------------------------

ShopTab.AddToggle("ESP Blue", false, function(Value)

		BlueESPEnabled = Value
		updateESP()
    end)

ShopTab.AddToggle("ESP Yellow", false, function(Value)

		YellowESPEnabled = Value
		updateESP()
    end)

ShopTab.AddToggle("ESP Highest Price", false, function(Value)

		HighestESPEnabled = Value
		updateESP()
end)

-- ================= NoClip =================
local noclipEnabled = false
local originalCollision = {}

PlayerTab.AddToggle("NoClip", false, function(Value)
        noclipEnabled = Value

        local character = LocalPlayer.Character
        if not character then
            return
        end

        if Value then
            -- Guarda o estado original
            originalCollision = {}

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    originalCollision[part] = part.CanCollide
                    part.CanCollide = false
                end
            end

        else
            -- Restaura exatamente como estava antes
            for part, originalValue in pairs(originalCollision) do
                if part and part.Parent then
                    part.CanCollide = originalValue
                end
            end

            originalCollision = {}
        end
    end)

RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--// VARS
local flying = false
local flySpeed = 16
local bodyVelocity
local bodyGyro
local connection

--// PEGAR CONTROL MODULE
local function getControlModule()
    local ok, module = pcall(function()
        return require(
            player:WaitForChild("PlayerScripts")
                :WaitForChild("PlayerModule")
                :WaitForChild("ControlModule")
        )
    end)

    return ok and module or nil
end

local controlModule = getControlModule()

--// PEGAR ROOT
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

--// PARAR FLY
local function stopFly()
    flying = false

    if connection then
        connection:Disconnect()
        connection = nil
    end

    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end

    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
end

--// INICIAR FLY
local function startFly()
    local root = getRoot()

    stopFly()

    flying = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.P = 10000
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    connection = RunService.Heartbeat:Connect(function()
        if not flying or not bodyVelocity or not bodyGyro then
            return
        end

        if not root.Parent then
            stopFly()
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then
            return
        end

        local moveVec = Vector3.zero

        if controlModule then
            moveVec = controlModule:GetMoveVector()
        end

        local velocity = Vector3.zero

        if moveVec.Magnitude > 0 then
            local direction = camera.CFrame:VectorToWorldSpace(moveVec)

            if direction.Magnitude > 0 then
                velocity = direction.Unit * flySpeed
            end
        end

        bodyVelocity.Velocity = velocity
        bodyGyro.CFrame = camera.CFrame
    end)
end

--// TOGGLE
local function toggleFly(state)
    if state then
        startFly()
    else
        stopFly()
    end
end

--// BOTÃO NO PLAYERTAB
PlayerTab.AddToggle("Fly", false, function(Value)
        toggleFly(Value)
    end)

--// MORTE / RESPAWN
player.CharacterAdded:Connect(function()
    stopFly()
end)