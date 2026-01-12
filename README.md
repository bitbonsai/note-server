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
5. Build and start: `docker-compose build && docker-compose up -d`

**Note**: This fork builds the Docker image locally from source instead of using a pre-built image. To update after pulling new changes: `git pull && docker-compose build && docker-compose up -d`

## `.env` options

| Option                 | Example             | Description                                                                                                                              |
|------------------------|---------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| BASE_WEB_URL           | https://example.com | **Required.** The base public URL for your server.                                                                                       |
| HASH_SALT              | Any random string   | **Required.** A random string used for hashing. Generate a secure random string for this value.                                          |
| MAXIMUM_UPLOAD_SIZE_MB | 5                   | The maximum allowed size for user uploads in megabytes (MB).                                                                             |
| FOLDER_PREFIX          | 0                   | *Optional.* Set this to `1` or `2` if you want user files to be split into subfolders based on the first *N* characters of the filename. |
