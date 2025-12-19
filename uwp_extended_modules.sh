################################################################################
# Extended Modules for Universal Workspace Platform v4.0
# 5 Additional feature modules: Pentest, Emulators, System, Web GUI, Security
################################################################################

################################################################################
# MODULE 1: Penetration Testing Module - modules/pentest/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="pentest"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Pentest] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Penetration Testing module..."

mkdir -p "${MODULE_DIR}/scripts"
mkdir -p "${MODULE_DIR}/tools"
mkdir -p "${MODULE_DIR}/wordlists"

# Install security tools
log_info "Installing security analysis tools..."

TOOLS="curl wget git netcat-openbsd nmap tcpdump"

if command -v apt-get &>/dev/null; then
    apt-get update &>/dev/null || true
    apt-get install -y $TOOLS &>/dev/null || true
elif command -v dnf &>/dev/null; then
    dnf install -y $TOOLS &>/dev/null || true
elif command -v pacman &>/dev/null; then
    pacman -S --noconfirm $TOOLS &>/dev/null || true
fi

# Security scanning script
cat > "${MODULE_DIR}/scripts/port-scan.sh" << 'PORT_SCRIPT'
#!/usr/bin/env bash
TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo "Usage: port-scan.sh <target>"
    exit 1
fi

echo "Scanning ports on: $TARGET"
if command -v nmap &>/dev/null; then
    nmap -sV "$TARGET"
else
    echo "nmap not installed"
fi
PORT_SCRIPT
chmod +x "${MODULE_DIR}/scripts/port-scan.sh"

# Vulnerability checker
cat > "${MODULE_DIR}/scripts/vuln-check.sh" << 'VULN_SCRIPT'
#!/usr/bin/env bash
PROJECT="${1:-.}"

echo "Checking for common vulnerabilities in: $PROJECT"
echo ""

# Check for hardcoded secrets
echo "[*] Scanning for hardcoded secrets..."
grep -r "password\|secret\|api_key\|token" "$PROJECT" --include="*.js" --include="*.py" --include="*.sh" 2>/dev/null | head -10 || echo "No obvious secrets found"

# Check file permissions
echo "[*] Checking file permissions..."
find "$PROJECT" -type f -perm 0777 2>/dev/null | head -5 || echo "No world-writable files found"

# Check for SQL injection patterns
echo "[*] Checking for SQL patterns..."
grep -r "SELECT.*FROM\|INSERT INTO\|UPDATE.*SET" "$PROJECT" --include="*.py" --include="*.js" 2>/dev/null | head -5 || echo "No SQL patterns found"

echo "[*] Scan complete"
VULN_SCRIPT
chmod +x "${MODULE_DIR}/scripts/vuln-check.sh"

# Network analysis script
cat > "${MODULE_DIR}/scripts/network-info.sh" << 'NET_SCRIPT'
#!/usr/bin/env bash
echo "=== Network Information ==="
echo ""
echo "Network Interfaces:"
ip addr show 2>/dev/null || ifconfig

echo ""
echo "Listening Ports:"
netstat -tlnp 2>/dev/null | grep LISTEN || ss -tlnp 2>/dev/null | grep LISTEN

echo ""
echo "DNS Configuration:"
cat /etc/resolv.conf 2>/dev/null | grep nameserver || echo "DNS info unavailable"

echo ""
echo "Routing Table:"
ip route 2>/dev/null || route
NET_SCRIPT
chmod +x "${MODULE_DIR}/scripts/network-info.sh"

touch "${MODULE_DIR}/.installed"
log_success "Penetration Testing module installed"

################################################################################
# MODULE 2: Emulators Module - modules/emulators/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="emulators"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Emulators] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Emulators module..."

mkdir -p "${MODULE_DIR}/scripts"
mkdir -p "${MODULE_DIR}/configs"
mkdir -p "${MODULE_DIR}/roms"

# Install emulation tools
log_info "Installing emulation tools..."

if command -v apt-get &>/dev/null; then
    apt-get install -y qemu libvirt-daemon-system virt-manager 2>/dev/null || true
elif command -v dnf &>/dev/null; then
    dnf install -y qemu libvirt virt-manager 2>/dev/null || true
fi

# VM management script
cat > "${MODULE_DIR}/scripts/vm-list.sh" << 'VM_SCRIPT'
#!/usr/bin/env bash
echo "Available Virtual Machines:"

