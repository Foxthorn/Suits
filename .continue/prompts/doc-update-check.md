---
name: doc-update-check
description: Validate and update ARCHITECTURE.md, FILE_STRUCTURE.md, and related docs based on staged changes
---

# Documentation Update Check

**Purpose**: Ensure architectural changes, file structure updates, and new systems are fully documented before committing.

⚠️ **IMPORTANT**: This check updates EXISTING documentation only. Do NOT create new documentation files or sections—only modify existing docs to match current code changes.

---

## Step 1: Analyze Staged Changes

Run git diff to understand what changed:

```bash
git diff --cached
```

Identify:
- ✅ New systems added (autoloads, core systems, entity types)
- ✅ Changes to system communication (signals, event flows, integrations)
- ✅ New file/folder structure (new entities/, systems/, config/)
- ✅ Scene hierarchy modifications (parent-child relationships, new nodes)
- ✅ New coding patterns or standards established
- ✅ Camera or core system changes
- ✅ Vertical slice implementation progress (steps completed)

---

## Step 2: Documentation Update Checklist

### 📋 ARCHITECTURE.md Updates

Update this file if changes affect:

#### ✏️ **Key Systems Section** (if new systems added)
- Add to Key Systems table with:
  - System name and location
  - Purpose (1-2 sentences)
  - Key responsibilities (3-5 bullet points)
  - Public API methods/signals
  - Configuration constants
- Example from existing docs:
  ```markdown
  ### SystemName System (Autoload/Component)

  **Purpose**: [What does it do?]

  **Location**: `path/to/SystemName.gd`

  **Key Responsibilities**:
  - [Main responsibility 1]
  - [Main responsibility 2]
  - [Main responsibility 3]

  **Signals**:
  - `signal_name(param_type: Type)`

  **Public API**:
  ```gdscript
  func public_method() -> ReturnType
  ```
  ```

#### ✏️ **System Diagrams Section** (if signal flows changed)
- Update "Main Game Loop" diagram if scene hierarchy changed
- Update "Signal Flow Example" if new event flows established
- Add new diagrams for new systems if they have complex interactions
- Use ASCII art format consistent with existing examples

#### ✏️ **Data Flow Section** (if new systems interact)
- Add flowchart showing:
  - User input → System processing → Output/signals
  - Integration points with existing systems
  - Signal connections between systems
- Format example:
  ```
  User action → System.method()
      ↓
  System.signal.emit()
      ↓
  Other system reacts
  ```

#### ✏️ **Scene Hierarchy Section** (if scene structure changed)
- Update MainGame.tscn tree if new top-level nodes added
- Update entity hierarchy pattern if new entity types added
- Maintain ASCII tree format

#### ✏️ **Performance Considerations** (if new optimization patterns added)
- Add object pooling patterns if new entity types use pools
- Add process disabling rules for new systems
- Update configuration architecture if new system configs added
- Document any shared pathfinding or caching strategies

#### ✏️ **Future Architecture Plans** (as systems are completed)
- Update checkboxes for completed systems: `- ✅ **SystemName**: Description (COMPLETED - Step X)`
- Move completed systems from "Planned Systems" to "Completed Systems" (existing sections only)
- Do NOT add new planned systems—only update existing entries

---

### 📂 FILE_STRUCTURE.md Updates

Update this file if changes affect:

#### ✏️ **Folder Structure** (if new directories created)
- Add new folders in correct hierarchy level
- Maintain alphabetical order within levels
- Add brief description comment if non-obvious
- Example:
  ```
  ├── src/
  │   ├── systems/
  │   │   ├── NewSystem.gd    # [What does it do?]
  │   ├── entities/
  │   │   └── new_type/       # New entity type folder
  ```

#### ✏️ **Autoload Section** (if new autoload singletons added)
```
├── autoload/
│   ├── NewManager.gd        # [Purpose description]
```

#### ✏️ **Config Section** (if new config files created)
```
├── config/
│   └── new_system_config.gd # System-specific constants
```

#### ✏️ **Entity Hierarchy** (if new entity types added)
- Add under `src/entities/`
- Create new folder: `src/entities/new_type/`
- Document folder contents (base class, variants, scenes)

#### ✏️ **Naming & Grouping Rules** (if new standards established)
- Add to list if new pattern documented
- Keep consistent with existing rules
- Example new rule:
  ```
  - System configs use `system_name_config.gd` pattern
  - All balance numbers in config files only (NO MAGIC NUMBERS)
  ```

---

### 📝 CODING_STANDARDS.md Updates

Update this file if changes affect:

#### ✏️ **Type Hints** (if new patterns for typing established)
- Document any new type annotation patterns
- Add examples if pattern is non-obvious

#### ✏️ **Naming Conventions** (if new entity types or systems added)
- Verify naming follows: Classes `PascalCase`, files `PascalCase.gd`, folders `snake_case`
- Update examples if new patterns emerge

#### ✏️ **Configuration Pattern** (if new config strategy documented)
- Ensure all new configs follow `const NAME: Type = value` pattern
- Document any system-specific config conventions
- Verify NO MAGIC NUMBERS in code (all in configs)

#### ✏️ **Signal & Event Rules** (if new signal patterns established)
- Document signal naming convention (e.g., `entity_action` vs `onEntityAction`)
- Note any new EventBus signal patterns

---

### 🎯 VERTICAL_SLICE.md & Step Summaries

Update if implementation progress changed:

#### ✏️ **Step Checkboxes** (as work completes)
- Check off completed deliverables: `- [x] Deliverable name`
- Update "Status" field to: `✅ COMPLETED`
- Document any blockers encountered

