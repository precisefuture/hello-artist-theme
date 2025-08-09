# Manual GitHub Setup Instructions

Dado que la autenticación automática del CLI requiere interacción manual, aquí están las instrucciones paso a paso para configurar el repositorio:

## Paso 1: Autenticación GitHub CLI

```bash
gh auth login
# Sigue las instrucciones en pantalla
```

## Paso 2: Ejecutar configuración automática

```bash
./configure-github.sh
```

## Alternativa: Configuración manual via UI de GitHub

### 1. Branch Protection Rules

#### Para `development`:
1. Ve a **Settings** → **Branches** → **Add rule**
2. **Branch name pattern:** `development`
3. ✅ **Require a pull request before merging** (1 approval)
4. ✅ **Require status checks to pass before merging**
5. **Status checks requeridos:**
   - `Lint and Build (8.2, 18)`
   - `Lint and Build (8.2, 20)`
   - `Lint and Build (8.3, 18)`
   - `Lint and Build (8.3, 20)`
   - `WordPress Environment Smoke Test`
6. ✅ **Require branches to be up to date before merging**
7. ❌ **Do not allow bypassing the above settings**

#### Para `main` (production):
1. Crear rule similar pero con **2 approvals required**
2. ✅ **Include administrators** (más restrictivo)

### 2. Environments

#### Staging Environment:
1. **Settings** → **Environments** → **New environment** → `staging`
2. **Deployment branches:** Custom → `development`
3. **Environment secrets:**
   ```
   STAGING_HOST=tu-servidor-staging.com
   STAGING_USER=deploy-user
   STAGING_SSH_KEY=[clave SSH privada sin passphrase]
   STAGING_PORT=22
   STAGING_WP_PATH=/var/www/staging/wordpress
   ```

#### Production Environment:
1. **New environment** → `production`
2. **Protection rules:**
   - ✅ **Required reviewers** (2 mínimo)
   - **Wait timer:** 5 minutes
3. **Deployment branches:** Custom → `main`
4. **Environment secrets:**
   ```
   PRODUCTION_HOST=tu-servidor-prod.com
   PRODUCTION_USER=deploy-user
   PRODUCTION_SSH_KEY=[clave SSH privada sin passphrase]
   PRODUCTION_PORT=22
   PRODUCTION_WP_PATH=/var/www/html/wordpress
   ```

### 3. Repository Settings

1. **Settings** → **General**:
   - **Default branch:** `development`
   - ✅ **Allow merge commits**
   - ❌ **Allow squash merging**
   - ❌ **Allow rebase merging**
   - ✅ **Automatically delete head branches**

2. **Variables** → **Repository variables**:
   ```
   STAGING_URL=https://dev.ejfa.precisefuture.com
   PRODUCTION_URL=https://ejfa.precisefuture.com
   ```

3. **Secrets** (opcional):
   ```
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
   ```

## Verificación

Una vez configurado, verifica:

1. **Branch protection:** Intenta hacer push directo a `development` (debería fallar)
2. **CI Pipeline:** Crea un PR para ver si los status checks funcionan
3. **Environments:** Verifica que aparezcan en Settings → Environments

## Testing del flujo completo

```bash
# 1. Crear feature branch
git checkout development
git checkout -b feature/test-ci-cd

# 2. Hacer cambio mínimo
echo "/* Test change */" >> style.css
git add style.css
git commit -m "feat: test CI/CD pipeline"

# 3. Push y crear PR
git push -u origin feature/test-ci-cd
gh pr create --title "Test CI/CD Pipeline" --body "Testing the automated CI/CD workflow"

# 4. Ver CI en acción en GitHub Actions tab
```

Si todo está bien configurado:
- ✅ CI ejecutará lint/build/tests
- ✅ Merge a development → deploy a staging
- ✅ PR development → main → deploy a production (con approvals)