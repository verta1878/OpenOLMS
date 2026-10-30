#!/bin/bash
# OpenOLMS regression test — one command after every edit
# Usage: ./test_olms.sh [--verbose]

VERBOSE=${1:---quiet}
LAST_MATCH=44
LAST_NEAR=4

# Step 1: Clean TPUs
rm -f *.TPU

# Step 2: Compile
timeout 120 xvfb-run dosbox -conf /home/claude/tp7/dosbox-olms.conf -exit 2>/dev/null
ERR=$(grep 'Error' TPCOUT.TXT 2>/dev/null | head -1)
if [ -n "$ERR" ]; then
    echo "FAIL — compile error: $ERR"
    exit 1
fi

# Step 3: Run matcher
RESULT=$(python3 MATCH.PY 2>/dev/null)
MATCH=$(echo "$RESULT" | grep 'Matched:' | grep -o '[0-9]*/124' | cut -d/ -f1)
NEAR=$(echo "$RESULT" | grep 'NEAR' | grep -o '[0-9]* func' | cut -d' ' -f1)
FAR=$(echo "$RESULT" | grep 'FAR' | grep -o '[0-9]* func' | cut -d' ' -f1)
NONE=$(echo "$RESULT" | grep 'NONE' | grep -o '[0-9]* func' | cut -d' ' -f1)
LINES=$(wc -l < DM6000.PAS)

# Step 4: Compare against last known good
PASS=true
if [ "$MATCH" -lt "$LAST_MATCH" ]; then
    echo "REGRESSION — Match dropped: $MATCH (was $LAST_MATCH)"
    PASS=false
fi

# Step 5: Report
echo "Compile: clean"
if [ "$MATCH" -gt "$LAST_MATCH" ]; then
    echo "Match: $MATCH/124 (was $LAST_MATCH) ▲ +$(($MATCH - $LAST_MATCH)) NEW"
elif [ "$MATCH" -eq "$LAST_MATCH" ]; then
    echo "Match: $MATCH/124 ✓ HELD"
fi
echo "NEAR:  $NEAR  FAR: $FAR  NONE: $NONE"
echo "DM6000.PAS: $LINES lines"

if [ "$VERBOSE" = "--verbose" ]; then
    echo ""
    echo "$RESULT"
fi

if $PASS; then
    echo "PASS"
else
    echo "FAIL"
    exit 1
fi
