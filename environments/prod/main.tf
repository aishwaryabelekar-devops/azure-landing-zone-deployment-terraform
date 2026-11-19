# ==============================================================================
# Main Infrastructure Definition: Production Environment (prod)
# Microsoft Cloud Adoption Framework (CAF) - Azure Landing Zone Implementation
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Platform Landing Zone: Resource Group & Hub Virtual Network
# ------------------------------------------------------------------------------
module "hub_rg" {
  source   = "../../modules/resource_group"
  name     = "rg-hub-${local.naming_prefix}"
  location = var.location
  tags     = merge(local.common_tags, { Tier = "Platform-Hub" })
}

module "hub_vnet" {
  source              = "../../modules/virtual_network"
  vnet_name           = "vnet-hub-${local.naming_prefix}"
  resource_group_name = module.hub_rg.name
  location            = module.hub_rg.location
  address_space       = var.hub_vnet_address_space
  tags                = merge(local.common_tags, { Tier = "Platform-Hub" })
}

module "hub_shared_subnet" {
  source               = "../../modules/subnet"
  name                 = "snet-shared-${local.naming_prefix}"
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefixes     = var.hub_shared_subnet_prefix
}

module "hub_gateway_subnet" {
  source               = "../../modules/subnet"
  name                 = "GatewaySubnet"
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefixes     = var.hub_gateway_subnet_prefix
}

module "hub_bastion_subnet" {
  source               = "../../modules/subnet"
  name                 = "AzureBastionSubnet"
  resource_group_name  = module.hub_rg.name
  virtual_network_name = module.hub_vnet.name
  address_prefixes     = var.hub_bastion_subnet_prefix
}

# ------------------------------------------------------------------------------
# 2. Application Landing Zone: Resource Group & Spoke Virtual Network
# ------------------------------------------------------------------------------
module "spoke_rg" {
  source   = "../../modules/resource_group"
  name     = "rg-spoke-${local.naming_prefix}"
  location = var.location
  tags     = merge(local.common_tags, { Tier = "Application-Spoke" })
}

module "spoke_vnet" {
  source              = "../../modules/virtual_network"
  vnet_name           = "vnet-spoke-${local.naming_prefix}"
  resource_group_name = module.spoke_rg.name
  location            = module.spoke_rg.location
  address_space       = var.spoke_vnet_address_space
  tags                = merge(local.common_tags, { Tier = "Application-Spoke" })
}

module "spoke_frontend_subnet" {
  source               = "../../modules/subnet"
  name                 = "snet-frontend-${local.naming_prefix}"
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefixes     = var.spoke_frontend_subnet_prefix
}

module "spoke_backend_subnet" {
  source               = "../../modules/subnet"
  name                 = "snet-backend-${local.naming_prefix}"
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefixes     = var.spoke_backend_subnet_prefix
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

module "spoke_database_subnet" {
  source               = "../../modules/subnet"
  name                 = "snet-database-${local.naming_prefix}"
  resource_group_name  = module.spoke_rg.name
  virtual_network_name = module.spoke_vnet.name
  address_prefixes     = var.spoke_database_subnet_prefix
}

# ------------------------------------------------------------------------------
# 3. Hub-and-Spoke Interconnectivity (VNet Peering)
# ------------------------------------------------------------------------------
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "peer-hub-to-spoke-${var.environment}"
  resource_group_name          = module.hub_rg.name
  virtual_network_name         = module.hub_vnet.name
  remote_virtual_network_id    = module.spoke_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-spoke-to-hub-${var.environment}"
  resource_group_name          = module.spoke_rg.name
  virtual_network_name         = module.spoke_vnet.name
  remote_virtual_network_id    = module.hub_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# ------------------------------------------------------------------------------
# 4. Network Security Groups & Subnet Associations (Hardened Production Rules)
# ------------------------------------------------------------------------------
module "spoke_frontend_nsg" {
  source              = "../../modules/network_security_group"
  name                = "nsg-frontend-${local.naming_prefix}"
  location            = module.spoke_rg.location
  resource_group_name = module.spoke_rg.name
  subnet_id           = module.spoke_frontend_subnet.id
  tags                = merge(local.common_tags, { Tier = "Frontend" })

  security_rules = [
    {
      name                       = "Allow-HTTPS-Inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Strictly permit TLS/HTTPS inbound for production workload"
    },
    {
      name                       = "Deny-HTTP-Inbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Explicitly block unencrypted HTTP traffic"
    }
  ]
}

module "spoke_backend_nsg" {
  source              = "../../modules/network_security_group"
  name                = "nsg-backend-${local.naming_prefix}"
  location            = module.spoke_rg.location
  resource_group_name = module.spoke_rg.name
  subnet_id           = module.spoke_backend_subnet.id
  tags                = merge(local.common_tags, { Tier = "Backend" })

  security_rules = [
    {
      name                       = "Allow-Frontend-To-Backend"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = var.spoke_frontend_subnet_prefix[0]
      destination_address_prefix = var.spoke_backend_subnet_prefix[0]
      description                = "Allow app API traffic only from frontend subnet"
    },
    {
      name                       = "Deny-Direct-Internet-Inbound"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
      description                = "Block all internet exposure to backend tier"
    }
  ]
}

module "spoke_database_nsg" {
  source              = "../../modules/network_security_group"
  name                = "nsg-database-${local.naming_prefix}"
  location            = module.spoke_rg.location
  resource_group_name = module.spoke_rg.name
  subnet_id           = module.spoke_database_subnet.id
  tags                = merge(local.common_tags, { Tier = "Database" })

  security_rules = [
    {
      name                       = "Allow-Backend-To-Database"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = var.spoke_backend_subnet_prefix[0]
      destination_address_prefix = var.spoke_database_subnet_prefix[0]
      description                = "Allow database queries strictly from backend tier"
    },
    {
      name                       = "Deny-All-Other-Inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Strict default deny for database tier"
    }
  ]
}

# ------------------------------------------------------------------------------
# 5. Security & Governance: Azure Key Vault (Production Hardened)
# ------------------------------------------------------------------------------
module "key_vault" {
  source                     = "../../modules/key_vault"
  name                       = "kv-${var.project_name}-${var.environment}-${var.location_short}-01"
  location                   = module.spoke_rg.location
  resource_group_name        = module.spoke_rg.name
  tenant_id                  = var.key_vault_tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 90
  purge_protection_enabled   = true # Production protection against accidental permanent deletion
  enable_rbac_authorization  = true
  tags                       = merge(local.common_tags, { Component = "Secrets-Management" })
}
