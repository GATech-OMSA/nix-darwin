# home/_profiles/work/packages.nix
#
# Work-specific packages for corporate development
# All packages commented out — uncomment as needed

{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # ============================================
    # API DEVELOPMENT & TESTING
    # ============================================
    # bruno              # Open-source API client (Git-friendly Postman alternative)
    # hurl               # Run and test HTTP requests from plain text files
    # posting            # TUI HTTP client
    # xh                 # Fast HTTP request tool (httpie-compatible)

    # ============================================
    # CONTAINER & KUBERNETES
    # ============================================
    # k9s                # TUI for Kubernetes cluster management
    # kubectx            # Switch kubectl contexts/namespaces quickly
    # dive               # Explore Docker image layers
    # lazydocker         # TUI for Docker management
    # helm               # Kubernetes package manager
    # kustomize          # Kubernetes config customization
    # skaffold           # Local Kubernetes development
    # tilt               # Multi-service dev environment for K8s
    # argocd             # GitOps continuous delivery

    # ============================================
    # SECURITY & COMPLIANCE
    # ============================================
    # trivy              # Container/filesystem vulnerability scanner
    # grype              # Container image vulnerability scanner
    # syft               # SBOM (software bill of materials) generator
    # cosign             # Container image signing/verification
    # gitleaks           # Secret detection in git repos
    # trufflehog         # Credential scanner for git/S3/filesystems

    # ============================================
    # CLOUD & INFRASTRUCTURE
    # ============================================
    # AWS tools
    # aws-vault          # Secure AWS credential storage
    # aws-iam-authenticator  # EKS authentication
    # eksctl             # EKS cluster management
    # granted            # Fast AWS role switching with SSO
    # infracost          # Cloud cost estimates for Terraform
    # steampipe          # Cloud infrastructure queries

    # Terraform/OpenTofu
    # tenv               # Terraform/OpenTofu version manager

    # Azure tools
    # azure-cli          # Azure command-line

    # GCP tools
    # google-cloud-sdk   # GCP command-line

    # Multi-cloud
    # cloudquery         # Cloud asset inventory

    # ============================================
    # DATA ENGINEERING & ETL
    # ============================================
    # ETL frameworks
    # airflow            # Workflow orchestration
    # dagster            # Data orchestration
    # prefect            # Modern workflow orchestration

    # Data transformation
    # sqlfluff           # SQL linter

    # Object storage
    # minio-client       # S3-compatible object storage CLI

    # Query engines
    # duckdb             # In-process analytical database
    # clickhouse         # Column-oriented database

    # ============================================
    # MONITORING & OBSERVABILITY
    # ============================================
    # Metrics & pipelines
    # prometheus         # Metrics collection
    # grafana            # Metrics visualization
    # vector             # High-performance log/metric pipeline

    # Tracing
    # jaeger             # Distributed tracing
    # tempo              # Distributed tracing backend
    # opentelemetry-collector  # Telemetry collection

    # Load testing
    # k6                 # Load testing tool (Grafana)
    # vegeta             # HTTP load testing
    # hey                # Simple HTTP load generator

    # ============================================
    # AI-ASSISTED DEVELOPMENT
    # ============================================
    kiro-cli            # Command-line interface for Kiro agentic IDE
    # aider-chat         # AI pair programming in terminal
    # fabric-ai          # AI-powered CLI for text processing patterns

    # ============================================
    # CODE ANALYSIS & BENCHMARKING
    # ============================================
    # tokei              # Fast code statistics by language
    # scc                # Fast code counter with complexity
    # hyperfine          # CLI benchmarking tool

    # ============================================
    # NETWORKING & DIAGNOSTICS
    # ============================================
    # doggo              # Modern DNS client (dig alternative)
    # bandwhich          # TUI bandwidth utilization by process
    # trippy             # Modern network diagnostics (traceroute + ping TUI)

    # ============================================
    # DATA SCIENCE & ML/AI
    # ============================================
    # python3Packages.tensorflow
    # python3Packages.pytorch
    # python3Packages.scikit-learn
    # mlflow             # ML lifecycle management

    # ============================================
    # DOCUMENTATION & DIAGRAMMING
    # ============================================
    # mkdocs             # Documentation generator
    # quarto             # Scientific publishing
    # mermaid-cli        # Text-to-diagram
    # graphviz           # Graph visualization
  ];
}
