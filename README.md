# Listicle - Architecture & Handoff Documentation

## 1. Project Overview

**Listille** is a premium, cross-platform shared task and grocery management application. It is designed for frictionless, power-user data entry and organization. The application features a highly interactive UI with custom gesture controls, segmented dynamic sorting, and a robust tag-based categorization system.

### Tech Stack

* **Framework:** Flutter / Dart
* **State Management:** `provider` (ChangeNotifier)
* **Backend:** Firebase Firestore (NoSQL)
* **Key Packages:** `flutter_slidable` (for multi-action swipe menus)

---

## 2. Core Architecture & Design Patterns

### 2.1 State Management (`ListProvider`)

The application uses a centralized Provider architecture (`ListProvider`) to manage local UI state and synchronize with Firestore.

* **Optimistic UI Updates:** Changes (like drag-and-drop reordering or status toggles) update the local state instantly via `notifyListeners()` before executing the asynchronous Firestore network calls.
* **Batch Operations:** Complex state changes (like cross-group drag-and-drop) utilize Firestore `WriteBatch` to minimize network calls and guarantee data integrity.
* **Active Filtering:** The provider actively filters out `isDeleted: true` and `isCompleted: true` items from the main views, ensuring the UI only renders active tasks.

### 2.2 Segmented List Engine

The `MainScreen` does not use standard nested lists. Instead, it utilizes a flattened array architecture to support complex drag-and-drop physics.

* **Data Flattening:** The `ListProvider` outputs a single array containing both `String` (Section Headers) and `ListItem` (Item Cards).
* **Dynamic Grouping:** Users can toggle the entire list architecture between "Group by Category" (Single-Select) and "Group by Store" (Multi-Select Tokens).
* **Simulated Reordering:** When an item is dragged across groups, the engine creates a simulated copy of the list, calculates the exact new visual index and the nearest Header, and dispatches a batch update to re-index the `order` integers of all sibling items.

### 2.3 The Universal Token Engine (`TokenSearchEngine`)

To keep the UI clean, the app avoids standard dropdowns in favor of a custom "Inline Typeahead Token Input."

* **Contextual States:** Functions as a quick-select horizontal scrolling list when minimized, and expands into a focused `TextField` for search/creation.
* **Unified Logic:** A single widget handles single-select (Categories), multi-select (Stores), and lowercase token arrays (Tags) via constructor parameters.
* **Advanced Keyboard Physics:** Implements a 50ms/500ms micro-stagger combined with a dynamic "Runway Buffer" (`SizedBox` at the bottom of the scroll view) to guarantee the widget perfectly clears the OS keyboard, circumventing native popup blockers and scroll extent traps.

### 2.4 Multi-Action Gesture Cards

Item cards utilize `flutter_slidable` integrated with custom `AnimatedSize` wrappers.

* **Smooth Teardown:** Fixes native framework teardown bugs by intercepting the dismiss action, manually shrinking the card's height to `0` over 300ms, and only dispatching the database deletion/completion *after* the animation finishes.

---

## 3. Database Schema (Firestore)

**Collection:** `items`

| Field | Type | Description |
| --- | --- | --- |
| `id` | String | Unique document identifier |
| `name` | String | User-defined item name |
| `type` | String | Top-level master list (e.g., Groceries, Hardware) |
| `category` | String | Primary grouping (Single-select, e.g., Produce) |
| `locations` | Array[String] | Store routing (Multi-select, e.g., ['Costco', 'Target']) |
| `context` | String | Comma-separated lowercase tags (e.g., 'vegan, urgent') |
| `quantity` | Integer | Item count |
| `order` | Integer | User-defined drag-and-drop index |
| `isCompleted` | Boolean | Marks item as done (hides from active view) |
| `isDeleted` | Boolean | Soft-delete flag for recovery |
| `createdAt` | Timestamp | Standard creation log |
| `updatedAt` | Timestamp | Updated via batch operations |

---

## 4. Directory Structure

```text
lib/
├── components/
│   ├── item_form_modal.dart       # Unified Add/Edit bottom sheet
│   ├── list_item_card.dart        # Slidable UI component with custom shrink animations
│   └── token_search_engine.dart   # Universal typeahead/quick-select input engine
├── models/
│   └── list_item.dart             # Data class and factory methods
├── screens/
│   └── main_screen.dart           # Segmented SliverReorderableList and App Drawer
├── services/
│   └── list_provider.dart         # Core state, grouping logic, and Firestore syncing
└── theme/
    └── app_theme.dart             # Centralized colors, typography, and styling

```

