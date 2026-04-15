---
layout: post
title: "Introducing AI-Stack: Your Private AI Infrastructure"
date: 2026-01-15
categories: [announcement, setup]
author: AI-Stack Team
---

Welcome to **AI-Stack** — a lean, local AI interface infrastructure designed for privacy-conscious users who want the power of large language models without sacrificing their data.

## Why AI-Stack?

In an era where AI assistants are increasingly cloud-based, we believe in putting **you** in control. AI-Stack lets you run powerful language models entirely on your hardware, with multiple interface options to match your workflow.

### Key Benefits

- **🔒 Complete Privacy**: Your conversations never leave your machine
- **🍎 Apple Silicon Optimized**: Native performance on M1, M2, M3 chips
- **📊 Resource Efficient**: Choose configurations from 50MB to 3GB RAM
- **🐳 Containerized**: Docker-based for easy deployment and reproducibility

## Quick Start

```bash
# Clone the repository
git clone https://github.com/irfan-ai/ai-stack.git
cd ai-stack

# Run lean setup (downloads models)
./scripts/setup-lean.sh

# Start the full stack
./scripts/setup.sh
```

## Choose Your Interface

| Mode | RAM | Best For |
|------|-----|----------|
| Terminal | ~50MB | Quick tasks, CLI power users |
| Simple Web | ~200MB | Lightweight browsing |
| Full WebUI | ~2-3GB | Complete RAG experience |

## What's Next?

In upcoming posts, we'll dive deeper into:
- Setting up RAG with your documents
- Optimizing model performance
- Advanced configuration options

Stay tuned! 🚀
