# 🔍 RAG (Retrieval-Augmented Generation)

Use your documents to augment AI responses with context from your knowledge base.

---

## What is RAG?

```
┌─────────────────────────────────────────────────────────────┐
│                      RAG Workflow                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 📄 Upload Documents                                     │
│       ↓                                                     │
│  2. 🔢 Embedding Model converts to vectors                  │
│       ↓                                                     │
│  3. 💾 Store in ChromaDB vector database                    │
│       ↓                                                     │
│  4. ❓ User asks question                                   │
│       ↓                                                     │
│  5. 🔍 Semantic search finds relevant chunks                │
│       ↓                                                     │
│  6. 🤖 LLM generates answer with context                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## How to Use RAG in Open WebUI

### Step 1: Access Knowledge Base

1. Open http://localhost:3000
2. Click on **Workspace** or **Knowledge** icon
3. Create a new knowledge base

### Step 2: Upload Documents

Supported formats:
- **PDF** - Research papers, reports
- **TXT** - Plain text
- **MD** - Markdown files
- **DOCX** - Word documents
- **CSV** - Tabular data

### Step 3: Chat with Your Documents

1. Select a knowledge base in the chat
2. Ask questions about your documents
3. The AI will cite sources

---

## Document Preparation Tips

### Good Documents for RAG

✅ Well-structured content
✅ Clear headings and sections
✅ Facts and references
✅ Code with comments
✅ FAQs and documentation

### Less Suitable

❌ Very short texts (<100 words)
❌ Images without alt text
❌ Scanned PDFs (need OCR)
❌ Noisy/unstructured data

### Optimization

```markdown
# Good Structure

## Introduction
[Clear intro paragraph]

## Main Topic
### Subsection A
[Content with examples]

### Subsection B
[More content]
```

---

## ChromaDB API

Access ChromaDB directly at http://localhost:8000

### Python Example

```python
import chromadb

# Connect to ChromaDB
client = chromadb.HttpClient(host='localhost', port=8000)

# Create collection
collection = client.create_collection("my-docs")

# Add documents
collection.add(
    documents=["Document text here"],
    metadatas=[{"source": "manual"}],
    ids=["doc1"]
)

# Query
results = collection.query(
    query_texts=["What is the topic?"],
    n_results=2
)
```

### JavaScript Example

```javascript
import { ChromaClient } from "chromadb";

const client = new ChromaClient({ path: "http://localhost:8000" });

const collection = await client.getOrCreateCollection("my-docs");

await collection.add({
    documents: ["Document text"],
    ids: ["1"]
});
```

---

## Embedding Models

ChromaDB uses embedding models to convert text to vectors.

### Default Embeddings

Open WebUI uses built-in embeddings:
- Fast, efficient
- Good quality for English
- 384 dimensions

### Custom Embeddings

Edit docker-compose.yml:

```yaml
chroma:
  environment:
    - EMBEDDING_MODEL=all-MiniLM-L6-v2
```

---

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

1. Check document format is supported
2. Verify documents were indexed
3. Try different search queries
4. Increase chunk size in settings

### Slow Performance

1. Use smaller embedding model
2. Reduce number of documents
3. Index in batches

---

## Best Practices

1. **Chunk Size**: 500-1000 tokens works well
2. **Overlap**: 10-20% overlap for context
3. **Metadata**: Add source, date, tags
4. **Quality**: Clean, structured documents
5. **Updates**: Re-index when documents change

---

## Security

### Disable Telemetry

```bash
# In .env
CHROMA_TELEMETRY=false
```

### Local Only

All data stays on your machine:
- No cloud upload
- No external API calls
- Complete privacy

---

## Resources

- [ChromaDB Docs](https://docs.trychroma.com/)
- [Open WebUI RAG](https://docs.openwebui.com/tutorials/rag/)
- [Embedding Models](https://www.sbert.net/)
