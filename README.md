# Claude Code Plugins

A marketplace of plugins for [Claude Code](https://claude.ai/claude-code).

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add casualgenius/claude-plugins
```

Or from a local clone:

```bash
/plugin marketplace add /path/to/claude-plugins
```

Then install individual plugins:

```bash
/plugin install casualgenius:prd-to-feature
```

## Available Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| [prd-to-feature](plugins/prd-to-feature/README.md) | PRD-driven development workflow with automated planning and task execution | 1.1.0 |

## Contributing

To add a plugin to this marketplace:

1. Create your plugin in the `plugins/` directory
2. Add a `.claude-plugin/plugin.json` manifest
3. Add an entry to `.claude-plugin/marketplace.json`
4. Submit a pull request

## License

MIT
