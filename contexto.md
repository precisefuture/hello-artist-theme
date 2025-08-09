# Especificación para Claude Code (contexto técnico, restricciones, stack y estructura)

## Contexto

Sitio eCommerce minimalista para artista **(pintura y prints)**. Diseño sin page builder, **modular por componentes**. Alto rendimiento y SEO.

## Restricciones

* **Sin Elementor**.
* **Tema hijo** sobre **Hello**.
* **Cada componente con su propio CSS/JS/AJAX**.
* JS vanilla, `defer`.
* **Semántica y accesibilidad** estrictas.
* **Performance budget**: CSS ≤ 60 KB gz, JS ≤ 15 KB gz.
* **Sin dependencias** pesadas salvo WooCommerce y plugins listados.

## Stack inicial (WP + plugins)

* **Tema:** `hello` (parent) + `hello-artist` (child).
* **Plugins core:**

  * WooCommerce + **Stripe** oficial.
  * RankMath (SEO).
  * Classic Editor.
  * Redis Object Cache.
  * Index WP MySQL for Speed.
  * **S3-Client (propio)** para estáticos/CDN.
  * WP Rocket.
  * **Google Site Kit** (GA4/GSC).
  * **Complianz** (cookies/consent).
  * (Opcionales) Polylang (+ Woo), Multi-currency, WP Mail SMTP, EWWW/Imagify.
  * **pf-artist-core (propio)** — ver abajo.

## Estructura del repo

```
/hello-artist/                # tema hijo
  style.css                   # mínimo, importar tokens si hace falta
  functions.php
  /templates/                 # plantillas WP/WC
    front-page.php
    page-gallery.php
    taxonomy-collection.php
    archive-product.php
    taxonomy-product_cat.php
    single-product.php
    page-contact.php
    page-shipping.php
    search.php
    404.php
    /woocommerce/overrides...
  /components/                # 1 carpeta por componente
    site-header/
      site-header.php
      site-header.css
      site-header.js
    card-product/
      card-product.php
      card-product.css
      card-product.js
      card-product.ajax.php   # si aplica
    gallery-grid/
    filters-bar/
    sort-dropdown/
    product-gallery/
    product-meta/
    price-block/
    variations/
    offer-button/
    inquire-button/
    breadcrumbs/
    chips-taxonomy/
    form-contact/
    form-offer/
    form-newsletter/
    modal/
  /assets/
    css/base.css              # reset, tokens, utilidades
    js/base.js
  /build/                     # salida de esbuild/postcss
/pf-artist-core/              # plugin propio
  pf-artist-core.php
  /inc/
    cpt-taxonomies.php        # taxonomy "collection"
    product-meta.php          # metacampos (material, year, is_offerable, min_offer, edition_size...)
    offer-endpoints.php       # REST + post type offer
    newsletter.php            # tabla y endpoints suscripción
    security.php              # nonces, rate-limit
  /migrations/
    001_newsletter_table.sql
    002_offer_posttype.php
```

## Metadatos/Taxonomías

* **Taxonomía** `collection`: `figures`, `urban-landscape`, `natural-landscape`, `portrait`, `still-lifes`, `sketchbook`.
* **Metacampos de producto (pf-artist-core):**

  * `material` (string), `year` (int), `dimensions_text` (string)
  * `is_offerable` (bool), `min_offer` (float)
  * `edition_size` (int, para prints)
  * `series_group_id` (para vincular cuadros de una obra dividida)

## Tipos de producto / flujos

* **Original único**: simple, stock 1, `is_offerable=true` → **botón “Realizar oferta”**.
* **Prints**: variable por `size` (A4/A3/50×70…), mostrar `edition_size`.
* **Series 3–10 cuadros**:

  * **Ruta recomendada:** Producto **agrupado** + hijos simples (cada cuadro) **o** variable por “Conjunto”.
  * **Escalable:** Composite Products (solo si lo piden).
* **Subasta (opcional):** plugin Simple Auctions; si no, flujo de **oferta**.

## Newsletter (módulo del plugin)

* **Tabla** `wp_pf_newsletter_subs`:

  * `id` PK, `email` UNIQUE, `name`, `lang`, `consent` tinyint, `status` enum(pending,active,unsub), `token`, `source`, `created_at`, `confirmed_at`, `gdpr_meta` JSON.
* **Flujo:** POST → pending → email confirmación → active; webhooks a ESP externo.

## Encolado de assets

* Un **handle** por componente, sólo donde se usa.
* Build con **esbuild + PostCSS** (autoprefixer, purge).
* `defer` para JS, CSS crítico inline en plantillas principales.

## Calidad de código

* **PHP 8.2+**, **WP Coding Standards** (PHPCS).
* **ESLint**, **Stylelint**, **Prettier**.
* Commits con **Conventional Commits**.
* Husky pre-commit (lint) y pre-push (tests/build).

## SEO/i18n

* RankMath sitemaps para `product`, `product_cat`, `product_tag`, páginas.
* Breadcrumbs, schema Product, Organization/Person.
* Polylang (si se activa): `hreflang` y duplicación de slugs.

## Seguridad

* Nonces en formularios; reCAPTCHA v3; honeypot; rate-limit.
* Desactivar XML-RPC; limitar REST de usuarios.
* Política de cookies con **Complianz**; scripts GA4 via **Site Kit** (consent mode).

## QA (staging)

* Pages a test: `/`, `/gallery/`, `/store/`, `/{product}`, `/contact/`, `/shipping/`.
* Casos: compra simple, variable, oferta, newsletter, multimoneda (si activo), caché y CDN.

---
