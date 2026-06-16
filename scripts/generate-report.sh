#!/bin/bash

set -e

DATE=$(date +%F)
OUTPUT_DIR="user-stories"
OUTPUT_FILE="$OUTPUT_DIR/$DATE.md"

mkdir -p "$OUTPUT_DIR"

echo "# DEBUG REPORT - $DATE" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Debug: afficher les types réellement présents

echo "## Types détectés" >> "$OUTPUT_FILE"
jq '.data.organization.projectV2.items.nodes[0].fieldValues.nodes' data.json

jq -r '.data.organization.projectV2.items.nodes[] | .fieldValues.nodes[]? | select(.field.name=="Type") | .name' data.json | sort -u >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Debug: afficher quelques issues avec leur type

echo "## Sample issues" >> "$OUTPUT_FILE"
jq -r '
.data.organization.projectV2.items.nodes[]
| . as $item
| ($item.fieldValues.nodes[]? | select(.field.name=="Type") | .name) as $type
| "- [($type)] #($item.content.number) - ($item.content.title)"
' data.json | head -20 >> "$OUTPUT_FILE"

cp "$OUTPUT_FILE" "$OUTPUT_DIR/latest.md"
