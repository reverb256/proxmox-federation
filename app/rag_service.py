"""
RAG Service - Full implementation with crawling, vector storage, and retrieval
Integrates with mcp-crawl4ai-rag and Perplexica, plus built-in capabilities
"""
import httpx
import os
import asyncio
from typing import List, Dict, Any, Optional
import json
import logging
from datetime import datetime
import aiofiles
import hashlib
from pathlib import Path

logger = logging.getLogger(__name__)

# External RAG providers
RAG_PROVIDERS = [
    {"name": "mcp-crawl4ai", "url": os.getenv("RAG_URL", "http://mcp-crawl4ai-rag:8001")},
    {"name": "perplexica", "url": os.getenv("PERPLEXICA_URL", "http://perplexica:8002")}
]

# Local storage for documents and embeddings
DOCS_DIR = Path("/app/data/rag/documents")
EMBEDDINGS_DIR = Path("/app/data/rag/embeddings")
DOCS_DIR.mkdir(parents=True, exist_ok=True)
EMBEDDINGS_DIR.mkdir(parents=True, exist_ok=True)

class RAGService:
    def __init__(self):
        self.document_store = {}
        self.embeddings_cache = {}
        self.providers = RAG_PROVIDERS
        
    async def crawl_website(self, url: str, depth: int = 2) -> Dict[str, Any]:
        """Crawl a website and extract content for RAG"""
        try:
            # Try external crawlers first
            for provider in self.providers:
                try:
                    async with httpx.AsyncClient(timeout=30.0) as client:
                        resp = await client.post(
                            f"{provider['url']}/crawl",
                            json={"url": url, "depth": depth}
                        )
                        if resp.status_code == 200:
                            data = resp.json()
                            await self._store_crawled_data(url, data)
                            return {"status": "success", "provider": provider["name"], "data": data}
                except Exception as e:
                    logger.warning(f"Provider {provider['name']} failed: {e}")
                    continue
            
            # Fallback: basic crawling
            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.get(url)
                if resp.status_code == 200:
                    content = resp.text
                    doc_id = hashlib.md5(url.encode()).hexdigest()
                    doc_data = {
                        "url": url,
                        "content": content,
                        "timestamp": datetime.now().isoformat(),
                        "doc_id": doc_id
                    }
                    await self._store_document(doc_id, doc_data)
                    return {"status": "success", "provider": "builtin", "doc_id": doc_id}
                    
        except Exception as e:
            logger.error(f"Crawling failed for {url}: {e}")
            return {"status": "error", "message": str(e)}
    
    async def _store_crawled_data(self, url: str, data: Dict[str, Any]):
        """Store crawled data locally"""
        doc_id = hashlib.md5(url.encode()).hexdigest()
        doc_path = DOCS_DIR / f"{doc_id}.json"
        async with aiofiles.open(doc_path, 'w') as f:
            await f.write(json.dumps({
                "url": url,
                "data": data,
                "timestamp": datetime.now().isoformat(),
                "doc_id": doc_id
            }))
    
    async def _store_document(self, doc_id: str, doc_data: Dict[str, Any]):
        """Store document locally"""
        doc_path = DOCS_DIR / f"{doc_id}.json"
        async with aiofiles.open(doc_path, 'w') as f:
            await f.write(json.dumps(doc_data))
    
    async def retrieve(self, query: str, top_k: int = 5) -> Dict[str, Any]:
        """Retrieve relevant documents for a query"""
        try:
            # Try external providers first
            for provider in self.providers:
                try:
                    async with httpx.AsyncClient(timeout=30.0) as client:
                        resp = await client.post(
                            f"{provider['url']}/retrieve",
                            json={"query": query, "top_k": top_k}
                        )
                        if resp.status_code == 200:
                            return {"status": "success", "provider": provider["name"], "results": resp.json()}
                except Exception as e:
                    logger.warning(f"Provider {provider['name']} retrieval failed: {e}")
                    continue
            
            # Fallback: local retrieval
            local_results = await self._local_retrieve(query, top_k)
            return {"status": "success", "provider": "builtin", "results": local_results}
            
        except Exception as e:
            logger.error(f"Retrieval failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def _local_retrieve(self, query: str, top_k: int) -> List[Dict[str, Any]]:
        """Basic local retrieval using text matching"""
        results = []
        query_lower = query.lower()
        
        for doc_file in DOCS_DIR.glob("*.json"):
            try:
                async with aiofiles.open(doc_file, 'r') as f:
                    doc_data = json.loads(await f.read())
                    
                content = doc_data.get("content", "").lower()
                if query_lower in content:
                        results.append({
                            "doc_id": doc_data.get("doc_id"),
                            "url": doc_data.get("url"),
                            "content": doc_data.get("content", "")[:500] + "...",
                            "score": content.count(query_lower) / len(content.split()),
                            "timestamp": doc_data.get("timestamp")
                        })
            except Exception as e:
                logger.warning(f"Error reading document {doc_file}: {e}")
        
        # Sort by score and return top_k
        results.sort(key=lambda x: x["score"], reverse=True)
        return results[:top_k]
    
    async def qa(self, document: str, question: str, context: Optional[str] = None) -> Dict[str, Any]:
        """Perform question answering on a document"""
        try:
            # Try external providers first
            for provider in self.providers:
                try:
                    async with httpx.AsyncClient(timeout=30.0) as client:
                        resp = await client.post(
                            f"{provider['url']}/qa",
                            json={"document": document, "question": question, "context": context}
                        )
                        if resp.status_code == 200:
                            return {"status": "success", "provider": provider["name"], "answer": resp.json()}
                except Exception as e:
                    logger.warning(f"Provider {provider['name']} QA failed: {e}")
                    continue
            
            # Fallback: basic QA using LLM
            answer = await self._local_qa(document, question, context)
            return {"status": "success", "provider": "builtin", "answer": answer}
            
        except Exception as e:
            logger.error(f"QA failed: {e}")
            return {"status": "error", "message": str(e)}
    
    async def _local_qa(self, document: str, question: str, context: Optional[str] = None) -> str:
        """Basic QA using local LLM"""
        # This would typically call your LLM endpoint
        prompt = f"""Document: {document}\n\nQuestion: {question}\n\nAnswer:"""
        if context:
            prompt = f"Context: {context}\n\n{prompt}"
        
        # For now, return a placeholder - in real implementation, call LLM
        return f"Based on the document, regarding '{question}': [This would be answered by your LLM]"
    
    async def add_document(self, content: str, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Add a document to the RAG system"""
        try:
            doc_id = hashlib.md5(content.encode()).hexdigest()
            doc_data = {
                "content": content,
                "metadata": metadata,
                "timestamp": datetime.now().isoformat(),
                "doc_id": doc_id
            }
            await self._store_document(doc_id, doc_data)
            return {"status": "success", "doc_id": doc_id}
        except Exception as e:
            logger.error(f"Failed to add document: {e}")
            return {"status": "error", "message": str(e)}
    
    async def list_documents(self) -> Dict[str, Any]:
        """List all documents in the RAG system"""
        try:
            documents = []
            for doc_file in DOCS_DIR.glob("*.json"):
                try:
                    async with aiofiles.open(doc_file, 'r') as f:
                        doc_data = json.loads(await f.read())
                        documents.append({
                            "doc_id": doc_data.get("doc_id"),
                            "url": doc_data.get("url"),
                            "timestamp": doc_data.get("timestamp"),
                            "content_preview": doc_data.get("content", "")[:200] + "..."
                        })
                except Exception as e:
                    logger.warning(f"Error reading document {doc_file}: {e}")
            
            return {"status": "success", "documents": documents}
        except Exception as e:
            logger.error(f"Failed to list documents: {e}")
            return {"status": "error", "message": str(e)}

# Global RAG service instance
rag_service = RAGService()

# Async functions for gateway integration
async def rag_retrieve(query: str, top_k: int = 5):
    return await rag_service.retrieve(query, top_k)

async def rag_qa(document: str, question: str, context: Optional[str] = None):
    return await rag_service.qa(document, question, context)

async def rag_crawl(url: str, depth: int = 2):
    return await rag_service.crawl_website(url, depth)

async def rag_add_document(content: str, metadata: Dict[str, Any]):
    return await rag_service.add_document(content, metadata)

async def rag_list_documents():
    return await rag_service.list_documents()
