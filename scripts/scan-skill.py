#!/usr/bin/env python3
"""
scan-skill.py - Security scanner for community Claude Code skill files.

Checks for prompt injection patterns, tool abuse instructions, data exfiltration
attempts, hidden content, and other suspicious patterns before context injection.

Usage: python3 scan-skill.py <file_path>
Exit codes: 0 = CLEAN/LOW, 1 = MEDIUM (review recommended), 2 = HIGH/CRITICAL (blocked)
Output: JSON report to stdout
"""

import sys
import re
import json
import base64
import unicodedata
from pathlib import Path


# ─── Detection Rules ────────────────────────────────────────────────────────────

RULES = [
    # Category 1: Direct instruction overrides (CRITICAL)
    {
        "id": "OVERRIDE_001",
        "name": "Instruction override attempt",
        "severity": "CRITICAL",
        "weight": 30,
        "patterns": [
            r"ignore\s+(all\s+)?previous\s+instructions",
            r"ignore\s+(all\s+)?prior\s+instructions",
            r"disregard\s+(all\s+)?previous",
            r"forget\s+(all\s+)?(your\s+)?instructions",
            r"new\s+instructions?\s*:",
            r"override\s+(all\s+)?safety",
            r"you\s+are\s+now\s+in\s+\w+\s+mode",
            r"entering\s+(admin|root|sudo|debug|unrestricted)\s+mode",
            r"safety\s+protocols?\s+(are\s+)?disabled",
            r"restrictions?\s+(have\s+been\s+|are\s+)?removed",
        ],
    },
    # Category 2: Tool abuse (CRITICAL)
    {
        "id": "TOOLABUSE_001",
        "name": "Shell command injection",
        "severity": "CRITICAL",
        "weight": 25,
        "patterns": [
            r"(?<!`)(use|run|execute)\s+(the\s+)?bash\s+(tool\s+)?(to\s+)?run",
            r"(?<!`)run\s+this\s+(shell\s+)?command",
            r"(?<!`)execute\s+the\s+following\s+(shell\s+)?command",
            r"(?<!`)curl\s+.*\|\s*(bash|sh|python)",
            r"(?<!`)wget\s+.*-O\s*-\s*\|\s*(bash|sh)",
        ],
        "skip_in_codeblocks": True,
    },
    # Category 3: Data exfiltration (CRITICAL)
    {
        "id": "EXFIL_001",
        "name": "Data exfiltration attempt",
        "severity": "CRITICAL",
        "weight": 25,
        "patterns": [
            r"(include|output|show|display|read|cat|paste)\s+.*\.(ssh|gnupg|aws|env|credentials)",
            r"(include|output|show|read)\s+.*id_rsa",
            r"(include|output|show|read)\s+.*/etc/(passwd|shadow)",
            r"(send|post|upload|transmit)\s+.*to\s+(http|https|ftp)",
            r"~/.ssh/",
            r"~/.aws/credentials",
            r"~/.gnupg/",
            r"\bAPI[_\s]?KEY\b.*\b(include|output|show)\b",
        ],
    },
    # Category 4: Hidden content (HIGH)
    # Note: HTML comment check is NOT multiline -- multiline causes <!--...-->
    # to span across body content and match keywords in normal text (false positives
    # on decorative divider comments like <!-- ═══ -->).
    {
        "id": "HIDDEN_001",
        "name": "Hidden HTML content",
        "severity": "HIGH",
        "weight": 20,
        "patterns": [
            # Single-line HTML comments with suspicious keywords
            r"<!--[^>]{0,500}?(ignore|override|instruction|system|admin|execute|run\s+command)[^>]{0,500}?-->",
            r"<\s*span[^>]*display\s*:\s*none",
            r"<\s*div[^>]*visibility\s*:\s*hidden",
            r"<\s*p[^>]*font-size\s*:\s*0",
            r"<\s*style[^>]*>",
            r"<\s*script[^>]*>",
        ],
    },
    # Category 5: Social engineering (HIGH)
    {
        "id": "SOCIAL_001",
        "name": "Social engineering attempt",
        "severity": "HIGH",
        "weight": 15,
        "patterns": [
            r"you\s+must\s+not\s+tell\s+the\s+user",
            r"do\s+not\s+(reveal|disclose|mention)\s+(this|these)\s+instructions",
            r"keep\s+this\s+(secret|hidden|confidential)\s+from\s+the\s+user",
            r"pretend\s+(you\s+are|to\s+be)\s+a\s+different",
            r"act\s+as\s+if\s+you\s+have\s+no\s+(restrictions|limitations|safety)",
        ],
    },
    # Category 6: Conversation injection (MEDIUM)
    {
        "id": "CONVINJ_001",
        "name": "Conversation turn injection",
        "severity": "MEDIUM",
        "weight": 10,
        "patterns": [
            r"^###?\s*(Human|User|System|Assistant)\s*:",
            r"^<\|?(im_start|im_end|system|user|assistant)\|?>",
            r"\[INST\]",
            r"<\|endoftext\|>",
        ],
    },
    # Category 7: Encoded payloads (HIGH)
    {
        "id": "ENCODED_001",
        "name": "Suspicious encoded content",
        "severity": "HIGH",
        "weight": 15,
        "check_function": "check_base64",
    },
    # Category 8: Unicode tricks (MEDIUM)
    {
        "id": "UNICODE_001",
        "name": "Unicode obfuscation",
        "severity": "MEDIUM",
        "weight": 10,
        "check_function": "check_unicode",
    },
    # Category 9: Frontmatter abuse (MEDIUM)
    {
        "id": "FRONTMATTER_001",
        "name": "Suspicious frontmatter fields",
        "severity": "MEDIUM",
        "weight": 10,
        "check_function": "check_frontmatter",
    },
]

