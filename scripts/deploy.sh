#!/bin/bash
#
# Azure Landing Zone Deployment Script (Bash)
# This script deploys the Azure Landing Zone using Bicep templates
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

function info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
function success() { echo -e "${GREEN}✅ $1${NC}"; }
function error() { echo -e "${RED}❌ $1${NC}"; exit 1; }
function warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Parse arguments
CUSTOMER=""
PHASE="full"
LOCATION=""
WHAT_IF=false
MODE="greenfield"
MANAGEMENT_GROUP_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--customer)
            CUSTOMER="$2"
            shift 2
            ;;
        -p|--phase)
            PHASE="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -w|--what-if)
            WHAT_IF=true
            shift
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -g|--management-group)
            MANAGEMENT_GROUP_ID="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 -c <customer> -l <location> [options]"
            echo ""
            echo "Options:"
            echo "  -c, --customer          Customer parameter file name (required)"
            echo "  -l, --location          Primary Azure region (required)"
            echo "  -p, --phase             Deployment phase: full, core, governance (default: full)"
            echo "  -w, --what-if           Perform validation-only deployment"
            echo "  -m, --mode              Deployment mode: greenfield, brownfield (default: greenfield)"
            echo "  -g, --management-group  Management group ID for deployment"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate required parameters
if [[ -z "$CUSTOMER" ]]; then
    error "Customer parameter is required. Use -c or --customer"
fi

if [[ -z "$LOCATION" ]]; then
    error "Location parameter is required. Use -l or --location"
fi

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PARAMETER_FILE="$ROOT_DIR/parameters/$CUSTOMER.bicepparam"
MAIN_BICEP_FILE="$ROOT_DIR/main.bicep"
DEPLOYMENT_NAME="alz-deployment-$(date +%Y%m%d-%H%M%S)"

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║         Azure Landing Zone Deployment Script                   ║
║         Bicep Implementation - Audit Ready                      ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

info "Customer: $CUSTOMER"
info "Phase: $PHASE"
info "Location: $LOCATION"
info "Mode: $MODE"
info "WhatIf: $WHAT_IF"
echo ""

# Prerequisites check
info "Checking prerequisites..."

# Check Azure CLI
if ! command -v az &> /dev/null; then
    error "Azure CLI is not installed"
fi
AZ_VERSION=$(az version --query '"azure-cli"' -o tsv)
success "Azure CLI version: $AZ_VERSION"

# Check Bicep CLI
if ! az bicep version &> /dev/null; then
    warning "Bicep CLI not found. Installing..."
    az bicep install
fi
BICEP_VERSION=$(az bicep version)
success "Bicep CLI version: $BICEP_VERSION"

# Check if logged in
if ! az account show &> /dev/null; then
    error "Not logged in to Azure. Please run 'az login'"
fi
ACCOUNT_NAME=$(az account show --query "user.name" -o tsv)
SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
success "Logged in as: $ACCOUNT_NAME"
success "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Check parameter file
if [[ ! -f "$PARAMETER_FILE" ]]; then
    error "Parameter file not found: $PARAMETER_FILE"
fi
success "Parameter file found: $PARAMETER_FILE"

# Check main Bicep file
if [[ ! -f "$MAIN_BICEP_FILE" ]]; then
    error "Main Bicep file not found: $MAIN_BICEP_FILE"
fi
success "Main Bicep file found: $MAIN_BICEP_FILE"

echo ""

# Validate Bicep template
info "Validating Bicep template..."
mkdir -p "$ROOT_DIR/temp"
if az bicep build --file "$MAIN_BICEP_FILE" --outdir "$ROOT_DIR/temp" &> /dev/null; then
    success "Bicep template validation passed"
else
    error "Bicep template validation failed"
fi

echo ""

# Determine deployment scope
if [[ -n "$MANAGEMENT_GROUP_ID" ]]; then
    DEPLOYMENT_SCOPE="mg"
    info "Deploying to Management Group: $MANAGEMENT_GROUP_ID"
else
    DEPLOYMENT_SCOPE="tenant"
    info "Deploying at Tenant scope"
    warning "Ensure you have tenant-level permissions"
fi

echo ""

# Build deployment command
DEPLOY_CMD="az deployment $DEPLOYMENT_SCOPE create \
    --name \"$DEPLOYMENT_NAME\" \
    --location \"$LOCATION\" \
    --template-file \"$MAIN_BICEP_FILE\" \
    --parameters \"$PARAMETER_FILE\""

if [[ "$DEPLOYMENT_SCOPE" == "mg" ]]; then
    DEPLOY_CMD="$DEPLOY_CMD --management-group-id \"$MANAGEMENT_GROUP_ID\""
fi

if [[ "$WHAT_IF" == true ]]; then
    DEPLOY_CMD="$DEPLOY_CMD --what-if"
    warning "Running in WhatIf mode - no resources will be deployed"
fi

echo ""

# Confirmation prompt (skip if WhatIf)
if [[ "$WHAT_IF" == false ]]; then
    warning "This will deploy Azure Landing Zone resources."
    warning "This may incur costs in your Azure subscription."
    read -p "Do you want to continue? (yes/no): " CONFIRMATION
    
    if [[ "$CONFIRMATION" != "yes" ]]; then
        info "Deployment cancelled by user"
        exit 0
    fi
fi

echo ""

# Execute deployment
info "Starting deployment..."
info "Deployment name: $DEPLOYMENT_NAME"
echo ""

START_TIME=$(date +%s)

if eval "$DEPLOY_CMD"; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    success "Deployment completed successfully!"
    info "Duration: $(date -u -d @${DURATION} +%T)"
    
    # Get deployment outputs
    echo ""
    info "Retrieving deployment outputs..."
    
    OUTPUT_CMD="az deployment $DEPLOYMENT_SCOPE show --name \"$DEPLOYMENT_NAME\""
    if [[ "$DEPLOYMENT_SCOPE" == "mg" ]]; then
        OUTPUT_CMD="$OUTPUT_CMD --management-group-id \"$MANAGEMENT_GROUP_ID\""
    fi
    
    OUTPUTS=$(eval "$OUTPUT_CMD --query 'properties.outputs' -o json")
    
    success "Deployment outputs:"
    echo "$OUTPUTS" | jq '.'
    
    # Save outputs to file
    mkdir -p "$ROOT_DIR/outputs"
    OUTPUT_FILE="$ROOT_DIR/outputs/$CUSTOMER-$DEPLOYMENT_NAME.json"
    echo "$OUTPUTS" > "$OUTPUT_FILE"
    success "Outputs saved to: $OUTPUT_FILE"
    
else
    error "Deployment failed. Check Azure Portal for detailed error messages"
fi

echo ""

# Next steps
info "Next Steps:"
echo -e "${YELLOW}1. Review deployment outputs above${NC}"
echo -e "${YELLOW}2. Configure Entra ID conditional access policies${NC}"
echo -e "${YELLOW}3. Connect ExpressRoute circuit (if applicable)${NC}"
echo -e "${YELLOW}4. Create spoke virtual networks${NC}"
echo -e "${YELLOW}5. Run Azure Landing Zone Review assessment${NC}"
echo -e "${YELLOW}6. Document configuration for audit evidence${NC}"

echo ""
success "Deployment script completed"
