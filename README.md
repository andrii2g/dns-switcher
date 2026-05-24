# DNS Switcher

Small utility for quickly switching DNS settings between known public DNS providers and your normal DHCP/provider DNS on Windows and Linux.

## Why this exists

Sometimes a website does not open because DNS traffic is filtered, sinkholed, or redirected by an ISP, router, antivirus product, corporate network, or security DNS provider.
I'm saying Hello! to ISP Astra with their `interesting` DNS `193.93.216.55` ([see details here](images/mitm-certificate.png))

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

You can add more custom DNS as you need

## Platforms

- Windows 10 / Windows 11 with PowerShell 5.1+ via [scripts/set-dns.ps1](scripts\set-dns.ps1)
- Linux systems managed by NetworkManager via [scripts/set-dns.sh](scripts\set-dns.sh)

## Documentation

- For step-by-step commands, see [QUICKSTART.md](QUICKSTART.md).
- Windows and Linux both support `cloudflare`, `google`, `quad9`, and `auto`.
- `auto` restores DHCP/default DNS instead of forcing a public resolver.

## How it works

- On Windows, the script updates active physical adapters and resets them back to DHCP/default DNS when `auto` is selected.
- On Linux, the script updates active NetworkManager-managed `ethernet` and `wifi` devices and removes explicit DNS overrides when `auto` is selected.
- After a successful change, each script attempts to flush the local DNS cache.

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

- If no adapters or interfaces are detected, verify that the target network device is up and managed by the local OS networking stack.
- If Linux changes do not apply, confirm the system is using NetworkManager and that `nmcli` is available.
- If the website still fails after switching DNS, test with a VPN or mobile hotspot. If it works there, the issue is likely still in the current network path, router, ISP, antivirus, or browser security configuration.
- For exact operational commands, manual verification steps, and cache flush commands, use [QUICKSTART.md](QUICKSTART.md).
