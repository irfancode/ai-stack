# 🎨 AI-Stack

> A powerful, containerized AI interface infrastructure for local LLM experimentation

<p align="center">
  <img src="https://img.shields.io/badge/Docker-Container-blue?style=for-the-badge&logo=docker"/>
  <img src="https://img.shields.io/badge/Open%20WebUI-Web%20Interface-purple?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Ollama-LLM%20Backend-green?style=for-the-badge&logo=ollama"/>
  <img src="https://img.shields.io/badge/ChromaDB-Vector%20Store-orange?style=for-the-badge"/>
</p>

---

## ✨ Features

- **🌐 Open WebUI** - Beautiful chat interface for LLM interaction
- **🧠 Ollama Integration** - Run local LLMs with privacy
- **☁️ OpenRouter API** - Access cloud models (Claude, GPT-4, etc.)
- **📚 RAG Ready** - Vector database for retrieval-augmented generation
- **🔐 Authentication** - Optional user auth with API key management
- **💾 Persistent Storage** - All data persists across restarts
- **🍎 Apple Silicon** - Optimized for M1/M2/M3 Macs

---

## 🚀 Quick Start

### Prerequisites

- macOS (Apple Silicon recommended)
- [OrbStack](https://orbstack.dev/) or Docker Desktop
- [Ollama](https://ollama.ai/) (optional, for local models)

### One-Command Setup

```bash
git clone https://github.com/irfancode/ai-stack.git ~/ai-stack
cd ~/ai-stack && ./scripts/setup.sh
```

### Manual Setup

```bash
# 1. Start Ollama (in background)
ollama serve &

# 2. Pull a model (optional)
ollama pull llama3.2

# 3. Start services
docker compose up -d

# 4. Open browser
open http://localhost:3000
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         macOS Host                               │
│                                                                 │
│   ┌─────────────┐                                               │
│   │   Ollama    │  Local LLM inference                         │
│   │   :11434    │  ollama pull llama3.2                        │
│   └──────┬──────┘                                               │
│          │                                                      │
│   ┌──────┴──────┐         ┌──────────────────────────────┐   │
│   │  OrbStack   │         │   Docker Network              │   │
│   │  (Docker)   │         │                              │   │
│   │             │         │  ┌────────────────────────┐  │   │
│   │             │         │  │    Open WebUI         │  │   │
│   │             │◄────────┼──│    :8080 → :3000      │  │   │
│   │             │         │  │                       │  │   │
│   │             │         │  └────────────────────────┘  │   │
│   │             │         │                              │   │
│   │             │         │  ┌────────────────────────┐  │   │
│   │             │         │  │    ChromaDB           │  │   │
│   │             │◄────────┼──│    Vector Store        │  │   │
│   │             │         │  │    :8000              │  │   │
│   │             │         │  └────────────────────────┘  │   │
│   └─────────────┘         └──────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

User → http://localhost:3000 → Chat with LLMs
```

---

## 📦 Services

### Open WebUI (Port 3000)

Beautiful chat interface with:
- Chat with local Ollama models
- Access cloud models via OpenRouter
- File upload and image analysis
- RAG with ChromaDB
- Model management
- Conversation history

### Ollama (Port 11434)

Local LLM runtime:
- Privacy-first inference
- No data leaves your machine
- Multiple model support
- Fast Apple Silicon optimized

### ChromaDB (Port 8000)

Vector database for RAG:
- Document embeddings
- Semantic search
- Retrieval-augmented generation
- Knowledge base management

---

## 🔧 Configuration

### Environment Variables

Edit `.env` file:

```bash
# OpenRouter API Key (for cloud models)
OPENROUTER_API_KEY=your-api-key-here

# Optional: Custom Ollama URL
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

### Docker Compose Services

| Service | Port | Description |
|---------|------|-------------|
| `openwebui` | 3000 | Web chat interface |
| `chroma` | 8000 | Vector database |

---

## 🛠️ Usage

### Start Services

```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d openwebui

# Start with logs visible
docker compose up
```

### Stop Services

```bash
# Stop all services
docker compose down

# Stop and remove volumes
docker compose down -v
```

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f openwebui
```

### Access Services

| Service | URL |
|---------|-----|
| Open WebUI | http://localhost:3000 |
| ChromaDB | http://localhost:8000 |
| Ollama API | http://localhost:11434 |

---

## 📚 Adding Models

### Local Models (Ollama)

```bash
# Pull a model
ollama pull llama3.2
ollama pull mistral
ollama pull codellama

# List available models
ollama list

# Run a model
ollama run llama3.2
```

### Cloud Models (OpenRouter)

1. Get API key from https://openrouter.ai/keys
2. Add to `.env` file
3. Models auto-appear in Open WebUI

---

## 🔐 Security

### Enable Authentication

Edit `docker-compose.yml`:

```yaml
environment:
  - WEBUI_AUTH=true
  - ADMIN_EMAIL=admin@example.com
  - ADMIN_PASSWORD=your-secure-password
```

### Recommended Security Steps

1. ✅ Use strong `ADMIN_PASSWORD`
2. ✅ Don't commit `.env` to git
3. ✅ Use firewall rules for production
4. ✅ Enable HTTPS with reverse proxy

---

## 📊 Model Performance

### Apple Silicon (M1/M2/M3)

| Model | Parameters | Speed | RAM |
|-------|------------|-------|-----|
| Llama 3.2 | 3B | ~30 tok/s | 2GB |
| Mistral | 7B | ~20 tok/s | 4GB |
| Llama 3.2 | 70B | ~8 tok/s | 40GB |

---

## 🐛 Troubleshooting

### Open WebUI not connecting to Ollama

```bash
# Ensure Ollama is running
ollama serve

# Check if Ollama is accessible
curl http://localhost:11434
```

### ChromaDB connection issues

```bash
# Check ChromaDB is running
docker compose ps chroma

# View ChromaDB logs
docker compose logs chroma
```

### Out of memory

```bash
# Use smaller models
ollama pull llama3.2:3b

# Run with limited threads
OLLAMA_NUM_THREADS=4 ollama serve
```

---

## 📝 File Structure

```
ai-stack/
├── README.md              # This file
├── .env                   # Environment variables (API keys)
├── .gitignore             # Git ignore rules
├── docker-compose.yml     # Service definitions
├── scripts/
│   └── setup.sh          # Installation script
└── docs/
    ├── MODELS.md          # Model guide
    └── RAG.md            # RAG setup guide
```

---

## 🤝 Contributing

Contributions welcome! Open issues or PRs.

---

## 📄 License

MIT License

---

<p align="center">
  Built with ❤️ for AI enthusiasts
</p>
