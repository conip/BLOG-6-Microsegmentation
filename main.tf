#---------------------------------------------------------- Transit ----------------------------------------------------------
module "mc_transit" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "v2.1.1"
  cloud   = "Azure"
  name    = "${local.env_prefix}-AZ-trans-1"
  region  = var.azure_region
  cidr    = "10.200.0.0/23"
  account = var.avx_ctrl_account_azure
  # ha_gw                  = true
  local_as_number        = "65101"
  enable_transit_firenet = true
  #enable_egress_transit_firenet = true   # for dual TRansit (1 for E/W and 1 for N/S - for this one only)
  #connected_transit             = true ()
  tags = {
    Owner = "pkonitz"
  }
}

module "mc-spoke-1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"
  # insert the 22 required variables here
  cloud = "Azure"
  #  ha_gw                  = false
  account = var.avx_ctrl_account_azure
  cidr    = "10.201.0.0/16"
  name    = "${local.env_prefix}-spoke1"
  region  = var.azure_region
  #attached = false
  transit_gw = module.mc_transit.transit_gateway.gw_name
  depends_on = [
    module.mc_transit
  ]
}


module "spoke_1_vm1" {
  source    = "git::https://github.com/conip/terraform-azure-instance-build-module.git?ref=v1.0.2"
  name      = "${local.env_prefix}-spoke1-vm1"
  region    = var.azure_region
  rg        = module.mc-spoke-1.vpc.resource_group
  subnet_id = module.mc-spoke-1.vpc.public_subnets[1].subnet_id
  ssh_key   = var.ssh_key
  public_ip = true
  tags = {
    ENV   = "DEV"
    OWNER = "TEAM1"
  }
  depends_on = [
    module.mc-spoke-1
  ]
}

module "spoke_1_vm2" {
  source    = "git::https://github.com/conip/terraform-azure-instance-build-module.git?ref=v1.0.2"
  name      = "${local.env_prefix}-spoke1-vm2"
  region    = var.azure_region
  rg        = module.mc-spoke-1.vpc.resource_group
  subnet_id = module.mc-spoke-1.vpc.public_subnets[1].subnet_id
  ssh_key   = var.ssh_key
  public_ip = true
  tags = {
    ENV   = "PROD",
    OWNER = "TEAM2"
  }
  depends_on = [
    module.mc-spoke-1
  ]
}


module "mc-spoke-2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "1.2.1"
  # insert the 22 required variables here
  cloud = "Azure"
  #    ha_gw                  = false
  account = var.avx_ctrl_account_azure
  cidr    = "10.202.0.0/16"
  name    = "${local.env_prefix}-spoke2"
  region  = var.azure_region
  #attached = false
  transit_gw = module.mc_transit.transit_gateway.gw_name
  depends_on = [
    module.mc_transit
  ]
}

module "spoke_2_vm1" {
  source    = "git::https://github.com/conip/terraform-azure-instance-build-module.git?ref=v1.0.2"
  name      = "${local.env_prefix}-spoke2-vm1"
  region    = var.azure_region
  rg        = module.mc-spoke-2.vpc.resource_group
  subnet_id = module.mc-spoke-2.vpc.private_subnets[1].subnet_id
  ssh_key   = var.ssh_key
  public_ip = true
  tags = {
    ENV   = "DEV",
    OWNER = "TEAM3"
  }
  depends_on = [
    module.mc-spoke-2
  ]
}

module "spoke_2_vm2" {
  source = "git::https://github.com/conip/terraform-azure-instance-build-module.git?ref=v1.0.2"

  name      = "${local.env_prefix}-spoke2-vm2"
  region    = var.azure_region
  rg        = module.mc-spoke-2.vpc.resource_group
  subnet_id = module.mc-spoke-2.vpc.private_subnets[1].subnet_id
  ssh_key   = var.ssh_key
  public_ip = true
  tags = {
    ENV   = "PROD",
    OWNER = "TEAM4"
  }
  depends_on = [
    module.mc-spoke-2
  ]
}


#------------------------------- MICROSEGMENTATION --------------------------------------

resource "aviatrix_app_domain" "PROD-domain" {
  name = "PROD-domain"
  selector {
    match_expressions {
      type = "vm"
      tags = { ENV = "PROD" }
    }
    match_expressions {
      type = "vpc"
      tags = { name = "BLOG6-spoke1" }
    }

  }
}

resource "aviatrix_app_domain" "DEV-domain" {
  name = "DEV-domain"
  selector {
    match_expressions {
      type = "vm"
      tags = { ENV = "DEV" }
    }
  }
}

resource "aviatrix_app_domain" "default-domain" {
  name = "default-domain"
  selector {
    match_expressions {
      cidr = "0.0.0.0/0"
    }
  }
}


resource "aviatrix_microseg_policy_list" "test" {
  policies {
    name     = "PROD-PROD"
    action   = "PERMIT"
    priority = 20
    protocol = "ICMP"
    logging  = true
    watch    = false
    src_app_domains = [
      aviatrix_app_domain.PROD-domain.uuid
    ]
    dst_app_domains = [
      aviatrix_app_domain.PROD-domain.uuid
    ]
  }

  policies {
    name     = "DENY-TCP"
    action   = "DENY"
    priority = 10
    protocol = "TCP"
    logging  = true
    watch    = false # Enforcement off or on

    port_ranges {
      hi = 50000
      lo = 22
    }
    src_app_domains = [
      aviatrix_app_domain.default-domain.uuid
    ]
    dst_app_domains = [
      aviatrix_app_domain.default-domain.uuid
    ]
  }

  policies {
    name     = "DEV-DEV"
    action   = "PERMIT"
    priority = 2
    protocol = "ICMP"
    logging  = true
    watch    = false
    src_app_domains = [
      aviatrix_app_domain.DEV-domain.uuid
    ]
    dst_app_domains = [
      aviatrix_app_domain.DEV-domain.uuid
    ]
  }

  policies {
    name     = "test"
    action   = "PERMIT"
    priority = 15
    protocol = "ICMP"
    logging  = true
    watch    = false
    src_app_domains = [
      aviatrix_app_domain.PROD-domain.uuid
    ]
    dst_app_domains = [
      aviatrix_app_domain.PROD-domain.uuid
    ]
  }

}
