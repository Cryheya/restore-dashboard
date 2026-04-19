#!/usr/bin/env bash
set -euo pipefail

# One-command updater for restore-dashboard GitHub Pages.
# Default flow:
# 1) Generate fresh data.json from Excel in SOURCE_DIR
# 2) Copy data.json into this git repo
# 3) Commit and push to main
#
# Usage examples:
#   ./update_dashboard.sh
#   ./update_dashboard.sh --quarter "Q2 2026"
#   ./update_dashboard.sh --with-index
#   ./update_dashboard.sh --quarter "Q2 2026" --with-index --message "Update Q2 2026"

SOURCE_DIR="/Users/nedin/Desktop/restore-dashboard"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
EXCEL_FILE="Перформеры_re.xlsx"

WITH_INDEX=0
QUARTER=""
COMMIT_MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-index)
      WITH_INDEX=1
      shift
      ;;
    --quarter)
      QUARTER="${2:-}"
      shift 2
      ;;
    --message)
      COMMIT_MESSAGE="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [[ ! -f "$SOURCE_DIR/generate_data.py" ]]; then
  echo "generate_data.py not found: $SOURCE_DIR/generate_data.py"
  exit 1
fi

if [[ ! -f "$SOURCE_DIR/$EXCEL_FILE" ]]; then
  echo "Excel file not found: $SOURCE_DIR/$EXCEL_FILE"
  exit 1
fi

echo "==> Generating data.json from $EXCEL_FILE"
cd "$SOURCE_DIR"
if [[ -n "$QUARTER" ]]; then
  printf "%s\n" "$QUARTER" | python3 generate_data.py "$EXCEL_FILE"
else
  python3 generate_data.py "$EXCEL_FILE"
fi

if [[ ! -f "$SOURCE_DIR/data.json" ]]; then
  echo "data.json was not generated"
  exit 1
fi

echo "==> Syncing files to git repo"
cp "$SOURCE_DIR/data.json" "$REPO_DIR/data.json"
if [[ "$WITH_INDEX" -eq 1 ]]; then
  if [[ ! -f "$SOURCE_DIR/index.html" ]]; then
    echo "index.html not found in source dir"
    exit 1
  fi
  cp "$SOURCE_DIR/index.html" "$REPO_DIR/index.html"
fi

cd "$REPO_DIR"
if [[ "$WITH_INDEX" -eq 1 ]]; then
  git add data.json index.html
else
  git add data.json
fi

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

if [[ -z "$COMMIT_MESSAGE" ]]; then
  if [[ -n "$QUARTER" ]]; then
    COMMIT_MESSAGE="Update dashboard data ${QUARTER}"
  else
    COMMIT_MESSAGE="Update dashboard data $(date +%Y-%m-%d)"
  fi
fi

echo "==> Committing"
git commit -m "$COMMIT_MESSAGE"

echo "==> Pushing to origin/main"
git push origin main

echo "Done."
