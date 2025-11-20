#!/bin/bash
###############################################################################
#  TUMOR IMAGE MANIFEST + MIGRATOR (BONE • SOFT TISSUE • SKIN)
#  Author: ChatGPT for Dr. Askia Dunnon
#
#  FUNCTIONS:
#    ✓ Recursively search for all tumor images
#    ✓ Preserve entity folders (e.g., chondrosarcoma, dfsp, melanoma)
#    ✓ Move images into GitHub repo
#    ✓ Create manifest.json with metadata:
#        • WHO category (bone / soft_tissue / skin)
#        • entity (folder name)
#        • app path
#        • size
#        • sha256
#        • original + github path
###############################################################################

SOURCE_ROOT="/Users/ski_mini/Downloads/src"
GITHUB_REPO="/Users/ski_mini/Projects/TumorAtlas"       # ← UPDATE IF NEEDED
TARGET_ROOT="$GITHUB_REPO/assets/images"
MANIFEST="$GITHUB_REPO/assets/tumor_manifest.json"

declare -a CATEGORIES=("bone" "soft_tissue" "skin")

IMAGE_TYPES="-iname *.jpg -o -iname *.jpeg -o -iname *.png -o -iname *.gif -o -iname *.webp -o -iname *.svg -o -iname *.tiff -o -iname *.tif"

mkdir -p "$TARGET_ROOT"

echo "----------------------------------------------------------"
echo "   TUMOR IMAGE MANIFEST GENERATOR"
echo "----------------------------------------------------------"
echo " SOURCE ROOT:   $SOURCE_ROOT"
echo " TARGET ROOT:   $TARGET_ROOT"
echo " MANIFEST:      $MANIFEST"
echo ""

echo '{ "tumor_images": [' > "$MANIFEST"

COUNT=0

for CATEGORY in "${CATEGORIES[@]}"; do
    SRC_DIR="$SOURCE_ROOT/$CATEGORY"
    echo "[Scanning category] $CATEGORY → $SRC_DIR"

    if [ ! -d "$SRC_DIR" ]; then
        echo "  [!] WARNING: $SRC_DIR does not exist. Skipping."
        continue
    fi

    find "$SRC_DIR" -type f \( $IMAGE_TYPES \) | while read -r FILE; do

        REL_PATH="${FILE#$SOURCE_ROOT/}"
        ENTITY=$(echo "$REL_PATH" | cut -d'/' -f2)
        BASENAME=$(basename "$FILE")

        DEST_DIR="$TARGET_ROOT/$CATEGORY/$ENTITY"
        mkdir -p "$DEST_DIR"

        TARGET="$DEST_DIR/$BASENAME"
        cp "$FILE" "$TARGET"

        SIZE=$(stat -f%z "$TARGET")
        SHA=$(shasum -a 256 "$TARGET" | awk '{print $1}')
        APP_PATH="assets/images/$CATEGORY/$ENTITY/$BASENAME"

        if [ $COUNT -gt 0 ]; then
            echo "," >> "$MANIFEST"
        fi

        cat >> "$MANIFEST" <<EOF
    {
      "category": "$CATEGORY",
      "entity": "$ENTITY",
      "original_path": "$FILE",
      "github_path": "$TARGET",
      "app_path": "$APP_PATH",
      "size_bytes": $SIZE,
      "sha256": "$SHA"
    }
EOF

        COUNT=$((COUNT + 1))
        echo "  [+] Added: $CATEGORY → $ENTITY → $BASENAME"

    done

done

echo "" >> "$MANIFEST"
echo "  ]" >> "$MANIFEST"
echo "}" >> "$MANIFEST"

echo "----------------------------------------------------------"
echo " COMPLETE: $COUNT tumor images processed."
echo " Manifest written to:"
echo "   $MANIFEST"
echo "----------------------------------------------------------"
