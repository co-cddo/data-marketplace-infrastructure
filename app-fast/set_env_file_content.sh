#!/bin/bash

IMAGE_BASE_NAMES=("catalogue" "ui" "api" "datashare" "users")
LATEST_IMAGE_NAMES=""

echo "Starting to retrieve latest ECR image versions in region"

for BASE_NAME in "${IMAGE_BASE_NAMES[@]}"; do
  echo "--- Processing service: $BASE_NAME ---"

  LATEST_TAG=$(aws ecr describe-images \
    --repository-name "${BASE_NAME}" \
    --query 'sort_by(imageDetails, &imagePushedAt)[-1].imageTags[0]' \
    --output text \
    --max-items 1 2>/dev/null)

  if [ -n "$LATEST_TAG" ] && [[ "$LATEST_TAG" =~ ^${BASE_NAME}-[0-9]+\.[0-9]+$ ]]; then
    echo "  Found latest tag: $LATEST_TAG"
    LATEST_IMAGE_NAMES="${LATEST_IMAGE_NAMES}${BASE_NAME}=\"${LATEST_TAG}\"\n"
  else
    echo "  Warning: Could not find a valid latest tag for repository '${BASE_NAME}' or tag format mismatch. Skipping."
    echo "  LATEST_TAG found (if any): '$LATEST_TAG'"
  fi
done

echo "--- Generating .env content ---"
echo -e "$LATEST_IMAGE_NAMES" | tee ./.env
echo "Content written to ./.env"
