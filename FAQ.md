# Frequently Asked Questions (FAQ)

Common questions about Skill-Seeker, answered comprehensively.

## General Questions

### What is Skill-Seeker?

Skill-Seeker is a Claude Code plugin that helps you discover, evaluate, and install community-created AI skills. Think of it as a package manager for AI behavioral frameworks - similar to npm for JavaScript or pip for Python, but for prompt-based skills that shape how Claude approaches tasks.

### How is this different from MCP tools?

| Feature | Skill-Seeker (Skills) | MCP Tools |
|---------|----------------------|-----------|
| **Type** | Behavioral frameworks (prompts) | Executable code |
| **Purpose** | Shape AI thinking | Add capabilities |
| **Installation** | Markdown files | Binary/code installation |
| **Security** | Content scanning | Code execution |
| **Examples** | "Design audit framework", "API patterns" | "Database connector", "File system access" |

**Use Skill-Seeker when**: You want Claude to apply specific thinking patterns, frameworks, or best practices.

**Use MCP tools when**: You need Claude to interact with external systems or execute code.

### Why would I use this instead of just asking Claude?

Without Skill-Seeker:
```
You: "Review this API design"
Claude: *Gives generic feedback*
```

With Skill-Seeker:
```
You: "Review this API design"
Claude (with REST API Design skill loaded):
- Endpoint naming should use plural nouns: /users not /user
- Missing pagination for GET /users
- Should return 201 Created not 200 OK for POST
- Error responses should follow RFC 7807 Problem Details
- Missing API versioning in endpoints
```

The skill provides Claude with specific frameworks, checklists, and patterns to apply.

### Is this free to use?

Yes! Skill-Seeker is MIT licensed and completely free. The skills in the registry are also open source and free to use.

### Do I need a GitHub account?

Not required for basic usage (searching the curated registry), but recommended for:
- Higher API rate limits (5,000 vs 60 requests/hour)
- Accessing more skills via live GitHub search
- Contributing skills to the registry

## Installation & Setup

### How do I install Skill-Seeker?

1. Clone the repository to your Claude Code plugins directory:
```bash
git clone https://github.com/mmmantasrrr/skill-seeker.git
```

2. Ensure dependencies are installed:
```bash
which curl jq python3  # Should all return paths
```

3. (Optional) Set GitHub token for higher rate limits:
```bash
export GITHUB_TOKEN=ghp_your_token_here
```

### What are the prerequisites?

Required:
- `curl` - For HTTP requests
- `jq` - For JSON parsing
- `python3` - For security scanning

Optional:
- `GITHUB_TOKEN` environment variable - For higher API rate limits

All these tools are typically pre-installed on macOS and Linux. On Windows, use WSL or Git Bash.

### Can I use this offline?

Partially. The curated registry works offline, but live GitHub API search requires internet connectivity. We're working on a full offline mode in a future release.

### How do I update Skill-Seeker?

```bash
cd /path/to/skill-seeker
git pull origin main
```

The registry is updated regularly with new verified skills.

## Using Skill-Seeker

### How do I search for skills?

Use natural language queries:

```bash
# Search for design-related skills
/skill-seeker:seek frontend design

# Search for testing tools
/skill-seeker:seek playwright testing

# Search for security patterns
/skill-seeker:seek security owasp

# Search for API design
/skill-seeker:seek rest api patterns
```

The search uses synonym expansion, so "frontend" automatically includes "ui", "web-design", "client-side", etc.

### What's a "trust score"?

Trust scores indicate skill quality based on:
- Repository stars (log scale, max 40 points)
- Recent activity (updated within 30 days, max 20 points)
- Fork count (log scale, max 15 points)
- Proper GitHub topics (5 points)
- Not archived (5 points)
- Has description (5 points)
- Has license (5 points)

**Score ranges**:
- **60+** (HIGH): Well-established, actively maintained
- **40-59** (MEDIUM): Reasonable quality, review recommended
- **<40** (LOW): Use with caution

### How do I install a skill?

After searching, you'll see results with paths. Install using:

