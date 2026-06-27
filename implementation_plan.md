# C# to Flutter Migration Plan for Petros_Pols

This document outlines the systematic plan to convert the legacy Windows Forms C# application (`Petros_Pols`) into a modern, robust, cross-platform Flutter application.

## 1. Project Analysis & Current State

After examining the C# source code, the following findings about the current architecture are established:

*   **Platform & Tech Stack:** The project is a .NET 3.5 Windows Forms Application.
*   **Database:** MS Access (`.mdb` file named `Betros_Bols.mdb` / `Betros_Bols 2-2014.mdb`). 
*   **Data Access Layer:** Uses a mix of ADO.NET `OleDbConnection`/`OleDbCommand` (raw SQL queries) and highly generated `DataSet` / `TableAdapter` objects (`Betros_BolsDataSet*.xsd`).
*   **Architecture Pattern:** The application currently exhibits the "Smart UI" pattern where Business Logic, Data Access, and UI manipulation are heavily coupled within the code-behind of forms (e.g., `MainForm.cs`, `Areas.cs`, `Users.cs`).
*   **Reporting:** Extensive use of Crystal Reports version 10.5 (`.rpt` files) for generating printouts and static reports.
*   **UI Layout:** Uses an MDI (Multiple Document Interface) parent `MainForm` that spawns child tracking forms for various church entities (Users, Areas, Schools, Hobbies, Stages, Attendance/Coming, Credit, etc.).

## 2. Target Flutter Architecture

To ensure the new Flutter project is maintainable, scalable, and testable, we will abandon the "Smart UI" pattern and adopt a modern architecture:

*   **Architectural Pattern:** MVVM (Model-View-ViewModel) or Feature-First Clean Architecture.
*   **State Management:** `Riverpod` or `Provider` for reactive state binding between Views and ViewModels.
*   **Local Database:** `Drift` (formerly Moor) or `sqflite`. `Drift` is highly recommended for its typesafe SQL generation, which will provide an equivalent but safer experience to the legacy Typed DataSets.
*   **Reporting / PDF Generation:** The `pdf` and `printing` packages in Flutter will be used to programmatically recreate the Crystal Reports templates.
*   **Navigation / Routing:** `go_router` or standard Navigator 2.0. Given the desktop-nature of the original app, a responsive layout featuring a side Navigation Rail/Drawer (replacing the MDI parent form) is recommended.

## 3. Migration Strategy (Step-by-Step)

### Phase 1: Database Migration (Critical First Step)
1.  **Extract Schema & Data:** Use a migration script or tool (like DBeaver or an MS Access to SQLite converter) to convert `Betros_Bols.mdb` into an SQLite database file.
2.  **Define Drift Schema:** Create Drift entity classes in Flutter representing the converted SQLite tables (e.g., `Users`, `Areas`, `Persons`, `Attendance`, `Schools`).
3.  **Generate DAL:** Run Drift's code generator to create the database access layer, replacing the hundreds of legacy `TableAdapter` SQL queries.

### Phase 2: Core Domain & Business Logic Extraction
1.  **Analyze Form Code-Behind:** Systematically review each C# Form (e.g., `Areas.cs`, `Coming.cs`) to identify validation and business rules.
2.  **Create Repositories/Services:** Implement these rules in pure Dart classes (Repositories for DB access, Services for business logic independent of UI).

### Phase 3: UI Implementation (Flutter Widgets)
1.  **Create responsive layouts:** Design a new desktop-first responsive UI. The `MainForm` will become a scaffold with a navigation drawer.
2.  **Implement Screens:** Recreate each C# Form as a Flutter Screen/Page.
    *   *Login Screen:* Maps to `Pass_Word.cs`.
    *   *Dashboard/Home:* Maps to the main view of `MainForm.cs`.
    *   *Entity Management Screens:* Maps to `Areas.cs`, `Users.cs`, `School_Adding.cs`, etc. (using DataTables, Forms, and Dialogs).

### Phase 4: Reporting Generation
1.  Analyze existing `.rpt` files regarding their data sources and layouts.
2.  Use the Flutter `pdf` package to programmatically build equivalent PDF documents that match the old Crystal Reports.
3.  Implement printing and viewing functionality using the `printing` package.

## 4. Verification Plan

*   **Database Verification:** Use DB Browser for SQLite to manually verify that data migrated correctly from Access to SQLite.
*   **Unit Testing:** Write unit tests for the core business logic and database queries (Repositories) to ensure they match the legacy behavior.
*   **UI/Integration Testing:** Use standard Flutter widget tests and manual verification to compare the functional behavior of legacy WinForms with the new Flutter screens (e.g., "Does adding an Area in Flutter update the DB correctly and refresh the table?").

## User Review Required

> [!IMPORTANT]
> Please review this migration plan. This is a complete re-write project rather than a 1:1 code translation due to the platform differences (C# WinForms vs. Dart Flutter) and the legacy database (MS Access vs. SQLite).
> 
> **Questions for the user before proceeding:**
> 1. Do you have a preferred Flutter state management solution (Riverpod vs Provider)?
> 2. For the database, do you prefer using `sqflite` directly, or the typesafe `Drift` ORM?
> 3. Does the application need to support Web and Mobile in the future, or just Desktop (Windows)?
