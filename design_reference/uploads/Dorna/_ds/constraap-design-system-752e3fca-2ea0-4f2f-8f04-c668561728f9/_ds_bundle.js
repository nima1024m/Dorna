/* @ds-bundle: {"format":3,"namespace":"ConstraAPDesignSystem_752e3f","components":[],"sourceHashes":{"onboarding/App.jsx":"5728474fb4d4","onboarding/Badges.jsx":"01e777598c1c","onboarding/GetStartedCard.jsx":"532bd31f0f36","onboarding/OnboardingDashboard.jsx":"f8c59f01c21d","onboarding/PrintApp.jsx":"2a12694f190b","onboarding/ProjectWizard.jsx":"ee092414b36f","onboarding/Sidebar.jsx":"eae1da42cd30","onboarding/TopBar.jsx":"6ee7d3147515","onboarding/data.js":"0c8fbdf15af3","onboarding/tweaks-panel.jsx":"6591467622ed","ui_kits/app/App.jsx":"5dbf7fbf05cf","ui_kits/app/Badges.jsx":"01e777598c1c","ui_kits/app/DashboardView.jsx":"4c163e22e1b6","ui_kits/app/InvoiceDetailView.jsx":"d06d7d0560bc","ui_kits/app/InvoicesView.jsx":"ac37e8a8bfb5","ui_kits/app/Sidebar.jsx":"eae1da42cd30","ui_kits/app/TopBar.jsx":"6ee7d3147515","ui_kits/app/data.js":"021ba31b45b4","ui_kits/marketing/LandingPage.jsx":"11f5726ec80a","ui_kits/marketing/LoginModal.jsx":"3672dd6cdaf2"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.ConstraAPDesignSystem_752e3f = window.ConstraAPDesignSystem_752e3f || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// onboarding/App.jsx
try { (() => {
/* ConstraAP — Onboarding prototype root.
   Wizard (org-done → project → project-done) → live first-run Dashboard.
   Owns the step state machine, prerequisite cascades, persistence, and tweaks. */
const {
  useState: useStateRoot,
  useEffect: useEffectRoot
} = React;
const ORG_NAME = "Cascade Builders Ltd.";
const LS_KEY = "constraap_onboarding_v1";

/* ---- step model ---------------------------------------------------------- */
function buildSteps(done, excelConnected) {
  const st = k => done[k] ? "done" : "todo";
  return [
  // Required
  {
    key: "create_org",
    group: "required",
    badge: "required",
    status: "done",
    title: "Create your organization",
    desc: "Your company workspace on ConstraAP."
  }, {
    key: "create_project",
    group: "required",
    badge: "required",
    status: "done",
    title: "Create your first project",
    desc: "Invoices, cost codes, and approvals live inside a project."
  }, {
    key: "upload_invoice",
    group: "required-core",
    badge: "required",
    status: st("upload_invoice"),
    title: "Upload your first invoice",
    desc: "The core action — extract vendor, amount, date, and line items.",
    cta: "Upload",
    ctaIcon: "cloud_upload"
  },
  // Optional — each unlocks a feature
  {
    key: "connect_email",
    group: "optional",
    badge: "optional",
    status: st("connect_email"),
    title: "Connect email for auto-import",
    desc: "Import invoices from Outlook or Gmail automatically.",
    unlocks: "Unlocks Poll Email",
    cta: "Connect",
    ctaIcon: "mail"
  }, {
    key: "connect_excel",
    group: "optional",
    badge: "optional",
    status: st("connect_excel"),
    title: "Connect Excel / SharePoint",
    desc: "Export reviewed invoices straight to your draw workbook.",
    unlocks: "Unlocks export",
    cta: "Connect",
    ctaIcon: "table_view"
  }, {
    key: "file_archive",
    group: "optional",
    badge: "optional",
    status: done.file_archive ? "done" : excelConnected ? "todo" : "locked",
    title: "Set up OneDrive file archive",
    desc: "Mirror invoice files to OneDrive with RAG-friendly names.",
    cta: "Configure",
    ctaIcon: "cloud_sync",
    lockedReason: "Connect Excel / SharePoint first to enable the OneDrive file archive."
  }, {
    key: "cost_codes",
    group: "optional",
    badge: "optional",
    status: st("cost_codes"),
    title: "Set up your cost codes",
    desc: "Accurate classification — otherwise invoices stay UNCLASSIFIED.",
    cta: "Set up",
    ctaIcon: "tag"
  }, {
    key: "invite_team",
    group: "optional",
    badge: "optional",
    status: st("invite_team"),
    title: "Invite your team",
    desc: "Add coordinators, accountants, and approvers with roles.",
    cta: "Invite",
    ctaIcon: "group_add"
  }];
}
function loadState() {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (raw) return JSON.parse(raw);
  } catch (e) {/* ignore */}
  return null;
}
function App() {
  const saved = loadState();
  const [phase, setPhase] = useStateRoot(saved?.phase || "org-done");
  const [project, setProject] = useStateRoot(saved?.project || {
    name: "",
    code: ""
  });
  const [done, setDone] = useStateRoot(saved?.done || {});
  const [dismissed, setDismissed] = useStateRoot(saved?.dismissed || false);
  const [t, setTweak] = window.useTweaks(window.TWEAK_DEFAULTS);

  // keep window.PROJECTS in sync for the Sidebar once a project exists
  useEffectRoot(() => {
    window.PROJECTS = project.code ? [{
      id: "np1",
      code: project.code,
      name: project.name
    }] : [];
  }, [project]);

  // persist
  useEffectRoot(() => {
    try {
      localStorage.setItem(LS_KEY, JSON.stringify({
        phase,
        project,
        done,
        dismissed
      }));
    } catch (e) {/* ignore */}
  }, [phase, project, done, dismissed]);
  const emailConnected = !!done.connect_email;
  const excelConnected = !!done.connect_excel;
  const steps = buildSteps(done, excelConnected);
  const invoices = done.upload_invoice ? window.SEED_INVOICES.map(i => ({
    ...i,
    project_id: "np1"
  })) : [];
  const handleStepAction = key => setDone(d => ({
    ...d,
    [key]: true
  }));
  const restart = () => {
    try {
      localStorage.removeItem(LS_KEY);
    } catch (e) {/* ignore */}
    setDone({});
    setDismissed(false);
    setProject({
      name: "",
      code: ""
    });
    setPhase("org-done");
  };
  const RestartPill = /*#__PURE__*/React.createElement("button", {
    className: "ob-restart",
    onClick: restart,
    title: "Reset the prototype to the start"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "restart_alt"), "Restart onboarding");
  const Tweaks = /*#__PURE__*/React.createElement(window.TweaksPanel, null, /*#__PURE__*/React.createElement(window.TweakSection, {
    label: "Checklist"
  }), /*#__PURE__*/React.createElement(window.TweakRadio, {
    label: "Density",
    value: t.density,
    options: ["comfortable", "compact"],
    onChange: v => setTweak("density", v)
  }), /*#__PURE__*/React.createElement(window.TweakToggle, {
    label: "Show 'unlocks' hints",
    value: t.showUnlocks,
    onChange: v => setTweak("showUnlocks", v)
  }), /*#__PURE__*/React.createElement(window.TweakSection, {
    label: "Accent"
  }), /*#__PURE__*/React.createElement(window.TweakColor, {
    label: "Progress accent",
    value: t.accent,
    options: ["#000000", "#0078d4", "#107C10"],
    onChange: v => setTweak("accent", v)
  }));

  // ---- wizard phases ----
  if (phase === "org-done") {
    return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(window.ProjectWizard.OrgDone, {
      orgName: ORG_NAME,
      onContinue: () => setPhase("project")
    }), RestartPill, Tweaks);
  }
  if (phase === "project") {
    return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(window.ProjectWizard.ProjectForm, {
      initial: project,
      onBack: () => setPhase("org-done"),
      onCreate: p => {
        setProject(p);
        setDone(d => ({
          ...d,
          create_project: true
        }));
        setPhase("project-done");
      }
    }), RestartPill, Tweaks);
  }
  if (phase === "project-done") {
    return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(window.ProjectWizard.ProjectDone, {
      project: project,
      onEnter: () => setPhase("app")
    }), RestartPill, Tweaks);
  }

  // ---- app phase ----
  return /*#__PURE__*/React.createElement("div", {
    className: "shell"
  }, /*#__PURE__*/React.createElement(window.Sidebar, {
    current: "dashboard",
    selectedProject: {
      id: "np1",
      code: project.code,
      name: project.name
    },
    onSelectProject: () => {},
    onNavigate: () => {}
  }), /*#__PURE__*/React.createElement("div", {
    className: "main-col"
  }, /*#__PURE__*/React.createElement(window.TopBar, {
    crumbs: ["Dashboard"],
    userEmail: "j.harper@cascadebuilders.ca"
  }), /*#__PURE__*/React.createElement("main", {
    className: "content"
  }, /*#__PURE__*/React.createElement(window.OnboardingDashboard, {
    project: project,
    steps: steps,
    invoices: invoices,
    emailConnected: emailConnected,
    excelConnected: excelConnected,
    checklistDismissed: dismissed,
    density: t.density,
    accent: t.accent,
    showUnlocks: t.showUnlocks,
    onStepAction: handleStepAction,
    onDismissChecklist: () => setDismissed(true)
  }))), RestartPill, Tweaks);
}
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/App.jsx", error: String((e && e.message) || e) }); }

