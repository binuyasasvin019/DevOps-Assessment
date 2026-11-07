### Problem 1.1 — S3 Access Policy

The policy grants the user permission to list all S3 buckets in the account using `s3:ListAllMyBuckets`, while restricting bucket-content listing and object read/write access to `xyz-media`. Bucket-level and object-level permissions are separated because AWS S3 uses different resource ARNs for buckets and objects. Explicit deny statements prevent the user from deleting `xyz-media` or modifying its bucket policy, even if another identity-based policy grants those actions. Object deletion is not granted by this policy, following the principle of least privilege.

### Problem 1.2 — Administrative Access with IAM Self-Service

**Policy file:** `admin-self-service.json`

The policy provides broad administrative permissions for AWS services outside IAM using `NotAction`, while restricting IAM permissions to read-only operations through `iam:Get*` and `iam:List*`. It also allows users to manage their own passwords, access keys, and virtual MFA devices using the `${aws:username}` policy variable, which dynamically references the authenticated IAM user's name. IAM user and MFA device ARNs restrict these self-service operations to the corresponding resources. The policy assumes that virtual MFA devices are named after their owners. Although it meets the intended permission structure, broad non-IAM administrative access can introduce indirect privilege-escalation paths and should be subject to additional controls in production.

**IAM Identity Center alternative**

With IAM Identity Center, I would create a permission set granting administrative access to non-IAM AWS services and read-only IAM access, then assign it to the appropriate users or groups. Users would manage their passwords and MFA through their identity provider or Identity Center rather than IAM user self-service permissions, and short-lived role credentials would replace long-lived IAM user access keys.

### Problem 1.3 — Per-User Secrets Manager Access

**Policy file:** `per-user-secrets.json`

This policy allows IAM users to retrieve their own RDS credentials from AWS Secrets Manager using `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret`. The `${aws:username}` policy variable dynamically matches the authenticated IAM user's name to the corresponding secret, allowing the same policy to be attached to both `mark` and `harry`. The resource ARN includes six wildcard characters to match the random suffix appended by AWS Secrets Manager. Since the policy contains only an `Allow` statement and no explicit `Deny`, it does not restrict access to other secrets that may be granted through separate IAM policies. If the secret is encrypted with a customer-managed KMS key, additional `kms:Decrypt` permissions may be required.