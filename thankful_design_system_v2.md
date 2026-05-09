# Thankful — Design System v2.0
# Status: LOCKED

## Philosophy
Meditative, calm, hopeful, thankful. Every screen should feel like a quiet
morning — warm light, unhurried, personal. No gradients. No shadows. No noise.
Warmth comes from the palette. Energy comes from restraint.

---

## 1. Colour System — LOCKED

### Core Palette
| Token | Hex | Flutter | Usage |
|---|---|---|---|
| `color-bg` | `#FAFAF8` | `0xFFFAFAF8` | App background — every screen |
| `color-surface` | `#F0EDE6` | `0xFFF0EDE6` | Cards, inputs, bottom sheets |
| `color-surface-raised` | `#E8E4DC` | `0xFFE8E4DC` | Elevated cards, selected states |
| `color-primary` | `#5E9A78` | `0xFF5E9A78` | Navigation, icons, progress rings |
| `color-cta` | `#E09050` | `0xFFE09050` | Primary buttons only |
| `color-accent-violet` | `#7B6FA8` | `0xFF7B6FA8` | Reflect button, milestone accents |
| `color-text-primary` | `#2C2416` | `0xFF2C2416` | Headlines, app name, CTA labels |
| `color-text-journal` | `#5C4A3A` | `0xFF5C4A3A` | Journal entry body text only |
| `color-text-secondary` | `#7A7060` | `0xFF7A7060` | Labels, dates, metadata |
| `color-text-tertiary` | `#A89E8E` | `0xFFA89E8E` | Placeholders, disabled states |
| `color-streak` | `#E09050` | `0xFFE09050` | Streak numbers (same as CTA) |
| `color-error` | `#C0392B` | `0xFFC0392B` | Error states only |

### Mascot Colours — UI USE FORBIDDEN
| Token | Hex | Usage |
|---|---|---|
| `color-monk-maroon` | `#6B2D2D` | Monk robes — mascot asset only |
| `color-monk-glasses` | `#E8940A` | Monk glasses frames — mascot asset only |

### Colour Rules
- `#FAFAF8` background is used on EVERY screen without exception
- Never use pure white `#FFFFFF` or pure black `#000000` anywhere
- No gradients of any kind — LinearGradient, RadialGradient, SweepGradient
- No BoxShadow or drop shadows anywhere
- No semi-transparent overlays except paywall blur effect
- Monk maroon and monk glasses are mascot-only — never apply to UI elements
- Maximum 3 colours visible on any single screen at once
- CTA apricot `#E09050` and violet `#7B6FA8` never appear on same screen

---

## 2. Typography — LOCKED

### Font Family
**Figtree** — all text, all weights, all screens
Flutter package: `google_fonts: ^6.0.0` → `GoogleFonts.figtree()`

