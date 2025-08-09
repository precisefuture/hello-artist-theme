# Hello Artist WordPress Theme

Child theme of Hello Elementor for eCommerce art gallery. Component-based architecture without page builders.

## Features

- **Performance-first**: CSS ≤ 60 KB gzipped, JS ≤ 15 KB gzipped
- **Component-based**: Modular architecture with dedicated CSS/JS per component
- **WooCommerce optimized**: Art-specific product types and metadata
- **Accessibility**: WCAG 2.1 AA compliant
- **SEO ready**: Structured data and RankMath integration

## Tech Stack

- PHP 8.2+
- WordPress 6.0+
- WooCommerce
- Vanilla JS (no jQuery)
- Component-based CSS

## Development

This project uses **Gitflow** with protected branches:

- `production` - Live site
- `development` - Staging environment  
- `feature/<slug>` - Feature branches
- `hotfix/<slug>` - Production hotfixes

## Structure

```
/hello-artist/
├── style.css                 # WordPress theme header
├── functions.php             # Theme functions
├── /templates/               # WordPress/WooCommerce templates
├── /components/              # Modular components
│   ├── site-header/
│   ├── card-product/
│   └── gallery-grid/
├── /assets/                  # Base styles and scripts
└── /build/                   # Build outputs
```

## Art-Specific Features

- **Collections taxonomy**: figures, urban-landscape, natural-landscape, portrait, still-lifes, sketchbook
- **Custom metadata**: material, year, dimensions, edition size
- **Offer system**: For original paintings
- **Print variations**: Multiple sizes (A4/A3/50×70cm)
- **Series support**: Grouped artworks

## License

GPL v2 or later