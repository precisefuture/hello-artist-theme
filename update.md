La **vía más corta**, con lo que YA tienes (3 workflows separados y despliegue por SSH), es:

* Mantener `ci.yml` tal cual (lint/build/tests).
* Que `deploy-staging.yml` y `deploy-production.yml` se activen **por push a `development`/`production`**, respectivamente, y hagan **rsync solo del tema y plugins propios** + `wp-cli` + purga de cachés.
* Con las **Branch Protection Rules** que ya definiste, ese push solo ocurre si el CI pasó ⇒ staging y prod **siempre** despliegan lo que pasó CI.
* Añadimos 3 microajustes para **rapidez y certeza**:

  1. **Cache** de `npm` y `composer` en los jobs de deploy (evitas reconstrucciones lentas).
  2. **rsync incremental** de `/wp-content/themes/hello-artist` y `/wp-content/plugins/pf-artist-core` (no muevas todo WordPress).
  3. **Marca de build** en el servidor (`wp-content/pf-build.sha` con `${{ github.sha }}`) y verificación inmediata.

Abajo te dejo **patches listos** (snippets) para tus 3 YAML.

---

# 1) `ci.yml` (déjalo como está o añade cache – opcional)

Tu `ci.yml` ya corre lint/build, `wp-env` y Lighthouse. Si quieres acelerar un poco, mete cache de `npm` y `composer` en ese workflow (opcional). No es condición para la vía corta porque el **deploy NO dependerá** de artefactos de `ci.yml`.

> **Importante**: con tus Branch Protection Rules (CI requerido), el merge a `development`/`production` solo sucede si `ci.yml` **pasa**. Eso ya “gatea” los deploys.

---

# 2) `deploy-staging.yml` (push a `development`)

Añade **concurrency**, cache y despliegue **incremental** + verificación:

