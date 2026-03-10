# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in skill-seeker, please report it by emailing the maintainers or opening a private security advisory on GitHub.

**Please do not open public issues for security vulnerabilities.**

## Security Model

Skill-Seeker implements a comprehensive security scanner that analyzes community-created skills before they're loaded into Claude's context. This helps protect against:

### Critical Threats
- **Instruction overrides**: Attempts to bypass or modify AI behavior patterns
- **Shell command injection**: Malicious tool usage or piped commands
- **Data exfiltration**: Attempts to read sensitive files (SSH keys, credentials, environment variables)

### High-Risk Threats
- **Hidden HTML content**: Invisible text, CSS tricks, or embedded scripts
- **Social engineering**: Instructions to hide information from users
- **Encoded payloads**: Base64 or other encoded malicious content

### Medium-Risk Threats
- **Conversation injection**: Fake turn markers or prompt format exploitation
- **Unicode obfuscation**: Zero-width characters, RTL overrides, homoglyphs
- **Frontmatter abuse**: Unexpected YAML keys that could alter behavior

## Risk Levels

The security scanner assigns risk scores:
- **CLEAN** (0): No security concerns detected
- **LOW** (1–14): Minor concerns, generally safe
- **MEDIUM** (15–29): Moderate concerns, review recommended
- **HIGH** (30–49): Significant concerns, blocked by default
- **CRITICAL** (50+): Severe security risks, blocked by default

Skills flagged as HIGH or CRITICAL require explicit user acknowledgment before installation.

## Security Best Practices

When creating or contributing skills:

1. **Keep skills simple**: Use plain markdown without HTML, scripts, or encoded content
2. **Be transparent**: All instructions should be clearly visible to users
3. **Avoid tool abuse**: Don't include patterns that could be used for command injection
4. **Respect privacy**: Never attempt to access files outside the current working directory
5. **Follow conventions**: Use standard frontmatter keys and markdown formatting

## Auditing Skills

Before installing a skill, review:
- The repository's reputation (stars, forks, last update)
- The skill's trust score in the registry
- Security scan results
- The actual markdown content

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Security Updates

Security updates are released as soon as possible after vulnerabilities are discovered and verified. Check the [CHANGELOG](CHANGELOG.md) for security-related updates.
