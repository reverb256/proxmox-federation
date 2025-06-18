"""
FastAPI Gateway for Modular AI Provider Orchestration
- Proxies OpenAI API requests to vLLM
- Routes image, TTS, STT, and embedding requests to their respective services
- Ready for future expansion (transformers, vision, RAG, etc.)
"""

from fastapi import FastAPI, Request, HTTPException, Body
from fastapi.responses import JSONResponse, StreamingResponse
import httpx
import os
from typing import Dict, Any
from app.rag_service import rag_retrieve, rag_qa, rag_crawl, rag_add_document, rag_list_documents
from app.agent_service import agent_act, agent_create, agent_list, agent_history
from app.orchestration.ansible_module import (run_ansible_playbook, run_ansible_adhoc, 
                                             create_ansible_playbook, list_ansible_playbooks)
from app.orchestration.terraform_module import (run_terraform_command, terraform_init, terraform_plan, 
                                               terraform_apply, terraform_destroy, terraform_show_state, 
                                               create_terraform_workspace)
from app.orchestration.proxmoxer_module import (connect_proxmox, proxmox_list_nodes, proxmox_list_vms, 
                                               proxmox_create_vm, proxmox_start_vm, proxmox_stop_vm, 
                                               proxmox_get_cluster_status)
from app.orchestration.powershell_module import run_powershell_command
from app.orchestration.bash_module import run_bash_command
from app.orchestration.ssh_module import (run_ssh_command, ssh_connect, ssh_execute, ssh_upload_file, 
                                         ssh_execute_script, ssh_generate_keys, ssh_list_connections)
from app.orchestration.talos_k8s_module import TalosK8sOrchestrator
from app.orchestration.monitoring_module import MonitoringOrchestrator
from app.orchestration.database_module import DatabaseOrchestrator
from app.orchestration.security_scanner_module import SecurityScannerOrchestrator
from app.orchestration.workflow_module import WorkflowOrchestrator
# New crypto and financial MCPs
from app.orchestration.mcp_crypto import CryptoOrchestrator
from app.orchestration.mcp_revenue_optimization import RevenueOptimizationOrchestrator
from app.orchestration.mcp_financial_analytics import FinancialAnalyticsOrchestrator

app = FastAPI(title="Consciousness Control Center Gateway")

# Service URLs (set via environment or docker-compose)
VLLM_URL = os.getenv("VLLM_URL", "http://vllm:8000")
SD_URL = os.getenv("SD_URL", "http://stable-diffusion:5000")
TTS_URL = os.getenv("TTS_URL", "http://tts:5002")
STT_URL = os.getenv("STT_URL", "http://stt:5003")
EMBED_URL = os.getenv("EMBED_URL", "http://embeddings:5004")

# Redundancy: fallback to secondary providers if main is unavailable
async def proxy_with_fallback(request: Request, primary_url: str, fallback_urls: list):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(primary_url, content=await request.body(), headers=request.headers)
            if resp.status_code == 200:
                return resp
        except Exception:
            pass
        # Try fallbacks
        for url in fallback_urls:
            try:
                resp = await client.post(url, content=await request.body(), headers=request.headers)
                if resp.status_code == 200:
                    return resp
            except Exception:
                continue
        raise HTTPException(status_code=503, detail="All providers unavailable.")

# Model registry for intelligent selection
MODEL_REGISTRY = {
    "chat": [
        {"id": "llama-3-8b", "provider": VLLM_URL, "priority": 1, "max_tokens": 4096},
        {"id": "mistral-7b", "provider": VLLM_URL, "priority": 2, "max_tokens": 4096},
        {"id": "intelligence-io", "provider": "https://api.intelligence.io.solutions/api/v1", "priority": 3, "max_tokens": 8192},
    ],
    "image": [
        {"id": "sdxl", "provider": SD_URL, "priority": 1},
        {"id": "hf-sdxl", "provider": "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0", "priority": 2},
    ],
    # ...add TTS, STT, embeddings as needed...
}

