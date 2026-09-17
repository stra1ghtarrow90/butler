# Terraform bootstrap

Creates the state backend for the later platform, DevOps, candidate and release roots. It does not deploy an application. See the [implementation plan](../../docs/azure-devsecops-implementation-plan.md) for the full lifecycle.

## Prerequisites

- Terraform 1.13 or newer (below 2.0); AzureRM is pinned and its lock file must be committed.
- Azure CLI sign-in with permissions to create subscription resources, budgets and scoped role assignments.
- The correct explicit subscription, tenant and human operator object IDs in a local `terraform.tfvars` file.
- `Microsoft.Consumption` already registered. This was verified for this lab; only the previously unregistered `Microsoft.Storage` registration is owned by this root.

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values. The local file, state and plans are ignored by Git. Set the budget's initial start date to the first day of the current month; keep it stable on subsequent runs. The budget is in the subscription billing currency and sends alerts, not spending restrictions. Confirm the subscription Owners receive billing notifications, or add a direct email recipient.

## Review and apply

From the repository root:

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap fmt -check
terraform -chdir=infra/bootstrap validate
terraform -chdir=infra/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap show bootstrap.tfplan
```

Review the actual plan and run the lab's IaC security checks before deploying. Scanner configuration is a separate implementation task; `validate` is not a security scan. Once ready, apply that saved plan:

```bash
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
terraform -chdir=infra/bootstrap plan -detailed-exitcode
```

The final command returns 0 for no changes, 2 for changes and 1 for an error. The first plan should contain nine additions: one provider registration, resource group, storage account, scoped role assignment and budget, plus four containers.

The backend is Standard LRS storage in UK South by default, with HTTPS, TLS 1.2, Entra authorization, private containers and seven-day soft-delete retention plus blob versioning. Its network endpoint remains publicly reachable for local and Microsoft-hosted agents; anonymous access and Shared Key authentication are disabled. Storage and retained versions can incur charges.

Azure role changes may take time to propagate. If an authenticated storage operation initially receives 403, check the role scope and allow propagation before rerunning a fresh plan. Do not re-enable access keys to work around it. If Cost Management is not ready on the new subscription, resolve that failure and re-plan; a partially successful apply may already have created other resources.

## State and recovery

Bootstrap intentionally uses local state at `infra/bootstrap/terraform.tfstate`. Securely back up this file after every apply and protect any backup file too. Never move bootstrap into the backend it owns, delete its state to resolve an error, or publish state/plans as ordinary reports. Provider state may contain sensitive storage properties even when keys are disabled.

`terraform output -json backend_configuration` (from this directory) returns only the non-secret backend settings for the later roots. Each root will declare an `azurerm` backend and use its own container. Pipeline authentication will use OIDC rather than the local CLI setting. Ordinary application identities must not receive account-wide state access.

Recover deleted state blobs through versioning/soft delete while the account still exists. Account deletion removes that recovery path. For lost local bootstrap state, recover its secure backup; if unavailable, inventory and import the existing resources instead of blindly recreating them.

## Destroy last

First destroy candidate/release apps and the dependent DevOps/platform resources using their respective states and retain any evidence. Only then:

```bash
terraform -chdir=infra/bootstrap plan -destroy -out=destroy.tfplan
terraform -chdir=infra/bootstrap show destroy.tfplan
terraform -chdir=infra/bootstrap apply destroy.tfplan
```

Destroying this root removes the remote state storage and unregisters Microsoft.Storage after its dependent resources are removed. Verify no other storage resources have been added to the subscription before doing so. The pre-existing Consumption registration remains. Keep independent operator sign-in available throughout teardown and check the subscription inventory afterwards.

The `expires_on` tag is a reminder, not an automatic teardown job. Subscription cancellation and previously incurred charges are outside this root.
