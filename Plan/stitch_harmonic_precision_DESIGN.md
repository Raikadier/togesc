---
name: Harmonic Precision
colors:
  surface: '#fff7fc'
  surface-dim: '#dfd8dd'
  surface-bright: '#fff7fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f9f1f6'
  surface-container: '#f3ecf1'
  surface-container-high: '#eee6eb'
  surface-container-highest: '#e8e0e5'
  on-surface: '#1e1b1e'
  on-surface-variant: '#4d4351'
  inverse-surface: '#332f33'
  inverse-on-surface: '#f6eff4'
  outline: '#7f7383'
  outline-variant: '#d0c2d3'
  surface-tint: '#843ab4'
  primary: '#4e0078'
  on-primary: '#ffffff'
  primary-container: '#6a1b9a'
  on-primary-container: '#da9cff'
  inverse-primary: '#e4b5ff'
  secondary: '#9a25ae'
  on-secondary: '#ffffff'
  secondary-container: '#ed76fd'
  on-secondary-container: '#69007a'
  tertiary: '#402747'
  on-tertiary: '#ffffff'
  tertiary-container: '#573d5f'
  on-tertiary-container: '#cbaad2'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#f4d9ff'
  primary-fixed-dim: '#e4b5ff'
  on-primary-fixed: '#2f004b'
  on-primary-fixed-variant: '#6a1b9a'
  secondary-fixed: '#ffd6fe'
  secondary-fixed-dim: '#f9abff'
  on-secondary-fixed: '#35003f'
  on-secondary-fixed-variant: '#7b008f'
  tertiary-fixed: '#fad7ff'
  tertiary-fixed-dim: '#debbe4'
  on-tertiary-fixed: '#291231'
  on-tertiary-fixed-variant: '#583d5f'
  background: '#fff7fc'
  on-background: '#1e1b1e'
  surface-variant: '#e8e0e5'
  correct: '#2E7D32'
  incorrect: '#C62828'
  selection: '#FFB300'
  piano-white: '#FFFFFF'
  piano-black: '#212121'
typography:
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-lg:
    fontFamily: Hanken Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  gap-xs: 4px
  gap-sm: 8px
  gap-md: 12px
  gap-lg: 16px
  margin-mobile: 16px
  margin-desktop: 24px
  touch-target-min: 48px
---

## Brand & Style
The design system embodies an **educational, clean, and professional** personality, moving away from high-stimulus gamification toward a focused, academic atmosphere for absolute pitch training. It is inspired by **Material 3 (M3)** principles, emphasizing structural clarity, purposeful movement, and a logical hierarchy that respects the user's cognitive load during intense ear training.

The visual style is **Corporate / Modern** with a scholarly tilt. It utilizes a refined "Harmonic Precision" theme that leverages tonal depth and light surfaces to create an inviting, low-stress environment. The interface focuses on high legibility and accessibility, ensuring that the student can focus entirely on the auditory-visual connection without distraction.

**Key Brand Attributes:**
- **Clarity:** Uncluttered layouts that prioritize the musical task.
- **Academic Rigor:** A professional aesthetic that treats the user as a dedicated student of music.
- **Accessibility:** Large touch targets (min 48x48dp) and high-contrast semantic feedback.

