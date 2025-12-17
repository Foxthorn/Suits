---
name: commit
description: Generate a commit message for current staged changes
---

Please analyze the current git changes and generate a commit message following these guidelines:

1. **Run git commands** to understand what changed:
   - `git status` to see staged files
   - `git diff --cached` to see the actual changes

2. **Generate a conventional commit message** with:
   - **Title**: One line, max 72 characters, format: `type: brief description`
     - Types: feat, fix, refactor, docs, style, test, chore
   - **Description**: Bulleted list (3-5 items) highlighting key changes

3. **Format the output** as:
   ```
   Title:
   <commit title>

   Description:
   <bulleted description>
   ```

4. **Guidelines**:
   - Focus on *what* and *why*, not *how*
   - Group related changes together
   - Mention architectural decisions if applicable
   - Keep it concise but informative

Example output:
```
Title:
refactor: Fix camera architecture and add living documentation system

Description:
- Fixed duplicate camera systems by passing Camera2D to HexGrid instead of internal creation
- Added ARCHITECTURE.md as comprehensive living document for system design
- Integrated all agent docs with cross-references to ARCHITECTURE.md
- Removed changelog references from docs (git history handles this)
- Added AI agent rule to keep ARCHITECTURE.md updated on architectural changes
```