## 5. Next Development Phases (Roadmap)

1. **Shopping Mode Banner:** Implement UI to filter the `MainScreen` by a single active Store location.
2. **Smart Item Suggestions:** Upgrade the `ItemFormModal` Name input to utilize historical data to auto-fill categories, stores, and tags based on the item name.
3. **Authentication:** Integrate Firebase Auth and apply `userId` filtering to all Firestore queries.
4. **Archive View:** Build a screen to view, restore, or permanently wipe items marked `isCompleted: true`.


```Updated 5/18/2026```
# Listicle - Architecture & Handoff Documentation

## 1. Project Overview

**Listille** is a premium, cross-platform shared task and grocery management application. It is designed for frictionless, power-user data entry and organization. The application features a highly interactive UI with custom gesture controls, segmented dynamic sorting, a robust tag-based categorization system, and custom sliver physics.

### Tech Stack

* **Framework:** Flutter / Dart
* **State Management:** `provider` (ChangeNotifier)
* **Backend:** Firebase Firestore (NoSQL)
* **Key Packages:** `flutter_slidable` (for multi-action swipe menus)

---

## 2. Core Architecture & Design Patterns

### 2.1 State Management (`ListProvider`)

The application uses a centralized Provider architecture (`ListProvider`) to manage local UI state and synchronize with Firestore.

* **Optimistic UI Updates:** Changes (like drag-and-drop reordering or status toggles) update the local state instantly via `notifyListeners()` before executing the asynchronous Firestore network calls.
* **Batch Operations:** Complex state changes (like cross-group drag-and-drop) utilize Firestore `WriteBatch` to minimize network calls and guarantee data integrity.
* **Active Filtering:** The provider actively filters out `isDeleted: true` and `isCompleted: true` items from the main views, ensuring the UI only renders active tasks.

### 2.2 Segmented List Engine & Custom Sticky Physics

The `MainScreen` does not use standard nested lists or third-party sticky header packages. Instead, it utilizes a flattened array architecture integrated with a custom physics engine to support cross-group drag-and-drop.

* **Data Flattening:** The `ListProvider` outputs a single array containing both `String` (Section Headers) and `ListItem` (Item Cards).
* **The Phantom Header Engine:** A separate physics engine tracks the real-time layout coordinates (`GlobalKeys`) of the floating App Bar, the inline headers, and an end-of-list bumper. It calculates collisions during scroll and data-mutation events.
* **Z-Index Masking:** The sticky header is rendered outside the Sliver tree in a `Stack`. It uses a `ClipRect` mask and a `Transform.translate` push offset to create the flawless optical illusion of headers gracefully sliding underneath the floating App Bar.

### 2.3 The Universal Token Engine (`TokenSearchEngine`)

To keep the UI clean, the app avoids standard dropdowns in favor of a custom "Inline Typeahead Token Input."

* **Contextual States:** Functions as a quick-select horizontal scrolling list when minimized, and expands into a focused `TextField` for search/creation.
* **Unified Logic:** A single widget handles single-select (Categories), multi-select (Stores), and lowercase token arrays (Tags).
* **Advanced Keyboard Physics:** Implements a 50ms/500ms micro-stagger combined with a dynamic "Runway Buffer" to guarantee the widget perfectly clears the OS keyboard.

### 2.4 Multi-Action Gesture Cards

Item cards utilize `flutter_slidable` integrated with custom `AnimatedSize` wrappers.

* **Smooth Teardown:** Fixes native framework teardown bugs by intercepting the dismiss action, manually shrinking the card's height to `0` over 300ms, and only dispatching the database deletion/completion *after* the animation finishes.

---

## 3. Database Schema (Firestore)

**Collection:** `items`