if command -v virsh &>/dev/null; then
    virsh list --all
else
    echo "Libvirt not installed"
fi

echo ""
echo "QEMU Processes:"
ps aux | grep qemu | grep -v grep || echo "No QEMU VMs running"
VM_SCRIPT
chmod +x "${MODULE_DIR}/scripts/vm-list.sh"

# Create VM script
cat > "${MODULE_DIR}/scripts/create-vm.sh" << 'CREATE_VM'
#!/usr/bin/env bash
VM_NAME="${1:-test-vm}"
OS="${2:-ubuntu}"
SIZE="${3:-20}"

echo "Creating VM: $VM_NAME"
echo "OS: $OS"
echo "Size: ${SIZE}GB"

# Create disk image
qemu-img create -f qcow2 "/tmp/${VM_NAME}.qcow2" "${SIZE}G" 2>/dev/null || echo "qemu-img not available"

echo "VM image created at /tmp/${VM_NAME}.qcow2"
CREATE_VM
chmod +x "${MODULE_DIR}/scripts/create-vm.sh"

# Android emulator setup
cat > "${MODULE_DIR}/scripts/android-emu.sh" << 'ANDROID_EMU'
#!/usr/bin/env bash
if command -v emulator &>/dev/null; then
    echo "Android Emulator available"
    emulator -list-avds
else
    echo "Android SDK/Emulator not installed"
    echo "Install Android SDK for emulator support"
fi
ANDROID_EMU
chmod +x "${MODULE_DIR}/scripts/android-emu.sh"

touch "${MODULE_DIR}/.installed"
log_success "Emulators module installed"

################################################################################
# MODULE 3: System Monitor Module - modules/sysmon/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="sysmon"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[SysMon] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing System Monitor module..."

mkdir -p "${MODULE_DIR}/scripts"
mkdir -p "${MODULE_DIR}/reports"

# Install monitoring tools
if command -v apt-get &>/dev/null; then
    apt-get install -y htop iotop sysstat dstat 2>/dev/null || true
fi

# System health check script
cat > "${MODULE_DIR}/scripts/health-check.sh" << 'HEALTH_SCRIPT'
#!/usr/bin/env bash
echo "╔════════════════════════════════════════════╗"
echo "║       System Health Check Report            ║"
echo "╚════════════════════════════════════════════╝"
echo ""

echo "[CPU]"
uptime
nproc --all 2>/dev/null || echo "CPU cores: $(grep -c ^processor /proc/cpuinfo)"
echo ""

echo "[MEMORY]"
free -h
echo ""

echo "[DISK]"
df -h | head -5
echo ""

echo "[PROCESSES]"
ps aux | wc -l
echo "Top 5 processes by memory:"
ps aux --sort=-%mem | head -6 | tail -5
echo ""

echo "[NETWORK]"
netstat -i 2>/dev/null || ss -i
echo ""

echo "[SYSTEM LOG ERRORS]"
dmesg | tail -5 || echo "Cannot read dmesg"
HEALTH_SCRIPT
chmod +x "${MODULE_DIR}/scripts/health-check.sh"

# Performance monitoring script
cat > "${MODULE_DIR}/scripts/perf-monitor.sh" << 'PERF_SCRIPT'
#!/usr/bin/env bash
INTERVAL="${1:-5}"
DURATION="${2:-60}"

echo "Performance Monitoring (${DURATION}s, refresh every ${INTERVAL}s)"
echo ""

if command -v dstat &>/dev/null; then
    dstat -tcms --disk --net --top-mem --top-cpu -T --output /tmp/perf_report.csv $INTERVAL $((DURATION/INTERVAL))
    echo "Report saved to /tmp/perf_report.csv"
elif command -v htop &>/dev/null; then
    htop
else
    watch -n $INTERVAL 'free -h && echo "---" && top -bn1 | head -20'
fi
PERF_SCRIPT
chmod +x "${MODULE_DIR}/scripts/perf-monitor.sh"

# Security audit script
cat > "${MODULE_DIR}/scripts/security-audit.sh" << 'SECURITY_SCRIPT'
#!/usr/bin/env bash
echo "=== Security Audit Report ==="
echo ""

echo "[Users & Groups]"
echo "Active users:"
who
echo ""
echo "Sudo users:"
getent group sudo | cut -d: -f4
echo ""

