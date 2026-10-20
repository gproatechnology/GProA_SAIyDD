--!strict
-- Controller de Interfaz de Actividades para SAIyDD (Roblox Studio)
-- Sincronizado por Rojo en StarterGui.ActivityGui.Controller
-- Ofrece una experiencia interactiva accesible para niños de 4 a 8 años
-- conectada directamente con el bridge cliente (Client.recordSession).

print("==============================================================")
print("[SaIyDD][UI] Iniciando Interfaz Interactiva de Actividades SaIyDD...")
print("==============================================================")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
	warn("[SaIyDD][UI] [FAIL] No se encontró PlayerGui en el jugador.")
	return
end

-- Crear o reutilizar ScreenGui en PlayerGui con prioridad de visualización
local existingGui = playerGui:FindFirstChild("SaIyDDActivityGui")
local screenGui: ScreenGui
if existingGui and existingGui:IsA("ScreenGui") then
	existingGui:ClearAllChildren()
	screenGui = existingGui
else
	local newGui = Instance.new("ScreenGui")
	newGui.Name = "SaIyDDActivityGui"
	newGui.ResetOnSpawn = false
	newGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	newGui.DisplayOrder = 10
	newGui.Parent = playerGui
	screenGui = newGui
end

-- ---------------------------------------------------------------------
-- Importar Bridge del Cliente
-- ---------------------------------------------------------------------
local clientFolder = script.Parent:WaitForChild("Client", 10)
if not clientFolder then
	local pScripts = player:FindFirstChild("PlayerScripts")
	clientFolder = pScripts and pScripts:WaitForChild("Client", 10)
end

if not clientFolder then
	warn("[SaIyDD][UI] [FAIL] No se encontró la carpeta Client tras 10s.")
	return
end

local mainModule = clientFolder:WaitForChild("main", 10)
if not mainModule or not mainModule:IsA("ModuleScript") then
	warn("[SaIyDD][UI] [FAIL] No se encontró ModuleScript Client.main.")
	return
end

local Client = require(mainModule :: ModuleScript)
print("[SaIyDD][UI] Bridge Client.main conectado exitosamente.")

