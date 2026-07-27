---
name: Organic Utility
colors:
  surface: '#f8fbee'
  surface-dim: '#d8dbd0'
  surface-bright: '#f8fbee'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f5e9'
  surface-container: '#ecefe3'
  surface-container-high: '#e6eadd'
  surface-container-highest: '#e1e4d8'
  on-surface: '#191d16'
  on-surface-variant: '#43493c'
  inverse-surface: '#2e322a'
  inverse-on-surface: '#eff2e6'
  outline: '#74796b'
  outline-variant: '#c3c9b8'
  surface-tint: '#446822'
  primary: '#395c16'
  on-primary: '#ffffff'
  primary-container: '#50752d'
  on-primary-container: '#cefaa2'
  inverse-primary: '#a9d37f'
  secondary: '#5f5e61'
  on-secondary: '#ffffff'
  secondary-container: '#e4e2e5'
  on-secondary-container: '#656467'
  tertiary: '#a11d24'
  on-tertiary: '#ffffff'
  tertiary-container: '#c33739'
  on-tertiary-container: '#ffe7e5'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c4f099'
  primary-fixed-dim: '#a9d37f'
  on-primary-fixed: '#0d2000'
  on-primary-fixed-variant: '#2d4f0a'
  secondary-fixed: '#e4e2e5'
  secondary-fixed-dim: '#c8c6c9'
  on-secondary-fixed: '#1b1b1e'
  on-secondary-fixed-variant: '#474649'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ae'
  on-tertiary-fixed: '#410005'
  on-tertiary-fixed-variant: '#8f0d19'
  background: '#f8fbee'
  on-background: '#191d16'
  surface-variant: '#e1e4d8'
typography:
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 16px
  margin-mobile: 20px
  margin-desktop: auto
---

## Brand & Style

This design system is built on a foundation of **Modern Minimalism** with a **Corporate** focus on reliability. Designed specifically for a service marketplace, the aesthetic balances the ruggedness of home services with the precision of a high-end SaaS platform.

The personality is professional, dependable, and approachable. It uses generous whitespace to reduce cognitive load in a data-heavy marketplace environment. The visual mood is "Clean & Competent," utilizing high-quality typography and a restricted color palette to evoke trust between service providers and customers.

## Colors

The palette is derived from natural, earthy tones to signify growth and stability.

- **Primary:** A deep, mossy green (#50752D) used for key branding elements, primary actions, and success states.
- **Secondary:** A soft, warm-tinted off-white (#F9F6F9) used for background surfaces to soften the overall UI compared to pure white.
- **Tertiary:** A muted red (#D64545) reserved exclusively for destructive actions or "Cancelled" statuses.
- **Neutral:** A dark charcoal with green undertones (#2D3129) used for primary text to ensure high legibility while maintaining a softer contrast than pure black.

## Typography

The design system utilizes **Manrope** for all roles. Its modern, geometric construction provides the "clean" aesthetic required for a professional marketplace while remaining highly legible at small sizes.

Headlines use tighter letter spacing and heavier weights to create a strong visual anchor. Body text is set with generous line heights to facilitate easy scanning of service descriptions. Labels are occasionally uppercase or medium-weight to distinguish them from standard body copy.

## Layout & Spacing

The system follows a **8px linear scale** to ensure mathematical harmony across all components.

- **Mobile-First:** The layout uses a fluid grid with a 20px safe margin on both sides. Content blocks are separated by 24px (md) to maintain the "generous whitespace" narrative.
- **Desktop:** The layout transitions to a 12-column fixed grid with a max-width of 1200px. Gutters remain fixed at 24px to provide clear separation of vertical modules.
- **Rhythm:** Vertical rhythm is strictly enforced. Vertical gaps between related elements (label + input) use 8px, while gaps between unrelated sections use 40px.

## Elevation & Depth

This system avoids heavy shadows in favor of **Tonal Layers** and **Low-Contrast Outlines**.

Depth is primarily achieved by stacking `#FFFFFF` (white) cards on top of the `#F9F6F9` (secondary) background. To define boundaries without visual clutter, elements use a 1px border in a lightened version of the primary color at 12% opacity.

When absolute elevation is required (e.g., sticky bottom bars or floating action buttons), use a single, highly diffused ambient shadow: `0px 12px 32px rgba(80, 117, 45, 0.08)`. This tinting keeps the shadow feeling "organic" rather than "digital gray."

## Shapes

The shape language is consistently **Rounded**.

The 0.5rem (8px) base radius reflects a balance between the precision of professional services and the friendly nature of a consumer app. Larger components like service cards or hero containers should utilize `rounded-xl` (24px) to create a softer, more inviting frame for photography and rich content. Small utility elements like checkboxes use the `soft` (4px) radius for better alignment with text.

## Components

- **Buttons:** Primary buttons are solid moss green with white text. Ghost buttons use a 1px primary border. All buttons have a minimum height of 48px for mobile accessibility.
- **Status Chips:** Use a background color at 10% opacity of the status color (e.g., Light Green background for "Completed") with dark, full-opacity text of the same hue for maximum contrast and "soft" aesthetic.
- **Cards:** White backgrounds with an 8px corner radius and a 1px light-gray stroke. Cards should have internal padding of 24px.
- **Input Fields:** Use a subtle background fill (#F0F0F0) and a 1px bottom border that transforms into a 2px primary-colored border on focus.
- **Lists:** Service lists should be separated by 1px horizontal dividers in a neutral gray-green at 10% opacity, ensuring a clean transition between items without heavy visual breaks.
- **Progress Indicators:** Use a thin, 4px rounded bar in the primary color to show booking status or service completion.
