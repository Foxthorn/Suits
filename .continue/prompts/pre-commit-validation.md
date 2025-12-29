---
name: pre-commit-validation
description: Complete pre-commit validation - check documentation updates, coding standards, and generate commit message
---

# Pre-Commit Validation & Documentation Check

**Purpose**: Ensure all staged changes are properly documented, follow coding standards, and generate appropriate commit messages before committing.

This prompt combines three critical checks:
1. **Documentation Validation** - ARCHITECTURE.md, FILE_STRUCTURE.md, CODING_STANDARDS.md, VERTICAL_SLICE.md
2. **Coding Standards Check** - Type hints, naming conventions, magic numbers, signals, etc.
3. **Commit Message Generation** - Conventional commits with detailed descriptions

---

## Phase 1: Analyze Staged Changes

### Step 1.1: View Current Changes

Run these commands to understand what's being committed:

```bash
git status
git diff --cached
```

### Step 1.2: Identify Change Categories

From the diff output, categorize changes:

**Architecture Changes**:
- ✅ New systems/autoloads added?
- ✅ System communication changes (signals, event flows)?
- ✅ Core system modifications (Camera, GameManager, etc.)?
- ✅ Scene hierarchy changes?
- ✅ New optimization patterns?

**Structure Changes**:
- ✅ New folders created (`/systems/`, `/entities/`, `/config/`)?
- ✅ File organization modified?
- ✅ Naming convention changes?

**Code Pattern Changes**:
- ✅ New coding patterns established?
- ✅ New standards to document?

**Progress Changes**:
- ✅ Vertical slice steps completed?
- ✅ Major implementation milestones?

---

## Phase 2: Documentation Validation

### Step 2.1: Check ARCHITECTURE.md Updates

For each architectural change detected, verify:

#### New Systems Added?
- [ ] System documented in "Key Systems" section with:
  - System name and location: `path/to/System.gd`
  - Purpose statement (1-2 sentences)
  - Key Responsibilities (3-5 bullet points)
  - Public API methods/signals with parameter types
  - Configuration constants (or reference to config file)
  - Example:
    ```markdown
    ### SystemName System

    **Purpose**: [What does it do?]

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

#### Signal Flows Changed?
- [ ] "System Diagrams" section updated
- [ ] "Data Flow" section updated with new connections
- [ ] ASCII diagrams use consistent formatting
- [ ] All new signals documented with parameter types

#### Scene Hierarchy Modified?
- [ ] "Scene Hierarchy" section reflects current structure
- [ ] MainGame.tscn tree representation is accurate
- [ ] Entity hierarchy pattern documented if changed

#### Camera or Core System Changes?
- [ ] Relevant subsections updated
- [ ] Integration points with other systems documented
- [ ] Any new signals/methods added to documentation

#### Performance Patterns Added?
- [ ] Object pooling patterns documented if applicable
- [ ] Caching strategies explained
- [ ] Configuration constants referenced

#### Vertical Slice Progress?
- [ ] "Future Architecture Plans" section updated
- [ ] Completed systems marked: `- ✅ **SystemName**: Description (COMPLETED - Step X)`
- [ ] New planned systems identified and listed
- [ ] Implementation order reflects dependencies

---

### Step 2.2: Check FILE_STRUCTURE.md Updates

For each structural change detected, verify:

#### New Folders Created?
- [ ] Added to correct hierarchy level
- [ ] Alphabetical order maintained within level
- [ ] Brief description comment added
- [ ] Example:
  ```
  ├── src/
  │   ├── systems/
  │   │   ├── NewSystem.gd    # [Purpose]
  │   ├── entities/
  │   │   └── new_type/       # New entity type folder
  ```

#### Autoload Section Needs Update?
- [ ] New autoload singletons documented:
  ```
  ├── autoload/
  │   ├── NewManager.gd        # [Purpose description]
  ```

#### Config Section Needs Update?
- [ ] New config files documented:
  ```
  ├── config/
  │   └── new_system_config.gd # System-specific constants
  ```

#### Entity Hierarchy Changed?
- [ ] New entity types documented under `src/entities/`
- [ ] New folders created: `src/entities/new_type/`
- [ ] Folder contents documented (base class, variants, scenes)

#### Naming & Grouping Rules Need Update?
- [ ] New patterns documented in "Naming & Grouping Rules" section
- [ ] Examples match actual code organization
- [ ] Consistency with existing rules maintained

---

### Step 2.3: Check CODING_STANDARDS.md Updates

For each code pattern change detected, verify:

#### Type Hints
- [ ] All functions have parameter type hints: `func name(param: Type) -> ReturnType`
- [ ] All variables have explicit type annotations: `var name: Type`
- [ ] No use of `Variant` (inferred types)
- [ ] New type annotation patterns documented if applicable

#### Naming Conventions
- [ ] Classes: `PascalCase`
- [ ] Functions/Variables: `snake_case`
- [ ] Constants: `SCREAMING_SNAKE_CASE`
- [ ] Private members: no `self.` prefix
- [ ] Public members: use `self.` prefix
- [ ] File names: `PascalCase.gd` for classes
- [ ] Folder names: `snake_case`
- [ ] Documentation updated if new patterns established

#### Magic Numbers
- [ ] NO hardcoded values in code
- [ ] All balance values in config files only
- [ ] Named constants for any repeated values
- [ ] Configuration pattern documented: `const NAME: Type = value`

#### Signals & Events
- [ ] Signal naming convention documented: `entity_action` format
- [ ] All signals include parameter types: `signal_name(param: Type)`
- [ ] No direct node references across systems
- [ ] EventBus patterns documented if used

#### Other Code Patterns
- [ ] Caching strategy (no `get_node()` in loops)
- [ ] Object pooling patterns documented if applicable
- [ ] Docstring requirements: all public functions have `##` comments
- [ ] One class per file rule maintained
- [ ] No coupling between systems (use signals)

