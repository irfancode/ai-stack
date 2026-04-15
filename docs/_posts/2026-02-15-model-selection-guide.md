---
layout: post
title: "Model Selection Guide: Choosing the Right LLM"
date: 2026-02-15
categories: [tutorial, models]
author: AI-Stack Team
---

Selecting the right language model is crucial for balancing performance, quality, and resource usage. This guide helps you choose the best model for your hardware and use case.

## Understanding Model Parameters

### Parameter Count

| Size | Memory | Best For |
|------|--------|----------|
| 1-3B | ~1-2GB | Quick tasks, constrained hardware |
| 7B | ~4GB | General purpose, balanced |
| 13B+ | ~8GB+ | Higher quality, needs more RAM |

### Quantization

Quantized models use less memory with minimal quality loss:
- **Q4**: ~60% memory reduction, good quality
- **Q8**: ~40% memory reduction, better quality
- **FP16**: Full precision, uses more memory

## Recommended Models for 8GB RAM

### llama3.2:3b ⭐ Recommended

```
Size: ~2GB
Speed: ~30 tokens/s
Best For: General chat, everyday tasks
```

Perfect balance of quality and resource usage for 8GB systems.

### qwen3:1b

```
Size: ~1.2GB
Speed: ~50 tokens/s
Best For: Quick tasks, scripting, constrained environments
```

Fastest option, ideal for rapid iteration.

### phi3:3.8b-mini

```
Size: ~2.4GB
Speed: ~25 tokens/s
Best For: Better reasoning, coding tasks
```

Higher quality when you need more capability.

## Apple Silicon Performance

| Model | M1 Speed | M2 Speed | M3 Speed |
|-------|----------|----------|----------|
| llama3.2:3b | ~30 t/s | ~40 t/s | ~50 t/s |
| qwen3:1b | ~50 t/s | ~65 t/s | ~80 t/s |
| phi3:3.8b-mini | ~25 t/s | ~35 t/s | ~45 t/s |

## Environment Optimization

For optimal performance, add these to your `~/.zshrc`:

```bash
# Limit loaded models to save memory
export OLLAMA_MAX_LOADED_MODELS=1

# Single request at a time
export OLLAMA_NUM_PARALLEL=1

# Context window size
export OLLAMA_CTX_SIZE=2048

# Model keep alive time
export OLLAMA_KEEP_ALIVE=15m

# Enable flash attention (faster)
export OLLAMA_FLASH_ATTENTION=1
```

## Downloading Models

```bash
# Pull a model
ollama pull llama3.2:3b

# List available models
ollama list

# Remove a model
ollama rm model-name
```

## Use Case Recommendations

### General Chat
→ `llama3.2:3b` or `mistral:7b`

### Code Generation
→ `codellama:7b` or `phi3:3.8b-mini`

### Fast Tasks
→ `qwen3:1b` or `llama3.2:1b`

### Long Documents
→ `llama3.2:3b` with increased `OLLAMA_CTX_SIZE`

## Questions?

Feel free to open an issue on GitHub or start a discussion!
