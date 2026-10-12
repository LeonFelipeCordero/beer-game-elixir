---
name: Beer Game
description: A friendly educational supply-chain simulation for learning through play.
colors:
  deep-blue: "#193b49"
  muted-teal: "#52686e"
  cool-ground: "#f1f4f1"
  white-surface: "#ffffff"
  soft-divider: "#d3ddda"
  citrus: "#e7f269"
  citrus-hover: "#d5e34c"
  pale-blue: "#e6eff0"
  on-blue-muted: "#c0d5da"
  success: "#24634c"
  success-wash: "#e3f0e8"
  warning: "#77501c"
  warning-wash: "#fbefce"
  danger: "#a23333"
  danger-wash: "#fbe9e5"
  focus-teal: "#28738a"
  chain-line: "#60818d"
typography:
  display:
    fontFamily: '"Barlow Condensed", sans-serif'
    fontSize: "clamp(56px, 6.1vw, 88px)"
    fontWeight: 600
    lineHeight: 1.04
    letterSpacing: "-0.025em"
  headline:
    fontFamily: '"Barlow Condensed", sans-serif'
    fontSize: "60px"
    fontWeight: 600
    lineHeight: 1.04
    letterSpacing: "-0.025em"
  title:
    fontFamily: "Barlow, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.2
  body:
    fontFamily: "Barlow, sans-serif"
    fontSize: "16px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Barlow, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.5
rounded:
  control: "5px"
  surface: "8px"
  status: "4px"
spacing:
  compact: "8px"
  regular: "16px"
  section: "24px"
components:
  button-primary:
    backgroundColor: "{colors.citrus}"
    textColor: "{colors.deep-blue}"
    rounded: "{rounded.control}"
    padding: "13px 20px"
    height: "46px"
  button-primary-hover:
    backgroundColor: "{colors.citrus-hover}"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.deep-blue}"
    rounded: "{rounded.control}"
    padding: "13px 20px"
    height: "46px"
  input:
    backgroundColor: "{colors.white-surface}"
    textColor: "{colors.deep-blue}"
    rounded: "{rounded.control}"
    padding: "12px 14px"
    height: "52px"
  selected-chain-stop:
    backgroundColor: "{colors.citrus}"
    textColor: "{colors.deep-blue}"
    rounded: "{rounded.control}"
    padding: "14px 5px"
  status-running:
    backgroundColor: "{colors.success-wash}"
    textColor: "{colors.success}"
    rounded: "{rounded.status}"
  status-pending:
    backgroundColor: "{colors.warning-wash}"
    textColor: "{colors.warning}"
    rounded: "{rounded.status}"
  status-error:
    backgroundColor: "{colors.danger-wash}"
    textColor: "{colors.danger}"
    rounded: "{rounded.status}"
---

# Design System: Beer Game

## Overview

**Creative North Star: “The Supply-Chain Workshop”**

A friendly educational Beer Game, not a beer store or SaaS admin. The visual system translates the clarity of a tabletop learning kit into a working web interface: deep-blue orientation, cool-white work areas, citrus actions, connected role pictograms, and quietly structured tables. It favors legibility and visible consequences over decorative atmosphere.

The build is code-led and uses authored inline SVGs rather than chosen comps or shipping image rasters. One shared three-role chain explains the system; the player's role alone is selected, never presented as a live cross-role view.

**Key Characteristics:**
- Cool, high-contrast blue and citrus palette with explicit semantic state colors.
- Barlow for readable interface text; condensed Barlow for instructional display hierarchy.
- Flat, square-ended paths and softly rounded working controls.

## Colors

Deep blue anchors the persistent shell and orientation; citrus marks primary action and the current role; cool pale surfaces keep the operational workspace calm. Status colors are semantic, not decoration.

### Primary
- **Workshop Blue** (`{colors.deep-blue}`): Masthead, dark orientation panels, inventory summary, and primary text.
- **Citrus Action** (`{colors.citrus}`): Main submit actions, selected role, brand mark, and selection highlight. Hover shifts to the darker citrus token.

### Secondary
- **Soft Blue** (`{colors.pale-blue}`): Secondary hover and quiet icon surfaces.
- **Muted Teal** (`{colors.muted-teal}`): Supporting copy, labels, and low-emphasis information.

### Neutral
- **Cool Ground** (`{colors.cool-ground}`): Page background.
- **White Work Surface** (`{colors.white-surface}`): Forms, cards, and table panels.
- **Soft Divider** (`{colors.soft-divider}`): Borders, separators, and table rules.
- **Muted on Blue** (`{colors.on-blue-muted}`): Secondary text on dark blue.

### Semantic States
- **Success Green** (`{colors.success}`) on **Success Wash** (`{colors.success-wash}`): Running/delivered status and open-board availability.
- **Caution Brown** (`{colors.warning}`) on **Caution Wash** (`{colors.warning-wash}`): Pending/paused status.
- **Alert Red** (`{colors.danger}`) on **Alert Wash** (`{colors.danger-wash}`): Errors and destructive actions.
- **Focus Teal** (`{colors.focus-teal}`): Visible keyboard focus on light surfaces; dark-shell focus changes to citrus.

