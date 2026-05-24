# DNS Switcher

Small utility for quickly switching DNS settings between known public DNS providers and your normal DHCP/provider DNS on Windows and Linux.

## Why this exists

Sometimes a website does not open because DNS traffic is filtered, sinkholed, or redirected by an ISP, router, antivirus product, corporate network, or security DNS provider.

A common symptom is a browser warning like:

```text
Your connection is not private
NET::ERR_CERT_AUTHORITY_INVALID
```

and the certificate viewer shows an unexpected issuer such as a security filtering or sinkhole CA instead of the website's normal certificate chain.

This tool helps you quickly test whether the problem is caused by DNS filtering, ISP DNS, router DNS, or security sinkhole systems. You can switch to Cloudflare, Google, or Quad9, test the website, and then switch back to automatic DHCP/provider DNS.

## Supported DNS providers

| Codename | DNS servers |
|---|---|
| `cloudflare` | `1.1.1.1`, `1.0.0.1` |
| `google` | `8.8.8.8`, `8.8.4.4` |
| `quad9` | `9.9.9.9`, `149.112.112.112` |
| `auto` | Restore DHCP/default DNS |

You can add more custom rows

## Quick usage

Windows PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-dns.ps1 cloudflare
```

Linux with `sudo` on a NetworkManager-managed system:

```bash
sudo ./scripts/set-dns.sh cloudflare
```

The Linux script also supports named parameter usage:

```bash
sudo ./scripts/set-dns.sh --provider cloudflare
```

## Restore provider/router DNS

If your DNS normally comes from DHCP, your router, or your ISP, restore it with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-dns.ps1 auto
```

or on Linux:

```bash
sudo ./scripts/set-dns.sh auto
```

On Windows this uses:

```powershell
Set-DnsClientServerAddress -ResetServerAddresses
```

On Linux it removes the explicit DNS override from the active NetworkManager connection and re-enables automatic DNS from DHCP or the connection's default resolver source.

## Verify current DNS settings

Windows:

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4
```

Linux:

```bash
nmcli device show | grep -E 'GENERAL.DEVICE|IP4.DNS'
```

## Safety notes

- Run the Windows script as Administrator.
- Run the Linux script as `root` with `sudo`.
- The Windows script changes Windows adapter DNS settings.
- The Linux script changes active NetworkManager connection DNS settings.
- It does not change Chrome settings directly.
- It does not install certificates.
- It does not modify the hosts file.
- It does not configure DNS-over-HTTPS.
- Use `auto` to restore DHCP/default DNS.
- Linux support currently targets NetworkManager via `nmcli`.

## Troubleshooting

If the Windows script says no active adapters were found, check adapter status:

```powershell
Get-NetAdapter
```

If the Linux script says no active interfaces were found, inspect NetworkManager state:

```bash
nmcli device status
nmcli connection show --active
```

If the website still fails after switching DNS, test with a VPN or mobile hotspot. If it works there, the issue is likely still in the current network path, router, ISP, antivirus, or browser security configuration.

To manually flush DNS cache on Windows:

```powershell
Clear-DnsClientCache
```

On Linux with `systemd-resolved`:

```bash
sudo resolvectl flush-caches
```
