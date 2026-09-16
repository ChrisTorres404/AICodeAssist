# Design System Instructions — template

## What this template is for

This is the instruction set an agent reads before it writes or changes any UI
in this project. It exists so that every component, page and fix comes out
looking like it was built by the same hand: one component library, one set of
tokens, one typography scale, one set of interaction rules.

The method below is general. The concrete values are not — every colour, font,
radius, class name and component name in this file is an **example, written to
be replaced**. Fill in the three tables in section 1 with your own design
system's identity, tokens and components, then work through the rest of the
document replacing the example values with yours. A half-filled copy is worse
than none: an agent will follow whatever is written here literally.

**Where to save the filled-in copy:** `{{DOCS_DIR}}/DESIGN-SYSTEM.md` in this
project. Then point the UI agents at it — add a line to `AGENTS.md` under
*Where Things Live*, and record the project's specifics in an agent overlay
under `{{PIPELINE_ROOT}}/core/agents/overlays/` so every UI agent applies them.
Re-running the installer never overwrites either file.

---

## 1. Fill in first

### 1.1 Identity

| Field | Your value |
|---|---|
| Design system name | `[name]` |
| One-line description | `[what it is]` |
| Core directive (see 1.4) | `[one sentence]` |
| Component library underneath it | `[e.g. a headless primitive library]` |
| Styling system | `[e.g. utility classes, CSS modules, CSS-in-JS]` |
| Reference documents | `[paths to the visual spec and the component catalog]` |

### 1.2 Tokens

Record the token **name** the code uses, not the raw value — code refers to
tokens, and the value lives in one place. Example values shown are from one
project's dark console theme; replace all of them.

| Role | Token | Example value | When to use |
|---|---|---|---|
| Background | `background` | `#0a0a0f` | Page ground |
| Foreground | `foreground` | `#fafafa` | Body text |
| Primary | `primary` | `#00e6ff` | Primary actions, active states, links, focus rings |
| Accent | `accent` | `#ffd700` | Elevated tier, premium or owner-only surfaces |
| Success | `success` | `#00ff88` | Completed operations, healthy status, positive metrics |
| Warning | `warning` | `#ffaa00` | Approaching a limit, review required, non-critical alerts |
| Destructive | `destructive` | `#ff3366` | Errors, delete actions, critical states |
| Muted | `muted-foreground` | `#888899` | Secondary text, disabled states, metadata, placeholders |
| Border | `border` | `#1a1a24` | Every dividing line |

| Scale | Your value | Example |
|---|---|---|
| Border radius | `[value]` | `0px`, maximum `1px` |
| Font family | `[stack]` | a system UI stack |
| Font weight range | `[range]` | `350`-`850` |
| Body size | `[value]` | `14px` |
| Label size | `[value]` | `10px`-`11px`, uppercase, wide tracking |
| Spacing unit | `[value]` | `4px` base, sections at `24px` |
| Transition | `[duration + easing]` | `260ms cubic-bezier(0.16, 1, 0.3, 1)` |

### 1.3 Component inventory

The single most important table in this document. An agent that has it reaches
for an existing component; an agent that does not invents a fourth card
variant. List every shared component, by the role it fills. Example role names
are used throughout the rest of this file — replace them with your own names.

| Role | Component in this project | Use it for |
|---|---|---|
| Page section container | `[SectionFrame]` | Major page sections, anything containing a table or form |
| Metric display | `[MetricBlock]` | KPIs, counts, statistics, summary cards |
| Data table | `[DataTable]` | Any tabular data that needs sorting or filtering |
| Event / activity list | `[ActivityFeed]` | Audit logs, timelines, event streams |
| Status indicator | `[StatusIndicator]` | Live state on a row or header |
| Badge / pill / chip | `[Badge]` | A short static label on a row or card — a tier, a category, a count |
| Top navigation | `[CommandBar]` | Header navigation |
| Side navigation | `[Sidebar]` | Primary navigation |
| Empty state | `[EmptyState]` | No data yet, no search results |
| Loading state | `[LoadingState]` | Any async region |
| Error state | `[ErrorState]` | Any failed fetch or action |
| Form field | `[from the primitive library]` | Inputs, labels, selects |
| Modal | `[from the primitive library]` | Confirmations, create and edit dialogs |

### 1.4 Core directive

