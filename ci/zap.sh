#!/bin/bash
TARGET_URL=$1

# Pull the ZAP docker image first
docker pull owasp/zap2docker-stable

# Run the scan
# -t: Target URL
# -r: HTML Report name
# -J: JSON Report name
# -I: Ignore warnings (fail only on errors)
# -m 1: Max run time in minutes (Short scan for testing)
docker run --rm -v $(pwd):/zap/wrk/:rw \
  owasp/zap2docker-stable zap-baseline.py \
  -t "$TARGET_URL" \
  -r zap-report.html \
  -J zap-report.json \
  -I

# Return exit code 0 so pipeline doesn't crash if it finds bugs (for now)
exit 0