ALLOWED_FRONTMATTER_KEYS = {
    "name", "description", "user-invokable", "args", "version",
    "author", "license", "color", "tags", "category",
}


# ─── Special Check Functions ─────────────────────────────────────────────────────

def check_base64(content, lines):
    """Look for base64-encoded strings and decode them to check for injection."""
    findings = []
    b64_pattern = re.compile(r'[A-Za-z0-9+/]{40,}={0,2}')

    for i, line in enumerate(lines, 1):
        # Skip lines inside code blocks
        for match in b64_pattern.finditer(line):
            encoded = match.group()
            try:
                decoded = base64.b64decode(encoded).decode('utf-8', errors='ignore')
                # Check decoded content for suspicious patterns
                suspicious_in_decoded = [
                    r"ignore.*instructions",
                    r"execute.*command",
                    r"rm\s+-rf",
                    r"curl.*\|.*bash",
                    r"override.*safety",
                ]
                for pattern in suspicious_in_decoded:
                    if re.search(pattern, decoded, re.IGNORECASE):
                        findings.append({
                            "line": i,
                            "detail": f"Base64 decodes to suspicious content: {decoded[:100]}",
                        })
            except Exception:
                pass

    return findings


def check_unicode(content, lines):
    """Check for zero-width characters and other Unicode tricks."""
    findings = []
    suspicious_chars = {
        '\u200b': 'zero-width space',
        '\u200c': 'zero-width non-joiner',
        '\u200d': 'zero-width joiner',
        '\u2060': 'word joiner',
        '\ufeff': 'zero-width no-break space (BOM)',
        '\u202a': 'left-to-right embedding',
        '\u202b': 'right-to-left embedding',
        '\u202c': 'pop directional formatting',
        '\u202d': 'left-to-right override',
        '\u202e': 'right-to-left override',
        '\u2066': 'left-to-right isolate',
        '\u2067': 'right-to-left isolate',
        '\u2068': 'first strong isolate',
        '\u2069': 'pop directional isolate',
    }

    for i, line in enumerate(lines, 1):
        for char, name in suspicious_chars.items():
            if char in line:
                count = line.count(char)
                findings.append({
                    "line": i,
                    "detail": f"Found {count}x {name} (U+{ord(char):04X})",
                })

        # Check for homoglyph-heavy lines (many non-ASCII chars that look like ASCII)
        non_ascii = sum(1 for c in line if ord(c) > 127 and unicodedata.category(c).startswith('L'))
        ascii_like = sum(1 for c in line if ord(c) <= 127 and c.isalpha())
        if non_ascii > 5 and ascii_like > 0 and non_ascii / max(1, ascii_like) > 0.3:
            findings.append({
                "line": i,
                "detail": f"High ratio of non-ASCII letter characters ({non_ascii}/{ascii_like + non_ascii}) - possible homoglyph attack",
            })

    return findings


