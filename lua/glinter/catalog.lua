-- Shared rule IDs, names, and default severities.
local M = {
  S0 = { name = "subject-empty", severity = "error" },
  S1 = { name = "subject-blank-line", severity = "error" },
  S2 = { name = "subject-soft-length", severity = "warning" },
  S3 = { name = "subject-hard-length", severity = "error" },
  S4 = { name = "subject-capitalize", severity = "error" },
  S5 = { name = "subject-no-period", severity = "error" },
  S6 = { name = "subject-imperative", severity = "warning" },
  S7 = { name = "subject-wip", severity = "warning" },
  B1 = { name = "body-wrap", severity = "error" },
  C1 = { name = "why-not-how", severity = "warning" },
}

return M
