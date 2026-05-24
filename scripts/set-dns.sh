#!/usr/bin/env bash

set -uo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/set-dns.sh cloudflare
  ./scripts/set-dns.sh --provider cloudflare

Supported providers:
  cloudflare
  google
  quad9
  auto
EOF
}

provider=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--provider)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for $1." >&2
        usage >&2
        exit 1
      fi
      provider="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$provider" ]]; then
        provider="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

case "$provider" in
  cloudflare|google|quad9|auto)
    ;;
  *)
    echo "Invalid provider: ${provider:-<empty>}." >&2
    usage >&2
    exit 1
    ;;
esac

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "This script must be run as root. Run it with sudo and try again." >&2
  exit 2
fi

if ! command -v nmcli >/dev/null 2>&1; then
  echo "NetworkManager nmcli is required on Linux for this script." >&2
  exit 4
fi

declare -A dns_map=(
  [cloudflare]="1.1.1.1 1.0.0.1"
  [google]="8.8.8.8 8.8.4.4"
  [quad9]="9.9.9.9 149.112.112.112"
)

declare -a active_devices=()

while IFS=: read -r device type state; do
  [[ -n "$device" ]] || continue

  case "$type" in
    ethernet|wifi)
      ;;
    *)
      continue
      ;;
  esac

  case "$state" in
    connected|connected\ \(externally\)|connected\ \(site\ only\)|connected\ \(limited\))
      active_devices+=("$device")
      ;;
  esac
done < <(nmcli -t -f DEVICE,TYPE,STATE device status)

if [[ ${#active_devices[@]} -eq 0 ]]; then
  echo "No active physical network interfaces were found." >&2
  exit 3
fi

echo "Selected provider: $provider"

if [[ "$provider" == "auto" ]]; then
  echo "Restoring DNS server addresses from DHCP/default configuration."
else
  echo "DNS servers: ${dns_map[$provider]// /, }"
fi

for device in "${active_devices[@]}"; do
  connection="$(nmcli -t -g GENERAL.CONNECTION device show "$device" 2>/dev/null || true)"

  if [[ -z "$connection" || "$connection" == "--" ]]; then
    echo "Failed to resolve the active NetworkManager connection for interface: $device" >&2
    exit 4
  fi

  echo "Updating interface: $device"

  if [[ "$provider" == "auto" ]]; then
    if ! nmcli connection modify "$connection" ipv4.ignore-auto-dns no ipv4.dns ""; then
      echo "Failed to update DNS settings for interface: $device" >&2
      exit 4
    fi
  else
    if ! nmcli connection modify "$connection" ipv4.ignore-auto-dns yes ipv4.dns "${dns_map[$provider]}"; then
      echo "Failed to update DNS settings for interface: $device" >&2
      exit 4
    fi
  fi

  if ! nmcli device reapply "$device"; then
    if ! nmcli connection up "$connection" ifname "$device"; then
      echo "Failed to apply DNS settings for interface: $device" >&2
      exit 4
    fi
  fi
done

echo "Flushing DNS client cache..."

if command -v resolvectl >/dev/null 2>&1; then
  if ! resolvectl flush-caches; then
    echo "Warning: DNS settings were updated, but DNS cache flush failed." >&2
  fi
elif command -v systemd-resolve >/dev/null 2>&1; then
  if ! systemd-resolve --flush-caches; then
    echo "Warning: DNS settings were updated, but DNS cache flush failed." >&2
  fi
else
  echo "Warning: DNS settings were updated, but no supported DNS cache flush command was found." >&2
fi

echo "Done."
exit 0