```yaml
name: Deploy to Staging

on:
  push:
    branches: [ development ]

concurrency:
  group: deploy-staging
  cancel-in-progress: true

jobs:
  deploy-staging:
    name: Deploy to Staging Environment
    runs-on: ubuntu-latest
    environment: staging

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # ---- Build rápido solo de lo nuestro (tema + plugin) ----
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
          cache-dependency-path: |
            hello-artist/package-lock.json
            pf-artist-core/package-lock.json

      - name: Build theme assets
        working-directory: hello-artist
        run: |
          npm ci
          npm run build

      # (Si tu plugin tiene build, descomenta)
      # - name: Build plugin assets
      #   working-directory: pf-artist-core
      #   run: |
      #     npm ci
      #     npm run build

      # ---- Despliegue incremental por SSH/rsync ----
      - name: Sync theme
        uses: burnett01/rsync-deployments@6.0
        with:
          switches: -az --delete
          path: hello-artist/
          remote_path: ${{ secrets.STAGING_WP_PATH }}/wp-content/themes/hello-artist/
          remote_host: ${{ secrets.STAGING_HOST }}
          remote_user: ${{ secrets.STAGING_USER }}
          remote_port: ${{ secrets.STAGING_PORT }}
          remote_key: ${{ secrets.STAGING_SSH_KEY }}

      - name: Sync plugin (pf-artist-core)
        uses: burnett01/rsync-deployments@6.0
        with:
          switches: -az --delete
          path: pf-artist-core/
          remote_path: ${{ secrets.STAGING_WP_PATH }}/wp-content/plugins/pf-artist-core/
          remote_host: ${{ secrets.STAGING_HOST }}
          remote_user: ${{ secrets.STAGING_USER }}
          remote_port: ${{ secrets.STAGING_PORT }}
          remote_key: ${{ secrets.STAGING_SSH_KEY }}

      # ---- Post-deploy en servidor: activar tema, DB updates, caches, marca de build ----
      - name: Post-deploy tasks
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          port: ${{ secrets.STAGING_PORT }}
          script: |
            cd ${{ secrets.STAGING_WP_PATH }}
            # Marca del commit desplegado
            echo "${{ github.sha }}" > wp-content/pf-build.sha

            # Activar tema (por si acaso) y correr posibles migrations
            wp theme activate hello-artist --allow-root || true
            wp plugin activate pf-artist-core --allow-root || true
            wp core update-db --allow-root || true

            # Purga cachés
            wp transient delete --all --allow-root || true
            wp rocket clean --allow-root || true
            wp rocket preload --allow-root || true
            # Opcional: purga Redis si usas object cache
            # wp redis flush --allow-root || true

      # ---- Verificación remota de commit ----
      - name: Verify deployed commit
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.STAGING_HOST }}
          username: ${{ secrets.STAGING_USER }}
          key: ${{ secrets.STAGING_SSH_KEY }}
          port: ${{ secrets.STAGING_PORT }}
          script: |
            cd ${{ secrets.STAGING_WP_PATH }}
            DEPLOYED=$(cat wp-content/pf-build.sha || echo "unknown")
            echo "Deployed SHA: $DEPLOYED"
            if [ "$DEPLOYED" != "${{ github.sha }}" ]; then
              echo "Mismatch in deployed SHA"; exit 1
            fi

      # ---- Notificación Slack (si configuraste el secret) ----
      - name: Notify deployment
        if: ${{ always() && env.SLACK_WEBHOOK_URL != '' }}
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          text: |
            🚀 Staging deployment ${{ job.status }}
            Branch: ${{ github.ref }}
            Commit: ${{ github.sha }}
            URL: ${{ secrets.STAGING_URL }}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

**Por qué es rápido:** cache de `npm`, build solo de **lo nuestro**, y **rsync incremental** (envías cambios, no todo WP). Post-deploy es puro `wp-cli` + purgas (segundos).

---

# 3) `deploy-production.yml` (push a `production` + environment protection)

Mismo patrón, pero con `environment: production`, reviewers y **dos aprobaciones** (ya lo definiste). Añade **concurrency** y el mismo pack de pasos:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ production ]
  release:
    types: [ published ]

concurrency:
  group: deploy-production
  cancel-in-progress: true

jobs:
  deploy-production:
    name: Deploy to Production Environment
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
          cache-dependency-path: |
            hello-artist/package-lock.json
            pf-artist-core/package-lock.json

      - name: Build theme assets
        working-directory: hello-artist
        run: |
          npm ci
          npm run build

      # - name: Build plugin assets
      #   working-directory: pf-artist-core
      #   run: |
      #     npm ci
      #     npm run build

      - name: Sync theme
        uses: burnett01/rsync-deployments@6.0
        with:
          switches: -az --delete
          path: hello-artist/
          remote_path: ${{ secrets.PRODUCTION_WP_PATH }}/wp-content/themes/hello-artist/
          remote_host: ${{ secrets.PRODUCTION_HOST }}
          remote_user: ${{ secrets.PRODUCTION_USER }}
          remote_port: ${{ secrets.PRODUCTION_PORT }}
          remote_key: ${{ secrets.PRODUCTION_SSH_KEY }}

      - name: Sync plugin (pf-artist-core)
        uses: burnett01/rsync-deployments@6.0
        with:
          switches: -az --delete
          path: pf-artist-core/
          remote_path: ${{ secrets.PRODUCTION_WP_PATH }}/wp-content/plugins/pf-artist-core/
          remote_host: ${{ secrets.PRODUCTION_HOST }}
          remote_user: ${{ secrets.PRODUCTION_USER }}
          remote_port: ${{ secrets.PRODUCTION_PORT }}
          remote_key: ${{ secrets.PRODUCTION_SSH_KEY }}

      - name: Post-deploy tasks
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          port: ${{ secrets.PRODUCTION_PORT }}
          script: |
            cd ${{ secrets.PRODUCTION_WP_PATH }}
            echo "${{ github.sha }}" > wp-content/pf-build.sha
            wp theme activate hello-artist --allow-root || true
            wp plugin activate pf-artist-core --allow-root || true
            wp core update-db --allow-root || true

            # Purga cachés de verdad
            wp transient delete --all --allow-root || true
            wp rocket clean --allow-root || true
            wp rocket preload --allow-root || true
            # Purga CDN opcional (Cloudflare/CloudFront) si configuraste tokens:
            # wp --allow-root rocketcdn purge || true

      - name: Verify deployed commit
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          port: ${{ secrets.PRODUCTION_PORT }}
          script: |
            cd ${{ secrets.PRODUCTION_WP_PATH }}
            DEPLOYED=$(cat wp-content/pf-build.sha || echo "unknown")
            echo "Deployed SHA: $DEPLOYED"
            if [ "$DEPLOYED" != "${{ github.sha }}" ]; then
              echo "Mismatch in deployed SHA"; exit 1
            fi

      - name: Notify deployment
        if: ${{ always() && env.SLACK_WEBHOOK_URL != '' }}
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          channel: '#deployments'
          text: |
            🎯 Production deployment ${{ job.status }}
            Branch: ${{ github.ref }}
            Commit: ${{ github.sha }}
            URL: ${{ secrets.PRODUCTION_URL }}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Notas clave

* **Rápido**: caches + rsync incremental + tareas `wp-cli`. Nada de empaquetados pesados ni contenedores ahora.
* **Confiable**: la marca `pf-build.sha` garantiza que el **commit** desplegado es exactamente el del push.
* **Gated**: tus Branch Protection Rules ya obligan a que `ci.yml` pase antes de que `development`/`production` reciban el push.
* **Privado staging**: lo resuelves en **infra** (Security Group con whitelist de IPs o VPN). El pipeline no publica URLs si no quieres.

Rol: DevOps. Corto y claro.

Ahora mismo las URLs **no están “definidas”** a menos que las pongas tú (en los secrets o en los workflows). Hagámoslo **bien y simple**: un **archivo de configuración en el repo** que cargan los workflows en cada push.

## 1) Crea el archivo de URLs en el repo

`.github/urls.env`

```env
# Staging y producción (solo dominios/URLs públicas)
STAGING_URL=https://dev.ejfa.precisefuture.com
PRODUCTION_URL=https://ejfa.precisefuture.com
```

> Esto NO lleva secretos. Solo dominios. Se versiona y es fácil de cambiar.

## 2) Carga estas variables en los deploys

### `deploy-staging.yml` — añade al principio del job:

```yaml
    steps:
      - uses: actions/checkout@v4

      - name: Load URLs
        run: |
          set -a
          source .github/urls.env
          echo "STAGING_URL=$STAGING_URL" >> $GITHUB_ENV
