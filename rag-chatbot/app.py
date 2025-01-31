import gradio as gr
import ray
import torch
from langchain.vectorstores import Qdrant
from langchain.embeddings import SentenceTransformerEmbeddings
from qdrant_client import QDrantClient
from transformers import pipeline

def rag_chatbot(query):
    # Placeholder function for demonstration purposes
    return "Sample response"

# Gradio UI
iface = gr.Interface(fn=rag_chatbot, inputs="text", outputs="text", title="RAG Chatbot with DeepSeek R1")
iface.launch(server_name="0.0.0.0", server_port=7860)
