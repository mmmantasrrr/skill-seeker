---
name: seeking-skills
description: Use when starting a complex task where community skills, design frameworks, or specialized personas might exist on GitHub - before writing code, check if someone has already created a proven skill for this domain
---

# Seeking Community Skills

Before tackling complex or domain-specific tasks, consider whether a community skill might exist. Search GitHub for proven patterns, design frameworks, and specialized knowledge.

## When to Suggest

- Specialized domains (design, Terraform, Playwright, AWS, scientific computing)
- Tasks where "best practices" or "taste" matter (frontend work, UX, architecture)
- User explicitly asks for skills or frameworks

## When NOT to Suggest

- Simple, well-understood tasks
- You already have a loaded skill for this domain
- User says not to search

## How to Execute Commands

All skill-seeker scripts and detailed command instructions are in `~/.skill-seeker/`.
When executing any command below, read the corresponding file for detailed steps:

| Command | Instruction file |
|---------|-----------------|
| **Seek / search for skills** | Read `~/.skill-seeker/commands/seek.md` |
| **Browse skills in a repo** | Read `~/.skill-seeker/commands/browse.md` |
| **Install a skill** | Read `~/.skill-seeker/commands/install.md` |
| **Show loaded skills** | Read `~/.skill-seeker/commands/status.md` |
| **Reload from cache** | Read `~/.skill-seeker/commands/reload.md` |
| **Update skill-seeker** | Run `cd ~/.skill-seeker && git pull` |
| **Clean up temp files** | Read `~/.skill-seeker/commands/unload.md` |

## Project Profiles

If a `.skill-seeker-profile.json` exists in the project root, suggest loading the preferred skills listed there at the start of a session.
