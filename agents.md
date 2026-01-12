# note-server Project Instructions

## Project Overview
TypeScript/Node.js server for sharing Obsidian notes. Custom fork with security fixes and template customizations. Built with Hono framework and Better-sqlite3.

## Architecture
- **Framework**: Hono (lightweight web framework)
- **Database**: Better-sqlite3 (SQLite)
- **Source**: `app/src/` (TypeScript)
- **Build**: `app/dist/` (compiled JavaScript)
- **Deployment**: Docker with docker-compose

## Key Files
- `app/src/index.ts` - Server entry point
- `app/src/v1/Database.ts` - Database operations
- `app/src/v1/Controller.ts` - Route handlers
- `app/src/v1/WebNote.ts` - Note rendering logic
- `app/src/v1/User.ts` - User management
- Template files in `app/templates/` - HTML templates for note display

## Security Requirements
- **CRITICAL**: All SQL queries MUST sanitize field names to prevent injection attacks
- Never trust user input in database queries
- Validate and escape all parameters before SQL operations
- Reference commit 67583d1 for SQL injection fix pattern

## Development Workflow
- Run dev server: `npm run dev` (from app/ directory)
- Build: `npm run build`
- Test: `npm run test` (builds and runs Docker image)
- Docker rebuild: `docker-compose build && docker-compose up -d`

## Code Standards
- TypeScript strict mode
- Use ESLint configuration in place
- Follow existing patterns in v1/ directory
- Keep changes minimal and focused
- Test SQL queries thoroughly

## Customizations in This Fork
- Removed status bar footer from note template
- Added CSS for Obsidian banner plugin support
- Field name sanitization in SQL queries
- Local Docker builds (not pre-built images)

## Before Making Changes
- Read relevant source files in `app/src/v1/`
- Check if changes affect SQL queries (security review required)
- Consider impact on Docker build
- Test with actual Obsidian notes if modifying templates