// onboarding/Badges.jsx
try { (() => {
/* ConstraAP — shared badges & helpers */
const STATUS_COLORS = {
  pending: {
    background: "#fef3c7",
    color: "#92400e"
  },
  processing: {
    background: "#dbeafe",
    color: "#1e40af"
  },
  reviewed: {
    background: "#d1fae5",
    color: "#065f46"
  },
  exported: {
    background: "#f3f4f6",
    color: "#374151"
  },
  deleted: {
    background: "#fee2e2",
    color: "#991b1b"
  }
};
function StatusBadge({
  status
}) {
  const c = STATUS_COLORS[status] || STATUS_COLORS.exported;
  return /*#__PURE__*/React.createElement("span", {
    className: "badge",
    style: c
  }, status);
}
const APPROVAL_CONFIG = {
  submitted: {
    label: "Submitted",
    bg: "#dce2f3",
    fg: "#5e6572",
    bd: "var(--color-outline-variant)"
  },
  coordinator_review: {
    label: "Coordinator Review",
    bg: "#dce2f7",
    fg: "#141b2b",
    bd: "var(--color-outline-variant)"
  },
  under_review: {
    label: "Under Review",
    bg: "#eae7e9",
    fg: "#1b1b1d",
    bd: "var(--color-outline-variant)"
  },
  pm_approved: {
    label: "PM Approved",
    bg: "#f0edee",
    fg: "#1b1b1d",
    bd: "var(--color-outline-variant)"
  },
  final_approved: {
    label: "Final Approved",
    bg: "#dce2f7",
    fg: "#141b2b",
    bd: "var(--color-outline-variant)"
  },
  payment_issued: {
    label: "Paid",
    bg: "#f6f3f4",
    fg: "#45464c",
    bd: "var(--color-outline-variant)"
  },
  returned: {
    label: "Returned",
    bg: "#f9debf",
    fg: "#55442d",
    bd: "var(--color-outline-variant)"
  },
  rejected: {
    label: "Rejected",
    bg: "#ffdad6",
    fg: "#93000a",
    bd: "rgba(186,26,26,.2)"
  },
  deleted: {
    label: "Deleted",
    bg: "#ffdad6",
    fg: "#93000a",
    bd: "rgba(186,26,26,.2)"
  }
};
function ApprovalBadge({
  status
}) {
  const c = APPROVAL_CONFIG[status] || {
    label: status,
    bg: "#f0edee",
    fg: "#45464c",
    bd: "var(--color-outline-variant)"
  };
  return /*#__PURE__*/React.createElement("span", {
    className: "abadge",
    style: {
      background: c.bg,
      color: c.fg,
      borderColor: c.bd
    }
  }, c.label);
}
function CostCode({
  code
}) {
  return /*#__PURE__*/React.createElement("span", {
    className: "cost-code"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "tag"), code);
}
const money = n => n.toLocaleString("en-CA", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});
Object.assign(window, {
  StatusBadge,
  ApprovalBadge,
  CostCode,
  money,
  APPROVAL_CONFIG
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/Badges.jsx", error: String((e && e.message) || e) }); }

// onboarding/GetStartedCard.jsx
try { (() => {
/* ConstraAP — Onboarding: persistent "Get started" checklist for the Dashboard.
   Tracks required + optional steps with live progress, per-item CTA, Optional/
   Required badges, and locked rows (with a reason tooltip) whose prerequisite
   isn't met yet. Presentational — App owns the step state. */
const {
  useState: useStateGS
} = React;
function StepRow({
  step,
  density,
  showUnlocks,
  onAction
}) {
  const {
    status,
    group
  } = step;
  const cls = "gs-item " + status + (group === "required-core" ? " required-core" : "");
  return /*#__PURE__*/React.createElement("div", {
    className: cls
  }, /*#__PURE__*/React.createElement("button", {
    className: "gs-check",
    disabled: status === "done" || status === "locked",
    onClick: () => status === "todo" && onAction(step.key),
    "aria-label": status === "done" ? "Completed" : status === "locked" ? "Locked" : "Mark complete"
  }, status === "done" && /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "check"), status === "locked" && /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "lock")), /*#__PURE__*/React.createElement("div", {
    className: "gs-meta"
  }, /*#__PURE__*/React.createElement("div", {
    className: "title"
  }, /*#__PURE__*/React.createElement("span", {
    className: "t"
  }, step.title), step.badge === "required" && /*#__PURE__*/React.createElement("span", {
    className: "gs-badge required"
  }, "Required"), step.badge === "optional" && /*#__PURE__*/React.createElement("span", {
    className: "gs-badge optional"
  }, "Optional"), showUnlocks && step.unlocks && status !== "done" && /*#__PURE__*/React.createElement("span", {
    className: "gs-badge unlocks"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "bolt"), step.unlocks)), density !== "compact" && /*#__PURE__*/React.createElement("div", {
    className: "desc"
  }, step.desc)), status === "done" && /*#__PURE__*/React.createElement("span", {
    className: "gs-done-tick"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "check_circle"), "Done"), status === "todo" && /*#__PURE__*/React.createElement("button", {
    className: "gs-cta " + (step.badge === "required" ? "solid" : "outline"),
    onClick: () => onAction(step.key)
  }, step.ctaIcon && /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, step.ctaIcon), step.cta), status === "locked" && /*#__PURE__*/React.createElement("span", {
    className: "gs-lock",
    tabIndex: 0
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "lock"), "Locked", /*#__PURE__*/React.createElement("span", {
    className: "gs-tip"
  }, step.lockedReason)));
}
function GetStartedCard({
  steps,
  density,
  accent,
  showUnlocks,
  onAction,
  onDismiss
}) {
  const [open, setOpen] = useStateGS(true);
  const counted = steps.filter(s => s.group !== "meta");
  const doneCount = counted.filter(s => s.status === "done").length;
  const total = counted.length;
  const pct = Math.round(doneCount / total * 100);
  const allDone = doneCount === total;
  const required = steps.filter(s => s.badge === "required");
  const optional = steps.filter(s => s.badge === "optional");
  if (allDone) {
    return /*#__PURE__*/React.createElement("div", {
      className: "gs-card obfade",
      style: {
        "--gs-accent": accent
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "gs-complete"
    }, /*#__PURE__*/React.createElement("div", {
      className: "burst"
    }, /*#__PURE__*/React.createElement("span", {
      className: "material-symbols-outlined"
    }, "verified")), /*#__PURE__*/React.createElement("div", {
      className: "gt",
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement("h2", null, "You're fully set up"), /*#__PURE__*/React.createElement("p", null, "Every required and optional step is complete. This card won't show again.")), /*#__PURE__*/React.createElement("button", {
      className: "gs-cta outline",
      onClick: onDismiss
    }, /*#__PURE__*/React.createElement("span", {
      className: "material-symbols-outlined"
    }, "check"), "Dismiss")));
  }
  return /*#__PURE__*/React.createElement("div", {
    className: "gs-card",
    style: {
      "--gs-accent": accent
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "gs-head",
    onClick: () => setOpen(o => !o)
  }, /*#__PURE__*/React.createElement("div", {
    className: "lead"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "rocket_launch")), /*#__PURE__*/React.createElement("div", {
    className: "ht"
  }, /*#__PURE__*/React.createElement("h2", null, "Get started with ConstraAP"), /*#__PURE__*/React.createElement("p", null, "Finish setup to unlock the full invoice pipeline.")), /*#__PURE__*/React.createElement("div", {
    className: "count"
  }, doneCount, " / ", total), /*#__PURE__*/React.createElement("div", {
    className: "chev" + (open ? " open" : "")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "expand_more"))), /*#__PURE__*/React.createElement("div", {
    className: "gs-progress"
  }, /*#__PURE__*/React.createElement("div", {
    className: "fill",
    style: {
      width: pct + "%"
    }
  })), open && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "gs-body"
  }, /*#__PURE__*/React.createElement("div", {
    className: "gs-group-label"
  }, "Required"), /*#__PURE__*/React.createElement("div", {
    className: "gs-list " + density
  }, required.map(s => /*#__PURE__*/React.createElement(StepRow, {
    key: s.key,
    step: s,
    density: density,
    showUnlocks: showUnlocks,
    onAction: onAction
  }))), /*#__PURE__*/React.createElement("div", {
    className: "gs-group-label"
  }, "Optional \xB7 each unlocks a feature"), /*#__PURE__*/React.createElement("div", {
    className: "gs-list " + density
  }, optional.map(s => /*#__PURE__*/React.createElement(StepRow, {
    key: s.key,
    step: s,
    density: density,
    showUnlocks: showUnlocks,
    onAction: onAction
  })))), /*#__PURE__*/React.createElement("div", {
    className: "gs-foot"
  }, /*#__PURE__*/React.createElement("span", {
    className: "txt"
  }, total - doneCount, " step", total - doneCount === 1 ? "" : "s", " left \xB7 optional steps can wait"), /*#__PURE__*/React.createElement("button", {
    className: "dismiss",
    onClick: onDismiss
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "close"), "Dismiss"))));
}
window.GetStartedCard = GetStartedCard;
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/GetStartedCard.jsx", error: String((e && e.message) || e) }); }

// onboarding/OnboardingDashboard.jsx
try { (() => {
/* ConstraAP — Onboarding: first-run Dashboard.
   Hosts the Get-started checklist, shows the empty state until the first invoice
   lands, and demonstrates the "disabled-until-prerequisite" rule on Poll Email
   (only active after email is connected). */
function OBStatCard({
  label,
  value,
  icon,
  sub
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "stat"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ico"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, icon)), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "k"
  }, label), /*#__PURE__*/React.createElement("div", {
    className: "v"
  }, value), sub && /*#__PURE__*/React.createElement("div", {
    className: "sub"
  }, sub)));
}
function OnboardingDashboard(props) {
  const {
    project,
    steps,
    invoices,
    emailConnected,
    excelConnected,
    checklistDismissed,
    density,
    accent,
    showUnlocks,
    onStepAction,
    onDismissChecklist
  } = props;
  const hasInvoices = invoices.length > 0;
  const reviewed = invoices.filter(i => i.status === "reviewed").length;
  const action = invoices.filter(i => i.status === "pending" || i.status === "processing").length;
  return /*#__PURE__*/React.createElement("div", {
    className: "stack"
  }, /*#__PURE__*/React.createElement("div", {
    className: "page-head"
  }, /*#__PURE__*/React.createElement("h1", null, "Dashboard"), /*#__PURE__*/React.createElement("p", null, "Overview of your invoice processing pipeline.")), !checklistDismissed && /*#__PURE__*/React.createElement(window.GetStartedCard, {
    steps: steps,
    density: density,
    accent: accent,
    showUnlocks: showUnlocks,
    onAction: onStepAction,
    onDismiss: onDismissChecklist
  }), /*#__PURE__*/React.createElement("div", {
    className: "proj-row"
  }, /*#__PURE__*/React.createElement("span", {
    className: "lbl"
  }, "Project:"), /*#__PURE__*/React.createElement("button", {
    className: "chip on"
  }, project.code, " \u2014 ", project.name)), /*#__PURE__*/React.createElement("div", {
    className: "row",
    style: {
      justifyContent: "flex-end",
      alignItems: "center"
    }
  }, emailConnected ? /*#__PURE__*/React.createElement("button", {
    className: "btn btn-outline",
    title: "Poll connected mailbox for new invoices"
  }, /*#__PURE__*/React.createElement("span", {
    className: "conn-dot"
  }), /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "sync"), "Poll Email") : /*#__PURE__*/React.createElement("span", {
    className: "tt-wrap"
  }, /*#__PURE__*/React.createElement("button", {
    className: "btn btn-outline is-locked",
    disabled: true
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined lk"
  }, "lock"), /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "sync"), "Poll Email"), /*#__PURE__*/React.createElement("span", {
    className: "tt"
  }, "Connect your email first to enable polling. Set it up from the Get started checklist.")), /*#__PURE__*/React.createElement("button", {
    className: "btn btn-primary",
    onClick: () => onStepAction("upload_invoice")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "cloud_upload"), "Upload Invoice")), !hasInvoices ? /*#__PURE__*/React.createElement("div", {
    className: "dash-empty obfade"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ico"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "receipt_long")), /*#__PURE__*/React.createElement("h3", null, "No invoices yet"), /*#__PURE__*/React.createElement("p", null, "Upload a PDF or photo, scan with your phone, or connect email to import automatically. Your extracted invoices for ", /*#__PURE__*/React.createElement("strong", {
    style: {
      color: "var(--color-on-surface)"
    }
  }, project.code), " will appear here."), /*#__PURE__*/React.createElement("div", {
    className: "e-actions"
  }, /*#__PURE__*/React.createElement("button", {
    className: "btn btn-primary",
    onClick: () => onStepAction("upload_invoice")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "cloud_upload"), "Upload your first invoice"), !emailConnected && /*#__PURE__*/React.createElement("button", {
    className: "btn btn-outline",
    onClick: () => onStepAction("connect_email")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "mail"), "Connect email"))) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "stat-grid obfade"
  }, /*#__PURE__*/React.createElement(OBStatCard, {
    label: "Total Invoices",
    value: invoices.length,
    icon: "receipt_long"
  }), /*#__PURE__*/React.createElement(OBStatCard, {
    label: "Action Required",
    value: action,
    icon: "pending_actions",
    sub: "needs review"
  }), /*#__PURE__*/React.createElement(OBStatCard, {
    label: "Reviewed",
    value: reviewed,
    icon: "task_alt"
  }), /*#__PURE__*/React.createElement(OBStatCard, {
    label: "Exported",
    value: 0,
    icon: "cloud_done",
    sub: excelConnected ? "ready to export" : "connect Excel"
  })), /*#__PURE__*/React.createElement("div", {
    className: "stack-sm"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sec-head"
  }, /*#__PURE__*/React.createElement("h2", null, "Recent Invoices"), /*#__PURE__*/React.createElement("button", {
    className: "link-btn"
  }, "View all", /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "arrow_forward"))), /*#__PURE__*/React.createElement("div", {
    className: "card-table obfade"
  }, /*#__PURE__*/React.createElement("table", null, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, /*#__PURE__*/React.createElement("th", null, "Vendor"), /*#__PURE__*/React.createElement("th", null, "Invoice #"), /*#__PURE__*/React.createElement("th", null, "Date"), /*#__PURE__*/React.createElement("th", null, "Amount"), /*#__PURE__*/React.createElement("th", null, "Status"))), /*#__PURE__*/React.createElement("tbody", null, invoices.map(inv => /*#__PURE__*/React.createElement("tr", {
    key: inv.id,
    className: inv.isNew ? "hl" : ""
  }, /*#__PURE__*/React.createElement("td", {
    className: "vendor"
  }, inv.vendor, inv.isNew && /*#__PURE__*/React.createElement("span", {
    className: "tag-new"
  }, "NEW")), /*#__PURE__*/React.createElement("td", {
    className: "muted-mono"
  }, inv.number), /*#__PURE__*/React.createElement("td", {
    className: "date"
  }, inv.date), /*#__PURE__*/React.createElement("td", {
    className: "amt"
  }, inv.currency, " ", window.money(inv.amount)), /*#__PURE__*/React.createElement("td", null, /*#__PURE__*/React.createElement(window.StatusBadge, {
    status: inv.status
  }))))))))));
}
window.OnboardingDashboard = OnboardingDashboard;
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/OnboardingDashboard.jsx", error: String((e && e.message) || e) }); }

// onboarding/PrintApp.jsx
try { (() => {
/* ConstraAP — Onboarding PRINT orchestrator.
   Renders the prototype's key states as static, paged screens for PDF export.
   Does NOT mount the interactive App (no state machine / tweaks / restart). */
const {
  useEffect: useEffectPrint
} = React;

/* same step model as App.jsx (kept local — App.jsx is not loaded in print) */
function buildStepsPrint(done, excelConnected) {
  const st = k => done[k] ? "done" : "todo";
  return [{
    key: "create_org",
    group: "required",
    badge: "required",
    status: "done",
    title: "Create your organization",
    desc: "Your company workspace on ConstraAP."
  }, {
    key: "create_project",
    group: "required",
    badge: "required",
    status: "done",
    title: "Create your first project",
    desc: "Invoices, cost codes, and approvals live inside a project."
  }, {
    key: "upload_invoice",
    group: "required-core",
    badge: "required",
    status: st("upload_invoice"),
    title: "Upload your first invoice",
    desc: "The core action — extract vendor, amount, date, and line items.",
    cta: "Upload",
    ctaIcon: "cloud_upload"
  }, {
    key: "connect_email",
    group: "optional",
    badge: "optional",
    status: st("connect_email"),
    title: "Connect email for auto-import",
    desc: "Import invoices from Outlook or Gmail automatically.",
    unlocks: "Unlocks Poll Email",
    cta: "Connect",
    ctaIcon: "mail"
  }, {
    key: "connect_excel",
    group: "optional",
    badge: "optional",
    status: st("connect_excel"),
    title: "Connect Excel / SharePoint",
    desc: "Export reviewed invoices straight to your draw workbook.",
    unlocks: "Unlocks export",
    cta: "Connect",
    ctaIcon: "table_view"
  }, {
    key: "file_archive",
    group: "optional",
    badge: "optional",
    status: done.file_archive ? "done" : excelConnected ? "todo" : "locked",
    title: "Set up OneDrive file archive",
    desc: "Mirror invoice files to OneDrive with RAG-friendly names.",
    cta: "Configure",
    ctaIcon: "cloud_sync",
    lockedReason: "Connect Excel / SharePoint first to enable the OneDrive file archive."
  }, {
    key: "cost_codes",
    group: "optional",
    badge: "optional",
    status: st("cost_codes"),
    title: "Set up your cost codes",
    desc: "Accurate classification — otherwise invoices stay UNCLASSIFIED.",
    cta: "Set up",
    ctaIcon: "tag"
  }, {
    key: "invite_team",
    group: "optional",
    badge: "optional",
    status: st("invite_team"),
    title: "Invite your team",
    desc: "Add coordinators, accountants, and approvers with roles.",
    cta: "Invite",
    ctaIcon: "group_add"
  }];
}
const PRINT_PROJECT = {
  id: "np1",
  code: "W15",
  name: "Tower Renovation"
};
function DashShell({
  done
}) {
  window.PROJECTS = [PRINT_PROJECT];
  const excelConnected = !!done.connect_excel;
  const steps = buildStepsPrint(done, excelConnected);
  const invoices = done.upload_invoice ? window.SEED_INVOICES.map(i => ({
    ...i,
    project_id: "np1"
  })) : [];
  return /*#__PURE__*/React.createElement("div", {
    className: "shell print-shell"
  }, /*#__PURE__*/React.createElement(window.Sidebar, {
    current: "dashboard",
    selectedProject: PRINT_PROJECT,
    onSelectProject: () => {},
    onNavigate: () => {}
  }), /*#__PURE__*/React.createElement("div", {
    className: "main-col"
  }, /*#__PURE__*/React.createElement(window.TopBar, {
    crumbs: ["Dashboard"],
    userEmail: "j.harper@cascadebuilders.ca"
  }), /*#__PURE__*/React.createElement("main", {
    className: "content"
  }, /*#__PURE__*/React.createElement(window.OnboardingDashboard, {
    project: PRINT_PROJECT,
    steps: steps,
    invoices: invoices,
    emailConnected: !!done.connect_email,
    excelConnected: excelConnected,
    checklistDismissed: false,
    density: "comfortable",
    accent: "#000000",
    showUnlocks: true,
    onStepAction: () => {},
    onDismissChecklist: () => {}
  }))));
}
function Page({
  n,
  title,
  sub,
  children
}) {
  return /*#__PURE__*/React.createElement("section", {
    className: "print-page"
  }, /*#__PURE__*/React.createElement("header", {
    className: "print-cap"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pc-n"
  }, n), /*#__PURE__*/React.createElement("span", {
    className: "pc-t"
  }, title), sub && /*#__PURE__*/React.createElement("span", {
    className: "pc-s"
  }, sub)), /*#__PURE__*/React.createElement("div", {
    className: "print-body"
  }, children));
}
function PrintApp() {
  useEffectPrint(() => {
    let done = false;
    const go = () => {
      if (done) return;
      done = true;
      setTimeout(() => window.print(), 500);
    };
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(go);else setTimeout(go, 1200);
  }, []);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Page, {
    n: "01",
    title: "Organization created \u2014 hand-off",
    sub: "Required wizard \xB7 the new step lives where \u201CGo to Dashboard\u201D used to be"
  }, /*#__PURE__*/React.createElement(window.ProjectWizard.OrgDone, {
    orgName: "Cascade Builders Ltd.",
    onContinue: () => {}
  })), /*#__PURE__*/React.createElement(Page, {
    n: "02",
    title: "Create your first project",
    sub: "New required step \xB7 minimal name + code, matches the org wizard"
  }, /*#__PURE__*/React.createElement(window.ProjectWizard.ProjectForm, {
    initial: {
      name: "Tower Renovation",
      code: "W15"
    },
    onBack: () => {},
    onCreate: () => {}
  })), /*#__PURE__*/React.createElement(Page, {
    n: "03",
    title: "Project created \u2014 into the app",
    sub: "Confirmation \u2192 first-run dashboard"
  }, /*#__PURE__*/React.createElement(window.ProjectWizard.ProjectDone, {
    project: PRINT_PROJECT,
    onEnter: () => {}
  })), /*#__PURE__*/React.createElement(Page, {
    n: "04",
    title: "Dashboard \u2014 first run",
    sub: "Get-started checklist \xB7 empty state \xB7 Poll Email locked until email connects"
  }, /*#__PURE__*/React.createElement(DashShell, {
    done: {}
  })), /*#__PURE__*/React.createElement(Page, {
    n: "05",
    title: "Dashboard \u2014 setup in progress",
    sub: "Excel connected \u2192 File Archive unlocked \xB7 email connected \u2192 Poll Email active"
  }, /*#__PURE__*/React.createElement(DashShell, {
    done: {
      connect_email: true,
      connect_excel: true,
      cost_codes: true
    }
  })), /*#__PURE__*/React.createElement(Page, {
    n: "06",
    title: "Dashboard \u2014 fully set up",
    sub: "Checklist complete \xB7 first invoices flowing in"
  }, /*#__PURE__*/React.createElement(DashShell, {
    done: {
      upload_invoice: true,
      connect_email: true,
      connect_excel: true,
      file_archive: true,
      cost_codes: true,
      invite_team: true
    }
  })));
}
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(PrintApp, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/PrintApp.jsx", error: String((e && e.message) || e) }); }

// onboarding/ProjectWizard.jsx
try { (() => {
/* ConstraAP — Onboarding: required linear wizard.
   Renders the three wizard phases that bridge org-creation → dashboard:
     org-done  → (NEW) project  → project-done
   The org sub-wizard (details/roles/done) already exists in the product; this
   picks up at its hand-off and adds the missing "Create your first project" step. */
const {
  useState: useStatePW
} = React;
const REQ_STEPS = ["Organization", "Project", "First invoice"];
function StepDots({
  activeIndex
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ob-dots",
    role: "progressbar",
    "aria-valuenow": activeIndex + 1,
    "aria-valuemax": REQ_STEPS.length
  }, REQ_STEPS.map((s, i) => /*#__PURE__*/React.createElement("div", {
    key: s,
    title: s,
    className: "ob-dot " + (i === activeIndex ? "active" : i < activeIndex ? "done" : "upcoming")
  })));
}
function RequiredFoot({
  activeIndex
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ob-foot"
  }, REQ_STEPS.map((s, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: s
  }, i > 0 && /*#__PURE__*/React.createElement("span", {
    className: "div"
  }), /*#__PURE__*/React.createElement("span", {
    className: "seg " + (i < activeIndex ? "done" : i === activeIndex ? "now" : "")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, i < activeIndex ? "check_circle" : i === activeIndex ? "radio_button_checked" : "radio_button_unchecked"), s))));
}

/* Phase: organization just created — the hand-off screen. In the live product
   this screen's primary button used to be "Go to Dashboard" (→ a locked,
   project-less dashboard). We replace it with the first-project step. */
function OrgDone({
  orgName,
  onContinue
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ob-stage"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ob-brand"
  }, /*#__PURE__*/React.createElement("div", {
    className: "wordmark"
  }, "ConstraAP"), /*#__PURE__*/React.createElement("p", null, "Operational Finance")), /*#__PURE__*/React.createElement("div", {
    className: "ob-card obfade"
  }, /*#__PURE__*/React.createElement(StepDots, {
    activeIndex: 0
  }), /*#__PURE__*/React.createElement("div", {
    className: "ob-done"
  }, /*#__PURE__*/React.createElement("div", {
    className: "burst"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "celebration")), /*#__PURE__*/React.createElement("h1", null, "Organization created"), /*#__PURE__*/React.createElement("div", {
    className: "pill"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined",
    style: {
      fontSize: 15,
      color: "var(--color-on-surface-variant)"
    }
  }, "apartment"), /*#__PURE__*/React.createElement("span", {
    className: "code"
  }, orgName)), /*#__PURE__*/React.createElement("p", {
    className: "sub",
    style: {
      marginBottom: 22
    }
  }, "Your workspace is ready. One more required step: create your first ", /*#__PURE__*/React.createElement("strong", {
    style: {
      color: "var(--color-on-surface)"
    }
  }, "project"), " so you can start processing invoices."), /*#__PURE__*/React.createElement("div", {
    className: "ob-actions"
  }, /*#__PURE__*/React.createElement("button", {
    className: "ob-btn primary",
    onClick: onContinue
  }, "Create your first project", /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "arrow_forward"))))), /*#__PURE__*/React.createElement(RequiredFoot, {
    activeIndex: 1
  }));
}