| Field | Type | Description |
| --- | --- | --- |
| `id` | String | Unique document identifier |
| `name` | String | User-defined item name |
| `type` | String | Top-level master list (e.g., Groceries, Hardware) |
| `category` | String | Primary grouping (Single-select, e.g., Produce) |
| `locations` | Array[String] | Store routing (Multi-select, e.g., ['Costco', 'Target']) |
| `context` | String | Comma-separated lowercase tags (e.g., 'vegan, urgent') |
| `quantity` | Integer | Item count |
| `order` | Integer | User-defined drag-and-drop index |
| `isCompleted` | Boolean | Marks item as done (hides from active view) |
| `isDeleted` | Boolean | Soft-delete flag for recovery |
| `createdAt` | Timestamp | Standard creation log |
| `updatedAt` | Timestamp | Updated via batch operations |

---

## 4. Directory Structure

```text
lib/
├── components/
│   ├── item_form_modal.dart       # Unified Add/Edit bottom sheet
│   ├── list_item_card.dart        # Slidable UI component with custom shrink animations
│   └── token_search_engine.dart   # Universal typeahead/quick-select input engine
├── models/
│   └── list_item.dart             # Data class and factory methods
├── screens/
│   ├── main_screen.dart           # Segmented SliverReorderableList and App Drawer
│   └── completed_items_screen.dart # Archive view for finished tasks
├── services/
│   ├── list_provider.dart         # Core state, grouping logic, and Firestore syncing
│   └── sticky_header_engine.dart  # (Upcoming) Encapsulated physics math for the phantom header
└── theme/
    └── app_theme.dart             # Centralized colors, typography, and styling
 ```

## 5. Next Development Phases (Roadmap)

1. **Engine Encapsulation & Bulletproofing:** Extract the Custom Sliver math into a dedicated, AI-safe `sticky_header_engine.dart` class. Bind the physics engine directly to `ListProvider` state mutations (rather than just scroll listeners) to guarantee layout stability during non-scroll UI shifts (e.g., instant deletions or list filtering).
2. **Compact Mode & Card Expansion:** Introduce a global toggle to shrink `ListItemCard` heights for denser data viewing, alongside the ability to tap a single card to expand its details dynamically. (Relies on Phase 1 autonomous layout tracking).
3. **Shopping Mode Banner:** Implement UI to filter the `MainScreen` by a single active Store location, optimizing the list for in-store navigation.
4. **Smart Item Suggestions:** Upgrade the `ItemFormModal` Name input to utilize historical data to auto-fill categories, stores, and tags based on the item name.
5. **Authentication:** Integrate Firebase Auth and apply `userId` filtering to all Firestore queries to support multi-user shared lists.

# AI Developer System Rules for ListiCle

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

```Updated 5/18/2026 v2```
# Listicle - Architecture & Handoff Documentation

## 1. Project Overview

**Listille** is a premium, cross-platform shared task and grocery management application. It is designed for frictionless, power-user data entry and organization. The application features a highly interactive UI with custom gesture controls, segmented dynamic sorting, a robust tag-based categorization system, and custom sliver physics.

### Tech Stack

* **Framework:** Flutter / Dart
* **State Management:** `provider` (ChangeNotifier)
* **Backend:** Firebase Firestore (NoSQL)
* **Key Packages:** `flutter_slidable` (for multi-action swipe menus)

---

## 2. Core Architecture & Design Patterns

### 2.1 State Management (`ListProvider`)

The application uses a centralized Provider architecture (`ListProvider`) to manage local UI state and synchronize with Firestore.

* **Optimistic UI Updates:** Changes (like drag-and-drop reordering or status toggles) update the local state instantly via `notifyListeners()` before executing the asynchronous Firestore network calls.
* **Global Continuous Ordering:** To support flawless cross-group drag-and-drop, the engine applies a continuous, global `order` integer to every item, overriding localized group sorting and locking items exactly where the user drops them.
* **Modular Sorting Hooks:** Group and item sorting logic is abstracted into internal hooks (`_getSortedGroupNames`), preparing the architecture for user-defined custom layout sequencing.
* **Batch Operations:** Complex state changes utilize Firestore `WriteBatch` to minimize network calls and guarantee data integrity.

### 2.2 Segmented List Engine & Custom Sticky Physics

The `MainScreen` does not use standard nested lists or third-party sticky header packages. Instead, it utilizes a flattened array architecture integrated with a custom physics engine.

