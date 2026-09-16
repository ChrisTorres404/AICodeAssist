# Design System Migration Guide — template

## What this template is for

`DESIGN-SYSTEM-INSTRUCTIONS.md` is for a project whose design system already
exists: it tells an agent how to build inside it. This document is the other
half — the **migration path** for an application that does not look like its
design system yet, and has to be converted.

It is written for the common case: an existing component-based UI built on a
utility-class CSS framework and a headless primitive component library, being
converted to a house design system. Every concrete value below — colour, font,
radius, class name, component name — is an **example, written to be replaced**
with the ones recorded in `{{DOCS_DIR}}/DESIGN-SYSTEM.md`. Fill that document
in first; this one is the plan for applying it.

**Where to save the filled-in copy:** `{{DOCS_DIR}}/DESIGN-SYSTEM-MIGRATION.md`.
Then open a work order for the conversion — it is a multi-day change across
every page, and it wants a spec, a task breakdown, and verification like any
other.

**Estimated Time:** 4-8 hours for a small application; a week or more for a
large one. The timeline table at the end breaks it down by phase.
**Difficulty:** Intermediate to advanced.
**Requirements:** An existing component-based UI, a styling system you control,
and a filled-in `{{DOCS_DIR}}/DESIGN-SYSTEM.md`.

**Do it on a branch, page by page, with the old build still runnable.** A
conversion that cannot be compared side by side with what it replaced cannot be
reviewed.

---

## Phase 1: Foundation Setup (30 minutes)

Everything after this phase depends on the tokens existing. Do not start
converting pages while colours are still literals.

### Step 1.1: Define the tokens in one stylesheet

One file holds every colour, every scale value, and the radius. Nothing else in
the codebase states a colour. The block below is one project's — replace every
value with yours.