```bash
/skill-seeker:install owner/repo/path/to/SKILL.md
```

For example:
```bash
/skill-seeker:install pbakaus/impeccable/.claude/skills/impeccable/SKILL.md
```

The system will:
1. Fetch the skill file
2. Run security scan
3. Show you the results
4. Ask for confirmation if any issues found
5. Load the skill into Claude's context

### How do I unload skills?

```bash
/skill-seeker:unload
```

This shows all loaded skills and lets you remove them. Useful when switching contexts (e.g., from frontend to backend work).

### Can I load multiple skills at once?

Yes! You can load complementary skills:

```bash
/skill-seeker:install [security-skill]
/skill-seeker:install [api-design-skill]
/skill-seeker:install [testing-skill]
```

Claude will apply all frameworks simultaneously.

### How long do skills stay loaded?

Skills remain loaded for your current Claude session. They're automatically unloaded when:
- You close Claude
- You explicitly unload them with `/skill-seeker:unload`
- You restart Claude

## Security

### Is it safe to load community skills?

Every skill passes through a comprehensive security scanner before installation. The scanner checks for:

**Critical threats** (auto-blocked):
- Instruction overrides ("ignore previous instructions")
- Shell command injection
- Data exfiltration attempts

**High-risk threats** (auto-blocked):
- Hidden HTML content
- Social engineering
- Encoded payloads

**Medium threats** (warning shown):
- Conversation injection
- Unicode obfuscation
- Frontmatter abuse

Skills flagged as HIGH or CRITICAL are blocked by default. You must explicitly acknowledge findings to proceed.

### What if a skill tries to do something malicious?

The security scanner detects and blocks malicious patterns. However, always:
1. Review the security scan results
2. Check the repository's reputation (stars, activity)
3. Look at the trust score
4. Preview the skill content before accepting

Report any suspicious skills via GitHub issues.

### Can skills access my files?

No. Skills are markdown files with prompts - they don't execute code. They only shape how Claude thinks about and approaches tasks.

### How do I report a security vulnerability?

See [SECURITY.md](SECURITY.md) for our security policy and reporting process.

## Troubleshooting

### "Command not found" error

**Problem**: `/skill-seeker:seek` returns "command not found"

**Solutions**:
1. Verify Skill-Seeker is in your plugins directory
2. Restart Claude Code
3. Check that plugin.json is valid:
```bash
cat .claude-plugin/plugin.json | jq
```

### "No skills found" when searching

**Problem**: Search returns no results

**Solutions**:
1. Try broader search terms: "frontend" instead of "react-hooks-best-practices"
2. Check your internet connection (for GitHub API search)
3. Search the registry directly:
```bash
./scripts/search-registry.sh frontend
```
4. Check GitHub API rate limits:
```bash
curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit
```

### Skills not loading properly

**Problem**: Skill installs but doesn't seem to work

**Solutions**:
1. Verify the skill loaded:
```bash
/skill-seeker:unload  # Shows all loaded skills
```
2. Be specific in your requests to Claude: "Apply the design audit framework to this code"
3. Unload conflicting skills that might interfere
4. Try reloading the skill

### "Security scan failed" error

**Problem**: Security scanner crashes or fails

**Solutions**:
1. Verify Python 3 is installed:
```bash
python3 --version
```
2. Check the skill file is valid markdown:
```bash
curl https://raw.githubusercontent.com/owner/repo/main/path/to/SKILL.md
```
3. Report the issue with the skill URL

### Rate limit exceeded

**Problem**: "API rate limit exceeded" error

**Solutions**:
1. Set GitHub token:
```bash
export GITHUB_TOKEN=ghp_your_token_here
```
This increases limit from 60 to 5,000 requests/hour

2. Search the registry instead (no rate limits):
```bash
/skill-seeker:seek [query]
# Registry results appear first
```

3. Wait for rate limit reset (shown in error message)

### Slow search results

**Problem**: Searches take a long time

**Solutions**:
1. Use the curated registry (instant results)
2. Check internet connection
3. GitHub API might be slow - try again later
4. Reduce search complexity

## Contributing

