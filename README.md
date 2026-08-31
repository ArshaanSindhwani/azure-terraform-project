# Azure Terraform Platform Demo

## Overview
A small, deployable Azure environment built entirely with Terraform, created to demonstrate core platform engineering skills: infrastructure as code, network configuration, identity and access management, and CI/CD automation. The project provisions a resource group, a virtual network with a subnet and network security group, a storage account, and a containerised app with a managed identity, then wires the whole thing into a pipeline that validates, plans, and applies changes on merge to main.

## Tech Stack
- Terraform (azurerm provider)
- Azure: Resource Groups, Virtual Network, Subnets, NSGs, Storage Account, Container Apps, Entra ID managed identity, RBAC role assignments
- Azure DevOps Pipelines (primary CI/CD), with a GitHub Actions equivalent included as a fallback

## Key Features
- Infrastructure defined entirely in version-controlled Terraform, no manual portal changes
- Network segmented into its own subnet with an explicit-deny NSG, only HTTPS allowed in
- Container App authenticates to storage using a system-assigned managed identity, no connection strings or keys stored anywhere
- RBAC role assignment scoped to exactly the permission the app needs, Storage Blob Data Reader on a single storage account, not subscription-wide
- Runs on Azure Container Apps' consumption model rather than an App Service Plan, deliberately chosen to avoid the VM quota reservation that App Service Plans require and that new or trial subscriptions frequently do not have
- Three-stage pipeline: validate and format check, plan, then a gated apply that only runs from main
- Plan artifact generated once and reused for apply, so what gets approved is what gets deployed

## Architecture
```
GitHub / Azure Repos
        |
        v
  Pipeline: Validate -> Plan -> Apply (gated, main only)
        |
        v
  Resource Group (rg-arshaan-azure-lab-dev)
        |
        +-- Virtual Network (10.0.0.0/16)
        |      +-- Subnet: snet-app (10.0.1.0/24), NSG attached
        |
        +-- Storage Account (LRS, TLS 1.2 minimum)
        |      +-- Container: app-data (private)
        |
        +-- Container App Environment
               +-- Container App, system-assigned managed identity
                      +-- RBAC: Storage Blob Data Reader on the storage account
```

## My Contribution
Designed and built the full environment from scratch: wrote the Terraform configuration split across functionally named files (network, storage, compute, outputs), configured the managed identity and RBAC assignment so the app never handles storage credentials directly, and authored both the Azure DevOps pipeline and a GitHub Actions equivalent so the same infrastructure could be deployed from either platform. Initially built compute on an App Service Plan, then diagnosed a VM quota limitation on the underlying subscription and re-architected the compute layer onto Azure Container Apps instead, which uses a consumption model with no VM quota dependency.

## What I Learned
Coming from an AWS background, the closest thing to a surprise was how much of Azure's access model is identity-first rather than credential-first: a managed identity plus a scoped role assignment replaces what would otherwise be a stored secret. Working through NSG rule priority, storage account naming constraints, and the difference between authenticating a pipeline with a service principal versus workload identity federation were the parts that took the most deliberate reading rather than just following a tutorial. Hitting a real subscription-level quota error on the App Service Plan and having to re-architect around it, rather than just retrying, was the most useful part of the exercise. The next extension would be adding Azure Key Vault for any values that do need to be secrets, VNet-integrating the Container App Environment, and layering Azure Policy on top for governance at scale.
