--!strict
-- Contrato compartido cliente/servidor para la API del backend SaIyDD.
-- Este módulo se replica a los clientes: NUNCA poner secretos ni tokens aquí.

local HttpService = game:GetService("HttpService")

export type Interaction = {
	promptIndex: number,
	selectedIndex: number,
	correct: boolean,
	responseTimeMs: number?,
}

export type SessionPayload = {
	childId: string,
	activityId: string,
	score: number,
	durationSeconds: number,
	interactions: {Interaction},
}

export type ApiResult = {
	ok: boolean,
	status: number,
	data: any?,
}

export type RemoteReply = {
	ok: boolean,
	data: any?,
	error: { code: string, message: string }?,
}

local Shared = {}

-- Rutas de la API (se concatenan con la apiUrl de server/secrets.lua).
Shared.ENDPOINTS = {
	health = "/api/health",
	sessions = "/api/sessions",
}

-- Nombres de los RemoteEvents declarados en default.project.json.
Shared.EVENTS = {
	recordSession = "SAIyDDRecordSession",
	healthCheck = "SAIyDDHealthCheck",
}

-- Construye el payload de sesión en camelCase, como espera el backend
-- (POST /api/sessions -> SessionRecordCreate).
function Shared.buildSessionPayload(
	childId: string,
	activityId: string,
	score: number,
	durationSeconds: number,
	interactions: {Interaction}?
): SessionPayload
	return {
		childId = childId,
		activityId = activityId,
		score = score,
		durationSeconds = durationSeconds,
		interactions = interactions or {},
	}
end

-- Valida el payload mínimo antes de enviarlo al backend.
function Shared.validateSessionPayload(payload: any): boolean
	if type(payload) ~= "table" then
		return false
	end
	if type(payload.childId) ~= "string" or payload.childId == "" then
		return false
	end
	if type(payload.activityId) ~= "string" or payload.activityId == "" then
		return false
	end
	if type(payload.score) ~= "number" or payload.score < 0 then
		return false
	end
	if type(payload.durationSeconds) ~= "number" or payload.durationSeconds < 0 then
		return false
	end
	return true
end

-- Interpreta la respuesta de HttpService:RequestAsync.
-- "ok" indica que hubo respuesta HTTP (sin error de red);
-- hay que verificar "status" para los códigos 2xx/4xx/5xx.
function Shared.parseApiResponse(response: any): ApiResult
	local ok = response ~= nil and response.Success == true
	local status = 0
	if response ~= nil and response.StatusCode ~= nil then
		status = response.StatusCode
	end

	local data: any = nil
	if ok then
		local body = response.Body
		if type(body) == "string" and body ~= "" then
			local success, decoded = pcall(function(): any
				return HttpService:JSONDecode(body)
			end)
			if success then
				data = decoded
			end
		end
	end

	return { ok = ok, status = status, data = data }
end

-- Verifica si un código de estado HTTP es exitoso (2xx).
function Shared.isSuccessStatus(status: number): boolean
	return status >= 200 and status < 300
end

-- Respuesta de error estandarizada para los RemoteEvents.
function Shared.newError(message: string, code: string?): RemoteReply
	return {
		ok = false,
		data = nil,
		error = { code = code or "unknown", message = message },
	}
end

-- Respuesta exitosa estandarizada para los RemoteEvents.
function Shared.newSuccess(data: any?): RemoteReply
	return {
		ok = true,
		data = data,
		error = nil,
	}
end

return Shared
