# Azure Terraform Platform Demo

## Overview

This project is a small Azure platform environment built with Terraform. It provisions a resource group, virtual network, subnet and network security group, a storage account with a private blob container, and an Azure Container App with a system-assigned managed identity.

It is intended as a practical demonstration of infrastructure as code, Azure identity and access management, remote Terraform state, and continuous delivery. The Azure DevOps pipeline validates the configuration, creates a saved plan, and applies that exact plan for changes pushed to `main`.

## Design approach

This repository is deliberately small enough to understand end to end, while covering the decisions that matter in a real platform environment: how resources are defined, how identities gain access, how changes are reviewed, and how repeatable deployments are made.

- **Infrastructure as code:** Terraform defines the Azure resources, provider requirements, remote state, variables, and outputs. The same environment can be reviewed, reproduced, and changed through version control rather than manual portal steps.
- **Networking:** A VNet, application subnet, and NSG establish the network boundary. This demonstrates address planning and traffic control, and provides a starting point for private integration.
- **Workload platform:** Azure Container Apps runs the public sample container. It provides a managed, consumption-based platform without managing virtual machines or an App Service Plan.
- **Access management:** The Container App has a system-assigned managed identity with a storage-scoped RBAC role. The workload can use an Azure identity instead of a stored storage key, and its permissions are limited to the intended storage account.
- **Data storage:** A private blob container sits in an LRS storage account with TLS 1.2 as the minimum version. The configuration makes the storage scope and baseline transport security explicit.
- **Delivery automation:** Azure DevOps validates, plans, publishes, and applies Terraform changes. A saved plan creates a clear hand-off between review and deployment, while the pipeline makes the process repeatable.

Two choices are worth calling out. The VNet and NSG are foundation resources, not active controls for the current Container App, because the environment is not VNet-integrated. Also, the hello-world sample image does not yet read from Blob Storage. The identity and role assignment are present so that a real application can add that integration without introducing a storage secret.

## What is provisioned

- Resource group: `rg-arshaan-azure-lab-dev`
- Virtual network: `10.0.0.0/16`
- Application subnet: `10.0.1.0/24`, with an NSG that permits inbound HTTPS and denies other inbound traffic
- Standard LRS storage account with TLS 1.2 as the minimum version
- Private `app-data` blob container
- Azure Container Apps environment and a public Container App
- System-assigned managed identity for the Container App
- `Storage Blob Data Reader` role assignment scoped to the storage account

## Architecture

```text
Git repository
    |
    v
Azure DevOps pipeline: Validate -> Plan -> Apply
    |
    v
Resource group
    |
    + Virtual network
    |  + Application subnet and network security group
    |
    + Storage account
    |  + Private app-data container
    |
    + Container Apps environment
       + Public Container App
         + System-assigned managed identity
           + Storage Blob Data Reader on the storage account
```

The virtual network, subnet and NSG are included as network foundations for a later private or VNet-integrated deployment. The current Container Apps environment uses the consumption model and is not VNet-integrated, so the NSG does not govern traffic to the running Container App.

The sample container image is Azure's public Container Apps hello-world image. The managed identity and RBAC assignment give the app permission to read blobs if storage access is added to the application; the sample image does not currently access the storage account.

## CI/CD

The primary pipeline is [azure-pipelines.yml](azure-pipelines.yml). It runs when a change is pushed to `main` and has three stages:

1. **Validate** installs Terraform, initialises without the remote backend, checks formatting, and validates the configuration.
2. **Plan** initialises the Azure Storage backend, creates `tfplan`, and publishes it as a pipeline artefact.
3. **Apply** runs only for `main`, downloads the saved artefact, reinitialises the backend, and applies that same plan.

The apply job targets the Azure DevOps `production` environment. Approval checks can be configured on that environment in Azure DevOps if a manual release gate is required. Terraform runs with `-auto-approve` because the pipeline is applying the saved plan rather than prompting interactively.

A GitHub Actions workflow is also included in [.github/workflows/terraform.yml](.github/workflows/terraform.yml) as an alternative implementation. It contains the same validate, plan, and apply pattern, with a pull request trigger. It receives its Azure credentials from repository secrets.

## State and authentication

Terraform state is stored remotely in an Azure Storage container, configured in [backend.tf](backend.tf). The state storage account and container must be created before the first pipeline run.

Both CI/CD implementations authenticate with the standard `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, and `ARM_TENANT_ID` values. In Azure DevOps, they are configured as secret pipeline variables. In GitHub Actions, they are stored as repository secrets and passed to Terraform as environment variables. The values are not committed to this repository.

The Container App uses a system-assigned managed identity. Terraform grants that identity the least privilege needed for the intended storage integration: `Storage Blob Data Reader` on this project’s storage account. No storage access keys or connection strings are placed in the Container App configuration.

## Prerequisites

- Terraform 1.7 or later
- An Azure subscription and permission to create the resources listed above
- An existing Azure Storage backend matching `backend.tf`
- Azure credentials available locally or supplied as pipeline variables

## Running locally

Copy the example variables file and adjust it if needed:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Then initialise, review, and apply the configuration:

```sh
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

`terraform.tfvars` is ignored by Git. The resource group location is currently set directly to `eastus` in `resource_group.tf`; the `location` variable is retained for future use and is not currently consumed by the resources.

## Repository layout

```text
backend.tf                 Remote Azure Storage state configuration
providers.tf               Terraform and provider version requirements
resource_group.tf          Resource group
network.tf                 Virtual network, subnet, and NSG
storage.tf                 Storage account and private blob container
compute.tf                 Container Apps environment, app, identity, and RBAC
variables.tf               Input variables
outputs.tf                 Useful deployment outputs
azure-pipelines.yml        Azure DevOps CI/CD pipeline
.github/workflows/         GitHub Actions alternative workflow
```

## Possible next steps

- Integrate the Container Apps environment with the VNet and apply the NSG-backed network design to the workload.
- Replace the sample image with an application that reads from Blob Storage using managed identity.
- Add Azure Key Vault for application secrets that cannot use managed identity.
- Configure Azure Policy and diagnostic settings for a more production-oriented baseline.
