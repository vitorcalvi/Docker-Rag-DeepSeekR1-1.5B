The errors you're encountering are primarily related to deprecated imports and the incorrect import of `QDrantClient`. Here’s how you can address these issues:

### 1. **Correct Import for QDrantClient**
   - The correct package name is `qdrant_client`, not `langchain`.
   - Ensure that you have installed the latest version of `qdrant-client`.

### 2. **Update Deprecation Warnings**
   - Follow the deprecation warnings to update your imports.

Here's the revised script with these corrections:

```bash
#!/bin/bash

# Stop script on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker if not found
if ! command_exists docker; then
    echo "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and log back in for changes to take effect."
fi

# Install Docker Compose if not found
if ! command_exists docker-compose; then
    echo "Docker Compose not found. Installing..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "Docker Compose installed."
fi

# Update pip and install requirements
pip install --upgrade pip
pip install -r requirements.txt

# Clone or create project folder
if [ ! -d "rag-chatbot" ]; then
    mkdir rag-chatbot
else
    rm -rf rag-chatbot/*
fi

cd rag-chatbot

# Create Dockerfile
cat > Dockerfile <<EOF
FROM python:3.10
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 7860 6333 8000
CMD ["python", "app.py"]
EOF

# Create docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  ray:
    image: rayproject/ray:latest
    command: ["ray", "start", "--head"]
    ports:
      - "8265:8265"

  qdrant:
    image: qdrant/qdrant
    ports:
      - "6333:6333"

  app:
    build: .
    depends_on:
      - ray
      - qdrant
    ports:
      - "7860:7860"
EOF

# Create requirements.txt (ensure you have the latest versions)
cat > requirements.txt <<EOF
gradio
transformers
torch
accelerate
langchain
qdrant-client==0.3.1  # Ensure a stable version for compatibility
langchain-community
ray
fastapi
EOF

# Create app.py with updated imports and functions
cat > app.py <<EOF
import gradio as gr
import ray
import torch
from langchain_community.vectorstores import Qdrant
from langchain_community.embeddings import SentenceTransformerEmbeddings
from qdrant_client import QDrantClient
from transformers import pipeline

# Start Ray
ray.init(address="auto")

# Initialize Qdrant
qdrant_client = QDrantClient(url="http://qdrant:6333")
embeddings = SentenceTransformerEmbeddings(model_name="all-MiniLM-L6-v2")
vectorstore = Qdrant(client=qdrant_client, collection_name="rag_collection", embeddings=embeddings)

# Chatbot function
def rag_chatbot(query):
    docs = vectorstore.similarity_search(query, k=3)
    context = "\n".join([doc.page_content for doc in docs])
    input_text = f"Context: {context}\n\nUser: {query}\nAssistant:"
    
    generator = pipeline("text-generation", model="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B")
    response = generator(input_text, max_length=200, do_sample=True)[0]['generated_text']
    
    return response

# Gradio UI
iface = gr.Interface(fn=rag_chatbot, inputs="text", outputs="text", title="RAG Chatbot with DeepSeek R1")
iface.launch(server_name="0.0.0.0", server_port=7860)
EOF

# Run the containers
echo "Building and running the RAG system..."
docker-compose up --build -d

if [ $? -eq 0 ]; then
    echo "Setup complete. Access your chatbot at http://localhost:7860"
else
    echo "Error occurred while setting up the RAG system."
fi
```