```css
@import "<your utility-class framework>";

/* ============================================
   COLOUR SYSTEM — example values, replace
   ============================================ */

@theme {
  /* Ground */
  --color-background: #0a0a0f;
  --color-foreground: #fafafa;
  --color-card: #0f0f14;
  --color-card-foreground: #fafafa;
  --color-popover: #0f0f14;
  --color-popover-foreground: #fafafa;

  /* Primary */
  --color-primary: #00e6ff;
  --color-primary-foreground: #000000;

  /* Secondary */
  --color-secondary: #1a1a24;
  --color-secondary-foreground: #fafafa;

  /* Accent — the elevated tier */
  --color-accent: #ffd700;
  --color-accent-foreground: #000000;

  /* System states */
  --color-success: #00ff88;
  --color-success-foreground: #000000;
  --color-warning: #ffaa00;
  --color-warning-foreground: #000000;
  --color-destructive: #ff3366;
  --color-destructive-foreground: #fafafa;
  --color-info: #00ccff;
  --color-info-foreground: #000000;
  --color-danger: #ff3366;
  --color-danger-foreground: #fafafa;

  /* Structural */
  --color-muted: #18181f;
  --color-muted-foreground: #888899;
  --color-border: #1a1a24;
  --color-input: #1a1a24;
  --color-ring: #00e6ff;

  /* Chart series, in order */
  --color-chart-1: #00e6ff;
  --color-chart-2: #ffd700;
  --color-chart-3: #00ff88;
  --color-chart-4: #ffaa00;
  --color-chart-5: #ff3366;

  /* Radius — the single most load-bearing value in a conversion */
  --radius: 0px;
}

/* ============================================
   TYPOGRAPHY SYSTEM
   ============================================ */

body {
  font-family: "<display face>", -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
  font-weight: 450;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

h1 {
  font-size: 2.5rem;
  font-weight: 750;
  line-height: 1.2;
  letter-spacing: -0.02em;
}

h2 {
  font-size: 2rem;
  font-weight: 650;
  line-height: 1.3;
  letter-spacing: -0.01em;
}

h3 {
  font-size: 1.5rem;
  font-weight: 650;
  line-height: 1.4;
}

h4 {
  font-size: 1.25rem;
  font-weight: 550;
  line-height: 1.5;
}

p {
  font-size: 0.875rem;
  font-weight: 450;
  line-height: 1.7;
}

label,
.label {
  font-size: 0.6875rem; /* 11px */
  font-weight: 550;
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

small,
.text-small {
  font-size: 0.75rem;
  font-weight: 450;
  letter-spacing: 0.05em;
}

code,
pre {
  font-family: "<mono face>", Monaco, Consolas, monospace;
  font-size: 0.8125rem;
}

/* ============================================
   UTILITY CLASSES — the shared treatments
   ============================================ */

/* Base container: every card, panel and section sits on this */
.surface {
  border-radius: 0px;
  border: 1px solid hsl(var(--color-border));
  background: hsl(var(--color-card));
  transition: all 260ms cubic-bezier(0.16, 1, 0.3, 1);
}

/* Optional background texture */
.grid-bg {
  background-image:
    linear-gradient(hsl(var(--color-border)) 1px, transparent 1px),
    linear-gradient(90deg, hsl(var(--color-border)) 1px, transparent 1px);
  background-size: 32px 32px;
}

/* Subsurface glow, for an emphasised region */
.glow-field {
  position: relative;
}

.glow-field::before {
  content: "";
  position: absolute;
  inset: 0;
  background: radial-gradient(
    circle at 50% 50%,
    hsl(var(--color-primary) / 0.15) 0%,
    transparent 60%
  );
  pointer-events: none;
}

/* The one shared hover treatment */
.hover-lift {
  transition: all 260ms cubic-bezier(0.16, 1, 0.3, 1);
}

.hover-lift:hover {
  transform: translateY(-1px);
  border-color: hsl(var(--color-primary) / 0.5);
  box-shadow: 0 4px 16px hsl(var(--color-primary) / 0.15);
}

/* ============================================
   ANIMATIONS
   ============================================ */

/* Page entry */
@keyframes pageEnter {
  0% {
    opacity: 0;
    transform: scale(0.96) translateY(10px);
  }
  100% {
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

.page-enter {
  animation: pageEnter 800ms cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

/* Stagger delays for a row of cards */
.page-enter .stagger-1 { animation-delay: 80ms; }
.page-enter .stagger-2 { animation-delay: 160ms; }
.page-enter .stagger-3 { animation-delay: 240ms; }
.page-enter .stagger-4 { animation-delay: 320ms; }

/* Pulse, for a live indicator */
@keyframes indicatorPulse {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 1; }
}

.pulse {
  animation: indicatorPulse 3s ease-in-out infinite;
}

/* Accent glow, for the elevated tier */
@keyframes accentGlow {
  0%, 100% {
    filter: drop-shadow(0 0 8px hsl(var(--color-accent) / 0.6));
  }
  50% {
    filter: drop-shadow(0 0 16px hsl(var(--color-accent) / 0.8));
  }
}

.accent-glow {
  animation: accentGlow 4s ease-in-out infinite;
}

/* Section-level loading sweep */
@keyframes loadingSweep {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(200%); }
}

.section-loading {
  position: relative;
  overflow: hidden;
}

.section-loading::after {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 2px;
  background: linear-gradient(90deg,
    transparent 0%,
    hsl(var(--color-primary)) 50%,
    transparent 100%
  );
  animation: loadingSweep 2s ease-in-out infinite;
}

/* Every animation above needs a still fallback */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Step 1.2: Install the display font

**Option A: use the system stack.** Already installed everywhere. The fallback
stack above resolves to it, so the conversion can proceed while font licensing
is being sorted out.

**Option B: self-host (recommended).**

1. Obtain the face under a licence that permits self-hosting.
2. Put the `woff2` files in the application's static assets directory.
3. Declare each weight:

```css
@font-face {
  font-family: "<display face>";
  src: url("/fonts/<face>-Regular.woff2") format("woff2");
  font-weight: 450;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "<display face>";
  src: url("/fonts/<face>-Semibold.woff2") format("woff2");
  font-weight: 650;
  font-style: normal;
  font-display: swap;
}

