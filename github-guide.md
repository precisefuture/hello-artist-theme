# GitHub Configuration Guide - Hello Artist Theme

Esta guía detalla paso a paso cómo configurar GitHub para que el repositorio y sus flujos queden perfectamente alineados con el proceso CI/CD descrito en `ci-cd.md`.

## 🎯 Resumen del flujo CI/CD

- **Ramas protegidas:** `production` y `development`
- **Flujo Gitflow:** `feature/*` → `development` → `production`
- **CI automatizado:** Lint, build, tests, performance budget
- **Deploy automático:** staging (development) y production (production)
- **Quality gates:** PHPCS, ESLint, Stylelint, Lighthouse, wp-env tests

## 📋 Configuración paso a paso

### 1. Configurar Branch Protection Rules

#### Para la rama `development`:

1. Ve a **Settings** → **Branches**
2. Click en **Add rule**
3. Configurar:
   - **Branch name pattern:** `development`
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals:** 1
   - ✅ **Dismiss stale PR approvals when new commits are pushed**
   - ✅ **Require status checks to pass before merging**
   - ✅ **Require branches to be up to date before merging**
   - **Status checks requeridos:**
     - `Lint and Build (8.2, 18)`
     - `Lint and Build (8.2, 20)`
     - `Lint and Build (8.3, 18)`
     - `Lint and Build (8.3, 20)`
     - `WordPress Environment Smoke Test`
   - ✅ **Restrict pushes that create files**
   - ✅ **Do not allow bypassing the above settings**

#### Para la rama `production`:

1. Crear otra rule con **Branch name pattern:** `production`
2. Configuración similar a `development` pero más restrictiva:
   - ✅ **Require a pull request before merging**
   - ✅ **Require approvals:** 2 (más restrictivo para producción)
   - ✅ **Require status checks to pass before merging**
   - **Status checks requeridos:** Los mismos que development
   - ✅ **Restrict pushes that create files**
   - ✅ **Include administrators** (nadie puede saltarse las reglas)
   - ✅ **Do not allow bypassing the above settings**

### 2. Configurar Environments y Secrets

#### Environment: `staging`

1. Ve a **Settings** → **Environments**
2. Click **New environment** → nombre: `staging`
3. **Protection rules:**
   - ✅ **Required reviewers:** 1 persona
   - **Deployment branches:** Selected branches → `development`
4. **Environment secrets:**
   ```
   STAGING_HOST=tu-servidor-staging.com
   STAGING_USER=deploy-user
   STAGING_SSH_KEY=[clave SSH privada]
   STAGING_PORT=22
   STAGING_WP_PATH=/var/www/staging/wordpress
   STAGING_URL=https://staging.tu-dominio.com
   ```

#### Environment: `production`

1. Crear environment: `production`
2. **Protection rules:**
   - ✅ **Required reviewers:** 2 personas mínimo
   - **Deployment branches:** Selected branches → `production`
   - **Wait timer:** 5 minutos (ventana de reflexión)
3. **Environment secrets:**
   ```
   PRODUCTION_HOST=tu-servidor-prod.com
   PRODUCTION_USER=deploy-user
   PRODUCTION_SSH_KEY=[clave SSH privada]
   PRODUCTION_PORT=22
   PRODUCTION_WP_PATH=/var/www/html/wordpress
   PRODUCTION_URL=https://tu-dominio.com
   ```

#### Secrets adicionales (Repository secrets)

En **Settings** → **Secrets and variables** → **Actions** → **Repository secrets:**

```bash
# CDN/Cache
CLOUDFLARE_ZONE_ID=zona-id-cloudflare
CLOUDFLARE_API_TOKEN=token-api-cloudflare
AWS_CLOUDFRONT_DISTRIBUTION_ID=distribution-id

# Notificaciones
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...

# Lighthouse CI (opcional)
LHCI_GITHUB_APP_TOKEN=token-lighthouse-ci
```

### 3. Configurar Repository Settings

#### General settings:
1. **Settings** → **General**
2. **Default branch:** `development`
3. **Pull Requests:**
   - ✅ **Allow merge commits**
   - ❌ **Allow squash merging** (para mantener historial limpio)
   - ❌ **Allow rebase merging**
   - ✅ **Always suggest updating pull request branches**
   - ✅ **Automatically delete head branches**

#### Actions permissions:
1. **Settings** → **Actions** → **General**
2. **Actions permissions:** Allow all actions and reusable workflows
3. **Workflow permissions:** Read and write permissions
4. ✅ **Allow GitHub Actions to create and approve pull requests**

