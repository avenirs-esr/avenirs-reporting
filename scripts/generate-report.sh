#!/bin/bash

set -e

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# 📊 Product Report - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 1. récupérer milestones

# -------------------------------

echo "$ISSUES_JSON" | jq -r '.[] | select(.milestone != null) | .milestone.title' | sort -u > milestones.txt

echo "## 🎯 Milestones suivies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
sed 's/^/- /' milestones.txt >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# 2. traitement

# -------------------------------

while IFS= read -r milestone; do

echo "## 🗂 Milestone: $milestone" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# --- USER STORIES ---

US_TOTAL=$(echo "$ISSUES_JSON" | jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="User Story")] | length')

US_DONE=$(echo "$ISSUES_JSON" | jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="User Story" and .state=="CLOSED")] | length')

US_REMAINING=$((US_TOTAL - US_DONE))

if [ "$US_TOTAL" -gt 0 ]; then
US_PROGRESS=$((US_DONE * 100 / US_TOTAL))
else
US_PROGRESS=0
fi

# --- BUGS ---

BUG_TOTAL=$(echo "$ISSUES_JSON" | jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="Bug")] | length')

BUG_OPEN=$(echo "$ISSUES_JSON" | jq --arg m "$milestone" '[.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="Bug" and .state!="CLOSED")] | length')

# --- KPI ---

if [ "$US_TOTAL" -gt 0 ]; then
BUG_RATIO=$((BUG_TOTAL * 100 / US_TOTAL))
else
BUG_RATIO=0
fi

# -------------------------------

# affichage

# -------------------------------

echo "### 📈 Progress" >> "$OUTPUT_FILE"
echo "- User Stories: $US_DONE / $US_TOTAL ($US_PROGRESS%)" >> "$OUTPUT_FILE"
echo "- Remaining: $US_REMAINING" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### 🐞 Quality" >> "$OUTPUT_FILE"
echo "- Bugs total: $BUG_TOTAL" >> "$OUTPUT_FILE"
echo "- Bugs open: $BUG_OPEN" >> "$OUTPUT_FILE"
echo "- Bug ratio: $BUG_RATIO%" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# -------------------------------

# DONE

# -------------------------------

echo "### ✅ Done (User Stories)" >> "$OUTPUT_FILE"
echo "$ISSUES_JSON" | jq -r --arg m "$milestone" '.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="User Story" and .state=="CLOSED") | "- #(.number) - (.title)"' >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

# -------------------------------

# REMAINING

# -------------------------------

echo "### ⏳ Remaining (top 20)" >> "$OUTPUT_FILE"
echo "$ISSUES_JSON" | jq -r --arg m "$milestone" '.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="User Story" and .state!="CLOSED") | "- #(.number) - (.title)"' | head -20 >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

# -------------------------------

# BUGS

# -------------------------------

echo "### 🐞 Open Bugs" >> "$OUTPUT_FILE"
echo "$ISSUES_JSON" | jq -r --arg m "$milestone" '.[] | select(.milestone != null and .milestone.title==$m and .issueType.name=="Bug" and .state!="CLOSED") | "- #(.number) - (.title)"' >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

done < milestones.txt

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"
