// --- STATE MANAGEMENT ---
let state = {
  credits: []
};

// Dexie database: single key-value table to hold the whole state object,
// preserving the existing state.credits shape untouched (no schema redesign this round).
const db = new Dexie("KreditDB");
db.version(1).stores({
  kv: "key" // { key: "state", value: {...} }
});

// One-time, non-destructive migration from localStorage['kredit_state'] into Dexie.
// Does NOT delete/clear localStorage['kredit_state'] — it stays as a passive backup.
async function migrateFromLocalStorageIfNeeded() {
  const existing = await db.kv.get("state");
  if (existing) return; // Dexie already has data, nothing to migrate

  const migratedFlag = await db.kv.get("migrated_v1");
  if (migratedFlag) return; // migration already ran once (even if there was nothing to migrate)

  const savedState = localStorage.getItem("kredit_state");
  if (savedState) {
    try {
      const parsed = JSON.parse(savedState);
      await db.kv.put({ key: "state", value: parsed });
    } catch (e) {
      console.error("Error migrando el estado desde localStorage:", e);
    }
  }
  await db.kv.put({ key: "migrated_v1", value: true });
}

// Load State from Dexie (IndexedDB), migrating from legacy localStorage on first run
async function loadState() {
  await migrateFromLocalStorageIfNeeded();
  const savedRow = await db.kv.get("state");
  if (savedRow && savedRow.value) {
    try {
      state = savedRow.value;
      // Migrate older state formats if any
      if (!state.credits) state.credits = [];
    } catch (e) {
      console.error("Error cargando el estado:", e);
      state = { credits: [] };
    }
  } else {
    // Demo data for new users to see how it looks
    state = {
      credits: [
        {
          id: "demo-1",
          name: "Préstamo de Coche",
          lender: "Banco Santander",
          totalAmount: 12000,
          quotaAmount: 500,
          totalInstallments: 24,
          frequency: "monthly",
          startDate: getRelativeDateStr(-60), // Started 2 months ago
          interestRate: 4.5,
          color: "#ffffff",
          location: "Concesionario AutoMix",
          card: "Cuenta Débito Santander",
          notes: "Débito automático los 5 de cada mes. Cuenta corriente terminada en 4321.",
          installments: generateDemoInstallments(24, 500, "monthly", -60, 2) // 2 paid
        },
        {
          id: "demo-2",
          name: "Compra de Laptop",
          lender: "Tienda Tech",
          totalAmount: 1200,
          quotaAmount: 200,
          totalInstallments: 6,
          frequency: "biweekly",
          startDate: getRelativeDateStr(-28), // Started 4 weeks ago
          interestRate: 0,
          color: "#c084fc",
          location: "Tienda Tech Outlet",
          card: "Tarjeta Visa BBVA",
          notes: "Pago quincenal manual por transferencia.",
          installments: generateDemoInstallments(6, 200, "biweekly", -28, 2) // 2 paid
        }
      ]
    };
    saveState();
  }
  
  // Apply pending interest/fee accrual cycles for credit cards
  accrueAllCards();

  // Load profile name
  const username = localStorage.getItem("kredit_username") || "Mi Control";
  const userLabel = document.getElementById("user-profile-name");
  if (userLabel) userLabel.textContent = username;
  const pName = document.getElementById("profile-name-display");
  if (pName) pName.textContent = username;
  const sidebarName = document.getElementById("sidebar-profile-name");
  if (sidebarName) sidebarName.textContent = username;
}

// Save State to Dexie (IndexedDB) and refresh UI
async function saveState() {
  await db.kv.put({ key: "state", value: state });
  renderAll();
}

// --- HELPER DATE FUNCTIONS ---
function getRelativeDateStr(daysOffset) {
  const d = new Date();
  d.setDate(d.getDate() + daysOffset);
  return d.toISOString().split("T")[0];
}

function generateDemoInstallments(total, amount, frequency, startOffsetDays, paidCount) {
  const installments = [];
  const start = new Date();
  start.setDate(start.getDate() + startOffsetDays);

  for (let i = 1; i <= total; i++) {
    const due = new Date(start);
    if (frequency === "weekly") {
      due.setDate(start.getDate() + (i - 1) * 7);
    } else if (frequency === "biweekly") {
      due.setDate(start.getDate() + (i - 1) * 14);
    } else { // monthly
      due.setMonth(start.getMonth() + (i - 1));
    }
    
    installments.push({
      number: i,
      dueDate: due.toISOString().split("T")[0],
      amount: amount,
      paid: i <= paidCount,
      paymentDate: i <= paidCount ? getRelativeDateStr(startOffsetDays + (i - 1) * (frequency === 'monthly' ? 30 : frequency === 'biweekly' ? 14 : 7)) : null
    });
  }
  return installments;
}

function toDateStr(d) {
  return d.toISOString().split("T")[0];
}

// Format date into human readable Spanish format (e.g. "31 Jul, 2026")
function formatDate(dateStr) {
  if (!dateStr) return "N/A";
  const [year, month, day] = dateStr.split("-").map(Number);
  // Create date using local timezone parameters to prevent offset errors
  const date = new Date(year, month - 1, day);
  const months = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"];
  return `${day} ${months[date.getMonth()]}, ${year}`;
}

// Get number of days difference between today and target date
function getDaysDifference(dateStr) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const [year, month, day] = dateStr.split("-").map(Number);
  const targetDate = new Date(year, month - 1, day);
  targetDate.setHours(0, 0, 0, 0);
  
  const diffTime = targetDate - today;
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
}

// Get status badge class and label based on payment status and due date
function getInstallmentStatus(inst) {
  if (inst.paid) {
    return { class: "badge-paid", label: "Pagado", state: "paid" };
  }
  
  const daysDiff = getDaysDifference(inst.dueDate);
  if (daysDiff < 0) {
    return { class: "badge-overdue", label: `Vencido (${Math.abs(daysDiff)}d)`, state: "overdue" };
  } else if (daysDiff <= 3) {
    return { class: "badge-overdue", label: daysDiff === 0 ? "Hoy" : `En ${daysDiff}d`, state: "warning" };
  } else {
    return { class: "badge-pending", label: `En ${daysDiff}d`, state: "pending" };
  }
}

// --- NAVIGATION & ROUTING ---
let activeView = "dashboard";
let activeCreditFilter = "active";
let currentDetailCreditId = null;
let creditDetailOriginView = "credits";

function switchView(viewName) {
  activeView = viewName;
  
  // Reset dynamic colors if we navigate away from credit detail
  if (viewName !== "credit-detail") {
    const container = document.querySelector(".app-container");
    if (container) {
      container.style.removeProperty("--accent-primary");
      container.style.removeProperty("--dynamic-glow");
    }
  }
  
  // Update active view class
  document.querySelectorAll(".view").forEach((v) => v.classList.remove("active"));
  document.getElementById(`view-${viewName}`).classList.add("active");
  
  // Update active nav-item and sidebar-link class
  document.querySelectorAll(".nav-item").forEach((n) => n.classList.remove("active"));
  document.querySelectorAll(".sidebar-link").forEach((n) => n.classList.remove("active"));
  
  // Highlight nav tabs (except when viewing details, which isn't on bottom-nav directly)
  if (["dashboard", "credits", "settings"].includes(viewName)) {
    const navEl = document.getElementById(`nav-${viewName}`);
    if (navEl) navEl.classList.add("active");
    const sidebarNavEl = document.getElementById(`sidebar-${viewName}`);
    if (sidebarNavEl) sidebarNavEl.classList.add("active");
  } else if (viewName === "credit-detail") {
    const navEl = document.getElementById(`nav-credits`);
    if (navEl) navEl.classList.add("active");
    const sidebarNavEl = document.getElementById(`sidebar-credits`);
    if (sidebarNavEl) sidebarNavEl.classList.add("active");
  }
  
  // Render specific view data
  if (viewName === "dashboard") {
    renderDashboard();
  } else if (viewName === "credits") {
    renderCreditsList();
  } else if (viewName === "settings") {
    renderSettings();
  } else if (viewName === "credit-detail" && currentDetailCreditId) {
    renderCreditDetail(currentDetailCreditId);
  }
}

// --- MODALS HANDLING ---
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  modal.classList.add("active");
  
  // Set default start date to today in form
  if (modalId === "modal-add-credit") {
    document.getElementById("credit-start-date").value = new Date().toISOString().split("T")[0];
  }
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  modal.classList.remove("active");
}

function closeModalOnOuterClick(e) {
  if (e.target.classList.contains("modal")) {
    e.target.classList.remove("active");
  }
}

// --- TOAST NOTIFICATION SYSTEM ---
// Small inline icon set (feather-style, matches index.html SVG conventions) for toast messages.
const TOAST_ICON_CHECK = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>';
const TOAST_ICON_EDIT = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>';
const TOAST_ICON_TRASH = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>';
const TOAST_ICON_RECEIPT = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2h12a1 1 0 0 1 1 1v18l-3-2-2 2-2-2-2 2-2-2-3 2V3a1 1 0 0 1 1-1z"></path><line x1="9" y1="8" x2="15" y2="8"></line><line x1="9" y1="12" x2="15" y2="12"></line></svg>';
const TOAST_ICON_DOWNLOAD = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>';
const TOAST_ICON_WARNING = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>';
const TOAST_ICON_ERROR = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>';