@font-face {
  font-family: "<display face>";
  src: url("/fonts/<face>-Bold.woff2") format("woff2");
  font-weight: 750;
  font-style: normal;
  font-display: swap;
}
```

`font-display: swap` is not optional: without it a failed font load is an
invisible page.

---

## Phase 2: Component Library Setup (1-2 hours)

### Step 2.1: Create the core components

These are the components every converted page is built from. Names are the role
names from the inventory in `{{DOCS_DIR}}/DESIGN-SYSTEM.md` — use yours.

| # | Role | Example name | For |
|---|---|---|---|
| 1 | Metric display | `MetricBlock` | KPIs, counts, statistics |
| 2 | Page section container | `SectionFrame` | Page sections, anything wrapping a table or form |
| 3 | Data table | `DataTable` | Tabular data with sorting and filtering |
| 4 | Event / activity list | `ActivityFeed` | Timelines, audit logs, event streams |
| 5 | Top navigation | `CommandBar` | Header |
| 6 | Side navigation | `Sidebar` | Primary navigation |

Build all six before converting the first page. Converting pages against
components that do not exist yet produces six slightly different versions of
each.

### Step 2.2: Update the primitive components

The primitive library ships with the radius, the shadows, and the casing of
*its* default look. Every primitive the application uses has to be brought into
line — once, centrally, not per call site.

**Before:**

```tsx
className="rounded-lg"
className="rounded-md"
className="rounded-full"
```

**After:**

```tsx
className=""
// or, explicitly, where something else might add a radius back:
className="rounded-none"
```

**Automated first pass** — run it inside the primitives directory only, and
read the diff afterwards; a blind find-and-replace across an application will
strip radii from things that legitimately have them, such as avatars you have
decided to keep round:

```bash
# from the primitive components directory
find . -type f -name "*.tsx" -exec sed -i'' -e 's/rounded-lg//g' {} +
find . -type f -name "*.tsx" -exec sed -i'' -e 's/rounded-md//g' {} +
find . -type f -name "*.tsx" -exec sed -i'' -e 's/rounded-full//g' {} +
find . -type f -name "*.tsx" -exec sed -i'' -e 's/rounded-sm//g' {} +
```

**Manual verification required for:**

- the button primitive — remove every rounded variant
- the card primitive — no radius, and check its default padding against the scale
- the dialog primitive — no radius on the panel or the overlay
- the badge primitive — no radius, and the label treatment applied
- the avatar primitive — decide deliberately, then apply it everywhere

---

## Phase 3: Page-by-Page Conversion (3-5 hours)

### Step 3.1: Conversion checklist per page

Work one page at a time, all the way through this list, and review it before
starting the next. Half-converted pages across the whole application are worse
than a queue of unconverted ones.

#### 3.1.1: Page structure

```tsx
// After: the standard page shape
export function YourPage() {
  return (
    <div className="flex-1 overflow-auto bg-background">
      {/* Header */}
      <div className="border-b border-border bg-card/50 px-8 py-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tighter uppercase mb-1">
              Page Title
            </h1>
            <p className="text-sm text-muted-foreground uppercase tracking-wider">
              Page description
            </p>
          </div>
          <Button className="gap-2 h-9 bg-primary hover:bg-primary/90">
            <Plus className="w-4 h-4" strokeWidth={2.5} />
            <span className="text-xs uppercase tracking-wider font-semibold">
              Action
            </span>
          </Button>
        </div>
      </div>

      {/* Content */}
      <div className="p-8 space-y-6">
        {/* Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 page-enter">
          {/* MetricBlock per metric */}
        </div>

        {/* Sections */}
        <SectionFrame title="Section">
          {/* content */}
        </SectionFrame>
      </div>
    </div>
  );
}
```

#### 3.1.2: Replace generic cards

**Before:**

```tsx
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
  </CardHeader>
  <CardContent>Content</CardContent>
</Card>
```

**After:**

```tsx
<SectionFrame title="Title" variant="default">
  Content
</SectionFrame>
```

#### 3.1.3: Replace metrics and stats

**Before:**

```tsx
<div className="bg-white rounded-lg p-6 shadow">
  <p className="text-sm text-gray-600">Total Users</p>
  <p className="text-3xl font-bold">1,250</p>
</div>
```

**After:**

```tsx
<MetricBlock
  title="Total Users"
  value="1,250"
  icon={<Users className="w-4 h-4" strokeWidth={2.5} />}
  variant="default"
/>
```

Note what disappeared: a literal colour, a literal radius, a shadow, and a
one-off type scale. That is the point of the conversion.

#### 3.1.4: Replace data tables

**Before:**

```tsx
<Table>
  <TableHeader>
    <TableRow>
      <TableHead>Name</TableHead>
      <TableHead>Status</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    {data.map(row => (
      <TableRow key={row.id}>
        <TableCell>{row.name}</TableCell>
        <TableCell>{row.status}</TableCell>
      </TableRow>
    ))}
  </TableBody>
</Table>
```

**After:**

```tsx
<DataTable
  columns={[
    { key: "name", label: "Name", width: "w-80" },
    { key: "status", label: "Status", width: "w-32" },
  ]}
  data={data}
  renderCell={(key, value, row) => {
    if (key === "status") {
      return <StatusIndicator status={value} label={value} />;
    }
    return value;
  }}