-- ---------------------------------------------------------------------
-- Catálogo de Actividades Pedagógicas
-- ---------------------------------------------------------------------
local ACTIVITIES = {
	{
		id = "act_002",
		title = "Colores del arcoíris 🎨",
		category = "Sensorial / Visual",
		questions = {
			{
				prompt = "¿Dónde está el color ROJO? 🔴",
				mascotHint = "¡Busca el color como una rica manzana!",
				options = {
					{ text = "Rojo 🔴", color = Color3.fromRGB(235, 75, 75), isCorrect = true },
					{ text = "Verde 🟢", color = Color3.fromRGB(46, 204, 113), isCorrect = false },
					{ text = "Azul 🔵", color = Color3.fromRGB(52, 152, 219), isCorrect = false },
					{ text = "Amarillo 🟡", color = Color3.fromRGB(241, 196, 15), isCorrect = false },
				},
			},
			{
				prompt = "¿Dónde está el color AZUL? 🔵",
				mascotHint = "¡Es el color del mar y del cielo!",
				options = {
					{ text = "Amarillo 🟡", color = Color3.fromRGB(241, 196, 15), isCorrect = false },
					{ text = "Rojo 🔴", color = Color3.fromRGB(235, 75, 75), isCorrect = false },
					{ text = "Azul 🔵", color = Color3.fromRGB(52, 152, 219), isCorrect = true },
					{ text = "Verde 🟢", color = Color3.fromRGB(46, 204, 113), isCorrect = false },
				},
			},
			{
				prompt = "¿Dónde está el color VERDE? 🟢",
				mascotHint = "¡Como las hojitas de los árboles!",
				options = {
					{ text = "Azul 🔵", color = Color3.fromRGB(52, 152, 219), isCorrect = false },
					{ text = "Verde 🟢", color = Color3.fromRGB(46, 204, 113), isCorrect = true },
					{ text = "Rojo 🔴", color = Color3.fromRGB(235, 75, 75), isCorrect = false },
					{ text = "Amarillo 🟡", color = Color3.fromRGB(241, 196, 15), isCorrect = false },
				},
			},
		},
	},
	{
		id = "act_001",
		title = "Sonidos de la granja 🐮",
		category = "Auditiva / Naturaleza",
		questions = {
			{
				prompt = "¿Qué animal hace '¡Muuu!'? 🐮",
				mascotHint = "Nos da leche fresca en las mañanas.",
				options = {
					{ text = "La Vaca 🐮", color = Color3.fromRGB(155, 89, 182), isCorrect = true },
					{ text = "El Cerdito 🐷", color = Color3.fromRGB(230, 126, 34), isCorrect = false },
					{ text = "La Oveja 🐑", color = Color3.fromRGB(52, 152, 219), isCorrect = false },
					{ text = "El Pollito 🐥", color = Color3.fromRGB(241, 196, 15), isCorrect = false },
				},
			},
			{
				prompt = "¿Qué animal hace '¡Oink oink!'? 🐷",
				mascotHint = "Le gusta el lodo y es rosadito.",
				options = {
					{ text = "El Caballo 🐴", color = Color3.fromRGB(155, 89, 182), isCorrect = false },
					{ text = "El Cerdito 🐷", color = Color3.fromRGB(230, 126, 34), isCorrect = true },
					{ text = "La Vaca 🐮", color = Color3.fromRGB(52, 152, 219), isCorrect = false },
					{ text = "El Pato 🦆", color = Color3.fromRGB(46, 204, 113), isCorrect = false },
				},
			},
		},
	},
	{
		id = "act_004",
		title = "Números divertidos 🔢",
		category = "Cognitiva / Conteo",
		questions = {
			{
				prompt = "¿Dónde está el número DOS? 2️⃣",
				mascotHint = "¡Cuenta con tus manitas: uno, dos!",
				options = {
					{ text = "Número 1️⃣", color = Color3.fromRGB(52, 152, 219), isCorrect = false },
					{ text = "Número 2️⃣", color = Color3.fromRGB(46, 204, 113), isCorrect = true },
					{ text = "Número 3️⃣", color = Color3.fromRGB(235, 75, 75), isCorrect = false },
					{ text = "Número 4️⃣", color = Color3.fromRGB(241, 196, 15), isCorrect = false },
				},
			},
			{
				prompt = "¿Dónde está el número TRES? 3️⃣",
				mascotHint = "¡Tiene tres puntitas!",
				options = {
					{ text = "Número 1️⃣", color = Color3.fromRGB(235, 75, 75), isCorrect = false },
					{ text = "Número 4️⃣", color = Color3.fromRGB(155, 89, 182), isCorrect = false },
					{ text = "Número 3️⃣", color = Color3.fromRGB(241, 196, 15), isCorrect = true },
					{ text = "Número 2️⃣", color = Color3.fromRGB(46, 204, 113), isCorrect = false },
				},
			},
		},
	},
}

-- ---------------------------------------------------------------------
-- Estado de Juego
-- ---------------------------------------------------------------------
local currentActivityIndex = 1
local currentQuestionIndex = 1
local activityStartTime = os.clock()
local questionStartTime = os.clock()
local score = 0
local interactions = {}
local isAnsweringLocked = false
local TEST_CHILD_ID = "child_TEST_001"

-- ---------------------------------------------------------------------
-- Sonidos amigables y accesibles (recursos locales de Roblox)
-- ---------------------------------------------------------------------
local function playTone(freq: number, duration: number)
	task.spawn(function()
		local ok, sound = pcall(function()
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/button.wav"
			s.PlaybackSpeed = freq
			s.Volume = 0.4
			s.Parent = SoundService
			s:Play()
			return s
		end)
		if ok and sound then
			task.wait(duration)
			pcall(function() sound:Destroy() end)
		end
	end)
end

-- ---------------------------------------------------------------------
-- Construcción de la UI
-- ---------------------------------------------------------------------
-- Limpiar elementos previos si se recarga por Rojo
for _, child in ipairs(screenGui:GetChildren()) do
	if child:IsA("GuiObject") then
		child:Destroy()
	end
