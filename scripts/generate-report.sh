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

# 2. Extraction complète

jq --argjson milestones "$FILTERED" '
.data.organization.projectV2.items.nodes[]
| select(.content != null)
| select(.content.milestone != null)
| select(.content.milestone.title as $m | $milestones | index($m))

# Type depuis Project

| .type = (
.fieldValues.nodes[]
| select(.field.name=="Type")
| .name
)

# Epic depuis body

| .epic = (
.content.body // ""
| capture("#(?<id>[0-9]+)")?.id // "No Epic"
)

| {
number: .content.number,
title: .content.title,
state: .content.state,
milestone: .content.milestone.title,
type: .type,
epic: .epic
}
' data.json | jq -s '
group_by(.milestone)
| .[]
| (
. as $items

```
| "## 🗂 Milestone: " + .[0].milestone,
  ""

# -------- EPICS / US --------
, "### 📦 Epics (fonctionnel)",
  ""

, (
    map(select(.type=="User Story"))
    | group_by(.epic)
    | .[]
    | {
        epic: .[0].epic,
        total: length,
        done: map(select(.state=="CLOSED")) | length
      }
    | .progress = (if .total > 0 then ((.done * 100) / .total | floor) else 0 end)
    | "#### Epic #" + .epic,
      "- Total US: " + (.total|tostring),
      "- Done: " + (.done|tostring),
      "- Progress: " + (.progress|tostring) + "%",
      ""
  )

# -------- BUGS --------
, "### 🐞 Bugs",
  ""

, (
    map(select(.type=="Bug")) as $bugs
    | {
        total: ($bugs | length),
        open: ($bugs | map(select(.state!="CLOSED")) | length),
        closed: ($bugs | map(select(.state=="CLOSED")) | length)
      }
    | "- Total: " + (.total|tostring),
      "- Ouverts: " + (.open|tostring),
      "- Fermés: " + (.closed|tostring),
      ""
  )
```

)
' >> $OUTPUT_FILE

cp $OUTPUT_FILE $OUTPUT_DIR/latest.md