### Type Scale
| Token | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `text-display` | 28px | 500 | 1.2 | Hero headlines, onboarding |
| `text-heading-1` | 22px | 500 | 1.25 | Screen titles, USP headlines |
| `text-heading-2` | 19px | 500 | 1.3 | Section headers |
| `text-heading-3` | 16px | 500 | 1.4 | Card titles, sub-sections |
| `text-body` | 15px | 400 | 1.6 | Body copy |
| `text-body-medium` | 15px | 500 | 1.6 | Emphasis within body |
| `text-journal` | 15px | 400 | 1.7 | Journal entry text (colour: #5C4A3A) |
| `text-caption` | 13px | 400 | 1.5 | Labels, dates, metadata |
| `text-caption-medium` | 13px | 500 | 1.5 | Active labels, badges |
| `text-micro` | 11px | 400 | 1.4 | Legal, fine print only |

### Typography Rules
- Only two weights: **400 regular** and **500 medium** — never 600, 700, bold
- Never use italic or underline (except hyperlinks in legal text)
- Sentence case always — never ALL CAPS, never Title Case
- Minimum font size: 11px — never smaller
- Text colour always from colour system — never hardcoded

### Two-tone Headline Pattern (Sign up, onboarding)
Line 1: `text-heading-1`, `color-text-primary` (#2C2416)
Line 2: `text-heading-1`, `color-primary` (#5E9A78)
Same font, same size, same weight — colour change only

---

## 3. Spacing System — LOCKED

Base unit: **6px**

| Token | Value | Usage |
|---|---|---|
| `space-xs` | 6px | Icon padding, tight internal gaps |
| `space-sm` | 12px | Between related elements |
| `space-md` | 18px | Standard padding, list item gaps |
| `space-lg` | 24px | Section separation |
| `space-xl` | 36px | Screen section breaks |
| `space-2xl` | 48px | Hero spacing |
| `space-screen-h` | 22px | Horizontal screen padding (both sides) |
| `space-screen-top` | 12px | Below status bar |
| `space-screen-bottom` | 24px | Above home indicator |

### Spacing Rules
- All values must be multiples of 6
- Never use values not in the scale (5px, 7px, 11px etc.)
- Safe area insets always respected on top of space-screen-bottom

---

## 4. Border Radius — LOCKED

| Token | Value | Usage |
|---|---|---|
| `radius-sm` | 8px | Chips, tags, small badges |
| `radius-md` | 12px | Input fields, small cards |
| `radius-lg` | 16px | Standard cards |
| `radius-xl` | 24px | Large cards, bottom sheets |
| `radius-full` | 100px | All buttons — always |
| `radius-circle` | 50% | Avatar containers only |

### Radius Rules
- All primary and secondary buttons always use `radius-full` (100px)
- Cards always use `radius-lg` (16px)
- Input fields always use `radius-md` (12px)
- Never mix radius values on same component
- No radius on dividers or list separators

---

## 5. Component Specifications — LOCKED

### Primary Button
```
Height:           52px
Border radius:    100px
Background:       #E09050
Text:             Figtree 15px 500 #FAFAF8
Padding:          0 24px
Width:            stretch (full width minus screen padding)
Pressed state:    opacity 0.82
Disabled:         background #F0EDE6, text #A89E8E
No border, no shadow, no gradient
```

### Secondary Button
```
Height:           52px
Border radius:    100px
Background:       transparent
Border:           1.5px solid #5E9A78
Text:             Figtree 15px 500 #5E9A78
Pressed state:    background #F0EDE6
```

### Text / Link Button
```
No container
Text:             Figtree 15px 400 #5E9A78
No underline in app (underline only in legal text)
Pressed state:    opacity 0.65
```

### Auth Button (sign up screen only)
```
Height:           44px
Border radius:    100px
Background:       #F0EDE6
Text:             Figtree 13px 400 #2C2416
Icon:             18px circle, left-aligned
Pressed state:    background #E8E4DC
Full width
```

### Card
```
Background:       #F0EDE6
Border radius:    16px
Padding:          16px
No border, no shadow
```

### Session Prompt Card (home screen)
```
Background:       #5E9A78
Border radius:    16px
Padding:          14px 16px
Label:            Figtree 10px 500 #FAFAF8 opacity 0.75
Headline:         Figtree 14px 500 #FAFAF8
Inner CTA:        background #FAFAF8, text #5E9A78, radius 100px, height 30px
```

### Input Field
```
Height:           52px
Background:       #F0EDE6
Border radius:    12px
Border:           none (default) / 1.5px solid #5E9A78 (focused)
Text:             Figtree 15px 400 #2C2416
Placeholder:      #A89E8E
Padding:          0 16px
No shadow
```

### Journal Entry Card
```
Background:       #F0EDE6
Border radius:    12px
Padding:          12px 14px
Date label:       Figtree 10px 400 #A89E8E
Entry text:       Figtree 13px 400 #5C4A3A (journal text colour)
Divider:          0.5px #E8E4DC
Metadata row:     Figtree 10px 400 #5E9A78 (type) + #A89E8E (time)
```

### Streak Stat Card
```
Background:       #F0EDE6 (or #FFFFFF with 0.5px #EAE4D9 border on white bg screens)
Border radius:    10px
Padding:          8px 10px
Number:           Figtree 16px 500 — #E09050 (streak) / #5E9A78 (entries) / #7B6FA8 (week)
Label:            Figtree 9px 400 #7A7060
```

### Bottom Navigation
```
Background:       #FAFAF8
Height:           60px + safe area
Border top:       0.5px solid #F0EDE6
Icon size:        24px (Lucide outline only)
Active colour:    #5E9A78
Inactive colour:  #A89E8E
Label:            Figtree 11px 500
Active label:     #5E9A78
Inactive label:   #A89E8E
No shadow, no elevation
```

### Tag / Chip
```
Height:           28px
Background:       #F0EDE6
Border radius:    100px
Text:             Figtree 13px 400 #7A7060
Padding:          0 12px
Active:           background #5E9A78, text #FAFAF8
```

### Divider
```
Height:           0.5px
Colour:           #F0EDE6
Full width
Vertical margin:  18px
No border radius
```

---

## 6. Iconography — LOCKED

**Lucide Icons** — outline style only, never filled
Sizes: 24px standard / 20px compact / 16px inline

Rules:
- Outline only — never use filled variants
- Active: `#5E9A78`
- Inactive: `#A89E8E`
- Destructive: `#C0392B`
- Never icon without label in navigation
- Never mix icon libraries

---

## 7. Mascot — LOCKED

### Character
Young monk, round gold glasses (#E8940A frames), maroon robes (#6B2D2D),
eyes always closed. Figtree-adjacent warmth in illustration style.

### Asset Files
| File | Pose | Screen |
|---|---|---|
| `monk_namaste.png` | Standing namaste | Sign up screen |
| `monk_meditation.png` | Sitting, hands in lap | Home, paywall, idle |
| `monk_writing.png` | Sitting, writing in journal | Entry review |
| `monk_milestone.png` | Sitting, warm glow | Streak milestone |
| `monk_bowed.png` | Sitting, head slightly bowed | Streak broken |

### Placement Rules
| Screen | Placement | Size | Crop |
|---|---|---|---|
| Splash / launch | Centered, large | 92% screen width | Bottom cropped by safe area |
| Sign up | Bottom right corner | ~55% screen width | Right and bottom edges cropped |
| Paywall | Bottom right corner | ~45% screen width | Right and bottom edges cropped |
| Home | Bottom right corner | ~50% screen width | Right and bottom edges cropped |
| Voice session | Centered | ~70% screen width | None — full figure |
| Entry review | Bottom right, writing | ~50% screen width | Right edge cropped |
| Milestone | Centered, full reveal | 80% screen width | None |

### Mascot Rules
- Transparent PNG only — no white background box
- mix-blend-mode: multiply if PNG background not removed
- Never add border, shadow, or container around mascot
- Never resize below 44px (glasses become unreadable)
- Never overlap primary CTAs
- Entry animation: fade + 8px upward drift, 600ms ease-out, first appearance only

---

## 8. Voice Session Screen — LOCKED

### Session States
| State | Monk | Text | Waveform |
|---|---|---|---|
| Bot speaking | Centered, still | Prompt text above, muted | Hidden |
| User speaking | Centered, still | "Listening..." above | Visible, animated |
| Processing | Centered, still | Subtle spinner | Hidden |
| Session complete | Centered, slight glow | "Almost done..." | Hidden |

### Waveform Spec
```
Bar colour active:   #5E9A78
Bar colour inactive: #F0EDE6
Bar width:           3px
Bar gap:             4px
Bar border radius:   2px
Height range:        8px min / 32px max
Bars:                14 bars total
Animation:           smooth height transition 120ms ease
```

### Session Controls
```
End session button:  Bottom center
                     44px circle
                     Background: #F0EDE6
                     Icon: square/stop, 18px, #7A7060
                     No label
```

---

## 9. Animation Rules — LOCKED

| Animation | Duration | Curve | Usage |
|---|---|---|---|
| Screen entry | 280ms | ease out | New screen push |
| Mascot entry | 600ms | ease out | First appearance only |
| Button press | 100ms | ease in | Opacity to 0.82 |
| Card press | 150ms | ease in | Scale to 0.98 |
| Streak idle pulse | 2000ms | ease in out | Home screen loop on streak number |
| Waveform bars | 120ms | ease | Voice session |

### Animation Rules
- No bounce, spring, or elastic curves anywhere
- No rotation animations
- No particle effects or confetti
- Mascot entry animation: first appearance only, never on revisit
- Never animate more than one element simultaneously
- All animations must be interruptible
- Maximum animation duration: 600ms

---

## 10. Screen Layout — LOCKED

### Standard Screen Template
```
StatusBar (system)
├── space-screen-top (12px below status bar)
├── Screen content
│   ├── Horizontal padding: 22px both sides
│   └── Content fills available height
├── Mascot (if applicable — bottom corner, partially cropped)
└── Primary CTA area
    ├── Bottom padding: 24px + safe area
    └── Horizontal padding: 22px
```

### CTA Pinning Rules
- Primary button always pinned to bottom
- Never floating mid-screen
- Always full width minus 22px horizontal padding
- 24px between button bottom and safe area

### Content Hierarchy Per Screen
- Maximum one display-size headline per screen
- Maximum two heading-level elements per screen
- Never more than 3 font sizes on a single screen

---

## 11. Flutter Implementation

### app_colors.dart
```dart
import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background    = Color(0xFFFAFAF8);
  static const Color surface       = Color(0xFFF0EDE6);
  static const Color surfaceRaised = Color(0xFFE8E4DC);

  // Brand
  static const Color primary       = Color(0xFF5E9A78);
  static const Color cta           = Color(0xFFE09050);
  static const Color accent        = Color(0xFF7B6FA8);
  static const Color streak        = Color(0xFFE09050);

  // Text
  static const Color textPrimary   = Color(0xFF2C2416);
  static const Color textJournal   = Color(0xFF5C4A3A);
  static const Color textSecondary = Color(0xFF7A7060);
  static const Color textTertiary  = Color(0xFFA89E8E);

  // System
  static const Color error         = Color(0xFFC0392B);

  // Mascot only — never apply to UI
  static const Color monkMaroon    = Color(0xFF6B2D2D);
  static const Color monkGlasses   = Color(0xFFE8940A);
}
```

### app_spacing.dart
```dart
class AppSpacing {
  static const double xs         = 6.0;
  static const double sm         = 12.0;
  static const double md         = 18.0;
  static const double lg         = 24.0;
  static const double xl         = 36.0;
  static const double xxl        = 48.0;
  static const double screenH    = 22.0;
  static const double screenTop  = 12.0;
  static const double screenBot  = 24.0;
}
```

### app_radius.dart
```dart
class AppRadius {
  static const double sm     = 8.0;
  static const double md     = 12.0;
  static const double lg     = 16.0;
  static const double xl     = 24.0;
  static const double full   = 100.0;
}
```

### app_text_styles.dart
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle display = GoogleFonts.figtree(
    fontSize: 28, fontWeight: FontWeight.w500,
    height: 1.2, color: AppColors.textPrimary);

  static TextStyle heading1 = GoogleFonts.figtree(
    fontSize: 22, fontWeight: FontWeight.w500,
    height: 1.25, color: AppColors.textPrimary);

  static TextStyle heading2 = GoogleFonts.figtree(
    fontSize: 19, fontWeight: FontWeight.w500,
    height: 1.3, color: AppColors.textPrimary);

  static TextStyle heading3 = GoogleFonts.figtree(
    fontSize: 16, fontWeight: FontWeight.w500,
    height: 1.4, color: AppColors.textPrimary);

  static TextStyle body = GoogleFonts.figtree(
    fontSize: 15, fontWeight: FontWeight.w400,
    height: 1.6, color: AppColors.textPrimary);

  static TextStyle bodyMedium = GoogleFonts.figtree(
    fontSize: 15, fontWeight: FontWeight.w500,
    height: 1.6, color: AppColors.textPrimary);

  static TextStyle journal = GoogleFonts.figtree(
    fontSize: 15, fontWeight: FontWeight.w400,
    height: 1.7, color: AppColors.textJournal);

  static TextStyle caption = GoogleFonts.figtree(
    fontSize: 13, fontWeight: FontWeight.w400,
    height: 1.5, color: AppColors.textSecondary);

  static TextStyle captionMedium = GoogleFonts.figtree(
    fontSize: 13, fontWeight: FontWeight.w500,
    height: 1.5, color: AppColors.textSecondary);

  static TextStyle micro = GoogleFonts.figtree(
    fontSize: 11, fontWeight: FontWeight.w400,
    height: 1.4, color: AppColors.textTertiary);
}
```

---

## 12. CLAUDE.md Additions

Add these to your project CLAUDE.md under design system:

```
## Design system — LOCKED v2.0
Palette: Warm White
Font: Figtree (weights w400 and w500 only — NEVER w600 or w700)

Background:     #FAFAF8   0xFFFAFAF8
Surface:        #F0EDE6   0xFFF0EDE6
Primary:        #5E9A78   0xFF5E9A78
CTA:            #E09050   0xFFE09050
Accent violet:  #7B6FA8   0xFF7B6FA8
Text primary:   #2C2416   0xFF2C2416
Text journal:   #5C4A3A   0xFF5C4A3A
Text secondary: #7A7060   0xFF7A7060
Text tertiary:  #A89E8E   0xFFA89E8E
Error:          #C0392B   0xFFC0392B

FORBIDDEN: gradients, shadows, pure white, pure black,
           font weights other than 400/500, all caps text,
           monk colours on UI elements
```

---

## 13. Changelog

| Version | Date | Changes |
|---|---|---|
| v1.0 | Initial | Sage & Stone palette, Plus Jakarta Sans |
| v2.0 | Locked | Warm White palette, Figtree font, lighter sage #5E9A78, apricot CTA #E09050, violet accent #7B6FA8, journal text colour #5C4A3A |
