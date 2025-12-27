---
name: standards-check
description: Validate staged changes against CODING_STANDARDS.md rules
---

Check current staged changes against CODING_STANDARDS.md rules:

1. **Run git diff to see changes:**
   ```
   git diff --cached
   ```

2. **Validate against these critical rules:**

   - **Type Hints**: All variables and functions have explicit type annotations (no `Variant` inference)
   - **Self References**: Public variables/functions use `self.`, private ones don't
   - **No Magic Numbers**: All hardcoded values in configs or named constants
   - **Signals Over Coupling**: No direct node references across systems
   - **Naming Conventions**: Variables/functions `snake_case`, constants `SCREAMING_SNAKE_CASE`, classes `PascalCase`
   - **Caching**: No `get_node()` or expensive lookups in loops
   - **Object Pooling**: Entities use pools for 1000+ enemy support
   - **File Naming**: `.gd`/`.tscn` as `PascalCase`, folders as `snake_case`
   - **Docstrings**: All public functions have `##` documentation
   - **One Class Per File**: File name matches class name

3. **Report format:**

   ```
   ✅ CODING STANDARDS CHECK

   Files Changed:
   - [List files]

   Issues Found:
   - [If any violations detected]

   OR

   ✅ All standards met - ready to commit
   ```

4. **For violations, provide:**
   - File path and line number
   - Which rule violated
   - What to fix (concrete example)
