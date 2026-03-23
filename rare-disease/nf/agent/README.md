# NF Agent Skills

Skills for AI-assisted NF data curation using the [nfty MCP server](https://github.com/nf-osi/mcp-server) and [agent-at-work](https://github.com/nf-osi/agent-at-work) recipes. These skills enable agents to review Synapse projects, generate portal metadata, and produce curation task assignments.

| Skill | Description |
|---|---|
| `nfty-mcp-server/` | Install and configure the nfty MCP server with Claude Code or Goose; full reference for all 10 tools |
| `portal-curation/` | Project review (DSP vs. actual assets) and portal dataset metadata generation using nfty tools and Goose recipes |
| `curation-tasks/` | 3-tier curation task generation pipeline: Component annotations → rule-based template selection → Claude Sonnet AI; GitHub Actions workflow for batch runs across all unreleased projects |
