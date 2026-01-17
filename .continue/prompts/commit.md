---
name: commit
description: Generate a commit message for current staged changes
---

Please analyze the current git changes and generate a commit message following these guidelines:

1. **Run git commands** to understand what changed:
   - `git status` to see staged files
   - `git diff --cached` to see the actual changes

2. **Commit format**
   - Ensure commit messages follow [Chris Beams](http://chris.beams.io/posts/git-commit/) style for commit messages.

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
