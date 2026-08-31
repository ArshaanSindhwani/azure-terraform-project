variable "project_name" {
  description = "Short name used as a prefix for resource naming"
  type        = string
  default     = "arshaan-azure-lab"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "uksouth"
}

variable "environment" {
  description = "Deployment environment tag, for example dev, staging, production"
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_subnet_prefix" {
  description = "Address prefix for the application subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}