**The Meaning-Before-Decoration Rule.** Use citrus for the main action or selected role; reserve green, amber, and red for their demonstrated availability, pending, and error meanings.

## Typography

**Display Font:** Barlow Condensed (with sans-serif fallback; local semibold file)
**Body Font:** Barlow (with sans-serif fallback; local regular, semibold, and bold files)

**Source and license:** `priv/static/fonts/barlow-regular.ttf`, `barlow-semibold.ttf`, `barlow-bold.ttf`, and `barlow-condensed-semibold.ttf`; SIL Open Font License 1.1, copies at `priv/static/fonts/OFL-Barlow.txt` and `priv/static/fonts/OFL-Barlow-Condensed.txt`.

**Character:** Barlow keeps labels, instructions, and numeric data straightforward; its condensed semibold companion gives large headings a compact, instructional voice. Counts use tabular numerals where operational comparison matters.

### Hierarchy
- **Display** (600, responsive 56–88px, 1.04): setup hero headings; 64px below 800px and 48px below 480px.
- **Headline** (600, 48–60px, 1.04): page and gameplay headings, adjusted by viewport.
- **Title** (600, 19–24px, 1.2–1.3): panel and section headings.
- **Body** (400, 16px, 1.5): default copy; lead text uses 18px/1.6 on wide layouts and 16px on small screens.
- **Label** (600, 12–14px, 1.5): form labels, table headers, statuses, and navigation.

**The Two-Voice Rule.** Use Barlow Condensed for display hierarchy; keep working copy and controls in Barlow.

## Layout

The shell and main content cap at 1360px with 40px desktop gutters; content areas commonly cap at 1152–1280px. Setup pairs the story/orientation with a compact form. Selection places role choices beside a note. Gameplay orders the role/inventory panel before incoming and outgoing order tables. Spacing is composed in compact 8px steps, with common 16px, 24px, and 40px gutters and section gaps.

At 1150px, gameplay changes from three columns to two. At 800px, setup and selection stack, gameplay becomes one column, and each role's icon and label stack within the horizontal chain; the masthead note disappears. At 480px, shell gutters tighten to 20px, page headings and role choices reflow, and the boards table changes to readable row cards while order tables can scroll horizontally. Preserve semantic table structure and visible actions at narrow widths.

## Elevation & Depth

Depth is mostly tonal and structural: dark-blue orientation bands, white work panels, pale table heads, and fine dividers. The entry panel alone uses a restrained ambient shadow (`0 8px 24px rgb(25 59 73 / 4%)`); controls and data panels remain flat. Focus is a clear 3px outline with 4px offset, not a shadow.

## Shapes

Most controls and panels use softly rounded corners (5–8px); status labels are tighter (4px). Role paths and data tables stay square and orderly, with borders and connected arrows doing the organizing. Avoid pill geometry for working controls; the setup step numbers are the intentional circular exception.

## Components

### Buttons
Confident, compact controls with clear action hierarchy. Primary buttons use citrus on blue text (46px minimum height, 13px 20px padding, 5px corners); hover uses the deeper citrus. Secondary buttons are transparent with a quiet outline and pale-blue hover. Deliver actions are smaller outlined controls; disabled buttons use muted gray and not-allowed affordance. Focus uses the global visible outline; loading labels communicate in-progress LiveView actions.

### Cards / Containers
White entry and data panels use a fine cool divider and 8px corners; the setup entry panel has the sole ambient lift. Dark-blue chain and selection panels use white text and muted-on-blue support copy. Panel padding varies by density (roughly 23–36px).

### Inputs / Fields
White text fields have a 1px neutral stroke, 5px corners, 52px height, and 12px 14px padding. Focus strengthens to teal with a visible outline. Invalid fields use alert red and pair with inline error text; hints remain muted. Numeric quantities align units and use tabular numerals.

### Navigation
The deep-blue masthead carries the box-mark wordmark and a single Boards link. The link is semibold, understated at rest, citrus on hover, with citrus focus against the dark shell. At 800px and below, remove the secondary masthead note rather than crowd navigation.

### Connected Role Chain
Three SVG role pictograms—factory, wholesaler, retailer—sit on a connected directional path. Highlight only the active player's role in citrus and label it “You”; never imply visibility into other players' live state. Selection uses a short background transition, not perpetual motion.

### Tables and Status
Board and order data use real semantic tables, left-aligned labels, right-aligned quantities, tabular numerals, fine row rules, pale headers, and a restrained hover wash. Status badges pair meaning-coded foreground/background colors. On small screens, the board list becomes row cards; order tables remain horizontally scrollable.

## Do's and Don'ts

### Do:
- **Do** keep the educational supply-chain workshop identity distinct from a beer retail storefront or generic admin dashboard.
- **Do** use local Barlow assets and their accompanying SIL OFL notices.
- **Do** keep role emphasis personal: highlight the current role, not a cross-role live overview.
- **Do** preserve semantic labels, explicit status colors, keyboard focus, and responsive table actions.

### Don't:
- **Don't** use citrus as a general-purpose status color; status hues retain their distinct meanings.
- **Don't** treat an unapproved comp or image raster as an existing brand authority; none is part of the shipped visual system.
- **Don't** turn tables into dashboard cards at desktop widths or remove their data hierarchy.
