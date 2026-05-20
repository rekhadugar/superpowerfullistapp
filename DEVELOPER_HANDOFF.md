# Listicle V2: AI Developer Handoff & System Rules

**CRITICAL INSTRUCTION FOR AI AGENTS:** You are working on Listicle V2, a high-performance, $120\text{Hz}$ optimized Flutter application. This project uses a highly custom **Math-Driven, Deterministic Architecture**. You must read and strictly adhere to this document before writing or modifying any code.

**DO NOT assume standard Flutter paradigms (like fluid text scaling or standard SliverAppBars) apply here. DO NOT introduce new third-party UI or gesture libraries.**

---

## 1. Component Contract & Immutable Design Guide

Listicle enforces a strict separation of concerns to prevent layout thrashing and maintain constant-time $O(1)$ scrolling math.

### 1.1 The "Dumb Component" Rule
UI components (e.g., `ListItemCard`, `SectionHeader`) must be strictly parameterized "Dumb Widgets."
* **NEVER** inject `context.read<ListProvider>()` deep inside reusable UI components.
* All data, state mutations, and callbacks must be passed down from the parent screen via `final` constructor parameters.

### 1.2 The Immutable Design System
* **NEVER** hardcode colors, paddings, margins, border radii, or text styles in the UI layer.
* All spatial geometry **MUST** be referenced from `AppConstants` (`lib/theme/app_constants.dart`).
* All styling **MUST** be referenced from `AppTheme` (`lib/theme/app_theme.dart`).

**Critical Layout Constants to Remember:**
* `AppConstants.headerHeight`: `44.0` (Strictly maps to the Spatial Cache engine)
* `AppConstants.baseCardHeight`: `56.0`
* `AppConstants.attributeRowHeight`: `20.0`
* `AppConstants.cardMargin`: `0.0` (Must remain 0px to preserve $O(1)$ scroll math)
* `AppConstants.topBarHeight`: `76.0`

*If you need to change a layout property, you must change it in `AppConstants`, not in the widget.*

---

## 2. Gesture Physics & Interaction Matrix

Listicle bypasses standard Flutter gesture packages to maintain hardware-accelerated physics and prevent diagonal scroll drift. **DO NOT attempt to replace `SwipeActionWrapper` with packages like `flutter_slidable`.**

### 2.1 The `SwipeActionWrapper` Engine
This widget utilizes a dual-directional, physics-based swipe engine directly inside the viewport.
* **Left-to-Right ($x > 0$):** Check-out action (Green backdrop, `Icons.check_circle`). Triggered via `AppPhysics.checkoutThreshold` (0.45).
* **Right-to-Left ($x < 0$):** Soft Delete / Edit action (Red/Blue backdrop). Triggered via `AppPhysics.swipeExecuteThreshold` (0.65).

### 2.2 Physics Parameters (`AppPhysics`)
All gestural interactions rely on mathematically defined physics constants:
* **Momentum Prediction (`momentumMultiplier`):** Calculates where a card will naturally stop given its velocity, deciding whether to snap back or glide off-screen.
* **Spring vs. Glide:** * Cancellations trigger a `SpringSimulation` (`springStiffness: 400.0`, `springDamping: 28.0`) to snap back tightly.
    * Successful commits trigger a fast `150ms` exit glide to guarantee the action completes instantly without a settling tail.

### 2.3 Global State Coordination
Swipe actions broadcast their state to prevent overlapping menus.
* When a drag starts, it updates `ListProvider.openSwipeItemId`.
* Other wrappers listen to this `ValueNotifier` and instantly snap closed if another item is swiped.

---

## 3. Fractional Multi-Indexing & Path Optimization Schema

Listicle does not use integer-based sorting (0, 1, 2) to manage list order. It utilizes **Fractional Multi-Indexing** to allow infinite local reordering with $O(1)$ database writes.

### 3.1 The Floating-Point Indexes
Each `ListItem` model contains three isolated `double` fields:
* `shopOrder`: Custom positioning within a specific Shop/Store section.
* `categoryOrder`: Custom positioning within a Category section.
* `globalCustomOrder`: Custom positioning within the flat unsectioned view.

### 3.2 Drag-and-Drop Midpoint Calculation
When reordering items, **NEVER** update the indexes of the surrounding array elements. Instead, assign the dragged item a new weight that is the exact midpoint of its new neighbors:
$$W_{target} = \frac{W_A + W_B}{2}$$

### 3.3 Shopping Mode & Store-Routing
Listicle features a physical path-optimization mode. Items map to physical store configurations (`Shop` schema) which contain an `aisleRoute` (e.g., `["Produce", "Bakery", "Dairy"]`).
* `ListItem.category`: Maps to the physical aisle.
* `ListItem.type` & `ListItem.locations`: Maps to the specific retail stores.
  When editing sorting logic, you must respect the deterministic `Routing Sort Priority Key` defined in the System Design Specification.