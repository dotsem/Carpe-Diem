# Carpe Diem Roadmap

A living document outlining the development milestones for Carpe Diem.

---

## Released: v0.1.0 (Initial Release)

- [✅] **Core Task Management:** Add, complete, and delete tasks.
- [✅] **Categories:** Organise tasks by projects.
- [✅] **Local Storage:** SQLite implementation for persistent data.
- [✅] **Basic UI:** Material Design implementation.

---

## In Plan: v0.2.0 (History, Statistics & Personalization)

The focus of this version is adding history and statistics. It will also include the addition of a settings menu to personalize the app.

### History

- [⏳] **History:** View completed tasks.
- [ ] **Overview:** Get an overview of completed tasks over a certain time period.

### Statistics

- [ ] **Statistics:** Get statistics about tasks.

### Personalization

- [ ] **Dynamic Theming:** Manual toggle and system-based dark mode.
- [ ] **Personalization:** More customizability of the app.

---

## Future: v0.3.0 (Riverpod Migration & Refactor)

This version is focused on architectural stability and technical debt.

### 🌊 State Management Rewrite

- [ ] **Migrate to Riverpod:** Replace Provider/ChangeNotifier with Riverpod providers.
- [ ] **Core Logic Decoupling:** Move repository and logic out of the providers.
- [ ] **Improved Performance:** Implement granular rebuilds for complex lists.

### 🧪 Quality Assurance

- [ ] **Unit Testing:** Increase coverage for core logic.
- [ ] **Widget Testing:** Initial test suite for major UI components.

---

## In Plan: v0.4.0 (Feature Expansion)

The focus of this version is enhancing functionality and user experience.

### Versions

- [ ] **Versions:** Assign a task to a certain version of a project.
- [ ] **Version Overview:** Get an overview of tasks per version.
- [ ] **Version Handling:** Handle multiple versions for a project.
- [ ] **Roadmap Integration:** Tightly integrate with Roadmap.md files.

### Enhanced Markdown Support

- [ ] **Markdown Import Enhancement:** Get preview when importing markdown files.
- [ ] **File Watcher:** Watch for changes in markdown (like Roadmap.md) files and update tasks accordingly.

### New Features

- [ ] **Advanced Filtering:** Filter tasks by priority and date range.

---

## Future: v0.5.0 (Cross platform)

- [ ] **Mobile Support:** Optimised layouts for Android/iOS.

## Future: v0.6.0 (Cloud Sync)

- [ ] **Cloud Sync:** Cross-device synchronization (via cloud provider).
- [ ] **Self Hosted Sync:** Option to sync with own server.

---

### Legend

- [ ] **To Do**
- [⏳] **In Progress**
- [✅] **Done**