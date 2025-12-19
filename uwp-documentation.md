# 🚀 Universal Workspace Platform v5.0

**Kompletní profesionální vývojové prostředí**  
Podporuje: Linux, Android (Termux), WSL, Raspberry Pi, Docker

---

## 📦 Co je UWP?

Universal Workspace Platform je **all-in-one řešení** pro vývojáře, které automaticky detekuje váš systém a nainstaluje optimalizované vývojové prostředí včetně:

- 🤖 **AI asistent** - Ollama s LLM modely pro analýzu kódu
- 📱 **Android nástroje** - ADB, Fastboot, device management
- 🐳 **Docker** - Container management
- 💻 **Dev tools** - Git, Node.js, Python, TypeScript, atd.
- 🖥️ **Terminal** - Zsh s Oh My Zsh a pluginy
- 🌐 **Web GUI** - Moderní dashboard pro ovládání

---

## ⚡ Rychlá Instalace

### Krok 1: Stažení

```bash
# Curl metoda
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/uwp/main/install.sh | bash

# Nebo wget
wget -qO- https://raw.githubusercontent.com/YOUR_REPO/uwp/main/install.sh | bash

# Nebo manuální stažení
git clone https://github.com/YOUR_REPO/uwp.git
cd uwp
chmod +x install.sh
./install.sh
```

### Krok 2: Načtení prostředí

```bash
# Bash
source ~/.bashrc

# Zsh
source ~/.zshrc
```

### Krok 3: Ověření

```bash
uwp status
```

---

## 🎯 Podporované Platformy

| Platforma | Status | Poznámky |
|-----------|--------|----------|
| **Ubuntu/Debian** | ✅ Plná podpora | Vč. všech modulů |
| **Arch Linux** | ✅ Plná podpora | Pacman support |
| **Fedora/RHEL** | ✅ Plná podpora | DNF/YUM support |
| **Termux (Android)** | ✅ Plná podpora | Optimalizováno pro Android |
| **WSL (Windows)** | ✅ Plná podpora | Windows integration |
| **Raspberry Pi** | ✅ Plná podpora | ARM optimalizace |
| **Docker** | ✅ Plná podpora | Kontejnerová verze |
| **macOS** | ⚠️ Částečná | Homebrew support |

---

## 📚 Moduly

### 🤖 AI Workspace

**Co obsahuje:**
- Ollama server
- LLM modely (phi3:mini, llama3.2, codellama)
- LangChain
- Python AI knihovny (transformers, chromadb)

**Instalace:**
```bash
uwp modules install ai
```

**Použití:**
```bash
# Chat s AI
uwp ai "Explain this code"

# Analýza projektu
uwp analyze /path/to/project

# Spustit Ollama server
ollama serve
```

---

### 📱 Android Toolkit

**Co obsahuje:**
- ADB (Android Debug Bridge)
- Fastboot
- Udev pravidla pro device detection
- Pomocné skripty

**Instalace:**
```bash
uwp modules install android
```

**Použití:**
```bash
# Zobrazit připojená zařízení
adb devices

# Instalovat APK
adb install app.apk

# Screen capture
adb shell screencap -p /sdcard/screen.png
adb pull /sdcard/screen.png
```

---

### 🐳 Docker Environment

**Co obsahuje:**
- Docker Engine
- Docker Compose
- Container management

**Instalace:**
```bash
uwp modules install docker
```

**Použití:**
```bash
# Spustit container
docker run hello-world

# Compose
docker-compose up -d

# Seznam containerů
docker ps
```

---

### 💻 Development Tools

**Co obsahuje:**
- Git
- Node.js + npm
- Python 3 + pip
- TypeScript, ESLint, Prettier
- Build tools (gcc, make)

**Instalace:**
```bash
uwp modules install development
```

**Použití:**
```bash
# Node.js projekt
npm init -y
npm install express

# Python virtual env
python3 -m venv venv
source venv/bin/activate

# TypeScript projekt
npx tsc --init
```

---

### 🖥️ Terminal Configuration

**Co obsahuje:**
- Zsh shell
- Oh My Zsh
- Syntax highlighting
- Auto-suggestions
- Powerlevel10k theme

**Instalace:**
```bash
uwp modules install terminal
```

**Použití:**
```bash
# Změnit shell na Zsh
chsh -s $(which zsh)

# Konfigurace P10k
p10k configure
```

---

## 🎨 CLI Příkazy

### Status a Info

```bash
# Zobrazit status platformy
uwp status

# Seznam všech modulů
uwp modules list

# Verze
uwp --version
```

### Správa Modulů

```bash
# Instalovat modul
uwp modules install <module>

# Odinstalovat modul
uwp modules uninstall <module>

# Aktualizovat modul
uwp modules update <module>
```

### Konfigurace

