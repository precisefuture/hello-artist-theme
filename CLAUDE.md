# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a WordPress child theme (`hello-artist`) built on the Hello Elementor parent theme for an eCommerce art gallery website. The project follows a **component-based modular architecture** without page builders, focusing on performance and clean code.

## Key Architecture Principles

- **Child theme of Hello Elementor** - inherits base functionality while maintaining custom features
- **Component-based structure** - each UI component has its own PHP, CSS, and JS files
- **No page builders** (specifically no Elementor usage despite parent theme)
- **Performance-first** - strict performance budget: CSS ≤ 60 KB gzipped, JS ≤ 15 KB gzipped
- **Vanilla JS only** - no jQuery, all scripts use `defer` attribute
- **Semantic HTML and accessibility** standards

## Tech Stack

### Core WordPress Setup
- **Parent Theme:** Hello Elementor
- **Child Theme:** hello-artist
- **PHP Version:** 8.2+
- **WordPress Coding Standards** (PHPCS)

### Essential Plugins
- WooCommerce + Stripe (official)
- RankMath (SEO)
- Redis Object Cache
- WP Rocket (caching)
- Google Site Kit (GA4/GSC)
- Complianz (GDPR/cookies)
- `pf-artist-core` (custom plugin - see below)

## Project Structure

```
/hello-artist/                 # Child theme root
  style.css                    # WordPress theme header (currently empty)
  functions.php               # Theme functions (to be created)
  /templates/                 # WordPress/WooCommerce templates
    front-page.php
    page-gallery.php
    archive-product.php
    single-product.php
    /woocommerce/             # WooCommerce overrides
  /components/                # Modular components
    site-header/
      site-header.php
      site-header.css
      site-header.js
    card-product/
    gallery-grid/
    product-gallery/
    form-contact/
    modal/
  /assets/
    css/base.css              # Tokens, utilities, reset
    js/base.js
  /build/                     # esbuild/PostCSS output

/pf-artist-core/              # Custom plugin (separate)
  /inc/
    cpt-taxonomies.php        # Custom taxonomy "collection"
    product-meta.php          # Art-specific metadata
    offer-endpoints.php       # Custom offer system
    newsletter.php            # Newsletter functionality
```

## Development Commands

**Note:** No build system is currently set up. Based on project specifications:

- Build tools: `esbuild + PostCSS` (autoprefixer, purge)
- Linting: `PHPCS` (WordPress standards), `ESLint`, `Stylelint`
- Git workflow: Gitflow with `development` and `production` branches

## Art-Specific Features

### Product Types
- **Original paintings:** Simple products with offer functionality
- **Prints:** Variable products by size (A4/A3/50×70cm)
- **Series:** Grouped products (3-10 related paintings)

### Custom Taxonomy
- `collection`: figures, urban-landscape, natural-landscape, portrait, still-lifes, sketchbook

### Product Metadata (via pf-artist-core)
- `material`, `year`, `dimensions_text`
- `is_offerable` (boolean), `min_offer` (float)
- `edition_size` (for prints)
- `series_group_id` (linking related works)

## Design Tokens

### Typography
- Stack: `system-ui, -apple-system, "Segoe UI", Roboto, Inter, Arial, sans-serif`
- H1: 48-64px / 600 weight / +0.02em tracking
- H2: 32-40px / 600 weight
- Body: 16-18px / 400 weight
- Overline: 12-14px / 500 weight / uppercase / +0.08em tracking

### Colors
- Background: #FFFFFF
- Text: #111111  
- Secondary: #666666
- Borders: #EDEDED
- Hover states: 80% opacity or thin underline

### Layout
- Spacing scale: 8px base (8/16/24/32/48/64)
- Container: 1200-1320px max-width
- Grid: 4 col desktop, 2 tablet, 1 mobile

## Quality Standards

### Performance Budget
- CSS ≤ 60 KB gzipped
- JS ≤ 15 KB gzipped  
- LCP < 2.0s (4G)
- INP < 200ms

### Code Quality
- WordPress Coding Standards (PHPCS)
- ESLint + Stylelint + Prettier
- Conventional Commits format
- Contrast minimum 4.5:1
- Touch targets ≥ 44×44px

## Git Workflow

- **Main branches:** `production` (live), `development` (staging)
- **Feature branches:** `feature/<slug>`
- **Hotfixes:** `hotfix/<slug>` from production
- Protected branches require PR + CI checks
- Semantic versioning for releases (`vX.Y.Z`)

## Current Status

This is a **new project** with only documentation files present:
- Theme structure needs to be built
- `style.css` exists but is empty (needs WordPress theme header)
- No `functions.php` or template files yet
- Component system needs implementation
- Build pipeline needs setup

## SEO & Performance Notes

- RankMath handles sitemaps for products and taxonomies
- Schema markup for products and organization
- Critical CSS should be inlined
- All JS should use `defer` attribute
- CDN integration via S3-Client plugin