/* Phase: the NEW create-first-project step. Minimal — name + code, matching the
   product's configApi.createProject({ name, code }). */
function ProjectForm({
  initial,
  onBack,
  onCreate
}) {
  const [name, setName] = useStatePW(initial.name || "");
  const [code, setCode] = useStatePW(initial.code || "");
  const [error, setError] = useStatePW(null);
  const [loading, setLoading] = useStatePW(false);
  const autoCode = s => s.trim().toUpperCase().replace(/[^A-Z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 12);
  const submit = () => {
    if (!name.trim() || !code.trim()) {
      setError("Project name and code are both required.");
      return;
    }
    setError(null);
    setLoading(true);
    // simulate the createProject round-trip
    setTimeout(() => onCreate({
      name: name.trim(),
      code: code.trim().toUpperCase()
    }), 650);
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "ob-stage"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ob-brand"
  }, /*#__PURE__*/React.createElement("div", {
    className: "wordmark"
  }, "ConstraAP"), /*#__PURE__*/React.createElement("p", null, "Operational Finance")), /*#__PURE__*/React.createElement("div", {
    className: "ob-card obfade"
  }, /*#__PURE__*/React.createElement(StepDots, {
    activeIndex: 1
  }), /*#__PURE__*/React.createElement("div", {
    className: "ob-eyebrow"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "lock"), "Required setup \xB7 Step 2 of 3"), /*#__PURE__*/React.createElement("h1", {
    style: {
      textAlign: "center"
    }
  }, "Create your first project"), /*#__PURE__*/React.createElement("p", {
    className: "sub",
    style: {
      textAlign: "center"
    }
  }, "Projects organize invoices, cost codes, and approvals. Almost everything in ConstraAP is project-scoped \u2014 you'll need at least one to begin."), /*#__PURE__*/React.createElement("label", {
    className: "ob-field"
  }, /*#__PURE__*/React.createElement("span", {
    className: "lbl"
  }, "Project name ", /*#__PURE__*/React.createElement("span", {
    className: "req"
  }, "*")), /*#__PURE__*/React.createElement("input", {
    value: name,
    placeholder: "Tower Renovation",
    autoFocus: true,
    onChange: e => {
      const v = e.target.value;
      setName(v);
      if (!code || code === autoCode(name)) setCode(autoCode(v));
    }
  })), /*#__PURE__*/React.createElement("label", {
    className: "ob-field"
  }, /*#__PURE__*/React.createElement("span", {
    className: "lbl"
  }, "Project code ", /*#__PURE__*/React.createElement("span", {
    className: "req"
  }, "*")), /*#__PURE__*/React.createElement("input", {
    className: "mono",
    value: code,
    placeholder: "W15",
    onChange: e => setCode(e.target.value.toUpperCase().slice(0, 14))
  }), /*#__PURE__*/React.createElement("span", {
    className: "hint"
  }, "A short identifier used on invoices and Excel exports \u2014 e.g. ", /*#__PURE__*/React.createElement("code", null, "W15"), ", ", /*#__PURE__*/React.createElement("code", null, "TOWER-04"), ".")), error && /*#__PURE__*/React.createElement("div", {
    className: "ob-error"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "error"), error), /*#__PURE__*/React.createElement("div", {
    className: "ob-actions"
  }, /*#__PURE__*/React.createElement("button", {
    className: "ob-btn ghost",
    onClick: onBack,
    disabled: loading
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "arrow_back"), "Back"), /*#__PURE__*/React.createElement("button", {
    className: "ob-btn primary",
    onClick: submit,
    disabled: loading
  }, loading ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined spin"
  }, "progress_activity"), "Creating\u2026") : /*#__PURE__*/React.createElement(React.Fragment, null, "Create project")))), /*#__PURE__*/React.createElement(RequiredFoot, {
    activeIndex: 1
  }));
}

/* Phase: project created confirmation → into the app. */
function ProjectDone({
  project,
  onEnter
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "ob-stage"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ob-brand"
  }, /*#__PURE__*/React.createElement("div", {
    className: "wordmark"
  }, "ConstraAP"), /*#__PURE__*/React.createElement("p", null, "Operational Finance")), /*#__PURE__*/React.createElement("div", {
    className: "ob-card obfade"
  }, /*#__PURE__*/React.createElement(StepDots, {
    activeIndex: 2
  }), /*#__PURE__*/React.createElement("div", {
    className: "ob-done"
  }, /*#__PURE__*/React.createElement("div", {
    className: "burst"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "task_alt")), /*#__PURE__*/React.createElement("h1", null, "Project created"), /*#__PURE__*/React.createElement("div", {
    className: "pill"
  }, /*#__PURE__*/React.createElement("span", {
    className: "code"
  }, project.code), /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--color-outline-variant)"
    }
  }, "\xB7"), /*#__PURE__*/React.createElement("span", null, project.name)), /*#__PURE__*/React.createElement("p", {
    className: "sub",
    style: {
      marginBottom: 22
    }
  }, "You're all set up. Next, upload your first invoice \u2014 and finish optional steps any time from the ", /*#__PURE__*/React.createElement("strong", {
    style: {
      color: "var(--color-on-surface)"
    }
  }, "Get started"), " checklist on your dashboard."), /*#__PURE__*/React.createElement("div", {
    className: "ob-actions"
  }, /*#__PURE__*/React.createElement("button", {
    className: "ob-btn primary",
    onClick: onEnter
  }, "Go to dashboard", /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "arrow_forward"))))), /*#__PURE__*/React.createElement(RequiredFoot, {
    activeIndex: 2
  }));
}
window.ProjectWizard = {
  OrgDone,
  ProjectForm,
  ProjectDone
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/ProjectWizard.jsx", error: String((e && e.message) || e) }); }

// onboarding/Sidebar.jsx
try { (() => {
/* ConstraAP — Sidebar (components/Sidebar.tsx) */
const {
  useState: useStateSB
} = React;
const PROJECT_NAV = [{
  key: "invoices",
  label: "Invoices",
  icon: "receipt_long"
}, {
  key: "emails",
  label: "Emails",
  icon: "mail"
}, {
  key: "contracts",
  label: "Contracts",
  icon: "contract"
}, {
  key: "vendors",
  label: "Vendors",
  icon: "business"
}, {
  key: "upload",
  label: "Upload",
  icon: "cloud_upload"
}];
const PROJECT_ADMIN = [{
  key: "files",
  label: "Project Files",
  icon: "folder_open"
}, {
  key: "ai",
  label: "AI Improvements",
  icon: "psychology"
}, {
  key: "users",
  label: "User Access & Roles",
  icon: "group"
}];
function Sidebar({
  current,
  selectedProject,
  onSelectProject,
  onNavigate
}) {
  const [projectsOpen, setProjectsOpen] = useStateSB(true);
  return /*#__PURE__*/React.createElement("nav", {
    className: "sidebar"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sb-brand"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sb-tile"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "account_balance")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", null, "ConstraAP"), /*#__PURE__*/React.createElement("p", null, "Operational Finance"))), /*#__PURE__*/React.createElement("div", {
    className: "sb-scroll"
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-item" + (current === "dashboard" ? " active" : ""),
    onClick: () => onNavigate("dashboard")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "dashboard"), "Dashboard"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8
    }
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-proj-toggle",
    onClick: () => setProjectsOpen(o => !o)
  }, /*#__PURE__*/React.createElement("span", {
    className: "lhs"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "folder"), selectedProject ? /*#__PURE__*/React.createElement("span", {
    className: "sel"
  }, selectedProject.code) : /*#__PURE__*/React.createElement("span", null, "Projects")), /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, projectsOpen ? "expand_less" : "expand_more")), projectsOpen && /*#__PURE__*/React.createElement("div", {
    className: "sb-sub",
    style: {
      borderLeftColor: "var(--color-outline-variant)"
    }
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-sub-item",
    onClick: () => onSelectProject(null),
    style: !selectedProject ? {
      color: "var(--color-primary)",
      fontWeight: 600
    } : null
  }, "All Projects"), window.PROJECTS.map(p => /*#__PURE__*/React.createElement("button", {
    key: p.id,
    className: "sb-sub-item",
    title: p.name,
    onClick: () => onSelectProject(p),
    style: selectedProject && selectedProject.id === p.id ? {
      color: "var(--color-primary)",
      fontWeight: 600
    } : null
  }, p.code, " \u2014 ", p.name))), selectedProject && /*#__PURE__*/React.createElement("div", {
    className: "sb-sub"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sb-sub-head",
    title: selectedProject.name
  }, selectedProject.name), PROJECT_NAV.map(item => /*#__PURE__*/React.createElement("button", {
    key: item.key,
    className: "sb-sub-item" + (current === item.key ? " active" : ""),
    onClick: () => onNavigate(item.key)
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, item.icon), item.label)), /*#__PURE__*/React.createElement("div", {
    className: "sb-sub-div"
  }), PROJECT_ADMIN.map(item => /*#__PURE__*/React.createElement("button", {
    key: item.key,
    className: "sb-sub-item" + (current === item.key ? " active" : ""),
    onClick: () => onNavigate(item.key)
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, item.icon), item.label)), /*#__PURE__*/React.createElement("button", {
    className: "sb-sub-item",
    onClick: () => onNavigate("project-settings")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "settings"), "Project Settings")))), /*#__PURE__*/React.createElement("div", {
    className: "sb-bottom"
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-item" + (current === "platform" ? " active" : ""),
    onClick: () => onNavigate("platform")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "admin_panel_settings"), "Platform Admin"), /*#__PURE__*/React.createElement("button", {
    className: "sb-item" + (current === "settings" ? " active" : ""),
    onClick: () => onNavigate("settings")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "settings"), "Settings"), /*#__PURE__*/React.createElement("a", {
    className: "sb-item",
    href: "mailto:support@constralabs.ai"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "contact_support"), "Support"), /*#__PURE__*/React.createElement("button", {
    className: "sb-item"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "logout"), "Sign Out")));
}
window.Sidebar = Sidebar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/Sidebar.jsx", error: String((e && e.message) || e) }); }

// onboarding/TopBar.jsx
try { (() => {
/* ConstraAP — TopBar (components/Shell.tsx) */
const {
  useState: useStateTB,
  useRef: useRefTB,
  useEffect: useEffectTB
} = React;
function TopBar({
  crumbs,
  userEmail
}) {
  const [open, setOpen] = useStateTB(false);
  const ref = useRefTB(null);
  useEffectTB(() => {
    const h = e => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener("mousedown", h);
    return () => document.removeEventListener("mousedown", h);
  }, []);
  const initial = userEmail ? userEmail[0].toUpperCase() : "U";
  return /*#__PURE__*/React.createElement("header", {
    className: "topbar"
  }, /*#__PURE__*/React.createElement("nav", {
    className: "crumbs"
  }, crumbs.map((c, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 4
    }
  }, i > 0 && /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "chevron_right"), /*#__PURE__*/React.createElement("span", {
    className: i === crumbs.length - 1 ? "last" : ""
  }, c)))), /*#__PURE__*/React.createElement("div", {
    className: "tb-right"
  }, /*#__PURE__*/React.createElement("button", {
    className: "tb-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "notifications")), /*#__PURE__*/React.createElement("button", {
    className: "tb-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "help_outline")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative"
    },
    ref: ref
  }, /*#__PURE__*/React.createElement("button", {
    className: "tb-avatar",
    onClick: () => setOpen(v => !v)
  }, initial), open && /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      right: 0,
      top: 40,
      width: 224,
      borderRadius: 12,
      border: "1px solid var(--color-outline-variant)",
      background: "var(--color-surface-container-lowest)",
      boxShadow: "var(--shadow-menu)",
      zIndex: 50,
      padding: "4px 0"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "12px 16px",
      borderBottom: "1px solid var(--color-outline-variant)"
    }
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 11,
      color: "var(--color-on-surface-variant)"
    }
  }, "Signed in as"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      fontWeight: 500,
      color: "var(--color-on-surface)"
    }
  }, userEmail)), /*#__PURE__*/React.createElement("button", {
    className: "sb-item",
    style: {
      padding: "10px 16px",
      borderRadius: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined",
    style: {
      fontSize: 18
    }
  }, "logout"), "Sign out")))));
}
window.TopBar = TopBar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/TopBar.jsx", error: String((e && e.message) || e) }); }

