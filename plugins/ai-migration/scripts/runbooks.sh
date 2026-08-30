#!/usr/bin/env bash
# Runbook helpers for the ai-migration plugin.
# Folder discovery and frontmatter parsing live here so that the skill and the
# status command always agree on where the runbooks are and what they claim.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: runbooks.sh <command> [folder]

  resolve              The runbook folder for this repo, relative to its root.
                       Exits 1 with no output when the repo has none yet.
  list      [folder]   One TSV row per active runbook:
                       path, status, updated, days-since-update, tracking, title, progress
  archived  [folder]   The same TSV rows, for the done/ archive
  index     [folder]   The index README's table rows, verbatim, for drift checks
  folders   [folder]   Each subfolder and how many runbooks it holds
  root                 The repo root all of this resolves against

Discovery order for the folder, first hit wins:
  1. $AI_MIGRATION_DIR
  2. The "Runbook folder" row of the CLAUDE.md AI Migration Runbooks table
  3. An existing docs/ai-migrations, tools/ai-migrations, .ai-migrations or ai-migrations
EOF
}

# Probed in this order. docs/ first: a runbook is prose a human reads, and docs/
# assumes no particular build tooling. tools/ is second because that is where
# the NX monorepos already keep theirs.
CANDIDATES=(docs/ai-migrations tools/ai-migrations .ai-migrations ai-migrations)

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