* **Data Flattening:** The `ListProvider` outputs a single array containing both `String` (Section Headers) and `ListItem` (Item Cards).
* **The Phantom Header Engine:** A separate physics engine tracks the real-time layout coordinates (`GlobalKeys`) of the floating App Bar, the inline headers, and an end-of-list bumper. It calculates collisions during scroll and data-mutation events.
* **Z-Index Masking:** The sticky header is rendered outside the Sliver tree in a `Stack`. It uses a `ClipRect` mask and a `Transform.translate` push offset to create the flawless optical illusion of headers gracefully sliding underneath the floating App Bar.

### 2.3 The Universal Token Engine (`TokenSearchEngine`)

To keep the UI clean, the app avoids standard dropdowns in favor of a custom "Inline Typeahead Token Input."

* **Contextual States:** Functions as a quick-select horizontal scrolling list when minimized, and expands into a focused `TextField` for search/creation.
* **Unified Logic:** A single widget handles single-select (Categories), multi-select (Stores), and lowercase token arrays (Tags).
* **Advanced Keyboard Physics:** Implements a micro-stagger combined with an animated "Runway Buffer" and isolated Scroll Physics to prevent layout thrashing and guarantee the widget clears the OS keyboard.

### 2.4 Multi-Action Gesture Cards

Item cards utilize `flutter_slidable` integrated with custom, nested `AnimatedSize` wrappers and cross-fading components.

* **Smooth Teardown:** Fixes native framework teardown bugs by intercepting the dismiss action, manually shrinking the card's height to `0` over 300ms, and dispatching database deletion *after* the animation finishes.
* **Seamless Expansion:** Inner `AnimatedSize` constraints and anchored padding ensure zero visual overlap when toggling between Compact and Expanded data views.

---

## 3. Database Schema (Firestore)

**Collection:** `items`

| Field | Type | Description |
| --- | --- | --- |
| `id` | String | Unique document identifier |
| `name` | String | User-defined item name |
| `type` | String | Top-level master list (e.g., Groceries, Hardware) |
| `category` | String | Primary grouping (Single-select, e.g., Produce) |
| `locations` | Array[String] | Store routing (Multi-select, e.g., ['Costco', 'Target']) |
| `context` | String | Comma-separated lowercase tags (e.g., 'vegan, urgent') |
| `quantity` | Integer | Item count |
| `order` | Integer | User-defined drag-and-drop index |
| `isCompleted` | Boolean | Marks item as done (hides from active view) |
| `isDeleted` | Boolean | Soft-delete flag for recovery |
| `createdAt` | Timestamp | Standard creation log |
| `updatedAt` | Timestamp | Updated via batch operations |

---

## 4. Directory Structure

```text
lib/
├── components/
│   ├── item_form_modal.dart       # Unified Add/Edit bottom sheet with stabilized drag gestures
│   ├── list_item_card.dart        # Slidable UI component with custom shrink/expand animations
│   ├── main_options_sheet.dart    # App-level configuration and grouping toggles
│   ├── section_header.dart        # Reusable typography layout for inline list grouping
│   └── token_search_engine.dart   # Universal typeahead/quick-select input engine
├── models/
│   └── list_item.dart             # Data class and factory methods
├── screens/
│   ├── main_screen.dart           # Segmented SliverReorderableList and App Drawer
│   └── completed_items_screen.dart # Archive view for finished tasks
├── services/
│   ├── list_provider.dart         # Core state, global ordering logic, and Firestore syncing
│   └── sticky_header_engine.dart  # Encapsulated physics math for the phantom header
└── theme/
    ├── app_constants.dart         # Centralized geometry, padding, and layout animation timings
    └── app_theme.dart             # Centralized colors and typography
```

## 5. Next Development Phases (Roadmap)

1. **Shopping Mode Banner:** Implement UI to filter the `MainScreen` by a single active Store location, optimizing the list for in-store navigation.
2. **Manage Shops & Categories:** Build a configuration UI allowing users to define and save their preferred, custom display sequence for Store and Category headers.
3. **Smart Item Suggestions:** Upgrade the `ItemFormModal` Name input to utilize historical data to auto-fill categories, stores, and tags based on the item name.
4. **Authentication:** Integrate Firebase Auth and apply `userId` filtering to all Firestore queries to support multi-user shared lists.

---

# AI Developer System Rules for Listicle

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