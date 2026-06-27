# C# Windows Forms to Flutter Migration Plan

## 1. Project Analysis
- [x] Read `.sln` and `.csproj` to identify targets, dependencies, and libraries (e.g., Crystal Reports, ADO.NET).
- [x] Identify the database schema (Access `.mdb` file, Typed DataSets). Connection string points to `D:\Betros_Bols.mdb` with Jet OLEDB.
- [x] Discover core data models and relationships.
- [x] Map out the UI architecture (Main forms, dialogs, navigation).
- [x] Locate and analyze core business logic.
- [x] Identify reports generated (Crystal Reports `.rpt` files).

## 2. Migration Strategy Formulation
- [x] Choose the appropriate Flutter state management and architecture (e.g., Provider/Riverpod + MVVM/Clean Architecture).
- [x] Plan database migration from MS Access to SQLite (or Drift) in Flutter.
- [x] Map Windows Forms UI components to Flutter widgets.
- [x] Formulate a plan for replacing Crystal Reports with a Flutter reporting/PDF generation solution.
- [x] Draft a comprehensive `implementation_plan.md`.
- [x] Review plan with the user.

## 3. Phase 1: Database Migration
- [x] Extract Schema & Data from Access `.mdb` to SQLite.
- [x] Define Drift Schema in Flutter.
- [x] Generate DAL (Database Access Layer) using Drift.

## 4. Phase 2: Core Domain & Business Logic 
- [x] Add state management (Riverpod).
- [x] Setup Repository Pattern (e.g., `AreasRepository`, `PersonsRepository`) to wrap Drift DB.
- [x] Reproduce C# business rules (add, edit, validation) in Dart services.

## 5. Phase 3: UI Implementation
- [x] Setup app shell (Main layout, Navigation rail/drawer, routing).
- [x] Create Login Screen (`Pass_Word.cs`).
- [x] Create Areas Management Screen (`Areas.cs`).
- [x] Create Users Management Screen (`Users.cs`).
- [x] Create Schools/Stages Management Screens.
- [x] Create Persons Management and Tracking Screens.

## 6. Phase 4: Reporting
- [ ] Replicate static reports using `pdf` and `printing` packages.
