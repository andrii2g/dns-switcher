$script = Join-Path $PSScriptRoot "..\scripts\set-dns.ps1"
& $script cloudflare
exit $LASTEXITCODE