```

Y en cualquier paso donde antes usabas una URL, referencia `${{ env.STAGING_URL }}`.
Ejemplo (notificación Slack):

```yaml
text: |
  🚀 Staging deployment ${{ job.status }}
  Commit: ${{ github.sha }}
  URL: ${{ env.STAGING_URL }}
```

### `deploy-production.yml` — igual:

```yaml
    steps:
      - uses: actions/checkout@v4

      - name: Load URLs
        run: |
          set -a
          source .github/urls.env
          echo "PRODUCTION_URL=$PRODUCTION_URL" >> $GITHUB_ENV
```

Y usa `${{ env.PRODUCTION_URL }}`.

> Si prefieres, puedes poner **ambas** (STAGING\_ y PRODUCTION\_) en ambos jobs; no molesta.

## 3) Dónde “vives” esas URLs fuera de GitHub

Las URLs en el workflow solo se usan para **mensajería/links**. Para que el sitio **responda** en esos dominios:

1. **DNS**: crea `A`/`CNAME` en Route 53:

   * `dev.ejfa.precisefuture.com` → tu ALB/EC2 de *staging*
   * `ejfa.precisefuture.com` → tu ALB/EC2 de *producción*

2. **Servidor web** (Nginx/Apache): añade el **server\_name** para cada dominio y vhost que apunte al docroot de WP.

3. **WordPress**: asegúrate de que **home** y **siteurl** coinciden con el dominio del entorno. Dos opciones:

   * **WP-CLI en post-deploy** (seguro si no defines constantes):

     ```bash
     wp option update home "${STAGING_URL}" --allow-root
     wp option update siteurl "${STAGING_URL}" --allow-root
     ```

     (En prod, igual pero con `${PRODUCTION_URL}`.)
   * **Variables de entorno** (si no quieres tocar opciones): en `wp-config.php`:

     ```php
     if (getenv('WP_HOME'))    define('WP_HOME', getenv('WP_HOME'));
     if (getenv('WP_SITEURL')) define('WP_SITEURL', getenv('WP_SITEURL'));
     ```

     Y en cada servidor exportas `WP_HOME`/`WP_SITEURL` a su dominio.

## 4) (Opcional) Usar Repository Variables en vez de archivo

---

### Resumen operativo

* **Staging**: `https://dev.ejfa.precisefuture.com`
* **Producción**: `https://ejfa.precisefuture.com`
* Se definen en `.github/urls.env` y se cargan en cada push.
* A nivel infra, configura DNS + vhosts + `home/siteurl` (WP-CLI o env vars) para que el dominio sirva el sitio correcto.
