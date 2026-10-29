// 05 — PM tool (Jira, live statuses via API).
#heading(level: 1)[Project Management Tool]
The team runs Scrum in Jira (`cos40007-mlops.atlassian.net`, project SCRUM,
board 1): Sprints 0–4 map foundation → data/ML pipeline → serving → Task-3
retraining/monitoring → hardening/report. The basic slice lives under
*SCRUM-75 — Applied Project Task 3* (Sprint 3, due 26 Nov) as sub-tasks
SCRUM-61…66, all assigned to Lâm An Thịnh with evidence comments linking each
claim to its artefact (workflow runs, `dvc.yaml`, commit history, registry
metrics). Statuses are updated as work lands — via the Jira API where the
token allows — so the board below is a live snapshot, not a staged photo:

#figure(
  image("../figs/fig_jira_board.png", width: 90%),
  caption: [Sprint 3 board snapshot (live Jira statuses, 29 Oct 2026): 4 Done (trigger workflow, DVC pipeline, Actions setup, semantic commits), 2 In Progress (Jira upkeep, this report), rest scheduled seminar extras.],
) <fig-jira>

#table(
  columns: 3,
  [*Sub-task*], [*Status*], [*Evidence*],
  [SCRUM-61 trigger workflow], [Done], [CI green, 3 triggers],
  [SCRUM-62 DVC pipeline], [Done], [`dvc repro` green, 12 outputs],
  [SCRUM-63 Actions setup], [Done], [run Success 2m46s],
  [SCRUM-64 semantic commits], [Done], [15 commits on `main`],
  [SCRUM-65 Jira active use], [In Progress], [this board],
  [SCRUM-66 Task 3 report], [In Progress], [this document],
)
Explore-side work (SCRUM-5/11 model pipeline, SCRUM-22 monitoring spec,
SCRUM-67…72 seminar panels) stays with its owners; the seminar extras
(Grafana, ECS, latency panels) remain To Do as stretch goals.
