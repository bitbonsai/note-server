#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Variables
VAULT_PATH=""
ENV="local"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --vault)
      VAULT_PATH="$2"
      shift 2
      ;;
    --env)
      ENV="$2"
      shift 2
      ;;
    switch)
      COMMAND="switch"
      shift
      ;;
    *)
      echo -e "${RED}❌ Unknown argument: $1${NC}"
      echo "Usage: $0 switch --env [local|production] --vault /path/to/vault"
      exit 1
      ;;
  esac
done

# Function: Print colored output
print_status() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}❌${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Function: Validate prerequisites
validate_prereqs() {
  # Check jq installed
  if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed"
    echo "Install with: brew install jq"
    exit 1
  fi

  # Check Docker is running
  if ! docker info &> /dev/null; then
    print_error "Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
  fi

  # Check vault path provided
  if [[ -z "$VAULT_PATH" ]]; then
    print_error "Vault path required"
    echo "Usage: bun run dev --vault /path/to/vault"
    exit 1
  fi

  # Check vault path exists
  if [[ ! -d "$VAULT_PATH" ]]; then
    print_error "Vault not found at: $VAULT_PATH"
    exit 1
  fi

  # Check plugin is installed
  local plugin_dir="$VAULT_PATH/.obsidian/plugins/share-note"
  if [[ ! -d "$plugin_dir" ]]; then
    print_error "Share Note plugin not found at vault"
    echo "Expected location: $plugin_dir"
    echo "Please install the plugin first"
    exit 1
  fi

  local config_file="$plugin_dir/data.json"
  if [[ ! -f "$config_file" ]]; then
    print_error "Plugin config not found: $config_file"
    exit 1
  fi

  print_status "Validating prerequisites (Docker, jq, vault)"
}

# Function: Backup plugin config
backup_plugin_config() {
  local config_file="$VAULT_PATH/.obsidian/plugins/share-note/data.json"
  local backup_dir="$VAULT_PATH/.obsidian/plugins/share-note/backups"
  local timestamp=$(date +"%Y-%m-%dT%H-%M-%S")
  local backup_file="$backup_dir/data.json.backup.$ENV.$timestamp.json"

  # Create backup directory if it doesn't exist
  mkdir -p "$backup_dir"

  # Copy config to backup
  cp "$config_file" "$backup_file"

  print_status "Backing up plugin config"

  # Keep only last 5 backups per environment
  local backup_pattern="$backup_dir/data.json.backup.$ENV.*.json"
  local backup_count=$(ls -1 $backup_pattern 2>/dev/null | wc -l)
  if [[ $backup_count -gt 5 ]]; then
    ls -1t $backup_pattern | tail -n +6 | xargs rm -f
  fi
}

# Function: Restore plugin config from latest backup
restore_plugin_config() {
  local config_file="$VAULT_PATH/.obsidian/plugins/share-note/data.json"
  local backup_dir="$VAULT_PATH/.obsidian/plugins/share-note/backups"

  # Find the latest production backup
  local latest_backup=$(ls -1t "$backup_dir"/data.json.backup.production.*.json 2>/dev/null | head -1)

  if [[ -z "$latest_backup" ]]; then
    print_error "No backup found for production environment"
    echo "Cannot safely restore configuration"
    exit 1
  fi

  # Restore from backup
  cp "$latest_backup" "$config_file"

  print_status "Restoring plugin config from backup"
}

# Function: Update plugin config with new server and API key
update_plugin_config() {
  local config_file="$VAULT_PATH/.obsidian/plugins/share-note/data.json"
  local server="$1"
  local api_key="$2"

  # Create temp file
  local temp_file=$(mktemp)

  # Update config using jq
  jq --arg server "$server" --arg key "$api_key" \
    '.server = $server | .apiKey = $key' \
    "$config_file" > "$temp_file"

  # Move temp file to config
  mv "$temp_file" "$config_file"

  print_status "Updating plugin configuration"
}

# Function: Extract UID from plugin config
get_uid() {
  local config_file="$VAULT_PATH/.obsidian/plugins/share-note/data.json"
  local uid=$(jq -r '.uid' "$config_file")
  echo "$uid"
}

# Function: Wait for server to be ready
wait_for_server() {
  local base_url="$1"
  local max_attempts=30

  print_info "Waiting for server to be ready (this may take 10-15 seconds)..."

  for i in $(seq 1 $max_attempts); do
    if curl -sf "$base_url/v1/ping" 2>/dev/null | grep -q "ok"; then
      print_status "Server is ready at $base_url"
      return 0
    fi
    sleep 1
  done

  print_error "Server failed to start within $max_attempts seconds"
  echo "Check logs: docker compose -f docker-compose.local.yml logs"
  return 1
}

# Function: Generate API key
generate_api_key() {
  local base_url="$1"
  local uid="$2"

  print_info "Generating new API key for $ENV environment..." >&2

  # Call the API endpoint
  local response=$(curl -sS "$base_url/v1/account/get-key?id=$uid" 2>/dev/null)

  # Extract API key from <code> tags using grep with Perl regex
  # macOS grep doesn't support -P, so use sed instead
  local api_key=$(echo "$response" | sed -n 's/.*<code>\([^<]*\)<\/code>.*/\1/p' | head -1)

  if [[ -z "$api_key" ]]; then
    print_warning "Couldn't auto-generate API key" >&2
    echo "Visit: $base_url/v1/account/get-key?id=$uid" >&2
    echo "Copy the API key and paste it below:" >&2
    read -p "API Key: " api_key

    if [[ -z "$api_key" ]]; then
      print_error "API key is required" >&2
      exit 1
    fi
  fi

  print_status "API key generated" >&2
  echo "$api_key"
}

# Function: Start Docker container
docker_start() {
  local compose_file="$1"
  local env_name="$2"

  cd "$PROJECT_ROOT"

  # Stop any running containers first
  if [[ "$env_name" == "local" ]]; then
    # Stop production if running
    if docker ps -a --format '{{.Names}}' | grep -q "^notesx-server$"; then
      print_info "Stopping production container"
      docker compose down 2>/dev/null || true
    fi
  else
    # Stop local if running
    if docker ps -a --format '{{.Names}}' | grep -q "^notesx-server-local$"; then
      print_info "Stopping local container"
      docker compose -f docker-compose.local.yml down 2>/dev/null || true
    fi
  fi

  print_info "Starting $env_name Docker container..."

  # Build and start
  docker compose -f "$compose_file" build --quiet
  docker compose -f "$compose_file" up -d

  print_status "Docker container started"
}

# Function: Stop Docker container
docker_stop() {
  local compose_file="$1"

  cd "$PROJECT_ROOT"

  print_info "Stopping Docker container..."
  docker compose -f "$compose_file" down

  print_status "Docker container stopped"
}

# Function: Switch environment
switch_environment() {
  validate_prereqs

  if [[ "$ENV" == "local" ]]; then
    # Switch to local development
    echo ""
    echo "🔄 Switching to LOCAL development environment"
    echo ""

    # Backup current config as production
    ENV="production" backup_plugin_config
    ENV="local"

    # Start local Docker
    docker_start "docker-compose.local.yml" "local"

    # Wait for server
    if ! wait_for_server "http://localhost:3000"; then
      print_error "Failed to start local server"
      exit 1
    fi

    # Generate API key
    local uid=$(get_uid)
    local api_key=$(generate_api_key "http://localhost:3000" "$uid")

    # Update plugin config
    update_plugin_config "http://localhost:3000" "$api_key"

    echo ""
    echo -e "${GREEN}✅ Successfully switched to LOCAL environment!${NC}"
    echo ""
    echo "Next steps:"
    echo "- Reload Obsidian plugin (Cmd+P → 'Reload app without saving')"
    echo "- Test sharing a note"
    echo "- View logs: docker compose -f docker-compose.local.yml logs -f"
    echo "- Switch back: bun run prod --vault $VAULT_PATH"
    echo ""

  elif [[ "$ENV" == "production" ]]; then
    # Switch to production
    echo ""
    echo "🔄 Switching to PRODUCTION environment"
    echo ""

    # Restore from backup
    restore_plugin_config

    # Stop local Docker
    docker_stop "docker-compose.local.yml"

    echo ""
    echo -e "${GREEN}✅ Successfully switched to PRODUCTION environment!${NC}"
    echo ""
    echo "Next steps:"
    echo "- Reload Obsidian plugin if needed"
    echo "- Your production server configuration has been restored"
    echo ""

  else
    print_error "Invalid environment: $ENV"
    echo "Valid options: local, production"
    exit 1
  fi
}

# Main execution
if [[ "$COMMAND" == "switch" ]]; then
  switch_environment
else
  print_error "Invalid command"
  echo "Usage: $0 switch --env [local|production] --vault /path/to/vault"
  exit 1
fi
