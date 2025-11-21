#!/bin/bash

# Usage: ./review-scoring.sh <critical_count> <high_count> <medium_count> <nitpick_count>
# Calculation logic:
#   - The score starts at 100.
#   - Subtract 15 points for each critical issue, 8 for each high, 3 for each medium, and 1 for each nitpick.
#   - Clamp the score between 0 and 100.
#   - The grade is determined by the score:
#       90+ = A, 80+ = B, 70+ = C, 60+ = D, below 60 = F.
#   - The risk_level is assigned as follows:
#       * "critical" if there is any critical issue.
#       * "high" if there are more than 1 high issue, or 1 high plus any medium issues.
#       * "medium" if more than 4 medium issues, or more than 1 medium plus any high.
#       * "low" if there are nitpicks but no higher severity.
#       * "none" if no issues.

# Validate input arguments
if [ $# -ne 4 ]; then
  echo "Error: Expected 4 arguments (critical_count high_count medium_count nitpick_count)" >&2
  exit 1
fi

critical_count=${1:-0}
high_count=${2:-0}
medium_count=${3:-0}
nitpick_count=${4:-0}

# Validate that inputs are numbers
if ! [[ "$critical_count" =~ ^[0-9]+$ ]] || ! [[ "$high_count" =~ ^[0-9]+$ ]] || \
   ! [[ "$medium_count" =~ ^[0-9]+$ ]] || ! [[ "$nitpick_count" =~ ^[0-9]+$ ]]; then
  echo "Error: All arguments must be non-negative integers" >&2
  exit 1
fi

score=$((100 - critical_count*15 - high_count*8 - medium_count*3 - nitpick_count*1))
if [ "$score" -lt 0 ]; then
  score=0
elif [ "$score" -gt 100 ]; then
  score=100
fi

# Determine grade
if [ "$score" -ge 90 ]; then
  grade="A"
elif [ "$score" -ge 80 ]; then
  grade="B"
elif [ "$score" -ge 70 ]; then
  grade="C"
elif [ "$score" -ge 60 ]; then
  grade="D"
else
  grade="F"
fi

# Determine risk_level
if [ "$critical_count" -gt 0 ]; then
  risk_level="critical"
elif [ "$high_count" -gt 1 ] || { [ "$high_count" -eq 1 ] && [ "$medium_count" -gt 0 ]; }; then
  risk_level="high"
elif [ "$medium_count" -gt 4 ] || { [ "$medium_count" -gt 1 ] && [ "$high_count" -gt 0 ]; }; then
  risk_level="medium"
elif [ "$nitpick_count" -gt 0 ]; then
  risk_level="low"
else
  risk_level="none"
fi

# Output as JSON
printf '{\n'
printf '  "score": %d,\n' "$score"
printf '  "grade": "%s",\n' "$grade"
printf '  "risk_level": "%s"\n' "$risk_level"
printf '}\n'