echo "[Firewall]"
if command -v ufw &>/dev/null; then
    ufw status
else
    iptables -L 2>/dev/null | head -10 || echo "Firewall status unavailable"
fi
echo ""

echo "[Failed Login Attempts]"
tail -20 /var/log/auth.log 2>/dev/null | grep "Failed" || echo "No failed attempts in recent logs"
echo ""

echo "[Open Ports]"
netstat -tlnp 2>/dev/null || ss -tlnp | head -10
SECURITY_SCRIPT
chmod +x "${MODULE_DIR}/scripts/security-audit.sh"

touch "${MODULE_DIR}/.installed"
log_success "System Monitor module installed"

################################################################################
# MODULE 4: Web GUI Dashboard - modules/webui/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="webui"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[WebUI] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Web GUI Dashboard module..."

mkdir -p "${MODULE_DIR}/public"
mkdir -p "${MODULE_DIR}/server"

# Install Flask if Python available
if command -v python3 &>/dev/null; then
    python3 -m pip install --quiet flask flask-cors 2>/dev/null || true
fi

# Create Flask server
cat > "${MODULE_DIR}/server/app.py" << 'FLASK_APP'
#!/usr/bin/env python3
from flask import Flask, jsonify, render_template, request
from flask_cors import CORS
import subprocess
import os
import json
from datetime import datetime

app = Flask(__name__)
CORS(app)

UWP_HOME = os.environ.get('UWP_HOME', os.path.expanduser('~/.universal-workspace'))

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/status')
def status():
    try:
        result = subprocess.run([f'{UWP_HOME}/bin/uwp', 'status'], 
                              capture_output=True, text=True, timeout=5)
        return jsonify({'status': 'ok', 'data': result.stdout})
    except Exception as e:
        return jsonify({'status': 'error', 'error': str(e)}), 500

@app.route('/api/modules')
def modules():
    try:
        result = subprocess.run([f'{UWP_HOME}/bin/uwp', 'modules', 'list'], 
                              capture_output=True, text=True, timeout=5)
        return jsonify({'status': 'ok', 'data': result.stdout})
    except Exception as e:
        return jsonify({'status': 'error', 'error': str(e)}), 500

@app.route('/api/system')
def system_info():
    import psutil
    try:
        return jsonify({
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory': {
                'total': psutil.virtual_memory().total,
                'available': psutil.virtual_memory().available,
                'percent': psutil.virtual_memory().percent
            },
            'disk': {
                'total': psutil.disk_usage('/').total,
                'free': psutil.disk_usage('/').free,
                'percent': psutil.disk_usage('/').percent
            }
        })
    except:
        return jsonify({'error': 'psutil not installed'}), 500

@app.route('/api/ai', methods=['POST'])
def ai_chat():
    data = request.json
    prompt = data.get('prompt', '')
    
    try:
        result = subprocess.run(['ollama', 'run', 'phi3:mini', prompt], 
                              capture_output=True, text=True, timeout=30)
        return jsonify({'status': 'ok', 'response': result.stdout})
    except Exception as e:
        return jsonify({'status': 'error', 'error': str(e)}), 500

@app.route('/api/logs')
def get_logs():
    try:
        log_dir = f'{UWP_HOME}/logs'
        logs = {}
        for f in os.listdir(log_dir)[:5]:
            with open(os.path.join(log_dir, f), 'r') as file:
                logs[f] = file.readlines()[-20:]
        return jsonify({'logs': logs})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
FLASK_APP
chmod +x "${MODULE_DIR}/server/app.py"