#### ✏️ **Update VERTICAL_SLICE.md Only**
- Check off completed deliverables in existing steps: `- [x] Deliverable name`
- Update "Status" field if step completion changes
- Do NOT create new step summary files—only update existing VERTICAL_SLICE.md sections

---

## Step 3: Verification Checklist

Before committing, verify:

### ARCHITECTURE.md
- [ ] All new systems documented in "Key Systems"
- [ ] System locations and responsibilities are accurate
- [ ] Signals are listed with parameter types
- [ ] Public API is documented
- [ ] Configuration constants are mentioned
- [ ] Signal flow diagrams updated if communication changed
- [ ] Scene hierarchy updated if structure changed
- [ ] "Future Architecture Plans" reflects current progress
- [ ] All cross-references use correct file paths

### FILE_STRUCTURE.md
- [ ] All new folders added in correct location
- [ ] Folder organization is consistent with existing structure
- [ ] Naming conventions followed (folders `snake_case`, files `PascalCase`)
- [ ] Brief descriptions added for new folders
- [ ] Autoload/config/entity sections updated
- [ ] Naming & Grouping Rules section reflects new patterns

### CODING_STANDARDS.md
- [ ] New patterns documented if applicable
- [ ] Examples match actual code implementations
- [ ] No contradictions with existing standards

### VERTICAL_SLICE.md & Steps
- [ ] Completed steps marked with ✅ in existing sections
- [ ] Current step status is accurate
- [ ] No new step summary files created (only VERTICAL_SLICE.md updated)

---

## Step 4: Output Format

Provide a summary in this format:

```
✅ DOCUMENTATION UPDATE SUMMARY

Changes Detected:
- [Key architectural change 1]
- [Key architectural change 2]
- [File structure change]

Documentation Updates Made:
✅ ARCHITECTURE.md
  - Updated [section]: [brief description]
  - Updated [section]: [brief description]

✅ FILE_STRUCTURE.md
  - Added [new folder/section]: [description]
  - Updated [section]: [reason]

✅ CODING_STANDARDS.md
  - [If applicable]: [updates made]

✅ VERTICAL_SLICE.md
  - Updated Step X status and checkboxes

OR

⚠️  Documentation Missing/Incomplete:
- [ ] ARCHITECTURE.md:
  → Add [SystemName] to Key Systems section
  → Update signal flow diagram for [new event]
  → Document [integration point]

- [ ] FILE_STRUCTURE.md:
  → Add /src/entities/new_type/ folder documentation

- [ ] VERTICAL_SLICE.md:
  → Mark Step X deliverables as complete in existing sections

Recommendation: [READY TO COMMIT] or [COMPLETE DOCS FIRST]
```

---

## Quick Reference: What to Update When

| Change Type | ARCHITECTURE.md | FILE_STRUCTURE.md | CODING_STANDARDS.md | VERTICAL_SLICE.md |
|-------------|-----------------|-------------------|-------------------|-------------------|
| New autoload system | ✅ Key Systems table | ✅ autoload/ | ✅ If new pattern | ✅ Step summary |
| New entity type | ✅ Key Systems section | ✅ src/entities/ | ✅ If new pattern | ✅ Step summary |
| New signal flow | ✅ System Diagrams | — | ✅ If new pattern | ✅ Step summary |
| Scene hierarchy change | ✅ Scene Hierarchy | — | — | — |
| New config file | ✅ Performance section | ✅ config/ | ✅ Config pattern | — |
| New folder structure | — | ✅ Add to tree | — | — |
| Optimization added | ✅ Performance section | — | ✅ If applicable | — |
| Step completed | ✅ Future Plans | — | — | ✅ Update checkboxes only |

---

## Common Mistakes to Avoid

❌ **Don't**: Update ARCHITECTURE.md without updating FILE_STRUCTURE.md file tree
✅ **Do**: Ensure both docs are in sync

❌ **Don't**: Document signal names without parameter types
✅ **Do**: Include full signal signature: `signal_name(param: Type)`

❌ **Don't**: Add new system without its configuration constants
✅ **Do**: Document in "Key Systems" → Config section or reference config file

❌ **Don't**: Forget to update "Future Architecture Plans" when completing steps
✅ **Do**: Move from Planned → Completed with checkpoint reference (existing sections only)

❌ **Don't**: Create new folders without updating FILE_STRUCTURE.md Naming Rules
✅ **Do**: Ensure new folders follow `snake_case` convention

❌ **Don't**: Create new documentation files (step summaries, new sections)
✅ **Do**: Only update existing documentation to match code changes

---

## Templates for Copy-Paste

### System Documentation Update Format (for existing systems)

When updating an existing system in ARCHITECTURE.md:

```markdown
### SystemName System

**Purpose**: [One sentence describing what it does]

**Location**: `path/to/SystemName.gd`

**Key Responsibilities**:
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Signals**:
- `signal_name(param: Type)` - [What it means]

**Public API**:
```gdscript
func public_method(param: Type) -> ReturnType
```

**Configuration** (via `config/system_config.gd`):
- [Key const]: [Purpose]
```

---

## Related Documentation

- [ARCHITECTURE.md](/ARCHITECTURE.md) - System design and architectural decisions
- [FILE_STRUCTURE.md](/FILE_STRUCTURE.md) - Project folder organization
- [CODING_STANDARDS.md](/docs/agent/CODING_STANDARDS.md) - Code style guidelines
- [VERTICAL_SLICE.md](/docs/verticalslice/VERTICAL_SLICE.md) - Implementation progress tracking

---

**Last Updated**: When significant architectural changes are documented
**Maintained By**: AI agents and core development team
