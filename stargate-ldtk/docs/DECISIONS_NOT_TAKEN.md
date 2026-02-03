# Decisions Not Taken

> **Purpose**: Document what was NOT done and why, to avoid future "what if..." questions.

---

## ❌ What Was NOT Done (Consciously)

### 1. No CI/CD Added

**Why NOT**:
- Project sealed, not in active development
- No frequent releases to justify automation
- CI implies continuous maintenance (dependencies, runners, configs)
- Cost > benefit for archived project

**When to DO it**:
- If project reactivates with active development
- If there are multiple contributors
- If it becomes critical dependency of another project

---

### 2. No Independent Gem Extraction

**Why NOT**:
- No demonstrated external usage
- Designed specifically for DragonRuby
- Extracting to gem requires:
  - Decoupling from DragonRuby (significant work)
  - Maintaining cross-platform compatibility
  - Publishing and maintaining on RubyGems
- No real need justifies the effort

**When to DO it**:
- If 3+ external projects request it
- If value is demonstrated outside DragonRuby
- If someone commits to maintaining it

---

### 3. No Formal RFC Spec

**Why NOT**:
- No external community adopting the format
- RFC implies formal governance and versioning process
- Format is documented in `referencia_nodal.md` (sufficient for current use)
- Formalizing without adoption is premature bureaucracy

**When to DO it**:
- If multiple format implementations emerge
- If there are interpretation conflicts between users
- If it becomes de facto standard

---

### 4. No Complete Automated Tests

**Why NOT**:
- Project sealed, not in active development
- Tests require continuous maintenance
- DragonRuby has no standard testing framework
- Code was manually audited and corrected

**When to DO it**:
- If project reactivates
- If regressions are detected
- If it becomes critical dependency

---

### 5. No Visual Editor Created

**Why NOT**:
- LDtk IS the visual editor
- Creating own editor would duplicate effort
- Would violate principle: "LDtk is just another importer"
- Massive scope creep

**When to DO it**:
- Never. Use LDtk.

---

### 6. No Networking/Multiplayer Implemented

**Why NOT**:
- Outside project scope
- Stargate is data format + spatial analysis
- Networking is game's responsibility, not runtime's
- Adding it would break separation of concerns

**When to DO it**:
- Never in this project. Create separate project.

---

### 7. No Aggressive Performance Optimization

**Why NOT**:
- Current performance is sufficient for typical use
- Premature optimization is root of all evil
- No benchmarks demonstrate need
- Optimized code is less readable code

**When to DO it**:
- If profiling demonstrates real bottleneck
- If real game reports measurable lag
- If there's use case with 1000+ entities

---

## ✅ What WAS Done (And Why)

### Surgical Corrections (7 fixes)

**Why YES**:
- Resolved real fragility
- Didn't expand scope
- Improved auditability
- Reduced technical debt

### #NNNN System

**Why YES**:
- Makes code auditable
- Allows resuming project years later
- Requires no maintenance
- Is documentation that doesn't get outdated

### Explicit Archiving

**Why YES**:
- Avoids zombie project
- Sets clear expectations
- Protects against future scope creep
- Is honest with potential users

---

## 🧠 Guiding Principle

**"Don't expand without real need"**

Real need means:
- ✅ Critical bug reported
- ✅ Real project blocked
- ✅ Painful limitation demonstrated

NOT real need means:
- ❌ "It would be interesting..."
- ❌ "We could improve..."
- ❌ "What if..."

---

**Date**: 2026-02-02  
**Version**: 0.8.0-alpha
