#!/bin/bash

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p $OUTPUT_DIR

echo "# 📊 User Stories Report - $DATE" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 1. Extraire milestones triées
MILESTONES=$(jq -r '
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

# 2. Date actuelle
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 3. Trouver index courant
INDEX=$(echo "$MILESTONES" | jq -r --arg NOW "$NOW" '
to_entries
| map(select(.value.due != null))
| map(select(.value.due >= $NOW))
| .[0].key // 0
')

# 4. Sélection -1 / courant / +1
FILTERED=$(echo "$MILESTONES" | jq -r --argjson idx "$INDEX" '
[
  .[$idx - 1],
  .[$idx],
  .[$idx + 1]
]
| map(select(. != null))
| .[].title
')

echo "## 🎯 Milestones suivies" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "$FILTERED" | sed 's/^/- /' >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# 5. Filtrer les US
jq -r --argjson milestones "$(echo "$FILTERED" | jq -R . | jq -s .)" '
.data.organization.projectV2.items.nodes[]
| select(.content != null)
| select(.content.milestone.title as $m | $milestones | index($m))
| {
    number: .content.number,
    title: .content.title,
    milestone: .content.milestone.title
}
' data.json | jq -s '
group_by(.milestone)
| sort_by(.[0].milestone)
| .[]
| "## 🗂 Milestone: " + .[0].milestone,
"",
(.[] | "- #" + (.number|tostring) + " - " + .title),
""
' >> $OUTPUT_FILE

# latest
cp $OUTPUT_FILE $OUTPUT_DIR/latest.md