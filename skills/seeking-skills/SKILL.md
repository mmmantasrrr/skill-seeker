---
name: seeking-skills
description: Use when starting a complex task where community skills, design frameworks, or specialized personas might exist on GitHub - before writing code, check if someone has already created a proven skill for this domain
---

# Seeking Community Skills

Before tackling complex or domain-specific tasks, consider whether a community skill might exist. Use `/skill-seeker:seek <query>` to search GitHub for proven patterns, design frameworks, and specialized knowledge.

## When to Suggest

- Specialized domains (design, Terraform, Playwright, AWS, scientific computing)
- Tasks where "best practices" or "taste" matter (frontend work, UX, architecture)
- User explicitly asks for skills or frameworks

## When NOT to Suggest

- Simple, well-understood tasks
- You already have a loaded skill for this domain
- User says not to search

## Available Commands

- `/skill-seeker:seek <query>` — Search for skills
- `/skill-seeker:browse <owner/repo>` — List skills in a repo
- `/skill-seeker:install <target>` — Fetch and install a skill
- `/skill-seeker:status` — Show loaded skills
- `/skill-seeker:reload` — Load from cache
- `/skill-seeker:update` — Check for and apply plugin updates
- `/skill-seeker:unload` — Clean up temp files

## Project Profiles

If a `.skill-seeker-profile.json` exists in the project root, suggest loading the preferred skills listed there at the start of a session.
