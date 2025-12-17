#!/bin/bash
#
# Transfer commit objects from temp-repo to bare repository
#

set -e

TEMP_REPO="$HOME/my-tmp/google-gerrit/temp-repo"
BARE_REPO="$HOME/my-tmp/google-gerrit/install-2.13.4/git/All-Projects.git"
NEW_COMMIT="${NEW_COMMIT:-a79a0ffc5c708db486057fe07ecf9cd33ddba857}"

echo "=========================================="
echo "Transferring Commit Objects"
echo "=========================================="
echo ""

cd "$BARE_REPO"

echo "Step 1: Adding temp-repo as remote..."
git remote remove temp-source 2>/dev/null || true
git remote add temp-source "$TEMP_REPO"

echo ""
echo "Step 2: Trying to push from temp-repo (most reliable method)..."
cd "$TEMP_REPO"
if git push "$BARE_REPO" refs/meta/config:refs/meta/config 2>/dev/null; then
    echo "✓ Successfully pushed refs/meta/config"
    PUSH_SUCCESS=true
else
    echo "⚠ Push failed, will try fetch method..."
    PUSH_SUCCESS=false
fi

cd "$BARE_REPO"

if [ "$PUSH_SUCCESS" = false ]; then
    echo ""
    echo "Step 3: Fetching refs/meta/config from temp-repo..."
    # Fetch the specific ref which will bring all necessary objects
    git fetch temp-source refs/meta/config:refs/meta/config || true

    echo ""
    echo "Step 4: Fetching all refs to ensure all objects are transferred..."
    # Fetch all refs (without --all flag, just fetch from the remote)
    git fetch temp-source || true
fi

echo ""
echo "Step 5: Verifying commit object exists..."
if git cat-file -e "$NEW_COMMIT" 2>/dev/null; then
    echo "✓ Commit object now exists in bare repository"
else
    echo "✗ Commit object still not found, trying alternative method..."

    # Alternative: Copy objects directly
    echo "Copying objects directly..."
    cd "$TEMP_REPO"

    # Get the tree hash from the commit
    TREE_HASH=$(git cat-file -p "$NEW_COMMIT" 2>/dev/null | grep ^tree | awk '{print $2}')
    if [ -z "$TREE_HASH" ]; then
        echo "Error: Could not read commit $NEW_COMMIT"
        cd "$BARE_REPO"
        exit 1
    fi

    echo "Tree hash: $TREE_HASH"

    # Copy commit object
    COMMIT_OBJECT="${NEW_COMMIT:0:2}/${NEW_COMMIT:2}"
    if [ -f ".git/objects/$COMMIT_OBJECT" ]; then
        mkdir -p "$BARE_REPO/objects/${NEW_COMMIT:0:2}"
        cp ".git/objects/$COMMIT_OBJECT" "$BARE_REPO/objects/$COMMIT_OBJECT"
        echo "✓ Copied commit object"
    else
        echo "✗ Commit object not found in temp-repo"
    fi

    # Copy tree object
    TREE_OBJECT="${TREE_HASH:0:2}/${TREE_HASH:2}"
    if [ -f ".git/objects/$TREE_OBJECT" ]; then
        mkdir -p "$BARE_REPO/objects/${TREE_HASH:0:2}"
        cp ".git/objects/$TREE_OBJECT" "$BARE_REPO/objects/$TREE_OBJECT"
        echo "✓ Copied tree object"
    else
        echo "✗ Tree object not found in temp-repo"
    fi

    # Copy all blob objects from the tree
    echo "Copying blob objects..."
    BLOB_COUNT=0
    git ls-tree -r "$TREE_HASH" 2>/dev/null | while read mode type hash name; do
        BLOB_OBJECT="${hash:0:2}/${hash:2}"
        if [ -f ".git/objects/$BLOB_OBJECT" ] && [ ! -f "$BARE_REPO/objects/$BLOB_OBJECT" ]; then
            mkdir -p "$BARE_REPO/objects/${hash:0:2}"
            cp ".git/objects/$BLOB_OBJECT" "$BARE_REPO/objects/$BLOB_OBJECT"
            BLOB_COUNT=$((BLOB_COUNT + 1))
        fi
    done
    echo "✓ Copied blob objects"

    cd "$BARE_REPO"
fi

echo ""
echo "Step 6: Updating refs/meta/config..."
if git cat-file -e "$NEW_COMMIT" 2>/dev/null; then
    git update-ref refs/meta/config "$NEW_COMMIT"
    echo "✓ Successfully updated refs/meta/config"
else
    echo "✗ Error: Commit object still not available after all methods"
    echo "The commit $NEW_COMMIT is not accessible in the bare repository"
    exit 1
fi

echo ""
echo "Step 7: Verifying..."
if git show-ref refs/meta/config > /dev/null 2>&1; then
    CURRENT_REF=$(git show-ref -s refs/meta/config)
    echo "✓ refs/meta/config exists"
    echo "  Current ref: $CURRENT_REF"

    if git cat-file -e refs/meta/config:lfs.config 2>/dev/null; then
        echo "✓ lfs.config exists!"
        echo ""
        echo "File contents:"
        echo "----------------------------------------"
        git show refs/meta/config:lfs.config
        echo "----------------------------------------"
    else
        echo "✗ lfs.config not found"
    fi
else
    echo "✗ refs/meta/config not found"
fi

echo ""
echo "Step 8: Cleaning up..."
git remote remove temp-source

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
