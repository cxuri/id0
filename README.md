# 🧬 ID0 — Identity Zero v1.0

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-1.0-green.svg)
![Shell Script](https://img.shields.io/badge/Bash-5.x-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/yourusername/id0/pulls)
[![Maintenance](https://img.shields.io/badge/maintained-yes-success.svg)](https://github.com/yourusername/id0)

**ID0** (Identity Zero) is a **complete MAC address and hostname rotation system** for Linux, designed for privacy, security testing, and network identity obfuscation.  
It automatically rotates your network interface identity, updates system records, and maintains full compatibility with **NetworkManager**.

---

## ✨ Features

- 🔄 **MAC Address Rotation** — Randomized or fixed-interval identity changes.  
- 🧩 **Hostname Rotation** — Syncs `/etc/hosts` and renews DHCP leases automatically.  
- 🧹 **System Log Cleaning** — Keeps logs tidy between rotations.  
- 🧠 **NetworkManager Compatible** — Includes fix and status tools.  
- 🕒 **Custom Rotation Intervals** — Choose random or fixed timing.  
- 🧾 **Comprehensive Logging** — Track every change and event.

---

## ⚙️ Usage

```bash
./id0.sh [command] [interface] [minutes]
```

## Commands 
here are the available commands
| Command                | Description                                    | Requires sudo |
| ---------------------- | ---------------------------------------------- | ------------- |
| `start [iface] [mins]` | Start identity rotation (e.g. every 5 minutes) | ✅             |
| `revert [iface]`       | Revert to original identity                    | ✅             |
| `status`               | Show current status                            | ❌             |
| `backup`               | Backup current identity                        | ❌             |
| `interfaces`           | List available interfaces                      | ❌             |
| `fix-networkmanager`   | Apply NetworkManager compatibility fix         | ✅             |
| `nm-status`            | Show NetworkManager status                     | ❌             |
| `logs`                 | Show recent logs                               | ❌             |
| `random-test`          | Test random generators                         | ❌             |
| `help`                 | Show this help message                         | ❌             |

## Examples

```bash
sudo ./id0.sh start wlan0 5
# Starts rotating wlan0 identity every 5 minutes

sudo ./id0.sh fix-networkmanager
# Applies compatibility fix for NetworkManager

./id0.sh status
# Displays current identity rotation status

sudo ./id0.sh revert wlan0
# Restores the original MAC and hostname

```
