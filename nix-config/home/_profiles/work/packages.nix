# home/_profiles/work/packages.nix
#
# Work-specific packages for corporate development

{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # ============================================
    # ACTIVE WORK TOOLS
    # ============================================
    # Secrets management - already in system packages (modules/darwin/packages.nix)
    # sops
    # age
    # yq-go

    # Python development
    python313          # Python 3.13
    uv                 # Fast Python package installer
    # micromamba       # BROKEN in nixpkgs 1.5.8 (fmt formatter issue) - using Homebrew instead

    # Node.js (required for VS Code extensions like Amazon Q)
    nodejs_22          # Node.js 22 LTS


    # ODBC drivers and database clients
    unixODBC           # ODBC driver manager
    unixODBCDrivers.msodbcsql18  # Microsoft ODBC Driver 18 for SQL Server
    # freetds          # Superseded by msodbcsql18
    postgresql_17      # PostgreSQL client + libpq

    # Database CLI tools
    pgcli              # PostgreSQL CLI with auto-completion
    # mycli            # MySQL/MariaDB CLI (uncomment if needed)

    # ============================================
    # DATA ENGINEERING & ETL TOOLS (Uncomment as needed)
    # ============================================
    # ETL frameworks
    # airflow            # Workflow orchestration
    # dagster            # Data orchestration
    # prefect            # Modern workflow orchestration
    # luigi              # Python ETL framework

    # Data transformation
    # dbt                # Data transformation tool
    # dataform           # SQL-based data transformation
    # sqlfluff           # SQL linter

    # Data integration
    # airbyte            # Open-source data integration
    # meltano            # ELT platform
    # singer-python      # Data extraction framework

    # Data quality
    # great-expectations # Data validation
    # soda-core          # Data quality testing
    # datafold           # Data testing

    # ============================================
    # BIG DATA & ANALYTICS (Uncomment as needed)
    # ============================================
    # Apache ecosystem
    # spark              # Distributed computing
    # hadoop             # Distributed storage/processing
    # hive               # Data warehouse
    # kafka              # Event streaming
    # flink              # Stream processing

    # Data lakes & warehouses
    # delta-lake         # ACID transactions on data lakes
    # iceberg            # Table format for data lakes
    # hudi               # Incremental data processing

    # Query engines
    # presto             # Distributed SQL query engine
    # trino              # Fast distributed SQL
    # duckdb             # In-process analytical database
    # clickhouse         # Column-oriented database

    # ============================================
    # CLOUD & INFRASTRUCTURE (Uncomment as needed)
    # ============================================
    # AWS tools (beyond awscli2)
    # aws-vault          # Secure AWS credential storage
    # aws-iam-authenticator  # EKS authentication
    # eksctl             # EKS cluster management
    # aws-nuke           # AWS resource cleanup
    # steampipe          # Cloud infrastructure queries

    # Azure tools
    # azure-cli          # Azure command-line
    # azure-functions-core-tools  # Azure Functions

    # GCP tools
    # google-cloud-sdk   # GCP command-line
    # gcloud-sql-proxy   # Cloud SQL proxy

    # Multi-cloud
    # cloudsplaining     # AWS IAM security assessment
    # cloud-nuke         # Multi-cloud resource cleanup
    # cloudquery         # Cloud asset inventory

    # ============================================
    # DATA SCIENCE & ML/AI (Uncomment as needed)
    # ============================================
    # ML frameworks
    # python3Packages.tensorflow
    # python3Packages.pytorch
    # python3Packages.scikit-learn

    # MLOps
    # mlflow             # ML lifecycle management
    # kubeflow           # ML on Kubernetes
    # seldon-core        # ML deployment

    # ============================================
    # MONITORING & OBSERVABILITY (Uncomment as needed)
    # ============================================
    # Metrics & monitoring
    # prometheus         # Metrics collection
    # grafana            # Metrics visualization
    # telegraf           # Metrics collection agent

    # Logging
    # elasticsearch      # Log storage
    # logstash           # Log processing
    # kibana             # Log visualization
    # fluentd            # Log collection

    # Tracing
    # jaeger             # Distributed tracing
    # zipkin             # Distributed tracing
    # tempo              # Distributed tracing backend

    # Application Performance Monitoring
    # opentelemetry-collector  # Telemetry collection
    # datadog-agent      # Datadog APM
    # new-relic-cli      # New Relic CLI

    # ============================================
    # DATA QUALITY & TESTING (Uncomment as needed)
    # ============================================
    # Data testing
    # pytest             # Python testing (in dev.nix)
    # great-expectations # Data validation framework
    # pandera            # Pandas data validation
    # cerberus           # Schema validation

    # Data profiling
    # ydata-profiling    # Data profiling
    # pandas-profiling   # Deprecated (use ydata-profiling)

    # Data lineage
    # datahub            # Metadata platform
    # amundsen           # Data discovery
    # marquez            # Metadata service

    # Schema validation
    # jsonschema         # JSON schema validation
    # pydantic           # Data validation (Python)

    # ============================================
    # BUSINESS INTELLIGENCE & VISUALIZATION (Uncomment as needed)
    # ============================================
    # BI tools
    # metabase           # Open-source BI
    # superset           # Data visualization
    # redash             # SQL-based BI

    # Reporting
    # jasperreports      # Reporting engine
    # pentaho            # BI suite

    # Dashboard frameworks
    # streamlit          # Python data apps
    # dash               # Python dashboards
    # voila              # Jupyter dashboards

    # ============================================
    # COLLABORATION & DOCUMENTATION (Uncomment as needed)
    # ============================================
    # Documentation
    # mkdocs             # Documentation generator
    # sphinx             # Python documentation
    # jupyter-book       # Executable books
    # quarto             # Scientific publishing

    # Diagramming
    # mermaid-cli        # Text-to-diagram
    # plantuml           # UML diagrams
    # graphviz           # Graph visualization
    # drawio             # Diagramming tool

    # Project management
    # jira-cli           # Jira CLI
    # gh                 # GitHub CLI (in shared packages)

    # Knowledge management
    # obsidian           # Knowledge base (via Homebrew on personal)
    # notion             # Workspace (web-based)
  ];
}
