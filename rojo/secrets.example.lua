-- Plantilla de configuración del servicio Roblox.
-- Copiar a rojo/server/secrets.lua con los valores reales.
-- Ese archivo está ignorado por git y nunca debe comitearse.
return {
	-- URL base del backend SaIyDD (servicio local durante el desarrollo)
	apiUrl = "http://localhost:8000",

	-- Cuenta de servicio de tutor: registrarla vía POST /api/auth/register
	-- y usar sus credenciales aquí. El servidor Roblox hace login y cachea
	-- el JWT (relogin automático ante 401).
	email = "studio-service@ejemplo.local",
	password = "cambia-esta-contrasena",
}
