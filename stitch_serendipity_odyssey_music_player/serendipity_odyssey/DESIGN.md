---
name: Serendipity Odyssey
colors:
  surface: '#131318'
  surface-dim: '#131318'
  surface-bright: '#39383e'
  surface-container-lowest: '#0e0e13'
  surface-container-low: '#1b1b20'
  surface-container: '#1f1f25'
  surface-container-high: '#2a292f'
  surface-container-highest: '#35343a'
  on-surface: '#e4e1e9'
  on-surface-variant: '#e2bfb3'
  inverse-surface: '#e4e1e9'
  inverse-on-surface: '#303036'
  outline: '#a98a7f'
  outline-variant: '#594139'
  surface-tint: '#ffb59a'
  primary: '#ffb59a'
  on-primary: '#5b1b00'
  primary-container: '#ff6b2c'
  on-primary-container: '#5c1c00'
  inverse-primary: '#a83900'
  secondary: '#edc157'
  on-secondary: '#3f2e00'
  secondary-container: '#906d00'
  on-secondary-container: '#fff7ee'
  tertiary: '#00dbe9'
  on-tertiary: '#00363a'
  tertiary-container: '#00aab5'
  on-tertiary-container: '#00383c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59a'
  on-primary-fixed: '#380d00'
  on-primary-fixed-variant: '#802900'
  secondary-fixed: '#ffdf9b'
  secondary-fixed-dim: '#edc157'
  on-secondary-fixed: '#251a00'
  on-secondary-fixed-variant: '#5b4300'
  tertiary-fixed: '#7df4ff'
  tertiary-fixed-dim: '#00dbe9'
  on-tertiary-fixed: '#002022'
  on-tertiary-fixed-variant: '#004f54'
  background: '#131318'
  on-background: '#e4e1e9'
  surface-variant: '#35343a'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-mono-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.04em
  label-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.06em
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.08em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1.25rem
  margin-tablet: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.25rem
---

## Brand & Style
The design system establishes a cyber-dark, cosmic audio atmosphere engineered for deep immersion, auditory exploration, and high-fidelity interaction. It targets electronic music lovers, audiophiles, and digital natives who view music not merely as background noise, but as a sensory odyssey. 

The aesthetic blends **Glassmorphism** with **Cyber-Futurism**:
- Deep void backdrops mimic deep space, allowing soundwaves and primary interactive controls to beam outward like optical anomalies.
- Translucent frosted glass substrates provide tactical depth without cluttering the screen.
- Neon photonic glows (electric neon orange and cyber cyan) guide the user's thumb instinctually across HUD-inspired interfaces and floating glass decks.
- Interactions evoke a tactile interstellar flight cockpit—ultra-smooth, responsive, and bathed in ambient radiation.

## Colors
The palette leverages high-contrast luminescence across a pitch-black cosmic canvas to direct visual hierarchy in low-light listening environments:

- **Primary (`#FF6B2C` - Radiant Electric Orange):** The primary pulse of the application. Dictates audio playback triggers, active scrub heads, high-priority actions, and vibrant aura glows (`rgba(255, 107, 44, 0.4)`).
- **Secondary (`#FFD166` - Celestial Gold):** Reserved for VIP badges, stellar curation stamps, high-fidelity status, and playlist achievements.
- **Tertiary (`#00F0FF` - Neon Cyan):** Signals live frequency metrics, lossless audio tags (FLAC/DSD), live party listeners, and BPM sync meters.
- **Support Warning/Amber (`#FFAA00`):** Buffer alerts, dynamic EQ peaks, and network drops.
- **Deep Void Surfaces:**
  - Base Background Canvas: `#0A0A0F`
  - Elevated Container / Secondary Void: `#12121A`
  - Glass Card Substrates: `rgba(28, 28, 40, 0.75)` with `1px` stroke of `rgba(255, 255, 255, 0.08)`
- **Typography Scale:**
  - Primary Text: `#FFFFFF` (High contrast, luminous)
  - Secondary Text: `#9E9EB2` (Muted lilac slate)
  - Ghost / Inactive / Dividers: `#6B6B80`

## Typography
The system employs a dual-typeface strategy to bridge organic melody and precision telemetry:

1. **Plus Jakarta Sans (Headlines, Body, Display):** A modern, geometric grotesque with wide apertures and pristine legibility against dark visual planes. It conveys refined warmth and energy.
2. **JetBrains Mono (Technical HUD, Telemetry, Metadata):** Utilized for timestamps, time remaining, audio bitrates (e.g., `24-bit / 96kHz`), BPM indicators, harmonic keys, and spectrum visualizer tags.

### Typographic Hierarchy Rules
- Track titles use `headline-lg` on the Now Playing screen, scaling down to `headline-sm` inside playlist rows.
- Artist credentials and secondary metadata use `body-md` in `#9E9EB2`.
- Audio fidelity chips and technical indicators must exclusively render in uppercase using `label-mono-sm` or `label-caps`.

## Layout & Spacing
The layout relies on a mobile-first fluid grid optimized for thumb-driven reachability and spatial depth:

