# Troubleshooting Guide

This guide helps you diagnose and fix common issues with Skill-Seeker.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Search Problems](#search-problems)
- [Installation Failures](#installation-failures)
- [Security Scanner Issues](#security-scanner-issues)
- [Performance Problems](#performance-problems)
- [GitHub API Issues](#github-api-issues)
- [General Debugging](#general-debugging)

## Installation Issues

### Problem: "Command not found" when running skill-seeker commands

**Symptoms**:
```
$ /skill-seeker:seek frontend
-bash: /skill-seeker:seek: No such file or directory
```

**Diagnosis**:
```bash
# Check if plugin is installed (inside Claude Code)
/plugin
# Go to the "Installed" tab and look for skill-seeker
```

**Solutions**:

1. **Install via the plugin marketplace**:
```
# Inside Claude Code:
/plugin marketplace add mmmantasrrr/skill-seeker
/plugin install skill-seeker@skill-seeker
```

2. **Restart Claude Code**:
After installing, restart Claude Code completely.

3. **Test locally**:
```bash
git clone https://github.com/mmmantasrrr/skill-seeker.git
claude --plugin-dir ./skill-seeker
```

4. **Verify file permissions**:
```bash
chmod +x scripts/*.sh
chmod +x scripts/*.py
```

---

### Problem: "Missing dependencies" error

**Symptoms**:
```
Error: curl not found
Error: jq not found
Error: python3 not found
```

**Diagnosis**:
```bash
# Check which dependencies are missing
which curl    # Should output: /usr/bin/curl
which jq      # Should output: /usr/bin/jq
which python3 # Should output: /usr/bin/python3
```

**Solutions**:

**On macOS**:
```bash
# Install using Homebrew
brew install curl jq python3
```

**On Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install curl jq python3
```

**On CentOS/RHEL**:
```bash
sudo yum install curl jq python3
```

**On Windows (WSL)**:
```bash
sudo apt-get install curl jq python3
```

---

## Search Problems

### Problem: "No skills found" for common queries

**Symptoms**:
```
$ /skill-seeker:seek react
No skills found matching "react"
```

**Diagnosis**:
```bash
# Test registry search directly
./scripts/search-registry.sh react

# Test GitHub API connectivity
curl -s https://api.github.com/rate_limit
```

**Solutions**:

1. **Check internet connection**:
```bash
ping -c 3 github.com
```

2. **Try broader search terms**:
```bash
# Instead of very specific:
/skill-seeker:seek react-hooks-typescript-patterns

# Try broader:
/skill-seeker:seek react patterns
```

3. **Search registry directly** (no internet needed):
```bash
cd /path/to/skill-seeker
./scripts/search-registry.sh react
```

4. **Check for typos**:
Common misspellings:
- "frontned" → "frontend"
- "javascipt" → "javascript"
- "kuberntes" → "kubernetes"

---

### Problem: Search returns irrelevant results

**Symptoms**:
Results don't match what you're looking for.

**Solutions**:

1. **Use more specific terms**:
```bash
# Too broad:
/skill-seeker:seek code

# Better:
/skill-seeker:seek python code quality

# Best:
/skill-seeker:seek python pep8 style guide
```

2. **Check synonyms in registry**:
The registry expands queries. View synonyms:
```bash
cat registry.json | jq '.query_synonyms'
```

3. **Use exact repository if known**:
```bash
/skill-seeker:browse pbakaus/impeccable
```

---

### Problem: Search is very slow

**Symptoms**:
Search takes 30+ seconds or times out.

**Diagnosis**:
```bash
# Check internet speed
curl -o /dev/null https://speed.cloudflare.com/__down?bytes=1000000

# Check GitHub API status
curl -s https://www.githubstatus.com/api/v2/status.json | jq
```

**Solutions**:

1. **Use registry search** (instant):
```bash
# Registry is cached locally, no API calls
/skill-seeker:seek [query]
# First results are always from registry
```

2. **Check network issues**:
```bash
# Test API latency
time curl -s https://api.github.com/ > /dev/null
```

3. **GitHub API might be slow**:
Check https://www.githubstatus.com/ for service issues.

4. **Reduce concurrent searches**:
Wait for one search to complete before starting another.

---

## Installation Failures

### Problem: "Failed to fetch skill" error

**Symptoms**:
```
Error: Failed to fetch skill from https://raw.githubusercontent.com/...
```

**Diagnosis**:
```bash
# Test URL directly
curl -I https://raw.githubusercontent.com/owner/repo/main/path/to/SKILL.md

# Check if repo exists
curl -s https://api.github.com/repos/owner/repo
```

**Solutions**:

1. **Verify URL is correct**:
- Check repository name spelling
- Verify branch name (main vs master)
- Confirm file path is correct

2. **Check if repo is private**:
```bash
# Set GitHub token for private repos
export GITHUB_TOKEN=ghp_your_token_here
```

3. **Verify file exists**:
Visit the URL in your browser:
```
https://github.com/owner/repo/blob/main/path/to/SKILL.md
```

4. **Repository might be deleted or renamed**:
Search for the skill again to find updated location.

---

### Problem: "Security scan blocked installation"

**Symptoms**:
```
Security scan detected HIGH risk issues.
Installation blocked for your safety.
```

**Diagnosis**:
Review the security scan output shown in the error message.

**Solutions**:

1. **Review what was detected**:
Security scanner found potentially malicious patterns. Check:
- Instruction overrides?
- Shell command injection?
- Data exfiltration attempts?

2. **If it's a false positive**:
- Review the skill content manually
- Understand why it was flagged
- If safe, you can override (use with caution)

3. **Report the issue**:
If you believe it's a false positive, open an issue with:
- Skill URL
- Security scan output
- Why you think it's safe

4. **Find alternative skills**:
```bash
/skill-seeker:seek [same topic]
# Look for skills with higher trust scores
```

---

### Problem: Skill installs but doesn't work

**Symptoms**:
Skill loads successfully but Claude doesn't apply it.

**Diagnosis**:
```bash
# Verify skill is loaded
/skill-seeker:unload
# Check the list of loaded skills
```

**Solutions**:

1. **Be explicit in your request**:
```
# Instead of:
"Review this code"

# Try:
"Apply the [skill name] framework to review this code"
```

2. **Check for skill conflicts**:
Multiple skills might conflict. Unload others:
```bash
/skill-seeker:unload
# Remove conflicting skills, keep only the one you need
```

3. **Reload the skill**:
```bash
/skill-seeker:unload
/skill-seeker:install [same-skill-path]
```

4. **Verify skill content**:
Visit the skill file on GitHub to ensure it has actual content.

---

## Security Scanner Issues

### Problem: "Security scanner crashed"

**Symptoms**:
```
Error: Python script failed
Traceback...
```

**Diagnosis**:
```bash
# Test scanner directly
python3 scripts/scan-skill.py --help

# Check Python version
python3 --version  # Should be 3.6+
```

**Solutions**:

1. **Verify Python installation**:
```bash
python3 --version
# Should output: Python 3.x.x
```

2. **Test scanner manually**:
```bash
echo "# Test skill" > /tmp/test-skill.md
python3 scripts/scan-skill.py /tmp/test-skill.md
```

3. **Check skill file encoding**:
Some files with unusual encoding can crash the scanner:
```bash
file path/to/SKILL.md
# Should show: UTF-8 Unicode text
```

4. **Update Python**:
If using Python < 3.6, update to a newer version.

---

### Problem: "Too many false positives"

**Symptoms**:
Safe skills are flagged as HIGH risk.

**Solutions**:

1. **Review specific detections**:
The scanner shows what was detected. Common false positives:
- Legitimate HTML examples in documentation
- Example code showing security vulnerabilities (educational)

2. **Check trust score**:
High trust score (60+) indicates community-validated safety.

3. **Manual review**:
Read the skill content yourself before installing.

4. **Report false positives**:
Open an issue so we can improve the scanner.

---

## Performance Problems

### Problem: Claude responses are slow after loading skills

**Symptoms**:
Noticeable delay in Claude's responses.

**Solutions**:

1. **Unload unnecessary skills**:
```bash
/skill-seeker:unload
# Remove skills you're not currently using
```

2. **Load fewer skills**:
Recommended: 1-3 skills for focused work
Maximum: 5-6 skills for complex projects

3. **Use more specific skills**:
Specific skills have less content than broad ones:
- ✅ "React Hooks Patterns" (focused)
- ❌ "Complete JavaScript Guide" (too broad)

---

### Problem: High memory usage

**Symptoms**:
System becomes slow, high RAM usage.

**Solutions**:

1. **Unload all skills**:
```bash
/skill-seeker:unload
# Remove all loaded skills
```

2. **Restart Claude**:
Fresh start clears all cached content.

3. **Load skills one at a time**:
Only load what you need for the current task.

---

## GitHub API Issues

### Problem: "Rate limit exceeded"

**Symptoms**:
```
Error: API rate limit exceeded.
Rate limit will reset in 32 minutes.
```

**Diagnosis**:
```bash
# Check current rate limit
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/rate_limit
```

**Solutions**:

1. **Set GitHub token**:
```bash
# Create token at https://github.com/settings/tokens
export GITHUB_TOKEN=ghp_your_token_here

# Add to shell profile for persistence
echo 'export GITHUB_TOKEN=ghp_your_token' >> ~/.bashrc
source ~/.bashrc
```

This increases limit from 60 to 5,000 requests/hour.

2. **Use registry search** (no limits):
```bash
# Registry searches don't use API
/skill-seeker:seek [query]
```

3. **Wait for reset**:
Check when rate limit resets:
```bash
curl https://api.github.com/rate_limit | jq '.rate.reset'
date -r 1234567890  # Replace with the reset timestamp
```

---

### Problem: "API authentication failed"

**Symptoms**:
```
Error: Bad credentials
```

**Solutions**:

1. **Check token format**:
```bash
echo $GITHUB_TOKEN
# Should start with: ghp_
```

2. **Verify token is valid**:
```bash
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/user
```

3. **Create new token**:
- Go to https://github.com/settings/tokens
- Generate new token (classic)
- Select scope: `public_repo` (minimum)
- Copy token immediately (shown only once)

4. **Unset invalid token**:
```bash
unset GITHUB_TOKEN
# Will use unauthenticated access (60 req/hour)
```

---

## General Debugging

### Enable Debug Mode

Add verbose output to diagnose issues:

```bash
# Enable bash debugging
export DEBUG=1

# Run command with detailed output
bash -x scripts/search-github.sh "test query"
```

### Check Logs

```bash
# View recent command output
# (varies by shell and system)

# Check system logs (macOS)
log show --predicate 'process == "Claude"' --last 10m

# Check system logs (Linux)
journalctl -u claude-code --since "10 minutes ago"
```

### Test Individual Components

```bash
# Test registry search
./scripts/search-registry.sh test

# Test GitHub API search
./scripts/search-github.sh test

# Test skill fetching
./scripts/fetch-skill.sh owner/repo path/to/skill.md

# Test security scanner
python3 scripts/scan-skill.py tests/fixtures/clean-skill.md
```

### Get System Info

When reporting bugs, include:

```bash
# Operating system
uname -a

# Dependency versions
curl --version
jq --version
python3 --version

# Plugin version
cat .claude-plugin/plugin.json | jq '.version'

# Registry version
cat registry.json | jq '.version'
```

---

## Still Having Issues?

If none of these solutions work:

1. **Search existing issues**:
https://github.com/mmmantasrrr/skill-seeker/issues

2. **Open a new issue**:
https://github.com/mmmantasrrr/skill-seeker/issues/new

Include:
- Problem description
- Steps to reproduce
- Error messages (full output)
- System information
- What you've already tried

3. **Check documentation**:
- [README](README.md)
- [FAQ](FAQ.md)
- [Architecture](ARCHITECTURE.md)

4. **Community help**:
- Start a discussion
- Ask in Claude Code community forums

---

## Prevention

### Regular Maintenance

```bash
# Update Skill-Seeker
cd /path/to/skill-seeker
git pull origin main

# Update dependencies
brew upgrade curl jq python3  # macOS
sudo apt-get upgrade curl jq python3  # Linux

# Clean cache (if experiencing issues)
rm -rf /tmp/claude-skills-cache
```

### Best Practices

1. **Keep GitHub token fresh**:
Tokens expire. Regenerate annually.

2. **Unload skills when done**:
Prevents conflicts and improves performance.

3. **Review security scans**:
Don't blindly override security warnings.

4. **Monitor rate limits**:
If doing heavy searching, set up a token.

5. **Report bugs**:
Help improve Skill-Seeker by reporting issues.

---

## Frequently Asked Questions

### How is this different from MCP tools?

| Feature | Skill-Seeker (Skills) | MCP Tools |
|---------|----------------------|-----------|
| **Type** | Behavioral frameworks (prompts) | Executable code |
| **Purpose** | Shape AI thinking | Add capabilities |
| **Installation** | Markdown files | Binary/code installation |
| **Security** | Content scanning | Code execution |

**Use Skill-Seeker when**: You want Claude to apply specific thinking patterns, frameworks, or best practices.

**Use MCP tools when**: You need Claude to interact with external systems or execute code.

### What's a "trust score"?

Trust scores indicate skill quality based on:
- Repository stars (log scale, max 40 points)
- Recent activity (updated within 30 days, max 20 points)
- Fork count (log scale, max 15 points)
- Proper GitHub topics (5 points)
- Not archived, has description, has license (5 points each)

**Score ranges**: **60+** (HIGH) → **40–59** (MEDIUM) → **<40** (LOW)

### Can I load multiple skills at once?

Yes! You can install multiple complementary skills sequentially. Claude will apply all frameworks simultaneously. For best results, limit to 1–3 focused skills per session and unload any you no longer need.

### How do I preview a skill before installing?

Use the browse command to list all skills in a repository:
```bash
/skill-seeker:browse owner/repo
```

Then view the raw file on GitHub before installing.

### Can I create my own skills?

Yes! Skills are plain markdown files. Create a repository with a `.claude/skills/` directory, add your `SKILL.md` files, and install from your repo. See [pbakaus/impeccable](https://github.com/pbakaus/impeccable) for a reference example.

### Can I use private repositories?

Yes. You'll need a `GITHUB_TOKEN` with private repo access:
```bash
export GITHUB_TOKEN=ghp_your_token_here
/skill-seeker:install owner/private-repo/path/to/SKILL.md
```

Note: private skills won't appear in public search results.

---

**Need more help?** Open an [issue](https://github.com/mmmantasrrr/skill-seeker/issues) or start a [discussion](https://github.com/mmmantasrrr/skill-seeker/discussions).