function showToast(message, icon = TOAST_ICON_CHECK, duration = 3000) {
  const container = document.getElementById("toast-container");
  if (!container) return;
  const toast = document.createElement("div");
  toast.className = "toast";
  toast.innerHTML = `<span class="toast-icon">${icon}</span><span>${message}</span>`;
  container.appendChild(toast);
  // Trigger animation
  requestAnimationFrame(() => {
    requestAnimationFrame(() => toast.classList.add("show"));
  });
  setTimeout(() => {
    toast.classList.remove("show");
    toast.addEventListener("transitionend", () => toast.remove(), { once: true });
  }, duration);
}

// --- THEME PERSONALIZATION (accent color + background tone) ---
// User's chosen accent lives on :root so it survives switchView's cleanup of the
// per-credit dynamic accent (which is only ever set on .app-container).
function applyAccentTheme(color, persist = true) {
  document.documentElement.style.setProperty("--accent-primary", color);
  if (persist) localStorage.setItem("kredit_theme_accent", color);

  document.querySelectorAll("#theme-accent-picker .color-option").forEach((opt) => {
    opt.classList.toggle("selected", opt.getAttribute("data-color") === color);
  });
}

function setAccentTheme(e, color) {
  applyAccentTheme(color);
}

function applyBgTheme(themeName, persist = true) {
  if (themeName === "pure") {
    document.documentElement.removeAttribute("data-bg-theme");
  } else {
    document.documentElement.setAttribute("data-bg-theme", themeName);
  }
  if (persist) localStorage.setItem("kredit_theme_bg", themeName);

  document.querySelectorAll("#theme-bg-picker .type-toggle-btn").forEach((btn) => {
    btn.classList.toggle("active", btn.getAttribute("data-bg") === themeName);
  });
}

function setBgTheme(themeName) {
  applyBgTheme(themeName);
}

function loadThemePreferences() {
  const savedAccent = localStorage.getItem("kredit_theme_accent") || "#ffffff";
  applyAccentTheme(savedAccent, false);

  const savedBg = localStorage.getItem("kredit_theme_bg") || "pure";
  applyBgTheme(savedBg, false);
}

// --- CREDIT TYPE TOGGLE (Cupo/Préstamo vs Tarjeta de Crédito) ---
// Field visibility, required attributes, and label text are now handled declaratively by
// Alpine.js (x-show/:required/x-text bound to the form's `creditType` state — see
// index.html). This is a thin bridge so vanilla code (the post-save form reset) can still
// drive that Alpine state from the outside.
function setCreditType(type) {
  const formEl = document.getElementById("form-add-credit");
  Alpine.$data(formEl).creditType = type;
}

// Nequi is confirmed 100% fixed-installment consumer credit (tasa fija, cuotas fijas) —
// still true as of research, so we nudge firmly toward "Cupo/Préstamo". DaviPlata is no
// longer a single product: alongside its older fixed-installment Nanocrédito, it launched
// a genuine revolving credit card in 2025, so we can't assert which one the user has —
// the hint softens to acknowledge the ambiguity instead of asserting certainty. They may
// still want the card mockup for a linked debit/prepaid card either way.
function checkTypeSuggestion(typeOverride) {
  const type = typeOverride || document.getElementById("credit-type").value;
  const lender = document.getElementById("credit-lender").value.toLowerCase();
  const hint = document.getElementById("type-suggestion-hint");
  const hintText = document.getElementById("type-suggestion-hint-text");
  const isNequi = lender.includes("nequi");
  const isDaviplata = lender.includes("daviplata");
  const shouldSuggest = type === "card" && (isNequi || isDaviplata);
  if (shouldSuggest && hintText) {
    hintText.textContent = isNequi
      ? "Nequi no maneja tarjeta rotativa real: su crédito es de cuotas fijas. Te recomendamos registrarlo como Préstamo / Cuotas Fijas."
      : "DaviPlata tiene dos productos distintos: el Nanocrédito (cuotas fijas) y una tarjeta de crédito rotativa más nueva. Si tienes el Nanocrédito, es mejor registrarlo como Préstamo / Cuotas Fijas.";
  }
  hint.style.display = shouldSuggest ? "flex" : "none";
}

// --- FORM CALCULATIONS & ACTIONS ---
function selectColor(e) {
  // Only toggle within the add-credit color picker, not edit
  document.querySelectorAll("#form-add-credit .color-option").forEach((opt) => opt.classList.remove("selected"));
  e.target.classList.add("selected");
  document.getElementById("credit-color").value = e.target.getAttribute("data-color");
}

function selectEditColor(e) {
  document.querySelectorAll("#edit-color-picker .color-option").forEach((opt) => opt.classList.remove("selected"));
  e.target.classList.add("selected");
  document.getElementById("edit-credit-color").value = e.target.getAttribute("data-color");
}

function calcSuggestedQuota() {
  const amount = parseFloat(document.getElementById("credit-amount").value);
  const installments = parseInt(document.getElementById("credit-installments").value);
  const quotaInput = document.getElementById("credit-quota");
  
  if (!isNaN(amount) && !isNaN(installments) && installments > 0) {
    const suggested = (amount / installments).toFixed(2);
    quotaInput.placeholder = `Sugerido: $${suggested}`;
    // Fill it in if it's currently empty
    if (!quotaInput.value) {
      quotaInput.value = suggested;
    }
  }
}

// Builds the installments list for a "loan/cupo" credit, splitting each
// quota into principal + interest so early payments can waive interest
// (interest is only "causado" once the due date of that specific quota arrives).
function buildLoanInstallments(totalAmount, totalInstallments, quotaAmount, frequency, startDate) {
  const installments = [];
  const start = new Date(startDate + "T00:00:00"); // Prevent local timezone offset

  const totalInterest = Math.max(0, (quotaAmount * totalInstallments) - totalAmount);
  const interestPerInstallment = totalInstallments > 0 ? totalInterest / totalInstallments : 0;
  const principalPerInstallment = quotaAmount - interestPerInstallment;

  for (let i = 1; i <= totalInstallments; i++) {
    const due = new Date(start);
    if (frequency === "weekly") {
      due.setDate(start.getDate() + (i - 1) * 7);
    } else if (frequency === "biweekly") {
      due.setDate(start.getDate() + (i - 1) * 14);
    } else { // monthly
      due.setMonth(start.getMonth() + (i - 1));
    }

    installments.push({
      number: i,
      dueDate: due.toISOString().split("T")[0],
      amount: quotaAmount,
      principal: principalPerInstallment,
      interest: interestPerInstallment,
      paid: false,
      paymentDate: null,
      interestWaived: false
    });
  }
  return installments;
}

function saveCredit(e) {
  e.preventDefault();

  const type = document.getElementById("credit-type").value;
  const name = document.getElementById("credit-name").value.trim();
  const lender = document.getElementById("credit-lender").value.trim();
  const color = document.getElementById("credit-color").value;
  const notes = document.getElementById("credit-notes").value.trim();

  let newCredit;

  if (type === "card") {
    const creditLimit = parseFloat(document.getElementById("credit-card-limit").value) || 0;
    const currentBalance = parseFloat(document.getElementById("credit-card-balance").value) || 0;
    const cutoffDay = parseInt(document.getElementById("credit-cutoff-day").value) || 1;
    const paymentDueOffsetDays = parseInt(document.getElementById("credit-payment-offset").value) || 20;
    const interestInput = document.getElementById("credit-interest").value;
    const interestRate = interestInput ? parseFloat(interestInput) : 0;
    const managementFee = parseFloat(document.getElementById("credit-management-fee").value) || 0;
    const managementFeeFrequency = document.getElementById("credit-management-fee-freq").value;

    newCredit = {
      id: "credit_" + Date.now(),
      type: "card",
      name,
      lender,
      color,
      notes,
      creditLimit,
      currentBalance,
      cutoffDay,
      paymentDueOffsetDays,
      interestRate,
      managementFee,
      managementFeeFrequency,
      cycleCount: 0,
      lastAccrualCutoff: null,
      movements: currentBalance > 0
        ? [{ date: toDateStr(new Date()), type: "charge", amount: currentBalance, note: "Saldo inicial registrado" }]
        : []
    };
    accrueCardCredit(newCredit); // initializes lastAccrualCutoff without back-charging
  } else {
    const location = document.getElementById("credit-location").value.trim();
    const card = document.getElementById("credit-card").value.trim();
    const totalAmount = parseFloat(document.getElementById("credit-amount").value);
    const totalInstallments = parseInt(document.getElementById("credit-installments").value);
    const quotaAmount = parseFloat(document.getElementById("credit-quota").value);
    const interestInput = document.getElementById("credit-interest").value;
    const interestRate = interestInput ? parseFloat(interestInput) : 0;
    const frequency = document.getElementById("credit-frequency").value;
    const startDate = document.getElementById("credit-start-date").value;

    const installments = buildLoanInstallments(totalAmount, totalInstallments, quotaAmount, frequency, startDate);

    newCredit = {
      id: "credit_" + Date.now(),
      type: "loan",
      name,
      lender,
      location,
      card,
      totalAmount,
      quotaAmount,
      totalInstallments,
      frequency,
      startDate,
      interestRate,
      color,
      notes,
      installments
    };
  }

  state.credits.push(newCredit);
  saveState();

  // Reset form and close modal
  document.getElementById("form-add-credit").reset();
  setCreditType("loan");
  const addColorOptions = document.querySelectorAll("#form-add-credit .color-option");
  addColorOptions.forEach((opt, idx) => {
    if (idx === 0) {
      opt.classList.add("selected");
      document.getElementById("credit-color").value = opt.getAttribute("data-color");
    } else {
      opt.classList.remove("selected");
    }
  });
  closeModal("modal-add-credit");
  showToast(`"${name}" registrado con éxito`, TOAST_ICON_CHECK);

  // Switch to credits view to see the new addition
  switchView("credits");
}

