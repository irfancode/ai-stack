# 📚 Model Guide

A guide to available models and how to use them in AI-Stack.

---

## Local Models (Ollama)

### Recommended Models

| Model | Size | RAM | Best For | Speed |
|-------|------|-----|----------|-------|
| **Llama 3.2** | 3B | 2GB | General use, fast responses | ~30 tok/s |
| **Llama 3.2** | 70B | 40GB | Highest quality, slower | ~8 tok/s |
| **Mistral** | 7B | 4GB | Balanced performance | ~20 tok/s |
| **Phi-3.5** | 3.8B | 2GB | Efficient, good quality | ~25 tok/s |
| **Codellama** | 7B | 4GB | Code generation | ~18 tok/s |

### Installing Models

```bash
# General purpose
ollama pull llama3.2

# Code generation
ollama pull codellama

# Scientific/math
ollama pull llama3.2-math

# Chinese support
ollama pull qwen2.5
```

### Apple Silicon Optimization

```bash
# List available models
ollama list

# Remove unused models
ollama rm <model-name>

# Show model info
ollama show llama3.2
```

---

## Cloud Models (OpenRouter)

### Popular Cloud Models

| Provider | Model | Context | Strengths |
|----------|-------|---------|-----------|
| **Anthropic** | Claude 3.5 Sonnet | 200K | Reasoning, coding |
| **Anthropic** | Claude 3 Opus | 200K | Complex tasks |
| **OpenAI** | GPT-4o | 128K | Multimodal |
| **OpenAI** | GPT-4 Turbo | 128K | Fast, capable |
| **Google** | Gemini 1.5 Pro | 1M | Long context |
| **Meta** | Llama 3.1 405B | 128K | Open, large |

### Getting API Keys

1. **OpenRouter** (recommended - unified access)
   - Visit: https://openrouter.ai/keys
   - Supports 100+ models with single API key

2. **Anthropic** (direct)
   - Visit: https://console.anthropic.com/
   - For Claude-specific features

3. **OpenAI** (direct)
   - Visit: https://platform.openai.com/api-keys

### Adding API Key

Edit `.env` file:

```bash
OPENROUTER_API_KEY=sk-or-v1-xxxxx
```

---

## Model Selection

### When to Use Local vs Cloud

| Task | Local | Cloud |
|------|-------|-------|
| Quick questions | ✅ | ✅ |
| Code generation | ✅ (Codellama) | ✅ (Claude/GPT) |
| Long documents | ❌ | ✅ |
| Privacy-sensitive | ✅ | ❌ |
| 24/7 availability | ✅ | ⚠️ (rate limits) |
| Cost | Free | Pay-per-use |

### Performance Tips

```bash
# Limit threads (if overheating)
OLLAMA_NUM_THREADS=4 ollama serve

# Limit memory
OLLAMA_NUM_PARALLEL=2 ollama serve

# Quick responses
ollama run llama3.2:3b "Your question"
```

---

## Model Parameters

### Temperature

- **0.0 - 0.3**: Focused, deterministic
- **0.4 - 0.7**: Balanced (recommended)
- **0.8 - 1.0**: Creative, varied

### Context Length

- **4K**: Short conversations
- **8K - 32K**: Medium documents
- **128K - 1M**: Long documents, RAG

### System Prompt

Customize behavior in Open WebUI:

```
You are a helpful coding assistant.
Always explain your reasoning.
Use code blocks for examples.
```
