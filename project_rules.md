# ROOM FINDER APP — AI ENGINEERING RULES

## PROJECT PHILOSOPHY

This project is an offline-first Flutter room rental marketplace application.

Primary goals:

* practical production-like MVP
* maintainable architecture
* stable incremental development
* mobile-first UX
* portfolio-quality implementation

The project intentionally prioritizes:

* local persistence
* architecture understanding
* clean ownership/data flow
  before cloud/backend migration.

Avoid:

* premature backend complexity
* unnecessary abstractions
* enterprise overengineering
* giant rewrites

---

# CURRENT STACK

* Flutter
* Dart
* Provider
* Hive
* SharedPreferences
* Material Design

State management:

* Provider only

Persistence:

* Hive + SharedPreferences

Do NOT introduce:

* Riverpod
* BLoC
* Redux
* GetX
  unless explicitly requested.

---

# ARCHITECTURE PRINCIPLES

## 1. Incremental Refactoring Only

Do NOT rewrite large working systems unnecessarily.

Prefer:

* targeted fixes
* small refactors
* backward-compatible improvements

Avoid:

* massive rewrites
* architecture resets
* replacing entire screens without request

---

## 2. Offline-First Priority

The app currently operates locally-first.

Current persistence layer:

* Hive
* SharedPreferences

Cloud migration will happen later.

Do NOT:

* tightly couple UI to Firebase yet
* redesign architecture around backend assumptions
* introduce realtime-only flows prematurely

---

## 3. Ownership Normalization

Use stable identity references.

Preferred pattern:

* ownerId
* userId
* senderId
* participantIds

Avoid duplicated ownership/profile data across models.

Example:
RoomModel should primarily store:

* ownerId

UserModel should remain source of truth for:

* display name
* avatar
* phone
* zalo
* profile data

Avoid long-term duplicated fields like:

* landlordName
* landlordAvatarUrl
* landlordPhone

unless temporarily needed for migration compatibility.

---

## 4. Defensive Null-Safe Coding

Avoid force unwrap operators:

* !

Prefer:

* nullable-safe rendering
* fallback values
* conditional UI rendering

Examples:

* use ?? fallback values
* render placeholders
* hide incomplete sections gracefully

The app must remain stable even with:

* incomplete Hive data
* partially migrated models
* missing local images

---

## 5. Hive Compatibility

Preserve backward compatibility whenever possible.

When extending models:

* prefer optional nullable fields
* avoid destructive migrations
* avoid breaking older local data aggressively

Model evolution should be gradual and resilient.

---

# UI/UX RULES

## 1. No Unrequested Redesigns

Do NOT redesign screens unless explicitly requested.

Prefer:

* refinement
* polish
* UX improvements
* consistency improvements

Maintain:

* existing navigation flow
* existing mental model
* existing architecture

---

## 2. Mobile-First UX

UI should feel:

* lightweight
* responsive
* production-like
* touch-friendly

Avoid:

* overcrowded layouts
* desktop-style UI
* excessive nesting

---

## 3. Consistency System

Maintain consistency for:

* spacing
* typography
* border radius
* colors
* component styling

Prefer reusable lightweight widgets where appropriate.

---

## 4. Smooth Rendering

Avoid:

* nested scrollable conflicts
* rebuild-heavy widgets
* unnecessary FutureBuilders
* expensive build methods

For GridView inside scrollable layouts:

* use shrinkWrap: true
* use NeverScrollableScrollPhysics()

Avoid:

* Expanded/Flexible inside SingleChildScrollView

---

# PROFILE & IDENTITY RULES

Each account should have:

* stable unique id

User identity must not depend on:

* display name
* email
* mutable profile fields

Profile system should support:

* avatar
* phone number
* zalo
* editable display name

Role logic should distinguish between:

* system permissions
  and
* active UI viewing mode

Avoid mixing both concerns into a single variable.

---

# ROOM SYSTEM RULES

Room data should evolve toward structured marketplace data.

Preferred structured fields:

* district
* detailedAddress
* dimensions
* amenities
* availabilityStatus
* galleryImages

Room detail UI should tolerate:

* incomplete data
* old room data
* missing optional fields

---

# CHAT SYSTEM RULES

Messages and conversations should rely on:

* senderId
* participantIds

Avoid duplicated user identity data when possible.

---

# ADMIN SYSTEM RULES

Admin functionality is already implemented.

Do NOT:

* rewrite admin architecture
* redesign moderation flow
* remove moderation protections

Maintain:

* landlord approval flow
* room moderation flow
* role switching capability

---

# PERFORMANCE RULES

Prefer:

* lightweight widgets
* efficient scrolling
* local caching
* stable rendering

Avoid:

* unnecessary rebuilds
* expensive synchronous operations in build()
* layout loops
* invalid image rendering

Validate local file existence before rendering local images.

---

# STEP 8 PREPARATION

The project will later migrate toward:

* Firebase or Supabase
* realtime chat
* cloud storage
* multi-device sync
* push notifications

Current goal:
prepare clean local architecture first.

Do NOT prematurely overengineer backend systems yet.

---

# AI IMPLEMENTATION RULES

When modifying this project:

DO:

* preserve existing architecture
* improve incrementally
* explain architectural tradeoffs clearly
* prefer maintainability over cleverness
* preserve working features
* use defensive programming

DO NOT:

* rewrite unrelated systems
* introduce large abstractions unnecessarily
* replace Provider architecture
* redesign UI without request
* aggressively break Hive compatibility
* duplicate ownership/profile data unnecessarily

Always prioritize:

* stability
* maintainability
* production-like UX
* clean ownership flow
* offline-first compatibility
