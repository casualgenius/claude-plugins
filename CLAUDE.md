# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugin marketplace. Users add this marketplace to Claude Code and can then install individual plugins from it.

**Marketplace name:** `casualgenius`
**GitHub:** `casualgenius/claude-plugins`

## Adding a New Plugin

1. Create plugin directory: `plugins/<plugin-name>/`
2. Add manifest: `plugins/<plugin-name>/.claude-plugin/plugin.json`
3. Add entry to `.claude-plugin/marketplace.json` in the `plugins` array
4. Update `README.md` to include the plugin in the Available Plugins table

## Plugin Structure

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json      # Required: name, version, description, author, keywords
├── README.md            # Plugin documentation with installation instructions
├── agents/              # Agent definitions (markdown files)
├── commands/            # Slash commands (markdown files)
└── skills/              # Knowledge/guidance for agents
    └── <skill-name>/
        ├── SKILL.md
        └── references/  # Supporting files
```

## Marketplace Configuration

The marketplace is configured in `.claude-plugin/marketplace.json`:
- `pluginRoot` is set to `./plugins` - plugin sources are relative to this directory
- Each plugin entry needs `name` and `source` (relative path from pluginRoot)

## Installation Commands

```bash
# Add marketplace
/plugin marketplace add casualgenius/claude-plugins

# Install a plugin
/plugin install casualgenius:<plugin-name>
```