end

-- Marco Principal Flotante
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 580, 0, 480)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(65, 80, 110)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainFrame

-- Barra Superior (Encabezado)
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = Color3.fromRGB(38, 44, 60)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 20)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0.65, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⭐ SaIyDD — Aprendizaje Inclusivo"
titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = header

local childBadge = Instance.new("TextLabel")
childBadge.Name = "ChildBadge"
childBadge.Size = UDim2.new(0.24, 0, 0, 30)
childBadge.Position = UDim2.new(1, -50, 0.5, 0)
childBadge.AnchorPoint = Vector2.new(1, 0.5)
childBadge.BackgroundColor3 = Color3.fromRGB(48, 58, 80)
childBadge.TextColor3 = Color3.fromRGB(160, 210, 255)
childBadge.Font = Enum.Font.GothamMedium
childBadge.TextSize = 12
childBadge.Text = "👤 Nico (Prueba)"
childBadge.Parent = header

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 10)
badgeCorner.Parent = childBadge

-- Botón para minimizar y disfrutar la vista 3D completa del avatar
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 32, 0, 30)
minimizeBtn.Position = UDim2.new(1, -10, 0.5, 0)
minimizeBtn.AnchorPoint = Vector2.new(1, 0.5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 88)
minimizeBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 16
minimizeBtn.Text = "─"
minimizeBtn.Parent = header

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minimizeBtn

-- Botón flotante para restaurar la tarjeta cuando esté minimizada
local restoreBtn = Instance.new("TextButton")
restoreBtn.Name = "RestoreBtn"
restoreBtn.Size = UDim2.new(0, 170, 0, 40)
restoreBtn.Position = UDim2.new(0, 20, 0, 20)
restoreBtn.BackgroundColor3 = Color3.fromRGB(38, 44, 60)
restoreBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
restoreBtn.Font = Enum.Font.GothamBold
restoreBtn.TextSize = 13
restoreBtn.Text = "📋 Ver Tarjeta de Preguntas"
restoreBtn.Visible = false
restoreBtn.Parent = screenGui

local restCorner = Instance.new("UICorner")
restCorner.CornerRadius = UDim.new(0, 10)
restCorner.Parent = restoreBtn

local restStroke = Instance.new("UIStroke")
restStroke.Color = Color3.fromRGB(52, 152, 219)
restStroke.Thickness = 2
restStroke.Parent = restoreBtn

minimizeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	restoreBtn.Visible = true
end)

restoreBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	restoreBtn.Visible = false
end)

-- Barra de pestañas de Actividades
local tabsFrame = Instance.new("Frame")
tabsFrame.Name = "TabsFrame"
tabsFrame.Size = UDim2.new(1, -32, 0, 36)
tabsFrame.Position = UDim2.new(0, 16, 0, 70)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.Padding = UDim.new(0, 8)
tabsLayout.Parent = tabsFrame

-- Mascota Guía (Niko el Robot)
local mascotBar = Instance.new("Frame")
mascotBar.Name = "MascotBar"
mascotBar.Size = UDim2.new(1, -32, 0, 48)
mascotBar.Position = UDim2.new(0, 16, 0, 114)
mascotBar.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
mascotBar.BorderSizePixel = 0
mascotBar.Parent = mainFrame

local mascotCorner = Instance.new("UICorner")
mascotCorner.CornerRadius = UDim.new(0, 12)
mascotCorner.Parent = mascotBar

local mascotIcon = Instance.new("TextLabel")
mascotIcon.Size = UDim2.new(0, 40, 1, 0)
mascotIcon.BackgroundTransparency = 1
mascotIcon.Text = "🤖"
mascotIcon.TextSize = 24
mascotIcon.Parent = mascotBar

local mascotText = Instance.new("TextLabel")
mascotText.Name = "MascotText"
mascotText.Size = UDim2.new(1, -50, 1, 0)
mascotText.Position = UDim2.new(0, 44, 0, 0)
mascotText.BackgroundTransparency = 1
mascotText.TextColor3 = Color3.fromRGB(220, 235, 255)
mascotText.Font = Enum.Font.Gotham
mascotText.TextSize = 13
mascotText.TextXAlignment = Enum.TextXAlignment.Left
mascotText.Text = "¡Hola! Vamos a jugar juntos hoy."
mascotText.Parent = mascotBar