```bash
# Zobrazit konfiguraci
uwp config get <key>

# Nastavit hodnotu
uwp config set <key> <value>

# Editovat config soubor
nano ~/.uwp/config/uwp.conf
```

### AI Nástroje

```bash
# Analýza projektu
uwp analyze .
uwp analyze /path/to/project

# Chat s AI
uwp ai "Vysvětli tento kód"
uwp ai "Jak optimalizovat tento algoritmus?"

# Generovat dokumentaci
uwp ai "Generate README for this project"
```

### Aktualizace

```bash
# Aktualizovat platformu
uwp update

# Zkontrolovat dostupné aktualizace
uwp update --check

# Aktualizovat konkrétní modul
uwp modules update ai
```

---

## 🌐 Web GUI

UWP obsahuje moderní webové rozhraní pro snadné ovládání.

### Spuštění

```bash
# Spustit Web GUI server
cd ~/.uwp
python3 -m http.server 8080

# Nebo přímo otevřít HTML
xdg-open ~/.uwp/web/index.html
```

### Přístup

Otevři v prohlížeči:
```
http://localhost:8080
```

### Funkce Web GUI

- 📊 **Dashboard** - Přehled systému a modulů
- 📦 **Module Manager** - Instalace/odinstalace modulů
- 🔍 **Code Analyzer** - AI analýza projektů
- 💬 **AI Chat** - Interaktivní AI asistent
- ⚙️ **Settings** - Konfigurace platformy
- 📝 **Logs** - Zobrazení logů

---

## 🛠️ Pokročilé Použití

### Automatická Instalace Modulů

Vytvoř soubor `uwp-modules.txt`:
```
ai
android
docker
development
terminal
```

Pak:
```bash
cat uwp-modules.txt | xargs -I {} uwp modules install {}
```

### Custom Skripty

Vytvoř vlastní skript v `~/.uwp/bin/`:
```bash
#!/usr/bin/env bash
source ~/.uwp/lib/uwp-core.sh

# Tvůj kód zde
uwp_info "Hello from custom script!"
```

### Integrace do CI/CD

```yaml
# .github/workflows/uwp.yml
name: UWP Analysis

on: [push]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install UWP
        run: curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/uwp/main/install.sh | bash
      
      - name: Analyze Code
        run: |
          source ~/.bashrc
          uwp modules install ai
          uwp analyze .
```

---

## 📁 Struktura Adresářů

```
~/.uwp/
├── bin/                    # CLI nástroje
│   └── uwp                # Hlavní CLI
├── config/                # Konfigurace
│   └── uwp.conf          # Hlavní config
├── data/                  # Uživatelská data
│   ├── projects/         # Projekty
│   ├── reports/          # Analýzy
│   ├── backups/          # Zálohy
│   └── ai-models/        # AI modely
├── lib/                   # Core knihovny
│   └── uwp-core.sh       # Hlavní knihovna
├── modules/               # Moduly
│   ├── ai/
│   ├── android/
│   ├── docker/
│   ├── development/
│   └── terminal/
├── plugins/               # Pluginy
├── logs/                  # Logy
│   ├── install_*.log
│   └── errors.log
├── cache/                 # Cache
├── templates/             # Šablony
└── web/                   # Web GUI
    └── index.html
```

---

## 🔧 Konfigurace

### Hlavní Config (`~/.uwp/config/uwp.conf`)

```bash
# UWP Configuration
version="5.0.0"
install_date="2025-01-20T10:30:00"
os="ubuntu"
arch="x86_64"

# Features
ai_enabled="true"
android_enabled="true"
docker_enabled="true"

# Paths
uwp_home="${HOME}/.uwp"
uwp_data="${HOME}/.uwp/data"
```

### Proměnné Prostředí

```bash
# Přidat do ~/.bashrc nebo ~/.zshrc
export UWP_HOME="${HOME}/.uwp"
export PATH="${UWP_HOME}/bin:${PATH}"

# Debug mode
export UWP_DEBUG=1

# Custom cache dir
export UWP_CACHE_DIR="/tmp/uwp-cache"
```

---

## 🐛 Troubleshooting

### Problem: `uwp: command not found`

**Řešení:**
```bash
# Reload shell
source ~/.bashrc
# nebo
source ~/.zshrc

# Nebo přidat do PATH manuálně
export PATH="$HOME/.uwp/bin:$PATH"
```

### Problem: Modul se nenainstaluje

**Řešení:**
```bash
# Zkontroluj logy
cat ~/.uwp/logs/install_*.log
cat ~/.uwp/logs/errors.log

# Zkus znovu s debug režimem
UWP_DEBUG=1 uwp modules install <module>
```

### Problem: AI nefunguje

**Řešení:**
```bash
# Zkontroluj Ollama
which ollama

# Nainstaluj Ollama manuálně
curl -fsSL https://ollama.ai/install.sh | sh

# Stáhni model
ollama pull phi3:mini
```

