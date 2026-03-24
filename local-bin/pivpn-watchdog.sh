#!/bin/bash

# PiVPN watchdog - restarts openvpn if tun0 interface disappears.
# Runs via root crontab every minute.
# Skips check if service started < 30s ago (avoids race during init).
# OpenVPN's own ping-restart 60 handles dead connections automatically.

SERVICE="openvpn-client@pivpn"

if systemctl is-active --quiet "${SERVICE}.service"; then
    active_ts=$(systemctl show "${SERVICE}.service" --property=ActiveEnterTimestamp --value)
    if [ -n "$active_ts" ]; then
        active_epoch=$(date -d "$active_ts" +%s 2>/dev/null || echo 0)
        now_epoch=$(date +%s)
        age=$(( now_epoch - active_epoch ))
        if [ "$age" -lt 30 ]; then
            exit 0
        fi
    fi

    # Check: tun0 interface must exist when the service is running
    if ! ip link show tun0 &>/dev/null; then
        logger "PiVPN watchdog: tun0 missing (service up ${age:-?}s), restarting"
        systemctl restart "${SERVICE}.service"
        exit 0
    fi

    # Note: OpenVPN's own ping-restart 60 handles dead connections.
    # We only need to catch the rare case where tun0 vanishes entirely.
fi