/>
```

Columns become data. After this, a new column is one entry plus one case.

#### 3.1.5: Update all text

Find and replace per file:

```tsx
// Labels
// Before: <Label>Email Address</Label>
// After:  <Label className="text-[11px]">Email Address</Label>

// Headings
// Before: <h2>Dashboard</h2>
// After:  <h2 className="uppercase tracking-tighter">Dashboard</h2>

// Descriptions
// Before: <p>Manage your users here</p>
// After:  <p className="text-sm uppercase tracking-wider">Manage your users here</p>

// Buttons
// Before: <Button>Save Changes</Button>
// After:
<Button className="uppercase tracking-wider font-semibold text-xs">
  Save Changes
</Button>
```

#### 3.1.6: Add the tier markers

If the design system uses a marker to signal tier or surface — a glyph, an
icon, a coloured rule — apply it now, consistently, from the tier table in
`{{DOCS_DIR}}/DESIGN-SYSTEM.md`. A marker applied to some headings and not
others reads as a bug.

```tsx
// Section titles
<h3>[marker] Security Settings</h3>

// Descriptions
<p>[marker] Configure authentication methods</p>
```

If the design system has no such marker, skip this step rather than inventing
one.

#### 3.1.7: Add the background treatment

```tsx
// At the page root
<div className="flex-1 overflow-auto bg-background">
  {/* Texture */}
  <div className="absolute inset-0 grid-bg opacity-10 pointer-events-none" />

  {/* Ambient fields */}
  <div className="absolute top-0 right-0 w-[600px] h-[600px] bg-primary/10 blur-3xl opacity-30 pointer-events-none" />
  <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-accent/10 blur-3xl opacity-20 pointer-events-none" />

  {/* Content above it */}
  <div className="relative z-10">
    {/* ... */}
  </div>
</div>
```

Every decorative layer carries `pointer-events-none`. A background that eats
clicks is the most common defect this phase introduces.

---

## Phase 4: Component-Specific Conversions

### 4.1: Buttons

**Before:**

```tsx
<Button variant="default">Click Me</Button>
```

**After:**

```tsx
<Button className="gap-2 h-9 bg-primary hover:bg-primary/90 hover-lift">
  <Icon className="w-4 h-4" strokeWidth={2.5} />
  <span className="text-xs uppercase tracking-wider font-semibold">
    Click Me
  </span>
</Button>

// Secondary
<Button
  variant="outline"
  className="gap-2 h-9 hover:bg-primary/10 hover:border-primary/50 hover-lift"
>
  <Icon className="w-4 h-4" strokeWidth={2.5} />
  <span className="text-xs uppercase tracking-wider font-semibold">
    Secondary
  </span>
</Button>
```

### 4.2: Badges

**Before:**

```tsx
<Badge>Active</Badge>
```

**After:**

```tsx
<Badge
  variant="outline"
  className="text-[9px] uppercase tracking-wider px-2 py-0 border-success text-success bg-success/10"
>
  Active
</Badge>

// Tier-specific
<Badge className="text-[9px] uppercase tracking-wider px-2 py-0 border-primary text-primary bg-primary/10">
  Enterprise
</Badge>
```

### 4.3: Forms

**Before:**

```tsx
<form>
  <Label>Email</Label>
  <Input type="email" placeholder="Enter email" />
  <Button>Submit</Button>
</form>
```

**After:**

```tsx
<form className="space-y-5">
  <div className="space-y-2">
    <Label className="text-[11px]">
      <Mail className="w-3 h-3 inline mr-1.5" strokeWidth={2.5} />
      Email Address
    </Label>
    <Input
      type="email"
      placeholder="you@example.com"
      className="h-11 border-border hover:border-primary/50 focus:border-primary tracking-wide text-sm"
    />
  </div>

  <Button
    type="submit"
    className="w-full h-12 gap-2 bg-primary hover:bg-primary/90 font-bold uppercase tracking-wider hover-lift"
  >
    <ArrowRight className="w-4 h-4" strokeWidth={2.5} />
    <span>Submit</span>
  </Button>
