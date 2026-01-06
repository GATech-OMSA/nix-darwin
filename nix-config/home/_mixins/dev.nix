{ config, pkgs, lib, ... }:

# Development Tools
#
# Development tools configuration for all dev machines (personal + work).
# Commented sections below are curated tool "menus" for easy discovery.
# Uncomment packages as needed for specific projects.

{
  home.packages = with pkgs; [
    # ============================================
    # ACTIVE DEVELOPMENT TOOLS
    # ============================================
    # Note: git, gh, tldr, lazydocker, docker-compose, xh are in shared/packages.nix

    # Build tools
    gnumake

    # ============================================
    # DATABASE TOOLS (Uncomment as needed)
    # ============================================
    # PostgreSQL client and utilities
    # postgresql_16  # Latest PostgreSQL client
    # pgcli          # PostgreSQL CLI with autocomplete

    # MySQL/MariaDB
    # mysql80        # MySQL 8.0 client
    # mycli          # MySQL CLI with autocomplete

    # Redis
    # redis          # Redis CLI and server

    # MongoDB
    # mongodb-tools  # mongodump, mongorestore, etc.
    # mongosh        # MongoDB shell

    # Other databases
    # sqlite         # Lightweight SQL database
    # clickhouse     # Column-oriented database
    # influxdb       # Time-series database
    # cassandra      # Distributed NoSQL database

    # Database utilities
    # dbeaver        # Universal database tool (GUI)
    # usql           # Universal SQL CLI

    # ============================================
    # API & WEB TESTING TOOLS (Uncomment as needed)
    # ============================================
    # Note: xh already in shared/packages.nix
    # httpie         # User-friendly HTTP client
    # curlie         # curl with httpie syntax
    # grpcurl        # gRPC curl-like tool
    # grpcui         # Interactive gRPC UI
    # hurl           # HTTP file-based testing
    # vegeta         # HTTP load testing
    # bombardier     # Fast HTTP benchmarking
    # hey            # HTTP load generator
    # wrk            # Modern HTTP benchmarking
    # postman        # API development platform (GUI)
    # insomnia       # REST/GraphQL client (GUI)

    # ============================================
    # INFRASTRUCTURE AS CODE (Uncomment as needed)
    # ============================================
    # Note: terraform, awscli2 already in shared/packages.nix
    # Terraform ecosystem
    # terraform-docs # Generate Terraform docs
    # tflint         # Terraform linter
    # tfsec          # Terraform security scanner
    # terrascan      # IaC security scanner
    # infracost      # Cloud cost estimates for Terraform

    # Other IaC tools
    # pulumi         # Modern IaC tool
    # ansible        # Configuration management
    # packer         # Machine image builder
    # vagrant        # Development environments

    # Cloud-specific
    # azure-cli      # Azure CLI
    # google-cloud-sdk  # Google Cloud CLI

    # ============================================
    # CONTAINER TOOLS (Uncomment as needed)
    # ============================================
    # Note: lazydocker, docker-compose already in shared/packages.nix
    # podman         # Docker alternative
    # buildah        # Container builder
    # skopeo         # Container image operations
    # dive           # Docker image layer explorer
    # ctop           # Container metrics viewer
    # hadolint       # Dockerfile linter (see Code Quality)

    # ============================================
    # CODE QUALITY & SECURITY (Uncomment as needed)
    # ============================================
    # Linters
    # shellcheck     # Shell script linter
    # shfmt          # Shell script formatter
    # hadolint       # Dockerfile linter
    # yamllint       # YAML linter
    # jsonlint       # JSON linter

    # Security scanners
    # Note: gitleaks already in shared/packages.nix
    # trivy          # Container/IaC security scanner
    # grype          # Vulnerability scanner
    # syft           # SBOM generator
    # cosign         # Container signing/verification
    # trufflehog     # Secret scanner

    # Code analysis
    # sonarqube      # Code quality platform
    # semgrep        # Static analysis tool
    # checkov        # IaC security scanner

    # ============================================
    # MONITORING & OBSERVABILITY (Uncomment as needed)
    # ============================================
    # Metrics & monitoring
    # prometheus     # Metrics collection
    # grafana        # Metrics visualization
    # alertmanager   # Alert management

    # Load testing & benchmarking
    # k6             # Modern load testing
    # locust         # Python-based load testing
    # gatling        # JVM-based load testing

    # Observability
    # jaeger         # Distributed tracing
    # zipkin         # Distributed tracing
    # opentelemetry-collector  # Telemetry collection

    # Log management
    # loki           # Log aggregation
    # promtail       # Log shipping to Loki
    # fluentd        # Log collection and forwarding
    # vector         # High-performance log router
  ];

  # Git delta (better git diff)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;  # Explicitly enable git integration
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "Nord";
    };
  };
}
