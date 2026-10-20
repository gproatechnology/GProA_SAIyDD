--!strict
-- Generador Procedural del Mundo 3D de Actividades para SaIyDD (Roblox Studio)
-- Ubicación: ServerScriptService.Server.WorldBuilder (sincronizado por Rojo)
-- Construye una arena 3D interactiva en Workspace donde el avatar del niño camina,
-- explora y pisa plataformas de colores/respuestas para resolver desafíos pedagógicos.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

print("==============================================================")
print("[SaIyDD][3D] Iniciando Generador de Arena 3D en Workspace...")
print("==============================================================")

-- Limpiar arena anterior si existe (hot-reload seguro con Rojo)
local existingArena = Workspace:FindFirstChild("SaIyDD_Arena")
if existingArena then
	existingArena:Destroy()
end

local arenaModel = Instance.new("Model")
arenaModel.Name = "SaIyDD_Arena"
arenaModel.Parent = Workspace

-- ---------------------------------------------------------------------
-- Plantilla de Actividad 3D activa (Colores del arcoíris 🎨)
-- ---------------------------------------------------------------------
local ACTIVITY_ID = "act_002"
local TEST_CHILD_ID = "child_TEST_001"

local QUESTIONS = {
	{
		prompt = "¿Dónde está el color ROJO? 🔴",
		hint = "¡Camina hacia la plataforma de color rojo!",
		correctPad = 1, -- Rojo
	},
	{
		prompt = "¿Dónde está el color AZUL? 🔵",
		hint = "¡Busca el color del cielo y del mar!",
		correctPad = 3, -- Azul
	},
	{
		prompt = "¿Dónde está el color VERDE? 🟢",
		hint = "¡Es el color de las hojas y el bosque!",
		correctPad = 2, -- Verde
	},
	{
		prompt = "¿Dónde está el color AMARILLO? 🟡",
		hint = "¡Brilla como el sol de la mañana!",
		correctPad = 4, -- Amarillo
	},
}

local PAD_DEFS = {
	{ id = 1, name = "Pad_Rojo", label = "🔴 ROJO", color = Color3.fromRGB(240, 65, 65), pos = Vector3.new(-18, 0.5, -4) },
	{ id = 2, name = "Pad_Verde", label = "🟢 VERDE", color = Color3.fromRGB(46, 204, 113), pos = Vector3.new(-6, 0.5, -4) },
	{ id = 3, name = "Pad_Azul", label = "🔵 AZUL", color = Color3.fromRGB(52, 152, 219), pos = Vector3.new(6, 0.5, -4) },
	{ id = 4, name = "Pad_Amarillo", label = "🟡 AMARILLO", color = Color3.fromRGB(245, 205, 30), pos = Vector3.new(18, 0.5, -4) },
}

-- ---------------------------------------------------------------------
-- 1. Suelo Principal y Límites de Seguridad
-- ---------------------------------------------------------------------
local floor = Instance.new("Part")
floor.Name = "ArenaFloor"
floor.Size = Vector3.new(80, 2, 80)
floor.Position = Vector3.new(0, -1, 0)
floor.Anchored = true
floor.Material = Enum.Material.SmoothPlastic
floor.Color = Color3.fromRGB(235, 245, 240) -- Verde pastel relajante
floor.TopSurface = Enum.SurfaceType.Smooth
floor.Parent = arenaModel

-- Vallas de contención perimetral (seguras para niños, evitan caídas)
local function createPerimeterFence(size: Vector3, pos: Vector3)
	local fence = Instance.new("Part")
	fence.Name = "SafetyFence"
	fence.Size = size
	fence.Position = pos
	fence.Anchored = true
	fence.Material = Enum.Material.Glass
	fence.Transparency = 0.5
	fence.Color = Color3.fromRGB(180, 210, 230)
	fence.Parent = arenaModel

	-- Borde superior luminoso
	local trim = Instance.new("Part")
	trim.Name = "FenceTrim"
	trim.Size = Vector3.new(size.X, 0.6, size.Z)
	trim.Position = pos + Vector3.new(0, size.Y / 2 + 0.3, 0)
	trim.Anchored = true
	trim.Material = Enum.Material.Neon
	trim.Color = Color3.fromRGB(120, 190, 240)
	trim.Parent = arenaModel
end