// --- EDIT CREDIT ---
function openEditCreditModal() {
  const credit = state.credits.find(c => c.id === currentDetailCreditId);
  if (!credit) return;

  const type = credit.type || "loan";

  document.getElementById("edit-credit-id").value = credit.id;
  document.getElementById("edit-credit-name").value = credit.name;
  document.getElementById("edit-credit-lender").value = credit.lender;
  document.getElementById("edit-credit-notes").value = credit.notes || "";
  document.getElementById("edit-credit-color").value = credit.color || "#00f2fe";

  // Sync color picker
  const editOptions = document.querySelectorAll("#edit-color-picker .color-option");
  editOptions.forEach(opt => {
    opt.classList.toggle("selected", opt.getAttribute("data-color") === (credit.color || "#00f2fe"));
  });

  // Toggle field groups based on credit type
  document.querySelectorAll(".edit-loan-fields").forEach(el => el.style.display = type === "card" ? "none" : "grid");
  document.querySelectorAll(".edit-card-fields").forEach(el => el.style.display = type === "card" ? "grid" : "none");

  if (type === "card") {
    document.getElementById("edit-credit-card-limit").value = credit.creditLimit || 0;
    document.getElementById("edit-credit-interest-card").value = credit.interestRate || 0;
    document.getElementById("edit-credit-cutoff-day").value = credit.cutoffDay || 1;
    document.getElementById("edit-credit-payment-offset").value = credit.paymentDueOffsetDays || 20;
    document.getElementById("edit-credit-management-fee").value = credit.managementFee || 0;
    document.getElementById("edit-credit-management-fee-freq").value = credit.managementFeeFrequency || "monthly";
  } else {
    document.getElementById("edit-credit-location").value = credit.location || "";
    document.getElementById("edit-credit-card").value = credit.card || "";
    document.getElementById("edit-credit-quota").value = credit.quotaAmount;
    document.getElementById("edit-credit-interest").value = credit.interestRate || 0;
  }

  openModal("modal-edit-credit");
}

function updateCreditData(e) {
  e.preventDefault();
  const id = document.getElementById("edit-credit-id").value;
  const credit = state.credits.find(c => c.id === id);
  if (!credit) return;

  const type = credit.type || "loan";

  credit.name = document.getElementById("edit-credit-name").value.trim();
  credit.lender = document.getElementById("edit-credit-lender").value.trim();
  credit.color = document.getElementById("edit-credit-color").value;
  credit.notes = document.getElementById("edit-credit-notes").value.trim();

  if (type === "card") {
    credit.creditLimit = parseFloat(document.getElementById("edit-credit-card-limit").value) || 0;
    credit.interestRate = parseFloat(document.getElementById("edit-credit-interest-card").value) || 0;
    credit.cutoffDay = parseInt(document.getElementById("edit-credit-cutoff-day").value) || 1;
    credit.paymentDueOffsetDays = parseInt(document.getElementById("edit-credit-payment-offset").value) || 20;
    credit.managementFee = parseFloat(document.getElementById("edit-credit-management-fee").value) || 0;
    credit.managementFeeFrequency = document.getElementById("edit-credit-management-fee-freq").value;
  } else {
    const newQuota = parseFloat(document.getElementById("edit-credit-quota").value);
    credit.location = document.getElementById("edit-credit-location").value.trim();
    credit.card = document.getElementById("edit-credit-card").value.trim();
    credit.interestRate = parseFloat(document.getElementById("edit-credit-interest").value) || 0;

    // Only update unpaid installment amounts (and their interest split) if quota changed
    if (newQuota !== credit.quotaAmount) {
      const unpaidInsts = credit.installments.filter(i => !i.paid);
      const unpaidCount = unpaidInsts.length;
      const paidPrincipal = credit.installments
        .filter(i => i.paid)
        .reduce((s, i) => s + (typeof i.principal === "number" ? i.principal : i.amount), 0);
      const remainingPrincipalOwed = Math.max(0, credit.totalAmount - paidPrincipal);

      credit.quotaAmount = newQuota;
      const totalInterestRemaining = Math.max(0, (newQuota * unpaidCount) - remainingPrincipalOwed);
      const interestPerRemaining = unpaidCount > 0 ? totalInterestRemaining / unpaidCount : 0;
      const principalPerRemaining = newQuota - interestPerRemaining;
      unpaidInsts.forEach(inst => {
        inst.amount = newQuota;
        inst.principal = principalPerRemaining;
        inst.interest = interestPerRemaining;
      });
    }
  }

  saveState();
  closeModal("modal-edit-credit");
  showToast("Crédito actualizado correctamente", TOAST_ICON_EDIT);

  // Re-render current detail
  renderCreditDetail(id);
}

function deleteCredit(creditId) {
  const credit = state.credits.find(c => c.id === creditId);
  const name = credit ? credit.name : "este crédito";
  if (confirm(`¿Eliminar "${name}" y todo su historial? Esta acción no se puede deshacer.`)) {
    state.credits = state.credits.filter((c) => c.id !== creditId);
    saveState();
    showToast(`"${name}" eliminado`, TOAST_ICON_TRASH);
    switchView("credits");
  }
}

// Apply/revert a payment on an installment. If paid BEFORE the due date, the
// interest portion of that quota was never "causado" so it gets waived
// entirely (matches how YOI/CrediPink and similar cupos actually operate) —
// this does NOT apply to credit cards, whose interest accrues on the
// revolving balance regardless of when a specific quota was created.
function applyInstallmentPayment(inst, paid) {
  if (paid) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const due = new Date(inst.dueDate + "T00:00:00");
    const paidEarly = today < due;

    if (paidEarly && typeof inst.interest === "number" && inst.interest > 0) {
      inst.interestWaived = true;
      inst.amount = inst.principal;
    }
    inst.paid = true;
    inst.paymentDate = new Date().toISOString();
  } else {
    if (inst.interestWaived) {
      inst.amount = inst.principal + inst.interest;
      inst.interestWaived = false;
    }
    inst.paid = false;
    inst.paymentDate = null;
  }
}

// Toggle payment status of a specific installment
function toggleInstallmentPaid(creditId, installmentNumber) {
  const credit = state.credits.find((c) => c.id === creditId);
  if (!credit) return;

  const inst = credit.installments.find((i) => i.number === installmentNumber);
  if (!inst) return;

  applyInstallmentPayment(inst, !inst.paid);

  saveState();
  
  // If we are currently in credit-detail view, refresh it
  if (activeView === "credit-detail" && currentDetailCreditId === creditId) {
    renderCreditDetail(creditId);
  }
}

// --- CREDIT CARD CYCLE ENGINE (corte / fecha límite / interés E.A. / cuota de manejo) ---

// Clamp a cutoff day to the actual last day of a given month (handles Feb, 30-day months, etc.)
function cutoffDateForMonth(year, month, cutoffDay) {
  const lastDay = new Date(year, month + 1, 0).getDate();
  return new Date(year, month, Math.min(cutoffDay, lastDay));
}

// Returns the last closed cutoff, the next upcoming cutoff, and the payment due date
// (due date = last cutoff + configured offset days) relative to a reference date.
function getCardCycleDates(credit, refDate) {
  const today = refDate ? new Date(refDate) : new Date();
  today.setHours(0, 0, 0, 0);
  const cutoffDay = Math.min(Math.max(parseInt(credit.cutoffDay) || 1, 1), 31);

  let lastCutoff = cutoffDateForMonth(today.getFullYear(), today.getMonth(), cutoffDay);
  if (lastCutoff > today) {
    const prevMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    lastCutoff = cutoffDateForMonth(prevMonth.getFullYear(), prevMonth.getMonth(), cutoffDay);
  }
  const nextMonthRef = new Date(lastCutoff);
  nextMonthRef.setMonth(nextMonthRef.getMonth() + 1);
  const nextCutoff = cutoffDateForMonth(nextMonthRef.getFullYear(), nextMonthRef.getMonth(), cutoffDay);

  const offset = parseInt(credit.paymentDueOffsetDays) || 20;
  const dueDate = new Date(lastCutoff);
  dueDate.setDate(dueDate.getDate() + offset);

  return { lastCutoff, nextCutoff, dueDate };
}

