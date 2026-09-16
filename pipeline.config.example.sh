#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# AICodePipeline — project binding
#
# Copy to pipeline.config.sh in the TARGET project and fill in. Every {{VAR}}
# placeholder in core/ and harness/ is resolved from the values below when
# bin/install.sh renders the pipeline into that project.
#
#   cp pipeline.config.example.sh /path/to/project/pipeline.config.sh
#   $EDITOR /path/to/project/pipeline.config.sh
#   bin/install.sh /path/to/project
# ---------------------------------------------------------------------------

# --- Identity --------------------------------------------------------------
export PROJECT_NAME="My Platform"          # Human name, used in prose
export PROJECT_SLUG="my-platform"          # Lowercase, used in paths and ids
export PROJECT_DOMAIN="example.com"        # Primary domain
export GITHUB_REPO="owner/repo"            # For `gh` commands in instructions

# --- Locations (absolute for PROJECT_ROOT, repo-relative for the rest) -----
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"   # this file lives at the repo root; keep it dynamic so clones work
export PIPELINE_ROOT=".aicodepipeline"     # Where the pipeline is installed
export WORKSPACE_DIR="Workspace"           # Umbrella dir for generated artifacts
export DOCS_DIR="Workspace/Docs"
export WORKORDERS_DIR="Workspace/Docs/WorkOrders"
export BUGS_DIR="Workspace/Docs/Bugs"
export TESTING_DIR="Workspace/Testing"
export KNOWLEDGE_DIR="Workspace/Docs/KnowledgeBase"   # the repository described: analysis, feature profiles, source index
export SESSIONS_DIR="Workspace/Sessions"

# --- Application layout (used by agents to locate code) -------------------
# Set to the empty string for any that do not apply to this project.
export API_APP="apps/api"
export ADMIN_APP="apps/admin"
export PORTAL_APP="apps/portal"
export DEV_APP="apps/dev"
export WEB_APP="apps/web"
export SDK_PKG="packages/sdk"

# --- Optional domain agent packs (space-separated; see core/agents/domain/) --
export AGENT_PACKS=""                       # e.g. "identity"  (core/agents/domain/)
export SKILL_PACKS=""                       # e.g. "healthcare network"  (core/skill-packs/)

# --- Test harness ---------------------------------------------------------
export API_BASE_URL="http://localhost:3001/api/v1"   # where behavioural suites send requests
export WEB_ORIGIN="http://localhost:3000"            # the web app's origin (Origin header, UI tests)
export DB_NAME="my_platform_dev"
export CLI_NAME="${PROJECT_SLUG}-cli"

# --- Local dev networking (used by bin/dev/dev-toggle.sh) -----------------
export PROJECT_DOMAIN_RE="example\\.com"      # PROJECT_DOMAIN escaped for awk/regex
export DEV_SUBDOMAINS="api admin portal dev"  # space-separated, mapped to 127.0.0.1
export PROD_IP=""                             # production IP, shown by dev-toggle status (informational)
export DEV_PORTS="3000 3001"                  # ports bin/dev/kill-ports.sh frees when called without arguments
