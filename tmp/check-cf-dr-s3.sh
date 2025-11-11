#!/usr/bin/env bash
# filepath: /tmp/check-cf-dr.sh
set -euo pipefail

# --- CONFIGURE these ---
DR_BUCKET="wordpress-media-dr-200"
KEY="wp-content/uploads/2025/11/10083347/Coraline_poster.jpg"
CLOUDFRONT_URL="https://qays.cloud"   # CloudFront alias or distribution domain
REGION="ca-central-1"

# how long to poll for logs (seconds)
MAX_POLL_SECONDS=900
POLL_INTERVAL=15

# temp work dir
TS=$(date -u +%Y%m%dT%H%M%SZ)
TMPDIR="/tmp/cf-dr-check-$TS"
mkdir -p "$TMPDIR"
echo "Working directory: $TMPDIR"

# 1) create a temporary log bucket (unique)
LOG_BUCKET="cf-dr-logs-45648646"
echo "Creating log bucket: $LOG_BUCKET (region $REGION)"
aws s3 mb "s3://$LOG_BUCKET" --region "$REGION"

# Allow S3 Log Delivery group to write logs
aws s3api put-bucket-acl \
  --bucket "$LOG_BUCKET" \
  --grant-write 'uri="http://acs.amazonaws.com/groups/s3/LogDelivery"' \
  --grant-read-acp 'uri="http://acs.amazonaws.com/groups/s3/LogDelivery"' \
  --region "$REGION"

# 2) enable server access logging on DR bucket (one-shot)
echo "Enabling access logging on $DR_BUCKET -> $LOG_BUCKET/dr-logs/"
aws s3api put-bucket-logging --bucket "$DR_BUCKET" \
  --bucket-logging-status "{\"LoggingEnabled\": {\"TargetBucket\":\"$LOG_BUCKET\", \"TargetPrefix\":\"dr-logs/\"}}" \
  --region "$REGION"

# 3) make the CloudFront request (causes edge to fetch origin if needed)
echo "Requesting $CLOUDFRONT_URL/$KEY"
curl -sS -I -L "${CLOUDFRONT_URL}/${KEY}" | sed -n '1,120p' || true

# 4) poll the log bucket for the new log file(s)
echo "Polling for logs (max ${MAX_POLL_SECONDS}s)..."
end=$((SECONDS + MAX_POLL_SECONDS))
found_key=""
while [ $SECONDS -lt $end ]; do
  # list recent keys under prefix
  recent=$(aws s3 ls "s3://$LOG_BUCKET/dr-logs/" --recursive --region "$REGION" | tail -n 20 || true)
  if echo "$recent" | grep -q '\.log'; then
    # find newest
    newest_key=$(echo "$recent" | awk '{print $4}' | sort | tail -n1)
    if [ -n "$newest_key" ]; then
      echo "Found log: $newest_key"
      found_key="$newest_key"
      break
    fi
  fi
  sleep "$POLL_INTERVAL"
done

if [ -z "$found_key" ]; then
  echo "No logs found within timeout ($MAX_POLL_SECONDS s). Logs can take several minutes to appear."
  echo "You can check later with: aws s3 ls s3://$LOG_BUCKET/dr-logs/ --region $REGION"
  exit 2
fi

# 5) download the log file and search for the key
aws s3 cp "s3://$LOG_BUCKET/$found_key" "$TMPDIR/dr-s3-log.txt" --region "$REGION"
echo "Saved log to $TMPDIR/dr-s3-log.txt"
echo "Searching logs for $KEY ..."
grep -n -- "$KEY" "$TMPDIR/dr-s3-log.txt" || true

# Print matching lines and extract remote IPs (S3 log format: remote IP is 4th field)
matches=$(grep -- "$KEY" "$TMPDIR/dr-s3-log.txt" || true)
if [ -z "$matches" ]; then
  echo "No GetObject record for the key found in this log file."
  echo "You may need to wait longer for logs or check other log files in $LOG_BUCKET/dr-logs/"
  exit 3
fi

echo "Matching log lines:"
echo "$matches"
echo
echo "Extracting client IP(s):"
ips=$(echo "$matches" | awk '{print $4}' | sort -u)
echo "$ips" > "$TMPDIR/requester-ips.txt"
cat "$TMPDIR/requester-ips.txt"

# 6) check each client IP against CloudFront IP ranges (CIDR containment)
echo "Fetching CloudFront IP ranges..."
curl -s 'https://ip-ranges.amazonaws.com/ip-ranges.json' -o "$TMPDIR/ip-ranges.json"
python3 - <<PY
import json, ipaddress, sys
ip_ranges = json.load(open("$TMPDIR/ip-ranges.json"))["prefixes"]
cf_cidrs = [p["ip_prefix"] for p in ip_ranges if p.get("service") == "CLOUDFRONT"]
ips = open("$TMPDIR/requester-ips.txt").read().strip().splitlines()
def in_cf(ip):
    a = ipaddress.IPv4Address(ip)
    for cidr in cf_cidrs:
        if a in ipaddress.IPv4Network(cidr):
            return cidr
    return None
for ip in ips:
    cid = in_cf(ip)
    if cid:
        print(f"{ip} => IN CloudFront range {cid}")
    else:
        print(f"{ip} => NOT in CloudFront ranges")
PY

echo
echo "Log file path: s3://$LOG_BUCKET/$found_key"
echo "Local copy: $TMPDIR/dr-s3-log.txt"
echo
echo "If any of the requester IPs are in CloudFront CIDR ranges, CloudFront contacted the DR S3 origin for the requested object."
echo "When done, you can disable logging by clearing the logging config (or keep logs for audit)."
echo
echo "To remove logging:"
echo "aws s3api put-bucket-logging --bucket $DR_BUCKET --bucket-logging-status '{}' --region $REGION"
