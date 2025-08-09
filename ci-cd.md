# Metodología CI/CD (especificación para DevOps/Claude)

## Nombre

**Gitflow** con ramas protegidas.

## Ramas

* `production` (deploy a prod) — protegida.
* `development` (staging) — protegida.
* `feature/<slug>` (por tarea).
* `hotfix/<slug>` (parches directos a prod).

## Flujo

1. Crear `feature/foo` desde `development`.
2. Commits pequeños con mensajes convencionales (Conventional Commits).
3. Pull Request → **CI:**

   * Lint PHP (PHPCS WordPress), JS (ESLint), CSS (Stylelint).
   * Build (esbuild/PostCSS) y tamaño de bundles (fallar si excede presupuesto).
   * PHPUnit mínimo (si aplica en plugin core).
4. Merge a `development` → **Deploy a staging** (hook o GH Actions).
5. QA (visual, Lighthouse, WC checkout, i18n/SEO, caché).
6. PR `development` → `production` (release) → **Deploy a prod**.
7. **Hotfix:** `hotfix/x` desde `production`, PR a `production`, desplegar; **merge back** a `development` para mantener historia.

## Reglas de protección

* `production`/`development`:

  * Requiere PR, 1–2 reviews, CI verde, **no force-push**.
  * Tags semánticos en releases (`vX.Y.Z`).

## Entornos

* **Staging**: WP con DB separada, Stripe en modo test, WP Rocket desactivado o en modo seguro, depuradores activos.
* **Production**: caché completa (WP Rocket + Redis), CDN S3, minificación activada.

## Variables/Secrets

* `WP_ENV` (`staging|production`)
* `DB_*` por entorno
* `S3_*` (bucket, key, region)
* `REDIS_*`
* `STRIPE_PUBLIC/SECRET` (test/prod)
* `GTM_ID`/`GA4_ID` (Site Kit)
* `RANKMATH_KEY` (si licencias)
* `POLYLANG` flags (si se usa)

## Gates de calidad (CI)

* **PHPCS** con reglas WordPress.
* **ESLint/Stylelint/Prettier**.
* **Composer validate / npm audit** (fail en alta severidad).
* **Lighthouse CI** (home, store, product): LCP ≥ 80/100, SEO ≥ 95.
* **Wp-env smoke test** (CLI: activar tema, visitar /, /store, /product/\*).

## Despliegue

* **Staging**: Github Actions → SSH/rsync o contenedor (CapRover/Fly/Render) + WP-CLI (migraciones simples), limpiar cachés.
* **Production**: idem con ventana corta; **mantenimiento** 503 si hace falta; invalidación CDN.

## Rollback

* Mantener **releases** empaquetadas; rollback por tag.
* Backups DB+uploads antes de release.
* `wp transient delete --all` y purga Redis/WP Rocket tras rollback.

---
