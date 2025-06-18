FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    docker.io \
    net-tools \
    iputils-ping \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /app/logs /app/config /app/data

# Copy requirements
COPY requirements-docker.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY consciousness_zero_optimized.py /app/

# Copy config if exists, otherwise create default
RUN if [ -d "config" ]; then cp -r config/* /app/config/; fi

# Create default config if not exists
RUN echo '{\
  "agent_name": "Consciousness Zero",\
  "version": "3.0.0",\
  "environment": "docker",\
  "tools_enabled": [\
    "system_monitor",\
    "shell_executor",\
    "web_search",\
    "memory_manager",\
    "file_manager",\
    "network_scanner",\
    "log_analyzer"\
  ],\
  "memory_retention_days": 30,\
  "max_context_tokens": 4000,\
  "debug_mode": false\
}' > /app/config/config.json

# Set permissions
RUN chmod +x /app/consciousness_zero_optimized.py

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python3 -c "import sys; sys.path.append('/app'); from consciousness_zero_optimized import initialize_agent; agent = initialize_agent(); print('healthy')" || exit 1

# Expose port for potential future API
EXPOSE 8080

# Environment variables
ENV CONSCIOUSNESS_ENVIRONMENT=docker
ENV CONSCIOUSNESS_DEBUG_MODE=false
ENV PYTHONPATH=/app

# Run the agent
CMD ["python3", "/app/consciousness_zero_optimized.py"]