// onboarding/data.js
try { (() => {
/* ConstraAP — Onboarding prototype data (fake; cosmetic only).
   PROJECTS starts EMPTY: a brand-new org has no project yet. The wizard
   creates the first one; App assigns it to window.PROJECTS at that point. */
window.PROJECTS = [];

/* Invoices that "arrive" once the user completes the Upload step. They are
   re-pointed onto the freshly-created project id at runtime. */
window.SEED_INVOICES = [{
  id: "i1",
  vendor: "Northwind Electrical",
  number: "INV-20493",
  date: "2026-06-02",
  currency: "CAD",
  amount: 1250.00,
  cost_code: "26-050",
  status: "pending",
  approval: "submitted",
  isNew: true
}, {
  id: "i2",
  vendor: "Cascade Concrete",
  number: "CC-1182",
  date: "2026-06-01",
  currency: "CAD",
  amount: 23840.00,
  cost_code: "03-300",
  status: "processing",
  approval: "under_review"
}, {
  id: "i3",
  vendor: "Pacific Supply Co.",
  number: "PS-8841",
  date: "2026-05-30",
  currency: "CAD",
  amount: 9402.55,
  cost_code: "06-100",
  status: "reviewed",
  approval: "coordinator_review"
}];
window.money = n => n.toLocaleString("en-CA", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/data.js", error: String((e && e.message) || e) }); }

// onboarding/tweaks-panel.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)

/* BEGIN USAGE */
// tweaks-panel.jsx
// Reusable Tweaks shell + form-control helpers.
// Exports (to window): useTweaks, TweaksPanel, TweakSection, TweakRow, TweakSlider,
//   TweakToggle, TweakRadio, TweakSelect, TweakText, TweakNumber, TweakColor, TweakButton.
//
// Owns the host protocol (listens for __activate_edit_mode / __deactivate_edit_mode,
// posts __edit_mode_available / __edit_mode_set_keys / __edit_mode_dismissed) so
// individual prototypes don't re-roll it. Ships a consistent set of controls so you
// don't hand-draw <input type="range">, segmented radios, steppers, etc.
//
// Usage (in an HTML file that loads React + Babel):
//
//   const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
//     "primaryColor": "#D97757",
//     "palette": ["#D97757", "#29261b", "#f6f4ef"],
//     "fontSize": 16,
//     "density": "regular",
//     "dark": false
//   }/*EDITMODE-END*/;
//
//   function App() {
//     const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
//     return (
//       <div style={{ fontSize: t.fontSize, color: t.primaryColor }}>
//         Hello
//         <TweaksPanel>
//           <TweakSection label="Typography" />
//           <TweakSlider label="Font size" value={t.fontSize} min={10} max={32} unit="px"
//                        onChange={(v) => setTweak('fontSize', v)} />
//           <TweakRadio  label="Density" value={t.density}
//                        options={['compact', 'regular', 'comfy']}
//                        onChange={(v) => setTweak('density', v)} />
//           <TweakSection label="Theme" />
//           <TweakColor  label="Primary" value={t.primaryColor}
//                        options={['#D97757', '#2A6FDB', '#1F8A5B', '#7A5AE0']}
//                        onChange={(v) => setTweak('primaryColor', v)} />
//           <TweakColor  label="Palette" value={t.palette}
//                        options={[['#D97757', '#29261b', '#f6f4ef'],
//                                  ['#475569', '#0f172a', '#f1f5f9']]}
//                        onChange={(v) => setTweak('palette', v)} />
//           <TweakToggle label="Dark mode" value={t.dark}
//                        onChange={(v) => setTweak('dark', v)} />
//         </TweaksPanel>
//       </div>
//     );
//   }
//
// TweakRadio is the segmented control for 2–3 short options (auto-falls-back to
// TweakSelect past ~16/~10 chars per label); reach for TweakSelect directly when
// options are many or long. For color tweaks always curate 3-4 options rather than
// a free picker; an option can also be a whole 2–5 color palette (the stored value
// is the array). The Tweak* controls are a floor, not a ceiling — build custom
// controls inside the panel if a tweak calls for UI they don't cover.
/* END USAGE */
// ─────────────────────────────────────────────────────────────────────────────

const __TWEAKS_STYLE = `
  .twk-panel{position:fixed;right:16px;bottom:16px;z-index:2147483646;width:280px;
    max-height:calc(100vh - 32px);display:flex;flex-direction:column;
    transform:scale(var(--dc-inv-zoom,1));transform-origin:bottom right;
    background:rgba(250,249,247,.78);color:#29261b;
    -webkit-backdrop-filter:blur(24px) saturate(160%);backdrop-filter:blur(24px) saturate(160%);
    border:.5px solid rgba(255,255,255,.6);border-radius:14px;
    box-shadow:0 1px 0 rgba(255,255,255,.5) inset,0 12px 40px rgba(0,0,0,.18);
    font:11.5px/1.4 ui-sans-serif,system-ui,-apple-system,sans-serif;overflow:hidden}
  .twk-hd{display:flex;align-items:center;justify-content:space-between;
    padding:10px 8px 10px 14px;cursor:move;user-select:none}
  .twk-hd b{font-size:12px;font-weight:600;letter-spacing:.01em}
  .twk-x{appearance:none;border:0;background:transparent;color:rgba(41,38,27,.55);
    width:22px;height:22px;border-radius:6px;cursor:default;font-size:13px;line-height:1}
  .twk-x:hover{background:rgba(0,0,0,.06);color:#29261b}
  .twk-body{padding:2px 14px 14px;display:flex;flex-direction:column;gap:10px;
    overflow-y:auto;overflow-x:hidden;min-height:0;
    scrollbar-width:thin;scrollbar-color:rgba(0,0,0,.15) transparent}
  .twk-body::-webkit-scrollbar{width:8px}
  .twk-body::-webkit-scrollbar-track{background:transparent;margin:2px}
  .twk-body::-webkit-scrollbar-thumb{background:rgba(0,0,0,.15);border-radius:4px;
    border:2px solid transparent;background-clip:content-box}
  .twk-body::-webkit-scrollbar-thumb:hover{background:rgba(0,0,0,.25);
    border:2px solid transparent;background-clip:content-box}
  .twk-row{display:flex;flex-direction:column;gap:5px}
  .twk-row-h{flex-direction:row;align-items:center;justify-content:space-between;gap:10px}
  .twk-lbl{display:flex;justify-content:space-between;align-items:baseline;
    color:rgba(41,38,27,.72)}
  .twk-lbl>span:first-child{font-weight:500}
  .twk-val{color:rgba(41,38,27,.5);font-variant-numeric:tabular-nums}

  .twk-sect{font-size:10px;font-weight:600;letter-spacing:.06em;text-transform:uppercase;
    color:rgba(41,38,27,.45);padding:10px 0 0}
  .twk-sect:first-child{padding-top:0}

  .twk-field{appearance:none;box-sizing:border-box;width:100%;min-width:0;height:26px;padding:0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;
    background:rgba(255,255,255,.6);color:inherit;font:inherit;outline:none}
  .twk-field:focus{border-color:rgba(0,0,0,.25);background:rgba(255,255,255,.85)}
  select.twk-field{padding-right:22px;
    background-image:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='rgba(0,0,0,.5)' d='M0 0h10L5 6z'/></svg>");
    background-repeat:no-repeat;background-position:right 8px center}

  .twk-slider{appearance:none;-webkit-appearance:none;width:100%;height:4px;margin:6px 0;
    border-radius:999px;background:rgba(0,0,0,.12);outline:none}
  .twk-slider::-webkit-slider-thumb{-webkit-appearance:none;appearance:none;
    width:14px;height:14px;border-radius:50%;background:#fff;
    border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}
  .twk-slider::-moz-range-thumb{width:14px;height:14px;border-radius:50%;
    background:#fff;border:.5px solid rgba(0,0,0,.12);box-shadow:0 1px 3px rgba(0,0,0,.2);cursor:default}

  .twk-seg{position:relative;display:flex;padding:2px;border-radius:8px;
    background:rgba(0,0,0,.06);user-select:none}
  .twk-seg-thumb{position:absolute;top:2px;bottom:2px;border-radius:6px;
    background:rgba(255,255,255,.9);box-shadow:0 1px 2px rgba(0,0,0,.12);
    transition:left .15s cubic-bezier(.3,.7,.4,1),width .15s}
  .twk-seg.dragging .twk-seg-thumb{transition:none}
  .twk-seg button{appearance:none;position:relative;z-index:1;flex:1;border:0;
    background:transparent;color:inherit;font:inherit;font-weight:500;min-height:22px;
    border-radius:6px;cursor:default;padding:4px 6px;line-height:1.2;
    overflow-wrap:anywhere}

  .twk-toggle{position:relative;width:32px;height:18px;border:0;border-radius:999px;
    background:rgba(0,0,0,.15);transition:background .15s;cursor:default;padding:0}
  .twk-toggle[data-on="1"]{background:#34c759}
  .twk-toggle i{position:absolute;top:2px;left:2px;width:14px;height:14px;border-radius:50%;
    background:#fff;box-shadow:0 1px 2px rgba(0,0,0,.25);transition:transform .15s}
  .twk-toggle[data-on="1"] i{transform:translateX(14px)}

  .twk-num{display:flex;align-items:center;box-sizing:border-box;min-width:0;height:26px;padding:0 0 0 8px;
    border:.5px solid rgba(0,0,0,.1);border-radius:7px;background:rgba(255,255,255,.6)}
  .twk-num-lbl{font-weight:500;color:rgba(41,38,27,.6);cursor:ew-resize;
    user-select:none;padding-right:8px}
  .twk-num input{flex:1;min-width:0;height:100%;border:0;background:transparent;
    font:inherit;font-variant-numeric:tabular-nums;text-align:right;padding:0 8px 0 0;
    outline:none;color:inherit;-moz-appearance:textfield}
  .twk-num input::-webkit-inner-spin-button,.twk-num input::-webkit-outer-spin-button{
    -webkit-appearance:none;margin:0}
  .twk-num-unit{padding-right:8px;color:rgba(41,38,27,.45)}

  .twk-btn{appearance:none;height:26px;padding:0 12px;border:0;border-radius:7px;
    background:rgba(0,0,0,.78);color:#fff;font:inherit;font-weight:500;cursor:default}
  .twk-btn:hover{background:rgba(0,0,0,.88)}
  .twk-btn.secondary{background:rgba(0,0,0,.06);color:inherit}
  .twk-btn.secondary:hover{background:rgba(0,0,0,.1)}

  .twk-swatch{appearance:none;-webkit-appearance:none;width:56px;height:22px;
    border:.5px solid rgba(0,0,0,.1);border-radius:6px;padding:0;cursor:default;
    background:transparent;flex-shrink:0}
  .twk-swatch::-webkit-color-swatch-wrapper{padding:0}
  .twk-swatch::-webkit-color-swatch{border:0;border-radius:5.5px}
  .twk-swatch::-moz-color-swatch{border:0;border-radius:5.5px}

  .twk-chips{display:flex;gap:6px}
  .twk-chip{position:relative;appearance:none;flex:1;min-width:0;height:46px;
    padding:0;border:0;border-radius:6px;overflow:hidden;cursor:default;
    box-shadow:0 0 0 .5px rgba(0,0,0,.12),0 1px 2px rgba(0,0,0,.06);
    transition:transform .12s cubic-bezier(.3,.7,.4,1),box-shadow .12s}
  .twk-chip:hover{transform:translateY(-1px);
    box-shadow:0 0 0 .5px rgba(0,0,0,.18),0 4px 10px rgba(0,0,0,.12)}
  .twk-chip[data-on="1"]{box-shadow:0 0 0 1.5px rgba(0,0,0,.85),
    0 2px 6px rgba(0,0,0,.15)}
  .twk-chip>span{position:absolute;top:0;bottom:0;right:0;width:34%;
    display:flex;flex-direction:column;box-shadow:-1px 0 0 rgba(0,0,0,.1)}
  .twk-chip>span>i{flex:1;box-shadow:0 -1px 0 rgba(0,0,0,.1)}
  .twk-chip>span>i:first-child{box-shadow:none}
  .twk-chip svg{position:absolute;top:6px;left:6px;width:13px;height:13px;
    filter:drop-shadow(0 1px 1px rgba(0,0,0,.3))}
`;

// ── useTweaks ───────────────────────────────────────────────────────────────
// Single source of truth for tweak values. setTweak persists via the host
// (__edit_mode_set_keys → host rewrites the EDITMODE block on disk).
function useTweaks(defaults) {
  const [values, setValues] = React.useState(defaults);
  // Accepts either setTweak('key', value) or setTweak({ key: value, ... }) so a
  // useState-style call doesn't write a "[object Object]" key into the persisted
  // JSON block.
  const setTweak = React.useCallback((keyOrEdits, val) => {
    const edits = typeof keyOrEdits === 'object' && keyOrEdits !== null ? keyOrEdits : {
      [keyOrEdits]: val
    };
    setValues(prev => ({
      ...prev,
      ...edits
    }));
    window.parent.postMessage({
      type: '__edit_mode_set_keys',
      edits
    }, '*');
    // Same-window signal so in-page listeners (deck-stage rail thumbnails)
    // can react — the parent message only reaches the host, not peers.
    window.dispatchEvent(new CustomEvent('tweakchange', {
      detail: edits
    }));
  }, []);
  return [values, setTweak];
}

// ── TweaksPanel ─────────────────────────────────────────────────────────────
// Floating shell. Registers the protocol listener BEFORE announcing
// availability — if the announce ran first, the host's activate could land
// before our handler exists and the toolbar toggle would silently no-op.
// The close button posts __edit_mode_dismissed so the host's toolbar toggle
// flips off in lockstep; the host echoes __deactivate_edit_mode back which
// is what actually hides the panel.
function TweaksPanel({
  title = 'Tweaks',
  children
}) {
  const [open, setOpen] = React.useState(false);
  const dragRef = React.useRef(null);
  const offsetRef = React.useRef({
    x: 16,
    y: 16
  });
  const PAD = 16;
  const clampToViewport = React.useCallback(() => {
    const panel = dragRef.current;
    if (!panel) return;
    const w = panel.offsetWidth,
      h = panel.offsetHeight;
    const maxRight = Math.max(PAD, window.innerWidth - w - PAD);
    const maxBottom = Math.max(PAD, window.innerHeight - h - PAD);
    offsetRef.current = {
      x: Math.min(maxRight, Math.max(PAD, offsetRef.current.x)),
      y: Math.min(maxBottom, Math.max(PAD, offsetRef.current.y))
    };
    panel.style.right = offsetRef.current.x + 'px';
    panel.style.bottom = offsetRef.current.y + 'px';
  }, []);
  React.useEffect(() => {
    if (!open) return;
    clampToViewport();
    if (typeof ResizeObserver === 'undefined') {
      window.addEventListener('resize', clampToViewport);
      return () => window.removeEventListener('resize', clampToViewport);
    }
    const ro = new ResizeObserver(clampToViewport);
    ro.observe(document.documentElement);
    return () => ro.disconnect();
  }, [open, clampToViewport]);
  React.useEffect(() => {
    const onMsg = e => {
      const t = e?.data?.type;
      if (t === '__activate_edit_mode') setOpen(true);else if (t === '__deactivate_edit_mode') setOpen(false);
    };
    window.addEventListener('message', onMsg);
    window.parent.postMessage({
      type: '__edit_mode_available'
    }, '*');
    return () => window.removeEventListener('message', onMsg);
  }, []);
  const dismiss = () => {
    setOpen(false);
    window.parent.postMessage({
      type: '__edit_mode_dismissed'
    }, '*');
  };
  const onDragStart = e => {
    const panel = dragRef.current;
    if (!panel) return;
    const r = panel.getBoundingClientRect();
    const sx = e.clientX,
      sy = e.clientY;
    const startRight = window.innerWidth - r.right;
    const startBottom = window.innerHeight - r.bottom;
    const move = ev => {
      offsetRef.current = {
        x: startRight - (ev.clientX - sx),
        y: startBottom - (ev.clientY - sy)
      };
      clampToViewport();
    };
    const up = () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
  };
  if (!open) return null;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("style", null, __TWEAKS_STYLE), /*#__PURE__*/React.createElement("div", {
    ref: dragRef,
    className: "twk-panel",
    "data-omelette-chrome": "",
    style: {
      right: offsetRef.current.x,
      bottom: offsetRef.current.y
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-hd",
    onMouseDown: onDragStart
  }, /*#__PURE__*/React.createElement("b", null, title), /*#__PURE__*/React.createElement("button", {
    className: "twk-x",
    "aria-label": "Close tweaks",
    onMouseDown: e => e.stopPropagation(),
    onClick: dismiss
  }, "\u2715")), /*#__PURE__*/React.createElement("div", {
    className: "twk-body"
  }, children)));
}

// ── Layout helpers ──────────────────────────────────────────────────────────

function TweakSection({
  label,
  children
}) {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "twk-sect"
  }, label), children);
}
function TweakRow({
  label,
  value,
  children,
  inline = false
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: inline ? 'twk-row twk-row-h' : 'twk-row'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label), value != null && /*#__PURE__*/React.createElement("span", {
    className: "twk-val"
  }, value)), children);
}