- **Mobile Viewports (<600px):** 4-column fluid layout with an edge canvas margin of `1.25rem` (`20px`) and column gutters of `1rem` (`16px`). Touch targets adhere to a minimum envelope of `48px` height/width.
- **Tablet / Large Handhelds (600px–1024px):** 8-column layout with `2rem` (`32px`) margins and `1.5rem` (`24px`) gutters, allowing split-pane views (album artwork pinned left, queue and lyrics pinned right).
- **Vertical Spacing Rhythm:** Component interiors utilize `space-sm` (`8px`) and `space-md` (`16px`) for structural separation. Large sectional modules (e.g., between the equalizer visualizer and track controls) consume `space-xl` (`36px`).
- **Safe Area Bottom Clears:** All primary scroll views require an artificial bottom inset of `100px` to float clean above the suspended HUD navigation dock.

## Elevation & Depth
Depth is created through ambient back-lighting, translucent glass refractions, and optical glow states rather than traditional muddy drop shadows:

- **Level 0 (Canvas Void):** `#0A0A0F`, infinite ground.
- **Level 1 (Sub-surface Deck):** `#12121A` solid panels with 1px hairline border `rgba(255, 255, 255, 0.05)`.
- **Level 2 (Nebula Frosted Glass):** Background fill `rgba(28, 28, 40, 0.75)`, integrated backdrop blur `24px`, saturation boost `180%`, and an outer border of `rgba(255, 255, 255, 0.08)`.
- **Level 3 (Floating HUD / Modals):** Background fill `rgba(22, 22, 34, 0.88)`, backdrop blur `32px`, paired with a deep ambient shadow: `0 16px 40px rgba(0, 0, 0, 0.6)`.
- **Level 4 (Photonic Glow / Active Playback):** Solid `#FF6B2C` accents layered with dual radial glows: `box-shadow: 0 0 20px rgba(255, 107, 44, 0.45), 0 0 40px rgba(255, 107, 44, 0.15)`.
- **Level 4 Cyan (Telemetry Focus):** Solid `#00F0FF` tags coupled with `box-shadow: 0 0 16px rgba(0, 240, 255, 0.4)`.

## Shapes
The shape language is aerodynamic, rounded, and tactile:

- **Radius Tokens:**
  - Base Elements & Small Cards: `1rem` (`16px`).
  - Standard Glass Containers & Album Art: `1.25rem`–`1.5rem` (`20px` to `24px`).
  - Feature Banners & Now Playing Drawer: `2rem` (`32px`).
  - Interactive Chips, Badges, Sliders, and Floating Dock: Full Pill (`9999px`).
- **Surface Borders:** All borders use an interior gradient stroke effect: `1px solid rgba(255, 255, 255, 0.08)` along the top and sides, softly tapering to `rgba(255, 255, 255, 0.02)` at the base to emulate top-down rim lighting.

## Components

### Buttons & Interactive Triggers
- **Hero Play / Lightning Trigger:** A floating circular element (`64px` diameter) filled with `#FF6B2C` featuring a sharp white playback glyph. Emits a continuous subtle pulse glow (`box-shadow: 0 0 24px rgba(255, 107, 44, 0.45)`). Scales down by 4% on press.
- **Glass Action Buttons:** Pill-shaped, `44px` height, `rgba(255, 255, 255, 0.06)` background, `rgba(255, 255, 255, 0.12)` border, text in `#FFFFFF`. Hover/focus injects a soft orange border tint (`rgba(255, 107, 44, 0.5)`).

### Floating HUD Navigation
- Suspended `24px` above the bottom screen safe area.
- Enclosed within an ultra-rounded glass pill (`backdrop-filter: blur(28px); background: rgba(20, 20, 30, 0.8)`).
- Features five navigational zones: Explore, Radio, Odyssey Flow (raised lightning action pill in center), Library, and Audio Profile.
- Active states illuminate with an orange under-glow dot (`#FF6B2C`) and white icons, while inactive icons sit in `#6B6B80`.

### Chips & Telemetry Tags
- **Hi-Fi / Lossless Audio Tags:** Pill containers with height `22px`, horizontal padding `8px`, background `rgba(0, 240, 255, 0.1)`, text in `#00F0FF`, rendered in `label-mono-sm`.
- **Genre & Filter Chips:** Pill containers with height `36px`, `rgba(255, 255, 255, 0.05)` fill, `12px` font size. Selected state flips fill to `#FF6B2C` with black text (`#0A0A0F`) and active glow.

### Track Lists & Queues
- **List Item Rows:** Height `68px`, transparent default surface.
- **Artwork Thumbnail:** `48px` square with `12px` roundedness.
- **Active Track State:** Background transitions to `rgba(255, 107, 44, 0.08)` with a 3px vertical `#FF6B2C` indicator bar hugging the left edge. Track title illuminates to `#FF6B2C`, accompanied by animated mini-spectrum equalizer bars.

### Audio Scrubber & Equalizer Sliders
- **Track Rail:** `4px` height, filled with `rgba(255, 255, 255, 0.1)`.
- **Elapsed Track Fill:** Linear gradient from `#FFD166` to `#FF6B2C`.
- **Scrub Thumb:** `16px` white circle with `#FF6B2C` center pip and `0 0 12px rgba(255, 107, 44, 0.6)` glow shadow. Expands to `20px` during scrub gesture.

### Cards & Media Panels
- **Album / Mix Card:** Frosted nebula glass body, `20px` border radius, padding `12px`. Artwork fills top area with an internal `14px` border radius. Glass bottom holds title, artist, and floating telemetry pill (`BPM / KEY`).