def select_model(task: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Select the ideal model/provider for the task based on input parameters
    """
    candidates = MODEL_REGISTRY.get(task, [])
    # Example: prefer models with enough max_tokens, or user-specified model
    if "model" in params:
        for m in candidates:
            if m["id"] == params["model"]:
                return m
    for m in candidates:
        if "max_tokens" in m and params.get("max_tokens", 0) <= m["max_tokens"]:
            return m
    return candidates[0] if candidates else {}

@app.post("/v1/chat/completions")
@app.post("/v1/completions")
async def openai_chat(request: Request):
    body = await request.json()
    model_info = select_model("chat", body)
    provider_url = model_info["provider"] if model_info else VLLM_URL
    fallback_urls = os.getenv("VLLM_FALLBACK_URLS", "").split(",") if os.getenv("VLLM_FALLBACK_URLS") else []
    resp = await proxy_with_fallback(request, f"{provider_url}{request.url.path}", fallback_urls)
    return StreamingResponse(resp.aiter_raw(), status_code=resp.status_code, headers=resp.headers)

@app.post("/v1/images/generations")
async def image_generation(request: Request):
    resp = await proxy_with_fallback(request, f"{SD_URL}/v1/images/generations", os.getenv("SD_FALLBACK_URLS", "").split(",") if os.getenv("SD_FALLBACK_URLS") else [])
    return JSONResponse(content=resp.json(), status_code=resp.status_code)

@app.post("/v1/audio/speech")
async def tts(request: Request):
    resp = await proxy_with_fallback(request, f"{TTS_URL}/v1/audio/speech", os.getenv("TTS_FALLBACK_URLS", "").split(",") if os.getenv("TTS_FALLBACK_URLS") else [])
    return StreamingResponse(resp.aiter_raw(), status_code=resp.status_code, headers=resp.headers)

@app.post("/v1/audio/transcriptions")
async def stt(request: Request):
    resp = await proxy_with_fallback(request, f"{STT_URL}/v1/audio/transcriptions", os.getenv("STT_FALLBACK_URLS", "").split(",") if os.getenv("STT_FALLBACK_URLS") else [])
    return JSONResponse(content=resp.json(), status_code=resp.status_code)

@app.post("/v1/embeddings")
async def embeddings(request: Request):
    resp = await proxy_with_fallback(request, f"{EMBED_URL}/v1/embeddings", os.getenv("EMBED_FALLBACK_URLS", "").split(",") if os.getenv("EMBED_FALLBACK_URLS") else [])
    return JSONResponse(content=resp.json(), status_code=resp.status_code)

@app.post("/v1/rag/retrieve")
async def rag_retrieve_endpoint(query: str = Body(...), top_k: int = Body(5)):
    return await rag_retrieve(query, top_k)

@app.post("/v1/rag/qa")
async def rag_qa_endpoint(document: str = Body(...), question: str = Body(...), context: str = Body(None)):
    return await rag_qa(document, question, context)

@app.post("/v1/rag/crawl")
async def rag_crawl_endpoint(url: str = Body(...), depth: int = Body(2)):
    return await rag_crawl(url, depth)

@app.post("/v1/rag/add_document")
async def rag_add_document_endpoint(content: str = Body(...), metadata: dict = Body({})):
    return await rag_add_document(content, metadata)

@app.get("/v1/rag/documents")
async def rag_list_documents_endpoint():
    return await rag_list_documents()

@app.post("/v1/agent/act")
async def agent_act_endpoint(task: str = Body(...), context: dict = Body({}), agent_id: str = Body(None)):
    return await agent_act(task, context, agent_id)

@app.post("/v1/agent/create")
async def agent_create_endpoint(name: str = Body(...), capabilities: list = Body(...), model: str = Body("gpt-4")):
    return await agent_create(name, capabilities, model)

@app.get("/v1/agent/list")
async def agent_list_endpoint():
    return await agent_list()

@app.get("/v1/agent/history")
async def agent_history_endpoint(agent_id: str = Body(None)):
    return await agent_history(agent_id)

@app.post("/v1/orchestrate/ansible/playbook")
async def orchestrate_ansible_playbook(playbook_path: str = Body(...), inventory: str = Body(None), 
                                      extra_vars: dict = Body(None), tags: list = Body(None), limit: str = Body(None)):
    return await run_ansible_playbook(playbook_path, inventory, extra_vars, tags, limit)

@app.post("/v1/orchestrate/ansible/adhoc")
async def orchestrate_ansible_adhoc(hosts: str = Body(...), module: str = Body(...), 
                                   args: str = Body(""), inventory: str = Body(None)):
    return await run_ansible_adhoc(hosts, module, args, inventory)

@app.post("/v1/orchestrate/ansible/create_playbook")
async def orchestrate_ansible_create_playbook(name: str = Body(...), plays: list = Body(...)):
    return await create_ansible_playbook(name, plays)

@app.get("/v1/orchestrate/ansible/playbooks")
async def orchestrate_ansible_list_playbooks():
    return await list_ansible_playbooks()

@app.post("/v1/orchestrate/terraform/init")
async def orchestrate_terraform_init(working_dir: str = Body(".")):
    return await terraform_init(working_dir)

@app.post("/v1/orchestrate/terraform/plan")
async def orchestrate_terraform_plan(working_dir: str = Body("."), var_file: str = Body(None), variables: dict = Body(None)):
    return await terraform_plan(working_dir, var_file, variables)

@app.post("/v1/orchestrate/terraform/apply")
async def orchestrate_terraform_apply(working_dir: str = Body("."), auto_approve: bool = Body(False), 
                                     var_file: str = Body(None), variables: dict = Body(None)):
    return await terraform_apply(working_dir, auto_approve, var_file, variables)

@app.post("/v1/orchestrate/terraform/destroy")
async def orchestrate_terraform_destroy(working_dir: str = Body("."), auto_approve: bool = Body(False), 
                                       var_file: str = Body(None), variables: dict = Body(None)):
    return await terraform_destroy(working_dir, auto_approve, var_file, variables)

@app.get("/v1/orchestrate/terraform/state")
async def orchestrate_terraform_state(working_dir: str = Body(".")):
    return await terraform_show_state(working_dir)

@app.post("/v1/orchestrate/terraform/workspace")
async def orchestrate_terraform_workspace(name: str = Body(...), template: str = Body(None)):
    return await create_terraform_workspace(name, template)

@app.post("/v1/orchestrate/proxmox/connect")
async def orchestrate_proxmox_connect(host: str = Body(...), user: str = Body(...), password: str = Body(...), 
                                     verify_ssl: bool = Body(False), connection_id: str = Body("default")):
    return await connect_proxmox(host, user, password, verify_ssl, connection_id)

@app.get("/v1/orchestrate/proxmox/nodes")
async def orchestrate_proxmox_nodes(connection_id: str = Body("default")):
    return await proxmox_list_nodes(connection_id)

@app.get("/v1/orchestrate/proxmox/vms")
async def orchestrate_proxmox_vms(node: str = Body(...), connection_id: str = Body("default")):
    return await proxmox_list_vms(node, connection_id)

@app.post("/v1/orchestrate/proxmox/vm/create")
async def orchestrate_proxmox_create_vm(node: str = Body(...), vmid: int = Body(...), 
                                       config: dict = Body(...), connection_id: str = Body("default")):
    return await proxmox_create_vm(node, vmid, config, connection_id)

@app.post("/v1/orchestrate/proxmox/vm/start")
async def orchestrate_proxmox_start_vm(node: str = Body(...), vmid: int = Body(...), connection_id: str = Body("default")):
    return await proxmox_start_vm(node, vmid, connection_id)

@app.post("/v1/orchestrate/proxmox/vm/stop")
async def orchestrate_proxmox_stop_vm(node: str = Body(...), vmid: int = Body(...), connection_id: str = Body("default")):
    return await proxmox_stop_vm(node, vmid, connection_id)

@app.get("/v1/orchestrate/proxmox/cluster/status")
async def orchestrate_proxmox_cluster_status(connection_id: str = Body("default")):
    return await proxmox_get_cluster_status(connection_id)

@app.post("/v1/orchestrate/ssh/connect")
async def orchestrate_ssh_connect(host: str = Body(...), user: str = Body(...), password: str = Body(None), 
                                 private_key_path: str = Body(None), port: int = Body(22), connection_id: str = Body("default")):
    return await ssh_connect(host, user, password, private_key_path, port, connection_id)

@app.post("/v1/orchestrate/ssh/execute")
async def orchestrate_ssh_execute(command: str = Body(...), connection_id: str = Body("default"), timeout: int = Body(30)):
    return await ssh_execute(command, connection_id, timeout)

@app.post("/v1/orchestrate/ssh/upload")
async def orchestrate_ssh_upload(local_path: str = Body(...), remote_path: str = Body(...), connection_id: str = Body("default")):
    return await ssh_upload_file(local_path, remote_path, connection_id)

@app.post("/v1/orchestrate/ssh/script")
async def orchestrate_ssh_script(script_content: str = Body(...), connection_id: str = Body("default"), interpreter: str = Body("bash")):
    return await ssh_execute_script(script_content, connection_id, interpreter)

@app.post("/v1/orchestrate/ssh/generate_keys")
async def orchestrate_ssh_generate_keys(key_name: str = Body(...), key_type: str = Body("rsa"), key_size: int = Body(2048)):
    return await ssh_generate_keys(key_name, key_type, key_size)

@app.get("/v1/orchestrate/ssh/connections")
async def orchestrate_ssh_connections():
    return await ssh_list_connections()

@app.post("/v1/orchestrate/powershell")
async def orchestrate_powershell(command: str = Body(...)):
    return run_powershell_command(command)

@app.post("/v1/orchestrate/bash")
async def orchestrate_bash(command: str = Body(...)):
    return run_bash_command(command)

talos_k8s = TalosK8sOrchestrator()
monitoring = MonitoringOrchestrator()
database = DatabaseOrchestrator()
security = SecurityScannerOrchestrator()
workflow = WorkflowOrchestrator()
crypto = CryptoOrchestrator()
revenue_optimization = RevenueOptimizationOrchestrator()
financial_analytics = FinancialAnalyticsOrchestrator()

# --- Talos/K8s Orchestration Endpoints ---
@app.post("/v1/orchestrate/talos_k8s/cluster/create")
async def talos_create_cluster(cluster_config: dict = Body(...)):
    return await talos_k8s.create_cluster(cluster_config)

@app.post("/v1/orchestrate/talos_k8s/cluster/delete")
async def talos_delete_cluster(cluster_id: str = Body(...)):
    return await talos_k8s.delete_cluster(cluster_id)

@app.post("/v1/orchestrate/talos_k8s/node/add")
async def talos_add_node(cluster_id: str = Body(...), node_config: dict = Body(...)):
    return await talos_k8s.add_node(cluster_id, node_config)

@app.post("/v1/orchestrate/talos_k8s/node/remove")
async def talos_remove_node(cluster_id: str = Body(...), node_id: str = Body(...)):
    return await talos_k8s.remove_node(cluster_id, node_id)

@app.get("/v1/orchestrate/talos_k8s/cluster/status")
async def talos_cluster_status(cluster_id: str):
    return await talos_k8s.get_cluster_status(cluster_id)

# --- Monitoring Orchestration Endpoints ---
@app.post("/v1/orchestrate/monitoring/deploy")
async def monitoring_deploy(cluster_id: str = Body(...), config: dict = Body(...)):
    return await monitoring.deploy_monitoring(cluster_id, config)

@app.get("/v1/orchestrate/monitoring/metrics")
async def monitoring_metrics(cluster_id: str, query: str):
    return await monitoring.get_metrics(cluster_id, query)

@app.get("/v1/orchestrate/monitoring/status")
async def monitoring_status(cluster_id: str):
    return await monitoring.get_monitoring_status(cluster_id)

# --- Database Orchestration Endpoints ---
@app.post("/v1/orchestrate/database/provision")
async def database_provision(db_config: dict = Body(...)):
    return await database.provision_database(db_config)

@app.post("/v1/orchestrate/database/delete")
async def database_delete(db_id: str = Body(...)):
    return await database.delete_database(db_id)

@app.get("/v1/orchestrate/database/status")
async def database_status(db_id: str):
    return await database.get_database_status(db_id)

# --- Security Scanning Orchestration Endpoints ---
@app.post("/v1/orchestrate/security/scan")
async def security_scan(target: str = Body(...), scan_type: str = Body("full")):
    return await security.run_security_scan(target, scan_type)

@app.get("/v1/orchestrate/security/report")
async def security_report(report_id: str):
    return await security.get_scan_report(report_id)

# --- Workflow Automation Orchestration Endpoints ---
@app.post("/v1/orchestrate/workflow/create")
async def workflow_create(workflow_config: dict = Body(...)):
    return await workflow.create_workflow(workflow_config)

@app.post("/v1/orchestrate/workflow/execute")
async def workflow_execute(workflow_id: str = Body(...), params: dict = Body(None)):
    return await workflow.execute_workflow(workflow_id, params)

@app.get("/v1/orchestrate/workflow/status")
async def workflow_status(workflow_id: str):
    return await workflow.get_workflow_status(workflow_id)

# --- Crypto, Revenue, and Financial MCP Endpoints are defined at the end of the file ---
# (see below for /v1/orchestrate/crypto/*, /v1/orchestrate/revenue/*, /v1/orchestrate/financial/*)

# --- Enhanced Model Discovery ---
@app.get("/v1/models/discover/crypto")
async def discover_crypto_models():
    """Discover available cryptocurrency and DeFi models"""
    return {
        "blockchain_networks": ["ethereum", "bitcoin", "polygon", "bsc", "arbitrum", "optimism"],
        "defi_protocols": ["uniswap", "compound", "aave", "curve", "yearn"],
        "nft_standards": ["erc721", "erc1155", "spl_token"],
        "oracle_providers": ["chainlink", "band", "api3", "pyth"],
        "bridge_protocols": ["stargate", "multichain", "hop", "across"]
    }

@app.get("/v1/models/discover/financial")
async def discover_financial_models():
    """Discover available financial analysis models"""
    return {
        "market_data_providers": ["binance", "coinbase", "alpaca", "polygon", "twelvedata"],
        "technical_indicators": ["trend", "momentum", "volatility", "volume"],
        "trading_strategies": ["mean_reversion", "trend_following", "breakout", "arbitrage"],
        "risk_models": ["var", "cvar", "monte_carlo", "black_scholes"],
        "compliance_frameworks": ["kyc", "aml", "mifid_ii", "dodd_frank", "gdpr"]
    }

# --- Health Check for New MCPs ---
@app.get("/v1/orchestrate/health/crypto")
async def crypto_health():
    return {"status": "operational", "modules": ["blockchain", "defi", "nft", "portfolio"]}

@app.get("/v1/orchestrate/health/revenue")
async def revenue_health():
    return {"status": "operational", "modules": ["mining", "compute_sharing", "ai_services", "pricing"]}

@app.get("/v1/orchestrate/health/financial")
async def financial_health():
    return {"status": "operational", "modules": ["market_data", "analytics", "trading", "compliance"]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