// ── Controls ────────────────────────────────────────────────────────────────

function TweakSlider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  unit = '',
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label,
    value: `${value}${unit}`
  }, /*#__PURE__*/React.createElement("input", {
    type: "range",
    className: "twk-slider",
    min: min,
    max: max,
    step: step,
    value: value,
    onChange: e => onChange(Number(e.target.value))
  }));
}
function TweakToggle({
  label,
  value,
  onChange
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-row twk-row-h"
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-lbl"
  }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "twk-toggle",
    "data-on": value ? '1' : '0',
    role: "switch",
    "aria-checked": !!value,
    onClick: () => onChange(!value)
  }, /*#__PURE__*/React.createElement("i", null)));
}
function TweakRadio({
  label,
  value,
  options,
  onChange
}) {
  const trackRef = React.useRef(null);
  const [dragging, setDragging] = React.useState(false);
  // The active value is read by pointer-move handlers attached for the lifetime
  // of a drag — ref it so a stale closure doesn't fire onChange for every move.
  const valueRef = React.useRef(value);
  valueRef.current = value;

  // Segments wrap mid-word once per-segment width runs out. The track is
  // ~248px (280 panel − 28 body pad − 4 seg pad), each button loses 12px
  // to its own padding, and 11.5px system-ui averages ~6.3px/char — so 2
  // options fit ~16 chars each, 3 fit ~10. Past that (or >3 options), fall
  // back to a dropdown rather than wrap.
  const labelLen = o => String(typeof o === 'object' ? o.label : o).length;
  const maxLen = options.reduce((m, o) => Math.max(m, labelLen(o)), 0);
  const fitsAsSegments = maxLen <= ({
    2: 16,
    3: 10
  }[options.length] ?? 0);
  if (!fitsAsSegments) {
    // <select> emits strings — map back to the original option value so the
    // fallback stays type-preserving (numbers, booleans) like the segment path.
    const resolve = s => {
      const m = options.find(o => String(typeof o === 'object' ? o.value : o) === s);
      return m === undefined ? s : typeof m === 'object' ? m.value : m;
    };
    return /*#__PURE__*/React.createElement(TweakSelect, {
      label: label,
      value: value,
      options: options,
      onChange: s => onChange(resolve(s))
    });
  }
  const opts = options.map(o => typeof o === 'object' ? o : {
    value: o,
    label: o
  });
  const idx = Math.max(0, opts.findIndex(o => o.value === value));
  const n = opts.length;
  const segAt = clientX => {
    const r = trackRef.current.getBoundingClientRect();
    const inner = r.width - 4;
    const i = Math.floor((clientX - r.left - 2) / inner * n);
    return opts[Math.max(0, Math.min(n - 1, i))].value;
  };
  const onPointerDown = e => {
    setDragging(true);
    const v0 = segAt(e.clientX);
    if (v0 !== valueRef.current) onChange(v0);
    const move = ev => {
      if (!trackRef.current) return;
      const v = segAt(ev.clientX);
      if (v !== valueRef.current) onChange(v);
    };
    const up = () => {
      setDragging(false);
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    ref: trackRef,
    role: "radiogroup",
    onPointerDown: onPointerDown,
    className: dragging ? 'twk-seg dragging' : 'twk-seg'
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-seg-thumb",
    style: {
      left: `calc(2px + ${idx} * (100% - 4px) / ${n})`,
      width: `calc((100% - 4px) / ${n})`
    }
  }), opts.map(o => /*#__PURE__*/React.createElement("button", {
    key: o.value,
    type: "button",
    role: "radio",
    "aria-checked": o.value === value
  }, o.label))));
}
function TweakSelect({
  label,
  value,
  options,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("select", {
    className: "twk-field",
    value: value,
    onChange: e => onChange(e.target.value)
  }, options.map(o => {
    const v = typeof o === 'object' ? o.value : o;
    const l = typeof o === 'object' ? o.label : o;
    return /*#__PURE__*/React.createElement("option", {
      key: v,
      value: v
    }, l);
  })));
}
function TweakText({
  label,
  value,
  placeholder,
  onChange
}) {
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("input", {
    className: "twk-field",
    type: "text",
    value: value,
    placeholder: placeholder,
    onChange: e => onChange(e.target.value)
  }));
}
function TweakNumber({
  label,
  value,
  min,
  max,
  step = 1,
  unit = '',
  onChange
}) {
  const clamp = n => {
    if (min != null && n < min) return min;
    if (max != null && n > max) return max;
    return n;
  };
  const startRef = React.useRef({
    x: 0,
    val: 0
  });
  const onScrubStart = e => {
    e.preventDefault();
    startRef.current = {
      x: e.clientX,
      val: value
    };
    const decimals = (String(step).split('.')[1] || '').length;
    const move = ev => {
      const dx = ev.clientX - startRef.current.x;
      const raw = startRef.current.val + dx * step;
      const snapped = Math.round(raw / step) * step;
      onChange(clamp(Number(snapped.toFixed(decimals))));
    };
    const up = () => {
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "twk-num"
  }, /*#__PURE__*/React.createElement("span", {
    className: "twk-num-lbl",
    onPointerDown: onScrubStart
  }, label), /*#__PURE__*/React.createElement("input", {
    type: "number",
    value: value,
    min: min,
    max: max,
    step: step,
    onChange: e => onChange(clamp(Number(e.target.value)))
  }), unit && /*#__PURE__*/React.createElement("span", {
    className: "twk-num-unit"
  }, unit));
}

// Relative-luminance contrast pick — checkmarks drawn over a swatch need to
// read on both #111 and #fafafa without per-option configuration. Hex input
// only (#rgb / #rrggbb); named or rgb()/hsl() colors fall through to "light".
function __twkIsLight(hex) {
  const h = String(hex).replace('#', '');
  const x = h.length === 3 ? h.replace(/./g, c => c + c) : h.padEnd(6, '0');
  const n = parseInt(x.slice(0, 6), 16);
  if (Number.isNaN(n)) return true;
  const r = n >> 16 & 255,
    g = n >> 8 & 255,
    b = n & 255;
  return r * 299 + g * 587 + b * 114 > 148000;
}
const __TwkCheck = ({
  light
}) => /*#__PURE__*/React.createElement("svg", {
  viewBox: "0 0 14 14",
  "aria-hidden": "true"
}, /*#__PURE__*/React.createElement("path", {
  d: "M3 7.2 5.8 10 11 4.2",
  fill: "none",
  strokeWidth: "2.2",
  strokeLinecap: "round",
  strokeLinejoin: "round",
  stroke: light ? 'rgba(0,0,0,.78)' : '#fff'
}));

