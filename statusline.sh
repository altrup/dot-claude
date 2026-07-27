#!/usr/bin/env bash
# Status line: model name, context window fill bar with token counts, 5-hour rate limit, and 7-day rate limit.
# Adapts to available terminal width by dropping sections when space is tight.
#
# Claude Code pipes fresh session state on every call via stdin (refreshInterval: 1).

input=$(timeout 0.3 cat 2>/dev/null)
[ -z "$input" ] && exit 0

# --- Extract all values in a single jq invocation ---
# Outputs: model_name|used_pct|used_tokens|total_tokens|five_pct|week_pct|five_reset|week_reset
#
# Use join("|") instead of @tsv: bash treats tab as an IFS whitespace character,
# which collapses consecutive tabs into one separator and silently drops empty
# fields (e.g. when five_hour.used_percentage is null). Pipe is a non-whitespace
# IFS character so consecutive "||" correctly produces an empty field.
IFS='|' read -r model_name used_pct used_tokens total_tokens five_pct week_pct five_reset week_reset \
  <<< "$(jq -r '[
    (.model.display_name // ""),
    (.context_window.used_percentage // ""),
    (.context_window.total_input_tokens // ""),
    (.context_window.context_window_size // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.resets_at // "")
  ] | join("|")' <<< "$input")"

# Abbreviate a raw token count: <1000 → as-is; 1k–9999 → 1.5k; 10k–999k → 36k; 1M+ → 1.0M
format_tokens() {
  local n="$1"
  if [ "$n" -ge 1000000 ]; then
    # One decimal place for millions
    printf "%.1fM" "$(echo "scale=2; $n / 1000000" | bc)"
  elif [ "$n" -ge 10000 ]; then
    # Whole thousands for 10k+
    printf "%dk" "$(( n / 1000 ))"
  elif [ "$n" -ge 1000 ]; then
    # One decimal place for 1k–9.9k (drops trailing .0 would be misleading at this scale)
    printf "%.1fk" "$(echo "scale=2; $n / 1000" | bc)"
  else
    printf "%d" "$n"
  fi
}

# Format a time-until-reset duration.
# $1 = seconds remaining, $2 = 1 to show days (for 7d), 0 for hours-only (for 5h)
format_duration() {
  local diff="$1"
  local show_days="${2:-0}"
  local d h m
  if [ "$show_days" = "1" ] && [ "$diff" -ge 86400 ]; then
    d=$(( diff / 86400 ))
    h=$(( (diff % 86400) / 3600 ))
    printf "%dd%dh" "$d" "$h"
  elif [ "$diff" -ge 3600 ]; then
    h=$(( diff / 3600 ))
    m=$(( (diff % 3600) / 60 ))
    printf "%dh%dm" "$h" "$m"
  else
    m=$(( diff / 60 ))
    printf "%dm" "$m"
  fi
}

# Build a fill bar of a given total width for a given percentage.
# $1 = label (e.g. "ctx"), $2 = pct (float), $3 = bar_width (inner chars)
# $4 = optional reset-in seconds
# $5 = optional token suffix string (e.g. "12450/200000"), appended after pct
fill_bar() {
  local label="$1"
  local pct="$2"
  local bar_width="$3"
  local reset_secs="$4"
  local token_suffix="$5"

  local pct_int
  pct_int=$(printf '%.0f' "$pct" 2>/dev/null) || pct_int=0
  [ "$pct_int" -gt 100 ] && pct_int=100

  local filled=$(( pct_int * bar_width / 100 ))
  local empty=$(( bar_width - filled ))

  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}#"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}-"; done

  local suffix=""
  if [ -n "$reset_secs" ]; then
    local now diff
    now=$(date +%s)
    diff=$(( reset_secs - now ))
    if [ "$diff" -gt 0 ]; then
      local use_days=0
      [ "$label" = "7d" ] && use_days=1
      suffix=$(format_duration "$diff" "$use_days")
    fi
  fi

  local tok_part=""
  [ -n "$token_suffix" ] && tok_part=" ${token_suffix}"

  local suffix_styled=""
  [ -n "$suffix" ] && suffix_styled=" (${suffix})"

  if [ "$label" = "ctx" ]; then
    printf "%s [%s]%s%s" \
      "$label" "$bar" "$tok_part" "$suffix_styled"
  else
    printf "%s [%s] %d%%%s%s" \
      "$label" "$bar" "$pct_int" "$tok_part" "$suffix_styled"
  fi
}

# --- Determine terminal width (default 80) ---
# Subtract a small margin because Claude Code's status bar has internal padding
# that isn't reflected in the COLUMNS value it passes to the script.
cols=$(( ${COLUMNS:-80} - 4 ))

# --- Build each segment string (no ANSI, for width measurement) ---
# We produce the visible-character length of each section to decide
# how many fill-bar chars to allocate.

SEP=" | "
SEP_LEN=3

# We allocate bar widths dynamically.
# Strategy: aim for 10-char bars. If total > cols, shrink. If still over, drop time.
# If still over with min bar (4), drop sections.

render_output() {
  local bar_w="$1"
  local show_reset="$2"  # 1 or 0
  local show_bars="$3"   # 1 or 0; when 0, omit [####----] and show only labels+values

  local parts=()

  if [ -n "$model_name" ]; then
    parts+=("$model_name")
  fi

  if [ -n "$used_pct" ]; then
    if [ "$show_bars" = "1" ]; then
      local tok_suffix=""
      if [ -n "$used_tokens" ] && [ -n "$total_tokens" ]; then
        tok_suffix="$(format_tokens "$used_tokens")/$(format_tokens "$total_tokens")"
      fi
      parts+=("$(fill_bar "ctx" "$used_pct" "$bar_w" "" "$tok_suffix")")
    else
      local tok_str=""
      if [ -n "$used_tokens" ] && [ -n "$total_tokens" ]; then
        tok_str="$(format_tokens "$used_tokens")/$(format_tokens "$total_tokens")"
      fi
      parts+=("ctx ${tok_str}")
    fi
  fi

  if [ -n "$five_pct" ]; then
    if [ "$show_bars" = "1" ]; then
      local reset_arg=""
      [ "$show_reset" = "1" ] && reset_arg="$five_reset"
      parts+=("$(fill_bar "5h" "$five_pct" "$bar_w" "$reset_arg")")
    else
      local pct_int reset_suffix=""
      pct_int=$(printf '%.0f' "$five_pct" 2>/dev/null) || pct_int=0
      if [ "$show_reset" = "1" ] && [ -n "$five_reset" ]; then
        local now diff
        now=$(date +%s); diff=$(( five_reset - now ))
        [ "$diff" -gt 0 ] && reset_suffix=" $(format_duration "$diff" 0)"
      fi
      parts+=("5h ${pct_int}%${reset_suffix}")
    fi
  fi

  if [ -n "$week_pct" ]; then
    if [ "$show_bars" = "1" ]; then
      local reset_arg=""
      [ "$show_reset" = "1" ] && reset_arg="$week_reset"
      parts+=("$(fill_bar "7d" "$week_pct" "$bar_w" "$reset_arg")")
    else
      local pct_int reset_suffix=""
      pct_int=$(printf '%.0f' "$week_pct" 2>/dev/null) || pct_int=0
      if [ "$show_reset" = "1" ] && [ -n "$week_reset" ]; then
        local now diff
        now=$(date +%s); diff=$(( week_reset - now ))
        [ "$diff" -gt 0 ] && reset_suffix=" $(format_duration "$diff" 1)"
      fi
      parts+=("7d ${pct_int}%${reset_suffix}")
    fi
  fi

  local result=""
  local first=1
  for seg in "${parts[@]}"; do
    if [ "$first" = "1" ]; then
      result="$seg"
      first=0
    else
      result="${result}${SEP}${seg}"
    fi
  done

  printf "%s" "$result"
}

# Measure the visible width of a rendered string by stripping ANSI escape codes.
visible_width() {
  local rendered="$1"
  local stripped
  stripped=$(printf '%s' "$rendered" | sed 's/\x1b\[[0-9;]*m//g')
  echo "${#stripped}"
}

# Shrink bars, keeping reset time throughout.
for bar_w in 15 14 13 12 11 10 9 8 7 6 5 4; do
  rendered=$(render_output "$bar_w" 1 1)
  if [ "$(visible_width "$rendered")" -le "$cols" ]; then
    printf '%s' "$rendered"
    exit 0
  fi
done

# Drop the bars but keep the reset time.
rendered=$(render_output 0 1 0)
if [ "$(visible_width "$rendered")" -le "$cols" ]; then
  printf '%s' "$rendered"
  exit 0
fi

# Last resort: labels and percentages only, no bars, no reset time.
rendered=$(render_output 0 0 0)
printf '%s' "$rendered"