</form>
```

Do not uppercase the value a user typed. Uppercase the label, not the input.

### 4.4: Dialogs and modals

```tsx
<DialogContent className="border-border bg-card">
  <DialogHeader>
    <DialogTitle className="uppercase tracking-wider">
      Modal Title
    </DialogTitle>
    <DialogDescription className="text-xs uppercase tracking-wide">
      What this dialog will do, stated plainly
    </DialogDescription>
  </DialogHeader>

  {/* Content */}

  <DialogFooter>
    <Button variant="outline">Cancel</Button>
    <Button className="bg-primary hover:bg-primary/90">Confirm</Button>
  </DialogFooter>
</DialogContent>
```

---

## Phase 5: Navigation and Layout

### 5.1: Replace the header

```tsx
import { CommandBar } from "./components/CommandBar";

<CommandBar
  userName="User Name"
  userRole="Admin"
  onProfileClick={() => {}}
  onLogout={() => {}}
/>
```

### 5.2: Replace the sidebar

```tsx
import { Sidebar } from "./components/Sidebar";

<Sidebar
  currentPage={currentPage}
  onNavigate={setCurrentPage}
  userRole="admin"
/>
```

### 5.3: Application layout

```tsx
export function App() {
  return (
    <div className="h-screen flex flex-col bg-background">
      {/* Background texture */}
      <div className="fixed inset-0 grid-bg opacity-10 pointer-events-none" />

      {/* Header */}
      <CommandBar {...headerProps} />

      {/* Main area */}
      <div className="flex-1 flex overflow-hidden relative">
        <Sidebar {...sidebarProps} />

        <main className="flex-1 overflow-auto">
          {/* Page content */}
        </main>
      </div>
    </div>
  );
}
```

---

## Phase 6: Fine-Tuning and QA (1 hour)

### 6.1: Visual inspection checklist

Go through every page and verify:

- [ ] Every radius matches the token — inspect the computed value, do not trust the source
- [ ] Every heading and label follows the typography scale
- [ ] Labels use the label size and tracking from the scale
- [ ] Buttons use the label treatment and the icon stroke width
- [ ] Every metric uses the metric component
- [ ] Every section uses the section container
- [ ] Every table uses the data table
- [ ] Tier markers present and consistent, where the system has them
- [ ] Hover states work, through the shared class
- [ ] Page entry animation applied
- [ ] No soft edges or stray pills anywhere
- [ ] Colours come from tokens — no literal values survive

### 6.2: Accessibility check

- [ ] Keyboard navigation reaches and operates every control
- [ ] Focus states visible on every interactive element
- [ ] Colour contrast meets WCAG AA — measured with a tool, not judged by eye
- [ ] Screen reader labels present
- [ ] Icon-only buttons carry an accessible name
- [ ] `prefers-reduced-motion` honoured by every animation

A conversion that improves the look and loses the focus ring is a regression.

### 6.3: Performance

- [ ] Unused primitive components removed
- [ ] Animation properties promoted deliberately, not everywhere
- [ ] Heavy components lazy-loaded
- [ ] Bundle size checked against the pre-conversion baseline
- [ ] Animations hold 60fps on the slowest supported device

---

## Phase 7: Final Polish

### 7.1: Loading states

```tsx
// A skeleton in the shape of what it replaces, so the layout does not jump
<div className="surface border border-border p-6 animate-pulse">
  <div className="h-4 bg-muted mb-2 w-1/4" />
  <div className="h-8 bg-muted/50 w-1/2" />
</div>
```

### 7.2: Empty states

```tsx
<div className="surface border border-dashed border-border p-12 text-center">
  <div className="w-16 h-16 border border-border bg-card mx-auto mb-4 flex items-center justify-center">
    <Icon className="w-8 h-8 text-muted-foreground" strokeWidth={2} />
  </div>
  <h3 className="text-sm font-semibold uppercase tracking-wider mb-2">
    No Data Available
  </h3>
  <p className="text-xs text-muted-foreground uppercase tracking-wide">
    What would appear here, and the action that fills it
  </p>
</div>
```

### 7.3: Error states

```tsx
<div className="surface border border-destructive/50 bg-destructive/5 p-6">
  <div className="flex items-start gap-3">
    <AlertTriangle className="w-5 h-5 text-destructive shrink-0" strokeWidth={2.5} />
    <div>
      <h4 className="text-sm font-semibold uppercase tracking-wider text-destructive mb-1">
        Error Detected
      </h4>
      <p className="text-xs text-muted-foreground uppercase tracking-wide">
        What happened, then what to do about it
      </p>
    </div>
  </div>