// TweakColor — curated color/palette picker. Each option is either a single
// hex string or an array of 1-5 hex strings; the card adapts — a lone color
// renders solid, a palette renders colors[0] as the hero (left ~2/3) with the
// rest stacked in a sharp column on the right. onChange emits the
// option in the shape it was passed (string stays string, array stays array).
// Without options it falls back to the native color input for back-compat.
function TweakColor({
  label,
  value,
  options,
  onChange
}) {
  if (!options || !options.length) {
    return /*#__PURE__*/React.createElement("div", {
      className: "twk-row twk-row-h"
    }, /*#__PURE__*/React.createElement("div", {
      className: "twk-lbl"
    }, /*#__PURE__*/React.createElement("span", null, label)), /*#__PURE__*/React.createElement("input", {
      type: "color",
      className: "twk-swatch",
      value: value,
      onChange: e => onChange(e.target.value)
    }));
  }
  // Native <input type=color> emits lowercase hex per the HTML spec, so
  // compare case-insensitively. String() guards JSON.stringify(undefined),
  // which returns the primitive undefined (no .toLowerCase).
  const key = o => String(JSON.stringify(o)).toLowerCase();
  const cur = key(value);
  return /*#__PURE__*/React.createElement(TweakRow, {
    label: label
  }, /*#__PURE__*/React.createElement("div", {
    className: "twk-chips",
    role: "radiogroup"
  }, options.map((o, i) => {
    const colors = Array.isArray(o) ? o : [o];
    const [hero, ...rest] = colors;
    const sup = rest.slice(0, 4);
    const on = key(o) === cur;
    return /*#__PURE__*/React.createElement("button", {
      key: i,
      type: "button",
      className: "twk-chip",
      role: "radio",
      "aria-checked": on,
      "data-on": on ? '1' : '0',
      "aria-label": colors.join(', '),
      title: colors.join(' · '),
      style: {
        background: hero
      },
      onClick: () => onChange(o)
    }, sup.length > 0 && /*#__PURE__*/React.createElement("span", null, sup.map((c, j) => /*#__PURE__*/React.createElement("i", {
      key: j,
      style: {
        background: c
      }
    }))), on && /*#__PURE__*/React.createElement(__TwkCheck, {
      light: __twkIsLight(hero)
    }));
  })));
}
function TweakButton({
  label,
  onClick,
  secondary = false
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: secondary ? 'twk-btn secondary' : 'twk-btn',
    onClick: onClick
  }, label);
}
Object.assign(window, {
  useTweaks,
  TweaksPanel,
  TweakSection,
  TweakRow,
  TweakSlider,
  TweakToggle,
  TweakRadio,
  TweakSelect,
  TweakText,
  TweakNumber,
  TweakColor,
  TweakButton
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "onboarding/tweaks-panel.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/App.jsx
try { (() => {
/* ConstraAP — App root (router + shell) */
const {
  useState: useStateApp
} = React;
const CRUMBS = {
  dashboard: ["Dashboard"],
  invoices: ["Invoices"],
  emails: ["Emails"],
  contracts: ["Contracts"],
  vendors: ["Vendors"],
  upload: ["Upload"],
  settings: ["Settings", "Projects"],
  platform: ["Platform Admin"],
  files: ["Settings", "Project Files"],
  ai: ["Settings", "AI Improvements"],
  users: ["Settings", "User Access & Roles"],
  "project-settings": ["Settings", "Project Settings"]
};
const PLACEHOLDER = {
  emails: {
    icon: "mail",
    title: "Emails",
    body: "Connected mailbox threads and invoice attachments appear here."
  },
  contracts: {
    icon: "contract",
    title: "Contracts",
    body: "Contracts and schedules of values for this project."
  },
  vendors: {
    icon: "business",
    title: "Vendors",
    body: "Vendor directory with linked invoices and totals."
  },
  upload: {
    icon: "cloud_upload",
    title: "Upload Invoice",
    body: "Drop a PDF or photo, or scan with your phone camera."
  },
  settings: {
    icon: "settings",
    title: "Projects",
    body: "Manage projects, cost codes, integrations, tax, and access."
  },
  platform: {
    icon: "admin_panel_settings",
    title: "Platform Admin",
    body: "Constralabs-internal: orgs, users, financing, and audit log."
  },
  files: {
    icon: "folder_open",
    title: "Project Files",
    body: "Archived source documents for this project."
  },
  ai: {
    icon: "psychology",
    title: "AI Improvements",
    body: "Learned values and extraction corrections over time."
  },
  users: {
    icon: "group",
    title: "User Access & Roles",
    body: "Project members, roles, and visible invoice statuses."
  },
  "project-settings": {
    icon: "settings",
    title: "Project Settings",
    body: "Cost codes, banks, extraction fields, and tax for this project."
  }
};
function Placeholder({
  view
}) {
  const p = PLACEHOLDER[view] || {
    icon: "construction",
    title: "Section",
    body: ""
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "stack"
  }, /*#__PURE__*/React.createElement("div", {
    className: "page-head"
  }, /*#__PURE__*/React.createElement("h1", null, p.title)), /*#__PURE__*/React.createElement("div", {
    className: "empty"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, p.icon), /*#__PURE__*/React.createElement("p", null, p.body), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 12,
      marginTop: 4,
      color: "var(--color-on-surface-variant)"
    }
  }, "Recreated for context \u2014 see the Dashboard, Invoices, and Invoice detail for full-fidelity screens.")));
}
function App() {
  const [view, setView] = useStateApp("dashboard");
  const [selectedProject, setSelectedProject] = useStateApp(window.PROJECTS[0]);
  const [openInvoice, setOpenInvoice] = useStateApp(null);
  const userEmail = "j.harper@constralabs.ai";
  if (openInvoice) {
    return /*#__PURE__*/React.createElement(window.InvoiceDetailView, {
      inv: openInvoice,
      onBack: () => setOpenInvoice(null)
    });
  }
  const navigate = v => {
    setView(v);
  };
  let content;
  if (view === "dashboard") {
    content = /*#__PURE__*/React.createElement(window.DashboardView, {
      selectedProject: selectedProject,
      onSelectProject: setSelectedProject,
      onOpenInvoice: setOpenInvoice,
      onNavigate: navigate
    });
  } else if (view === "invoices") {
    content = /*#__PURE__*/React.createElement(window.InvoicesView, {
      selectedProject: selectedProject,
      onOpenInvoice: setOpenInvoice
    });
  } else {
    content = /*#__PURE__*/React.createElement(Placeholder, {
      view: view
    });
  }
  return /*#__PURE__*/React.createElement("div", {
    className: "shell"
  }, /*#__PURE__*/React.createElement(window.Sidebar, {
    current: view,
    selectedProject: selectedProject,
    onSelectProject: setSelectedProject,
    onNavigate: navigate
  }), /*#__PURE__*/React.createElement("div", {
    className: "main-col"
  }, /*#__PURE__*/React.createElement(window.TopBar, {
    crumbs: CRUMBS[view] || ["Dashboard"],
    userEmail: userEmail
  }), /*#__PURE__*/React.createElement("main", {
    className: "content"
  }, content)));
}
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/Badges.jsx
try { (() => {
/* ConstraAP — shared badges & helpers */
const STATUS_COLORS = {
  pending: {
    background: "#fef3c7",
    color: "#92400e"
  },
  processing: {
    background: "#dbeafe",
    color: "#1e40af"
  },
  reviewed: {
    background: "#d1fae5",
    color: "#065f46"
  },
  exported: {
    background: "#f3f4f6",
    color: "#374151"
  },
  deleted: {
    background: "#fee2e2",
    color: "#991b1b"
  }
};
function StatusBadge({
  status
}) {
  const c = STATUS_COLORS[status] || STATUS_COLORS.exported;
  return /*#__PURE__*/React.createElement("span", {
    className: "badge",
    style: c
  }, status);
}
const APPROVAL_CONFIG = {
  submitted: {
    label: "Submitted",
    bg: "#dce2f3",
    fg: "#5e6572",
    bd: "var(--color-outline-variant)"
  },
  coordinator_review: {
    label: "Coordinator Review",
    bg: "#dce2f7",
    fg: "#141b2b",
    bd: "var(--color-outline-variant)"
  },
  under_review: {
    label: "Under Review",
    bg: "#eae7e9",
    fg: "#1b1b1d",
    bd: "var(--color-outline-variant)"
  },
  pm_approved: {
    label: "PM Approved",
    bg: "#f0edee",
    fg: "#1b1b1d",
    bd: "var(--color-outline-variant)"
  },
  final_approved: {
    label: "Final Approved",
    bg: "#dce2f7",
    fg: "#141b2b",
    bd: "var(--color-outline-variant)"
  },
  payment_issued: {
    label: "Paid",
    bg: "#f6f3f4",
    fg: "#45464c",
    bd: "var(--color-outline-variant)"
  },
  returned: {
    label: "Returned",
    bg: "#f9debf",
    fg: "#55442d",
    bd: "var(--color-outline-variant)"
  },
  rejected: {
    label: "Rejected",
    bg: "#ffdad6",
    fg: "#93000a",
    bd: "rgba(186,26,26,.2)"
  },
  deleted: {
    label: "Deleted",
    bg: "#ffdad6",
    fg: "#93000a",
    bd: "rgba(186,26,26,.2)"
  }
};
function ApprovalBadge({
  status
}) {
  const c = APPROVAL_CONFIG[status] || {
    label: status,
    bg: "#f0edee",
    fg: "#45464c",
    bd: "var(--color-outline-variant)"
  };
  return /*#__PURE__*/React.createElement("span", {
    className: "abadge",
    style: {
      background: c.bg,
      color: c.fg,
      borderColor: c.bd
    }
  }, c.label);
}
function CostCode({
  code
}) {
  return /*#__PURE__*/React.createElement("span", {
    className: "cost-code"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "tag"), code);
}
const money = n => n.toLocaleString("en-CA", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});
Object.assign(window, {
  StatusBadge,
  ApprovalBadge,
  CostCode,
  money,
  APPROVAL_CONFIG
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/Badges.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/DashboardView.jsx
try { (() => {
/* ConstraAP — Dashboard (pages/DashboardPage.tsx) */
function StatCard({
  label,
  value,
  icon,
  sub
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "stat"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ico"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, icon)), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "k"
  }, label), /*#__PURE__*/React.createElement("div", {
    className: "v"
  }, value), sub && /*#__PURE__*/React.createElement("div", {
    className: "sub"
  }, sub)));
}
function DashboardView({
  selectedProject,
  onSelectProject,
  onOpenInvoice,
  onNavigate
}) {
  const all = window.INVOICES;
  const invoices = selectedProject ? all.filter(i => i.project_id === selectedProject.id) : all;
  const reviewed = invoices.filter(i => i.status === "reviewed").length;
  const exported = invoices.filter(i => i.status === "exported").length;
  const action = invoices.filter(i => i.status === "pending" || i.approval === "submitted" || i.approval === "coordinator_review").length;
  const recent = invoices.slice(0, 5);
  return /*#__PURE__*/React.createElement("div", {
    className: "stack"
  }, /*#__PURE__*/React.createElement("div", {
    className: "page-head"
  }, /*#__PURE__*/React.createElement("h1", null, "Dashboard"), /*#__PURE__*/React.createElement("p", null, "Overview of your invoice processing pipeline.")), /*#__PURE__*/React.createElement("div", {
    className: "proj-row"
  }, /*#__PURE__*/React.createElement("span", {
    className: "lbl"
  }, "Project:"), /*#__PURE__*/React.createElement("button", {
    className: "chip" + (!selectedProject ? " on" : ""),
    onClick: () => onSelectProject(null)
  }, "All Projects"), window.PROJECTS.map(p => {
    const pa = all.filter(i => i.project_id === p.id && (i.status === "pending" || i.approval === "submitted" || i.approval === "coordinator_review")).length;
    return /*#__PURE__*/React.createElement("button", {
      key: p.id,
      className: "chip" + (selectedProject && selectedProject.id === p.id ? " on" : ""),
      onClick: () => onSelectProject(p)
    }, p.code, " \u2014 ", p.name, pa > 0 && /*#__PURE__*/React.createElement("span", {
      className: "badge-count"
    }, pa));
  })), /*#__PURE__*/React.createElement("div", {
    className: "row",
    style: {
      justifyContent: "flex-end"
    }
  }, /*#__PURE__*/React.createElement("button", {
    className: "btn btn-outline"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "sync"), "Poll Email"), /*#__PURE__*/React.createElement("button", {
    className: "btn btn-primary",
    onClick: () => onNavigate("upload")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "cloud_upload"), "Upload Invoice")), /*#__PURE__*/React.createElement("div", {
    className: "stat-grid"
  }, /*#__PURE__*/React.createElement(StatCard, {
    label: "Total Invoices",
    value: invoices.length,
    icon: "receipt_long"
  }), /*#__PURE__*/React.createElement(StatCard, {
    label: "Action Required",
    value: action,
    icon: "pending_actions",
    sub: "needs review"
  }), /*#__PURE__*/React.createElement(StatCard, {
    label: "Reviewed",
    value: reviewed,
    icon: "task_alt"
  }), /*#__PURE__*/React.createElement(StatCard, {
    label: "Exported",
    value: exported,
    icon: "cloud_done"
  })), /*#__PURE__*/React.createElement("div", {
    className: "stack-sm"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sec-head"
  }, /*#__PURE__*/React.createElement("h2", null, "Recent Invoices"), /*#__PURE__*/React.createElement("button", {
    className: "link-btn",
    onClick: () => onNavigate("invoices")
  }, "View all", /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "arrow_forward"))), /*#__PURE__*/React.createElement("div", {
    className: "card-table"
  }, /*#__PURE__*/React.createElement("table", null, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, /*#__PURE__*/React.createElement("th", null, "Vendor"), /*#__PURE__*/React.createElement("th", null, "Invoice #"), /*#__PURE__*/React.createElement("th", null, "Date"), /*#__PURE__*/React.createElement("th", null, "Amount"), /*#__PURE__*/React.createElement("th", null, "Status"))), /*#__PURE__*/React.createElement("tbody", null, recent.map(inv => /*#__PURE__*/React.createElement("tr", {
    key: inv.id,
    onClick: () => onOpenInvoice(inv)
  }, /*#__PURE__*/React.createElement("td", {
    className: "vendor"
  }, inv.vendor), /*#__PURE__*/React.createElement("td", {
    className: "muted-mono"
  }, inv.number), /*#__PURE__*/React.createElement("td", {
    className: "date"
  }, inv.date), /*#__PURE__*/React.createElement("td", {
    className: "amt"
  }, inv.currency, " ", window.money(inv.amount)), /*#__PURE__*/React.createElement("td", null, /*#__PURE__*/React.createElement(window.StatusBadge, {
    status: inv.status
  })))))))), /*#__PURE__*/React.createElement("div", {
    className: "stack-sm"
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      fontSize: 18,
      fontWeight: 600,
      letterSpacing: "-0.01em",
      color: "var(--color-primary)"
    }
  }, "Pipeline Logs"), /*#__PURE__*/React.createElement("div", {
    className: "logs"
  }, window.LOGS.map((log, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    className: "log-row " + log.level
  }, /*#__PURE__*/React.createElement("span", {
    className: "log-lvl " + log.level
  }, log.level), /*#__PURE__*/React.createElement("span", {
    className: "log-src"
  }, log.source), /*#__PURE__*/React.createElement("span", {
    className: "log-msg"
  }, log.message), /*#__PURE__*/React.createElement("span", {
    className: "log-time"
  }, log.time))))));
}
window.DashboardView = DashboardView;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/DashboardView.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/InvoiceDetailView.jsx
try { (() => {
/* ConstraAP — Invoice detail (pages/InvoiceDetailPage.tsx) */
const {
  useState: useStateDV
} = React;
const RAIL = [{
  icon: "dashboard",
  key: "dashboard"
}, {
  icon: "receipt_long",
  key: "invoices",
  active: true
}, {
  icon: "cloud_upload",
  key: "upload"
}, {
  icon: "settings",
  key: "settings"
}];
const WF_ORDER = ["submitted", "coordinator_review", "under_review", "pm_approved", "final_approved", "payment_issued"];
function InvoiceDoc({
  inv
}) {
  const items = window.LINE_ITEMS;
  const net = inv.amount / 1.05;
  const gst = inv.amount - net;
  return /*#__PURE__*/React.createElement("div", {
    className: "invoice-doc"
  }, /*#__PURE__*/React.createElement("div", {
    className: "idoc-top"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h3", null, inv.vendor), /*#__PURE__*/React.createElement("div", {
    className: "idoc-vendor-sub"
  }, "1450 Industrial Way", /*#__PURE__*/React.createElement("br", null), "Burnaby, BC V5A 3K2", /*#__PURE__*/React.createElement("br", null), "GST# 81923 4471 RT0001")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h2", null, "INVOICE"), /*#__PURE__*/React.createElement("div", {
    className: "idoc-meta"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, inv.number)), /*#__PURE__*/React.createElement("div", null, "Date: ", inv.date), /*#__PURE__*/React.createElement("div", null, "Terms: Net 30")))), /*#__PURE__*/React.createElement("table", {
    className: "idoc-table"
  }, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, /*#__PURE__*/React.createElement("th", null, "Description"), /*#__PURE__*/React.createElement("th", {
    className: "r"
  }, "Qty"), /*#__PURE__*/React.createElement("th", {
    className: "r"
  }, "Unit"), /*#__PURE__*/React.createElement("th", {
    className: "r"
  }, "Amount"))), /*#__PURE__*/React.createElement("tbody", null, items.map((it, i) => /*#__PURE__*/React.createElement("tr", {
    key: i
  }, /*#__PURE__*/React.createElement("td", null, it.desc), /*#__PURE__*/React.createElement("td", {
    className: "r num"
  }, it.qty), /*#__PURE__*/React.createElement("td", {
    className: "r num"
  }, window.money(it.price)), /*#__PURE__*/React.createElement("td", {
    className: "r num"
  }, window.money(it.qty * it.price)))))), /*#__PURE__*/React.createElement("div", {
    className: "idoc-totals"
  }, /*#__PURE__*/React.createElement("div", {
    className: "tr"
  }, /*#__PURE__*/React.createElement("span", null, "Subtotal"), /*#__PURE__*/React.createElement("span", {
    className: "num"
  }, window.money(net))), /*#__PURE__*/React.createElement("div", {
    className: "tr"
  }, /*#__PURE__*/React.createElement("span", null, "GST (5%)"), /*#__PURE__*/React.createElement("span", {
    className: "num"
  }, window.money(gst))), /*#__PURE__*/React.createElement("div", {
    className: "tr grand"
  }, /*#__PURE__*/React.createElement("span", null, "Total ", inv.currency), /*#__PURE__*/React.createElement("span", {
    className: "num"
  }, window.money(inv.amount)))));
}
function Field({
  k,
  v,
  mono,
  conf
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: "dfield"
  }, /*#__PURE__*/React.createElement("span", {
    className: "fk"
  }, k), /*#__PURE__*/React.createElement("span", {
    className: "fv" + (mono ? " mono" : "")
  }, v, conf && /*#__PURE__*/React.createElement("span", {
    className: "conf"
  }, conf)));
}
function ExtractedData({
  inv
}) {
  const net = inv.amount / 1.05;
  const gst = inv.amount - net;
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "callout match"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ch"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "contract"), "Contract Match"), /*#__PURE__*/React.createElement("p", null, "Linked contract ", inv.project_id === "p1" ? "TOWER-04-ELEC" : "—", " \xB7 94% confidence"), /*#__PURE__*/React.createElement("p", null, "Vendor and cost code align with the active schedule of values line.")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "sub-h"
  }, "Header"), /*#__PURE__*/React.createElement("div", {
    className: "dfields"
  }, /*#__PURE__*/React.createElement(Field, {
    k: "Vendor",
    v: inv.vendor,
    conf: "96%"
  }), /*#__PURE__*/React.createElement(Field, {
    k: "Invoice #",
    v: inv.number,
    mono: true
  }), /*#__PURE__*/React.createElement(Field, {
    k: "Invoice Date",
    v: inv.date,
    mono: true
  }), /*#__PURE__*/React.createElement(Field, {
    k: "Cost Code",
    v: inv.cost_code,
    mono: true,
    conf: "91%"
  }))), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "sub-h"
  }, "Amounts"), /*#__PURE__*/React.createElement("div", {
    className: "dfields"
  }, /*#__PURE__*/React.createElement(Field, {
    k: "Net Amount",
    v: inv.currency + " " + window.money(net),
    mono: true
  }), /*#__PURE__*/React.createElement(Field, {
    k: "GST (5%)",
    v: inv.currency + " " + window.money(gst),
    mono: true
  }), /*#__PURE__*/React.createElement(Field, {
    k: "Total",
    v: inv.currency + " " + window.money(inv.amount),
    mono: true
  }))));
}
function Workflow({
  inv
}) {
  const currentIdx = WF_ORDER.indexOf(inv.approval === "returned" || inv.approval === "rejected" ? "coordinator_review" : inv.approval);
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "wf-steps"
  }, WF_ORDER.map((step, i) => {
    const cfg = window.APPROVAL_CONFIG[step];
    const done = i < currentIdx;
    const current = i === currentIdx;
    return /*#__PURE__*/React.createElement("div", {
      key: step,
      className: "wf-step" + (done ? " done" : current ? " current" : "")
    }, /*#__PURE__*/React.createElement("div", {
      className: "wf-rail"
    }, /*#__PURE__*/React.createElement("div", {
      className: "wf-dot"
    }, /*#__PURE__*/React.createElement("span", {
      className: "material-symbols-outlined"
    }, done ? "check" : current ? "schedule" : "circle")), i < WF_ORDER.length - 1 && /*#__PURE__*/React.createElement("div", {
      className: "wf-line"
    })), /*#__PURE__*/React.createElement("div", {
      className: "wf-body"
    }, /*#__PURE__*/React.createElement("div", {
      className: "t"
    }, cfg.label), /*#__PURE__*/React.createElement("div", {
      className: "m"
    }, done ? "Completed" : current ? "In progress" : "Pending"), current && /*#__PURE__*/React.createElement("div", {
      className: "wf-actions"
    }, /*#__PURE__*/React.createElement("button", {
      className: "btn btn-primary",
      style: {
        padding: "6px 14px"
      }
    }, "Approve"), /*#__PURE__*/React.createElement("button", {
      className: "btn btn-outline",
      style: {
        padding: "6px 14px"
      }
    }, "Return"))));
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "sub-h",
    style: {
      marginBottom: 8
    }
  }, "Activity"), /*#__PURE__*/React.createElement("div", {
    className: "act-feed"
  }, window.ACTIVITY.map((a, i) => /*#__PURE__*/React.createElement("div", {
    className: "act-item",
    key: i
  }, /*#__PURE__*/React.createElement("div", {
    className: "act-av"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, a.who === "AI Extraction" ? "smart_toy" : a.who === "System" ? "settings" : "person")), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "baseline"
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "who"
  }, a.who), /*#__PURE__*/React.createElement("span", {
    className: "t"
  }, a.time)), /*#__PURE__*/React.createElement("div", {
    className: "what"
  }, a.action)))))));
}
function InvoiceDetailView({
  inv,
  onBack
}) {
  const [tab, setTab] = useStateDV("data");
  const [zoom, setZoom] = useStateDV(100);
  return /*#__PURE__*/React.createElement("div", {
    className: "detail"
  }, /*#__PURE__*/React.createElement("nav", {
    className: "drail"
  }, /*#__PURE__*/React.createElement("div", {
    className: "drail-logo"
  }, /*#__PURE__*/React.createElement("div", {
    className: "tile"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "account_balance"))), /*#__PURE__*/React.createElement("ul", null, RAIL.map(r => /*#__PURE__*/React.createElement("li", {
    key: r.key
  }, /*#__PURE__*/React.createElement("button", {
    className: "drail-item" + (r.active ? " active" : ""),
    onClick: onBack
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, r.icon))))), /*#__PURE__*/React.createElement("ul", {
    className: "bottom"
  }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("a", {
    className: "drail-item",
    href: "mailto:support@constralabs.ai"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "contact_support"))), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("button", {
    className: "drail-item"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "logout"))))), /*#__PURE__*/React.createElement("div", {
    className: "dmain"
  }, /*#__PURE__*/React.createElement("header", {
    className: "dtop"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dtop-left"
  }, /*#__PURE__*/React.createElement("button", {
    className: "dback",
    onClick: onBack
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "arrow_back"), "Invoices"), /*#__PURE__*/React.createElement("span", {
    className: "dsep"
  }, "/"), /*#__PURE__*/React.createElement("span", {
    className: "dtitle"
  }, inv.vendor, " \xB7 ", inv.number)), /*#__PURE__*/React.createElement("div", {
    className: "dtop-right"
  }, /*#__PURE__*/React.createElement("button", {
    className: "tb-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "notifications")), /*#__PURE__*/React.createElement("button", {
    className: "tb-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "help_outline")), /*#__PURE__*/React.createElement("span", {
    className: "vsep"
  }), /*#__PURE__*/React.createElement("span", {
    className: "av"
  }, "J"))), /*#__PURE__*/React.createElement("main", {
    className: "dcanvas"
  }, /*#__PURE__*/React.createElement("section", {
    className: "dpanel"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dpanel-bar"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ttl"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "description"), inv.number, ".pdf"), /*#__PURE__*/React.createElement("div", {
    className: "dtools"
  }, /*#__PURE__*/React.createElement("button", {
    className: "dtool-btn",
    onClick: () => setZoom(z => Math.max(50, z - 10))
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "zoom_out")), /*#__PURE__*/React.createElement("span", {
    className: "dzoom"
  }, zoom, "%"), /*#__PURE__*/React.createElement("button", {
    className: "dtool-btn",
    onClick: () => setZoom(z => Math.min(150, z + 10))
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "zoom_in")))), /*#__PURE__*/React.createElement("div", {
    className: "ddoc"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      transform: "scale(" + zoom / 100 + ")",
      transformOrigin: "top center"
    }
  }, /*#__PURE__*/React.createElement(InvoiceDoc, {
    inv: inv
  })))), /*#__PURE__*/React.createElement("aside", {
    className: "dpanel"
  }, /*#__PURE__*/React.createElement("div", {
    className: "dpanel-head"
  }, /*#__PURE__*/React.createElement("div", {
    className: "top"
  }, /*#__PURE__*/React.createElement("h2", null, "Invoice Details"), /*#__PURE__*/React.createElement(window.StatusBadge, {
    status: inv.status
  })), /*#__PURE__*/React.createElement("div", {
    className: "dtabs"
  }, /*#__PURE__*/React.createElement("button", {
    className: "dtab" + (tab === "data" ? " active" : ""),
    onClick: () => setTab("data")
  }, "Extracted Data"), /*#__PURE__*/React.createElement("button", {
    className: "dtab" + (tab === "workflow" ? " active" : ""),
    onClick: () => setTab("workflow")
  }, "Workflow"))), /*#__PURE__*/React.createElement("div", {
    className: "dscroll"
  }, tab === "data" ? /*#__PURE__*/React.createElement(ExtractedData, {
    inv: inv
  }) : /*#__PURE__*/React.createElement(Workflow, {
    inv: inv
  }))))));
}
window.InvoiceDetailView = InvoiceDetailView;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/InvoiceDetailView.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/InvoicesView.jsx
try { (() => {
/* ConstraAP — Invoices (pages/InvoicesPage.tsx) */
const {
  useState: useStateIV
} = React;
function InvoicesView({
  selectedProject,
  onOpenInvoice
}) {
  const [search, setSearch] = useStateIV("");
  const [statusFilter, setStatusFilter] = useStateIV("all");
  const [approvalFilter, setApprovalFilter] = useStateIV("all");
  const [showAll, setShowAll] = useStateIV(true);
  const base = selectedProject ? window.INVOICES.filter(i => i.project_id === selectedProject.id) : window.INVOICES;
  const filtered = base.filter(inv => {
    if (statusFilter !== "all" && inv.status !== statusFilter) return false;
    if (approvalFilter !== "all" && inv.approval !== approvalFilter) return false;
    if (search) {
      const q = search.toLowerCase();
      return inv.vendor.toLowerCase().includes(q) || inv.number.toLowerCase().includes(q) || inv.cost_code.toLowerCase().includes(q);
    }
    return true;
  });
  const processing = base.some(i => i.status === "processing");
  return /*#__PURE__*/React.createElement("div", {
    className: "stack"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sec-head",
    style: {
      alignItems: "flex-start"
    }
  }, /*#__PURE__*/React.createElement("div", {
    className: "page-head"
  }, /*#__PURE__*/React.createElement("h1", null, "Invoices"), /*#__PURE__*/React.createElement("p", null, "Review extracted invoices, confirm coding, and export approved records.")), /*#__PURE__*/React.createElement("div", {
    className: "row"
  }, /*#__PURE__*/React.createElement("button", {
    className: "btn btn-outline"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "sync"), "Poll Email"), /*#__PURE__*/React.createElement("button", {
    className: "btn btn-primary"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "cloud_upload"), "Upload Invoice"))), /*#__PURE__*/React.createElement("div", {
    className: "filters"
  }, /*#__PURE__*/React.createElement("div", {
    className: "search"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "search"), /*#__PURE__*/React.createElement("input", {
    className: "field-input",
    value: search,
    onChange: e => setSearch(e.target.value),
    placeholder: "Search vendor, invoice #..."
  })), /*#__PURE__*/React.createElement("select", {
    className: "field-input",
    value: statusFilter,
    onChange: e => setStatusFilter(e.target.value)
  }, /*#__PURE__*/React.createElement("option", {
    value: "all"
  }, "All Statuses"), /*#__PURE__*/React.createElement("option", {
    value: "pending"
  }, "Pending"), /*#__PURE__*/React.createElement("option", {
    value: "processing"
  }, "Processing"), /*#__PURE__*/React.createElement("option", {
    value: "reviewed"
  }, "Reviewed"), /*#__PURE__*/React.createElement("option", {
    value: "exported"
  }, "Exported")), /*#__PURE__*/React.createElement("select", {
    className: "field-input",
    value: approvalFilter,
    onChange: e => setApprovalFilter(e.target.value)
  }, /*#__PURE__*/React.createElement("option", {
    value: "all"
  }, "All Approvals"), /*#__PURE__*/React.createElement("option", {
    value: "submitted"
  }, "Submitted"), /*#__PURE__*/React.createElement("option", {
    value: "coordinator_review"
  }, "Coordinator Review"), /*#__PURE__*/React.createElement("option", {
    value: "under_review"
  }, "Under Review"), /*#__PURE__*/React.createElement("option", {
    value: "pm_approved"
  }, "PM Approved"), /*#__PURE__*/React.createElement("option", {
    value: "final_approved"
  }, "Final Approved"), /*#__PURE__*/React.createElement("option", {
    value: "payment_issued"
  }, "Paid"), /*#__PURE__*/React.createElement("option", {
    value: "returned"
  }, "Returned")), /*#__PURE__*/React.createElement("button", {
    className: "toggle-btn" + (showAll ? " on" : ""),
    onClick: () => setShowAll(v => !v)
  }, showAll ? "All (org)" : "Role view")), processing && /*#__PURE__*/React.createElement("div", {
    className: "banner proc"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined spin"
  }, "progress_activity"), /*#__PURE__*/React.createElement("span", null, "Analysis queue: 1 processing (max 3)")), filtered.length === 0 ? /*#__PURE__*/React.createElement("div", {
    className: "empty"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "receipt_long"), /*#__PURE__*/React.createElement("p", null, "No invoices match your filters.")) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
    className: "card-table"
  }, /*#__PURE__*/React.createElement("table", null, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, /*#__PURE__*/React.createElement("th", null, "Vendor"), /*#__PURE__*/React.createElement("th", null, "Invoice #"), /*#__PURE__*/React.createElement("th", null, "Date"), /*#__PURE__*/React.createElement("th", null, "Amount"), /*#__PURE__*/React.createElement("th", null, "Cost Code"), /*#__PURE__*/React.createElement("th", null, "Status"), /*#__PURE__*/React.createElement("th", null, "Approval"), /*#__PURE__*/React.createElement("th", {
    className: "right"
  }, "Actions"))), /*#__PURE__*/React.createElement("tbody", null, filtered.map(inv => /*#__PURE__*/React.createElement("tr", {
    key: inv.id,
    className: inv.isNew ? "hl" : "",
    onClick: () => inv.status !== "processing" && onOpenInvoice(inv),
    style: inv.status === "processing" ? {
      cursor: "not-allowed",
      opacity: 0.7
    } : null
  }, /*#__PURE__*/React.createElement("td", {
    className: "vendor" + (inv.isNew ? " hl-first" : "")
  }, /*#__PURE__*/React.createElement("span", {
    className: "vlink"
  }, inv.vendor), inv.isNew && /*#__PURE__*/React.createElement("span", {
    className: "tag-new"
  }, "New")), /*#__PURE__*/React.createElement("td", {
    className: "muted-mono"
  }, inv.number), /*#__PURE__*/React.createElement("td", {
    className: "date"
  }, inv.date), /*#__PURE__*/React.createElement("td", {
    className: "amt"
  }, inv.currency, " ", window.money(inv.amount)), /*#__PURE__*/React.createElement("td", null, /*#__PURE__*/React.createElement(window.CostCode, {
    code: inv.cost_code
  })), /*#__PURE__*/React.createElement("td", null, inv.status === "processing" ? /*#__PURE__*/React.createElement("span", {
    className: "qchip analyzing"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pulse-dot"
  }), "Analyzing") : /*#__PURE__*/React.createElement(window.StatusBadge, {
    status: inv.status
  })), /*#__PURE__*/React.createElement("td", null, /*#__PURE__*/React.createElement(window.ApprovalBadge, {
    status: inv.approval
  })), /*#__PURE__*/React.createElement("td", {
    className: "right",
    onClick: e => e.stopPropagation()
  }, /*#__PURE__*/React.createElement("span", {
    className: "row-actions"
  }, /*#__PURE__*/React.createElement("button", {
    className: "del",
    title: "Delete invoice"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "delete")), /*#__PURE__*/React.createElement("button", {
    title: "Open"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "open_in_new"))))))))), /*#__PURE__*/React.createElement("p", {
    className: "tablewrap-foot"
  }, "Showing ", filtered.length, " of ", base.length, " invoices")));
}
window.InvoicesView = InvoicesView;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/InvoicesView.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/Sidebar.jsx
try { (() => {
/* ConstraAP — Sidebar (components/Sidebar.tsx) */
const {
  useState: useStateSB
} = React;
const PROJECT_NAV = [{
  key: "invoices",
  label: "Invoices",
  icon: "receipt_long"
}, {
  key: "emails",
  label: "Emails",
  icon: "mail"
}, {
  key: "contracts",
  label: "Contracts",
  icon: "contract"
}, {
  key: "vendors",
  label: "Vendors",
  icon: "business"
}, {
  key: "upload",
  label: "Upload",
  icon: "cloud_upload"
}];
const PROJECT_ADMIN = [{
  key: "files",
  label: "Project Files",
  icon: "folder_open"
}, {
  key: "ai",
  label: "AI Improvements",
  icon: "psychology"
}, {
  key: "users",
  label: "User Access & Roles",
  icon: "group"
}];
function Sidebar({
  current,
  selectedProject,
  onSelectProject,
  onNavigate
}) {
  const [projectsOpen, setProjectsOpen] = useStateSB(true);
  return /*#__PURE__*/React.createElement("nav", {
    className: "sidebar"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sb-brand"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sb-tile"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "account_balance")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", null, "ConstraAP"), /*#__PURE__*/React.createElement("p", null, "Operational Finance"))), /*#__PURE__*/React.createElement("div", {
    className: "sb-scroll"
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-item" + (current === "dashboard" ? " active" : ""),
    onClick: () => onNavigate("dashboard")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "dashboard"), "Dashboard"), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8
    }
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-proj-toggle",
    onClick: () => setProjectsOpen(o => !o)
  }, /*#__PURE__*/React.createElement("span", {
    className: "lhs"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "folder"), selectedProject ? /*#__PURE__*/React.createElement("span", {
    className: "sel"
  }, selectedProject.code) : /*#__PURE__*/React.createElement("span", null, "Projects")), /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, projectsOpen ? "expand_less" : "expand_more")), projectsOpen && /*#__PURE__*/React.createElement("div", {
    className: "sb-sub",
    style: {
      borderLeftColor: "var(--color-outline-variant)"
    }
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-sub-item",
    onClick: () => onSelectProject(null),
    style: !selectedProject ? {
      color: "var(--color-primary)",
      fontWeight: 600
    } : null
  }, "All Projects"), window.PROJECTS.map(p => /*#__PURE__*/React.createElement("button", {
    key: p.id,
    className: "sb-sub-item",
    title: p.name,
    onClick: () => onSelectProject(p),
    style: selectedProject && selectedProject.id === p.id ? {
      color: "var(--color-primary)",
      fontWeight: 600
    } : null
  }, p.code, " \u2014 ", p.name))), selectedProject && /*#__PURE__*/React.createElement("div", {
    className: "sb-sub"
  }, /*#__PURE__*/React.createElement("div", {
    className: "sb-sub-head",
    title: selectedProject.name
  }, selectedProject.name), PROJECT_NAV.map(item => /*#__PURE__*/React.createElement("button", {
    key: item.key,
    className: "sb-sub-item" + (current === item.key ? " active" : ""),
    onClick: () => onNavigate(item.key)
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, item.icon), item.label)), /*#__PURE__*/React.createElement("div", {
    className: "sb-sub-div"
  }), PROJECT_ADMIN.map(item => /*#__PURE__*/React.createElement("button", {
    key: item.key,
    className: "sb-sub-item" + (current === item.key ? " active" : ""),
    onClick: () => onNavigate(item.key)
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, item.icon), item.label)), /*#__PURE__*/React.createElement("button", {
    className: "sb-sub-item",
    onClick: () => onNavigate("project-settings")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "settings"), "Project Settings")))), /*#__PURE__*/React.createElement("div", {
    className: "sb-bottom"
  }, /*#__PURE__*/React.createElement("button", {
    className: "sb-item" + (current === "platform" ? " active" : ""),
    onClick: () => onNavigate("platform")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "admin_panel_settings"), "Platform Admin"), /*#__PURE__*/React.createElement("button", {
    className: "sb-item" + (current === "settings" ? " active" : ""),
    onClick: () => onNavigate("settings")
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "settings"), "Settings"), /*#__PURE__*/React.createElement("a", {
    className: "sb-item",
    href: "mailto:support@constralabs.ai"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "contact_support"), "Support"), /*#__PURE__*/React.createElement("button", {
    className: "sb-item"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "logout"), "Sign Out")));
}
window.Sidebar = Sidebar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/Sidebar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/TopBar.jsx
try { (() => {
/* ConstraAP — TopBar (components/Shell.tsx) */
const {
  useState: useStateTB,
  useRef: useRefTB,
  useEffect: useEffectTB
} = React;
function TopBar({
  crumbs,
  userEmail
}) {
  const [open, setOpen] = useStateTB(false);
  const ref = useRefTB(null);
  useEffectTB(() => {
    const h = e => {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener("mousedown", h);
    return () => document.removeEventListener("mousedown", h);
  }, []);
  const initial = userEmail ? userEmail[0].toUpperCase() : "U";
  return /*#__PURE__*/React.createElement("header", {
    className: "topbar"
  }, /*#__PURE__*/React.createElement("nav", {
    className: "crumbs"
  }, crumbs.map((c, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 4
    }
  }, i > 0 && /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "chevron_right"), /*#__PURE__*/React.createElement("span", {
    className: i === crumbs.length - 1 ? "last" : ""
  }, c)))), /*#__PURE__*/React.createElement("div", {
    className: "tb-right"
  }, /*#__PURE__*/React.createElement("button", {
    className: "tb-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "notifications")), /*#__PURE__*/React.createElement("button", {
    className: "tb-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "help_outline")), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative"
    },
    ref: ref
  }, /*#__PURE__*/React.createElement("button", {
    className: "tb-avatar",
    onClick: () => setOpen(v => !v)
  }, initial), open && /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      right: 0,
      top: 40,
      width: 224,
      borderRadius: 12,
      border: "1px solid var(--color-outline-variant)",
      background: "var(--color-surface-container-lowest)",
      boxShadow: "var(--shadow-menu)",
      zIndex: 50,
      padding: "4px 0"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "12px 16px",
      borderBottom: "1px solid var(--color-outline-variant)"
    }
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 11,
      color: "var(--color-on-surface-variant)"
    }
  }, "Signed in as"), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      fontWeight: 500,
      color: "var(--color-on-surface)"
    }
  }, userEmail)), /*#__PURE__*/React.createElement("button", {
    className: "sb-item",
    style: {
      padding: "10px 16px",
      borderRadius: 0
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined",
    style: {
      fontSize: 18
    }
  }, "logout"), "Sign out")))));
}
window.TopBar = TopBar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/TopBar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/data.js
try { (() => {
/* ConstraAP — App kit demo data (fake; cosmetic only) */
window.PROJECTS = [{
  id: "p1",
  code: "TOWER-04",
  name: "Riverside Tower"
}, {
  id: "p2",
  code: "DEPOT-12",
  name: "Westgate Depot"
}, {
  id: "p3",
  code: "CIVIC-07",
  name: "Civic Center Reno"
}];
window.INVOICES = [{
  id: "i1",
  project_id: "p1",
  vendor: "Northwind Electrical",
  number: "INV-20493",
  date: "2026-05-28",
  currency: "CAD",
  amount: 1250.00,
  cost_code: "26-050",
  status: "pending",
  approval: "submitted",
  isNew: true
}, {
  id: "i2",
  project_id: "p1",
  vendor: "Pacific Supply Co.",
  number: "PS-8841",
  date: "2026-05-27",
  currency: "CAD",
  amount: 9402.55,
  cost_code: "06-100",
  status: "reviewed",
  approval: "coordinator_review"
}, {
  id: "i3",
  project_id: "p1",
  vendor: "BC Hydro",
  number: "88213-A",
  date: "2026-05-26",
  currency: "CAD",
  amount: 418.07,
  cost_code: "26-010",
  status: "exported",
  approval: "payment_issued"
}, {
  id: "i4",
  project_id: "p2",
  vendor: "Cascade Concrete",
  number: "CC-1182",
  date: "2026-05-25",
  currency: "CAD",
  amount: 23840.00,
  cost_code: "03-300",
  status: "processing",
  approval: "under_review"
}, {
  id: "i5",
  project_id: "p2",
  vendor: "Summit Steel Ltd.",
  number: "SS-44120",
  date: "2026-05-24",
  currency: "CAD",
  amount: 51200.75,
  cost_code: "05-120",
  status: "reviewed",
  approval: "pm_approved"
}, {
  id: "i6",
  project_id: "p1",
  vendor: "Delta Plumbing",
  number: "DP-7731",
  date: "2026-05-23",
  currency: "CAD",
  amount: 3120.40,
  cost_code: "22-100",
  status: "reviewed",
  approval: "final_approved"
}, {
  id: "i7",
  project_id: "p3",
  vendor: "Apex Drywall",
  number: "AD-0091",
  date: "2026-05-22",
  currency: "CAD",
  amount: 7860.00,
  cost_code: "09-250",
  status: "pending",
  approval: "returned"
}, {
  id: "i8",
  project_id: "p2",
  vendor: "Granite Glass & Glazing",
  number: "GG-3340",
  date: "2026-05-21",
  currency: "CAD",
  amount: 14250.90,
  cost_code: "08-800",
  status: "exported",
  approval: "payment_issued"
}];

// Line items for the detail view document.
window.LINE_ITEMS = [{
  desc: "Branch circuit wiring — Level 4 east",
  qty: 1,
  unit: "lot",
  price: 640.00
}, {
  desc: "EMT conduit, 3/4\" (bundle)",
  qty: 12,
  unit: "ea",
  price: 18.50
}, {
  desc: "Panel labor — certified electrician",
  qty: 8,
  unit: "hr",
  price: 48.50
}];
window.ACTIVITY = [{
  who: "AI Extraction",
  action: "Extracted 7 fields · 96% confidence",
  time: "2:14 PM"
}, {
  who: "j.harper@constralabs.ai",
  action: "Confirmed cost code 26-050",
  time: "2:31 PM"
}, {
  who: "System",
  action: "Matched contract TOWER-04-ELEC",
  time: "2:31 PM"
}, {
  who: "m.ruiz@constralabs.ai",
  action: "Submitted for coordinator review",
  time: "3:02 PM"
}];
window.LOGS = [{
  level: "info",
  source: "email-poll",
  message: "Polled mailbox — 3 new messages, 2 invoices detected",
  time: "2:09 PM"
}, {
  level: "info",
  source: "extractor",
  message: "Northwind Electrical INV-20493 — extraction complete",
  time: "2:14 PM"
}, {
  level: "warning",
  source: "cost-code",
  message: "Apex Drywall AD-0091 — low confidence (0.61), flagged for review",
  time: "2:18 PM"
}, {
  level: "info",
  source: "sharepoint",
  message: "BC Hydro 88213-A — appended row 4471 to draw workbook",
  time: "2:22 PM"
}, {
  level: "error",
  source: "quickbooks",
  message: "Sync retry 1/3 — token expired, re-authenticating",
  time: "2:25 PM"
}];
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/data.js", error: String((e && e.message) || e) }); }

// ui_kits/marketing/LandingPage.jsx
try { (() => {
/* ConstraAP — Landing page (recreation of pages/LandingPage.tsx) */
const {
  useState: useStateLP
} = React;
const FEATURES = [{
  icon: "mark_email_unread",
  title: "Email Intake",
  desc: "Connects to your Microsoft 365 mailbox and picks up invoices automatically as they arrive."
}, {
  icon: "smart_toy",
  title: "AI Extraction",
  desc: "Gemini Vision reads every PDF and image — vendor, amount, date, line items — no templates needed."
}, {
  icon: "tag",
  title: "Cost Code Assignment",
  desc: "Classifies each invoice against your cost code list and flags low-confidence items for review."
}, {
  icon: "table",
  title: "SharePoint Export",
  desc: "Appends one row per invoice to your SharePoint Excel file — ready for draw submissions."
}, {
  icon: "receipt_long",
  title: "Invoice Dashboard",
  desc: "Review, override, and approve invoices from a single web interface — desktop and mobile."
}, {
  icon: "cloud_upload",
  title: "Direct Upload",
  desc: "Drop a PDF or photo directly into the app when an invoice arrives outside email."
}];
function LandingPage() {
  const [signInOpen, setSignInOpen] = useStateLP(false);
  return /*#__PURE__*/React.createElement("div", {
    className: "land"
  }, /*#__PURE__*/React.createElement("header", {
    className: "lhead"
  }, /*#__PURE__*/React.createElement("a", {
    className: "brand",
    href: "#"
  }, /*#__PURE__*/React.createElement("span", {
    className: "brand-tile"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "account_balance_wallet")), "ConstraAP"), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "btn-ghost",
    onClick: () => setSignInOpen(true)
  }, "Sign in")), /*#__PURE__*/React.createElement("section", {
    className: "hero"
  }, /*#__PURE__*/React.createElement("div", {
    className: "eyebrow-pill"
  }, /*#__PURE__*/React.createElement("span", {
    className: "dot"
  }), "Accounts Payable Automation"), /*#__PURE__*/React.createElement("h1", null, "Stop entering invoices", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
    className: "muted"
  }, "manually.")), /*#__PURE__*/React.createElement("p", null, "ConstraAP reads your Outlook inbox, extracts invoice data using AI, assigns cost codes, and writes everything to SharePoint \u2014 without anyone touching a keyboard."), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "btn-cta",
    onClick: () => setSignInOpen(true)
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "login"), "Sign in to ConstraAP")), /*#__PURE__*/React.createElement("section", {
    className: "features"
  }, /*#__PURE__*/React.createElement("div", {
    className: "features-inner"
  }, /*#__PURE__*/React.createElement("p", {
    className: "features-eyebrow"
  }, "What it does"), /*#__PURE__*/React.createElement("div", {
    className: "fgrid"
  }, FEATURES.map(f => /*#__PURE__*/React.createElement("div", {
    key: f.title,
    className: "fcell"
  }, /*#__PURE__*/React.createElement("div", {
    className: "ico"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, f.icon)), /*#__PURE__*/React.createElement("h3", null, f.title), /*#__PURE__*/React.createElement("p", null, f.desc)))))), /*#__PURE__*/React.createElement("footer", {
    className: "lfoot"
  }, /*#__PURE__*/React.createElement("span", null, "\xA9 2026 Constralabs \u2014 ConstraAP"), /*#__PURE__*/React.createElement("nav", null, /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Terms of Service"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Privacy Policy"), /*#__PURE__*/React.createElement("span", null, "ap.constralabs.ai"))), /*#__PURE__*/React.createElement(LoginModal, {
    open: signInOpen,
    onClose: () => setSignInOpen(false)
  }));
}
window.LandingPage = LandingPage;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/marketing/LandingPage.jsx", error: String((e && e.message) || e) }); }

