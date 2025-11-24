{ config, pkgs, lib, myLib, ... }:

# Work Configuration
#
# Work machine-specific configuration (MACHINE_MODE="work").
# Includes AWS helpers, database connectors, project shortcuts, and curated tool menus
# for data engineering, cloud architecture, AI/ML, and system design.
# Commented sections are work-related tools for enterprise projects.

{
  # AWS CLI configuration with corporate CA bundle
  programs.aws = {
    caBundle = "~/.config/certs/cacert.pem";
  };

  # Work-specific packages
  home.packages = with pkgs; [
    # ============================================
    # ACTIVE WORK TOOLS
    # ============================================
    # ODBC drivers and database clients
    unixODBC           # ODBC driver manager
    freetds            # ODBC for SQL Server
    postgresql_16      # PostgreSQL client + libpq
    git-filter-repo

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
    # Python ML libraries (via UV/Micromamba for project isolation)
    # python3Packages.scikit-learn   # ML library
    # python3Packages.xgboost        # Gradient boosting
    # python3Packages.lightgbm       # Gradient boosting
    # python3Packages.catboost       # Gradient boosting

    # Deep learning frameworks
    # python3Packages.pytorch        # PyTorch
    # python3Packages.tensorflow     # TensorFlow
    # python3Packages.keras          # High-level neural networks

    # Data science tools
    # python3Packages.pandas         # Data manipulation
    # python3Packages.numpy          # Numerical computing
    # python3Packages.scipy          # Scientific computing
    # python3Packages.statsmodels    # Statistical models

    # Visualization
    # python3Packages.matplotlib     # Plotting
    # python3Packages.seaborn        # Statistical visualization
    # python3Packages.plotly         # Interactive plots

    # Experiment tracking
    # mlflow             # ML lifecycle management
    # wandb              # Experiment tracking
    # neptune-client     # ML metadata store

    # ============================================
    # LLM & MODEL TOOLS (Uncomment as needed)
    # ============================================
    # LLM serving & inference
    # ollama             # Local LLM inference
    # vllm               # Fast LLM inference
    # text-generation-webui  # LLM interface
    # localai            # OpenAI-compatible API

    # Model tools
    # huggingface-cli    # Hugging Face CLI
    # transformers-cli   # Transformers utilities

    # Fine-tuning & training
    # python3Packages.transformers   # Hugging Face transformers
    # python3Packages.peft           # Parameter-efficient fine-tuning
    # python3Packages.accelerate     # Distributed training
    # python3Packages.bitsandbytes   # 8-bit optimizers

    # Vector databases & embeddings
    # qdrant             # Vector database
    # weaviate           # Vector search engine
    # milvus             # Vector database
    # faiss              # Vector similarity search
    # chromadb           # AI-native embedding database

    # LLM frameworks
    # langchain          # LLM application framework
    # llamaindex         # LLM data framework
    # semantic-kernel    # AI orchestration

    # ============================================
    # API DEVELOPMENT & INTEGRATION (Uncomment as needed)
    # ============================================
    # API frameworks (Python)
    # python3Packages.fastapi        # Modern API framework
    # python3Packages.flask          # Web framework
    # python3Packages.django         # Full-stack framework

    # API testing
    # postman            # API platform (GUI)
    # insomnia           # API client (GUI)
    # httpie             # HTTP client
    # grpcurl            # gRPC testing
    # newman             # Postman CLI runner

    # API documentation
    # swagger-cli        # OpenAPI validator
    # redoc-cli          # OpenAPI documentation
    # spectral           # OpenAPI linter

    # Message queues
    # rabbitmq           # Message broker
    # nats-server        # Cloud-native messaging
    # pulsar             # Distributed messaging

    # ============================================
    # MONITORING & OBSERVABILITY (Uncomment as needed)
    # ============================================
    # Metrics & monitoring
    # prometheus         # Metrics collection
    # grafana            # Metrics visualization
    # thanos             # Prometheus long-term storage
    # cortex             # Multi-tenant Prometheus

    # Logging
    # loki               # Log aggregation
    # promtail           # Log shipping
    # fluentd            # Log collection
    # vector             # Observability pipeline

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

  # Machine detection for shell
  home.sessionVariables = {
    MACHINE_MODE = "work";
    # AWS_PROFILE - Auto-restored from ~/.aws/.last_profile on shell start
    # Managed by: awsuse <project> <env> [role]
    # Examples:
    #   awsuse tririga-integrations dev
    #   awsuse ti sbx developer
    #   awslogin hr qa

    # ODBC Configuration
    ODBCSYSINI = "/usr/local/etc";
    ODBCINI = "/usr/local/etc/odbc.ini";
  };

  # Work-specific shell aliases
  programs.zsh.shellAliases = {
    # Project directory shortcuts
    fscst = "cd ~/Dev/scst";
    fti = "cd ~/Dev/tririga";
    fps-proj = "cd ~/Dev/paging-solution";
    fmp = "cd ~/Dev/misc-projects";
    fwfhub = "cd ~/Dev/workforce-hub";
    fap = "cd ~/Dev/webMethods/api";
    fdeploys = "cd ~/Dev/production-deploys";
  };

  # Work-specific shell functions
  programs.zsh.initContent = ''
    # HRStringCrypter helper
    function crypter() {
      if command -v micromamba &> /dev/null && command -v python &> /dev/null; then
        # Use system Python or activate an environment first with: act <env-name>
        python ~/Dev/misc-projects/HRStringCrypter/run-crypter.py
      else
        echo "❌ Error: Python or micromamba not found"
        echo "Please ensure Python is available (system or activate micromamba environment)"
        return 1
      fi
    }

    # ==================================================
    # AWS HELPER FUNCTIONS
    # ==================================================
    # AWS functions read from ~/.aws/accounts.json for project configuration.
    #
    # Usage:
    #   awsuse <project|alias> <env> [role]
    #   awslogin <project|alias> <env> [role]
    #   awswho, awslist, awswhere, awscheck
    #
    # Examples:
    #   awsuse ti sbx                # tririga-integrations sbx (support role)
    #   awsuse ti sbx developer      # tririga-integrations sbx (developer role)
    #   awslogin ps dev              # paging-solution dev + SSO login
    #
    # Generated aliases from accounts.json:
    #   tidev, tisbx, tiqa, tiprod, tidev-developer, tisbx-developer, etc.

    ${myLib.aws.mkAwsAccountHelper}
    ${myLib.aws.mkAwsInfoCommands}
    ${myLib.aws.mkAwsSearchCommands}
    ${myLib.aws.mkAwsProfileAutoRestore}

    # ==================================================
    # DATABASE INSTANCE CONNECTORS (Environment Variables)
    # ==================================================
    # Pattern: dbconnect-<instance> <env>
    # Examples:
    #   dbconnect-ti dev         → Tririga Oracle (dev)
    #   dbconnect-hrdb prod      → HR SQL Server (prod)
    #   dbconnect-payroll qa     → Payroll PostgreSQL (qa)
    #
    # Credentials: Loaded from ~/.secrets/credentials.env.enc
    # Rotation: edit-credentials → save → exec zsh (NO nix rebuild!)
    #
    # Required env vars (example for TI prod):
    #   TI_PROD_USERNAME, TI_PROD_PASSWORD, TI_PROD_HOST,
    #   TI_PROD_PORT, TI_PROD_SERVICE

    ${myLib.database.mkDatabaseInstances [
      # Tririga Oracle Database (multiple environments)
      {
        instance = "ti";
        type = "oracle";
        environments = [ "dev" "qa" "prod" ];
        description = "Tririga Oracle Database";
      }

      # HR Database - SQL Server (prod only)
      {
        instance = "hrdb";
        type = "mssql";
        environments = [ "prod" ];
        description = "HR SQL Server Database";
      }

      # PeopleSoft Oracle (dev, qa, prod)
      {
        instance = "ps";
        type = "oracle";
        environments = [ "dev" "qa" "prod" ];
        description = "PeopleSoft Oracle Database";
      }

      # ODS - SQL Server (qa, prod)
      {
        instance = "ods";
        type = "mssql";
        environments = [ "qa" "prod" ];
        description = "Operational Data Store (ODS)";
      }

      # Data Warehouse - SQL Server
      {
        instance = "dw";
        type = "mssql";
        environments = [ "prod" ];
        description = "Data Warehouse";
      }

      # Payroll PostgreSQL (uses LAN credentials)
      {
        instance = "payroll";
        type = "postgres";
        environments = [ "qa" "prod" ];
        description = "Payroll PostgreSQL Database";
      }

      # Add more database instances as needed:
      # {
      #   instance = "your-db-name";
      #   type = "oracle|mssql|postgres|mysql";
      #   environments = [ "dev" "qa" "prod" ];
      #   description = "Your Database Description";
      # }
    ]}

    ${myLib.database.mkInstanceList [
      { instance = "ti"; type = "oracle"; environments = [ "dev" "qa" "prod" ]; description = "Tririga"; }
      { instance = "hrdb"; type = "mssql"; environments = [ "prod" ]; description = "HR Database"; }
      { instance = "ps"; type = "oracle"; environments = [ "dev" "qa" "prod" ]; description = "PeopleSoft"; }
      { instance = "ods"; type = "mssql"; environments = [ "qa" "prod" ]; description = "ODS"; }
      { instance = "dw"; type = "mssql"; environments = [ "prod" ]; description = "Data Warehouse"; }
      { instance = "payroll"; type = "postgres"; environments = [ "qa" "prod" ]; description = "Payroll"; }
    ]}

    # ==================================================
    # TOKEN HELPERS (File-based - kept for tokens)
    # ==================================================
    # Usage: git-token, terraform-token, jira-token
    # Tokens managed via sops-nix in secrets.yaml
    # Includes: File permission validation (600)

    ${myLib.database.mkTokenHelpers [
      {
        name = "git";
        description = "Git token";
        file = "git_token";
      }
      {
        name = "terraform";
        description = "HCP Terraform token";
        file = "hcp_terraform_token";
      }
      {
        name = "jira";
        description = "Jira API token";
        file = "jira_api_token";
      }
    ]}
  '';
}
