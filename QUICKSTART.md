# QUICKSTART.md - DNS Switcher

## Windows

Open PowerShell as Administrator:

```text
Start -> type PowerShell -> right-click Windows PowerShell -> Run as administrator
```

Switch to Cloudflare:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-dns.ps1 cloudflare
```

Switch to Google:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-dns.ps1 google
```

Switch to Quad9:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-dns.ps1 quad9
```

Restore DHCP/default DNS:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-dns.ps1 auto
```

Check current DNS:

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
```

Flush DNS manually:

```powershell
Clear-DnsClientCache
```

## Linux

The Linux script currently supports systems managed by NetworkManager.

Switch to Cloudflare:

```bash
sudo ./scripts/set-dns.sh cloudflare
```

Switch to Google:

```bash
sudo ./scripts/set-dns.sh google
```

Switch to Quad9:

```bash
sudo ./scripts/set-dns.sh quad9
```

Restore DHCP/default DNS:

```bash
sudo ./scripts/set-dns.sh auto
```

Check current DNS:

```bash
nmcli device show | grep -E 'GENERAL.DEVICE|IP4.DNS'
```

Flush DNS manually:

```bash
sudo resolvectl flush-caches
```