## Colors
The color palette is rooted in the **Musical Purple** (#6A1B9A), representing the intersection of artistic creativity and disciplined precision. Surfaces use a very light, desaturated violet-pink (#FFF7FC) to provide a warmer, more sophisticated alternative to pure white, reducing eye strain during long practice sessions.

**Semantic Colors:**
- **Primary:** Used for key actions, active progress indicators, and primary branding.
- **Correct (Green):** Instant positive reinforcement for correct note identification.
- **Incorrect (Red):** Clear, non-punitive feedback for errors.
- **Selection (Amber):** High-visibility highlight for the active selection state on the piano or text input before confirmation.

For the **Piano Keyboard** component, use high-contrast neutrals for the keys (piano-white and piano-black) to maintain traditional musical mapping, applying the semantic selection and result colors as overlays or border highlights.

## Typography
**Hanken Grotesk** is the exclusive typeface for this design system. It was chosen for its sharp, contemporary geometry and exceptional legibility across both functional labels and editorial headings. 

Typography follows a strict hierarchy to differentiate between instructional content and interactive data. 
- **Headlines:** Use tighter letter spacing and bolder weights to create a strong visual anchor for screen titles.
- **Body Text:** Standard weight for maximum readability. 
- **Interactive Labels:** Slightly increased letter spacing and medium weights to ensure buttons and menu items are easily identifiable.
- **Musical Notation:** When displaying note names (e.g., C#, Db), use the **Title-LG** or **Headline-MD** styles to ensure the characters are the primary focus of the session screen.

## Layout & Spacing
The design system employs a **Fluid Grid** model optimized for mobile-first interaction but scaling gracefully to desktop. The layout rhythm is based on a 4px baseline, with most components using **12px or 16px gaps** to maintain a clean, airy feel consistent with the Material 3 influence.

**Breakpoints & Reflow:**
- **Mobile (<600px):** Single column layout. Piano keys are horizontally scrollable or stacked depending on orientation. Margins are fixed at 16px.
- **Tablet (600px - 1024px):** 8-column grid. Information cards (SRS stats) can sit side-by-side with the primary game area.
- **Desktop (>1024px):** 12-column grid. The layout centers the primary interaction zone within a max-width container (approx. 1200px) to prevent excessive eye scanning.

**Interaction Targets:**
Every interactive element must maintain a minimum touch target of **48x48dp**. On the piano keyboard, key widths should be prioritized to ensure precision selection, especially on smaller mobile devices.

## Elevation & Depth
In alignment with the "Harmonic Precision" theme, hierarchy is established through **Tonal Layers** and **Low-Contrast Outlines** rather than heavy shadows. This creates a flat, professional "Sheet Music" aesthetic.

- **Surfaces:** The primary background uses the neutral base. Cards and containers use a slightly lighter or darker tint (Primary-Container) to create separation.
- **Outlines:** Instead of shadows, UI elements (Cards, Input Fields, Piano Keys) use a 1px border using an `outlineVariant` (a subtle, low-opacity version of the primary or neutral-mid tone).
- **Active State:** When an element is focused or selected (Selection Amber), the border weight may increase to 2px to provide clear visual feedback without needing elevation shifts.
- **Shadows:** Restricted to temporary floating elements like Snackbars or Bottom Sheets, using very soft, low-opacity (10-15%) ambient shadows.

## Shapes
The shape language is defined by a consistent **12px (0.75rem)** corner radius for all primary components (Buttons, Cards, and Modals). This level of roundedness balances the professional nature of the app with an approachable, modern feel.

- **Standard Components:** 12px (Rounded).
- **Small Components (Chips/Tags):** Can use the same 12px radius or a full pill-shape if used for categorical labels.
- **Piano Keys:** The bottom of the keys should remain sharp (0px) or slightly rounded (4px) to mimic physical piano key geometry, while the overall keyboard container adheres to the 12px system standard.

## Components
Consistent component styling ensures the training loop remains predictable and efficient.

- **Buttons:** 
  - Primary: Filled with `#6A1B9A`, white text, 12px radius, min-height 48px.
  - Secondary: Outlined with 1px `outlineVariant`, primary text.
- **Piano Keyboard:**
  - The most critical component. Natural keys use `piano-white` and sharps use `piano-black`. 
  - Selection state: Amber border (2px) or slight Amber tint.
  - Feedback state: Green (correct) or Red (incorrect) flash/fill upon confirmation.
- **Cards (Result/SRS):**
  - Use 12px roundedness and a 1px outline border. 
  - Use internal padding of 16px. 
  - Display SRS changes (e.g., "Next review: 3 days") using **Label-MD** in a subtle tertiary color.
- **Input Fields:**
  - For text-based note entry, use the Material 3 "Outlined" style with a 12px radius. The label should float on the border when active.
- **Chips:**
  - Used for game mode selection or filtering. Use a 12px radius and clear icons (e.g., single note icon, chord icon).
- **Progress Bars:**
  - Linear, thin (4px-8px height), using the Primary color for the progress and a light Tertiary for the track.