# Listicle V2: AI Developer Handoff & System Rules

**CRITICAL INSTRUCTION FOR AI AGENTS:** You are working on Listicle V2, a high-performance, $120\text{Hz}$ optimized Flutter application. This project uses a highly custom **Math-Driven, Deterministic Architecture**. You must read and strictly adhere to this document before writing or modifying any code.

**DO NOT assume standard Flutter paradigms (like fluid text scaling or standard SliverAppBars) apply here. DO NOT introduce new third-party UI or gesture libraries.**

---

## 1. Component Contract & Immutable Design Guide

Listicle enforces a strict separation of concerns to prevent layout thrashing and maintain constant-time $O(1)$ scrolling math.

### 1.1 The "Dumb Component" Rule
UI components (e.g., `ListItemCard`, `SectionHeader`) must be strictly parameterized "Dumb Widgets."
* **NEVER** inject `context.read<ListProvider>()` deep inside reusable UI components.
* All data, state mutations, and interaction flags (e.g., `isBatchModeActive`, `isFluidEditing`) must be passed down from the parent screen via `final` constructor parameters.

### 1.2 The Immutable Design System
* **NEVER** hardcode colors, paddings, margins, border radii, or text styles in the UI layer.
* All spatial geometry **MUST** be referenced from `AppConstants` (`lib/theme/app_constants.dart`).
* All styling **MUST** be referenced from `AppTheme` (`lib/theme/app_theme.dart`).

**Critical Layout Constants to Remember:**
* `AppConstants.headerHeight`: `44.0` (Strictly maps to the Spatial Cache engine)
* `AppConstants.baseCardHeight`: `56.0`
* `AppConstants.attributeRowHeight`: `20.0`
* `AppConstants.cardMargin`: `0.0` (Must remain 0px to preserve $O(1)$ scroll math)

---

## 2. Gesture Physics & Interaction Matrix

Listicle bypasses standard Flutter gesture packages to maintain hardware-accelerated physics, manage floating-point thresholds, and prevent diagonal scroll drift. **DO NOT attempt to replace custom wrappers with packages like `flutter_slidable`.**

### 2.1 Passive Dual-Intent Engine (`ListItemCard`)
To allow `ReorderableListView` drag-and-drop to coexist with Long-Press Multi-Select, the card utilizes a raw pointer `Listener` instead of a `GestureDetector` for holding actions.
* **Tap Collision Locks:** Ensure `_wasLongPressed` absorbs rogue tap events emitted by the gesture arena when a user releases a multi-select hold.
* **Drag Handshake:** If the list takes over the pointer to drag (`onPointerCancel`), the card must immediately cancel its selection timers.

### 2.2 The `SwipeActionWrapper` Engine
This widget utilizes a dual-directional, physics-based swipe engine directly inside the viewport.
* **Left-to-Right ($x > 0$):** Check-out action. Triggered via `AppPhysics.checkoutThreshold`.
* **Right-to-Left ($x < 0$):** Soft Delete / Edit action. Triggered via `AppPhysics.swipeExecuteThreshold`.
* **Batch Lock:** Swiping is strictly immobilized (`_onDragStart` aborts) if `isBatchModeActive` is true.
* **Floating-Point UI Locks:** To prevent microscopic physics settling (`0.00000001`) from triggering the `AbsorbPointer` lock, menu-open checks must use a threshold (`> 0.1`).

### 2.3 Physics Parameters (`AppPhysics`)
All gestural interactions rely on mathematically defined physics constants:
* **Spring vs. Glide:** Cancellations trigger a `SpringSimulation` (`springStiffness: 400.0`, `springDamping: 28.0`). Commits trigger a fast `150ms` exit glide.
* **Hard Resets:** Before any swipe action executes a provider callback, it MUST call `_forceCloseMenu()` to sync `_currentVisualOffset` to `0.0` and prevent "Zombie" item tap locks.

---

## 3. Strict State Separation

UI bottom sheets (Fluid Edit vs Batch Action) are mathematically isolated to prevent render freezing and collision.
* **Fluid Edit Intent:** Tracked strictly via `ListProvider.editItemId`.
* **Batch Select Intent:** Tracked strictly via `ListProvider.selectedItemIds`.
* These variables must be mutually exclusive. If a user begins dragging, or selects a batch item, the `editItemId` must be nulled out instantly.

---

## 4. Fractional Multi-Indexing

Listicle does not use integer-based sorting (0, 1, 2) to manage list order. It utilizes **Fractional Multi-Indexing** to allow infinite local reordering with $O(1)$ database writes.
* When reordering items, **NEVER** update the indexes of the surrounding array elements. Instead, assign the dragged item a new weight that is the exact midpoint of its new neighbors:
  $$W_{target} = \frac{W_A + W_B}{2}$$