One sentence that decides the borderline cases, written so that it can be
wrong. "Every design decision reinforces authority and precision; if something
looks friendly or approachable, it is wrong" is one project's. "Calm, legible,
unremarkable — the data is the interesting part" is another's. Write yours,
and mean it: the directive is what an agent falls back on when no rule below
covers the decision in front of it.

> **Core directive for this project:** `[fill in]`

### 1.5 Forbidden patterns

The list of things that are always wrong here, however good they look in
isolation. Keep it short and absolute — a long list is ignored. One project's:

- Rounded corners over 1px
- Gradients
- Soft shadows
- Conversational copy ("Hey!", "Let's go!")
- Centred single-column layouts
- Playful easing (bounce, elastic)

> **Forbidden in this project:** `[fill in]`

---

## 2. When creating a new component

### Step 1: Planning

Before writing any code, answer three questions.

1. **Does a component already exist for this?** Check the inventory in 1.3
   first, then search the codebase. Reuse it. If it nearly fits, extend it and
   keep its existing callers working. Write a new component only when nothing
   is close *and* extending would be the wrong shape. "I looked and found
   nothing" is a finding to record in the work order, not a formality.

2. **What tier or surface is this?** If the system distinguishes surfaces —
   by tenancy, by role, by environment — the component has to declare which it
   is, because the tokens differ. Record the project's tiers here:

   | Tier | Applies to | Accent token | Marker |
   |---|---|---|---|
   | `[tier]` | `[audience]` | `[token]` | `[optional glyph or icon]` |

3. **What is the interaction pattern?** Hover, active, loading, and error are
   decided by the design system, not per component. Record them here:

   | State | Treatment |
   |---|---|
   | Hover | `[e.g. lift plus border highlight, via one shared class]` |
   | Active | `[...]` |
   | Loading | `[...]` |
   | Error | `[...]` |
   | Focus | `[...]` — visible, always, never removed |

### Step 2: Structure

Every component takes the same shape. Types first, one class-composition
helper, variants expressed as data rather than as branching markup.

```tsx
import { cn } from "@/lib/utils";

interface ComponentProps {
  variant?: "default" | "elevated" | "accent";
  className?: string;
}

export function Component({ variant = "default", className }: ComponentProps) {
  return (
    <div
      className={cn(
        // base
        "surface border border-border p-6",
        // variant
        variant === "elevated" && "border-primary/30 bg-primary/5",
        variant === "accent" && "border-accent/30 bg-accent/5",
        // interaction
        "hover-lift",
        // caller override, always last
        className
      )}
    >
      {/* content */}
    </div>
  );
}
```

Keep the order: base, variant, interaction, caller override. The caller's
`className` comes last so it can win. Do not accept `any` in props.

`surface` is the shared base container class — the one place the radius,
border and card background are stated — and `hover-lift` is the shared hover
treatment. Every card, panel and section starts from `surface`; a component
that restates those values instead is the next thing to drift.

### Step 3: Styling checklist

Before opening a pull request, verify each of these against the values you
filled into 1.2. The example answers are one project's.

- Border radius matches the token (example: `0`, maximum `1px`)
- Labels use the label treatment (example: uppercase, wide tracking)
- Buttons follow the button pattern, including icon stroke width
- Any required marker or tier indicator is present
- Hover, focus, active and disabled states are all implemented
- Colours come from tokens — no literal hex in a component
- Font weight is inside the declared range
- Transition duration and easing come from the token

---

## 3. When modifying an existing page

### Analysis first

1. **Read the whole file before changing it.** Understand the structure,
   which components it uses, which tier or surface it belongs to.
2. **Decide the scope.** Adding a feature means extending existing patterns.
   A bug fix means the smallest change that fixes it. A redesign means the
   full page template.

### Adding a section

```tsx
<SectionFrame title="New Section" variant="default">
  <div className="space-y-4">{/* content at the standard spacing */}</div>
</SectionFrame>
```

### Adding a metric

```tsx
<MetricBlock
  title="New Metric"
  value={value}
  icon={<Icon className="w-4 h-4" strokeWidth={2.5} />}
  variant="default"
/>
```

### Adding a table column

Add to the column definition, then handle the key in the cell renderer. Never
add a column by writing markup into the table body.

```tsx
const columns = [
  // ...existing
  { key: "newColumn", label: "New Column", width: "w-32" },
];

renderCell={(key, value, row) => {
  // ...existing cases
  if (key === "newColumn") return <span className="text-xs font-bold">{value}</span>;
  return value;
}}
```

