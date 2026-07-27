#!/usr/bin/env bash
# Tracker helpers for the prd-to-feature plugin.
# All reads and writes to tracker.json go through here so the jq stays in one place.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: tracker.sh <command> [args]

Read:
  next     <tracker>                       Next task id to work on, or "none"
  task     <tracker> <id>                  Full task JSON
  summary  <tracker>                       Counts, plus the non-done tasks grouped by status
  list     <tracker> <status>              All tasks with the given status
  blockers <tracker>                       Blocked tasks with their latest note
  context  <impl-doc> <id>                 Architecture section + this task's section

Write:
  status   <tracker> <id> <status>         todo | in-progress | blocked | done
  note     <tracker> <id> <content> <by>   Append a timestamped note
  files    <tracker> <id> <file>...        Record filesModified
  commit   <tracker> <id> <hash> <iter>    Append to the commits array
  iter     <tracker> <id> <n>|clear        Set or clear currentIteration
  done     <tracker> <id>                  Mark done and clear currentIteration
EOF
}

# Rewrite a tracker in place with the given jq program and arguments.
edit_tracker() {
  local tracker="$1"; shift
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/tracker.XXXXXX")"
  if jq "$@" "$tracker" >"$tmp"; then
    mv "$tmp" "$tracker"
  else
    rm -f "$tmp"
    echo "tracker.sh: failed to update $tracker" >&2
    return 1
  fi
}

need() {
  local n="$1" got="$2"
  if [ "$got" -lt "$n" ]; then
    echo "tracker.sh: not enough arguments" >&2
    usage >&2
    exit 2
  fi
}

# Print the lines of a markdown section: from the line matching $2 up to the
# next heading at the same level or shallower, or end of file. Unlike a fixed
# line-count window this never truncates a long final section.
print_section() {
  local doc="$1" pattern="$2" level="$3"
  awk -v pat="$pattern" -v lvl="$level" '
    !inside && $0 ~ pat { inside = 1; print; next }
    inside {
      # A heading of depth <= lvl ends the section.
      if (match($0, /^#+/) && RLENGTH <= lvl) exit
      print
    }
  ' "$doc"
}

cmd="${1:-}"
[ -n "$cmd" ] || { usage >&2; exit 2; }
shift || true

case "$cmd" in
  next)
    need 1 $#
    # in-progress first (resume interrupted work), then the first todo whose
    # dependencies are all done. Blocked tasks are never selected.
    jq -r '
      .tasks as $all
      | ( [ $all[] | select(.status == "in-progress") | .id ]
        + [ $all[]
            | select(.status == "todo")
            | select(
                (.dependsOn // []) as $deps
                | $deps | all(. as $d | any($all[]; .id == $d and .status == "done"))
              )
            | .id
          ]
        )
      | if length == 0 then "none" else .[0] end
    ' "$1"
    ;;

  task)
    need 2 $#
    jq --arg id "$2" '.tasks[] | select(.id == $id)' "$1"
    ;;

  summary)
    need 1 $#
    jq '
      .tasks as $all
      | {
          feature: .feature,
          implementationDoc: .implementationDoc,
          total: ($all | length),
          done: ([$all[] | select(.status == "done")] | length),
          inProgress: ([$all[] | select(.status == "in-progress")] | length),
          blocked: ([$all[] | select(.status == "blocked")] | length),
          todo: ([$all[] | select(.status == "todo")] | length),
          available: ([
            $all[]
            | select(.status == "todo")
            | select(
                (.dependsOn // []) as $deps
                | $deps | all(. as $d | any($all[]; .id == $d and .status == "done"))
              )
          ] | length),
          # Actionable tasks only. Completed work is a count, not a list -
          # on a 37-task feature the done list is 34 titles nobody reads.
          # Use `tracker.sh list <tracker> done` when you actually want them.
          tasksByStatus: (
            [$all[] | select(.status != "done")]
            | group_by(.status)
            | map({ (.[0].status): map(
                {id, title, phase}
                + (if .currentIteration then {currentIteration} else {} end)
              ) })
            | add // {}
          )
        }
    ' "$1"
    ;;

  list)
    need 2 $#
    jq --arg s "$2" '[
      .tasks[]
      | select(.status == $s)
      | {id, title, phase}
        + (if .currentIteration then {currentIteration} else {} end)
    ]' "$1"
    ;;

  blockers)
    need 1 $#
    jq '[
      .tasks[]
      | select(.status == "blocked")
      | { id, title, dependsOn, lastNote: (.notes // [] | last | .content?) }
    ]' "$1"
    ;;

  context)
    need 2 $#
    doc="$1"; id="$2"
    [ -f "$doc" ] || { echo "tracker.sh: no such file: $doc" >&2; exit 1; }
    echo "=== Tech Stack and Architecture ==="
    print_section "$doc" '^## Tech Stack and Architecture' 2
    echo
    echo "=== Task $id ==="
    print_section "$doc" "^#### ${id}:" 4
    ;;

  status)
    need 3 $#
    case "$3" in
      todo|in-progress|blocked|done) ;;
      *) echo "tracker.sh: invalid status '$3'" >&2; exit 2 ;;
    esac
    edit_tracker "$1" --arg id "$2" --arg s "$3" \
      '.tasks |= map(if .id == $id then .status = $s else . end)'
    ;;

  done)
    need 2 $#
    edit_tracker "$1" --arg id "$2" \
      '.tasks |= map(if .id == $id then .status = "done" | del(.currentIteration) else . end)'
    ;;

  note)
    need 4 $#
    edit_tracker "$1" --arg id "$2" --arg content "$3" --arg by "$4" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '.tasks |= map(
         if .id == $id
         then .notes = ((.notes // []) + [{timestamp: $ts, content: $content, addedBy: $by}])
         else . end
       )'
    ;;

  files)
    need 3 $#
    tracker="$1"; id="$2"; shift 2
    files_json="$(printf '%s\n' "$@" | jq -R . | jq -s .)"
    edit_tracker "$tracker" --arg id "$id" --argjson files "$files_json" \
      '.tasks |= map(if .id == $id then .filesModified = $files else . end)'
    ;;

  commit)
    need 4 $#
    # Migrates a legacy commitHash string into the commits array before appending.
    edit_tracker "$1" --arg id "$2" --arg hash "$3" --argjson iter "$4" \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '.tasks |= map(
         if .id == $id
         then
           ( if .commits then .
             elif .commitHash then .commits = [{hash: .commitHash, iteration: 1}] | del(.commitHash)
             else .commits = []
             end
           )
           | .commits += [{hash: $hash, iteration: $iter, timestamp: $ts}]
         else . end
       )'
    ;;

  iter)
    need 3 $#
    if [ "$3" = "clear" ]; then
      edit_tracker "$1" --arg id "$2" \
        '.tasks |= map(if .id == $id then del(.currentIteration) else . end)'
    else
      edit_tracker "$1" --arg id "$2" --argjson n "$3" \
        '.tasks |= map(if .id == $id then .currentIteration = $n else . end)'
    fi
    ;;

  -h|--help|help)
    usage
    ;;

  *)
    echo "tracker.sh: unknown command '$cmd'" >&2
    usage >&2
    exit 2
    ;;
esac
