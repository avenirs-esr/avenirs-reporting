#!/bin/bash

set -e

INPUT_FILE="issues.json"

if [ ! -f "$INPUT_FILE" ]; then
echo "Erreur : $INPUT_FILE introuvable"
exit 1
fi

DATE=$(date +%F)

OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# 📊 Product Report - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Milestones

jq -r '.[] | select(.milestone != null) | .milestone.title' "$INPUT_FILE" | sort -u > milestones.txt

echo "## 🎯 Milestones suivies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
sed 's/^/- /' milestones.txt >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

while IFS= read -r milestone; do

echo "## 🗂 Milestone : $milestone" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

FUNCTIONAL_TOTAL=$(jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m) | select(.issueType != null and (.issueType.name=="User Story" or .issueType.name=="Feature" or .issueType.name=="Enabler Story" or .issueType.name=="Spike"))] | length' "$INPUT_FILE")

FUNCTIONAL_DONE=$(jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m and .state=="CLOSED") | select(.issueType != null and (.issueType.name=="User Story" or .issueType.name=="Feature" or .issueType.name=="Enabler Story" or .issueType.name=="Spike"))] | length' "$INPUT_FILE")

FUNCTIONAL_REMAINING=$((FUNCTIONAL_TOTAL - FUNCTIONAL_DONE))

BUG_TOTAL=$(jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m) | select(.issueType != null and .issueType.name=="Bug")] | length' "$INPUT_FILE")

BUG_OPEN=$(jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m and .state!="CLOSED") | select(.issueType != null and .issueType.name=="Bug")] | length' "$INPUT_FILE")

EPIC_TOTAL=$(jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m) | select(.issueType != null and .issueType.name=="Epic")] | length' "$INPUT_FILE")

if [ "$FUNCTIONAL_TOTAL" -gt 0 ]; then
PROGRESS=$((FUNCTIONAL_DONE * 100 / FUNCTIONAL_TOTAL))
else
PROGRESS=0
fi

echo "### 📈 Progression" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- Fonctionnels : $FUNCTIONAL_DONE / $FUNCTIONAL_TOTAL ($PROGRESS%)" >> "$OUTPUT_FILE"
echo "- Restants : $FUNCTIONAL_REMAINING" >> "$OUTPUT_FILE"
echo "- Epics : $EPIC_TOTAL" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🐞 Qualité" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- Bugs : $BUG_TOTAL" >> "$OUTPUT_FILE"
echo "- Bugs ouverts : $BUG_OPEN" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🎯 Epics" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

jq -r --arg m "$milestone" '.[] | select(.milestone != null and .milestone.title==$m) | select(.issueType != null and .issueType.name=="Epic") | "- #(.number) - (.title)"' "$INPUT_FILE" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo "### ⏳ Fonctionnels restants (20 premiers)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

jq -r --arg m "$milestone" '.[] | select(.milestone != null and .milestone.title==$m and .state!="CLOSED") | select(.issueType != null and (.issueType.name=="User Story" or .issueType.name=="Feature" or .issueType.name=="Enabler Story" or .issueType.name=="Spike")) | "- #(.number) - (.title)"' "$INPUT_FILE" | head -20 >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo "### 🐞 Bugs ouverts" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

jq -r --arg m "$milestone" '.[] | select(.milestone != null and .milestone.title==$m and .state!="CLOSED") | select(.issueType != null and .issueType.name=="Bug") | "- #(.number) - (.title)"' "$INPUT_FILE" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

done < milestones.txt

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"

echo "Rapport généré : $OUTPUT_FILE"
