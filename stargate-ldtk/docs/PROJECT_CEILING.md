# Project Ceiling

> **Purpose**: Define how far StargateLDtk can grow without losing its identity.

---

## 🎯 Core Identity

**StargateLDtk IS**:
- A data format for 2D tactical maps
- A spatial analysis runtime
- A deterministic decision engine

**StargateLDtk is NOT**:
- A complete game engine
- A rendering framework
- A map editor
- A networking solution

---

## 📏 Project Boundaries

### ✅ Within Ceiling (Allowed)

These changes do NOT break identity:

1. **New importers** (Tiled, Ogmo, custom)
   - As long as they produce the same canonical format
   - As long as they're optional

2. **Performance optimizations**
   - As long as they don't break determinism
   - As long as they maintain API

3. **New spatial analysis types**
   - Line of sight
   - Cover detection
   - Influence maps
   - As long as they're pure queries (no side effects)

4. **Validation improvements**
   - More semantic checks
   - Better error messages
   - As long as they don't relax restrictions

5. **Documentation**
   - More examples
   - More guides
   - Translations
   - Always

---

### ❌ Outside Ceiling (Forbidden)

These changes BREAK identity:

1. **Integrated rendering**
   - Stargate does NOT render
   - Rendering is game's responsibility
   - Adding rendering would make it a "game engine"

2. **Game state management**
   - Stargate does NOT manage game state (HP, inventory, etc.)
   - Only manages map structure
   - Adding game state would make it a "framework"

3. **Own visual editor**
   - LDtk is the editor
   - Creating own editor duplicates effort
   - Would make it a "complete suite"

4. **Networking/Multiplayer**
   - Outside scope
   - Game's responsibility
   - Would make it an "online engine"

5. **Continuous physics**
   - Stargate is discrete (grid-based)
   - Continuous physics requires different architecture
   - Would make it a "physics engine"

6. **Scripting engine**
   - Not a scripting system
   - Not a behavior DSL
   - Would make it a "logic engine"

---

## 🚧 Gray Zone (Requires Debate)

These changes are on the boundary:

### 1. Event System

**Argument for**:
- Useful for notifying map changes
- Maintains separation of concerns

**Argument against**:
- Adds complexity
- Can lead to game state management
- Can break determinism

**Verdict**: ⚠️ Only if 100% optional and doesn't affect core

---

### 2. Binary Serialization

**Argument for**:
- Performance
- File size

**Argument against**:
- Loses readability
- Loses auditability
- JSON is sufficient

**Verdict**: ⚠️ Only as alternative format, never replace JSON

---

### 3. Automatic Hot-Reload

**Argument for**:
- Useful for development
- Already exists partially

**Argument against**:
- Adds filesystem dependencies
- Can break determinism
- Game's responsibility

**Verdict**: ⚠️ Only as optional helper, not core feature

---

## 🔄 Identity Change

If these features are ever added, **the project must be renamed**:

- Integrated rendering → "StargateLDtk Engine"
- Game state management → "StargateLDtk Framework"
- Visual editor → "StargateLDtk Suite"
- Networking → "StargateLDtk Online"

**Reason**: Don't lie about what the project is.

---

## 📐 Golden Rule

**Before adding any feature, ask**:

1. Does this change the project's identity?
2. Is this the runtime's or the game's responsibility?
3. Does this break any architectural principle?
4. Does this introduce technical debt?
5. Does this have demonstrated real need?

If answer to 1-4 is "yes", **DON'T do it**.  
If answer to 5 is "no", **DON'T do it**.

---

## 🎯 Maximum Absolute Ceiling

**StargateLDtk can grow to be**:
- The best 2D tactical map runtime for DragonRuby
- The canonical reference format for discrete maps
- The reference implementation of deterministic spatial analysis

**StargateLDtk CANNOT grow to be**:
- A complete game engine
- An all-in-one framework
- An enterprise solution

---

**If the project exceeds this ceiling, it must become a different project.**

---

**Date**: 2026-02-02  
**Version**: 0.8.0-alpha