-- Tarjeta de Pregunta
local questionCard = Instance.new("Frame")
questionCard.Name = "QuestionCard"
questionCard.Size = UDim2.new(1, -32, 0, 80)
questionCard.Position = UDim2.new(0, 16, 0, 172)
questionCard.BackgroundColor3 = Color3.fromRGB(42, 50, 70)
questionCard.BorderSizePixel = 0
questionCard.Parent = mainFrame

local qCorner = Instance.new("UICorner")
qCorner.CornerRadius = UDim.new(0, 14)
qCorner.Parent = questionCard

local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, -20, 0, 20)
progressText.Position = UDim2.new(0, 12, 0, 8)
progressText.BackgroundTransparency = 1
progressText.TextColor3 = Color3.fromRGB(150, 175, 210)
progressText.Font = Enum.Font.GothamMedium
progressText.TextSize = 12
progressText.TextXAlignment = Enum.TextXAlignment.Left
progressText.Text = "Paso 1 de 3"
progressText.Parent = questionCard

local promptLabel = Instance.new("TextLabel")
promptLabel.Name = "PromptLabel"
promptLabel.Size = UDim2.new(1, -24, 0, 44)
promptLabel.Position = UDim2.new(0, 12, 0, 28)
promptLabel.BackgroundTransparency = 1
promptLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
promptLabel.Font = Enum.Font.GothamBold
promptLabel.TextSize = 18
promptLabel.TextWrapped = true
promptLabel.TextXAlignment = Enum.TextXAlignment.Left
promptLabel.Text = "Cargando..."
promptLabel.Parent = questionCard

-- Contenedor de Botones de Opciones
local optionsGrid = Instance.new("Frame")
optionsGrid.Name = "OptionsGrid"
optionsGrid.Size = UDim2.new(1, -32, 0, 150)
optionsGrid.Position = UDim2.new(0, 16, 0, 262)
optionsGrid.BackgroundTransparency = 1
optionsGrid.Parent = mainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.485, 0, 0.45, 0)
gridLayout.CellPadding = UDim2.new(0.03, 0, 0.1, 0)
gridLayout.Parent = optionsGrid

-- Banner de Retroalimentación Inferior
local feedbackBanner = Instance.new("Frame")
feedbackBanner.Name = "FeedbackBanner"
feedbackBanner.Size = UDim2.new(1, -32, 0, 44)
feedbackBanner.Position = UDim2.new(0, 16, 1, -56)
feedbackBanner.BackgroundColor3 = Color3.fromRGB(36, 42, 58)
feedbackBanner.BorderSizePixel = 0
feedbackBanner.Parent = mainFrame

local fbCorner = Instance.new("UICorner")
fbCorner.CornerRadius = UDim.new(0, 12)
fbCorner.Parent = feedbackBanner

local feedbackText = Instance.new("TextLabel")
feedbackText.Name = "FeedbackText"
feedbackText.Size = UDim2.new(1, 0, 1, 0)
feedbackText.BackgroundTransparency = 1
feedbackText.TextColor3 = Color3.fromRGB(200, 220, 245)
feedbackText.Font = Enum.Font.GothamBold
feedbackText.TextSize = 14
feedbackText.Text = "Selecciona una opción para responder"
feedbackText.Parent = feedbackBanner

-- ---------------------------------------------------------------------
-- Pantalla de Finalización y Envío a Backend
-- ---------------------------------------------------------------------
local completionFrame = Instance.new("Frame")
completionFrame.Name = "CompletionFrame"
completionFrame.Size = UDim2.new(1, 0, 1, 0)
completionFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
completionFrame.BackgroundTransparency = 0.05
completionFrame.Visible = false
completionFrame.Parent = mainFrame

local compCorner = Instance.new("UICorner")
compCorner.CornerRadius = UDim.new(0, 20)
compCorner.Parent = completionFrame

