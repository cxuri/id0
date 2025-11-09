# 🦎 ID0 — Identity Zero v1.0 👻

![ID0 Banner](assets/banner.png)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-1.0-green.svg)
![Shell Script](https://img.shields.io/badge/Bash-5.x-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/yourusername/id0/pulls)
[![Maintenance](https://img.shields.io/badge/maintained-yes-success.svg)](https://github.com/yourusername/id0)

---

> **ID0 (Identity Zero)** is a **complete MAC address and hostname rotation system** for Linux — built for privacy, security testing, and anonymous networking.  
> It automatically rotates network interface identities, updates `/etc/hosts`, cleans logs, and ensures full **NetworkManager compatibility**.

---

## 🌟 Overview

ID0 helps you manage and rotate your **digital identity** at the system level — offering complete control over:

- 🔄 **MAC Address Randomization**
- 🧩 **Hostname Rotation with DHCP Renewal**
- 🧹 **System Log Cleaning**
- 🧠 **NetworkManager Fix & Integration**
- 🕒 **Fixed or Random Intervals**
- 📜 **Detailed Logging and Backup**

Perfect for **penetration testers**, **privacy researchers**, and **network engineers**.

---

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/id0.git

# Navigate into the folder
cd id0

# Make the script executable
chmod +x id0.sh
```
---

## ⚙️ Usage
./id0.sh [command] [interface] [minutes]

---
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

## Quick Start

```bash
# Backup your current network identity
./id0.sh backup

# Start rotation on wlan0 every 5 minutes
sudo ./id0.sh start wlan0 5

# View current rotation status
./id0.sh status

# Revert to your original identity
sudo ./id0.sh revert wlan0
```

## 🧭 Commands

Here are the available commands and their descriptions:

| Command | Description | Requires sudo |
|----------|--------------|---------------|
| `start [iface] [mins]` | Start identity rotation (e.g. every 5 minutes) | ✅ |
| `revert [iface]` | Revert to original identity | ✅ |
| `status` | Show current status | ❌ |
| `backup` | Backup current identity | ❌ |
| `interfaces` | List available interfaces | ❌ |
| `fix-networkmanager` | Apply NetworkManager compatibility fix | ✅ |
| `nm-status` | Show NetworkManager status | ❌ |
| `logs` | Show recent logs | ❌ |
| `random-test` | Test random generators | ❌ |
| `help` | Show this help message | ❌ |

---

## 🖼️ Screenshots

| Action | Description |
|--------|--------------|
| ![Start Example](assets/start.png) | **Starting rotation** on wlan0 with a 5-minute interval |
| ![Status Example](assets/status.png) | **Viewing current rotation status** with dynamic hostname |
| ![Logs Example](assets/logs.png) | **Inspecting logs** of identity changes |

> 🧩 _You can add your screenshots in the `assets/` folder to match the paths above._

---

## 🧰 Requirements

| Dependency | Purpose |
|-------------|----------|
| **Linux OS** | Required platform |
| **bash (5.x+)** | Shell interpreter |
| **sudo** | To modify network identities |
| **NetworkManager** *(optional)* | For managed network interfaces |

---

## 🧠 Tips & Best Practices

- Use **fixed intervals** for predictable rotation timing (e.g. `5` minutes).  
- Use **random intervals** for stealth mode (feature planned for v1.1).  
- Always **backup** before testing new rotations.  
- Combine with VPN/Tor for layered anonymity.

---

## ⚠️ Disclaimer

**ID0 is intended for educational, privacy, and ethical security research only.**  
Do **not** use it to disguise illegal activity or access networks without authorization.  
Use responsibly and in compliance with local laws.

---

## 🧾 License

**MIT License © 2025 — [Your Name or Organization]**

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction.

---

## 🌐 Project Links

- 📘 **Documentation:** [docs/](docs/)
- 🧾 **Change Log:** [CHANGELOG.md](CHANGELOG.md)
- 🐛 **Report Issues:** [GitHub Issues](https://github.com/yourusername/id0/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/yourusername/id0/discussions)

---

## 💡 Quote

> “Privacy is not about hiding — it’s about **choosing what to reveal**.”  
> — *Anonymous Researcher, 2025*

---

### 🧬 Identity Zero — Because your identity deserves rotation.