# Create HTML dashboard
cat > "${MODULE_DIR}/public/index.html" << 'HTML_DASH'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UWP Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            background: linear-gradient(135deg, #0f172a 0%, #1a1f3a 100%);
            color: #e2e8f0;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding: 20px;
        }
        .container { max-width: 1400px; margin: 0 auto; }
        header {
            text-align: center;
            margin-bottom: 40px;
            border-bottom: 2px solid #60a5fa;
            padding-bottom: 20px;
        }
        h1 { color: #60a5fa; font-size: 2.5em; }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: rgba(30, 41, 59, 0.8);
            border: 1px solid #334155;
            border-radius: 8px;
            padding: 20px;
            transition: all 0.3s ease;
        }
        .card:hover {
            border-color: #60a5fa;
            box-shadow: 0 0 20px rgba(96, 165, 250, 0.2);
        }
        .card h2 { color: #60a5fa; margin-bottom: 15px; }
        button {
            background: #3b82f6;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            width: 100%;
            margin-top: 10px;
        }
        button:hover { background: #2563eb; }
        #output {
            background: rgba(15, 23, 42, 0.8);
            border: 1px solid #334155;
            border-radius: 5px;
            padding: 15px;
            min-height: 200px;
            overflow-y: auto;
            max-height: 400px;
            font-family: monospace;
            font-size: 0.9em;
        }
        .stat { display: flex; justify-content: space-between; margin: 10px 0; }
        .stat-label { color: #cbd5e1; }
        .stat-value { color: #60a5fa; font-weight: bold; }
        .progress-bar {
            background: #334155;
            border-radius: 3px;
            height: 8px;
            overflow: hidden;
            margin: 5px 0;
        }
        .progress-fill {
            background: #10b981;
            height: 100%;
            transition: width 0.3s;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 UWP Dashboard</h1>
            <p>Universal Workspace Platform Control Center</p>
        </header>

        <div class="grid">
            <div class="card">
                <h2>📊 System Status</h2>
                <button onclick="loadStatus()">Refresh</button>
                <div id="status"></div>
            </div>

            <div class="card">
                <h2>⚙️ System Resources</h2>
                <button onclick="loadSystem()">Refresh</button>
                <div id="system"></div>
            </div>

            <div class="card">
                <h2>🧩 Modules</h2>
                <button onclick="loadModules()">Refresh</button>
                <div id="modules"></div>
            </div>

            <div class="card">
                <h2>🤖 AI Assistant</h2>
                <input type="text" id="prompt" placeholder="Ask AI..." style="width:100%; padding:8px; margin-bottom:10px;">
                <button onclick="sendAI()">Send</button>
                <div id="ai-response"></div>
            </div>
        </div>

        <div class="card">
            <h2>📝 Output</h2>
            <div id="output">Ready...</div>
        </div>
    </div>

    <script>
        async function loadStatus() {
            try {
                const res = await fetch('/api/status');
                const data = await res.json();
                document.getElementById('status').innerHTML = 
                    `<pre>${data.data || data.error}</pre>`;
            } catch(e) {
                document.getElementById('status').innerHTML = `Error: ${e}`;
            }
        }

        async function loadSystem() {
            try {
                const res = await fetch('/api/system');
                const data = await res.json();
                let html = `
                    <div class="stat">
                        <span class="stat-label">CPU:</span>
                        <span class="stat-value">${data.cpu_percent}%</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${data.cpu_percent}%"></div>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Memory:</span>
                        <span class="stat-value">${data.memory.percent}%</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${data.memory.percent}%"></div>
                    </div>
                    <div class="stat">
                        <span class="stat-label">Disk:</span>
                        <span class="stat-value">${data.disk.percent}%</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${data.disk.percent}%"></div>
                    </div>
                `;
                document.getElementById('system').innerHTML = html;
            } catch(e) {
                document.getElementById('system').innerHTML = `Error: ${e}`;
            }
        }

        async function loadModules() {
            try {
                const res = await fetch('/api/modules');
                const data = await res.json();
                document.getElementById('modules').innerHTML = 
                    `<pre>${data.data || data.error}</pre>`;
            } catch(e) {
                document.getElementById('modules').innerHTML = `Error: ${e}`;
            }
        }

        async function sendAI() {
            const prompt = document.getElementById('prompt').value;
            if (!prompt) return;
            
            document.getElementById('ai-response').innerHTML = 'Thinking...';
            try {
                const res = await fetch('/api/ai', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ prompt })
                });
                const data = await res.json();
                document.getElementById('ai-response').innerHTML = 
                    `<p>${data.response || data.error}</p>`;
            } catch(e) {
                document.getElementById('ai-response').innerHTML = `Error: ${e}`;
            }
        }

        // Load on startup
        loadStatus();
        loadSystem();
        loadModules();
        setInterval(loadSystem, 5000);
    </script>
</body>
</html>
HTML_DASH

# Create startup script
cat > "${MODULE_DIR}/scripts/start-dashboard.sh" << 'START_DASH'
#!/usr/bin/env bash
PORT="${1:-5000}"
echo "Starting UWP Dashboard on port $PORT"
echo "Access at: http://localhost:$PORT"
python3 "${UWP_HOME}/modules/webui/server/app.py"
START_DASH
chmod +x "${MODULE_DIR}/scripts/start-dashboard.sh"

touch "${MODULE_DIR}/.installed"
log_success "Web GUI Dashboard module installed"

################################################################################
# MODULE 5: Security Hardening - modules/security/install.sh
################################################################################

#!/usr/bin/env bash
set -euo pipefail

MODULE_NAME="security"
MODULE_DIR="${UWP_HOME}/modules/${MODULE_NAME}"

log_info() { echo "[Security] $*"; }
log_success() { echo "✓ $*"; }

log_info "Installing Security Hardening module..."

mkdir -p "${MODULE_DIR}/scripts"
mkdir -p "${MODULE_DIR}/policies"

# SSH hardening script
cat > "${MODULE_DIR}/scripts/harden-ssh.sh" << 'HARDEN_SSH'
#!/usr/bin/env bash
SSH_CONFIG="/etc/ssh/sshd_config"

if [[ ! -w "$SSH_CONFIG" ]]; then
    echo "Need root access to modify SSH config"
    exit 1
fi

echo "Hardening SSH configuration..."

# Backup original
cp "$SSH_CONFIG" "${SSH_CONFIG}.backup"

# Apply hardening
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
sed -i 's/#X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"
sed -i 's/#AllowAgentForwarding.*/AllowAgentForwarding no/' "$SSH_CONFIG"

systemctl restart ssh || systemctl restart sshd

echo "SSH hardening complete. Backup: ${SSH_CONFIG}.backup"
HARDEN_SSH
chmod +x "${MODULE_DIR}/scripts/harden-ssh.sh"

# File permission checker
cat > "${MODULE_DIR}/scripts/check-perms.sh" << 'CHECK_PERMS'
#!/usr/bin/env bash
echo "=== File Permission Security Check ==="
echo ""

echo "[Critical Files - Should be 644 or less]"
ls -la /etc/passwd /etc/shadow /etc/group /etc/gshadow 2>/dev/null | awk '{print $1, $9}'

echo ""
echo "[SUID Binaries - Review for security]"
find / -perm -4000 -type f 2>/dev/null | head -20

echo ""
echo "[World-Writable Directories]"
find / -type d -perm -002 ! -path '*/proc/*' ! -path '*/sys/*' 2>/dev/null | head -10

echo ""
echo "[Suspicious Scripts in Home]"
find ~ -type f -name "*.sh" -perm -100 2>/dev/null || echo "None found"
CHECK_PERMS
chmod +x "${MODULE_DIR}/scripts/check-perms.sh"

# Firewall setup script
cat > "${MODULE_DIR}/scripts/setup-firewall.sh" << 'FIREWALL_SCRIPT'
#!/usr/bin/env bash
if [[ $EUID -ne 0 ]]; then
    echo "Firewall setup requires root"
    exit 1
fi

echo "Setting up firewall..."

if command -v ufw &>/dev/null; then
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    echo "y" | ufw enable
    echo "Firewall enabled with ufw"
elif command -v firewalld &>/dev/null; then
    systemctl enable firewalld
    systemctl start firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    echo "Firewall enabled with firewalld"
else
    echo "No firewall tool available"
fi
FIREWALL_SCRIPT
chmod +x "${MODULE_DIR}/scripts/setup-firewall.sh"

# Password policy script
cat > "${MODULE_DIR}/scripts/password-policy.sh" << 'PWD_POLICY'
#!/usr/bin/env bash
echo "=== Password Security Policy ==="
echo ""

if [[ -f /etc/login.defs ]]; then
    echo "Current password settings:"
    grep -E "^PASS_MAX_DAYS|^PASS_MIN_DAYS|^PASS_WARN_AGE" /etc/login.defs
fi

echo ""
echo "Recommended settings:"
echo "PASS_MAX_DAYS=90"
echo "PASS_MIN_DAYS=1"
echo "PASS_WARN_AGE=14"
echo ""
echo "To apply, edit /etc/login.defs as root"
PWD_POLICY
chmod +x "${MODULE_DIR}/scripts/password-policy.sh"

touch "${MODULE_DIR}/.installed"
log_success "Security Hardening module installed"