// ui_kits/marketing/LoginModal.jsx
try { (() => {
/* ConstraAP — Login modal (recreation of components/LoginModal.tsx) */
const {
  useState,
  useEffect
} = React;
function MicrosoftIcon() {
  return /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 21 21",
    style: {
      flexShrink: 0
    },
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "1",
    y: "1",
    width: "9",
    height: "9",
    fill: "#f25022"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "11",
    y: "1",
    width: "9",
    height: "9",
    fill: "#7fba00"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "1",
    y: "11",
    width: "9",
    height: "9",
    fill: "#00a4ef"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "11",
    y: "11",
    width: "9",
    height: "9",
    fill: "#ffb900"
  }));
}
function GoogleIcon() {
  return /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "16",
    viewBox: "0 0 18 18",
    style: {
      flexShrink: 0
    },
    "aria-hidden": "true"
  }, /*#__PURE__*/React.createElement("path", {
    fill: "#4285F4",
    d: "M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18z"
  }), /*#__PURE__*/React.createElement("path", {
    fill: "#34A853",
    d: "M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2a4.8 4.8 0 0 1-7.18-2.54H1.83v2.07A8 8 0 0 0 8.98 17z"
  }), /*#__PURE__*/React.createElement("path", {
    fill: "#FBBC05",
    d: "M4.5 10.52a4.8 4.8 0 0 1 0-3.04V5.41H1.83a8 8 0 0 0 0 7.18z"
  }), /*#__PURE__*/React.createElement("path", {
    fill: "#EA4335",
    d: "M8.98 4.18c1.17 0 2.23.4 3.06 1.2l2.3-2.3A8 8 0 0 0 1.83 5.4L4.5 7.49a4.77 4.77 0 0 1 4.48-3.3z"
  }));
}
function LoginModal({
  open,
  onClose
}) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  useEffect(() => {
    if (!open) return;
    const onKey = e => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, onClose]);
  if (!open) return null;
  const submit = e => {
    e.preventDefault();
    setLoading(true);
    // Demo only — simulate the sign-in spinner then close.
    setTimeout(() => {
      setLoading(false);
      onClose();
    }, 1100);
  };
  return /*#__PURE__*/React.createElement("div", {
    className: "modal-root",
    role: "presentation"
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Close sign in",
    className: "modal-backdrop",
    onClick: onClose
  }), /*#__PURE__*/React.createElement("div", {
    className: "modal-panel",
    role: "dialog",
    "aria-modal": "true",
    "aria-labelledby": "login-title"
  }, /*#__PURE__*/React.createElement("div", {
    className: "orb orb-a"
  }), /*#__PURE__*/React.createElement("div", {
    className: "orb orb-b"
  }), /*#__PURE__*/React.createElement("div", {
    className: "modal-head"
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "modal-close",
    onClick: onClose,
    "aria-label": "Close"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "close")), /*#__PURE__*/React.createElement("div", {
    className: "modal-icon"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "account_balance_wallet")), /*#__PURE__*/React.createElement("h2", {
    id: "login-title"
  }, "Welcome back"), /*#__PURE__*/React.createElement("p", null, "Sign in to your AP dashboard \u2014 email, password, or SSO.")), /*#__PURE__*/React.createElement("div", {
    className: "modal-body"
  }, /*#__PURE__*/React.createElement("form", {
    onSubmit: submit
  }, /*#__PURE__*/React.createElement("label", {
    className: "field",
    htmlFor: "login-email"
  }, /*#__PURE__*/React.createElement("span", null, "Email"), /*#__PURE__*/React.createElement("input", {
    id: "login-email",
    className: "input",
    type: "email",
    autoComplete: "email",
    required: true,
    value: email,
    onChange: e => setEmail(e.target.value),
    placeholder: "you@company.com"
  })), /*#__PURE__*/React.createElement("label", {
    className: "field",
    htmlFor: "login-password"
  }, /*#__PURE__*/React.createElement("span", null, "Password"), /*#__PURE__*/React.createElement("div", {
    className: "pwrap"
  }, /*#__PURE__*/React.createElement("input", {
    id: "login-password",
    className: "input",
    type: showPassword ? "text" : "password",
    required: true,
    value: password,
    onChange: e => setPassword(e.target.value),
    placeholder: "\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022"
  }), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "peye",
    onClick: () => setShowPassword(v => !v),
    "aria-label": showPassword ? "Hide password" : "Show password"
  }, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, showPassword ? "visibility_off" : "visibility")))), /*#__PURE__*/React.createElement("button", {
    type: "submit",
    className: "btn-submit",
    disabled: loading
  }, loading ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    className: "login-spinner"
  }), "Signing in\u2026") : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    className: "material-symbols-outlined"
  }, "login"), "Sign in"))), /*#__PURE__*/React.createElement("div", {
    className: "divider"
  }, /*#__PURE__*/React.createElement("span", {
    className: "line"
  }), /*#__PURE__*/React.createElement("span", {
    className: "or"
  }, "or"), /*#__PURE__*/React.createElement("span", {
    className: "line"
  })), /*#__PURE__*/React.createElement("div", {
    className: "sso"
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "btn-sso"
  }, /*#__PURE__*/React.createElement(MicrosoftIcon, null), "Sign in with Microsoft"), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "btn-sso"
  }, /*#__PURE__*/React.createElement(GoogleIcon, null), "Sign in with Google"))), /*#__PURE__*/React.createElement("div", {
    className: "modal-foot"
  }, /*#__PURE__*/React.createElement("p", null, "Protected workspace \xB7 \xA9 2026 Constralabs"))));
}
window.LoginModal = LoginModal;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/marketing/LoginModal.jsx", error: String((e && e.message) || e) }); }

})();