---

### Step 2.4: Check VERTICAL_SLICE.md & Step Summaries

For implementation progress changes, verify:

#### Step Completion
- [ ] Completed deliverables marked: `- [x] Deliverable name`
- [ ] Status field updated: `✅ COMPLETED`
- [ ] Step summary created if step is complete:
  - File: `docs/verticalslice/STEP_X_STEP_NAME.md`
  - Includes: Systems created, key files, integration points, limitations
- [ ] Current step status accurately reflects work done
- [ ] Blockers/dependencies documented

---

## Phase 3: Coding Standards Validation

### Step 3.1: Check Against Code Standards Rules

Scan the actual file changes for violations:

```
✅ CRITICAL STANDARDS (must pass):
  - Type hints on all functions and variables
  - No magic numbers in code (config only)
  - No duplicate code (use functions/components)
  - Signals used instead of direct node references
  - One class per file

⚠️  IMPORTANT STANDARDS:
  - Naming conventions followed (cases, prefixes)
  - Self references for public members
  - Documentation on public functions
  - Caching for expensive operations
  - Object pooling for 1000+ entities

📋 DOCUMENTATION STANDARDS:
  - Public API documented
  - Complex logic explained
  - Signals documented with parameter types
```

### Step 3.2: Specific Checks Per File Type

**For .gd files**:
- [ ] All functions: `func name(param: Type) -> ReturnType`
- [ ] All variables: `var name: Type` or `const NAME: Type`
- [ ] Public functions have `##` docstring
- [ ] No `get_node()` or `$` in loops/frequently called code
- [ ] Signals include full signature: `signal name(param: Type)`
- [ ] No magic numbers (reference config constants)

**For .tscn files**:
- [ ] Scene structure matches documentation
- [ ] Node naming follows conventions
- [ ] Scripts attached are properly typed

**For config files**:
- [ ] All constants follow: `const NAME: Type = value`
- [ ] Values grouped logically with comments
- [ ] Related constants use common prefix
- [ ] All magic numbers extracted from code

---

## Phase 4: Generate Commit Message

### Step 4.1: Conventional Commit Format

