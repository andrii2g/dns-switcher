param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("cloudflare", "google", "quad9", "auto")]
    [string]$Provider
)

$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    Write-Error "This script must be run as Administrator. Open PowerShell as Administrator and try again."
    exit 2
}

$dnsMap = @{
    cloudflare = @("1.1.1.1", "1.0.0.1")
    google     = @("8.8.8.8", "8.8.4.4")
    quad9      = @("9.9.9.9", "149.112.112.112")
}

$adapters = Get-NetAdapter |
    Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true }

if (-not $adapters -or $adapters.Count -eq 0) {
    Write-Error "No active physical network adapters were found."
    exit 3
}

Write-Host "Selected provider: $Provider"

if ($Provider -eq "auto") {
    Write-Host "Restoring DNS server addresses from DHCP/default configuration."
}
else {
    Write-Host "DNS servers: $($dnsMap[$Provider] -join ', ')"
}

try {
    foreach ($adapter in $adapters) {
        Write-Host "Updating adapter: $($adapter.Name)"

        if ($Provider -eq "auto") {
            Set-DnsClientServerAddress `
                -InterfaceIndex $adapter.InterfaceIndex `
                -ResetServerAddresses
        }
        else {
            Set-DnsClientServerAddress `
                -InterfaceIndex $adapter.InterfaceIndex `
                -ServerAddresses $dnsMap[$Provider]
        }
    }
}
catch {
    Write-Error "Failed to update DNS settings. $($_.Exception.Message)"
    exit 4
}

try {
    Write-Host "Flushing DNS client cache..."
    Clear-DnsClientCache
}
catch {
    Write-Warning "DNS settings were updated, but DNS cache flush failed. $($_.Exception.Message)"
}

Write-Host "Done."
exit 0