### How do I add my skill to the registry?

See [CONTRIBUTING-REGISTRY.md](CONTRIBUTING-REGISTRY.md) for detailed instructions. Quick summary:

1. Ensure your skill meets quality criteria:
   - Repository has 10+ stars
   - Updated within last 6 months
   - Well-documented
   - Passes security scan

2. Submit a PR adding your skill to `registry.json`

3. Include:
   - Description
   - Tags and aliases
   - Repository info
   - Domain categorization

### What makes a good skill?

Good skills are:
- **Specific**: Focus on one area (e.g., "React Hooks" not "Programming")
- **Actionable**: Provide concrete guidance, not just theory
- **Well-documented**: Include examples and use cases
- **Tested**: Verify it actually improves Claude's output
- **Maintained**: Actively updated and improved

### Can I create my own skills?

Yes! Skills are just markdown files. Create a repository with a `.claude/skills/` directory and add your SKILL.md files. See existing skills for examples:
- [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- [msitarzewski/agency-agents](https://github.com/msitarzewski/agency-agents)

### How do I report bugs?

Open an issue on GitHub using our bug report template:
https://github.com/mmmantasrrr/skill-seeker/issues/new/choose

Include:
- Command you ran
- Expected behavior
- Actual behavior
- Error messages
- Your environment (OS, Claude version)

## Advanced Usage

### Can I use this with other AI assistants?

Skill-Seeker is designed for Claude Code, but the skills themselves (markdown prompt files) can be adapted for other AI systems. The search and installation features are Claude Code-specific.

### Can I create private skills?

Yes! Skills can be in private repositories. You'll need:
1. GitHub token with private repo access
2. Use the full path when installing
3. Note that private skills won't appear in public search results

### How do I bulk install skills?

Create a script:
```bash
#!/bin/bash
/skill-seeker:install repo1/skill1.md
/skill-seeker:install repo2/skill2.md
/skill-seeker:install repo3/skill3.md
```

Or use the registry to find multiple skills and install them sequentially.

### Can I customize skill behavior?

Skills are markdown files with prompts. You can:
1. Fork the skill repository
2. Modify the SKILL.md file
3. Install from your fork

Or create a completely custom skill for your specific needs.

### How do I see what's in a skill before installing?

Use the browse command:
```bash
/skill-seeker:browse owner/repo
```

This shows all skills in the repository. Then view the file on GitHub before installing.

## Performance

### Does using skills slow down Claude?

Skills add context to Claude's prompts, which:
- Increases token usage slightly
- May increase response time marginally (usually imperceptible)
- Significantly improves output quality

The quality improvement far outweighs the minimal performance impact.

### How many skills can I load at once?

Technically unlimited, but practically:
- **1-2 skills**: Optimal for focused tasks
- **3-5 skills**: Good for complex multi-faceted projects
- **6+ skills**: May dilute effectiveness or conflict

Unload unnecessary skills for best results.

### Does this use my Claude API quota?

Skill-Seeker commands (search, install) don't use Claude API calls. The skills themselves add context to your Claude prompts, which does count toward your usage, but the added value typically justifies the small increase.

## Future Features

### What's on the roadmap?

See our [Roadmap](README.md#-roadmap) for upcoming features:
- Multi-source search (GitLab, Bitbucket)
- Local caching and offline mode
- Semantic search with embeddings
- Usage analytics and recommendations
- Browser-based skill marketplace

### Can I request features?

Yes! Open a feature request:
https://github.com/mmmantasrrr/skill-seeker/issues/new/choose

We prioritize features based on:
- Community demand
- Implementation feasibility
- Alignment with project goals

### Will this always be free?

Yes. Skill-Seeker is MIT licensed and will always be free and open source.

---

## Still Have Questions?

- Check the main [README](README.md)
- Read the [Architecture documentation](ARCHITECTURE.md)
- Browse [Examples](EXAMPLES.md)
- Open an [issue](https://github.com/mmmantasrrr/skill-seeker/issues)
- Start a [discussion](https://github.com/mmmantasrrr/skill-seeker/discussions)