</div>
```

---

## Common Pitfalls and Solutions

### Pitfall 1: the radius creeps back

**Problem:** rounded corners reappear after a dependency update or a new page.

**Solution:**

```css
/* Containment while you find the source */
* {
  border-radius: 0 !important;
}

/* Then re-add, deliberately, where the system says so */
.specific-element {
  border-radius: 1px !important;
}
```

The real fix is a lint rule or a review check that rejects the radius utility
outside the token file.

### Pitfall 2: the font does not load

**Problem:** the display face never appears.

**Solution:** open the network panel and look at the request. Then:

1. Verify the font file paths resolve from the deployed base URL.
2. Check the served media types.
3. Confirm the fallback stack is in place, so a failure degrades rather than
   blanking the page.

### Pitfall 3: animations are janky

**Problem:** transitions stutter.

**Solution:**

```css
.animated-element {
  will-change: transform, opacity;
  transform: translateZ(0);
}
```

Use it on the few elements that need it. `will-change` applied broadly costs
more than it saves.

### Pitfall 4: colours look wrong

**Problem:** rendered colours do not match the reference.

**Solution:**

1. Verify the colour format the style config expects matches the format the
   tokens are written in.
2. Check whether a theme or colour-scheme override is interfering.
3. Inspect the computed value in developer tools rather than reading the source.

---

## Maintenance Guidelines

### When adding new features

**Always:**

1. Use the metric component for metrics
2. Use the section container for sections
3. Use the data table for tabular data
4. Keep the radius at the token value
5. Use the label treatment for labels
6. Apply the tier marker, where the system has one
7. Use the shared hover class

**Never:**

1. Add a radius the system does not have
2. Introduce a colour outside the tokens
3. Use a one-off type scale
4. Add easing the system does not use
5. Write copy in a register the system does not use

### Code review checklist

Before merging any change to the UI:

- [ ] No radius outside the token
- [ ] Text follows the casing rule the system chose
- [ ] Uses the established components rather than new ones
- [ ] Tier markers present and consistent
- [ ] Hover and focus states work
- [ ] Colours come from tokens
- [ ] Animations use the system's duration and easing
- [ ] Nothing that reads as a default from the primitive library

---

## Testing the Conversion

### Visual regression

Take screenshots before and after, at the same widths, and compare them.

```bash
# one browser-automation tool's screenshot command
npx playwright screenshot --full-page <url> before.png
# ...convert, then
npx playwright screenshot --full-page <url> after.png
```

What to compare:

| Before | After |
|---|---|
| Soft edges | The system's radius |
| Default primitive styling | The house components |
| Ad-hoc colours | Tokens |
| Mixed type scales | One scale |
| Mixed casing | The casing rule |

Keep the screenshots with the work order. They are the evidence a UI
verification asks for.

### Stakeholder check

Show it to the people who asked for the design system and ask the one question
the core directive in `{{DOCS_DIR}}/DESIGN-SYSTEM.md` implies. If the answer is
not an unhesitating yes, the conversion is not done.

---

## Estimated Timeline

| Phase | Time | Difficulty |
|-------|------|-----------|
| 1. Foundation setup | 30 min | Easy |
| 2. Component library | 1-2 hrs | Medium |
| 3. Page conversion | 3-5 hrs | Hard |
| 4. Component updates | 1-2 hrs | Medium |
| 5. Navigation and layout | 1 hr | Medium |
| 6. QA and polish | 1 hr | Easy |
| **TOTAL** | **7.5-11.5 hrs** | **Medium-Hard** |

Phase 3 scales with the number of pages; the rest does not. Multiply phase 3 by
your page count over the handful this estimate assumes.

---

## When Something Is Still Wrong

**"The borders are still rounded."** Search the whole codebase for the radius
utility prefix and remove it; then add the global override from Pitfall 1 so a
regression is visible immediately.

**"The colours do not look right."** Verify the style config reads from the
tokens rather than restating them, and check for a theme override.

**"The fonts are not loading."** Check the paths, the `@font-face`
declarations, and the served media types. Test with the system fallback first
to prove the rest of the page is correct.

**"The animations do not run."** Confirm the token stylesheet is imported,
look for conflicting rules, and check whether reduced-motion is switched on in
the operating system.

Anything this document does not answer is a question for
`{{DOCS_DIR}}/DESIGN-SYSTEM.md`. If that does not answer it either, the answer
is a change to the design system — make it there first, then write the code.
