# Lab evidence

## 14 September 2026 — Local bootstrap preparation

- Azure CLI 2.90.0 installed and verified; Terraform 1.13.4 available on Darwin ARM64.
- Azure CLI sign-in verified against the enabled `devops-test-subscription` subscription.
- Signed-in operator has the subscription Owner role. Local subscription, tenant and operator IDs are recorded in ignored `infra/bootstrap/terraform.tfvars`.
- Resource-group inventory was empty. Microsoft.Storage was NotRegistered; Microsoft.Consumption was Registered.
- Added a minimal bootstrap using AzureRM 5.5.0, its dependency lock file, local input example and apply/recovery/teardown instructions.
- `terraform init`, `terraform fmt -check` and `terraform validate` passed.
- Authenticated `terraform plan -input=false -out=bootstrap.tfplan` succeeded: **9 additions, 0 changes, 0 deletions**.
- Proposed configuration: UK South, Standard LRS state storage, four private containers, scoped operator Blob access, Storage registration and monthly budget alerts at 50/80/100% of 20 billing-currency units. Draft teardown reminder: 14 October 2026. These defaults have not been confirmed by the user.
- State and plan artifacts and local inputs are excluded from Git and Docker build context. Bootstrap state must be backed up securely after apply.

**Not completed:** IaC scanner setup/security scan, final settings/cost review, Terraform apply, backend access/locking verification and actual alert delivery. No Azure resources have been created by this work. The saved plan is local and ignored by Git; regenerate it if settings or configuration change before deployment.