createPerimeterFence(Vector3.new(80, 6, 1), Vector3.new(0, 2, 40))   -- Sur
createPerimeterFence(Vector3.new(80, 6, 1), Vector3.new(0, 2, -40))  -- Norte
createPerimeterFence(Vector3.new(1, 6, 80), Vector3.new(-40, 2, 0))  -- Oeste
createPerimeterFence(Vector3.new(1, 6, 80), Vector3.new(40, 2, 0))   -- Este

-- Spawn seguro frente al área de juego
local spawnPoint = Instance.new("SpawnLocation")
spawnPoint.Name = "SaIyDDSpawn"
spawnPoint.Size = Vector3.new(8, 0.5, 8)
spawnPoint.Position = Vector3.new(0, 0.25, 22)
spawnPoint.Anchored = true
spawnPoint.Neutral = true
spawnPoint.Duration = 0
spawnPoint.Material = Enum.Material.SmoothPlastic
spawnPoint.Color = Color3.fromRGB(160, 210, 255)
spawnPoint.TopSurface = Enum.SurfaceType.Smooth
spawnPoint.Parent = arenaModel

local spawnDecal = spawnPoint:FindFirstChildOfClass("Decal")
if spawnDecal then spawnDecal:Destroy() end

local spawnGui = Instance.new("SurfaceGui")
spawnGui.Face = Enum.NormalId.Top
spawnGui.Parent = spawnPoint

local spawnLabel = Instance.new("TextLabel")
spawnLabel.Size = UDim2.new(1, 0, 1, 0)
spawnLabel.BackgroundTransparency = 1
spawnLabel.Text = "⭐ ZONA DE INICIO"
spawnLabel.TextColor3 = Color3.fromRGB(40, 70, 120)
spawnLabel.Font = Enum.Font.GothamBold
spawnLabel.TextSize = 22
spawnLabel.Parent = spawnGui

-- ---------------------------------------------------------------------
-- 2. Cartel Gigante de Preguntas 3D (Billboard en Workspace)
-- ---------------------------------------------------------------------
local boardBacking = Instance.new("Part")
boardBacking.Name = "QuestionBoard"
boardBacking.Size = Vector3.new(38, 16, 2)
boardBacking.Position = Vector3.new(0, 14, -24)
boardBacking.Anchored = true
boardBacking.Material = Enum.Material.Metal
boardBacking.Color = Color3.fromRGB(32, 38, 54)
boardBacking.Parent = arenaModel

-- Luces de borde en el cartel
local boardLight = Instance.new("PointLight")
boardLight.Color = Color3.fromRGB(150, 200, 255)
boardLight.Range = 25
boardLight.Brightness = 1.5
boardLight.Parent = boardBacking

local boardGui = Instance.new("SurfaceGui")
boardGui.Name = "BoardGui"
boardGui.Face = Enum.NormalId.Front
boardGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
boardGui.PixelsPerStud = 30
boardGui.Parent = boardBacking

local boardContainer = Instance.new("Frame")
boardContainer.Size = UDim2.new(1, 0, 1, 0)
boardContainer.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
boardContainer.BorderSizePixel = 0
boardContainer.Parent = boardGui

local boardHeader = Instance.new("TextLabel")
boardHeader.Size = UDim2.new(1, 0, 0, 70)
boardHeader.BackgroundColor3 = Color3.fromRGB(40, 50, 75)
boardHeader.BorderSizePixel = 0
boardHeader.Text = "⭐ SaIyDD — ACTIVIDAD INTERACTIVA 3D ⭐"
boardHeader.TextColor3 = Color3.fromRGB(255, 235, 120)
boardHeader.Font = Enum.Font.GothamBold
boardHeader.TextSize = 34
boardHeader.Parent = boardContainer

local boardMascot = Instance.new("TextLabel")
boardMascot.Name = "BoardMascot"
boardMascot.Size = UDim2.new(1, -40, 0, 50)
boardMascot.Position = UDim2.new(0, 20, 0, 85)
boardMascot.BackgroundTransparency = 1
boardMascot.Text = "🤖 Niko: ¡Usa tu avatar para pisar la plataforma correcta!"
boardMascot.TextColor3 = Color3.fromRGB(180, 220, 255)
boardMascot.Font = Enum.Font.GothamMedium
boardMascot.TextSize = 26
boardMascot.TextXAlignment = Enum.TextXAlignment.Center
boardMascot.Parent = boardContainer

