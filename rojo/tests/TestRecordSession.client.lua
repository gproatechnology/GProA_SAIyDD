--!strict
-- LocalScript de prueba de humo (Smoke Test) defensivo para SaIyDD.
-- Ubicación: StarterPlayer.StarterPlayerScripts.TestRecordSession
-- Verifica la cadena completa: Rojo -> StarterPlayerScripts.Client -> RemoteEvents -> ServerScriptService.Server -> Backend FastAPI.

print("==============================================================")
print("[SaIyDD][TEST] Iniciando Smoke Test de integración...")
print("==============================================================")

local TEST_CHILD_ID = "child_TEST_001"
local TEST_ACTIVITY_ID = "act_001"
local WAIT_TIMEOUT = 10
local AUTO_RUN_ON_PLAY = false -- Cambiar a true si deseas la prueba de humo automática por consola

if not AUTO_RUN_ON_PLAY then
	print("[SaIyDD][TEST] Smoke test automático en espera. Usa la interfaz visual interactiva en pantalla (StarterGui.ActivityGui).")
	return
end

task.spawn(function()
	-- -----------------------------------------------------------------
	-- PASO 1: Carga del módulo Client sincronizado por Rojo (con timeout)
	-- -----------------------------------------------------------------
	print("[SaIyDD][TEST] [1/4] Buscando StarterPlayerScripts.Client...")
	local clientFolder = script.Parent:WaitForChild("Client", WAIT_TIMEOUT)
	if not clientFolder then
		warn("[SaIyDD][TEST] [FAIL] No se encontró la carpeta 'Client' tras " .. WAIT_TIMEOUT .. "s.")
		warn("  -> Causa: Rojo no está conectado o no sincronizó StarterPlayerScripts.")
		warn("  -> Solución: En Studio, ve a Plugins -> Rojo -> Connect (puerto 34872).")
		return
	end

	print("[SaIyDD][TEST] [2/4] Buscando Client.main...")
	local mainModule = clientFolder:WaitForChild("main", WAIT_TIMEOUT)
	if not mainModule or not mainModule:IsA("ModuleScript") then
		warn("[SaIyDD][TEST] [FAIL] No se encontró ModuleScript 'main' dentro de Client.")
		warn("  -> Causa: El archivo rojo/client/main.lua no fue sincronizado.")
		return
	end

	local requireOk, Client = pcall(require, mainModule)
	if not requireOk or type(Client) ~= "table" then
		warn("[SaIyDD][TEST] [FAIL] Error al hacer require(Client.main): " .. tostring(Client))
		return
	end

	-- -----------------------------------------------------------------
	-- PASO 2: Introspección y validación defensiva de funciones
	-- -----------------------------------------------------------------
	print("[SaIyDD][TEST] Módulo Client.main cargado correctamente.")
	print("[SaIyDD][TEST] Inspeccionando funciones exportadas:")
	local functionCount = 0
	for name, val in pairs(Client) do
		print(string.format("   * %s (%s)", tostring(name), type(val)))
		if type(val) == "function" then
			functionCount += 1
		end
	end

	if functionCount == 0 then
		warn("[SaIyDD][TEST] [FAIL] Client no exporta ninguna función. ¿Rojo sincronizó una versión vacía?")
		return
	end

	if type(Client.healthCheck) ~= "function" then
		warn("[SaIyDD][TEST] [FAIL] Client.healthCheck no existe o no es función (es " .. type(Client.healthCheck) .. ").")
		return
	end

	if type(Client.recordSession) ~= "function" then
		warn("[SaIyDD][TEST] [FAIL] Client.recordSession no existe o no es función (es " .. type(Client.recordSession) .. ").")
		return
	end

	print("[SaIyDD][TEST] [OK] Interfaz de funciones validada.")

	-- -----------------------------------------------------------------
	-- PASO 3: HealthCheck (Client -> RemoteEvent -> Server -> GET /api/health)
	-- -----------------------------------------------------------------
	print("\n[SaIyDD][TEST] [3/4] Ejecutando Client.healthCheck()...")
	local healthOk, healthReply = pcall(function()
		return Client.healthCheck()
	end)

	if not healthOk then
		warn("[SaIyDD][TEST] [FAIL] Excepción al invocar Client.healthCheck(): " .. tostring(healthReply))
		return
	end

	if not healthReply or not healthReply.ok then
		local errCode = (healthReply and healthReply.error and healthReply.error.code) or "desconocido"
		local errMsg = (healthReply and healthReply.error and healthReply.error.message) or "sin mensaje"
		warn(string.format("[SaIyDD][TEST] [FAIL] healthCheck rechazado [%s]: %s", tostring(errCode), tostring(errMsg)))
		warn("  -> Diagnóstico de causas comunes:")
		warn("     1. HttpService deshabilitado: Activa 'Allow HTTP Requests' en Game Settings -> Security.")
		warn("     2. Backend apagado: Inicia el backend (opción 7 u 8 de rojo-manager.ps1) en http://127.0.0.1:8000.")
		warn("     3. Script servidor no corre: Verifica ServerScriptService.Server.main.server.lua.")
		return
	end

	print(string.format(
		"[SaIyDD][TEST] [OK] HealthCheck exitoso! Backend responde: status=%s, version=%s",
		tostring(healthReply.data and healthReply.data.status),
		tostring(healthReply.data and healthReply.data.version)
	))

	-- -----------------------------------------------------------------
	-- PASO 4: RecordSession (Client -> RemoteEvent -> Server -> POST /api/sessions)
	-- -----------------------------------------------------------------
	print(string.format("\n[SaIyDD][TEST] [4/4] Ejecutando Client.recordSession para '%s'...", TEST_CHILD_ID))
	local sampleInteractions = {
		{
			promptIndex = 0,
			selectedIndex = 1,
			correct = true,
			responseTimeMs = 2100,
		},
	}

	local sessionOk, sessionReply = pcall(function()
		return Client.recordSession(
			TEST_CHILD_ID,
			TEST_ACTIVITY_ID,
			100, -- score
			60,  -- durationSeconds
			sampleInteractions
		)
	end)

	if not sessionOk then
		warn("[SaIyDD][TEST] [FAIL] Excepción al invocar Client.recordSession(): " .. tostring(sessionReply))
		return
	end

	if not sessionReply or not sessionReply.ok then
		local errCode = (sessionReply and sessionReply.error and sessionReply.error.code) or "desconocido"
		local errMsg = (sessionReply and sessionReply.error and sessionReply.error.message) or "sin mensaje"
		warn(string.format("[SaIyDD][TEST] [FAIL] recordSession rechazado [%s]: %s", tostring(errCode), tostring(errMsg)))
		warn("  -> Diagnóstico de causas comunes:")
		warn("     1. Credenciales de secrets.lua inválidas o no registradas en backend.")
		warn("     2. El niño '" .. TEST_CHILD_ID .. "' no existe en la base de datos.")
		warn("     3. La actividad '" .. TEST_ACTIVITY_ID .. "' no existe en el catálogo.")
		return
	end

	local sessionId = sessionReply.data and sessionReply.data.id or "N/A"
	print(string.format("[SaIyDD][TEST] [OK] Sesión registrada exitosamente en backend! ID: %s", tostring(sessionId)))
	print("==============================================================")
	print("[SaIyDD][TEST] PRUEBA DE INTEGRACIÓN COMPLETADA CON ÉXITO")
	print("==============================================================")
end)
