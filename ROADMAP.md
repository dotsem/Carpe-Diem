# Carpe Diem Roadmap

A document outlining the current & future development milestones for Carpe Diem.

---

## Current Scope: v0.8.0

- [ ] **Continuous Saving:** Remove the need for manual save button. Edits to the same field coalesce into one undo step.
- [ ] **Advanced Filtering:** Filter tasks by priority and date range, as part of filter modes.
- [ ] **Add & Create More:** Easily create more tasks with the same metadata.
- [ ] **Command Queue:** Queue commands instead of dropping them while another one is processing.
- [ ] **Transactional Commands:** Run compound commands inside a single database transaction.
- [ ] **Soft Deletes:** Tombstone rows (`deleted_at`) instead of hard deletes, preparing for sync.

---

## Planned: v0.9.0 (MCP)

- [ ] **MCP Server:** In-app local HTTP MCP server, secured with a token and Host/Origin checks.
- [ ] **Domain-Level Tools:** Task-oriented tools (e.g. get today, plan task, add tasks) that respect planning rules.
- [ ] **Undoable Agent Actions:** Each MCP call is a single undo step.
- [ ] **Approval Mode:** Settings toggle between auto-apply and approving pending changes in the right sidebar.

---

## Planned: v0.10.0 (Project Notes)

- [ ] **Project Notes:** One markdown document per project.
- [ ] **Extract Tasks:** Highlight text in a note to extract it as a task. Replaces markdown import preview.

---

## Planned: v0.11.0 (Sync)

- [ ] **Hybrid Logical Clocks:** Clock-skew-safe change ordering across devices.
- [ ] **Last-Write-Wins Sync:** Per-row reconciliation, the app stays fully functional offline without setup.
- [ ] **Self-Hosted Sync Server:** Tiny single-user Go relay binary for homelabs.
- [ ] **Cloud Sync:** Hosted instance of the same server (multi-user later).

---

## Planned: v0.12.0 (Cross Platform)

- [ ] **Mobile Support:** Full replica on Android and iOS with an adaptive shell (swipeable kanban columns, sheets instead of sidebar, long-press instead of hover and context menus).

---

## Future plans (no fixed release)

- [ ] **Project Versions:** Assign tasks to specific project versions and track version progress.
