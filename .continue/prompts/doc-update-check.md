---
name: doc-update-check
description: Quick validation that ARCHITECTURE.md, FILE_STRUCTURE.md, and related docs are updated to match staged changes
---

# Documentation Update Check

**Core Rule**: Only update EXISTING documentation to match code changes. Do NOT create new files or sections.

---

## Quick Reference: What to Update When

| Change Type | ARCHITECTURE.md | FILE_STRUCTURE.md | CODING_STANDARDS.md | VERTICAL_SLICE.md |
|---|---|---|---|---|
| New systems added | ✅ Key Systems | ✅ autoload/config/ | ✅ Checkboxes |
| New entity type | ✅ Key Systems | ✅ src/entities/ | ✅ Checkboxes |
| Signal flows changed | ✅ Diagrams/Data Flow | — | ✅ Checkboxes |
| Scene hierarchy changed | ✅ Scene Hierarchy | — | — |
| Config files added | ✅ Performance section | ✅ config/ | — |
| New folders | — | ✅ Folder tree | — |
| Step completed | ✅ Future Architecture Plans | — | ✅ Check deliverables |

---

## Pre-Commit Process

### Step 1: Analyze Changes
```bash
git diff --cached
```
Identify: new systems, entity types, signal flows, scene changes, config updates, folder structure, step progress.

### Step 2: Check Documentation
Use the table above to determine what docs need updating.

### Step 3: Update Relevant Files Only
- **ARCHITECTURE.md** - Systems, signals, diagrams, scene structure, performance patterns
- **FILE_STRUCTURE.md** - Folder organization, naming conventions, autoload/config sections
- **CODING_STANDARDS.md** - New coding patterns or style guidelines (if applicable)
- **VERTICAL_SLICE.md** - Check off completed deliverables in existing sections only

### Step 4: Report Status

```
✅ DOCUMENTATION CHECK

Changes Detected:
- [List key changes]

Status:
✅ ARCHITECTURE.md - [Updated / No update needed]
✅ FILE_STRUCTURE.md - [Updated / No update needed]
✅ VERTICAL_SLICE.md - [Updated / No update needed]

Recommendation: [READY TO COMMIT] or [UPDATE DOCS FIRST]
```

---

## ARCHITECTURE.md Updates

Update these sections if changes affect them:

- **Key Systems** - System name, location, purpose, responsibilities, signals, public API, config
- **System Diagrams** - Main Game Loop, Signal Flow, Data Flow (if communication changed)
- **Scene Hierarchy** - MainGame.tscn tree structure if new nodes added
- **Performance Considerations** - Object pooling, caching, process disabling, config architecture
- **Future Architecture Plans** - Update checkboxes for completed systems (existing entries only)

---

## FILE_STRUCTURE.md Updates

Update these sections if changes affect them:

- **Folder Structure** - Add new folders in correct hierarchy, maintain alphabetical order
- **Autoload Section** - New autoload singletons with brief descriptions
- **Config Section** - New config files with comments on purpose
- **Entity Hierarchy** - New entity types under `src/entities/`
- **Naming & Grouping Rules** - New patterns if established (folders `snake_case`, files `PascalCase`)

---

## VERTICAL_SLICE.md Updates

Update only if step deliverables completed:

- Check off completed deliverables: `- [x] Deliverable name`
- Update Step status to: `✅ COMPLETED`
- **Do NOT** create new step summary files—only update existing VERTICAL_SLICE.md sections

---

## Critical Don'ts ❌

- ❌ Create new documentation files or sections
- ❌ Document signals without parameter types: must be `signal_name(param: Type)`
- ❌ Add systems without documenting configuration
- ❌ Leave ARCHITECTURE.md and FILE_STRUCTURE.md out of sync
- ❌ Create new step summaries—only update existing VERTICAL_SLICE.md sections
- ❌ Add magic numbers to code (all in config files)
- ❌ Skip updating Future Architecture Plans when steps complete

---

## Related Documentation

- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design and architectural decisions
- [FILE_STRUCTURE.md](/FILE_STRUCTURE.md) - Project folder organization
- [VERTICAL_SLICE.md](/docs/verticalslice/VERTICAL_SLICE.md) - Implementation progress tracking
