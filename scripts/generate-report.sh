#!/bin/bash

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p $OUTPUT_DIR

echo "# 📊 User Stories Report - $DATE" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 1. Extraire milestones

MILESTONES=$(jq '
[
.data.organization.projectV2.items.nodes[]
| select(.content.milestone != null)
| {
title: .content.milestone.title,
due: .content.milestone.dueOn
}
]
| unique_by(.title)
| sort_by(.due)
' data.json)

# 2. Pivot (milieu)

INDEX=$(echo "$MILESTONES" | jq '
to_entries
| (length / 2 | floor)
')

# 3. Sélection -1 / courant / +1

FILTERED=$(echo "$MILESTONES" | jq -r --argjson idx "$INDEX" '
[
.[$idx - 1],
.[$idx],
.[$idx + 1]
]
| map(select(. != null))
| map(.title)
| unique
')

echo "## 🎯 Milestones suivies" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "$FILTERED" | jq -r '.[] | "- " + .' >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 4. Extraction + calcul V2

jq --argjson milestones "$FILTERED" '
.data.organization.projectV2.items.nodes[]
| select(.content != null)
| select(.content.milestone != null)
| select(.content.milestone.title as $m | $milestones | index($m))
| {
number: .content.number,
title: .content.title,
milestone: .content.milestone.title,
state: .content.state,
is_bug: (
[.content.labels.nodes[].name]
| map(ascii_downcase)
| index("bug")
) != null
}
' data.json | jq -s '
group_by(.milestone)
| sort_by(.[0].milestone)
| .[]
| (
. as $items
| {
milestone: .[0].milestone,
total: length,
done: map(select(.state=="CLOSED")) | length,
remaining: map(select(.state!="CLOSED")) | length,
bugs_open: map(select(.is_bug == true and .state!="CLOSED")) | length
}
)
| .progress = (if .total > 0 then ((.done * 100) / .total | floor) else 0 end)
| "## 🗂 Milestone: " + .milestone,
"",
"- Total issues: " + (.total|tostring),
"- Done: " + (.done|tostring),
"- Remaining: " + (.remaining|tostring),
"- Bugs ouverts: " + (.bugs_open|tostring),
"- Progress: " + (.progress|tostring) + "%",
"",
($items | map("- #" + (.number|tostring) + " - " + .title) | join("\n")),
"",
""
' >> $OUTPUT_FILE

# latest

cp $OUTPUT_FILE $OUTPUT_DIR/latest.md