---

## 4. Component usage guidelines

Write one of these blocks per shared component, using your own names from 1.3.
The blocks below show the shape: when to use it, which variant means what, and
one worked example. An agent reads "when to use" more often than it reads the
source.

### Metric display

**When to use:** KPIs, statistics, dashboard summary cards, quick status.

**Variant selection:**

| Variant | Meaning |
|---|---|
| `default` | Neutral metric |
| `success` | Positive or healthy |
| `warning` | Approaching a limit |
| `danger` | Over a limit, or errored |
| `accent` | Elevated tier |
| `info` | Informational — a number that is context, not a judgement |

In code, the variant is the one prop that decides the colour. Never override it
with a class:

```tsx
variant="default"   // neutral metric
variant="success"   // positive or healthy
variant="warning"   // approaching a limit
variant="danger"    // over a limit, or errored
variant="accent"    // elevated tier
variant="info"      // informational
```

```tsx
<MetricBlock
  title="Active Users"
  value="1,250"
  subtitle="+12% this month"
  icon={<Users className="w-4 h-4" strokeWidth={2.5} />}
  variant="default"
  status="active"
/>
```

### Page section container

**When to use:** Major page sections; anything wrapping a table, a form, or
grouped functionality.

**Variant selection:**

```tsx
variant="default"    // standard sections — most of them
variant="elevated"   // a section that needs to read as raised
variant="accent"     // elevated tier
```

```tsx
<SectionFrame
  title="Section Title"        // required
  variant="default"            // default | elevated | accent
  headerAction={<Button />}    // optional action in the header
  noPadding                    // for tables that meet the frame edge
>
  {children}
</SectionFrame>
```

### Data table

**When to use:** Any tabular data, especially lists that need sorting or
filtering.

Columns are data. Cells are rendered by a single renderer keyed on the column,
so a new column is one entry plus one case — never a second table.

**Column definition:**

```tsx
const columns = [
  { key: "name", label: "Name", width: "w-80" },
  { key: "status", label: "Status", width: "w-32" },
];
```

**Cell rendering:**

```tsx
renderCell={(key, value, row) => {
  switch (key) {
    case "status":
      return <StatusIndicator status={value} label={value} />;
    case "date":
      return <span className="text-xs">{formatDate(value)}</span>;
    default:
      return value;
  }
}}
```

### Badge / pill / chip

**When to use:** A short static label attached to a row or card — a tier, a
category, a state that does not change while you look at it. For a state that
does change, use the status indicator instead.

One size, one casing, one border treatment. A badge never carries an action.

```tsx
<Badge variant="outline" className="text-[9px] uppercase tracking-wider px-2 py-0">
  Enterprise
</Badge>

// In a cell renderer, alongside the other cases
renderCell={(key, value) => {
  switch (key) {
    case "tier":
      return (
        <Badge variant="outline" className="text-[9px] uppercase">
          {value}
        </Badge>
      );
    default:
      return value;
  }
}}
```

### Event / activity list

**When to use:** Audit logs, timelines, event streams, live updates.

```tsx
const events = [
  {
    id: "1",
    type: "auth" | "security" | "access" | "system",
    severity: "success" | "warning" | "critical" | "info",
    title: "Event Title",
    description: "Event description",
    timestamp: "2m ago",
    user: "user@example.com",
    metadata: { key: "value" },
  },
];

<ActivityFeed events={events} maxItems={20} />
```

---

## 5. Text and typography

One scale, applied everywhere. Replace the example classes with yours.

### Headings

```tsx
// Page title
<h1 className="text-2xl font-bold tracking-tighter uppercase mb-1">Page Title</h1>

// Section title
<h2 className="text-xl font-bold uppercase tracking-tighter">Section Title</h2>

// Subsection title
<h3 className="text-sm font-bold uppercase tracking-wider">Subsection Title</h3>
```

### Labels

```tsx
// Form label
<Label className="text-[11px]">
  <Icon className="w-3 h-3 inline mr-1.5" strokeWidth={2.5} />
  Label Text
</Label>

// Table header
<div className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground">
  Column Header
</div>
```

### Descriptions and technical text

```tsx
// Page description
<p className="text-sm text-muted-foreground uppercase tracking-wider">Description</p>

// Help text
<p className="text-xs text-muted-foreground uppercase tracking-wide">Guidance</p>

// Identifier or machine value
<code className="text-[10px] bg-muted/50 px-2 py-1 border border-border">value</code>
```

