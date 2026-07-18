#!/usr/bin/env bash
# Test runner for the Notepad++ bug validation challenge.
#
# Usage:
#   ./test.sh [--output_path <junit.xml>] <base|new>
#
#   base  Runs the existing xmlValidator tests on unmodified code.
#   new   Runs the new API null pointer validation tests.
set -uo pipefail

# Ensure we are executing from the /app workspace root
cd /app

OUTPUT_PATH=""
if [ "${1:-}" = "--output_path" ]; then
  OUTPUT_PATH="$2"
  shift 2
fi

MODE="${1:-new}"

# Suppress Wine warnings and set virtual display display port
export DISPLAY=:99
export WINEDEBUG=-all

# Start Xvfb virtual display if not already running (required for Wine GUI)
if ! pgrep -x "Xvfb" > /dev/null; then
  echo "Initializing Xvfb display server on port :99..."
  Xvfb :99 -screen 0 1024x768x16 &
  sleep 2 # Let the X-server start up
fi

TEST_LOG="$(mktemp)"
STATUS=0

case "$MODE" in
  base)
    echo "Running legacy XML validation checks..." | tee -a "$TEST_LOG"
    # Execute the existing validation script directly on unmodified code
    python3 PowerEditor/Test/xmlValidator/validator_xml.py 2>&1 | tee -a "$TEST_LOG"
    STATUS=${PIPESTATUS[0]}
    ;;
    
  new)
    echo "Running new null pointer validation tests..." | tee -a "$TEST_LOG"
    # Execute new pytest cases
    pytest PowerEditor/Test/apiValidator/test_null_allocations.py -v 2>&1 | tee -a "$TEST_LOG"
    STATUS=${PIPESTATUS[0]}
    ;;
    
  *)
    echo "unknown mode: $MODE (expected base or new)" >&2
    exit 2
    ;;
esac

# Write output to JUnit XML
if [ -n "$OUTPUT_PATH" ]; then
  if [ "$MODE" = "new" ]; then
    # Generate native pytest JUnit XML report for the new tests
    pytest PowerEditor/Test/apiValidator/test_null_allocations.py --junitxml="$OUTPUT_PATH" >/dev/null 2>&1 || true
  else
    # Fallback: Manually generate a valid JUnit XML structure for base checks (no code modifications)
    if [ "$STATUS" -eq 0 ]; then
      cat <<EOF > "$OUTPUT_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="1" failures="0" errors="0">
  <testsuite name="NotepadPlusPlusBase" tests="1" failures="0" errors="0">
    <testcase name="XmlValidation" className="BaseTests"/>
  </testsuite>
</testsuites>
EOF
    else
      cat <<EOF > "$OUTPUT_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="1" failures="1" errors="0">
  <testsuite name="NotepadPlusPlusBase" tests="1" failures="1" errors="0">
    <testcase name="XmlValidation" className="BaseTests">
      <failure message="XML schema validation failed.">
        $(cat "$TEST_LOG" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
      </failure>
    </testcase>
  </testsuite>
</testsuites>
EOF
    fi
  fi
fi

exit "$STATUS"
