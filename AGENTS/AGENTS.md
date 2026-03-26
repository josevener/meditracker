# Purpose

This file defines how AI coding agents (e.g. Antigravity and Codex) should behave when working in this repository. Agents must follow the rules below to ensure code quality, consistency, and safety.

# General Rules

- Follow existing project structure and conventions
- Prefer clarity over cleverness
- Do not introduce unnecessary abstractions
- Do not refactor unrelated code unless explicitly asked
- Do not invent APIs, database tables, or fields
- If unsure, ask for clarification instead of guessing
- Keep changes minimal and focused
- Ensure all code is compatible with Windows (e.g. use proper path separators, handle case-insensitivity)
- Do not modify any files in `mobile-app/.dart_tool` unless explicitly asked
- Do not modify the following files unless explicitly asked:
  - `mobile-app/pubspec.yaml`
  - `mobile-app/analysis_options.yaml`
  - Any `.bat` files (e.g. `run_flutter.bat`)
- Always ask for confirmation before implementing any changes unless explicitly stated that you can proceed or if it is obvious in the conversation that you can proceed even without asking for confirmation

# Tech Stack

## Mobile App (mobile-app)

- **Flutter**: Modern UI framework
- **State Management**: Riverpod
- **Routing**: GoRouter
- **HTTP Client**: Dio
- **Local Database**: Drift (with SQLite)
- **Notifications**: flutter_local_notifications

# General Coding Standards

- Use project-standard indentation (2 spaces for Dart).
- Ensure variable names are descriptive and follow project conventions.
- **Naming Conventions by Context**:
  - **Mobile (Dart/Flutter)**:
    - Classes: `PascalCase`
    - Variables/Functions: `camelCase`
    - Constants/Enums: `lowerCamelCase` or `UpperCamelCase` (following official Dart linting)
  - **JSON (API Request & Response Payloads)**:
    - All keys must use `snake_case` (e.g., `{ "employee_id": 1, "time_in": "08:00" }`)
- **AI-Generated Code**: All code written or suggested by an AI agent **must include comments** explaining the logic, especially for non-obvious or complex sections.

## Error handling

- Return meaningful error messages -> good for non technical users, it should be user friendly
- Do not expose sensitive system details
- **Mobile (Flutter)**: Use proper `try...catch` blocks and show user-friendly messages via SnackBar or Dialogs.

# Mobile App Coding Standards (Flutter)

- **Architecture**: Modularize code into `providers`, `repositories`, `models`, and `views`.
- **UI Design**: Follow Material Design principles. Ensure responsive layouts using `MediaQuery` or `LayoutBuilder` when necessary.
- **State Management**: Use `flutter_riverpod` for all state management. Avoid using `setState` in complex widgets.
- **Navigation**: Use `go_router` for all navigation logic.

# When in Doubt

## If any requirement is unclear:

- **Ask**: Don't guess. If a requirement is ambiguous, ask the user for clarification immediately.
- **Verify**: If you make an assumption, state it clearly in your plan and ask for confirmation.
- **Safety**: If a change seems risky or might break existing functionality, stop and warn the user.
- **Context**: If you are missing context (e.g., how a feature overlaps with another), ask the user to point you to relevant files or tasks.

# Final Note for Agents

This repository is production-critical.
