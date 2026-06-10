# AI PROJECT RULES (MUST FOLLOW)

This document defines **mandatory rules** for generating or modifying code in this project.  
These rules must always be provided to the AI along with the prompt.

---

## 1. Project Structure (Mandatory)

The project follows this structure and **must be strictly respected**:

- `controllers/`  
  Contains **GetX controllers** and all business logic.

- `screens/`  
  Contains application pages, categorized by feature/topic.

- `widgets/`  
  Contains reusable widgets, categorized appropriately.

- `models/`  
  Contains all data models and DTOs.

❗ Code must only be created or modified in its **correct and intended location**.

---

## 2. Business Logic Separation (Very Important)

- No business logic is allowed inside UI files (`screens` or `widgets`)
- All logic must be implemented inside `controllers`
- UI must only:
    - Display state
    - Call controller methods

---

## 3. Creating New Screens

When creating a new screen:

- Follow the pattern of existing screens
- Place the page inside `screens`
- Create the related controller inside `controllers`
- **Register the new page inside `routes.dart`**
- Follow existing naming conventions and structure

---

## 4. Modifying Existing Code (Critical Rule)

- Modify code **only based on the given prompt**
- ❌ Do NOT make unrelated changes to existing code
- Always review similar existing code before writing new code
- Reuse existing patterns and structures

---

## 5. Widgets & UI Quality

- Widgets must be:
    - Clean
    - Optimized
    - Readable
    - Reusable
- Avoid very large widget files
- Split complex UIs into smaller widgets
- Extract reusable widgets into the `widgets/` directory

---

## 6. Theme, Fonts & Responsive Design

- Always follow the existing **theme, fonts, and styling**
- Do NOT introduce new styles without matching the current structure
- UI must be fully **responsive**
- Follow responsive patterns already used in the project

---

## 7. API & Networking

- All API calls must:
    - Use `api_client.dart`
    - Follow the existing controller API-call pattern

---

## 8. Model Design

- All models must be placed inside `models/`
- Models must be:
    - Clean
    - Reusable
    - Properly mapped to API responses

---

## 9. Toast & User Messages

- For showing toast messages, use ui/toast.dart