// Applies interest (converted from E.A. to a simple daily rate, applied per elapsed day —
// NOT effective monthly compounding) and the management fee for every billing cycle that
// has closed since the last accrual, bringing the card's currentBalance up to date.
// Idempotent — safe to call on every app load.
function accrueCardCredit(credit) {
  if (!credit || credit.type !== "card") return;

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  if (!credit.movements) credit.movements = [];
  if (typeof credit.cycleCount !== "number") credit.cycleCount = 0;

  if (!credit.lastAccrualCutoff) {
    // First run: anchor to the most recent cutoff without back-charging historical interest.
    const { lastCutoff } = getCardCycleDates(credit, today);
    credit.lastAccrualCutoff = toDateStr(lastCutoff);
    return;
  }

  const cutoffDay = Math.min(Math.max(parseInt(credit.cutoffDay) || 1, 1), 31);
  // Real Colombian card issuers (Bancolombia, BBVA, Nu, Davivienda, Scotiabank/Colpatria —
  // confirmed in each one's own published explanation) charge "interés corriente" as SIMPLE
  // daily interest on the balance: saldo × (E.A./365) × días transcurridos. It is NOT monthly
  // effective compounding — that would overstate the real cost of carrying a balance.
  const dailyRate = credit.interestRate ? (credit.interestRate / 100 / 365) : 0;

  let cursorStr = credit.lastAccrualCutoff;
  let safety = 0;
  while (safety < 36) {
    const cursor = new Date(cursorStr + "T00:00:00");
    const nextRef = new Date(cursor);
    nextRef.setMonth(nextRef.getMonth() + 1);
    const next = cutoffDateForMonth(nextRef.getFullYear(), nextRef.getMonth(), cutoffDay);
    if (next > today) break;

    const daysInCycle = Math.round((next - cursor) / (1000 * 60 * 60 * 24));
    if (credit.currentBalance > 0 && dailyRate > 0) {
      const interestAmt = Math.round(credit.currentBalance * dailyRate * daysInCycle * 100) / 100;
      credit.currentBalance = Math.round((credit.currentBalance + interestAmt) * 100) / 100;
      credit.movements.push({ date: toDateStr(next), type: "interest", amount: interestAmt, note: `Interés corriente (${daysInCycle}d × tasa diaria)` });
    }

    credit.cycleCount++;
    const fee = parseFloat(credit.managementFee) || 0;
    if (fee > 0) {
      const freq = credit.managementFeeFrequency || "monthly";
      const chargeFee = freq === "annual" ? (credit.cycleCount % 12 === 0) : true;
      if (chargeFee) {
        credit.currentBalance = Math.round((credit.currentBalance + fee) * 100) / 100;
        credit.movements.push({ date: toDateStr(next), type: "fee", amount: fee, note: "Cuota de manejo" });
      }
    }

    cursorStr = toDateStr(next);
    safety++;
  }
  credit.lastAccrualCutoff = cursorStr;
}

function accrueAllCards() {
  state.credits.forEach((credit) => accrueCardCredit(credit));
}

// Register a manual movement (cargo/compra o pago) on a credit card, adjusting its balance.
function registerCardMovement(creditId, type, amount, note) {
  const credit = state.credits.find((c) => c.id === creditId);
  if (!credit || credit.type !== "card") return;

  if (!credit.movements) credit.movements = [];
  const delta = type === "payment" ? -Math.abs(amount) : Math.abs(amount);
  credit.currentBalance = Math.max(0, Math.round((credit.currentBalance + delta) * 100) / 100);
  credit.movements.push({ date: toDateStr(new Date()), type, amount: Math.abs(amount), note: note || "" });

  saveState();
}

let cardMovementCreditId = null;

function openCardMovementModal(type) {
  cardMovementCreditId = currentDetailCreditId;
  document.getElementById("movement-type").value = type;
  document.getElementById("card-movement-title").textContent = type === "payment" ? "Registrar Pago" : "Cargo/Compra";
  document.getElementById("form-card-movement").reset();
  document.getElementById("movement-type").value = type; // reset() clears it back, so set again
  openModal("modal-card-movement");
}

function saveCardMovement(e) {
  e.preventDefault();
  const type = document.getElementById("movement-type").value;
  const amount = parseFloat(document.getElementById("movement-amount").value);
  const note = document.getElementById("movement-note").value.trim();

  if (!cardMovementCreditId || isNaN(amount) || amount <= 0) return;

  registerCardMovement(cardMovementCreditId, type, amount, note);
  closeModal("modal-card-movement");
  showToast(type === "payment" ? "Pago registrado" : "Cargo registrado", type === "payment" ? TOAST_ICON_CHECK : TOAST_ICON_RECEIPT);
  renderCreditDetail(cardMovementCreditId);
}

// --- RENDERING VIEWS ---

function renderAll() {
  if (activeView === "dashboard") renderDashboard();
  else if (activeView === "credits") renderCreditsList();
  else if (activeView === "credit-detail" && currentDetailCreditId) renderCreditDetail(currentDetailCreditId);
  else if (activeView === "settings") renderSettings();
}