local boardPrompt = Instance.new("TextLabel")
boardPrompt.Name = "BoardPrompt"
boardPrompt.Size = UDim2.new(1, -60, 0, 140)
boardPrompt.Position = UDim2.new(0, 30, 0, 145)
boardPrompt.BackgroundColor3 = Color3.fromRGB(42, 52, 78)
boardPrompt.BorderSizePixel = 0
boardPrompt.Text = "Cargando..."
boardPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
boardPrompt.Font = Enum.Font.GothamBold
boardPrompt.TextSize = 42
boardPrompt.TextWrapped = true
boardPrompt.Parent = boardContainer

local promptCorner = Instance.new("UICorner")
promptCorner.CornerRadius = UDim.new(0, 18)
promptCorner.Parent = boardPrompt

local boardFeedback = Instance.new("TextLabel")
boardFeedback.Name = "BoardFeedback"
boardFeedback.Size = UDim2.new(1, -60, 0, 65)
boardFeedback.Position = UDim2.new(0, 30, 0, 300)
boardFeedback.BackgroundColor3 = Color3.fromRGB(35, 42, 60)
boardFeedback.BorderSizePixel = 0
boardFeedback.Text = "Camina hacia la plataforma de color y písala con tu avatar 👇"
boardFeedback.TextColor3 = Color3.fromRGB(220, 240, 255)
boardFeedback.Font = Enum.Font.GothamBold
boardFeedback.TextSize = 28
boardFeedback.Parent = boardContainer

local fbCorner = Instance.new("UICorner")
fbCorner.CornerRadius = UDim.new(0, 14)
fbCorner.Parent = boardFeedback

local boardProgress = Instance.new("TextLabel")
boardProgress.Name = "BoardProgress"
boardProgress.Size = UDim2.new(1, 0, 0, 40)
boardProgress.Position = UDim2.new(0, 0, 1, -55)
boardProgress.BackgroundTransparency = 1
boardProgress.Text = "Desafío 1 de 4  •  Puntaje: 0 pts"
boardProgress.TextColor3 = Color3.fromRGB(150, 180, 220)
boardProgress.Font = Enum.Font.Gotham
boardProgress.TextSize = 22
boardProgress.Parent = boardContainer

-- ---------------------------------------------------------------------
-- 3. Cuatro Plataformas 3D Interactivas que Detectan al Avatar
-- ---------------------------------------------------------------------
local currentQuestionIndex = 1
local currentScore = 0
local activityStartTime = os.clock()
local questionStartTime = os.clock()
local interactions = {}
local isLocked = false

local padInstances: {[number]: Part} = {}

