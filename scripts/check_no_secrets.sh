#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if find FieldBriefAI -name 'GoogleService-Info.plist' | grep -q .; then
  echo 'NOTICE: Local Firebase config present. Ensure excluded from public repo.'
fi
if grep -R -E '(AIza[0-9A-Za-z_-]{35}|sk-[0-9A-Za-z_-]{20,}|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY)' \
     --include='*.swift' --include='*.md' FieldBriefAI Docs README.md; then
  echo 'Possible secret found. Review before publishing.' >&2
  exit 1
fi
echo 'No obvious credential patterns found in reviewed source/doc files.'
