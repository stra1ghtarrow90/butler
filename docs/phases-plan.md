# Phases plan

Updated: 17 September 2026.

Use this file for the next hands-on phase. The [full implementation plan](azure-devsecops-implementation-plan.md) covers the complete lab; record completed checks in [lab evidence](lab-evidence.md).

## Next phase — Review, scan and deploy the Terraform bootstrap

**Outcome:** create the remote state storage needed by later Terraform roots, configure budget alerts, and verify authenticated storage access. Application infrastructure and Azure DevOps configuration follow in later phases.

**Starting point:** bootstrap configuration is prepared. Its last recorded validation and plan succeeded on 14 September, with nine additions. Deployment has not been recorded as completed. Generate a fresh plan instead of relying on that earlier artifact.

Run each step individually in the same terminal session and inspect its result before continuing.

### 1. Confirm the subscription and settings

- [ ] Check the active subscription and review the explicit subscription/tenant IDs in the local input file.
- [ ] Confirm the region, budget, alert recipients and intended teardown date.

```bash
cd /Users/msalter/github/butler
umask 077

az account show \
  --query '{name:name,subscriptionId:id,tenantId:tenantId,state:state}' \
  --output json

nano infra/bootstrap/terraform.tfvars
```

The expected subscription name is `devops-test-subscription`. The local file already contains the subscription, tenant and operator IDs; Terraform uses its explicit subscription setting, so check it agrees with your intended target.

Review these draft values:

```hcl
location              = "uksouth"
monthly_budget_amount = 20
budget_start_date     = "2026-09-01"
expires_on            = "2026-10-14"
budget_contact_emails = []
```

The budget uses the subscription billing currency and sends alerts; it does not cap spending. Alerts go to subscription Owners. Add a direct recipient, such as `["your-email@example.com"]`, if desired. For the first deployment, use the first day of the current month as `budget_start_date`; keep it stable after deployment. The `expires_on` tag is a reminder, not an automatic deletion job.

### 2. Validate and generate a fresh plan

- [ ] Initialization, formatting and validation succeed.
- [ ] Review the saved plan, including subscription, region, resource names and role scope.

```bash
terraform -chdir=infra/bootstrap init -input=false
terraform -chdir=infra/bootstrap fmt -check
terraform -chdir=infra/bootstrap validate
terraform -chdir=infra/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infra/bootstrap show bootstrap.tfplan
```

For the first deployment with the current configuration, expect **9 additions, 0 changes and 0 deletions**:

| Item | Count |
| --- | ---: |
| State resource group | 1 |
| Standard LRS storage account | 1 |
| Private containers: platform, devops, candidate, release | 4 |
| Operator Storage Blob Data Contributor assignment | 1 |
| Microsoft.Storage registration | 1 |
| Monthly subscription budget | 1 |

If resources have already been partially deployed, the count can differ. Investigate the difference before applying. Terraform validation checks configuration correctness; it is not a security scan.

### 3. Scan the source and saved plan

- [ ] Docker Desktop is running.
- [ ] Both scans finish successfully and inspect the intended resources.
- [ ] Findings are fixed or covered by narrowly scoped, documented and reviewed exceptions.

Start Docker Desktop if needed and wait until `docker info` succeeds:

```bash
open -a Docker
docker info
```

Pull Checkov 3.3.17 using the published image digest verified when these instructions were prepared:

```bash
CHECKOV_IMAGE="bridgecrew/checkov:3.3.17@sha256:41c4701c6a56d8952e5aba7a420f871c8b70b57da94eb4f142dcdf7295bb0be3"
docker pull "$CHECKOV_IMAGE"
```

Scan the Terraform source:

```bash
docker run --rm \
  -v "$PWD/infra/bootstrap:/tf:ro" \
  "$CHECKOV_IMAGE" \
  --directory /tf \
  --framework terraform \
  --skip-download \
  --compact
```

Export and scan the exact saved plan:

```bash
terraform -chdir=infra/bootstrap show -json bootstrap.tfplan \
  > infra/bootstrap/bootstrap.tfplan.json

docker run --rm \
  -v "$PWD/infra/bootstrap:/tf:ro" \
  "$CHECKOV_IMAGE" \
  --file /tf/bootstrap.tfplan.json \
  --framework terraform_plan \
  --skip-download \
  --compact
```

These scans mount the bootstrap directory read-only and receive no Azure credentials. Keep plan JSON and state private; both are excluded from Git. See [Checkov Docker usage](https://www.checkov.io/4.Integrations/Docker.html) and [Terraform plan scanning](https://www.checkov.io/7.Scan%20Examples/Terraform%20Plan%20Scanning.html).

**Review checkpoint:** if either scan fails or encounters an error, bring its summary and failed check IDs back to our working session before applying. Public network reachability is an intentional lab choice, but any associated finding still needs an explicit assessment. Do not use blanket skips or `--soft-fail` to make the gate pass. Record exceptions with their rationale, scope, owner and expiry as described in the implementation plan.

After changing configuration or input values, regenerate the saved plan and repeat the scans. A successful scan of an earlier plan does not cover the changed deployment.

### 4. Apply the reviewed plan

- [ ] Confirm that the plan and scan results refer to the same current configuration.
- [ ] Apply succeeds, or any partial failure is recorded and resolved.

This command creates resources and can start storage charges. Applying a saved plan does **not** ask for another confirmation:

```bash
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
```

If it fails partway through, preserve the state and record the error: some resources may already exist. Resolve the cause, generate a fresh plan and repeat review/scanning before retrying. Do not delete state or re-enable storage access keys as a workaround.

### 5. Back up the local bootstrap state

- [ ] Save a protected local backup after the apply, including after a partial apply that created resources.
- [ ] Keep an additional secure backup off the laptop.

```bash
butler_backup_dir="$HOME/.local/share/butler/terraform-backups/$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$butler_backup_dir"
chmod 700 "$butler_backup_dir"
cp infra/bootstrap/terraform.tfstate "$butler_backup_dir/"
chmod 600 "$butler_backup_dir/terraform.tfstate"
```

Bootstrap state remains local so it can destroy the remote backend last. Do not commit it or migrate it into the storage account it owns. Repeat the backup after future bootstrap changes.

### 6. Verify the deployed resources

- [ ] A new Terraform plan reports no changes.
- [ ] Entra-authenticated access lists all four containers.
- [ ] Budget configuration and recipients are checked in Azure Cost Management.

```bash
terraform -chdir=infra/bootstrap plan -detailed-exitcode
echo $?
```

Expect **No changes** and exit code `0`. Code `2` means changes remain; code `1` means an error.

```bash
butler_state_account="$(terraform -chdir=infra/bootstrap output -raw storage_account_name)"

az storage container list \
  --account-name "$butler_state_account" \
  --auth-mode login \
  --query "[].name" \
  --output table
```

Expect `candidate`, `devops`, `platform` and `release`. For an initial `403`, verify the role scope and allow time for role propagation before retrying. Listing containers proves this operator's access; backend locking and pipeline identity isolation will be verified when the later roots are initialized.

### Completion and handoff

- [ ] Update [lab evidence](lab-evidence.md) with deployment date, plan counts, scan summaries, reviewed exceptions, verification results and backup confirmation. Do not include credentials or state contents.
- [ ] Keep `.terraform.lock.hcl` and the configuration in version control; keep local inputs, state, plans and reports out of Git.
- [ ] Proceed to the platform phase only after this bootstrap is verified.

The following phase will implement shared Azure infrastructure—registry, Container Apps environment, logging and scoped identities—using the `platform` remote state container. Azure DevOps configuration follows in its own root. Final teardown instructions are in the [bootstrap runbook](../infra/bootstrap/README.md#destroy-last); do not destroy the backend while other roots still depend on it.
