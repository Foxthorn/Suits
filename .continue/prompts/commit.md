---
name: commit
description: Generate a commit message for current staged changes
---

Please analyze the current git changes and generate a commit message following these guidelines:

1. **Run git commands** to understand what changed:
   - `git status` to see staged files
   - `git diff --cached` to see the actual changes

2. ## Git Commit Message Guidelines (based on Chris Beams - https://cbea.ms/git-commit/)
   # Follow these 7 rules for clean, professional, and tool-friendly commit messages:

   - Separate subject from body with a blank line
      - Subject = one-line summary
      - Blank line
      - Body (optional detailed explanation)

   - Limit the subject line to 50 characters
      - Aim for ~50 chars (72 max) so it displays well in git log, rebase, etc.
      - Forces you to keep commits small & focused

   - Capitalize the subject line
      - Start with uppercase letter (e.g. "Add user authentication")

   - Do not end the subject line with a period
      - Saves space and looks cleaner in most tools

   - Use the imperative mood in the subject ("command" style)
      - Good: "Add", "Fix", "Refactor", "Update", "Remove"
      - Bad: "Added", "Fixes", "Updating", "Removed"
      - Think: "This commit will <subject>"

   - Wrap the body at 72 characters
      - Keep lines ≤72 chars for readability in terminals/editors
      - Use hard line breaks

   - Use the body to explain WHAT and WHY vs. HOW
      - WHAT: Describe the change & its effects
      - WHY: Explain the motivation/context (bug, requirement, decision)
      - HOW: belongs in the code/diff — not the commit message

   Example good commit:

   Add support for dark mode

   Implement system preference detection and manual toggle.
   Update all main UI components to support light/dark themes.
   Fix color contrast issues in dark mode for accessibility.

   Fixes #123

3. **Format the output** as:
   ```
   Title:
   <commit title>

   Description:
   <bulleted description>
   ```
