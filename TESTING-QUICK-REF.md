# Quick Testing Reference for skill-seeker v2.0

This is a quick reference guide for testing all v2.0 features. For comprehensive documentation, see TESTING-WALKTHROUGH-V2.md.

## Quick Test Commands

### 1. Combined Search (Phase B)
```bash
bash scripts/search-combined.sh "design"
```
**Expected:** Unified results from registry + GitHub, no duplicates

### 2. Registry ID Resolution (Phase C)
```bash
bash scripts/resolve-skill-id.sh "metaskills-skill-builder"
bash scripts/resolve-skill-id.sh "pbakaus-impeccable"
```
**Expected:** Returns repo, path, name, description

### 3. Browse Repository
```bash
bash scripts/search-github.sh --browse "metaskills/skill-builder"
```
**Expected:** List of skills with token counts

### 4. Security Scanner
```bash
python3 tests/test_scan_skill.py
```
**Expected:** All 34 tests pass

### 5. JSON Validity Check
```bash
bash scripts/search-combined.sh "test" | jq empty && echo "✅ Valid JSON"
bash scripts/resolve-skill-id.sh "impeccable" | jq empty && echo "✅ Valid JSON"
```
**Expected:** Both output "✅ Valid JSON"

## Feature Verification Checklist

### Context Overhead (Phase A)
- [ ] SKILL.md is ~343 tokens (down from ~961)
- [ ] unload.md is ~179 tokens (down from ~505)
- [ ] Security protocol moved to install.md
- [ ] Token budgets moved to install.md

### Combined Search (Phase B)
- [ ] search-combined.sh exists and is executable
- [ ] Returns unified JSON with source attribution
- [ ] Deduplicates by repository name
- [ ] Registry results take priority

### Registry Quick-Install (Phase C)
- [ ] resolve-skill-id.sh exists and is executable
- [ ] Resolves IDs with and without -v1 suffix
- [ ] install.md documents registry ID support
- [ ] Flexible matching works (partial IDs)

### Status Command (Phase D)
- [ ] commands/status.md exists
- [ ] Documents conversation history review
- [ ] Shows token counts and context budget
- [ ] Lists cached skills for reload

### Project Profiles (Phase E)
- [ ] .skill-seeker-profile.example.json exists
- [ ] PROJECT-PROFILES.md comprehensive guide exists
- [ ] SKILL.md mentions profile check
- [ ] Valid JSON schema

### Cache Reload (Phase F)
- [ ] commands/reload.md exists
- [ ] Documents SHA256 integrity check
- [ ] Supports partial matching
- [ ] Lists cached skills when no target

### Auto-Browse (Phase G)
- [ ] seek.md mentions auto-browse for HIGH trust
- [ ] Documented as optional optimization
- [ ] Security checkpoint still required

## Quick Metrics Check

```bash
# Token counts
wc -c skills/seeking-skills/SKILL.md | awk '{print "SKILL.md:", $1/4, "tokens"}'
wc -c commands/unload.md | awk '{print "unload.md:", $1/4, "tokens"}'

# Test results
python3 tests/test_scan_skill.py 2>&1 | tail -1

# File existence
ls -1 scripts/search-combined.sh scripts/resolve-skill-id.sh commands/status.md commands/reload.md 2>&1 | wc -l
# Should output: 4
```

## Common Issues

### Issue: search-combined.sh returns error
**Fix:** Check that search-registry.sh and search-github.sh work individually

### Issue: resolve-skill-id.sh returns "not found"
**Fix:** Check registry.json for correct skill ID format

### Issue: Tests fail
**Fix:** Ensure Python 3 is installed and scan-skill.py hasn't been modified

## Full Documentation

- **Complete walkthrough:** TESTING-WALKTHROUGH-V2.md
- **Implementation details:** IMPLEMENTATION-SUMMARY.md
- **Project profiles guide:** PROJECT-PROFILES.md
- **Original v1 testing:** TESTING_REPORT.md