// 1. Render Dashboard View
function renderDashboard() {
  let totalUnpaid = 0;
  let totalPaid = 0;
  // Amortization progress (the ring) only makes sense for loans/cupos, which have
  // a fixed finish line. Revolving card balances have no "% paid off" — including
  // them would dilute the ring toward 0% forever and make the metric meaningless.
  let loanPaid = 0;
  let loanUnpaid = 0;
  let allUnpaidInstallments = [];

  state.credits.forEach((credit) => {
    if (credit.type === "card") {
      totalUnpaid += getCreditRemainingBalance(credit);
      if (credit.currentBalance > 0) {
        const { dueDate } = getCardCycleDates(credit);
        allUnpaidInstallments.push({
          creditId: credit.id,
          creditName: credit.name,
          color: credit.color,
          number: null,
          totalInsts: null,
          amount: credit.currentBalance,
          dueDate: toDateStr(dueDate),
          instObj: { paid: false, dueDate: toDateStr(dueDate) },
          isCard: true
        });
      }
      return;
    }
    credit.installments.forEach((inst) => {
      if (inst.paid) {
        totalPaid += inst.amount;
        loanPaid += inst.amount;
      } else {
        totalUnpaid += inst.amount;
        loanUnpaid += inst.amount;
        allUnpaidInstallments.push({
          creditId: credit.id,
          creditName: credit.name,
          color: credit.color,
          number: inst.number,
          totalInsts: credit.totalInstallments,
          amount: inst.amount,
          dueDate: inst.dueDate,
          instObj: inst
        });
      }
    });
  });
  
  // Sort unpaid installments by closest due date first
  allUnpaidInstallments.sort((a, b) => new Date(a.dueDate) - new Date(b.dueDate));
  
  // Update total debt display
  document.getElementById("dashboard-total-debt").textContent = `$${totalUnpaid.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  
  // Update progress ring (loans/cupos only — see note above)
  const loanVolume = loanPaid + loanUnpaid;
  const progressPct = loanVolume > 0 ? Math.round((loanPaid / loanVolume) * 100) : 0;
  document.getElementById("dashboard-progress-pct").textContent = loanVolume > 0 ? `${progressPct}%` : "—";
  
  const circle = document.querySelector(".progress-ring__circle");
  const radius = circle.r.baseVal.value;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (progressPct / 100) * circumference;
  circle.style.strokeDasharray = `${circumference} ${circumference}`;
  circle.style.strokeDashoffset = offset;
  
  // Update Next Payment Info
  const nextPaymentDateLabel = document.getElementById("dashboard-next-payment-date");
  if (allUnpaidInstallments.length > 0) {
    const nextInst = allUnpaidInstallments[0];
    const daysDiff = getDaysDifference(nextInst.dueDate);
    let diffStr = "";
    if (daysDiff < 0) {
      diffStr = `(Vencido hace ${Math.abs(daysDiff)}d)`;
      nextPaymentDateLabel.innerHTML = `<span>$${nextInst.amount.toLocaleString('es-ES')} el ${formatDate(nextInst.dueDate)} <span style="color: var(--danger); font-weight: bold;">${diffStr}</span></span>`;
    } else if (daysDiff === 0) {
      diffStr = `(¡Vence Hoy!)`;
      nextPaymentDateLabel.innerHTML = `<span>$${nextInst.amount.toLocaleString('es-ES')} el ${formatDate(nextInst.dueDate)} <span style="color: var(--danger); font-weight: bold;">${diffStr}</span></span>`;
    } else {
      diffStr = `(en ${daysDiff} días)`;
      nextPaymentDateLabel.innerHTML = `<span>$${nextInst.amount.toLocaleString('es-ES')} el ${formatDate(nextInst.dueDate)} <span style="color: var(--warning);">${diffStr}</span></span>`;
    }
  } else {
    nextPaymentDateLabel.textContent = "Sin pagos pendientes";
  }
  
  // --- ACTIVE CARDS LIST RENDER (Vertical Stack - No Horizontal Scroll) ---
  const carouselContainer = document.getElementById("dashboard-card-carousel");
  const activeCredits = state.credits.filter(c => c.type === "card" ? (c.currentBalance > 0) : c.installments.some(i => !i.paid));
  document.getElementById("carousel-cards-count").textContent = activeCredits.length;
  
  let carouselHtml = "";
  if (activeCredits.length === 0) {
    carouselHtml = `
      <div class="active-card-empty" onclick="openModal('modal-add-credit')">
        <div class="add-card-circle">+</div>
        <span>Agregar tarjeta o préstamo</span>
      </div>
    `;
  } else {
    carouselHtml = '<div class="active-cards-list">';
    activeCredits.forEach(credit => {
      const remainingDebt = getCreditRemainingBalance(credit);

      // Detect Bank for Card styling
      const textToSearch = `${credit.lender} ${credit.card || ''}`.toLowerCase();
      let bankClass = "bank-generic";
      let bankLabel = credit.lender;
      
      if (textToSearch.includes("nequi")) { bankClass = "bank-nequi"; bankLabel = "Nequi"; }
      else if (textToSearch.includes("bancolombia")) { bankClass = "bank-bancolombia"; bankLabel = "Bancolombia"; }
      else if (textToSearch.includes("nubank") || textToSearch.includes("nu ") || textToSearch.includes("nu colombia") || textToSearch === "nu") { bankClass = "bank-nu"; bankLabel = "Nu"; }
      else if (textToSearch.includes("davivienda")) { bankClass = "bank-davivienda"; bankLabel = "Davivienda"; }
      else if (textToSearch.includes("daviplata")) { bankClass = "bank-daviplata"; bankLabel = "DaviPlata"; }
      else if (textToSearch.includes("bbva")) { bankClass = "bank-bbva"; bankLabel = "BBVA"; }
      else if (textToSearch.includes("rappi")) { bankClass = "bank-rappi"; bankLabel = "RappiCard"; }
      else if (textToSearch.includes("lulo")) { bankClass = "bank-lulo"; bankLabel = "Lulo"; }
      else if (textToSearch.includes("bogota") || textToSearch.includes("bogotá")) { bankClass = "bank-bogota"; bankLabel = "B. Bogotá"; }
      else if (textToSearch.includes("falabella")) { bankClass = "bank-falabella"; bankLabel = "Falabella"; }
      else if (textToSearch.includes("colpatria")) { bankClass = "bank-colpatria"; bankLabel = "Colpatria"; }

      const typeLabel = credit.type === 'card' ? 'Tarjeta' : 'Préstamo';
      let inlineBg = "";
      if (bankClass === "bank-generic") {
        const baseColor = credit.color || '#4facfe';
        inlineBg = `style="background: linear-gradient(135deg, rgba(255,255,255,0.12) 0%, rgba(0,0,0,0.4) 100%), ${baseColor}; border-color: ${baseColor};"`;
      }
      
      carouselHtml += `
        <div class="active-card-row" onclick="openCreditDetail('${credit.id}')">
          <div class="active-card-mini-graphic ${bankClass}" ${inlineBg}>
            <div class="mini-graphic-chip"></div>
          </div>
          <div class="active-card-details">
            <div class="active-card-header-line">
              <span class="active-card-bank-title">${bankLabel}</span>
              <span class="active-card-type-tag">${typeLabel}</span>
            </div>
            <div class="active-card-name-title">${credit.name}${(credit.id === "demo-1" || credit.id === "demo-2") ? ' <span class="badge-demo">Ejemplo</span>' : ''}</div>
          </div>
          <div class="active-card-amount-box">
            <span class="active-card-amount-label">Deuda</span>
            <span class="active-card-amount-val">$${remainingDebt.toLocaleString('es-ES', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</span>
          </div>
          <svg class="active-card-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"></polyline></svg>
        </div>
      `;
    });
    
    // Add button at bottom of vertical list
    carouselHtml += `
      <div class="active-card-add-row" onclick="openModal('modal-add-credit')">
        <div class="add-card-circle" style="width: 28px; height: 28px; font-size: 16px;">+</div>
        <span>Agregar tarjeta o préstamo</span>
      </div>
    `;
    carouselHtml += '</div>';
  }
  carouselContainer.innerHTML = carouselHtml;
  
  // Render upcoming list (up to 4 items)
  const listContainer = document.getElementById("dashboard-upcoming-list");
  const upcomingCountBadge = document.getElementById("upcoming-count");
  upcomingCountBadge.textContent = `${allUnpaidInstallments.length} pendientes`;
  
  if (allUnpaidInstallments.length === 0) {
    const upcomingEmptyMessage = state.credits.length === 0
      ? "Todavía no registraste ningún crédito."
      : "No tienes pagos pendientes registrados. ¡Todo al día!";
    listContainer.innerHTML = `
      <div class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><path d="M8 12h8"></path></svg>
        <p>${upcomingEmptyMessage}</p>
      </div>
    `;
    return;
  }
  
  const viewAllLink = document.getElementById("upcoming-view-all");
  if (viewAllLink) {
    viewAllLink.style.display = allUnpaidInstallments.length > 4 ? "flex" : "none";
  }

  const maxToShow = allUnpaidInstallments.slice(0, 4);
  let html = "";
  
  maxToShow.forEach((item) => {
    const status = getInstallmentStatus(item.instObj);
    // Card balances can't be "checked off" like a fixed installment, so they get a
    // chevron affordance (go to detail to register a payment) instead of a checkbox
    // that looks actionable but silently does something different than expected.
    const checkboxHtml = item.isCard
      ? `<div class="inst-goto-arrow" onclick="openCreditDetail('${item.creditId}')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"></polyline></svg>
        </div>`
      : `<div class="checkbox-container" onclick="toggleInstallmentPaid('${item.creditId}', ${item.number})">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
        </div>`;
    const subLabel = item.isCard ? `Fecha límite de pago: ${formatDate(item.dueDate)}` : `Cuota ${item.number}/${item.totalInsts} • Vence: ${formatDate(item.dueDate)}`;
    html += `
      <div class="installment-item ${status.state === 'overdue' ? 'overdue' : ''}">
        <div class="inst-left">
          ${checkboxHtml}
          <div class="inst-info" onclick="openCreditDetail('${item.creditId}')" style="cursor:pointer;">
            <span class="inst-num" style="display:flex; align-items:center; gap:6px;">
              <span class="credit-color-dot" style="background-color: ${item.color}; width: 8px; height: 8px;"></span>
              ${item.creditName}
            </span>
            <span class="inst-date">${subLabel}</span>
          </div>
        </div>
        <div class="inst-right" onclick="openCreditDetail('${item.creditId}')" style="cursor:pointer;">
          <span class="inst-amount">$${item.amount.toLocaleString('es-ES')}</span>
          <div>
            <span class="inst-badge ${status.class}">${status.label}</span>
          </div>
        </div>
      </div>
    `;
  });
  
  listContainer.innerHTML = html;
}

// 2. Render Credits View
function filterCredits(filterType) {
  activeCreditFilter = filterType;
  document.getElementById("tab-active").classList.toggle("active", filterType === "active");
  document.getElementById("tab-completed").classList.toggle("active", filterType === "completed");
  renderCreditsList();
}

function renderCreditsList() {
  const container = document.getElementById("credits-list");
  const countBadge = document.getElementById("credits-count");
  
  // Filter by status
  let filtered = state.credits.filter((credit) => {
    const hasUnpaid = credit.type === "card" ? (credit.currentBalance > 0) : credit.installments.some((i) => !i.paid);
    return activeCreditFilter === "active" ? hasUnpaid : !hasUnpaid;
  });
  
  // Filter by search query
  const searchEl = document.getElementById("search-credits");
  if (searchEl && searchEl.value.trim()) {
    const query = searchEl.value.trim().toLowerCase();
    filtered = filtered.filter(c =>
      c.name.toLowerCase().includes(query) ||
      c.lender.toLowerCase().includes(query) ||
      (c.location || "").toLowerCase().includes(query) ||
      (c.card || "").toLowerCase().includes(query)
    );
  }
  
  // Sort
  const sortEl = document.getElementById("sort-credits");
  const sortVal = sortEl ? sortEl.value : "due";
  filtered.sort((a, b) => {
    if (sortVal === "name") return a.name.localeCompare(b.name);
    const debtOf = (c) => getCreditRemainingBalance(c);
    if (sortVal === "debt-desc" || sortVal === "debt-asc") {
      const aDebt = debtOf(a);
      const bDebt = debtOf(b);
      return sortVal === "debt-desc" ? bDebt - aDebt : aDebt - bDebt;
    }
    // Default: sort by next due date
    const nextDueOf = (c) => c.type === "card" ? toDateStr(getCardCycleDates(c).dueDate) : (c.installments.find(i => !i.paid) || {}).dueDate;
    const aDate = nextDueOf(a);
    const bDate = nextDueOf(b);
    if (!aDate) return 1;
    if (!bDate) return -1;
    return new Date(aDate) - new Date(bDate);
  });
  
  countBadge.textContent = `${filtered.length} créditos`;
  
  if (filtered.length === 0) {
    const emptyMessage = state.credits.length === 0
      ? "Aún no tienes créditos registrados. Toca + para agregar tu primer crédito o tarjeta."
      : "Ningún crédito coincide con tu búsqueda o filtro actual.";
    container.innerHTML = `
      <div class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="5" width="20" height="14" rx="2" ry="2"></rect><line x1="2" y1="10" x2="22" y2="10"></line></svg>
        <p>${emptyMessage}</p>
      </div>
    `;
    return;
  }
  
  let html = "";
  filtered.forEach((credit) => {
    let subLabel, remainingAmount, statusBadgeHTML;

    // Detect Bank for Card styling
    const textToSearch = `${credit.lender} ${credit.card || ''}`.toLowerCase();
    let bankClass = "bank-generic";
    let bankLabel = credit.lender;
    
    if (textToSearch.includes("nequi")) { bankClass = "bank-nequi"; bankLabel = "Nequi"; }
    else if (textToSearch.includes("bancolombia")) { bankClass = "bank-bancolombia"; bankLabel = "Bancolombia"; }
    else if (textToSearch.includes("nubank") || textToSearch.includes("nu ") || textToSearch.includes("nu colombia") || textToSearch === "nu") { bankClass = "bank-nu"; bankLabel = "Nu"; }
    else if (textToSearch.includes("davivienda")) { bankClass = "bank-davivienda"; bankLabel = "Davivienda"; }
    else if (textToSearch.includes("daviplata")) { bankClass = "bank-daviplata"; bankLabel = "DaviPlata"; }
    else if (textToSearch.includes("bbva")) { bankClass = "bank-bbva"; bankLabel = "BBVA"; }
    else if (textToSearch.includes("rappi")) { bankClass = "bank-rappi"; bankLabel = "RappiCard"; }
    else if (textToSearch.includes("lulo")) { bankClass = "bank-lulo"; bankLabel = "Lulo"; }
    else if (textToSearch.includes("bogota") || textToSearch.includes("bogotá")) { bankClass = "bank-bogota"; bankLabel = "B. Bogotá"; }
    else if (textToSearch.includes("falabella")) { bankClass = "bank-falabella"; bankLabel = "Falabella"; }
    else if (textToSearch.includes("colpatria")) { bankClass = "bank-colpatria"; bankLabel = "Colpatria"; }

    let inlineBg = "";
    if (bankClass === "bank-generic") {
      const baseColor = credit.color || '#4facfe';
      inlineBg = `style="background: linear-gradient(135deg, rgba(255,255,255,0.12) 0%, rgba(0,0,0,0.4) 100%), ${baseColor}; border-color: ${baseColor};"`;
    }

    if (credit.type === "card") {
      const { dueDate } = getCardCycleDates(credit);
      remainingAmount = getCreditRemainingBalance(credit);
      subLabel = `${bankLabel} • Tarjeta de Crédito`;

      if (remainingAmount > 0) {
        const dueDateStr = toDateStr(dueDate);
        const daysDiff = getDaysDifference(dueDateStr);
        if (daysDiff < 0) {
          statusBadgeHTML = `<span class="credit-status-badge badge-overdue">⚠️ VENCIDO (${Math.abs(daysDiff)}d)</span>`;
        } else if (daysDiff === 0) {
          statusBadgeHTML = `<span class="credit-status-badge badge-today">🚨 ¡Vence Hoy!</span>`;
        } else if (daysDiff <= 3) {
          statusBadgeHTML = `<span class="credit-status-badge badge-soon">⏳ Vence en ${daysDiff}d</span>`;
        } else {
          statusBadgeHTML = `<span class="credit-status-badge badge-normal">📅 Vence ${formatDate(dueDateStr)}</span>`;
        }
      } else {
        statusBadgeHTML = `<span class="credit-status-badge badge-completed">✓ Sin Deuda</span>`;
      }
    } else {
      const paidCount = credit.installments.filter((i) => i.paid).length;
      remainingAmount = getCreditRemainingBalance(credit);
      subLabel = `${bankLabel} • Cuotas ${paidCount}/${credit.totalInstallments}`;

      const nextUnpaid = credit.installments.find((i) => !i.paid);
      if (nextUnpaid) {
        const daysDiff = getDaysDifference(nextUnpaid.dueDate);
        if (daysDiff < 0) {
          statusBadgeHTML = `<span class="credit-status-badge badge-overdue">⚠️ VENCIDO ($${nextUnpaid.amount.toLocaleString('es-ES')})</span>`;
        } else if (daysDiff === 0) {
          statusBadgeHTML = `<span class="credit-status-badge badge-today">🚨 ¡Vence Hoy! ($${nextUnpaid.amount.toLocaleString('es-ES')})</span>`;
        } else if (daysDiff <= 3) {
          statusBadgeHTML = `<span class="credit-status-badge badge-soon">⏳ Vence en ${daysDiff}d ($${nextUnpaid.amount.toLocaleString('es-ES')})</span>`;
        } else {
          statusBadgeHTML = `<span class="credit-status-badge badge-normal">📅 Cuota ${nextUnpaid.number}: ${formatDate(nextUnpaid.dueDate)}</span>`;
        }
      } else {
        statusBadgeHTML = `<span class="credit-status-badge badge-completed">✓ Totalmente Pagado</span>`;
      }
    }

    html += `
      <div class="credit-item-card" onclick="openCreditDetail('${credit.id}')">
        <div class="credit-item-left">
          <div class="active-card-mini-graphic ${bankClass}" ${inlineBg}>
            <div class="mini-graphic-chip"></div>
          </div>
          <div class="credit-item-info">
            <span class="credit-item-name">${credit.name}${(credit.id === "demo-1" || credit.id === "demo-2") ? ' <span class="badge-demo">Ejemplo</span>' : ''}</span>
            <span class="credit-item-sub">${subLabel}</span>
          </div>
        </div>
        <div class="credit-item-right">
          <span class="credit-item-amount">$${remainingAmount.toLocaleString('es-ES', { minimumFractionDigits: 0, maximumFractionDigits: 0 })}</span>
          ${statusBadgeHTML}
        </div>
      </div>
    `;
  });
  
  container.innerHTML = html;
}

// 3. Render Credit Detail View
function openCreditDetail(creditId) {
  currentDetailCreditId = creditId;
  creditDetailOriginView = activeView === "dashboard" ? "dashboard" : "credits";
  switchView("credit-detail");
  switchDetailTab("summary");
}

function switchDetailTab(tabName) {
  document.querySelectorAll(".detail-tabs-container .tab").forEach((tabEl) => {
    tabEl.classList.toggle("active", tabEl.id === `detail-tab-${tabName}`);
  });
  document.querySelectorAll(".detail-tab-panel").forEach((panelEl) => {
    panelEl.classList.toggle("active", panelEl.id === `detail-panel-${tabName}`);
  });
}

// --- GOOGLE WALLET CARD DYNAMIC DESIGN ---
function updateWalletCardDesign(credit, remainingDebt) {
  const cardEl = document.getElementById("detail-wallet-card");
  const bankNameEl = document.getElementById("card-bank-name");
  const displayNameEl = document.getElementById("card-display-name");
  const displayAmtEl = document.getElementById("card-display-amount");
  const brandLogoEl = document.getElementById("card-brand-logo");

  // Clean previous classes
  cardEl.className = "wallet-card"; 
  cardEl.style.background = ""; 

  // Detect Bank from lender or card description
  const textToSearch = `${credit.lender} ${credit.card || ''}`.toLowerCase();
  
  let bankClass = "bank-generic";
  let bankLabel = credit.lender;
  let brandSVG = "";

  // Brands SVGs
  const mastercardSVG = `<svg viewBox="0 0 24 15" style="width: 32px;"><circle cx="7" cy="7.5" r="7.5" fill="#eb001b" opacity="0.9"/><circle cx="17" cy="7.5" r="7.5" fill="#ff5f00" opacity="0.9"/><path d="M12 7.5a7.5 7.5 0 0 1 2.22-5.28 7.5 7.5 0 0 1 0 10.56A7.5 7.5 0 0 1 12 7.5z" fill="#ff9900"/></svg>`;
  const visaSVG = `<span style="font-weight: 800; font-style: italic; color: #fff; font-size: 17px; letter-spacing: 0.5px;">VISA</span>`;
  const daviviendaSVG = `<span style="font-weight: 800; color: #fff; font-size: 12px; letter-spacing: 0.5px;">DAVIVIENDA</span>`;

  if (textToSearch.includes("nequi")) {
    bankClass = "bank-nequi";
    bankLabel = "Nequi";
    brandSVG = visaSVG; // real Nequi card carries a VISA network logo bottom-right
  } else if (textToSearch.includes("bancolombia")) {
    bankClass = "bank-bancolombia";
    bankLabel = "Crédito";
    brandSVG = visaSVG; // real card: "VISA Infinite"
  } else if (textToSearch.includes("nubank") || textToSearch.includes("nu ") || textToSearch.includes("nu colombia") || textToSearch === "nu") {
    bankClass = "bank-nu";
    bankLabel = "nu";
    brandSVG = mastercardSVG;
  } else if (textToSearch.includes("davivienda")) {
    bankClass = "bank-davivienda";
    bankLabel = "Davivienda";
    brandSVG = daviviendaSVG;
  } else if (textToSearch.includes("daviplata")) {
    bankClass = "bank-daviplata";
    bankLabel = "DaviPlata";
    brandSVG = visaSVG;
  } else if (textToSearch.includes("bbva")) {
    bankClass = "bank-bbva";
    bankLabel = "BBVA Colombia";
    brandSVG = visaSVG;
  } else if (textToSearch.includes("rappi")) {
    bankClass = "bank-rappi";
    bankLabel = "RappiCard";
    brandSVG = visaSVG;
  } else if (textToSearch.includes("lulo")) {
    bankClass = "bank-lulo";
    bankLabel = "Lulo Bank";
    brandSVG = mastercardSVG;
  } else if (textToSearch.includes("bogota") || textToSearch.includes("bogotá")) {
    bankClass = "bank-bogota";
    bankLabel = "Banco de Bogotá";
    brandSVG = visaSVG;
  } else if (textToSearch.includes("falabella")) {
    bankClass = "bank-falabella";
    bankLabel = "Banco Falabella";
    brandSVG = mastercardSVG;
  } else if (textToSearch.includes("colpatria")) {
    bankClass = "bank-colpatria";
    bankLabel = "Scotiabank Colpatria";
    brandSVG = visaSVG;
  } else {
    // Generic Card Design using custom selected color
    bankClass = "bank-generic";
    bankLabel = credit.lender || "Crédito Personal";
    const numId = credit.id.replace(/\D/g, '');
    brandSVG = (parseInt(numId || '0') % 2 === 0) ? visaSVG : mastercardSVG;
    
    const baseColor = credit.color || '#4facfe';
    cardEl.style.background = `linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(0,0,0,0.3) 100%), ${baseColor}`;
  }

  cardEl.classList.add(bankClass);
  bankNameEl.textContent = bankLabel;
  displayNameEl.textContent = credit.name;
  displayAmtEl.textContent = `$${remainingDebt.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  brandLogoEl.innerHTML = brandSVG;
}

// --- COLOR TINTING & ENHANCEMENT HELPERS ---
function hexToRgba(hex, alpha) {
  let c;
  if(/^#([A-Fa-f0-9]{3}){1,2}$/.test(hex)){
    c = hex.substring(1).split('');
    if(c.length == 3){
      c = [c[0], c[0], c[1], c[1], c[2], c[2]];
    }
    c = '0x' + c.join('');
    return 'rgba(' + [(c>>16)&255, (c>>8)&255, c&255].join(',') + ',' + alpha + ')';
  }
  return `rgba(255,255,255,${alpha})`;
}

// Returns the interactive accent color for a credit (drives buttons/glow in detail view).
// This is deliberately a lighter tint of the real brand color where the true brand hue is
// too dark to keep black text legible on a filled button (e.g. BBVA's navy Electric Blue) —
// the actual card artwork in CSS (.bank-*) still uses the true, darker brand color.
function getBankColor(credit) {
  const textToSearch = `${credit.lender} ${credit.card || ''}`.toLowerCase();
  if (textToSearch.includes("nequi")) return "#9333ea"; // Nequi purple family
  if (textToSearch.includes("bancolombia")) return "#ffdd00"; // accent yellow from 2021 rebrand
  if (textToSearch.includes("nubank") || textToSearch.includes("nu ") || textToSearch.includes("nu colombia") || textToSearch === "nu") return "#9333ea"; // Nu Electric Violet family
  if (textToSearch.includes("davivienda")) return "#e4032e";
  if (textToSearch.includes("daviplata")) return "#f0521c";
  if (textToSearch.includes("bbva")) return "#85c8ff"; // BBVA Serene Blue (official secondary tone)
  if (textToSearch.includes("rappi")) return "#fe3f23"; // Rappi official Red-Orange
  if (textToSearch.includes("lulo")) return "#00e28a";
  if (textToSearch.includes("bogota") || textToSearch.includes("bogotá")) return "#d4af37";
  if (textToSearch.includes("falabella")) return "#c3d500"; // Falabella official Rio Grande green
  if (textToSearch.includes("colpatria")) return "#ec0712"; // Scotiabank red
  return credit.color || "#ffffff";
}

// Computes the outstanding balance for a credit using the shared formula:
// revolving cards use their tracked currentBalance; loan/cupo credits sum the
// amount of every installment that hasn't been marked paid yet.
function getCreditRemainingBalance(credit) {
  return credit.type === "card"
    ? (credit.currentBalance || 0)
    : credit.installments.filter((i) => !i.paid).reduce((sum, i) => sum + i.amount, 0);
}

function renderCreditDetail(creditId) {
  const credit = state.credits.find((c) => c.id === creditId);
  if (!credit) {
    switchView("credits");
    return;
  }

  const type = credit.type || "loan";

  // Set delete listener dynamically to avoid memory leaks or multiple events
  const deleteBtn = document.getElementById("btn-delete-credit");
  deleteBtn.onclick = () => deleteCredit(credit.id);

  const remainingDebt = getCreditRemainingBalance(credit);

  // Update wallet card design dynamically
  updateWalletCardDesign(credit, remainingDebt);

  // Set dynamic accent color and dynamic background glow
  const accentColor = getBankColor(credit);
  const container = document.querySelector(".app-container");
  if (container) {
    container.style.setProperty("--accent-primary", accentColor);
    const rgbaGlow = hexToRgba(accentColor, 0.08); // 8% opacity is extremely subtle and clean
    container.style.setProperty("--dynamic-glow", `radial-gradient(circle at 50% 30%, ${rgbaGlow} 0%, transparent 70%)`);
  }

  document.getElementById("detail-val-remaining").textContent = `$${remainingDebt.toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  document.getElementById("detail-val-interest").textContent = credit.interestRate ? `${credit.interestRate}%` : "0%";

  // Toggle loan schedule vs card panel
  document.getElementById("detail-loan-schedule").style.display = type === "card" ? "none" : "block";
  document.getElementById("detail-card-panel").style.display = type === "card" ? "block" : "none";
  document.getElementById("detail-progress-container").style.display = type === "card" ? "none" : "block";
  document.getElementById("detail-interest-caveat").style.display = type === "card" ? "block" : "none";
  document.getElementById("label-detail-total").textContent = type === "card" ? "Cupo Total" : "Monto Financiado";
  document.getElementById("label-detail-quota").textContent = type === "card" ? "Cuota de Manejo" : "Monto Cuota";
  document.getElementById("detail-tab-movimientos").textContent = type === "card" ? "Movimientos" : "Cronograma";

  // Notes area & Extra Info (shared between both types)
  const notesCard = document.getElementById("detail-notes-card");
  if (credit.notes || credit.location || credit.card) {
    notesCard.style.display = "block";

    const locEl = document.getElementById("detail-location-text");
    const locContainer = document.getElementById("detail-location-container");
    if (credit.location) {
      locContainer.style.display = "block";
      locEl.textContent = credit.location;
    } else {
      locContainer.style.display = "none";
    }

    const cardTxtEl = document.getElementById("detail-card-text");
    const cardTxtContainer = document.getElementById("detail-card-container");
    if (credit.card) {
      cardTxtContainer.style.display = "block";
      cardTxtEl.textContent = credit.card;
    } else {
      cardTxtContainer.style.display = "none";
    }

    const notesEl = document.getElementById("detail-notes-text");
    const notesContainer = document.getElementById("detail-notes-container");
    if (credit.notes) {
      notesContainer.style.display = "block";
      notesEl.textContent = credit.notes;
    } else {
      notesContainer.style.display = "none";
    }
  } else {
    notesCard.style.display = "none";
  }

  if (type === "card") {
    renderCardDetailPanel(credit);
    return;
  }

  document.getElementById("detail-val-total").textContent = `$${credit.totalAmount.toLocaleString('es-ES')}`;
  document.getElementById("detail-val-quota").textContent = `$${credit.quotaAmount.toLocaleString('es-ES')}`;

  // Progress Bar
  const paidCount = credit.installments.filter((i) => i.paid).length;
  document.getElementById("detail-progress-label").textContent = `${paidCount} de ${credit.totalInstallments} cuotas`;
  const progressPct = credit.totalInstallments > 0 ? (paidCount / credit.totalInstallments) * 100 : 0;
  document.getElementById("detail-progress-bar-fill").style.width = `${progressPct}%`;

  // Unpaid count badge
  const unpaidCount = credit.totalInstallments - paidCount;
  document.getElementById("detail-unpaid-installments-count").textContent = `${unpaidCount} pendientes`;

  // Render individual installments
  const instListContainer = document.getElementById("detail-installments-list");
  let html = "";

  credit.installments.forEach((inst) => {
    const status = getInstallmentStatus(inst);
    const waivedNote = inst.interestWaived ? ' • Interés no cobrado (pago anticipado)' : '';
    html += `
      <div class="installment-item ${inst.paid ? 'paid' : ''} ${status.state === 'overdue' ? 'overdue' : ''}">
        <div class="inst-left">
          <div class="checkbox-container" onclick="toggleInstallmentPaid('${credit.id}', ${inst.number})">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
          </div>
          <div class="inst-info">
            <span class="inst-num">Cuota ${inst.number}</span>
            <span class="inst-date">Vencimiento: ${formatDate(inst.dueDate)} ${inst.paid && inst.paymentDate ? '• Pagado el ' + formatDate(inst.paymentDate.split ? inst.paymentDate.split('T')[0] : inst.paymentDate) : ''}${waivedNote}</span>
          </div>
        </div>
        <div class="inst-right">
          <span class="inst-amount">$${inst.amount.toLocaleString('es-ES', { maximumFractionDigits: 2 })}</span>
          <div>
            <span class="inst-badge ${status.class}">${status.label}</span>
          </div>
        </div>
      </div>
    `;
  });

  instListContainer.innerHTML = html;
}

// Populates the revolving-balance panel for credit-card type credits: cutoff/due dates,
// available limit, management fee info, and the movement history (cargos/pagos/intereses).
function renderCardDetailPanel(credit) {
  const { nextCutoff, dueDate } = getCardCycleDates(credit);

  document.getElementById("detail-val-total").textContent = `$${(credit.creditLimit || 0).toLocaleString('es-ES')}`;
  document.getElementById("detail-val-quota").textContent = `$${(credit.managementFee || 0).toLocaleString('es-ES')}`;

  const available = Math.max(0, (credit.creditLimit || 0) - (credit.currentBalance || 0));
  document.getElementById("detail-card-available").textContent = `$${available.toLocaleString('es-ES', { maximumFractionDigits: 2 })}`;

  const feeFreqLabel = credit.managementFeeFrequency === "annual" ? "al año" : "al mes";
  document.getElementById("detail-card-fee-line").textContent = credit.managementFee
    ? `Cobra cuota de manejo de $${credit.managementFee.toLocaleString('es-ES')} ${feeFreqLabel}.`
    : "Esta tarjeta no cobra cuota de manejo.";

  document.getElementById("detail-card-cutoff").textContent = formatDate(toDateStr(nextCutoff));

  const dueDateStr = toDateStr(dueDate);
  const daysDiff = getDaysDifference(dueDateStr);
  const dueEl = document.getElementById("detail-card-duedate");
  if (credit.currentBalance > 0 && daysDiff < 0) {
    dueEl.innerHTML = `${formatDate(dueDateStr)} <span style="color:var(--danger); font-size:11px;">(Vencido ${Math.abs(daysDiff)}d)</span>`;
  } else {
    dueEl.textContent = formatDate(dueDateStr);
  }

  const movementsContainer = document.getElementById("detail-card-movements");
  const movements = (credit.movements || []).slice().reverse();

  if (movements.length === 0) {
    movementsContainer.innerHTML = `
      <div class="empty-state">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><path d="M8 12h8"></path></svg>
        <p>Sin movimientos registrados todavía.</p>
      </div>
    `;
    return;
  }

  const typeLabels = { charge: "Cargo/Compra", payment: "Pago", interest: "Interés E.A.", fee: "Cuota de Manejo" };
  let html = "";
  movements.forEach((m) => {
    const isCredit = m.type === "payment";
    html += `
      <div class="installment-item">
        <div class="inst-left">
          <div class="inst-info">
            <span class="inst-num">${typeLabels[m.type] || m.type}${m.note ? " — " + m.note : ""}</span>
            <span class="inst-date">${formatDate(m.date)}</span>
          </div>
        </div>
        <div class="inst-right">
          <span class="inst-amount" style="color: ${isCredit ? 'var(--success)' : 'var(--text-primary)'}">${isCredit ? '-' : '+'}$${m.amount.toLocaleString('es-ES', { maximumFractionDigits: 2 })}</span>
        </div>
      </div>
    `;
  });
  movementsContainer.innerHTML = html;
}

// 4. Render Account / Settings View
function renderSettings() {
  const activeCount = state.credits.filter(c => c.type === "card" ? (c.currentBalance > 0) : c.installments.some(i => !i.paid)).length;
  const completedCount = state.credits.length - activeCount;

  // Total actually invested/borrowed: loans use the financed amount; cards use the sum
  // of real charges ever made (their credit LIMIT is just a ceiling, not money spent).
  const totalBorrowed = state.credits.reduce((sum, c) => {
    if (c.type === "card") {
      const chargedTotal = (c.movements || []).filter(m => m.type === "charge").reduce((s, m) => s + m.amount, 0);
      return sum + chargedTotal;
    }
    return sum + c.totalAmount;
  }, 0);

  // Common frequency (only meaningful for cupos/préstamos)
  const freqs = state.credits.filter(c => c.type !== "card").map(c => c.frequency);
  let commonFreq = "-";
  if (freqs.length > 0) {
    const freqCounts = freqs.reduce((acc, f) => { acc[f] = (acc[f] || 0) + 1; return acc; }, {});
    const sortedFreqs = Object.keys(freqCounts).sort((a, b) => freqCounts[b] - freqCounts[a]);
    const freqLabels = { monthly: "Mensual", biweekly: "Quincenal", weekly: "Semanal" };
    commonFreq = freqLabels[sortedFreqs[0]] || "-";
  }
  
  document.getElementById("stats-active-count").textContent = activeCount;
  document.getElementById("stats-completed-count").textContent = completedCount;
  document.getElementById("stats-total-borrowed").textContent = `$${totalBorrowed.toLocaleString('es-ES', { maximumFractionDigits: 0 })}`;
  document.getElementById("stats-common-freq").textContent = commonFreq;
  
  const username = localStorage.getItem("kredit_username") || "Mi Control";
  const pDisplay = document.getElementById("profile-name-display");
  if (pDisplay) pDisplay.textContent = username;
}

// --- HELPER FLOW Rework Actions ---
function editProfileName() {
  const current = localStorage.getItem("kredit_username") || "Mi Control";
  const input = document.getElementById("profile-name-input");
  if (input) input.value = current;
  openModal("modal-edit-profile");
}

function saveProfileName(e) {
  e.preventDefault();
  const input = document.getElementById("profile-name-input");
  const name = input ? input.value.trim() : "";
  if (!name) return;

  localStorage.setItem("kredit_username", name);

  // Update labels in real time
  const userLabel = document.getElementById("user-profile-name");
  if (userLabel) userLabel.textContent = name;
  const pDisplay = document.getElementById("profile-name-display");
  if (pDisplay) pDisplay.textContent = name;
  const sidebarName = document.getElementById("sidebar-profile-name");
  if (sidebarName) sidebarName.textContent = name;

  closeModal("modal-edit-profile");
  showToast("Nombre de perfil actualizado", TOAST_ICON_EDIT);
}

function goBackToCredits() {
  switchView(creditDetailOriginView);
}

function goToAllUpcoming() {
  const sortEl = document.getElementById("sort-credits");
  if (sortEl) sortEl.value = "due";
  switchView("credits");
}

// --- MARCAR CUOTAS COMO PAGADAS (registro manual) ---
function markAllInstallments() {
  const credit = state.credits.find(c => c.id === currentDetailCreditId);
  if (!credit) return;
  const unpaid = credit.installments.filter(i => !i.paid);
  if (unpaid.length === 0) {
    showToast("Todas las cuotas ya están marcadas en tu registro", TOAST_ICON_CHECK);
    return;
  }
  if (confirm(`¿Marcar las ${unpaid.length} cuota(s) restantes como pagadas en tu registro de control?`)) {
    credit.installments.forEach(inst => {
      if (!inst.paid) applyInstallmentPayment(inst, true);
    });
    saveState();
    showToast(`${unpaid.length} cuota(s) registradas como pagadas`, TOAST_ICON_CHECK);
    renderCreditDetail(currentDetailCreditId);
  }
}

// --- DATA BACKUP AND RESTORE ---
function exportData() {
  const dataStr = JSON.stringify(state, null, 2);
  const blob = new Blob([dataStr], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  
  const today = new Date().toISOString().split("T")[0];
  const a = document.createElement("a");
  a.href = url;
  a.download = `kredit_backup_${today}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function importData(event) {
  const file = event.target.files[0];
  if (!file) return;
  
  const reader = new FileReader();
  reader.onload = function(e) {
    try {
      const importedState = JSON.parse(e.target.result);
      
      // Basic validation
      if (importedState && Array.isArray(importedState.credits)) {
        if (!confirm("Esto reemplazará todos tus créditos actuales por los del archivo importado. ¿Continuar?")) {
          event.target.value = "";
          return;
        }
        state = importedState;
        saveState();
        showToast(`${importedState.credits.length} crédito(s) importados con éxito`, TOAST_ICON_DOWNLOAD);
        switchView("dashboard");
      } else {
        showToast("Archivo inválido: no es un respaldo de Kredit", TOAST_ICON_WARNING);
      }
    } catch (err) {
      showToast("Error al leer el archivo JSON", TOAST_ICON_ERROR);
      console.error(err);
    }
  };
  reader.readAsText(file);
}

function clearAllData() {
  if (confirm("¿Borrar absolutamente todos tus créditos y pagos registrados? Esta acción NO se puede deshacer.")) {
    if (confirm("Confirmación final: ¿Sí, vaciar todos los registros de Kredit?")) {
      state = { credits: [] };
      saveState();
      showToast("Todos los datos han sido eliminados", TOAST_ICON_TRASH);
      switchView("dashboard");
    }
  }
}

// --- INIT APP ---
window.addEventListener("DOMContentLoaded", async () => {
  loadThemePreferences();
  await loadState();
  switchView("dashboard");

  // Keep the splash visible long enough for its build-in animation to play
  // (~0.9s, see .splash-stroke-3's animation-delay + duration in css/style.css)
  // even if loadState() resolves near-instantly on a warm cache.
  const splash = document.getElementById("splash-screen");
  if (splash) {
    setTimeout(() => splash.classList.add("splash-hidden"), 900);
  }
});

// PWA Install Prompt Listener
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
  // Prevent Chrome 67 and earlier from automatically showing the prompt
  e.preventDefault();
  // Stash the event so it can be triggered later.
  deferredPrompt = e;
  // Update UI to show the PWA installation item in settings
  const installItem = document.getElementById("pwa-install-item");
  if (installItem) {
    installItem.style.display = "flex";
  }
  
  const btnInstall = document.getElementById("btn-install-pwa");
  if (btnInstall) {
    btnInstall.addEventListener('click', () => {
      // Show the prompt
      deferredPrompt.prompt();
      // Wait for the user to respond to the prompt
      deferredPrompt.userChoice.then((choiceResult) => {
        if (choiceResult.outcome === 'accepted') {
          console.log('User accepted the install prompt');
          installItem.style.display = "none";
        }
        deferredPrompt = null;
      });
    });
  }
});

window.addEventListener('appinstalled', (evt) => {
  console.log('Kredit fue instalada en el dispositivo.');
  const installItem = document.getElementById("pwa-install-item");
  if (installItem) {
    installItem.style.display = "none";
  }
});