local compTitle = Instance.new("TextLabel")
compTitle.Size = UDim2.new(1, 0, 0, 60)
compTitle.Position = UDim2.new(0, 0, 0, 40)
compTitle.BackgroundTransparency = 1
compTitle.Text = "🎉 ¡Excelente Trabajo! 🎉"
compTitle.TextColor3 = Color3.fromRGB(255, 230, 100)
compTitle.Font = Enum.Font.GothamBold
compTitle.TextSize = 24
compTitle.Parent = completionFrame

local compScore = Instance.new("TextLabel")
compScore.Name = "CompScore"
compScore.Size = UDim2.new(1, 0, 0, 40)
compScore.Position = UDim2.new(0, 0, 0, 100)
compScore.BackgroundTransparency = 1
compScore.TextColor3 = Color3.fromRGB(240, 245, 255)
compScore.Font = Enum.Font.GothamMedium
compScore.TextSize = 16
compScore.Text = "Puntaje: 100 / 100"
compScore.Parent = completionFrame

local syncCard = Instance.new("Frame")
syncCard.Size = UDim2.new(0.85, 0, 0, 100)
syncCard.Position = UDim2.new(0.5, 0, 0, 150)
syncCard.AnchorPoint = Vector2.new(0.5, 0)
syncCard.BackgroundColor3 = Color3.fromRGB(36, 44, 62)
syncCard.BorderSizePixel = 0
syncCard.Parent = completionFrame

local syncCorner = Instance.new("UICorner")
syncCorner.CornerRadius = UDim.new(0, 12)
syncCorner.Parent = syncCard

local syncStatus = Instance.new("TextLabel")
syncStatus.Name = "SyncStatus"
syncStatus.Size = UDim2.new(1, -20, 1, 0)
syncStatus.Position = UDim2.new(0, 10, 0, 0)
syncStatus.BackgroundTransparency = 1
syncStatus.TextColor3 = Color3.fromRGB(160, 220, 255)
syncStatus.Font = Enum.Font.Gotham
syncStatus.TextSize = 13
syncStatus.TextWrapped = true
syncStatus.Text = "📡 Sincronizando con backend SaIyDD..."
syncStatus.Parent = syncCard

local playAgainBtn = Instance.new("TextButton")
playAgainBtn.Size = UDim2.new(0.4, 0, 0, 44)
playAgainBtn.Position = UDim2.new(0.28, 0, 1, -70)
playAgainBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
playAgainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playAgainBtn.Font = Enum.Font.GothamBold
playAgainBtn.TextSize = 14
playAgainBtn.Text = "🔄 Jugar Otra Vez"
playAgainBtn.Parent = completionFrame

local playAgainCorner = Instance.new("UICorner")
playAgainCorner.CornerRadius = UDim.new(0, 12)
playAgainCorner.Parent = playAgainBtn

-- ---------------------------------------------------------------------
-- Lógica del Juego y Envío de Sesión
-- ---------------------------------------------------------------------
local renderQuestion: () -> ()

local function finishActivity()
	completionFrame.Visible = true
	local duration = math.max(1, math.floor(os.clock() - activityStartTime))
	local act = ACTIVITIES[currentActivityIndex]
	compScore.Text = string.format("Puntaje Obtenido: %d / 100  •  Tiempo: %ds", score, duration)
	syncStatus.Text = "📡 Guardando sesión en el backend SaIyDD (FastAPI)..."
	playTone(1.4, 0.4)

	task.spawn(function()
		print(string.format("[SaIyDD][UI] Registrando sesión real: niño=%s, act=%s, pts=%d", TEST_CHILD_ID, act.id, score))
		local reply = Client.recordSession(
			TEST_CHILD_ID,
			act.id,
			score,
			duration,
			interactions
		)

		if reply and reply.ok then
			local sessId = (reply.data and reply.data.id) or "ok"
			syncStatus.Text = string.format("✅ ¡Guardado con éxito en base de datos!\nID de Sesión: %s", tostring(sessId))
			syncStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
		else
			local errMsg = (reply and reply.error and reply.error.message) or "Error desconocido"
			syncStatus.Text = string.format("⚠️ No se pudo guardar: %s", errMsg)
			syncStatus.TextColor3 = Color3.fromRGB(255, 130, 130)
		end
	end)