# The folder named in the repo's own CLAUDE.md, which outranks any probe: a repo
# that says where its runbooks live is never overruled by a folder of the right
# name that merely happens to exist somewhere else.
declared_dir() {
  local root="$1" f line path
  for f in "$root/CLAUDE.md" "$root/.claude/CLAUDE.md" "$root/CLAUDE.local.md"; do
    [ -f "$f" ] || continue
    line=$(grep -i -m1 'runbook folder' "$f" 2>/dev/null || true)
    [ -n "$line" ] || continue
    path=$(printf '%s\n' "$line" | sed -n 's/.*`\([^`]*\)`.*/\1/p' | head -1)
    path="${path%/}"
    if [ -n "$path" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  done
  return 1
}

resolve_dir() {
  local root cand declared
  root="$(repo_root)"

  if [ -n "${AI_MIGRATION_DIR:-}" ]; then
    printf '%s\n' "${AI_MIGRATION_DIR%/}"
    return 0
  fi

  if declared=$(declared_dir "$root"); then
    printf '%s\n' "$declared"
    return 0
  fi

  for cand in "${CANDIDATES[@]}"; do
    if [ -d "$root/$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done

  return 1
}

# Whole days between an ISO date and today. BSD date first, then GNU.
days_since() {
  local d="${1:-}" ts now
  if [ -z "$d" ]; then printf '\n'; return 0; fi
  ts=$(date -j -f "%Y-%m-%d" "$d" +%s 2>/dev/null) \
    || ts=$(date -d "$d" +%s 2>/dev/null) \
    || { printf '\n'; return 0; }
  now=$(date +%s)
  printf '%s\n' "$(( (now - ts) / 86400 ))"
}

# status, updated, tracking, title and the Progress line of one runbook, one per
# line. One per line rather than tab-joined because bash treats tab as IFS
# whitespace and silently collapses the empty fields away.
# The Progress line wraps in most runbooks, so it is joined up to the blank line.
parse_runbook() {
  awk '
    function clean(v) { gsub(/\t/, " ", v); gsub(/^[ ]+|[ ]+$/, "", v); return v }
    BEGIN { infm = 0; inprog = 0; status = ""; updated = ""; tracking = ""; title = ""; buf = "" }
    {
      line = $0
      sub(/\r$/, "", line)

      if (NR == 1 && line == "---") { infm = 1; next }
      if (infm && line == "---")    { infm = 0; next }

      if (infm) {
        v = line
        sub(/[ \t]+#.*$/, "", v)          # strip trailing "# planned | ready | ..." hints
        if (v ~ /^status:/)        { sub(/^status:[ \t]*/, "", v);   status = v }
        else if (v ~ /^updated:/)  { sub(/^updated:[ \t]*/, "", v);  updated = v }
        else if (v ~ /^tracking:/) { sub(/^tracking:[ \t]*/, "", v); tracking = v }
        next
      }

      if (title == "" && line ~ /^# /) { title = substr(line, 3); next }

      if (inprog == 1) {
        if (line ~ /^[ \t]*$/) { inprog = 2; next }
        buf = buf " " line
        next
      }
      if (inprog == 0 && line ~ /^\*\*Progress\*\*/) {
        p = line
        sub(/^\*\*Progress\*\*/, "", p)
        sub(/^[^A-Za-z0-9(]*/, "", p)     # the em dash and its spaces, without a multibyte regex
        buf = p
        inprog = 1
        next
      }
    }
    END {
      print clean(status)
      print clean(updated)
      print clean(tracking)
      print clean(title)
      print clean(buf)
    }
  ' "$1"
}

# Every runbook under a subtree, skipping the index, the archive and any
# tool-generated folder that pins its own path there.
find_runbooks() {
  local base="$1"
  [ -d "$base" ] || return 0
  find "$base" -type f -name '*.md' \
    ! -name 'README.md' \
    ! -path '*/done/*' \
    ! -path '*/@nx/*' \
    2>/dev/null | LC_ALL=C sort
}

emit_rows() {
  local root="$1" file rel days ln
  local -a f
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    rel="${file#"$root"/}"
    # "IFS= read -r" line by line keeps empty fields; a $'\t' read would eat them.
    f=()
    while IFS= read -r ln; do f+=("$ln"); done < <(parse_runbook "$file")
    while [ "${#f[@]}" -lt 5 ]; do f+=(""); done
    days="$(days_since "${f[1]}")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$rel" \
      "${f[0]:--}" \
      "${f[1]:--}" \
      "${days:--}" \
      "${f[2]:--}" \
      "${f[3]:--}" \
      "${f[4]:--}"
  done
}

require_dir() {
  local root dir
  root="$(repo_root)"
  dir="${1:-}"
  if [ -z "$dir" ]; then
    if ! dir="$(resolve_dir)"; then
      echo "runbooks.sh: no runbook folder found in $root" >&2
      echo "runbooks.sh: expected one of: ${CANDIDATES[*]}, or a Runbook folder row in CLAUDE.md" >&2
      return 1
    fi
  fi
  printf '%s\n' "$root/${dir#/}"
}

cmd="${1:-}"
if [ $# -gt 0 ]; then shift; fi

case "$cmd" in
  resolve)
    resolve_dir
    ;;
  root)
    repo_root
    ;;
  list)
    root="$(repo_root)"
    base="$(require_dir "${1:-}")"
    find_runbooks "$base" | emit_rows "$root"
    ;;
  archived)
    root="$(repo_root)"
    base="$(require_dir "${1:-}")"
    if [ -d "$base/done" ]; then
      find "$base/done" -type f -name '*.md' ! -name 'README.md' 2>/dev/null \
        | LC_ALL=C sort | emit_rows "$root"
    fi
    ;;
  index)
    base="$(require_dir "${1:-}")"
    if [ -f "$base/README.md" ]; then
      grep -n '^|' "$base/README.md" || true
    else
      echo "runbooks.sh: no index at $base/README.md" >&2
      exit 1
    fi
    ;;
  folders)
    base="$(require_dir "${1:-}")"
    for d in "$base"/*/; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      [ "$name" = "@nx" ] && continue
      if [ "$name" = "done" ]; then
        n="$(find "$d" -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
      else
        n="$(find_runbooks "$d" | wc -l | tr -d ' ')"
      fi
      printf '%s\t%s\n' "$name" "$n"
    done
    n="$(find "$base" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$n" != "0" ]; then printf '%s\t%s\n' "(root)" "$n"; fi
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "runbooks.sh: unknown command '$cmd'" >&2
    usage >&2
    exit 1
    ;;
esac
