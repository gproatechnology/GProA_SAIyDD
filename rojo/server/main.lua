--!strict
-- Servicio del servidor: conecta Studio con el backend SaIyDD.
-- Vive en ServerScriptService: el único lugar donde pueden
-- existir secretos (secrets.lua, sincronizado por Rojo).

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedModule = ReplicatedStorage:FindFirstChild("Shared")
if sharedModule == nil then
	error("[SaIyDD] No se encontró ReplicatedStorage.Shared. Sincronizá con Rojo primero.")
end
local Shared = require(sharedModule)

local secretsModule = script.Parent:FindFirstChild("secrets")
if secretsModule == nil then
	error("[SaIyDD] Falta server/secrets.lua. Copiá secrets.example.lua y configurá las credenciales.")
end
local Secrets = require(secretsModule)

local BASE_URL: string = (Secrets.apiUrl or "http://localhost:8000"):gsub("/+$", "")

-- JWT de la cuenta de servicio, cacheado tras el primer login.
local TOKEN: string? = nil

-- Petición HTTP al backend. Devuelve { ok, status, data }.
-- "ok" indica que hubo respuesta HTTP (sin error de red);
-- los códigos 2xx/4xx/5xx se revisan aparte.
local function request(
	method: string,
	path: string,
	body: any?,
	token: string?
): Shared.ApiResult
	local headers: {[string]: string} = {}
	if token ~= nil then
		headers["Authorization"] = "Bearer " .. token
	end

	local options: {[string]: any} = {
		Url = BASE_URL .. path,
		Method = method,
		Headers = headers,
	}
	if body ~= nil then
		headers["Content-Type"] = "application/json"
		options.Body = HttpService:JSONEncode(body)
	end

	local ok, response = pcall(function(): any
		return HttpService:RequestAsync(options)
	end)
	if not ok then
		return { ok = false, status = 0, data = nil }
	end
	return Shared.parseApiResponse(response)
end

-- Login con la cuenta de servicio. Devuelve el JWT o nil.
local function login(): string?
	local result = request("POST", "/api/auth/login", {
		email = Secrets.email,
		password = Secrets.password,
	}, nil)
	if result.ok
		and result.status == 200
		and result.data ~= nil
		and result.data.accessToken ~= nil
	then
		return result.data.accessToken
	end
	warn("[SaIyDD] Login fallido (HTTP " .. result.status .. ")")
	return nil
end

-- Devuelve un JWT válido, haciendo login si es necesario.
local function ensureToken(): string?
	if TOKEN ~= nil then
		return TOKEN
	end
	TOKEN = login()
	return TOKEN
end

-- POST /api/sessions con reintento ante 401 (token expirado).
local function recordSession(payload: any): Shared.RemoteReply
	if not Shared.validateSessionPayload(payload) then
		return Shared.newError("Payload de sesión inválido", "invalid_payload")
	end

	local token = ensureToken()
	if token == nil then
		return Shared.newError("No se pudo autenticar con el backend", "auth_failed")
	end

	local result = request("POST", Shared.ENDPOINTS.sessions, payload, token)
	if result.ok and result.status == 401 then
		TOKEN = nil
		token = ensureToken()
		if token == nil then
			return Shared.newError("No se pudo reautenticar con el backend", "auth_failed")
		end
		result = request("POST", Shared.ENDPOINTS.sessions, payload, token)
	end

	if not result.ok then
		return Shared.newError("Sin respuesta del backend", "network_error")
	end
	if not Shared.isSuccessStatus(result.status) then
		local message = "Error del backend (HTTP " .. result.status .. ")"
		if
			result.data ~= nil
			and result.data.error ~= nil
			and result.data.error.message ~= nil
		then
			message = result.data.error.message
		end
		return Shared.newError(message, "backend_error")
	end

	return Shared.newSuccess(result.data)
end

-- GET /api/health para verificar conectividad con el backend.
local function healthCheck(): Shared.RemoteReply
	local result = request("GET", Shared.ENDPOINTS.health, nil, nil)
	if not result.ok then
		return Shared.newError("Sin respuesta del backend", "network_error")
	end
	if not Shared.isSuccessStatus(result.status) then
		return Shared.newError(
			"Backend no disponible (HTTP " .. result.status .. ")",
			"backend_error"
		)
	end
	return Shared.newSuccess(result.data)
end

-- Conecta un RemoteEvent del folder Events con su handler.
local function wireEvent(
	name: string,
	handler: (payload: any) -> Shared.RemoteReply
)
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if eventsFolder == nil then
		error("[SaIyDD] No se encontró ReplicatedStorage.Events. Sincronizá con Rojo primero.")
	end

	local event = eventsFolder:FindFirstChild(name)
	if event == nil or not event:IsA("RemoteEvent") then
		warn("[SaIyDD] RemoteEvent no encontrado: " .. name)
		return
	end

	event.OnServerEvent:Connect(function(player: Player, payload: any)
		event:FireClient(player, handler(payload))
	end)
	print("[SaIyDD] Handler listo: " .. name)
end

wireEvent(Shared.EVENTS.recordSession, recordSession)
wireEvent(Shared.EVENTS.healthCheck, healthCheck)

print("[SaIyDD] Servicio backend listo: " .. BASE_URL)
