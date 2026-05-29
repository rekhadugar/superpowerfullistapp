Listicle V2: AI Developer Handoff & System Rules

CRITICAL INSTRUCTION FOR AI AGENTS: You are working on Listicle V2, a high-performance, $120\text{Hz}$ optimized Flutter application. This project uses a highly custom Math-Driven, Deterministic Architecture. You must read and strictly adhere to this document before writing or modifying any code.

1. Dynamic Taxonomy & Alias Mapping (v2.2 Architecture)

Listicle V2 is a polymorphic categorization engine. It utilizes Alias Mapping to project dynamic user labels onto a rigid backend schema.

The Schema: ListItem fundamentally stores grouping data in type and category fields.

The Projection: Conceptually, type is Axis 1 (e.g., Store, Platform, Region) and category is Axis 2 (e.g., Aisle, Genre, Varietal).

Rule 1 (No Hardcoding): NEVER use hardcoded labels like "Store" or "Category" in the UI. Always resolve labels dynamically using AppListType.axis1Label and AppListType.axis2Label via the SettingsProvider.

Rule 2 (Group Lookups): All list-grouping configuration must be accessed via SettingsProvider.getAxis1Groups(typeId) and SettingsProvider.getAxis2Groups(typeId).

2. Safe Data Lifecycle: The Cascading Delete Protocol

When deleting an AppListType, you must perform a strict Cascading Delete to prevent memory leaks in SharedPreferences.

MacroList Purge: Invoke MacroListProvider.deleteAllListsOfType(typeId). This will hunt down every list attached to the dying Type and physically wipe its underlying items from local storage.

Settings Purge: Invoke SettingsProvider.deleteCustomType(typeId) to wipe the taxonomy metadata, grouping dictionaries, and anchor logic.

3. Component Contract & Immutable Design Guide

Listicle enforces a strict separation of concerns to prevent layout thrashing and maintain constant-time $O(1)$ scrolling math.

3.1 The "Dumb Component" Rule

UI components (ListItemCard, SectionHeader) must be strictly parameterized "Dumb Widgets."

NEVER inject context.read<ListProvider>() or SettingsProvider deep inside reusable UI components if the data can be passed down via final constructor parameters.

Components must only re-render when their explicitly passed parameters change.

3.2 The Immutable Design System

NEVER hardcode colors, paddings, margins, border radii, or text styles in the UI layer.

All spatial geometry MUST be referenced from AppConstants.

All styling MUST be referenced from AppTheme.

4. Deterministic Scrolling (The "Phantom Header" Math)

AppConstants height constants are mathematically binding.

StickyHeaderEngine relies on these constants for its $O(\log N)$ binary search scroll resolution.

Any modification to a component's layout height MUST be mirrored exactly in StickyHeaderEngine.calculateSpatialCache. Failure to do so will desynchronize the UI and the physics engine, resulting in visual stuttering.

5. Strict State Separation

UI overlays and bottom sheets (FluidEditSheet, BatchActionBar, Quick Add Pill) are mathematically isolated to prevent render freezing and collision.

Fluid Edit Intent: Tracked strictly via ListProvider.editItemId.

Batch Select Intent: Tracked strictly via ListProvider.selectedItemIds.

Quick Add Intent: Managed actively with system-level WidgetsBindingObserver overrides and full-screen modal barriers. Do not rely on flaky FocusNode states for closures.

These variables must be mutually exclusive. If a user begins dragging, selects a batch item, or opens the keyboard, concurrent intents must be nulled out instantly to prevent "Zombie" item tap locks and rendering overlaps.