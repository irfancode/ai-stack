---
layout: post
title: "Getting Started with RAG: Chat with Your Documents"
date: 2026-02-01
categories: [tutorial, rag]
author: AI-Stack Team
---

One of the most powerful features of AI-Stack is **Retrieval-Augmented Generation (RAG)** — the ability to chat with your own documents. In this guide, we'll walk you through setting up and using RAG with your knowledge base.

## What is RAG?

RAG combines the power of large language models with your own documents. Instead of relying solely on a model's training data, RAG:

1. **Retrieves** relevant document chunks based on your query
2. **Augments** the prompt with this context
3. **Generates** accurate, grounded responses

```
┌─────────────────────────────────────────────────────────┐
│                      RAG Workflow                        │
├─────────────────────────────────────────────────────────┤
│  📄 Upload Documents                                     │
│       ↓                                                  │
│  🔢 Embedding Model converts to vectors                  │
│       ↓                                                  │
│  💾 Store in ChromaDB vector database                    │
│       ↓                                                  │
│  ❓ User asks question                                   │
│       ↓                                                  │
│  🔍 Semantic search finds relevant chunks               │
│       ↓                                                  │
│  🤖 LLM generates answer with context                    │
└─────────────────────────────────────────────────────────┘
```

## Setting Up RAG

### 1. Start with the Full Stack

```bash
./scripts/setup.sh
```

This starts Open WebUI with ChromaDB integration.

### 2. Access Open WebUI

Open [http://localhost:3000](http://localhost:3000) in your browser.

### 3. Create a Knowledge Base

1. Click on the **Workspace** or **Knowledge** icon
2. Create a new knowledge base
3. Upload your documents (PDF, TXT, MD, DOCX supported)

### 4. Chat with Your Documents

Select your knowledge base in the chat and start asking questions!

## Best Practices

### Document Preparation

✅ **Good documents for RAG:**
- Well-structured content with clear headings
- Factual information and references
- FAQs and documentation
- Code with comments

❌ **Less suitable:**
- Very short texts (<100 words)
- Scanned PDFs (need OCR)
- Noisy or unstructured data

### Optimization Tips

```markdown
# Optimal Document Structure

## Introduction
[Clear intro paragraph]

## Main Topic
### Subsection A
[Content with examples]

### Subsection B
[More content]
```

### Configuration

For advanced users, you can customize chunk size and overlap in Open WebUI settings. Recommended:
- **Chunk size**: 500-1000 tokens
- **Overlap**: 10-20% for context continuity

## Troubleshooting

### ChromaDB Connection Issues

```bash
# Check if ChromaDB is running
docker compose ps chroma

# View logs
docker compose logs chroma

# Restart
docker compose restart chroma
```

### Empty Results

1. Verify documents were indexed successfully
2. Try different search queries
3. Increase chunk size in settings

## Next Steps

Ready to explore more? Check out our [model guide](/docs/MODELS) for choosing the right model for your use case.

Happy chatting! 📚
