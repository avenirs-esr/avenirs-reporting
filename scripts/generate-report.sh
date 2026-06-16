#!/bin/bash

set -e

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# 📊 User Stories Report - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 1. milestones

# -------------------------------

jq -r '.data.organization.projectV2.items.nodes[] | select(.content != null) | select(.content.__typename=="Issue") | select(.content.milestone != null) | .content.milestone.title' data.json 
| sort | uniq -c | sort -nr | head -3 | awk '{print $2}' > milestones.txt

echo "## 🎯 Milestones suivies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
sed 's/^/- /' milestones.txt >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 2. issues.json (TABLEAU)

# -------------------------------

jq '[.data.organization.projectV2.items.nodes[] | select(.content != null) | select(.content.__typename=="Issue") | select(.content.milestone != null) | {number: .content.number, title: .content.title, state: (.content.state // "OPEN"), milestone: .content.milestone.title}]' data.json > issues.json

# -------------------------------

# 3. traitement

# -------------------------------

while read milestone; do

echo "## 🗂 Milestone: $milestone" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

TOTAL=$(jq --arg m "$milestone" '.[] | select(.milestone==$m)' issues.json | jq -s 'length')
DONE=$(jq --arg m "$milestone" '.[] | select(.milestone==$m and .state=="CLOSED")' issues.json | jq -s 'length')

REMAINING=$((TOTAL - DONE))

if [ "$TOTAL" -gt 0 ]; then
PROGRESS=$((DONE * 100 / TOTAL))
else
PROGRESS=0
fi

echo "- Total: $TOTAL" >> "$OUTPUT_FILE"
echo "- Done: $DONE" >> "$OUTPUT_FILE"
echo "- Remaining: $REMAINING" >> "$OUTPUT_FILE"
echo "- Progress: $PROGRESS%" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

jq -r --arg m "$milestone" '.[] | select(.milestone==$m) | "- #(.number) - (.title)"' issues.json >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

done < milestones.txt

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"
