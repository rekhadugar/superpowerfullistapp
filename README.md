Listicle V2 🚀

Listicle V2 is a high-performance, real-time grocery and task management application engineered specifically for $120\text{Hz}$ mobile displays. Moving away from standard render-driven layout trees, Listicle utilizes a Math-Driven, Deterministic Architecture to achieve zero frame drops, $O(1)$ scrolling math, and seamless collaborative concurrency.

Lead Developer / Product Manager: Dhiraj Dugar

🧠 Core Architecture

Traditional Flutter lists rely on continuous $O(N)$ tree-walking to track sticky headers and active items. Listicle bypasses this entirely:

$O(1)$ Layout Geometry: All UI elements (ListItemCard, SectionHeader) are bound to strict, compile-time height constants. Flutter's default fluid text-scaling is bypassed for deterministic mathematical rows.

$O(\log N)$ Spatial Cache: The ListProvider pre-computes an array of cumulative Y-offsets. During scrolling, a pure Dart StickyHeaderEngine runs a binary search against this cache, resolving phantom header collisions instantly without ever touching the render tree.

Hardware-Accelerated Physics: Sticky headers and sliding App Bars are isolated inside RepaintBoundary widgets and shifted using GPU-accelerated Transform.translate matrices.

Strict State Separation: Intent management (Fluid Editing vs. Batch Selection vs Quick Add) is mathematically isolated at the provider level, ensuring complex UI overlays never collide or freeze the render pipeline.

✨ Key Features (v2.2 Dynamic Taxonomy Engine)

Listicle V2 is no longer just a "Shopping" app; it is a polymorphic categorization engine.

Infinite Custom Types: Users can create custom taxonomies (e.g., a "Wine Collection" sorted by "Region" and "Varietal").

Alias Mapping: The entire UI dynamically morphs to reflect the active list's taxonomy. Add/Edit sheets, batch action bars, and list rendering automatically adopt the correct contextual labels.

Rapid-Fire Quick Add: A dynamically scaling, fluid AppBar pill that leverages a modal barrier and WidgetsBindingObserver for bulletproof, keyboard-aware data entry without layout thrashing. Items added via Rapid-Fire are flashed and snapped into view $O(1)$ using Temporary Scroll Expansion math.

Smart Dictionary Orchestrator: The Provider engine aggregates system defaults, cross-list cloud items, and active list items to dynamically populate a Smart Suggestions overlay during quick add, instantly auto-filling stores, categories, and units based on algorithmic frequency and recency mapping.

Universal Settings Hub: A centralized, 2-level dashboard to manage List Order, Axis Labels, and Group Configurations dynamically, featuring a Cascading Delete protocol for safe data lifecycle management.

Passive Dual-Intent Gestures: A sophisticated interaction engine utilizing raw pointer Listener objects to allow simultaneous drag-and-drop reordering and haptic-triggered multi-selection without locking the gesture arena.

Fractional Multi-Indexing: Solves the classic drag-and-drop database reordering problem. Items use floating-point step arithmetic (calculating the midpoint between neighbors) to allow infinite local list reordering with only $O(1)$ database writes.

Path-Optimization Shopping Mode: Designed for physical store runs. Items map to specific store schemas (e.g., Costco) and automatically sort themselves to match the exact physical aisle route from front to back, eliminating backtracking.

🛠️ Tech Stack & Design System

Framework: Flutter / Dart

Backend: Local SharedPreferences (Transitioning to Firebase Cloud Firestore)

State Management: Provider with isolated ValueNotifier hooks for localized gesture states.

Immutable Design: UI components strictly adhere to AppTheme and AppConstants. No hardcoded paddings, margins, or colors exist in the UI layer.

📂 Project Structure

lib/engine/ - Pure mathematical black boxes (e.g., StickyHeaderEngine).

lib/models/ - Domain schemas including ListItem and SmartItem variants.

lib/providers/ - Global state managers (ListProvider) handling strict interaction locks.

lib/widgets/ - "Dumb", parameterized UI components locked to the Design System.

🚀 Roadmap Highlights

Currently in Phase 2 (UI Expansion & State Hardening), upcoming features include:

Auto-hiding empty sections with virtual layout proxies.

Global mass-expansion pivoting to preserve viewport scroll coordinates.

Seamless Firebase Cloud Firestore integration with "Dual-Flash" UX conflict resolution.