# ============================================================
#  configure_oauth.ps1
#  Configura Google OAuth para GuardiaMaster (Supabase + Google Cloud)
#  Ejecutar desde PowerShell: .\configure_oauth.ps1
# ============================================================

$PROJECT_REF    = "sqvnwbyciampgixlubxc"
$APP_SCHEME     = "com.tuempresa.guardiasapp://login-callback"
$SUPABASE_CB    = "https://$PROJECT_REF.supabase.co/auth/v1/callback"
$SUPABASE_URL   = "https://$PROJECT_REF.supabase.co"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  GuardiaMaster - Configuracion OAuth" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── PASO 1: Supabase (via Management API) ───────────────────
Write-Host "[PASO 1/2] Configurar redirect URL en Supabase" -ForegroundColor Yellow
Write-Host ""
Write-Host "Necesitas un Personal Access Token de Supabase."
Write-Host "Abriendo la pagina para generarlo..." -ForegroundColor Gray
Start-Process "https://app.supabase.com/account/tokens"
Write-Host ""
$pat = Read-Host "Pega aqui tu Supabase Personal Access Token (o ENTER para saltar)"

if ($pat -and $pat.Trim() -ne "") {
    Write-Host ""
    Write-Host "  Configurando redirect URL: $APP_SCHEME" -ForegroundColor Gray

    $body = @{
        additional_redirect_urls = @($APP_SCHEME)
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod `
            -Method Patch `
            -Uri "https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth" `
            -Headers @{
                "Authorization" = "Bearer $($pat.Trim())"
                "Content-Type"  = "application/json"
            } `
            -Body $body `
            -ErrorAction Stop

        Write-Host "  [OK] Supabase configurado correctamente" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Puedes hacerlo manualmente en:" -ForegroundColor Gray
        Write-Host "  https://app.supabase.com/project/$PROJECT_REF/auth/url-configuration" -ForegroundColor White
        Write-Host "  -> Redirect URLs -> Add URL -> $APP_SCHEME" -ForegroundColor White
    }
} else {
    Write-Host "  [SALTADO] Hazlo manualmente en:" -ForegroundColor DarkYellow
    Write-Host "  https://app.supabase.com/project/$PROJECT_REF/auth/url-configuration" -ForegroundColor White
    Write-Host "  -> Redirect URLs -> Add URL -> $APP_SCHEME" -ForegroundColor White
}

Write-Host ""

# ── PASO 2: Google Cloud Console (requiere accion manual) ───
Write-Host "[PASO 2/2] Registrar callback en Google Cloud Console" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Abriendo Google Cloud Console -> Credenciales..." -ForegroundColor Gray
Start-Process "https://console.cloud.google.com/apis/credentials"

Write-Host ""
Write-Host "  Que debes hacer en el navegador:" -ForegroundColor White
Write-Host "  1. Haz clic en tu OAuth 2.0 Client ID" -ForegroundColor Gray
Write-Host "  2. En 'URIs de redireccionamiento autorizados' -> Agregar URI" -ForegroundColor Gray
Write-Host "  3. Pega exactamente esta URL:" -ForegroundColor Gray
Write-Host ""
Write-Host "     $SUPABASE_CB" -ForegroundColor Green
Write-Host ""
Write-Host "  4. Haz clic en Guardar" -ForegroundColor Gray
Write-Host "  5. Espera ~2 minutos para que se propague" -ForegroundColor Gray

# Copia la URL al portapapeles
Set-Clipboard -Value $SUPABASE_CB
Write-Host ""
Write-Host "  [OK] La URL ya esta copiada en tu portapapeles, solo pega (Ctrl+V)" -ForegroundColor Green

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Una vez hecho, reinicia la app y prueba" -ForegroundColor Cyan
Write-Host "  el boton 'Continuar con Google'." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
