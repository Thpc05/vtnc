#!/usr/bin/env python3
# nmcli wrapper printing the JSON NetworkService.qml reads.
#   network.py status | networks | enable <true|false> | connect <ssid> [password]
#              disconnect <ssid> | monitor   (one status line per `nmcli monitor` event)
import json
import subprocess
import sys


def sh(cmd):
    try:
        return subprocess.run(cmd, shell=isinstance(cmd, str), capture_output=True, text=True).stdout
    except Exception:
        return ""


def atoi(s):
    try:
        return int(s.strip())
    except ValueError:
        return 0


def snapshot():
    st = {"wifi": False, "ethernet": False, "wifi_enabled": False, "wifi_status": "",
          "network_name": "", "strength": 0, "connectivity": ""}
    lines = sh("nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g").split()
    if lines:
        conn = lines[-1]
        st["connectivity"] = conn
        for l in lines[:-1]:
            parts = l.split(":", 1)
            if len(parts) != 2:
                continue
            typ, state = parts
            if typ == "ethernet" and state == "connected":
                st["ethernet"] = True
            elif typ == "wifi":
                if state == "connected":
                    st["wifi"] = True
                    st["wifi_status"] = "connected"
                    if conn == "limited":
                        st["wifi_status"] = "limited"
                        st["wifi"] = False
                elif state == "connecting":
                    st["wifi_status"] = "connecting"
                elif state == "unavailable":
                    st["wifi_status"] = "disabled"
    st["network_name"] = sh("nmcli -t -f NAME c show --active | head -1").strip()
    st["strength"] = atoi(sh("nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'").split("\n")[0])
    st["wifi_enabled"] = sh(["nmcli", "radio", "wifi"]).strip() == "enabled"
    if not st["wifi"] and st["wifi_status"] == "" and not st["ethernet"]:
        st["wifi_status"] = "disconnected"
    return st


def networks():
    out = sh(["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "device", "wifi"])
    ph = "STRINGWHICHWILLNEVERAPPEAR"
    seen = {}
    for line in out.split("\n"):
        net = line.replace("\\:", ph).split(":")
        if len(net) < 6 or net[3] == "":
            continue
        e = {
            "active": net[0].replace(ph, ":") == "yes",
            "strength": atoi(net[1]),
            "frequency": atoi(net[2].split()[0] if net[2].strip() else "0"),
            "ssid": net[3].replace(ph, ":"),
            "bssid": net[4].replace(ph, ":"),
            "security": net[5].replace(ph, ":"),
        }
        ex = seen.get(e["ssid"])
        if ex is None or (e["active"] and not ex["active"]) or (not e["active"] and not ex["active"] and e["strength"] > ex["strength"]):
            seen[e["ssid"]] = e
    return list(seen.values())


def connect(ssid, password=""):
    if not ssid:
        return {"error": "missing ssid"}
    if password:
        subprocess.run(["nmcli", "connection", "modify", ssid, "wifi-sec.psk", password], capture_output=True)
    r = subprocess.run(["nmcli", "dev", "wifi", "connect", ssid], capture_output=True, text=True)
    if r.returncode != 0:
        out = r.stdout + r.stderr
        if "Secrets were required" in out:
            return {"need_password": True}
        return {"error": out.strip()}
    return snapshot()


def die_with_parent():
    try:
        import ctypes
        import signal
        ctypes.CDLL("libc.so.6").prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG
    except Exception:
        pass


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    args = sys.argv[2:]
    if cmd == "status":
        res = snapshot()
    elif cmd == "networks":
        res = networks()
    elif cmd == "enable":
        subprocess.run(["nmcli", "radio", "wifi", "on" if args and args[0] == "true" else "off"], capture_output=True)
        res = snapshot()
    elif cmd == "connect":
        res = connect(args[0] if args else "", args[1] if len(args) > 1 else "")
    elif cmd == "disconnect":
        if args and args[0]:
            subprocess.run(["nmcli", "connection", "down", args[0]], capture_output=True)
        res = snapshot()
    elif cmd == "monitor":
        # vtnc: die with the shell (the monitor never exits on its own), and take nmcli with us
        die_with_parent()
        print(json.dumps(snapshot()), flush=True)
        p = subprocess.Popen(["nmcli", "monitor"], stdout=subprocess.PIPE, text=True, preexec_fn=die_with_parent)
        for _ in p.stdout:
            print(json.dumps(snapshot()), flush=True)
        return
    else:
        res = {"error": "unknown command " + cmd}
    print(json.dumps(res))


if __name__ == "__main__":
    main()
