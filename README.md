# 🎨 AI-Stack

> A lean, local AI interface infrastructure - optimized for 8GB systems

<p align="center">
  <img src="https://img.shields.io/badge/Docker-Container-blue?style=for-the-badge&logo=docker"/>
  <img src="https://img.shields.io/badge/Open%20WebUI-Web%20Interface-purple?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Ollama-LLM%20Backend-green?style=for-the-badge&logo=ollama"/>
  <img src="https://img.shields.io/badge/ChromaDB-Vector%20Store-orange?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/CLI-Terminal-red?style=for-the-badge&logo=terminal"/>
</p>

---

## ✨ Three Ways to Interact

| Mode | RAM Usage | Best For | Start Command |
|------|-----------|----------|---------------|
| **Terminal** | ~50MB | Quick tasks, CLI power users | `./scripts/local.sh` |
| **Simple Web** | ~200MB | Lightweight browser chat | `./scripts/web-simple.sh` |
| **Full WebUI** | ~2-3GB | Visual chat, RAG, uploads | `./scripts/web.sh` |

---

## 🚀 Quick Start

### Prerequisites

- macOS (Apple Silicon recommended)
- [OrbStack](https://orbstack.dev/) or Docker Desktop
- [Ollama](https://ollama.ai/)

### Setup (One Command)

```bash
git clone https://github.com/irfan-ai/ai-stack.git
cd ai-stack
./scripts/setup-lean.sh  # Downloads models
./scripts/setup.sh       # Starts services
```

### Choose Your Interface

```bash
# Option 1: Terminal Mode (Leanest - ~50MB RAM)
./scripts/local.sh

# Option 2: Simple Web UI (Lightweight - ~200MB RAM, No Docker)
./scripts/web-simple.sh

# Option 3: Full Web UI (Complete - ~2-3GB RAM)
./scripts/web.sh
```

---

## 🛠️ Management Tools

### Validate Configuration
```bash
./scripts/validate.sh    # Check prerequisites and config
```

### Health Monitoring
```bash
./scripts/health.sh      # Single health check
./scripts/health.sh -w   # Continuous monitoring
```

### Backup & Restore
```bash
./scripts/backup.sh       # Create backup
./scripts/backup.sh -l    # List backups
./scripts/backup.sh -r backup.tar.gz  # Restore
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         macOS Host                               │
│                                                                 │
│   ┌─────────────┐                                               │
│   │   Ollama    │  Local LLM inference                         │
│   │   :11434    │                                               │
│   └──────┬──────┘                                               │
│          │                                                      │
│   ┌──────┴──────┐         ┌──────────────────────────────┐   │
│   │  OrbStack   │         │   Docker Network              │   │
│   │  (Docker)   │         │                              │   │
│   │             │         │  ┌────────────────────────┐  │   │
│   │             │         │  │    Open WebUI         │  │   │
│   │             │◄────────┼──│    :3000             │  │   │
│   │             │         │  └────────────────────────┘  │   │
│   │             │         │                              │   │
│   │             │         │  ┌────────────────────────┐  │   │
│   │             │◄────────┼──│    ChromaDB           │  │   │
│   │             │         │  │    :8000              │  │   │
│   │             │         │  └────────────────────────┘  │   │
│   └─────────────┘         └──────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
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

Edit `.env` file (copy from `.env.example`):

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

## 🛡️ Security Features

### Built-in Protections

- **Secure password generation** on first setup
- **Port conflict detection** prevents service conflicts
- **Config validation** checks for security issues
- **Dry-run mode** on all scripts for safe testing
- **Telemetry disabled** by default (ChromaDB)

### Security Best Practices

1. ✅ Use `openssl rand -base64 24` to generate strong passwords
2. ✅ Never commit `.env` to git (already in .gitignore)
3. ✅ Use firewall rules for production deployments
4. ✅ Enable HTTPS with reverse proxy for production

---

## 📚 Adding Models

### Local Models (Ollama)

```bash
# Pull a model
ollama pull llama3.2:3b
ollama pull mistral
ollama pull codellama

# List available models
ollama list

# Run a model
ollama run llama3.2:3b
```

### Cloud Models (OpenRouter)

1. Get API key from https://openrouter.ai/keys
2. Add to `.env` file
3. Models auto-appear in Open WebUI

---

## 🔋 Lean Mode (8GB Optimization)

### Recommended Models for 8GB M1

| Model | Size | Best For | Speed |
|-------|------|----------|-------|
| `llama3.2:3b` | ~2GB | General chat (recommended) | ~30 tok/s |
| `qwen3:1b` | ~1.2GB | Quick tasks, scripts | ~50 tok/s |
| `phi3:3.8b-mini-q4` | ~2.4GB | Better quality | ~25 tok/s |

### Environment Optimizations

Added to `~/.zshrc`:
```bash
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_CTX_SIZE=2048
export OLLAMA_KEEP_ALIVE=15m
export OLLAMA_FLASH_ATTENTION=1
```

---

## 📊 Performance Comparison

| Setup | RAM Usage | Container Size |
|-------|-----------|----------------|
| Terminal (ollama run) | ~50MB | N/A |
| Simple Web Chat | ~200MB | 32MB |
| Open WebUI | ~2-3GB | 6GB |

### Apple Silicon (M1/M2/M3)

| Model | Parameters | Speed | RAM |
|-------|------------|-------|-----|
| Llama 3.2 | 3B | ~30 tok/s | 2GB |
| Mistral | 7B | ~20 tok/s | 4GB |
| Llama 3.2 | 70B | ~8 tok/s | 40GB |

---

## 🐛 Troubleshooting

### Quick Diagnostics

```bash
# Validate your configuration
./scripts/validate.sh

# Check service health
./scripts/health.sh
```

### Common Issues

**Open WebUI not connecting to Ollama**

```bash
# Ensure Ollama is running
ollama serve

# Check if Ollama is accessible
curl http://localhost:11434
```

**ChromaDB connection issues**

```bash
# Check ChromaDB is running
docker compose ps chroma

# View ChromaDB logs
docker compose logs chroma

# Restart
docker compose restart chroma
```

**Out of memory**

```bash
# Use smaller models
ollama pull llama3.2:3b

# Run with limited threads
OLLAMA_NUM_THREADS=4 ollama serve
```

---

## 📁 File Structure

```
ai-stack/
├── README.md              # This file
├── .env                   # Environment variables (API keys)
├── .env.example           # Environment template
├── .gitignore             # Git ignore rules
├── docker-compose.yml     # Full WebUI (6GB)
├── docker-compose.lean.yml # Lightweight WebUI options
├── scripts/
│   ├── setup.sh          # Full setup (Docker)
│   ├── setup-lean.sh     # Lean setup + models
│   ├── local.sh          # Terminal mode
│   ├── web.sh            # Web UI mode
│   ├── web-simple.sh     # Simple HTML chat (no Docker)
│   ├── health.sh         # Health monitoring
│   ├── backup.sh         # Backup & restore
│   └── validate.sh       # Configuration validation
└── docs/
    ├── index.html        # GitHub Pages documentation
    ├── MODELS.md         # Model guide
    ├── RAG.md           # RAG setup guide
    └── _posts/          # Blog posts
```

---

## 🌐 Documentation

Live documentation: **https://irfan-ai.github.io/ai-stack/**

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