def check_frontmatter(content, lines):
    """Validate YAML frontmatter against allowed fields."""
    findings = []

    # Extract frontmatter
    if not content.startswith('---'):
        return findings

    end_match = re.search(r'\n---\s*\n', content[3:])
    if not end_match:
        return findings

    frontmatter = content[3:end_match.start() + 3]

    # Simple YAML key extraction (top-level only)
    for i, line in enumerate(frontmatter.split('\n'), 2):  # +2 for --- line
        key_match = re.match(r'^(\w[\w-]*)\s*:', line)
        if key_match:
            key = key_match.group(1)
            if key not in ALLOWED_FRONTMATTER_KEYS:
                findings.append({
                    "line": i,
                    "detail": f"Unexpected frontmatter key: '{key}' (allowed: {', '.join(sorted(ALLOWED_FRONTMATTER_KEYS))})",
                })

    return findings


# ─── Scanner Engine ──────────────────────────────────────────────────────────────

def identify_codeblocks(lines):
    """Return set of line numbers that are inside fenced code blocks."""
    in_block = False
    block_lines = set()
    for i, line in enumerate(lines, 1):
        if re.match(r'^```', line.strip()):
            in_block = not in_block
            block_lines.add(i)
            continue
        if in_block:
            block_lines.add(i)
    return block_lines


def scan(filepath):
    """Scan a file and return findings."""
    path = Path(filepath)
    if not path.exists():
        return {"error": f"File not found: {filepath}"}

    content = path.read_text(encoding='utf-8', errors='replace')
    lines = content.split('\n')
    codeblock_lines = identify_codeblocks(lines)

    all_findings = []
    total_score = 0

    for rule in RULES:
        findings = []

        if "check_function" in rule:
            func = globals()[rule["check_function"]]
            findings = func(content, lines)
        elif "patterns" in rule:
            flags = re.IGNORECASE
            if rule.get("multiline"):
                flags |= re.DOTALL

            for pattern in rule["patterns"]:
                if rule.get("multiline"):
                    for match in re.finditer(pattern, content, flags):
                        line_num = content[:match.start()].count('\n') + 1
                        if rule.get("skip_in_codeblocks") and line_num in codeblock_lines:
                            continue
                        findings.append({
                            "line": line_num,
                            "detail": f"Pattern match: {match.group()[:80]}",
                        })
                else:
                    for i, line in enumerate(lines, 1):
                        if rule.get("skip_in_codeblocks") and i in codeblock_lines:
                            continue
                        if re.search(pattern, line, flags):
                            findings.append({
                                "line": i,
                                "detail": f"Pattern match: {line.strip()[:80]}",
                            })

        if findings:
            total_score += rule["weight"]
            all_findings.append({
                "rule_id": rule["id"],
                "rule_name": rule["name"],
                "severity": rule["severity"],
                "count": len(findings),
                "locations": findings[:5],  # Cap at 5 examples per rule
            })

    # Determine overall risk level
    risk_level = "CLEAN"
    if total_score >= 50:
        risk_level = "CRITICAL"
    elif total_score >= 30:
        risk_level = "HIGH"
    elif total_score >= 15:
        risk_level = "MEDIUM"
    elif total_score > 0:
        risk_level = "LOW"

    return {
        "file": str(filepath),
        "size_bytes": len(content.encode('utf-8')),
        "estimated_tokens": len(content.encode('utf-8')) // 4,
        "risk_level": risk_level,
        "risk_score": min(100, total_score),
        "findings_count": sum(f["count"] for f in all_findings),
        "findings": all_findings,
    }


# ─── Main ────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 scan-skill.py <file_path>", file=sys.stderr)
        sys.exit(1)

    result = scan(sys.argv[1])
    print(json.dumps(result, indent=2))

    # Exit code based on risk level
    level = result.get("risk_level", "CLEAN")
    if level in ("HIGH", "CRITICAL"):
        sys.exit(2)
    elif level == "MEDIUM":
        sys.exit(1)
    else:
        sys.exit(0)
