#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# AI-Stack - Ultra Lightweight Web UI (No Docker)
# Serves a single HTML file - uses zero Docker, minimal RAM
# Access: http://localhost:8080
# ═══════════════════════════════════════════════════════════════════════════════

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

DRY_RUN=false
PORT=8080

usage() {
    cat << EOF
${BOLD}AI-Stack - Simple Web UI (No Docker)${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    -p, --port PORT   Port to serve on (default: 8080)
    -d, --dry-run     Show what would be done
    -h, --help        Show this help

${BOLD}EXAMPLES:${NC}
    $0                  # Start on default port 8080
    $0 -p 3000          # Start on port 3000
    $0 -d               # Dry run

EOF
    exit 0
}

log_info() { echo -e "${CYAN}→${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port) PORT="$2"; shift 2 ;;
        -d|--dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}AI-Stack - Simple Web UI (No Docker)${NC}               ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"

# Check Ollama
if ! curl -sf --max-time 2 http://localhost:11434/api/version > /dev/null 2>&1; then
    if [[ "$DRY_RUN" == true ]]; then
        log_info "Would start Ollama daemon"
    else
        log_warning "Ollama not running, starting..."
        ollama serve > /dev/null 2>&1 &
        sleep 3
    fi
else
    log_success "Ollama running"
fi

if [[ "$DRY_RUN" == true ]]; then
    log_info "Would serve chat UI on port $PORT"
    log_info "Would open: http://localhost:$PORT"
    exit 0
fi

# Use AI-Stack temp directory for HTML file
HTML_DIR="${HOME}/.ai-stack"
mkdir -p "$HTML_DIR"
HTML_FILE="${HTML_DIR}/chat.html"

# Create beautiful chat HTML
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI-Stack Chat</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --bg-primary: #0f0f1a;
            --bg-secondary: #1a1a2e;
            --bg-tertiary: #16213e;
            --accent: #00d9ff;
            --accent-hover: #00b8d4;
            --text-primary: #eee;
            --text-secondary: #888;
            --border: #333;
            --user-bg: #0f3460;
            --assistant-bg: #16213e;
        }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; 
            background: var(--bg-primary); 
            color: var(--text-primary); 
            height: 100vh; 
            display: flex; 
            flex-direction: column; 
        }
        .header { 
            background: var(--bg-tertiary); 
            padding: 15px 20px; 
            display: flex; 
            align-items: center; 
            gap: 15px; 
            border-bottom: 1px solid var(--border); 
        }
        .header h1 { font-size: 1.2rem; color: var(--accent); }
        .header .logo { font-size: 1.5rem; }
        select, button { padding: 8px 12px; border: none; border-radius: 6px; cursor: pointer; }
        select { background: var(--user-bg); color: #fff; }
        button { background: var(--accent); color: var(--bg-primary); font-weight: bold; }
        button:hover { background: var(--accent-hover); }
        button:disabled { background: #555; cursor: not-allowed; }
        .chat { 
            flex: 1; 
            overflow-y: auto; 
            padding: 20px; 
            display: flex; 
            flex-direction: column; 
            gap: 15px; 
        }
        .message { 
            max-width: 80%; 
            padding: 12px 16px; 
            border-radius: 12px; 
            line-height: 1.5; 
            white-space: pre-wrap; 
            word-wrap: break-word;
            animation: fadeIn 0.3s ease;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .user { align-self: flex-end; background: var(--user-bg); }
        .assistant { align-self: flex-start; background: var(--assistant-bg); border: 1px solid var(--border); }
        .input-area { 
            padding: 15px 20px; 
            background: var(--bg-tertiary); 
            display: flex; 
            gap: 10px; 
            border-top: 1px solid var(--border); 
        }
        textarea { 
            flex: 1; 
            padding: 12px; 
            border: 1px solid var(--border); 
            border-radius: 8px; 
            background: var(--bg-primary); 
            color: #fff; 
            resize: none; 
            font-family: inherit; 
            font-size: 14px; 
        }
        textarea:focus { outline: 2px solid var(--accent); border-color: transparent; }
        .status { font-size: 12px; color: var(--text-secondary); }
        .loading { display: flex; align-items: center; gap: 8px; }
        .loading span { width: 8px; height: 8px; background: var(--accent); border-radius: 50%; animation: bounce 1.4s infinite ease-in-out both; }
        .loading span:nth-child(1) { animation-delay: -0.32s; }
        .loading span:nth-child(2) { animation-delay: -0.16s; }
        @keyframes bounce { 0%, 80%, 100% { transform: scale(0); } 40% { transform: scale(1); } }
    </style>
</head>
<body>
    <div class="header">
        <span class="logo">🤖</span>
        <h1>AI-Stack Chat</h1>
        <select id="model"><option value="llama3.2:3b">llama3.2:3b</option></select>
        <span class="status" id="status">Ready</span>
    </div>
    <div class="chat" id="chat"></div>
    <div class="input-area">
        <textarea id="input" rows="2" placeholder="Ask something..." onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();send()}"></textarea>
        <button id="send" onclick="send()">Send</button>
    </div>
    <script>
        const chat = document.getElementById('chat');
        const input = document.getElementById('input');
        const sendBtn = document.getElementById('send');
        const status = document.getElementById('status');
        const modelSelect = document.getElementById('model');
        let streaming = false;

        fetch('http://localhost:11434/api/tags').then(r=>r.json()).then(d=>{
            modelSelect.innerHTML = '';
            d.models.forEach(m => {
                const opt = document.createElement('option');
                opt.value = m.name;
                opt.textContent = m.name;
                if (m.name.includes('llama3.2')) opt.selected = true;
                modelSelect.appendChild(opt);
            });
        }).catch(()=>status.textContent='Ollama offline');

        function addMessage(role, content) {
            const div = document.createElement('div');
            div.className = 'message ' + role;
            div.textContent = content;
            chat.appendChild(div);
            chat.scrollTop = chat.scrollHeight;
            return div;
        }

        function setLoading(loading) {
            const existing = document.querySelector('.loading');
            if (loading && !existing) {
                const loader = document.createElement('div');
                loader.className = 'message assistant loading';
                loader.id = 'loader';
                loader.innerHTML = '<span></span><span></span><span></span>';
                chat.appendChild(loader);
            } else if (!loading && existing) {
                existing.remove();
            }
        }

        async function send() {
            if(streaming) return;
            const text = input.value.trim();
            if(!text) return;
            addMessage('user', text);
            input.value = '';
            streaming = true;
            sendBtn.disabled = true;
            status.textContent = 'Thinking...';
            setLoading(true);

            const model = modelSelect.value;
            try {
                const response = await fetch('http://localhost:11434/api/chat', {
                    method: 'POST',
                    headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({model, messages:[{role:'user',content:text}], stream:true})
                });

                setLoading(false);
                const reader = response.body.getReader();
                const decoder = new TextDecoder();
                const msgDiv = addMessage('assistant', '');
                let buffer = '';

                while(true) {
                    const {done, value} = await reader.read();
                    if(done) break;
                    buffer += decoder.decode(value, {stream: true});
                    const lines = buffer.split('\n');
                    buffer = lines.pop();
                    
                    for(const line of lines) {
                        if(line.trim()) {
                            try {
                                const data = JSON.parse(line);
                                if(data.message?.content) {
                                    msgDiv.textContent += data.message.content;
                                    chat.scrollTop = chat.scrollHeight;
                                }
                            } catch(e) {}
                        }
                    }
                }
            } catch(e) {
                setLoading(false);
                addMessage('assistant', 'Error: ' + e.message);
            }

            chat.scrollTop = chat.scrollHeight;
            streaming = false;
            sendBtn.disabled = false;
            status.textContent = 'Ready';
        }
    </script>
</body>
</html>
HTMLEOF

echo ""
log_info "Starting simple web server..."
echo ""
log_success "Open: http://localhost:${PORT}"
echo -e "Press ${YELLOW}Ctrl+C${NC} to stop"
echo ""

# Kill any existing server on port
lsof -ti:${PORT} 2>/dev/null | xargs kill 2>/dev/null || true

# Start Python HTTP server
cd "$HTML_DIR" && python3 -m http.server "$PORT"
