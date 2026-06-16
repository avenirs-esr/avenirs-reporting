#!/bin/bash

set -e

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# 📊 User Stories Report - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 1. Extraction milestones (SAFE)

# -------------------------------

MILESTONES_RAW=$(jq -r '
.data.organization.projectV2.items.nodes[]
| select(.content.milestone != null)
| .content.milestone.title
' data.json)

FILTERED=$(echo "$MILESTONES_RAW" 
| sort 
| uniq -c 
| sort -nr 
| head -3 
| awk '{print $2}' 
| jq -R . 
| jq -s .)

echo "## 🎯 Milestones suivies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "$FILTERED" | jq -r '.[] | "- " + .' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 2. Extraction issues

# -------------------------------

ISSUES=$(jq --argjson milestones "$FILTERED" '
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
' data.json)

# -------------------------------

# 3. Agrégation

# -------------------------------

echo "$ISSUES" | jq -r -s '
group_by(.milestone)
| .[]
| (
{
milestone: .[0].milestone,
total: length,
done: map(select(.state=="CLOSED")) | length,
remaining: map(select(.state!="CLOSED")) | length,
list: (map("- #" + (.number|tostring) + " - " + .title) | join("\n"))
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
.list,
"",
""
' >> "$OUTPUT_FILE"

# -------------------------------

# 4. latest

# -------------------------------

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"
