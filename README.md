# Share Note backend server (Custom Fork)

Custom fork of the backend server for [Share Note](https://github.com/alangrainger/share-note/).

## Customizations in this fork

- **Removed status bar**: Footer with "Share Note for Obsidian" link and theme toggle removed from note template
- **Banner plugin support**: Added CSS for Obsidian banner plugin compatibility
- **Security fix**: Field name sanitization in SQL queries to prevent injection attacks
- **Local build**: Configured for local Docker builds instead of using pre-built images

For the original upstream project, see [note-sx/server](https://github.com/note-sx/server).

## Configure the Obsidian plugin to use your server

### Step 1: Find your plugin configuration file

Open `<VAULT_DIR>/.obsidian/plugins/share-note/data.json` in your Obsidian vault.

### Step 2: Get your user ID (uid)

Your `uid` is already in the config file. Copy it - you'll need it in the next step.

Example: `"uid": "c90b197b3853ad19d0c08320f087115f"`

### Step 3: Generate your API key

Open this URL in your browser, replacing `YOUR_SERVER_URL` with your server address and `YOUR_UID` with the uid from Step 2:

```
YOUR_SERVER_URL/v1/account/get-key?id=YOUR_UID
```

Example:
```
https://notes.example.com/v1/account/get-key?id=c90b197b3853ad19d0c08320f087115f
```

The page will display your API key. Copy it.

### Step 4: Update your plugin configuration

Edit the `data.json` file and update these two fields:

```json
{
  "server": "https://notes.example.com",
  "apiKey": "your-api-key-from-step-3",
  ...
}
```

### Step 5: Reload the plugin

Reload the Share Note plugin or restart Obsidian for the changes to take effect.

This file will sync to all your devices using your normal sync method, so all your devices will update automatically.

## Run with Docker

1. Clone this repository: `git clone https://github.com/bitbonsai/note-server.git`
2. Navigate to the directory: `cd note-server`
3. Copy the example env file: `cp .env.example .env`
4. Update the `.env` options as below (especially `BASE_WEB_URL` and `HASH_SALT`)
5. Build and start: `docker compose build && docker compose up -d`

**Note**: This fork builds the Docker image locally from source instead of using a pre-built image. To update after pulling new changes: `git pull && docker compose build && docker compose up -d`

**Note**: Modern Docker uses `docker compose` (without hyphen) instead of the older `docker-compose` command.

### Useful Docker commands

- **Restart the server**: `docker compose restart`
- **Stop the server**: `docker compose down`
- **View logs**: `docker compose logs -f`
- **Rebuild and restart**: `docker compose build && docker compose up -d`

## Local Development Workflow

Switch seamlessly between local development and production environments with automated Docker management and plugin configuration.

### Prerequisites

Install `jq` for JSON parsing:
```bash
brew install jq
```

### Quick Start

**Switch to local development:**
```bash
bun run dev --vault /path/to/your/obsidian/vault
```

This command will:
- Back up your current plugin configuration
- Start a local Docker container on port 3000
- Generate a new API key automatically
- Update your plugin configuration to use localhost

**Switch back to production:**
```bash
bun run prod --vault /path/to/your/obsidian/vault
```

This command will:
- Restore your original plugin configuration from backup
- Stop the local Docker container
- Return to production settings

### How It Works

The workflow automation handles all the tedious steps:

1. **Environment Management**: Separate `.env.local` and `.env.production` configurations
2. **Docker Automation**: Starts/stops the appropriate container automatically
3. **API Key Generation**: Fetches new API keys from the server endpoint
4. **Configuration Backup**: Creates timestamped backups (keeps last 5 per environment)
5. **Zero Manual Steps**: Everything is automated - just run one command

### Workflow Details

When you switch to **local development**:
1. Current plugin config is backed up to `<vault>/.obsidian/plugins/share-note/backups/`
2. Local Docker container starts with `BASE_WEB_URL=http://localhost:3000`
3. Script waits for server to be healthy
4. New API key is generated for localhost
5. Plugin config updated with localhost server and new API key

When you switch to **production**:
1. Original plugin config restored from backup
2. Local Docker container stopped
3. Production settings fully restored

### Troubleshooting

**Docker not running:**
```
❌ Docker is not running
Please start Docker Desktop and try again
```

**jq not installed:**
```bash
brew install jq
```

**Vault path not found:**
Make sure you provide the correct absolute path to your Obsidian vault.

**Server won't start:**
Check logs with:
```bash
docker compose -f docker-compose.local.yml logs
```

**Port 3000 already in use:**
Stop any other services using port 3000, or stop the production container:
```bash
docker compose down
```

### Tips

- **Reload Obsidian**: After switching environments, reload the plugin with `Cmd+P` → "Reload app without saving"
- **View local logs**: `docker compose -f docker-compose.local.yml logs -f`
- **Multiple switches**: The script handles switching back and forth multiple times safely
- **Backups**: Old backups are automatically cleaned up (keeps last 5 per environment)

## `.env` options

| Option                 | Example             | Description                                                                                                                              |
|------------------------|---------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| BASE_WEB_URL           | https://example.com | **Required.** The base public URL for your server.                                                                                       |
| HASH_SALT              | Any random string   | **Required.** A random string used for hashing. Generate a secure random string for this value.                                          |
| MAXIMUM_UPLOAD_SIZE_MB | 5                   | The maximum allowed size for user uploads in megabytes (MB).                                                                             |
| FOLDER_PREFIX          | 0                   | *Optional.* Set this to `1` or `2` if you want user files to be split into subfolders based on the first *N* characters of the filename. |