### Problem: Permission denied

**Řešení:**
```bash
# Oprav oprávnění
chmod +x ~/.uwp/bin/*
chmod +x ~/.uwp/modules/*/install.sh

# Pro systémové instalace použij sudo
sudo uwp modules install docker
```

---

## 📊 Příklady Použití

### 1. Analýza React Projektu

```bash
# Nainstaluj AI modul
uwp modules install ai

# Analyzuj projekt
cd ~/projects/my-react-app
uwp analyze .

# Zobraz report
cat ~/.uwp/data/reports/analysis_*.md
```

### 2. Android Development Setup

```bash
# Nainstaluj Android modul
uwp modules install android

# Připoj zařízení
adb devices

# Instaluj APK
adb install my-app.apk

# Logcat
adb logcat
```

### 3. Docker Workflow

```bash
# Nainstaluj Docker modul
uwp modules install docker

# Vytvoř Dockerfile
cat > Dockerfile << 'EOF'
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
CMD ["npm", "start"]
EOF

# Build image
docker build -t my-app .

# Run container
docker run -p 3000:3000 my-app
```

### 4. AI Assisted Development

```bash
# Zeptej se AI
uwp ai "How to implement JWT authentication in Node.js?"

# Code review
uwp ai "Review this code for security issues: $(cat app.js)"

# Generate tests
uwp ai "Generate unit tests for this function: $(cat utils.js)"
```

---

## 🔄 Aktualizace

### Automatická Aktualizace

```bash
uwp update
```

### Manuální Aktualizace

```bash
cd ~/.uwp
git pull origin main

# Spusť update skript
bash scripts/update.sh
```

### Co se aktualizuje?

- ✅ Core knihovny
- ✅ CLI nástroje
- ✅ Moduly
- ✅ Web GUI
- ✅ Dokumentace
- ⚠️ Uživatelská data a konfigurace zůstávají nedotčena

---

## 🗑️ Odinstalace

### Kompletní odinstalace

```bash
# Smazat všechno
rm -rf ~/.uwp

# Odstranit z PATH (edituj ~/.bashrc nebo ~/.zshrc)
# Smaž řádky obsahující UWP_HOME
```

### Zachovat uživatelská data

```bash
# Zálohuj data
cp -r ~/.uwp/data ~/uwp-backup

# Smaž instalaci
rm -rf ~/.uwp

# Obnov data po reinstalaci
cp -r ~/uwp-backup ~/.uwp/data
```

---

## 🤝 Přispívání

### Nahlášení Chyby

1. Zkontroluj [Issues](https://github.com/YOUR_REPO/uwp/issues)
2. Vytvoř nový issue s:
   - Popis problému
   - Kroky k reprodukci
   - System info (`uwp status`)
   - Logy (`cat ~/.uwp/logs/errors.log`)

### Pull Requesty

1. Fork repository
2. Vytvoř feature branch (`git checkout -b feature/amazing`)
3. Commit změny (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Otevři Pull Request

---

## 📝 Changelog

### v5.0.0 (2025-01-20)

**Nové funkce:**
- ✨ Kompletně přepsaná architektura
- ✨ Modulární systém
- ✨ Web GUI dashboard
- ✨ AI code analyzer
- ✨ Pokročilá detekce systému
- ✨ Podpora více platforem

**Vylepšení:**
- 🚀 Rychlejší instalace
- 🚀 Lepší error handling
- 🚀 Detailnější logging
- 🚀 Optimalizované pro Termux

**Opravy:**
- 🐛 Fixed path issues on Android
- 🐛 Fixed permission problems
- 🐛 Fixed module dependencies

---

## 📄 Licence

MIT License - volně použitelné pro osobní i komerční účely.

---

## 🌟 Poděkování

Děkujeme všem přispěvatelům a komunitě za podporu!

**Special Thanks:**
- Ollama team za AI modely
- Oh My Zsh komunita
- Docker team
- Android Open Source Project

---

## 📞 Podpora

- **GitHub Issues**: https://github.com/YOUR_REPO/uwp/issues
- **Documentation**: https://uwp.dev/docs
- **Discord**: https://discord.gg/uwp
- **Email**: support@uwp.dev

---

## 🎓 Další Zdroje

- [Video Tutorial](https://youtube.com/uwp-tutorial)
- [Blog](https://uwp.dev/blog)
- [FAQ](https://uwp.dev/faq)
- [API Docs](https://uwp.dev/api)

---

<div align="center">

**Made with ❤️ for developers**

[⭐ Star on GitHub](https://github.com/YOUR_REPO/uwp) • [🐛 Report Bug](https://github.com/YOUR_REPO/uwp/issues) • [💡 Request Feature](https://github.com/YOUR_REPO/uwp/issues)

</div>