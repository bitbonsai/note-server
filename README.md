# Share Note backend server (Custom Fork)

Custom fork of the backend server for [Share Note](https://github.com/alangrainger/share-note/).

## Customizations in this fork

- **Removed status bar**: Footer with "Share Note for Obsidian" link and theme toggle removed from note template
- **Banner plugin support**: Added CSS for Obsidian banner plugin compatibility
- **Security fix**: Field name sanitization in SQL queries to prevent injection attacks
- **Local build**: Configured for local Docker builds instead of using pre-built images

For the original upstream project, see [note-sx/server](https://github.com/note-sx/server).

## Change your Obsidian plugin to point to your server

Change the server URL in your `<VAULT_DIR>/.obsidian/plugins/share-note/data.json` file. Either reload the plugin or reload Obsidian for the changes to take effect.

This file will sync to all your devices using your normal sync method, so all your devices will update.

## Run with Docker

1. Clone this repository: `git clone https://github.com/bitbonsai/note-server.git`
2. Navigate to the directory: `cd note-server`
3. Copy the example env file: `cp .env.example .env`
4. Update the `.env` options as below (especially `BASE_WEB_URL` and `HASH_SALT`)
5. Build and start: `docker-compose build && docker-compose up -d`

**Note**: This fork builds the Docker image locally from source instead of using a pre-built image. To update after pulling new changes: `git pull && docker-compose build && docker-compose up -d`

## `.env` options

| Option                      | Example             | Description                                                                                                                              |
|-----------------------------|---------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| BASE_WEB_URL                | https://example.com | The base public URL for your server.                                                                                                     |
| HASH_SALT                   | Any random string   |                                                                                                                                          |
| MAXIMUM_UPLOAD_SIZE_MB      | 5                   | The maximum allowed size for user uploads in megabytes (MB).                                                                             |
| FOLDER_PREFIX               | 0                   | *OPTIONAL.* Set this to `1` or `2` if you want user files to be split into subfolders based on the first *N* characters of the filename. |
| CLOUDFLARE_TURNSTILE_KEY    |                     | *OPTIONAL.* If you want to use Turnstile to show a captcha when someone creates an account.                                              |
| CLOUDFLARE_TURNSTILE_SECRET |                     | *OPTIONAL.* If you want to use Turnstile to show a captcha when someone creates an account.                                              |
| CLOUDFLARE_ZONE_ID          |                     | *OPTIONAL.* If you want to use Cloudflare proxy in front of your server.                                                                 |
| CLOUDFLARE_API_KEY          |                     | *OPTIONAL.* If you want to use Cloudflare proxy in front of your server.                                                                 |