local function updateBoard()
	local q = QUESTIONS[currentQuestionIndex]
	boardPrompt.Text = q.prompt
	boardMascot.Text = "🤖 Niko: " .. q.hint
	boardFeedback.Text = "Pisa con tu avatar la plataforma correcta 👇"
	boardFeedback.BackgroundColor3 = Color3.fromRGB(35, 42, 60)
	boardProgress.Text = string.format("Desafío %d de %d  •  Puntaje: %d pts", currentQuestionIndex, #QUESTIONS, currentScore)
end

-- Función para celebrar y registrar sesión en el Backend
local function completeActivity()
	isLocked = true
	local duration = math.max(1, math.floor(os.clock() - activityStartTime))
	boardPrompt.Text = "🎉 ¡FELICIDADES! ¡ACTIVIDAD COMPLETADA! 🎉"
	boardPrompt.TextColor3 = Color3.fromRGB(255, 230, 100)
	boardMascot.Text = "🤖 Niko: ¡Increíble! ¡Lograste responder todos los desafíos con tu avatar!"
	boardFeedback.Text = "📡 Guardando sesión en el backend SaIyDD (FastAPI)..."
	boardFeedback.BackgroundColor3 = Color3.fromRGB(46, 204, 113)

	task.spawn(function()
		print(string.format("[SaIyDD][3D] Guardando sesión desde el mundo 3D: niño=%s, pts=%d, t=%ds", TEST_CHILD_ID, currentScore, duration))
		local recordFunc = script.Parent:FindFirstChild("RecordSessionInternal") :: BindableFunction?
		if recordFunc then
			local reply = recordFunc:Invoke({
				childId = TEST_CHILD_ID,
				activityId = ACTIVITY_ID,
				score = currentScore,
				durationSeconds = duration,
				interactions = interactions,
			})
			if reply and reply.ok then
				local sid = (reply.data and reply.data.id) or "ok"
				boardFeedback.Text = string.format("✅ ¡Guardado en la base de datos! (ID: %s)", tostring(sid))
			else
				local err = (reply and reply.error and reply.error.message) or "error"
				boardFeedback.Text = string.format("⚠️ Error al registrar sesión: %s", err)
			end
		else
			warn("[SaIyDD][3D] No se encontró RecordSessionInternal en ServerScriptService.")
		end

		task.wait(6)
		-- Reiniciar ciclo para seguir jugando
		currentQuestionIndex = 1
		currentScore = 0
		interactions = {}
		activityStartTime = os.clock()
		isLocked = false
		updateBoard()
	end)
end

-- Crear cada plataforma interactiva
for _, pdef in ipairs(PAD_DEFS) do
	local pad = Instance.new("Part")
	pad.Name = pdef.name
	pad.Size = Vector3.new(10, 1, 10)
	pad.Position = pdef.pos
	pad.Anchored = true
	pad.Material = Enum.Material.Neon
	pad.Transparency = 0.2
	pad.Color = pdef.color
	pad.TopSurface = Enum.SurfaceType.Smooth
	pad.Parent = arenaModel
	padInstances[pdef.id] = pad

	-- Luz propia que ilumina el área de la plataforma
	local light = Instance.new("PointLight")
	light.Color = pdef.color
	light.Range = 16
	light.Brightness = 2
	light.Parent = pad

	-- Partículas de estrellas (se disparan al pisar)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "StarsEmitter"
	emitter.Rate = 0
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(45, 45)
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 240, 100))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Parent = pad

	-- Sonido nativo de paso
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/button.wav"
	sound.Volume = 0.5
	sound.Parent = pad

	-- Texto 3D superior sobre la plataforma
	local padGui = Instance.new("SurfaceGui")
	padGui.Face = Enum.NormalId.Top
	padGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	padGui.PixelsPerStud = 25
	padGui.Parent = pad

	local padLabel = Instance.new("TextLabel")
	padLabel.Size = UDim2.new(1, 0, 1, 0)
	padLabel.BackgroundTransparency = 1
	padLabel.Text = pdef.label
	padLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	padLabel.Font = Enum.Font.GothamBold
	padLabel.TextSize = 42
	padLabel.Parent = padGui

	-- Detector de toque del avatar (Touched)
	local touchDebounce = false
	pad.Touched:Connect(function(hit)
		if isLocked or touchDebounce then return end
		local char = hit.Parent
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local plr = char and Players:GetPlayerFromCharacter(char)
		if not humanoid or not plr or humanoid.Health <= 0 then return end

		touchDebounce = true
		task.delay(0.9, function() touchDebounce = false end)

		-- Efecto físico: la plataforma se hunde un poquito y rebota
		sound.PlaybackSpeed = 1.0 + (pdef.id * 0.1)
		pcall(function() sound:Play() end)
		emitter:Emit(25)

		local originalPos = pdef.pos
		TweenService:Create(pad, TweenInfo.new(0.12), { Position = originalPos - Vector3.new(0, 0.4, 0) }):Play()
		task.delay(0.2, function()
			TweenService:Create(pad, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Position = originalPos }):Play()
		end)

		-- Evaluar respuesta pedagógica
		local q = QUESTIONS[currentQuestionIndex]
		local isCorrect = (pdef.id == q.correctPad)
		local elapsedMs = math.floor((os.clock() - questionStartTime) * 1000)

		table.insert(interactions, {
			promptIndex = currentQuestionIndex - 1,
			selectedIndex = pdef.id - 1,
			correct = isCorrect,
			responseTimeMs = elapsedMs,
		})

		if isCorrect then
			currentScore += 25
			boardFeedback.Text = string.format("🎉 ¡EXCELENTE! ¡Pisaste la plataforma correcta: %s! (+25 pts)", pdef.label)
			boardFeedback.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			boardMascot.Text = "🤖 Niko: ¡Qué bien lo hiciste! ¡Avanzamos al siguiente color!"

			task.wait(1.4)
			if currentQuestionIndex < #QUESTIONS then
				currentQuestionIndex += 1
				questionStartTime = os.clock()
				updateBoard()
			else
				completeActivity()
			end
		else
			boardFeedback.Text = string.format("¡Casi! Pisaste %s, pero buscamos otro color. ¡Inténtalo de nuevo! 💪", pdef.label)
			boardFeedback.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
			boardMascot.Text = "🤖 Niko: ¡No pasa nada! Camina hacia otra plataforma."
		end
	end)
end

-- Inicializar Cartel 3D
updateBoard()

print("[SaIyDD][3D] ¡Arena 3D construida exitosamente en Workspace con 4 plataformas táctiles!")
print("[SaIyDD][3D] El avatar del jugador puede caminar y pisar las plataformas interactivas.")