end

renderQuestion = function()
	isAnsweringLocked = false
	completionFrame.Visible = false
	questionStartTime = os.clock()

	local act = ACTIVITIES[currentActivityIndex]
	local q = act.questions[currentQuestionIndex]

	progressText.Text = string.format("%s  •  Desafío %d de %d", act.title, currentQuestionIndex, #act.questions)
	promptLabel.Text = q.prompt
	mascotText.Text = q.mascotHint
	feedbackText.Text = "Toca la opción que creas correcta 👇"
	feedbackBanner.BackgroundColor3 = Color3.fromRGB(36, 42, 58)

	-- Limpiar opciones anteriores
	for _, child in ipairs(optionsGrid:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	-- Crear botones de opciones
	for i, opt in ipairs(q.options) do
		local btn = Instance.new("TextButton")
		btn.Name = "Option_" .. i
		btn.BackgroundColor3 = opt.color
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 16
		btn.Text = opt.text
		btn.AutoButtonColor = false
		btn.Parent = optionsGrid

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 14)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Thickness = 2
		bStroke.Color = Color3.fromRGB(255, 255, 255)
		bStroke.Transparency = 0.7
		bStroke.Parent = btn

		-- Efecto Hover
		btn.MouseEnter:Connect(function()
			if not isAnsweringLocked then
				TweenService:Create(btn, TweenInfo.new(0.2), { Size = UDim2.new(0.5, 0, 0.48, 0) }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), { Size = UDim2.new(0.485, 0, 0.45, 0) }):Play()
		end)

		-- Al presionar una opción
		btn.MouseButton1Click:Connect(function()
			if isAnsweringLocked then return end
			isAnsweringLocked = true

			local responseTime = math.floor((os.clock() - questionStartTime) * 1000)
			table.insert(interactions, {
				promptIndex = currentQuestionIndex - 1,
				selectedIndex = i - 1,
				correct = opt.isCorrect,
				responseTimeMs = responseTime,
			})

			if opt.isCorrect then
				score += math.floor(100 / #act.questions)
				feedbackBanner.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				feedbackText.Text = "¡Excelente! ¡Respuesta correcta! 🎉"
				mascotText.Text = "¡Muy bien! ¡Qué inteligente eres! ⭐"
				playTone(1.2, 0.2)
			else
				feedbackBanner.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
				feedbackText.Text = "¡Casi! Buen intento, seguimos adelante 💪"
				mascotText.Text = "No te preocupes, ¡la próxima lo lograrás!"
				playTone(0.8, 0.2)
			end

			task.wait(1.4)
			if currentQuestionIndex < #act.questions then
				currentQuestionIndex += 1
				renderQuestion()
			else
				finishActivity()
			end
		end)
	end
end

-- ---------------------------------------------------------------------
-- Construcción de Pestañas de Selección de Actividad
-- ---------------------------------------------------------------------
local function setupTabs()
	for i, act in ipairs(ACTIVITIES) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. i
		tabBtn.Size = UDim2.new(0, 160, 1, 0)
		tabBtn.BackgroundColor3 = if i == currentActivityIndex then Color3.fromRGB(52, 152, 219) else Color3.fromRGB(40, 48, 66)
		tabBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
		tabBtn.Font = Enum.Font.GothamMedium
		tabBtn.TextSize = 12
		tabBtn.Text = act.title
		tabBtn.Parent = tabsFrame

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 8)
		tCorner.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			if currentActivityIndex ~= i then
				currentActivityIndex = i
				currentQuestionIndex = 1
				score = 0
				interactions = {}
				activityStartTime = os.clock()
				setupTabs()
				renderQuestion()
			end
		end)
	end
end

playAgainBtn.MouseButton1Click:Connect(function()
	currentQuestionIndex = 1
	score = 0
	interactions = {}
	activityStartTime = os.clock()
	renderQuestion()
end)

-- Iniciar primera actividad
setupTabs()
renderQuestion()

print("[SaIyDD][UI] Interfaz interactiva de actividades cargada en pantalla.")