### Buttons

```tsx
// Primary
<Button className="gap-2 h-9 bg-primary hover:bg-primary/90">
  <Icon className="w-4 h-4" strokeWidth={2.5} />
  <span className="text-xs uppercase tracking-wider font-semibold">Button Text</span>
</Button>

// Secondary
<Button variant="outline" className="gap-2 h-9 hover:bg-primary/10 hover:border-primary/50">
  <Icon className="w-4 h-4" strokeWidth={2.5} />
  <span className="text-xs uppercase tracking-wider font-semibold">Button Text</span>
</Button>
```

### Copy rules

- Sentence case or upper case — decide once, here, and never mix.
- Error messages say what happened and what to do, in that order.
- No exclamation marks in system copy.
- Numbers are formatted by one shared helper, not per component.

---

## 6. Motion

Motion is a system property. One duration, one easing, one entry pattern.

### Page entry

```tsx
<div className="p-8 space-y-6 page-enter">
  <div className="grid grid-cols-4 gap-4">
    <div className="stagger-1"><MetricBlock /></div>
    <div className="stagger-2"><MetricBlock /></div>
    <div className="stagger-3"><MetricBlock /></div>
    <div className="stagger-4"><MetricBlock /></div>
  </div>
</div>
```

### Hover states

```tsx
// Shared hover class, preferred
<div className="hover-lift">{/* content */}</div>

// Explicit, when the shared class does not fit
<div className="transition-all duration-260 hover:-translate-y-1 hover:border-primary/50" />
```

### Loading states

```tsx
// Loading indicator, for a single control
<div className="w-2 h-2 bg-primary pulse" />

// Section-level loading: one treatment on the whole region, so a section that
// is refreshing reads as one thing rather than as a dozen spinners
<section className="section-loading">{/* content, dimmed and inert */}</section>
```

A region that is loading gets one indicator, on the region. Per-element
spinners inside a loading section are noise.

### Rules

- One easing curve for the whole system.
- Nothing animates longer than the declared duration.
- Respect `prefers-reduced-motion`: every animation has a still fallback.
- No animation on a state the user did not cause, except a loading indicator.

---

## 7. Colour usage

### When to use each colour

Colour carries meaning; it is never decoration. Each token means one thing,
recorded in 1.2, and the meaning never varies by page. The "When to use" column
of the token table is the whole rule. Three sub-rules decide the cases the
table cannot spell out:

- **State colours report state only.** `success`, `warning` and `destructive`
  say what happened to the data; none of them is available as decoration, a
  brand colour, or a way to make a region look busier.
- **The accent belongs to one tier.** Whatever the accent marks — an elevated
  plan, an owner-only surface — it marks only that. An accent that appears on
  an ordinary row stops meaning anything.
- **When no row covers the case, the answer is `muted-foreground`.** Reaching
  for a colour the table does not list is how a fourth palette starts; add a
  row to the table, with its meaning, or use the muted token.

### Colour application

```tsx
// Text
className="text-primary"
className="text-accent"
className="text-success"
className="text-warning"
className="text-destructive"
className="text-muted-foreground"

// Background tints
className="bg-primary/10"
className="bg-accent/5"
className="bg-success/10"

// Borders
className="border-primary"
className="border-accent"
className="border-success"
```

Two rules that outrank taste:

- **No literal colour values in components.** A hex code in a component is a
  token that was not created.
- **Contrast is a requirement, not a preference.** Body text meets WCAG AA
  against its background; so does any state colour used as text.

---

## 8. State management patterns

### Local state

```tsx
const [isOpen, setIsOpen] = useState(false);
const [searchQuery, setSearchQuery] = useState("");

const filtered = useMemo(
  () => data.filter((item) => item.name.toLowerCase().includes(searchQuery.toLowerCase())),
  [data, searchQuery]
);
```

### Form state

```tsx
const [formData, setFormData] = useState({ name: "", email: "", role: "user" });

const handleChange = (field: string) => (value: string) =>
  setFormData((prev) => ({ ...prev, [field]: value }));
```

### Error handling

Every async action owns three states, and renders all three.