Generate a commit message following conventional commits:

```
<type>: <brief description (max 72 chars)>

<description - bulleted list of key changes>

<footer - if applicable>
```

**Type Options**:
- `feat` - New feature or system added
- `fix` - Bug fix
- `refactor` - Code restructuring without feature changes
- `docs` - Documentation updates
- `style` - Code style changes (formatting, no logic change)
- `test` - Test additions/modifications
- `chore` - Build, deps, tooling changes

### Step 4.2: Title Generation

Summarize the change in one line, max 72 characters:

**Examples**:
- `feat: Add camera system with zoom and follow mechanics`
- `refactor: Separate input handling from game logic`
- `docs: Update ARCHITECTURE.md with new systems`
- `feat: Implement object pooling for 1000+ enemy support`

### Step 4.3: Description Generation

Create 3-5 bullet points highlighting:
- What changed (not how)
- Why it changed (architectural reason)
- Integration points
- Key new features or patterns
- Files/systems affected

**Example**:
```
- Added Camera2D system as core autoload for unified camera control
- Implemented camera follow mechanics with configurable speed/distance
- Integrated signal-based camera commands (pan, zoom, focus_entity)
- Created camera_config.gd with all balance constants
- Refactored MainGame.tscn to use Camera2D system instead of inline camera
```

---

## Phase 5: Final Validation Checklist

Before generating report, verify:

### Documentation Completeness
- [ ] ARCHITECTURE.md: All new systems in Key Systems
- [ ] ARCHITECTURE.md: Signal flows updated if changed
- [ ] ARCHITECTURE.md: Scene hierarchy reflects current state
- [ ] ARCHITECTURE.md: Future Plans reflects progress
- [ ] FILE_STRUCTURE.md: New folders documented
- [ ] FILE_STRUCTURE.md: Organization consistent with existing structure
- [ ] CODING_STANDARDS.md: New patterns documented if any
- [ ] VERTICAL_SLICE.md: Steps marked complete/in-progress
- [ ] VERTICAL_SLICE.md: Step summaries created for completions

### Code Quality
- [ ] No type hint violations
- [ ] No magic numbers in code
- [ ] No direct node coupling between systems
- [ ] All public functions documented
- [ ] Naming conventions followed throughout
- [ ] No unused imports or variables

### Commit Readiness
- [ ] Changes are logically grouped (one feature/fix per commit)
- [ ] No unrelated changes mixed in
- [ ] All documentation in sync
- [ ] Code passes all standards

---

## Phase 6: Output Report

Provide comprehensive validation report:

