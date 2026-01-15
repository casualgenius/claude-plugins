# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugin marketplace. Users add this marketplace to Claude Code and can then install individual plugins from it.

**Marketplace name:** `casualgenius-plugins`
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
- Each plugin entry needs `name` and `source` (full relative path like `./plugins/plugin-name`)

## Relevant Documentation

Here are links to relevant documentation for building plugins in markdown format:
- Creating Plugins: https://code.claude.com/docs/en/plugins.md
- Plugins Reference: https://code.claude.com/docs/en/plugins-reference.md
- Slash Commands: https://code.claude.com/docs/en/slash-commands.md
- Agent Skills: https://code.claude.com/docs/en/skills.md
- Sub Agents: https://code.claude.com/docs/en/sub-agents.md
- Hooks: https://code.claude.com/docs/en/hooks.md

## Installation Commands

```bash
# Add marketplace
/plugin marketplace add casualgenius/claude-plugins

# Install a plugin (marketplace is optional if no name conflicts)
/plugin install <plugin-name>
/plugin install <plugin-name>@casualgenius-plugins
```
