--!strict
-- Bridge cliente hacia el backend SaIyDD.
-- Expone Client.recordSession y Client.healthCheck, que se
-- comunican con el servidor vía los RemoteEvents de Events.
--
-- Las funciones bloquean la corrutina actual: llamarlas desde
-- task.spawn (o un handler de evento), nunca desde el hilo
-- principal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedModule = ReplicatedStorage:WaitForChild("Shared", 10)
if sharedModule == nil then
	error("[SaIyDD] No se encontró ReplicatedStorage.Shared tras 10s. Sincronizá con Rojo primero.")
end
local Shared = require(sharedModule)

local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
if eventsFolder == nil then
	error("[SaIyDD] No se encontró ReplicatedStorage.Events tras 10s. Sincronizá con Rojo primero.")
end

local Client = {}

local REPLY_TIMEOUT_SECONDS = 15

-- Hilos esperando respuesta, por RemoteEvent.
local waiters: {[RemoteEvent]: thread?} = {}

-- Conexiones de respuesta ya creadas, por RemoteEvent.
local connected: {[RemoteEvent]: boolean} = {}

local function ensureConnected(event: RemoteEvent)
	if connected[event] then
		return
	end
	connected[event] = true

	event.OnClientEvent:Connect(function(reply: any)
		local waiter = waiters[event]
		if waiter ~= nil then
			waiters[event] = nil
			task.spawn(waiter, reply)
		end
	end)
end

-- Dispara el RemoteEvent y bloquea hasta la respuesta del servidor.
local function callServer(name: string, payload: any?): Shared.RemoteReply
	local event = eventsFolder:WaitForChild(name, 5)
	if event == nil or not event:IsA("RemoteEvent") then
		return Shared.newError("RemoteEvent no encontrado: " .. name, "missing_event")
	end
	-- Si ya hay una petición en curso para este RemoteEvent, esperamos a que termine
	local waitStart = os.clock()
	while waiters[event] ~= nil do
		if os.clock() - waitStart > REPLY_TIMEOUT_SECONDS then
			return Shared.newError("Tiempo de espera en cola agotado para: " .. name, "queue_timeout")
		end
		task.wait(0.1)
	end
	if not coroutine.isyieldable() then
		error("[SaIyDD] " .. name .. " debe llamarse desde una corrutina (ej: task.spawn).", 2)
	end

	ensureConnected(event)

	local thread = coroutine.running()
	waiters[event] = thread
	event:FireServer(payload)

	local timer = task.delay(REPLY_TIMEOUT_SECONDS, function()
		if waiters[event] == thread then
			waiters[event] = nil
			task.spawn(thread, Shared.newError("Tiempo de espera agotado", "timeout"))
		end
	end)

	local reply: any = coroutine.yield()
	pcall(task.cancel, timer)
	return reply
end

-- Registra una sesión de actividad en el backend.
-- Ejemplo:
--   task.spawn(function()
--     local reply = Client.recordSession("child_001", "act_001", 100, 90)
--     if not reply.ok then warn("[SaIyDD] " .. reply.error.message) end
--   end)
function Client.recordSession(
	childId: string,
	activityId: string,
	score: number,
	durationSeconds: number,
	interactions: {Shared.Interaction}?
): Shared.RemoteReply
	local payload = Shared.buildSessionPayload(
		childId,
		activityId,
		score,
		durationSeconds,
		interactions
	)
	return callServer(Shared.EVENTS.recordSession, payload)
end

-- Verifica la conectividad con el backend.
function Client.healthCheck(): Shared.RemoteReply
	return callServer(Shared.EVENTS.healthCheck, nil)
end

print("[SaIyDD] Bridge cliente listo")

return Client
