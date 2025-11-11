{ config, pkgs, lib, ... }:

{
  # AI/ML development configuration
  # For LLM, RAG, and AI agent development

  home.packages = with pkgs; [
    # Data analysis
    duckdb  # Fast analytics database (great for RAG data processing)

    # Python tools for AI/ML (most packages go in venv/micromamba)
    # Global tools only
  ];

  # AI/ML specific environment variables
  home.sessionVariables = {
    # Ollama configuration
    OLLAMA_HOST = "http://localhost:11434";
    OLLAMA_MODELS = "$HOME/.ollama/models";

    # HuggingFace
    HF_HOME = "$HOME/.cache/huggingface";

    # Transformers cache
    TRANSFORMERS_CACHE = "$HOME/.cache/huggingface/transformers";
  };

  # Templates and aliases added to zsh.nix
}
