#!/bin/bash

# GitHub Configuration Script for Hello Artist Theme
# Run this after: gh auth login

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO="precisefuture/hello-artist-theme"

echo -e "${BLUE}🚀 Configuring Hello Artist Theme GitHub repository...${NC}\n"

# Verify authentication
if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}❌ Please authenticate first: gh auth login${NC}"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI authenticated${NC}\n"

# Function to handle API errors gracefully
api_call() {
    local description=$1
    shift
    echo -e "${YELLOW}${description}...${NC}"
    
    if "$@" 2>/dev/null; then
        echo -e "${GREEN}✅ ${description} completed${NC}"
    else
        echo -e "${YELLOW}⚠️ ${description} may have failed or already configured${NC}"
    fi
    echo
}

# Set default branch to development
api_call "Setting default branch to development" \
    gh api repos/$REPO -X PATCH -f default_branch=development

# Configure merge settings
api_call "Configuring merge options" \
    gh api repos/$REPO -X PATCH \
        -f allow_merge_commit=true \
        -f allow_squash_merge=false \
        -f allow_rebase_merge=false \
        -f allow_auto_merge=true \
        -f delete_branch_on_merge=true

# Get current SHA for main branch creation
DEVELOPMENT_SHA=$(gh api repos/$REPO/git/refs/heads/development --jq '.object.sha' 2>/dev/null)

if [ -n "$DEVELOPMENT_SHA" ]; then
    # Create/update main branch to match development
    api_call "Creating/updating main branch" \
        gh api repos/$REPO/git/refs -X POST -f ref="refs/heads/main" -f sha="$DEVELOPMENT_SHA"
fi

# Configure development branch protection
echo -e "${BLUE}🛡️ Configuring development branch protection...${NC}"
cat > /tmp/dev-protection.json << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Lint and Build (8.2, 18)",
      "Lint and Build (8.2, 20)",
      "Lint and Build (8.3, 18)", 
      "Lint and Build (8.3, 20)",
      "WordPress Environment Smoke Test"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

api_call "Setting up development branch protection" \
    gh api repos/$REPO/branches/development/protection -X PUT --input /tmp/dev-protection.json

# Configure main branch protection (production)
echo -e "${BLUE}🛡️ Configuring main/production branch protection...${NC}"
cat > /tmp/main-protection.json << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Lint and Build (8.2, 18)",
      "Lint and Build (8.2, 20)", 
      "Lint and Build (8.3, 18)",
      "Lint and Build (8.3, 20)",
      "WordPress Environment Smoke Test"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

api_call "Setting up main branch protection" \
    gh api repos/$REPO/branches/main/protection -X PUT --input /tmp/main-protection.json

# Create staging environment
echo -e "${BLUE}🏗️ Setting up staging environment...${NC}"
cat > /tmp/staging-env.json << 'EOF'
{
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF

api_call "Creating staging environment" \
    gh api repos/$REPO/environments/staging -X PUT --input /tmp/staging-env.json

# Add staging branch policy
cat > /tmp/staging-branch-policy.json << 'EOF'
{
  "name": "development",
  "type": "branch"
}
EOF

api_call "Setting staging deployment branch policy" \
    gh api repos/$REPO/environments/staging/deployment-branch-policies -X POST --input /tmp/staging-branch-policy.json

# Create production environment
echo -e "${BLUE}🏭 Setting up production environment...${NC}"
cat > /tmp/production-env.json << 'EOF'
{
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  },
  "protection_rules": [
    {
      "type": "wait_timer",
      "wait_timer": 5
    }
  ]
}
EOF

api_call "Creating production environment" \
    gh api repos/$REPO/environments/production -X PUT --input /tmp/production-env.json

# Add production branch policy
cat > /tmp/production-branch-policy.json << 'EOF'
{
  "name": "main", 
  "type": "branch"
}
EOF

api_call "Setting production deployment branch policy" \
    gh api repos/$REPO/environments/production/deployment-branch-policies -X POST --input /tmp/production-branch-policy.json

# Set repository variables
echo -e "${BLUE}📍 Setting up repository variables...${NC}"
api_call "Setting STAGING_URL variable" \
    gh variable set STAGING_URL --body "https://dev.ejfa.precisefuture.com"

api_call "Setting PRODUCTION_URL variable" \
    gh variable set PRODUCTION_URL --body "https://ejfa.precisefuture.com"

# Cleanup temp files
rm -f /tmp/*-protection.json /tmp/*-env.json /tmp/*-policy.json

echo -e "${GREEN}🎉 GitHub repository configuration completed!${NC}\n"

echo -e "${BLUE}📋 Summary of what was configured:${NC}"
echo "  ✅ Default branch: development"
echo "  ✅ Merge settings: commits only, auto-delete branches"
echo "  ✅ Branch protection: development (1 review) + main (2 reviews)"
echo "  ✅ CI status checks: required for all merges"
echo "  ✅ Environments: staging (development) + production (main)"
echo "  ✅ Variables: STAGING_URL + PRODUCTION_URL"
echo ""

echo -e "${YELLOW}🔑 Next: Configure these secrets manually in GitHub UI:${NC}"
echo ""
echo -e "${BLUE}Staging Environment Secrets:${NC}"
echo "  gh secret set STAGING_HOST --env staging --body 'tu-servidor-staging.com'"
echo "  gh secret set STAGING_USER --env staging --body 'deploy-user'"
echo "  gh secret set STAGING_SSH_KEY --env staging --body 'ssh-private-key-content'"
echo "  gh secret set STAGING_PORT --env staging --body '22'"
echo "  gh secret set STAGING_WP_PATH --env staging --body '/var/www/staging/wordpress'"
echo ""
echo -e "${BLUE}Production Environment Secrets:${NC}"
echo "  gh secret set PRODUCTION_HOST --env production --body 'tu-servidor-prod.com'"
echo "  gh secret set PRODUCTION_USER --env production --body 'deploy-user'"
echo "  gh secret set PRODUCTION_SSH_KEY --env production --body 'ssh-private-key-content'"
echo "  gh secret set PRODUCTION_PORT --env production --body '22'"
echo "  gh secret set PRODUCTION_WP_PATH --env production --body '/var/www/html/wordpress'"
echo ""
echo -e "${BLUE}Optional Repository Secrets:${NC}"
echo "  gh secret set SLACK_WEBHOOK_URL --body 'https://hooks.slack.com/services/...'"
echo ""
echo -e "${GREEN}✨ Repository is ready for CI/CD workflow!${NC}"