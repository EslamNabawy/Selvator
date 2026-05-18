# Design System Document

## 1. Overview & Creative North Star: "The Living Sanctuary"

This design system is built upon the concept of **"The Living Sanctuary."** Unlike traditional utility-first frameworks that rely on rigid grids and harsh dividers, this system prioritizes emotional resonance and atmospheric depth. We are moving away from the "app-as-a-tool" aesthetic toward an "app-as-an-environment."

### The Creative North Star
Our goal is to create a digital space that feels breathable, organic, and responsive. We achieve this through:
- **Intentional Asymmetry:** Breaking the vertical "stack" by shifting elements slightly off-center or using varied card widths to mimic natural, non-linear thought.
- **Tonal Transitions:** Replacing borders with light-and-shadow physics.
- **Organic Motion:** Using the "Blob" character as a fluid anchor that bridges the gap between the interface and the user’s emotional state.

---

## 2. Colors & Atmospheric Logic

The palette is not just a set of hex codes; it is a system of "Emotional Latitudes." We utilize Material Design token logic but apply it through an editorial lens.

### Core Mood Spectrum
Each mood occupies a specific tonal range. Use these for high-impact moments (Hero backgrounds, Character states, Primary CTAs).
- **Happy (Yellow/Orange):** `primary` (#7f5200) & `primary_container` (#feb64c)
- **Calm (Blue/Teal):** `secondary` (#006760) & `secondary_container` (#7fe6db)
- **Love (Pink/Red):** `tertiary` (#a7295a) & `tertiary_container` (#ff8eaf)
- **Other Moods:** Map to these families using the same logic—vibrant parent, soft child.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to section content. 
- Boundaries must be defined by **Background Color Shifts**. For example, a `surface_container_low` card sitting on a `surface` background provides all the definition needed.
- **The Glass & Gradient Rule:** To move beyond a "standard" feel, use semi-transparent surface colors with a `backdrop-blur` of 20px–40px. This allows the mood colors to bleed into the UI, making the interface feel like it’s floating in a colored atmosphere.

### Signature Textures
Avoid flat backgrounds. Use a subtle linear gradient (e.g., `primary` to `primary_container` at 15% opacity) for hero sections to give the UI "soul."

---

## 3. Typography: Editorial Sophistication

We pair **Plus Jakarta Sans** for expression and **Inter** for utility. The contrast in x-heights and geometric structures creates a high-end editorial feel.

| Level | Token | Font | Size | Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Plus Jakarta Sans | 3.5rem | Emotive, large-scale declarations. |
| **Headline** | `headline-md` | Plus Jakarta Sans | 1.75rem | Section entry points. |
| **Title** | `title-lg` | Inter | 1.375rem | Component headers and card titles. |
| **Body** | `body-lg` | Inter | 1rem | Standard reading text (High legibility). |
| **Label** | `label-md` | Inter | 0.75rem | Metadata and sub-mood chips. |

**Styling Note:** Use `title-lg` for most user-facing questions. It feels personal and direct, whereas `display` should be reserved for state-based feedback (e.g., "Good morning").

---

## 4. Elevation & Depth: Tonal Layering

We discard traditional drop shadows in favor of **Tonal Layering** and **Ambient Glows.**

- **The Layering Principle:** Stacking follows the natural light of the "Sanctuary." 
    - Base: `surface`
    - Content Section: `surface_container_low`
    - Floating Interactive Card: `surface_container_lowest` (White)
- **Ambient Shadows:** Shadows should never be gray. Use the `on_surface` color at 4% opacity with a blur of 40px and a Y-offset of 10px. This creates a "lift" rather than a "drop."
- **The "Ghost Border" Fallback:** If accessibility requires a border, use `outline_variant` at 15% opacity. Never use a 100% opaque border.

---

## 5. Components & Character

### The Organic Character (The Blob)
The character is the heartbeat of the system.
- **Forms:** Use `xl` (3rem) or `full` roundedness for the character container. 
- **Behavior:** The character should overlap container boundaries. For example, the character's "head" might break the top edge of a card, creating a 3D effect.
- **Interaction:** On hover or tap, the character should transition with a `cubic-bezier(0.34, 1.56, 0.64, 1)` easing (a soft "bounce").

### Mood Chips
- **Core Moods:** Use `primary_container` or `secondary_container` with full opacity.
- **Sub-moods:** These are "Nested Chips." Use the same family but at 40% opacity, placed inside or adjacent to the parent. They should appear "faded" to represent a nuance of the core emotion.

### Buttons & Fields
- **Primary Button:** Large `xl` corner radius. Use a gradient of `primary` to `primary_dim`. No shadow.
- **Input Fields:** Use `surface_container_high` as the fill. On focus, do not change the border; instead, shift the background to `surface_container_lowest` and add a subtle ambient glow of the current mood color.
- **Cards & Lists:** **Forbidden:** Divider lines. Use a 24px vertical gap (`Spacing Scale`) or a slight shift from `surface_container_low` to `surface_container_highest` to denote a new item.

---

## 6. Do's and Don'ts

### Do
- **Do** use overlapping elements. Let the character or a glass container bleed over the edge of a section.
- **Do** use `backdrop-filter: blur()` on all floating modals.
- **Do** use "Plus Jakarta Sans" for all numerical data to give it a premium, designed look.
- **Do** allow for significant "negative space." If in doubt, add 16px of extra padding.

### Don't
- **Don't** use pure black (#000000). Use `on_surface` (#2c2f30) for text to maintain a soft, organic feel.
- **Don't** use standard Material "elevations" (1dp, 2dp). Use the Surface Hierarchy tiers instead.
- **Don't** use 90-degree corners. Even the sharpest element should have at least a `sm` (0.5rem) radius.
- **Don't** use "Alert Red" for errors unless critical. Use the `error` token (#b41340) which is slightly muted to fit the "Sanctuary" vibe.