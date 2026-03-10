# Project Skill Profiles

Project skill profiles allow you to define preferred skills for your project, enabling Claude Code to suggest them at the start of each session. This eliminates the repetitive seek → browse → install flow for skills you use daily.

## Overview

A `.skill-seeker-profile.json` file in your project root tells skill-seeker which skills are most relevant to your work. When Claude Code starts a new session, it checks for this file and proactively suggests loading the specified skills.

**Important**: All suggestions still require user approval. This feature makes discovery faster, not automatic.

## Creating a Profile

1. Copy the example file:
   ```bash
   cp .skill-seeker-profile.example.json .skill-seeker-profile.json
   ```

2. Edit the file to specify your preferred skills:
   ```json
   {
     "version": "1.0.0",
     "auto_suggest": [
       {
         "skill_id": "pbakaus-impeccable-v1",
         "repo": "pbakaus/impeccable",
         "path": ".claude/skills/impeccable/SKILL.md",
         "reason": "Frontend project requiring design standards",
         "enabled": true
       }
     ]
   }
   ```

3. Commit the profile to your repository so team members can benefit too.

## Profile Schema

### Root Fields

- `version` (string, required): Schema version (currently "1.0.0")
- `description` (string, optional): Human-readable description of this profile
- `auto_suggest` (array, required): List of skills to suggest at session start
- `disabled_skills` (array, optional): List of skill IDs to never suggest
- `notes` (string, optional): Additional context or instructions

### Skill Entry Fields

- `skill_id` (string, required): Registry ID (e.g., "pbakaus-impeccable-v1")
- `repo` (string, required): GitHub repository (owner/repo format)
- `path` (string, required): Path to SKILL.md within the repo
- `reason` (string, required): Why this skill is recommended for this project
- `enabled` (boolean, optional): Whether to suggest this skill (default: true)

## How It Works

1. **Session Start**: Claude Code checks for `.skill-seeker-profile.json` in the project root
2. **Suggestion**: If found, Claude suggests enabled skills with their reasons
3. **User Choice**: You can accept all, select specific skills, or skip
4. **Loading**: Accepted skills are installed (or reloaded from cache) automatically
5. **Efficiency**: Skills in cache are reloaded in seconds without re-fetching

## Example Use Cases

### Frontend Development Project
```json
{
  "version": "1.0.0",
  "auto_suggest": [
    {
      "skill_id": "pbakaus-impeccable-v1",
      "repo": "pbakaus/impeccable",
      "path": ".claude/skills/impeccable/SKILL.md",
      "reason": "Enforce design system compliance and accessibility",
      "enabled": true
    }
  ]
}
```

### Skill Development Project
```json
{
  "version": "1.0.0",
  "auto_suggest": [
    {
      "skill_id": "metaskills-skill-builder-v1",
      "repo": "metaskills/skill-builder",
      "path": "reference/skill-structure-and-format.md",
      "reason": "Reference for creating well-structured skills",
      "enabled": true
    },
    {
      "skill_id": "refly-ai-skill-builder-v1",
      "repo": "refly-ai/refly",
      "path": "skills/",
      "reason": "Alternative skill-building patterns",
      "enabled": false
    }
  ]
}
```

### Infrastructure/DevOps Project
```json
{
  "version": "1.0.0",
  "auto_suggest": [
    {
      "skill_id": "terraform-best-practices",
      "repo": "cloudposse/terraform-best-practices",
      "path": ".claude/skills/terraform/SKILL.md",
      "reason": "Terraform code quality and security patterns",
      "enabled": true
    }
  ],
  "notes": "This project uses Terraform 1.5+ with AWS provider"
}
```

## Benefits

- **Eliminate Repetition**: No more seeking/browsing the same skills every session
- **Team Consistency**: Team members get the same skill recommendations
- **Context Awareness**: New contributors immediately see which skills matter
- **Flexibility**: Enable/disable skills without removing them from the profile
- **Fast Loading**: Cached skills reload in under a second

## Best Practices

1. **Be Selective**: Only include skills you use in >50% of sessions
2. **Document Reasons**: Help teammates understand why each skill matters
3. **Use Registry IDs**: Prefer verified skills from the registry for reliability
4. **Commit the Profile**: Make it part of your project's setup documentation
5. **Update Regularly**: Remove skills that become less relevant over time

## Privacy & Security

- Profile files contain only public repository references (no secrets)
- All skill installations still go through security scanning
- User approval is always required before loading any skill
- Profiles are project-specific, not user-specific

## Disabling Skills

To temporarily disable a skill without removing it from the profile:

```json
{
  "skill_id": "example-skill-v1",
  "enabled": false
}
```

To permanently block a skill from being suggested:

```json
{
  "disabled_skills": ["unwanted-skill-id"]
}
```

## Troubleshooting

**Profile not being detected?**
- Ensure the file is named exactly `.skill-seeker-profile.json`
- Verify it's in the project root directory (same level as .git/)
- Check that the JSON is valid (use a JSON validator)

**Skills failing to load?**
- Make sure the skill is already in cache or can be fetched
- Check that repo/path fields match the actual GitHub structure
- Try installing the skill manually first to verify it works

**Too many suggestions?**
- Set `enabled: false` for skills you don't need right now
- Remove skills that are no longer relevant to the project
- Consider splitting profiles if your project has distinct work modes

## See Also

- `/skill-seeker:reload` - Quickly reload cached skills
- `/skill-seeker:status` - See which skills are currently loaded
- `registry.json` - Browse available verified skills
