---
description: Always check ARCHITECTURE.md before proposing system changes. Apply
  when making architectural changes like adding new systems, changing system
  communication patterns, modifying scene hierarchy, camera systems, or other
  structural changes
alwaysApply: false
---

**Step 1: Check Existing Architecture FIRST**
- Read /docs/ARCHITECTURE.md to understand current system design
- Read /docs/agent/PROJECT_CONTEXT.md for core vision and non-negotiable standards
- Read /docs/agent/FILE_STRUCTURE.md to verify correct file placement
- Verify your proposed changes align with existing patterns
- Check if similar systems already exist or if you're duplicating functionality
- Ensure signal-driven communication (EventBus) is used, NOT tight coupling

**Step 2: Validate Against Project Standards**
- New systems must go in `/src/systems/`, `/src/entities/`, or `/autoload/` (never in `/scenes/` or root)
- Check if GameConfig.gd needs new constants (NO magic numbers)
- Verify inherited scenes are used for reusable entities (crops, enemies, towers)
- If adding performance-critical code (enemies, pooling), verify object pooling patterns
- Demo/test code MUST stay in `/demos/` — never mix with production code in `/src/`

**Step 3: Update /docs/ARCHITECTURE.md** with:
1. **Key Systems section**: Add purpose, location (`/src/systems/X.gd`), responsibilities, signals, and public API
2. **System Diagrams**: Update if new EventBus signals or system communication patterns change
3. **Data Flow**: Document new signal flows (e.g., "crop_harvested → EconomyManager → UI")
4. **Scene Hierarchy**: Update if MainGame.tscn or entity node structures change
5. **Performance Considerations**: Document if adding pooling, shared paths, MultiMesh, or optimization patterns
6. **Autoload Singletons table**: Add new autoloads with purpose and key responsibilities
7. **Camera System section**: Update if camera logic, ownership, or control changes

**Step 4: Cross-Reference Documentation Updates**
- If adding new folders/files → also update FILE_STRUCTURE.md
- If establishing new coding patterns → also update CODING_STANDARDS.md
- If implementing vertical slice steps → update VERTICAL_SLICE.md checkboxes

Keep entries concise but informative. Use code blocks for technical examples. Follow hex-grid farming + wave-defense game context.