```tsx
const [error, setError] = useState<string | null>(null);
const [isLoading, setIsLoading] = useState(false);

const handleSubmit = async () => {
  setIsLoading(true);
  setError(null);
  try {
    await submit();
  } catch (err) {
    setError(err instanceof Error ? err.message : "Request failed");
  } finally {
    setIsLoading(false);
  }
};

{error && (
  <div className="surface border border-destructive/50 bg-destructive/5 p-4">
    <p className="text-xs text-destructive uppercase tracking-wide">{error}</p>
  </div>
)}
```

---

## 9. Common patterns

### Status

```tsx
<StatusIndicator
  status={user.isActive ? "active" : "inactive"}
  label={user.isActive ? "Online" : "Offline"}
/>
```

### Empty state

Never an empty region. An empty state says what is missing and offers the
action that fills it.

```tsx
<div className="surface border border-dashed border-border p-12 text-center">
  <div className="w-16 h-16 border border-border bg-card mx-auto mb-4 flex items-center justify-center">
    <Icon className="w-8 h-8 text-muted-foreground" strokeWidth={2} />
  </div>
  <h3 className="text-sm font-semibold uppercase tracking-wider mb-2">No Data Available</h3>
  <p className="text-xs text-muted-foreground uppercase tracking-wide mb-4">
    What would appear here, and why it is empty
  </p>
  <Button>
    <Plus className="w-4 h-4 mr-2" strokeWidth={2.5} />
    <span className="text-xs uppercase tracking-wider">Create First Item</span>
  </Button>
</div>
```

### Loading state

A skeleton in the shape of the content it replaces, so the layout does not
jump when the data arrives.

```tsx
{isLoading ? (
  <div className="surface border border-border p-6 animate-pulse">
    <div className="h-4 bg-muted mb-2 w-1/4" />
    <div className="h-8 bg-muted/50 w-1/2" />
  </div>
) : (
  <MetricBlock {...props} />
)}
```

### Confirmation

Destructive actions confirm, and the confirm button carries the destructive
token. The dialog says what will happen, not "Are you sure?".

```tsx
<Dialog open={isOpen} onOpenChange={setIsOpen}>
  <DialogContent className="border-border bg-card">
    <DialogHeader>
      <DialogTitle className="uppercase tracking-wider">Confirm Action</DialogTitle>
      <DialogDescription className="text-xs uppercase tracking-wide">
        This deletes the record permanently and cannot be undone.
      </DialogDescription>
    </DialogHeader>
    <DialogFooter>
      <Button variant="outline" onClick={() => setIsOpen(false)}>Cancel</Button>
      <Button className="bg-destructive hover:bg-destructive/90" onClick={handleConfirm}>
        Delete
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

---

## 10. Debugging checklist

### Visual

1. Radius wrong anywhere? Search the codebase for the radius utility prefix.
2. Colours off? Check that the style config and the token stylesheet agree;
   verify the computed value in developer tools.
3. Typography wrong? Check the font family resolves, that the label transform
   is applied, and that letter-spacing comes from the scale.
4. Layout broken? Check the grid classes, look for conflicting absolute
   positioning, test each responsive breakpoint.

### Interaction

1. Hover not working? Confirm the shared hover class is present, check for
   `pointer-events: none`, check nothing is stacked above it.
2. Click not responding? Confirm the handler is attached, the control is not
   disabled, and no overlay covers it.
3. Animation stuttering? Promote the animated property, look for layout
   thrashing, reduce the number of simultaneous animations.

### Component

1. Not rendering? Check the import path, the export, and the type errors.
2. Props not applied? Check the prop names against the interface and the
   default values.
3. State not updating? Check the setter, check for direct mutation, check for
   a stale closure.

---

## 11. Agent workflow

### Starting a task

1. Read the requirements.
2. Read this document, the visual reference, and the component catalog.
3. Search for existing components that already do the job.
4. Plan the approach before writing code.
5. Write the code against the rules above.
6. Self-review against the checklist in section 13.
7. Run it and look at it.
8. Record any new pattern here, so the next agent inherits it.

### Fixing a bug

1. Reproduce it.
2. Find the root cause, not the symptom.
3. Check that the fix does not violate the design system.
4. Make the smallest change that fixes it.
5. Verify no regression, including the edge cases around it.
6. Update or add the test.

### Adding a feature

1. Understand the requirement.
2. Design the component structure.
3. Check whether existing components can be extended before adding new ones.
4. Follow every rule above.
5. Type everything.
6. Write the tests.
7. Document the component's usage.
8. Update the inventory in 1.3 if a new shared component was added.

---

## 12. Code quality

### Types

```tsx
// Do: explicit
interface UserTableProps {
  users: User[];
  onUserClick: (user: User) => void;
  isLoading?: boolean;
}

