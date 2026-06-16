#!/bin/bash

set -e

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# 📊 User Stories Report - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 1. Extraire milestones

# -------------------------------

jq -r '
.data.organization.projectV2.items.nodes[]
| select(.content.milestone != null)
| .content.milestone.title
' data.json > milestones.txt

sort milestones.txt | uniq -c | sort -nr | head -3 | awk '{print $2}' > milestones_filtered.txt

echo "## 🎯 Milestones suivies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

while read m; do
echo "- $m" >> "$OUTPUT_FILE"
done < milestones_filtered.txt

echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 2. Extraire issues filtrées

# -------------------------------

jq '
.data.organization.projectV2.items.nodes[]
| select(.content != null)
| select(.content.milestone != null)
| {
number: .content.number,
title: .content.title,
state: (.content.state // "OPEN"),
milestone: .content.milestone.title
}
' data.json > issues.json

# -------------------------------

# 3. Traitement par milestone

# -------------------------------

while read milestone; do

echo "## 🗂 Milestone: $milestone" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

MATCHING=$(jq --arg m "$milestone" '
select(.milestone == $m)
' issues.json)

TOTAL=$(echo "$MATCHING" | jq -s 'length')
DONE=$(echo "$MATCHING" | jq -s 'map(select(.state=="CLOSED")) | length')
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

echo "$MATCHING" | jq -r '"- #(.number) - (.title)"' >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

done < milestones_filtered.txt

# -------------------------------

# 4. latest

# -------------------------------

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"
