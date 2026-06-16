#!/bin/bash

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p $OUTPUT_DIR

echo "# 📊 User Stories Report - $DATE" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 1. Milestones les plus utilisées

FILTERED=$(jq -r '
.data.organization.projectV2.items.nodes[]
| select(.content.milestone != null)
| .content.milestone.title
' data.json | sort | uniq -c | sort -nr | head -3 | awk '{print $2}' | jq -R . | jq -s .)

echo "## 🎯 Milestones suivies" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "$FILTERED" | jq -r '.[] | "- " + .' >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 2. Extraction simple (SANS EPIC)

jq --argjson milestones "$FILTERED" '
.data.organization.projectV2.items.nodes[]
| select(.content != null)
| select(.content.milestone != null)
| select(.content.milestone.title as $m | $milestones | index($m))

| {
number: .content.number,
title: .content.title,
state: (.content.state // "OPEN"),
milestone: .content.milestone.title
}
' data.json | jq -s '
group_by(.milestone)
| .[]
| (
. as $items
| {
milestone: .[0].milestone,
total: length,
done: map(select(.state=="CLOSED")) | length,
remaining: map(select(.state!="CLOSED")) | length
}
)
| .progress = (if .total > 0 then ((.done * 100) / .total | floor) else 0 end)
| "## 🗂 Milestone: " + .milestone,
"",
"- Total: " + (.total|tostring),
"- Done: " + (.done|tostring),
"- Remaining: " + (.remaining|tostring),
"- Progress: " + (.progress|tostring) + "%",
"",
($items | map("- #" + (.number|tostring) + " - " + .title) | join("\n")),
"",
""
' >> $OUTPUT_FILE

cp $OUTPUT_FILE $OUTPUT_DIR/latest.md