// Avoid: untyped
interface Props {
  data: any;
  onClick: any;
}
```

### Component structure

```tsx
// Do: one order, every file
export function Component({ prop1, prop2 }: ComponentProps) {
  // hooks
  // derived state
  // handlers
  // effects
  // render
}
```

```tsx
// Avoid: mixed concerns, no order
export function Component(props: any) {
  const handleClick = () => {};
  const [state, setState] = useState();
  useEffect(() => {}, []);
  const computed = useMemo(() => {}, []);
  return <div></div>;
}
```

Mixed ordering costs nothing to write and everything to read.

### Class composition

```tsx
// Do: grouped by purpose
className="
  border border-border
  p-6
  hover:border-primary/50
  transition-all duration-260
"

// Avoid: arbitrary order
className="p-6 border transition-all duration-260 hover:border-primary/50 border-border"
```

---

## 13. Verification before submitting

Run every line. An unchecked box is unfinished work, not a detail.

**Visual**

- Radius matches the token everywhere
- Headings and labels follow the typography scale
- Any required tier marker is present
- Colours come from tokens; no literal values
- Font family and weights are correct
- Letter-spacing comes from the scale

**Interaction**

- Hover states work
- Animation is smooth — 60fps, no dropped frames while it runs — and respects reduced-motion
- Focus states are visible on every interactive element
- Loading states implemented
- Error states handled

**Code**

- Types complete, no `any`
- No console output left behind
- No unused imports
- Follows the component patterns above
- Tests written and passing

**Accessibility**

- Keyboard navigation reaches and operates every control
- Labels present for screen readers
- Colour contrast meets WCAG AA
- Focus order is sensible

**Performance**

- No unnecessary re-renders
- Long lists virtualised or paginated
- Images lazy-loaded and sized
- Bundle impact checked

### Component tests

**Component tests cover**

- Renders with required props
- Handles optional props
- Responds to user interaction
- Shows the loading, error and empty states
- Applies the right classes per variant

### Page tests

**Page tests cover**

- The page loads without errors
- Every section renders
- Navigation works
- Forms submit and validate
- Tables display, sort and paginate

---

## 14. Quick reference: which component

Fill in the right-hand side from your inventory in 1.3. This table is the one
an agent scans first, so keep it current.

| Need | Use |
|---|---|
| Display a metric | `[MetricBlock]` |
| Contain a page section | `[SectionFrame]` |
| Show tabular data | `[DataTable]` |
| Show a timeline or events | `[ActivityFeed]` |
| Show status | `[StatusIndicator]` |
| Label a row or card | `[Badge]` |
| Header navigation | `[CommandBar]` |
| Side navigation | `[Sidebar]` |
| A form | `[primitive inputs plus the project's field wrapper]` |
| A modal | `[primitive dialog plus the project's styling]` |
| A dropdown | `[primitive select plus the project's styling]` |
| Nothing above fits | Extend the closest one; write a new one only as a last resort, and add it to 1.3 |

---

## 15. When the system is visibly wrong

These are containment measures for a broken build, not fixes. Each one is a
defect to open, not a state to leave in place.

### "Everything has the wrong radius"

A global override in the base stylesheet
stops the bleeding:

```css
/* containment, not a fix */
* { border-radius: 0 !important; }
```

The real fix is finding where the radius utility entered the codebase and
removing it there.

### "The colours are wrong across the app"

The style config and the token stylesheet have diverged. Force the palette to
stop the bleeding:

```js
// containment, not a fix
colors: {
  background: "var(--color-background)",
  foreground: "var(--color-foreground)",
  primary:    "var(--color-primary)",
  accent:     "var(--color-accent)",
  // ...the rest of the palette, every entry reading from the token
}
```

Make the config read from the tokens rather than restating them; two lists of
colours will always drift.

### "The fonts are not loading"

Fall back to the system stack so text stays readable:

```css
/* containment, not a fix */
body { font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif; }
```

Then fix the font loading. Never leave an invisible-text state.

---

## 16. When this document does not answer the question

In order:

1. The project's visual reference and component catalog, listed in 1.1.
2. An existing component that solves the nearest problem — read the source.
3. The type definitions.

If none of them answers it, the answer is a change to the design system, not a
local override. Make the change here first, then write the code.
