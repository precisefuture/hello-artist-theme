#!/bin/bash

# Setup script for Hello Artist Theme GitHub repository
# This script configures branch protection rules, environments, and settings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Setting up Hello Artist Theme GitHub repository...${NC}\n"

# Check if gh CLI is available and authenticated
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) is not installed. Please install it first:${NC}"
    echo "https://github.com/cli/cli#installation"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  You need to authenticate with GitHub CLI first:${NC}"
    echo "Run: gh auth login"
    echo "Then run this script again."
    exit 1
fi

REPO="precisefuture/hello-artist-theme"

echo -e "${BLUE}📊 Setting up repository settings...${NC}"

# Set default branch to development
echo -e "${YELLOW}Setting default branch to development...${NC}"
gh api repos/$REPO -X PATCH -f default_branch=development || echo "Default branch may already be set"

# Enable/disable merge options
echo -e "${YELLOW}Configuring merge options...${NC}"
gh api repos/$REPO -X PATCH \
  -f allow_merge_commit=true \
  -f allow_squash_merge=false \
  -f allow_rebase_merge=false \
  -f allow_auto_merge=true \
  -f delete_branch_on_merge=true || echo "Merge options configuration may have failed"

echo -e "${GREEN}✅ Repository settings updated${NC}\n"

# Configure branch protection for development
echo -e "${BLUE}🛡️  Setting up branch protection for 'development'...${NC}"

gh api repos/$REPO/branches/development/protection -X PUT --input - << 'EOF'
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
    "require_code_owner_reviews": false,
    "dismiss_on_push": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo -e "${GREEN}✅ Development branch protection configured${NC}\n"

# Configure branch protection for production (main)
echo -e "${BLUE}🛡️  Setting up branch protection for 'main' (production)...${NC}"

# First create/sync main branch if needed
gh api repos/$REPO/git/refs -X POST --input - << 'EOF' || echo "Main branch may already exist"
{
  "ref": "refs/heads/main",
  "sha": "$(gh api repos/precisefuture/hello-artist-theme/git/refs/heads/development --jq '.object.sha')"
}
EOF

gh api repos/$REPO/branches/main/protection -X PUT --input - << 'EOF'
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
    "require_code_owner_reviews": false,
    "dismiss_on_push": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

echo -e "${GREEN}✅ Production branch protection configured${NC}\n"

# Create staging environment
echo -e "${BLUE}🏗️  Setting up 'staging' environment...${NC}"

gh api repos/$REPO/environments/staging -X PUT --input - << 'EOF'
{
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  }
}
EOF

# Add deployment branch policy for staging (development only)
gh api repos/$REPO/environments/staging/deployment-branch-policies -X POST --input - << 'EOF'
{
  "name": "development",
  "type": "branch"
}
EOF

echo -e "${GREEN}✅ Staging environment created${NC}\n"

# Create production environment  
echo -e "${BLUE}🏭  Setting up 'production' environment...${NC}"

gh api repos/$REPO/environments/production -X PUT --input - << 'EOF'
{
  "deployment_branch_policy": {
    "protected_branches": false,
    "custom_branch_policies": true
  },
  "protection_rules": [
    {
      "type": "required_reviewers",
      "reviewers": []
    },
    {
      "type": "wait_timer",
      "wait_timer": 5
    }
  ]
}
EOF

# Add deployment branch policy for production (main only)  
gh api repos/$REPO/environments/production/deployment-branch-policies -X POST --input - << 'EOF'
{
  "name": "main", 
  "type": "branch"
}
EOF

echo -e "${GREEN}✅ Production environment created${NC}\n"

# Set up repository variables for URLs
echo -e "${BLUE}📍 Setting up repository variables...${NC}"

gh variable set STAGING_URL --body "https://dev.ejfa.precisefuture.com"
gh variable set PRODUCTION_URL --body "https://ejfa.precisefuture.com"

echo -e "${GREEN}✅ Repository variables configured${NC}\n"

echo -e "${BLUE}🔑 Next steps - Configure these secrets manually:${NC}"
echo -e "${YELLOW}Staging environment secrets:${NC}"
echo "  - STAGING_HOST=tu-servidor-staging.com"
echo "  - STAGING_USER=deploy-user"
echo "  - STAGING_SSH_KEY=[clave SSH privada]"
echo "  - STAGING_PORT=22"
echo "  - STAGING_WP_PATH=/var/www/staging/wordpress"
echo ""
echo -e "${YELLOW}Production environment secrets:${NC}"  
echo "  - PRODUCTION_HOST=tu-servidor-prod.com"
echo "  - PRODUCTION_USER=deploy-user"
echo "  - PRODUCTION_SSH_KEY=[clave SSH privada]"
echo "  - PRODUCTION_PORT=22"
echo "  - PRODUCTION_WP_PATH=/var/www/html/wordpress"
echo ""
echo -e "${YELLOW}Optional repository secrets:${NC}"
echo "  - SLACK_WEBHOOK_URL=https://hooks.slack.com/services/..."
echo "  - CLOUDFLARE_ZONE_ID=zona-id-cloudflare"
echo "  - CLOUDFLARE_API_TOKEN=token-api-cloudflare"
echo ""
echo -e "${GREEN}🎉 GitHub repository setup completed!${NC}"
echo -e "${BLUE}💡 Run 'gh secret set SECRET_NAME --body \"value\"' to add secrets${NC}"
echo -e "${BLUE}💡 Run 'gh secret set SECRET_NAME --env staging --body \"value\"' for environment secrets${NC}"