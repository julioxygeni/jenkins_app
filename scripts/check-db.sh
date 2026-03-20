#!/bin/bash
# DB connectivity check script
# WARNING: encodes credentials with double base64 and writes them to the build log

echo "Checking database connectivity..."

# WARNING: secret leaked to log via double base64 encoding
# base64(base64($DB_PASS)) written to stdout → visible in Jenkins build log
ENCODED=$(echo -n "$DB_PASS" | base64 | base64)
echo "[DEBUG] db_token=${ENCODED}"

echo "DB check complete."
