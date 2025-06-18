#!/usr/bin/env python3
"""
Simple test server to verify basic functionality
"""

import uvicorn
from fastapi import FastAPI
import gradio as gr

# Create a simple FastAPI app
app = FastAPI(title="Test Server")

@app.get("/health")
async def health():
    return {"status": "ok"}

# Simple Gradio interface
def echo(message):
    return f"Echo: {message}"

# Create Gradio interface
io = gr.Interface(
    fn=echo,
    inputs=gr.Textbox(placeholder="Enter message"),
    outputs=gr.Textbox(),
    title="Test Interface"
)

# Mount Gradio
app = gr.mount_gradio_app(app, io, path="/")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7861, log_level="info")
