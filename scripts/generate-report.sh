#!/bin/bash

set -e

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# 📊 User Stories Report - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 1. Milestones propres

# -------------------------------

jq -r '.data.organization.projectV2.items.nodes[] | select(.content.milestone != null) | .content.milestone.title' data.json | tr -d '\r' | sed '/^\s*$/d' | sort -u | head -3 > milestones.txt

echo "## 🎯 Milestones suivies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
sed 's/^/- /' milestones.txt >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 2. Traitement

# -------------------------------

while IFS= read -r milestone; do

echo "## 🗂 Milestone: $milestone" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

TOTAL=$(jq --arg m "$milestone" '.data.organization.projectV2.items.nodes[] | select(.content.milestone.title==$m) | select(any(.fieldValues.nodes[]?; .field.name=="Type" and .name=="User Story"))' data.json | jq -s 'length')

DONE=$(jq --arg m "$milestone" '.data.organization.projectV2.items.nodes[] | select(.content.milestone.title==$m) | select(.content.state=="CLOSED") | select(any(.fieldValues.nodes[]?; .field.name=="Type" and .name=="User Story"))' data.json | jq -s 'length')

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

echo "### ✅ Done ($DONE)" >> "$OUTPUT_FILE"
jq -r --arg m "$milestone" '.data.organization.projectV2.items.nodes[] | select(.content.milestone.title==$m) | select(.content.state=="CLOSED") | select(any(.fieldValues.nodes[]?; .field.name=="Type" and .name=="User Story")) | "- #(.content.number) - (.content.title)"' data.json >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo "### ⏳ Remaining (top 20)" >> "$OUTPUT_FILE"
jq -r --arg m "$milestone" '.data.organization.projectV2.items.nodes[] | select(.content.milestone.title==$m) | select(.content.state!="CLOSED") | select(any(.fieldValues.nodes[]?; .field.name=="Type" and .name=="User Story")) | "- #(.content.number) - (.content.title)"' data.json | head -20 >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

done < milestones.txt

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"
