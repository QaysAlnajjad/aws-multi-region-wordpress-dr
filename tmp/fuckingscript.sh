#!/usr/bin/env bash
set -euo pipefail

# ----- EDIT ONLY THESE -----
CF_URL="https://qays.cloud/path/to/Coraline_poster.jpg"   # exact CloudFront URL to request (your original test URL)
OBJECT_KEY="path/to/Coraline_poster.jpg"                  # S3 object key inside the bucket
DR_BUCKET="wordpress-media-dr-200"                        # DR S3 bucket name
# ---------------------------

REGION="ca-central-1"
CT_BUCKET="cf-trail-logs-$(date -u +%Y%m%dT%H%M%SZ | tr '[:upper:]' '[:lower:]')"
TRAIL_NAME="cf-dr-s3-trail-$(date -u +%s)"

# check commands
for cmd in aws curl jq gunzip awk sort sed basename; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 2
  fi
done

echo "Using:"
echo "  Initial CloudFront URL: $CF_URL"
echo "  OBJECT_KEY:            $OBJECT_KEY"
echo "  DR bucket:             $DR_BUCKET"
echo "  Trail bucket:          $CT_BUCKET"
echo "  Trail name:            $TRAIL_NAME"
echo "  Region:                $REGION"
echo

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account: $AWS_ACCOUNT_ID"
echo

# 1) Create trail S3 bucket (safe: if already owned, continue)
echo "Creating trail S3 bucket: $CT_BUCKET ..."
if aws s3api create-bucket \
     --bucket "$CT_BUCKET" \
     --region "$REGION" \
     --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null; then
  echo "Bucket created."
else
  if aws s3api head-bucket --bucket "$CT_BUCKET" 2>/dev/null; then
    echo "Bucket already exists and is reachable; continuing."
  else
    echo "Failed to create or access bucket $CT_BUCKET" >&2
    exit 3
  fi
fi

