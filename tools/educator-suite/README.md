# SaIyDD - Suite Educativa

Suite web independiente para que la profesional de la educación visualice los resultados del simulador SaIyDD.

## Requisitos
- Backend FastAPI corriendo en `http://127.0.0.1:8000`
- Servidor Rojo corriendo en `http://localhost:34872` (opcional para ver estado de sincronización)
- Navegador moderno
- Credenciales de tutor válidas

## Levantar en local

```powershell
cd "C:\Users\X1\OneDrive\Documentos\Python_VS Code\GProA\SAIyDD\tools\educator-suite"
python -m http.server 8081
```

Abrir: [http://localhost:8081](http://localhost:8081)

## Uso
1. Iniciar sesión con las credenciales del tutor
2. Ver resultados en Panel General / Alumnos / Ficha / Historial
3. Revisar estado del simulador en "Estado del simulador"

## Notas
- Usa el mismo login que el gestor (`rojo-manager.ps1`)
- Solo lectura. No crea/modifica/borra niños
- Muestra `child_TEST_001` por defecto
- Si el token expira vuelve automáticamente al login
- Recordatorio: activar `Allow HTTP Requests = ON` en Game Settings > Security de Roblox Studio