```markdown
# 🔍 PRE-COMMIT VALIDATION REPORT

## Changes Detected
- [Key change 1]
- [Key change 2]
- [Key change 3]

## 📋 Documentation Status

### ✅ ARCHITECTURE.md
- [Section updated]: [What was added/modified]
- [Section updated]: [What was added/modified]
- Status: ✅ UP TO DATE

### ✅ FILE_STRUCTURE.md
- [Section updated]: [What was added/modified]
- Status: ✅ UP TO DATE

### ✅ CODING_STANDARDS.md
- [Pattern documented]: [Description]
- Status: ✅ NO UPDATES NEEDED (or ✅ UPDATED)

### ✅ VERTICAL_SLICE.md
- Step X marked complete with summary
- Status: ✅ UP TO DATE (or ✅ NO UPDATES NEEDED)

## 📝 Code Standards Check

### Type Hints
✅ All functions typed correctly
✅ All variables have explicit types
✅ No `Variant` inference detected

### Naming Conventions
✅ Classes use PascalCase
✅ Functions/variables use snake_case
✅ Constants use SCREAMING_SNAKE_CASE
✅ Files match class names

### Magic Numbers
✅ No hardcoded values in code
✅ All balance values in config files
✅ Configuration pattern consistent

### Other Standards
✅ Signals include parameter types
✅ No direct node coupling
✅ Public functions documented
✅ One class per file maintained

## 💾 Generated Commit Message

**Title**: `<type>: <brief description>`

**Description**:
- [Key change with why]
- [Key change with why]
- [Key change with why]
- [Integration point or architectural decision]
- [Files/systems affected]

---

## 🎯 Recommendation

### ✅ READY TO COMMIT
All documentation is up to date, code standards are met, and commit message is ready.

**Next Step**: Execute commit with provided message

---

OR IF ISSUES FOUND:

## ⚠️ Issues Requiring Attention

### ARCHITECTURE.md
- [ ] Add [SystemName] to Key Systems section
  → Include purpose, responsibilities, signals, API
  → Reference location: `path/to/System.gd`

- [ ] Update signal flow diagram
  → Add new event: [event name]
  → Show integration with: [other systems]

- [ ] Update scene hierarchy
  → New top-level node: [node name]
  → Update entity pattern for: [entity type]

### FILE_STRUCTURE.md
- [ ] Add `/src/systems/new_system/` folder documentation
  → Describe contents and purpose

- [ ] Update Naming & Grouping Rules
  → Add new pattern: [pattern description]

### CODING_STANDARDS.md
- [ ] Document new pattern: [pattern name]
  → Add example implementation
  → Reference files using pattern: [file list]

### Code Issues
- [ ] File: [filepath] - Line [X]: [Standard violated]
  → Issue: [What's wrong]
  → Fix: [What to do]

---

## 🔗 Recommendation: UPDATE DOCS FIRST

Complete the above before committing. Documents must stay in sync with code.

**Estimated time**: [minutes to fix]

**Priority issues** (block commit):
1. [Issue 1]
2. [Issue 2]

**Nice to have** (can update later):
1. [Issue 1]
```

---

## Execution Instructions

### For AI Agents Using This Prompt

1. **Run Phase 1** (Analyze Changes)
   ```bash
   git status
   git diff --cached
   ```

2. **Run Phase 2** (Documentation Validation)
   - Read relevant doc files
   - Check if sections match git changes
   - Note missing documentation

3. **Run Phase 3** (Code Standards)
   - Review actual code changes
   - Check for type hints, magic numbers, naming
   - Identify violations

4. **Run Phase 4** (Commit Message)
   - Summarize changes
   - Generate conventional commit title
   - List 3-5 key bullets

5. **Run Phase 5** (Final Checklist)
   - Verify all docs are synced
   - Confirm code quality
   - Check commit readiness

6. **Run Phase 6** (Report)
   - Provide comprehensive summary
   - Clear ✅ READY or ⚠️ ISSUES FOUND
   - Actionable next steps

---

## Integration with Other Prompts

This prompt works with:
- **doc-update-check.md** - Detailed doc update requirements
- **ARCHITECTURE.md** - System design documentation
- **FILE_STRUCTURE.md** - Project organization
- **CODING_STANDARDS.md** - Code style guidelines
- **VERTICAL_SLICE.md** - Implementation progress tracking

---

## Quick Reference: What to Check When

| Change Type | Check ARCHITECTURE | Check FILE_STRUCTURE | Check STANDARDS | Check VERTICAL_SLICE |
|---|---|---|---|---|
| New system/autoload | ✅ Key Systems section | ✅ autoload/ folder | ✅ Type hints, signals | ✅ Step summary |
| New entity type | ✅ Key Systems section | ✅ src/entities/ folder | ✅ Naming, config pattern | ✅ Step summary |
| Signal flow changes | ✅ System Diagrams, Data Flow | — | ✅ Signal naming, types | ✅ Step summary |
| Scene hierarchy | ✅ Scene Hierarchy section | — | — | — |
| New config file | ✅ Performance section | ✅ config/ folder | ✅ Config pattern, no magic numbers | — |
| Folder structure | — | ✅ Update tree | — | — |
| Optimization pattern | ✅ Performance section | — | ✅ Document pattern | — |
| Step completion | ✅ Future Plans (mark done) | — | — | ✅ Mark [x], create summary |

---

**Created**: For pre-commit validation workflow
**Last Updated**: Referenced doc-update-check.md
**Maintained By**: AI agents and development team