# 2) Put bucket policy that CloudTrail expects.
echo "Writing bucket policy required by CloudTrail..."
POLICY_FILE=$(mktemp)
cat > "$POLICY_FILE" <<EOF
{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AWSCloudTrailAclCheck",
      "Effect":"Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action":"s3:GetBucketAcl",
      "Resource":"arn:aws:s3:::$CT_BUCKET"
    },
    {
      "Sid":"AWSCloudTrailWrite",
      "Effect":"Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action":"s3:PutObject",
      "Resource":"arn:aws:s3:::$CT_BUCKET/AWSLogs/$AWS_ACCOUNT_ID/*",
      "Condition":{
        "StringEquals":{
          "s3:x-amz-acl":"bucket-owner-full-control",
          "aws:SourceAccount":"$AWS_ACCOUNT_ID"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy --bucket "$CT_BUCKET" --policy "file://$POLICY_FILE" --region "$REGION"
rm -f "$POLICY_FILE"
echo "Bucket policy applied."

# 3) Create CloudTrail in the same region. Use negated flag for false multi-region.
echo "Creating CloudTrail: $TRAIL_NAME ..."
aws cloudtrail create-trail \
  --name "$TRAIL_NAME" \
  --s3-bucket-name "$CT_BUCKET" \
  --no-is-multi-region-trail \
  --region "$REGION"

# 4) Put event selectors for S3 object data events on the DR bucket
echo "Configuring event selectors for S3 object-level events on bucket: $DR_BUCKET ..."
EVENT_SELECTORS_JSON=$(cat <<EOF
[{
  "ReadWriteType": "All",
  "IncludeManagementEvents": false,
  "DataResources": [{
    "Type": "AWS::S3::Object",
    "Values": ["arn:aws:s3:::$DR_BUCKET/"]
  }]
}]
EOF
)

aws cloudtrail put-event-selectors \
  --trail-name "$TRAIL_NAME" \
  --event-selectors "$EVENT_SELECTORS_JSON" \
  --region "$REGION"

# 5) Start logging (must call in same region)
echo "Starting CloudTrail logging..."
aws cloudtrail start-logging --name "$TRAIL_NAME" --region "$REGION"

echo
echo "CloudTrail created and logging started. Waiting a few seconds for initialization..."
sleep 5

# Helper to request URL and return server header and status
request_and_inspect() {
  local url="$1"
  echo "Requesting: $url"
  # fetch headers (follow redirects)
  HEADERS=$(curl -s -I -L "$url" || true)
  echo "$HEADERS" | sed -n '1,120p'
  # extract server header and status line
  STATUS_LINE=$(echo "$HEADERS" | head -n1 | tr -d '\r')
  SERVER_HDR=$(echo "$HEADERS" | awk 'BEGIN{IGNORECASE=1} /^server:/{print tolower($0)}' | sed 's/server:[[:space:]]*//I' | tr -d '\r' | head -n1 || echo "")
  X_CACHE=$(echo "$HEADERS" | awk 'BEGIN{IGNORECASE=1} /^x-cache:/{print tolower($0)}' | sed 's/x-cache:[[:space:]]*//I' | tr -d '\r' | head -n1 || echo "")
  echo "STATUS_LINE: $STATUS_LINE"
  echo "SERVER: $SERVER_HDR"
  echo "X-Cache: $X_CACHE"
  # return values
  echo "$STATUS_LINE" "$SERVER_HDR" "$X_CACHE"
}

# 6) First try the user-provided URL
read -r STATUS_LINE SERVER_HDR X_CACHE <<<"$(request_and_inspect "$CF_URL")"

# If server header doesn't indicate S3, try the uploads path variant (common WP path)
if [[ -z "$SERVER_HDR" || "$SERVER_HDR" != *"amazons3"* && "$SERVER_HDR" != *"amazon s3"* && "$SERVER_HDR" != *"amazon-s3"* && "$X_CACHE" != *"from cloudfront"* ]]; then
  echo
  echo "Response did not appear to come from S3 (server: $SERVER_HDR, x-cache: $X_CACHE)."
  BASENAME=$(basename "$OBJECT_KEY")
  UPLOADS_PATH="/wp-content/uploads/$BASENAME"
  # try to construct an uploads URL on the same domain
  CF_HOST=$(echo "$CF_URL" | sed -n 's|^[a-zA-Z]*://\([^/]*\).*$|\1|p')
  UPLOADS_URL="https://$CF_HOST$UPLOADS_PATH"
  echo "Trying likely uploads URL: $UPLOADS_URL"
  read -r STATUS_LINE SERVER_HDR X_CACHE <<<"$(request_and_inspect "$UPLOADS_URL")"
  if [[ "$SERVER_HDR" == *"amazons3"* || "$SERVER_HDR" == *"amazon s3"* || "$SERVER_HDR" == *"amazon-s3"* || "$X_CACHE" == *"from cloudfront"* ]]; then
    echo "Uploads URL appears to hit S3. Switching to uploads URL for CloudTrail verification."
    CF_URL="$UPLOADS_URL"
    OBJECT_KEY="${UPLOADS_PATH#"/"}"  # remove leading slash for OBJECT_KEY
    echo "New CF_URL: $CF_URL"
    echo "New OBJECT_KEY: $OBJECT_KEY"
  else
    echo "Uploads URL also did not hit S3. If your CloudFront behavior routes /wp-content/uploads/* to S3, ensure you requested a path that matches that behavior. Exiting."
    exit 5
  fi
else
  echo "Initial request appears to be hitting S3 (server: $SERVER_HDR). Continuing to CloudTrail check."
fi

echo
echo "Sleeping 5s to allow CloudTrail to capture and deliver..."
sleep 5

# 7) Poll the trail S3 bucket for latest delivered CloudTrail file and search for GetObject events
PREFIX="AWSLogs/${AWS_ACCOUNT_ID}/CloudTrail/${REGION}/"
echo "Looking for CloudTrail files under s3://$CT_BUCKET/$PREFIX ..."

# Be generous with retries (CloudTrail may deliver with some delay)
MAX_ATTEMPTS=20
SLEEP_BETWEEN=15
FOUND=0

for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "Attempt $attempt/$MAX_ATTEMPTS - listing objects..."
  LATEST_KEY=$(aws s3 ls "s3://$CT_BUCKET/$PREFIX" --recursive 2>/dev/null | awk '{print $4}' | sort | tail -n1 || true)

  if [ -z "$LATEST_KEY" ]; then
    echo "No CloudTrail objects found yet(continued script — paste the rest of the file exactly as shown)

```bash
    echo "No CloudTrail objects found yet. Waiting $SLEEP_BETWEEN s..."
    sleep "$SLEEP_BETWEEN"
    continue
  fi

  echo "Found latest key: $LATEST_KEY"
  echo "Downloading and scanning for GetObject events (bucket=$DR_BUCKET key=$OBJECT_KEY)..."

  if aws s3 cp "s3://$CT_BUCKET/$LATEST_KEY" - 2>/dev/null | gunzip -c | \
     jq -r --arg bucket "$DR_BUCKET" --arg key "$OBJECT_KEY" '
       .Records[]
       | select(.eventName == "GetObject")
       | select(.requestParameters.bucketName == $bucket and .requestParameters.key == $key)
       | {eventTime, eventName, sourceIPAddress, userAgent, requestParameters: .requestParameters, responseElements: .responseElements}
     ' 2>/dev/null | tee /dev/stderr | grep -q '"eventTime"'; then
    echo
    echo "MATCH: CloudFront-origin GetObject event found in $LATEST_KEY"
    FOUND=1
    break
  else
    echo "No matching GetObject in $LATEST_KEY. Waiting $SLEEP_BETWEEN s and retrying..."
    sleep "$SLEEP_BETWEEN"
  fi
done

if [ "$FOUND" -eq 0 ]; then
  echo
  echo "No GetObject event found after $MAX_ATTEMPTS attempts."
  echo "Possible reasons:"
  echo " - CloudTrail delivery lag (wait longer and retry)."
  echo " - CloudFront served the object from cache (no origin fetch)."
  echo " - The object key or bucket name are incorrect in the script variables."
  echo
  echo "You can inspect recent files manually with:"
  echo "  aws s3 ls s3://$CT_BUCKET/$PREFIX --recursive | tail -n 50"
  exit 4
fi

echo
echo "Success: the CloudTrail record shows a GetObject for $DR_BUCKET/$OBJECT_KEY."
echo "Inspect the printed JSON above for sourceIPAddress (should be a CloudFront IP)."

cat <<EOF

CLEANUP (manual) — run these when you are finished:
# stop logging
aws cloudtrail stop-logging --name "$TRAIL_NAME" --region "$REGION"

# delete trail
aws cloudtrail delete-trail --name "$TRAIL_NAME" --region "$REGION"

# remove event selectors (optional)
aws cloudtrail put-event-selectors --trail-name "$TRAIL_NAME" --event-selectors '[]' --region "$REGION"

# remove S3 bucket (only after emptying it)
# aws s3 rb s3://$CT_BUCKET --force

EOF