### 4. Configurar webhooks para despliegue (opcional)

Si usas servicios como CapRover, Fly.io o Render:

1. **Settings** → **Webhooks**
2. **Add webhook**
3. **Payload URL:** URL del webhook del servicio
4. **Content type:** application/json
5. **Events:** Just the push event
6. **Branches:** development, production

### 5. Configurar etiquetas semánticas

#### Crear release template:

1. **Code** → **Releases** → **Create a new release**
2. Crear template en `.github/RELEASE_TEMPLATE.md`:

```markdown
## 🚀 Release v{VERSION}

### 📋 Changes
- Feature: Nueva funcionalidad X
- Fix: Corrección del bug Y
- Performance: Optimización Z

### 🧪 Testing
- [ ] Staging tests passed
- [ ] Lighthouse scores: LCP ≥ 80, SEO ≥ 95
- [ ] WooCommerce checkout flow
- [ ] Cross-browser testing

### 📦 Deployment
- Staging URL: https://staging.tu-dominio.com
- Production URL: https://tu-dominio.com

### 📈 Performance Budget
- CSS: ≤ 60 KB gzipped
- JS: ≤ 15 KB gzipped
```

### 6. Configurar issue y PR templates

#### Pull Request template (`.github/pull_request_template.md`):

```markdown
## 📋 Description
Brief description of changes

## 🔗 Related Issue
Fixes #(issue number)

## 📸 Screenshots (if applicable)
Add screenshots of UI changes

## ✅ Checklist
- [ ] Code follows WordPress coding standards
- [ ] Self-review of the code
- [ ] Components are properly documented
- [ ] Performance budget respected (CSS ≤ 60KB, JS ≤ 15KB)
- [ ] Cross-browser testing completed
- [ ] Accessibility guidelines followed (WCAG 2.1 AA)

## 🧪 Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Staging deployment successful

## 📱 Responsive Design
- [ ] Mobile (320px+)
- [ ] Tablet (768px+)
- [ ] Desktop (1200px+)
```

### 7. Configurar notificaciones de Slack (opcional)

En tu workspace de Slack:
1. Crear canal `#deployments`
2. Agregar app **Incoming Webhooks**
3. Generar webhook URL
4. Agregar `SLACK_WEBHOOK_URL` a repository secrets

### 8. Verificar configuración

#### Checklist final:

- [ ] Branch protection rules activas en `development` y `production`
- [ ] Environments `staging` y `production` configurados con secrets
- [ ] Default branch es `development`
- [ ] Merge commits habilitados, squash deshabilitado
- [ ] Actions permissions configurados correctamente
- [ ] Webhooks configurados (si aplica)
- [ ] Templates de PR e issues creados

## 🚀 Flujo de trabajo en acción

### Para nueva feature:

```bash
# 1. Crear feature branch desde development
git checkout development
git pull origin development
git checkout -b feature/nueva-funcionalidad

# 2. Desarrollar con commits convencionales
git commit -m "feat: add new gallery component"
git commit -m "style: improve gallery responsive design"

# 3. Push y crear PR
git push -u origin feature/nueva-funcionalidad
# Crear PR en GitHub: feature/nueva-funcionalidad → development
```

### Para release a producción:

```bash
# 1. PR de development a production
# En GitHub: crear PR development → production
# 2. Esperar aprobaciones (2 mínimo)
# 3. El merge automáticamente despliega a producción
# 4. GitHub Actions crea release automático con tag vX.Y.Z
```

### Para hotfix crítico:

```bash
# 1. Crear desde production
git checkout production
git pull origin production
git checkout -b hotfix/critical-fix

# 2. Fix y commit
git commit -m "fix: critical security issue in contact form"

# 3. PR directo a production
git push -u origin hotfix/critical-fix
# Crear PR: hotfix/critical-fix → production

# 4. Después del merge, sync a development
# GitHub Actions automáticamente hace merge back
```

## 🔧 Troubleshooting

### Problema: CI falla en bundle size
**Solución:** Revisar archivos en `/build` o `/dist`, optimizar CSS/JS

### Problema: wp-env smoke test falla
**Solución:** Verificar que `style.css` tenga header correcto de WordPress

### Problema: Deploy falla en SSH
**Solución:** Verificar que la clave SSH esté en formato PEM y sin passphrase

### Problema: Lighthouse CI no encuentra páginas
**Solución:** Configurar URLs correctas en `.lighthouserc.js`

## 📚 Referencias

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches)
- [Environments Documentation](https://docs.github.com/en/actions/deployment/targeting-different-environments)
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [Conventional Commits](https://conventionalcommits.org/)