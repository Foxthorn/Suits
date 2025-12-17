---
name: pre-commit
description: Verify relevant documentation has been updated before committing
---

Please analyze the current staged changes and verify that all relevant project documentation has been updated.

**Step 1: Analyze Changes**
Run `git diff --cached` and identify:
- New systems, autoloads, or major components
- Changes to system communication (signals, event flows)
- New file/folder structure
- Scene hierarchy modifications
- New coding patterns or standards
- Camera or core system changes
- Vertical slice implementation progress

**Step 2: Check Documentation Updates**
Based on the changes, verify these docs were updated if relevant:

📋 **ARCHITECTURE.md** - Update if:
- New systems added → Add to "Key Systems" section
- Signal flows changed → Update "System Diagrams" or "Data Flow"
- Scene hierarchy modified → Update "Scene Hierarchy"
- Camera/core systems changed → Update relevant subsection
- Performance patterns added → Update "Performance Considerations"

📂 **docs/agent/FILE_STRUCTURE.md** - Update if:
- New folders created
- File organization changed
- New file naming conventions

📝 **docs/agent/CODING_STANDARDS.md** - Update if:
- New coding patterns established
- Style guidelines changed
- New anti-patterns identified

🎯 **docs/agent/VERTICAL_SLICE.md** - Update if:
- Step deliverables completed → Check off checkboxes
- Implementation approach changed

**Step 3: Generate Report**

Provide output in this format:

```
✅ PRE-COMMIT DOCUMENTATION CHECK

Changes Detected:
- [List key changes from git diff]

Documentation Status:
✅ ARCHITECTURE.md - Updated (or ✅ No update needed)
✅ FILE_STRUCTURE.md - Updated (or ✅ No update needed)
✅ CODING_STANDARDS.md - Updated (or ✅ No update needed)
✅ VERTICAL_SLICE.md - Updated (or ✅ No update needed)

OR

⚠️  Missing Documentation Updates:
- [ ] ARCHITECTURE.md needs update:
  → Add MyNewSystem to "Key Systems" section
  → Update signal flow diagram for new events
- [ ] FILE_STRUCTURE.md needs update:
  → Document new /src/entities/towers/ folder

Recommendation: [READY TO COMMIT] or [UPDATE DOCS FIRST]
```

**Guidelines:**
- Only flag documentation that's actually relevant to the changes
- Be specific about what sections need updates
- If everything is good, give a clear ✅ READY TO COMMIT
- If docs are missing, provide actionable guidance on what to update
