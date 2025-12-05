# Route53 Dynamic DNS Updater

Automatically updates a Route53 DNS A record with your current public IP address.

## Configuration

Update the following values in `route53-secret.yaml`:

- `HOSTED_ZONE_ID`: Your Route53 hosted zone ID (e.g., Z1234567890ABC)
- `RECORD_NAME`: The DNS record to update (e.g., home.yourdomain.com)
- `AWS_REGION`: Your AWS region (default: us-east-1)
- `RECORD_TTL`: DNS TTL in seconds (default: 300)

The AWS credentials are already populated from your terraform profile.

## Encryption

Before committing, encrypt the secret:

```bash
sops --encrypt --in-place clusters/home/apps/route53-ddns/route53-secret.yaml
```

## How It Works

- CronJob runs every 5 minutes
- Checks your current public IP (via ipify.org)
- Compares with current Route53 DNS record
- Updates Route53 only if IP has changed
- Logs all actions

## IAM Policy Required

Your IAM user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID"
    }
  ]
}
```

## Monitoring

```bash
# View recent jobs
kubectl get jobs -n route53-ddns

# View logs from latest job
kubectl logs -n route53-ddns -l job-name=$(kubectl get jobs -n route53-ddns -o jsonpath='{.items[-1].metadata.name}')

# Watch logs in real-time
kubectl get pods -n route53-ddns -w
```

## Customization

To change update frequency, edit `cronjob.yaml` schedule:
- Every 5 minutes: `*/5 * * * *` (current)
- Every 15 minutes: `*/15 * * * *`
- Every hour: `0 * * * *`
- Every 30 minutes: `*/30 * * * *`
