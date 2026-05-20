# Listicle V2 🚀

Listicle V2 is a high-performance, real-time grocery and task management application engineered specifically for $120\text{Hz}$ mobile displays. Moving away from standard render-driven layout trees, Listicle utilizes a **Math-Driven, Deterministic Architecture** to achieve zero frame drops, $O(1)$ scrolling math, and seamless collaborative concurrency.

**Lead Developer / Product Manager:** Dhiraj Dugar

## 🧠 Core Architecture

Traditional Flutter lists rely on continuous $O(N)$ tree-walking to track sticky headers and active items. Listicle bypasses this entirely:
* **$O(1)$ Layout Geometry:** All UI elements (`ListItemCard`, `SectionHeader`) are bound to strict, compile-time height constants. Flutter's default fluid text-scaling is bypassed for deterministic mathematical rows.
* **$O(\log N)$ Spatial Cache:** The `ListProvider` pre-computes an array of cumulative Y-offsets. During scrolling, a pure Dart `StickyHeaderEngine` runs a binary search against this cache, resolving phantom header collisions instantly without ever touching the render tree.
* **Hardware-Accelerated Physics:** Sticky headers and sliding App Bars are isolated inside `RepaintBoundary` widgets and shifted using GPU-accelerated `Transform.translate` matrices.

## ✨ Key Features

* **Custom Swipe-to-Action Physics:** A dual-directional gesture engine featuring logarithmic rubber-banding resistance and two-stage haptic feedback for satisfying Check-Off and Soft-Delete interactions.
* **Fractional Multi-Indexing:** Solves the classic drag-and-drop database reordering problem. Items use floating-point step arithmetic (calculating the midpoint between neighbors) to allow infinite local list reordering with only $O(1)$ database writes.
* **Path-Optimization Shopping Mode:** Designed for physical store runs. Items map to specific store schemas (e.g., Costco) and automatically sort themselves to match the exact physical aisle route from front to back, eliminating backtracking.
* **Collaborative Sync Engine:** Built on Firebase Cloud Firestore. Implements a "Dual-Flash" UX system to seamlessly merge real-time list additions from collaborators (e.g., syncing instantly between Dhiraj and Rekha) without jarring layout shifts or viewport jumping.

## 🛠️ Tech Stack & Design System

* **Framework:** Flutter / Dart
* **Backend:** Firebase Cloud Firestore & Auth
* **State Management:** `Provider` with isolated `ValueNotifier` hooks for localized gesture states.
* **Immutable Design:** UI components strictly adhere to `AppTheme` and `AppConstants`. No hardcoded paddings, margins, or colors exist in the UI layer.

## 📂 Project Structure

* `lib/engine/` - Pure mathematical black boxes (e.g., `StickyHeaderEngine`).
* `lib/models/` - Domain schemas including `ListItem` and `Shop` route configurations.
* `lib/providers/` - Global state managers (`ListProvider`) handling batch Firestore operations.
* `lib/widgets/` - "Dumb", parameterized UI components locked to the Design System.

## 🚀 Roadmap Highlights

Currently in **Phase 2 (UI Expansion)**, upcoming features include:
* Auto-hiding empty sections with virtual layout proxies.
* Global mass-expansion pivoting to preserve viewport scroll coordinates.
* Smart Item Suggestions based on historical data context.

---

# AI Developer System Rules for Listicle v2

## 1. Immutable Design System
* **NEVER hardcode colors, paddings, margins, border radii, or text styles in the UI.**
* All visual properties MUST be referenced from `lib/theme/app_theme.dart` or `lib/theme/app_constants.dart`.
* Do not introduce new third-party UI libraries without explicit permission.

## 2. Architectural Boundaries
* **Separation of Concerns:** UI files (Widgets) must only handle rendering. They must NOT contain complex data filtering, sorting, or mathematical layout logic.
* **State Management:** All global state must go through `ListProvider`. Do not use `setState` for anything other than transient, local UI animations (e.g., hover states, expanding a card).
* **Physics & Math:** All complex mathematical calculations (like the Sticky Header engine) must remain strictly encapsulated in pure Dart classes (e.g., `StickyHeaderEngine`). Treat these files as read-only black boxes unless explicitly instructed to modify them.

## 3. Component Parameterization (Dumb Components)
* Reusable components (like `ListItemCard`, `SectionHeader`, `TokenSearchEngine`) must be treated as "Dumb Widgets".
* They should receive all data, callbacks, and configuration via `final` parameters in their constructor.
* Do not inject `context.read<ListProvider>()` directly deep inside reusable UI components. Pass the data down from the parent screen to keep the component pure and testable.