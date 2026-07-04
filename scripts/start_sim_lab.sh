#!/usr/bin/env bash
# Launches the sim_lab tmuxp stack, sweeping any leftover processes from a
# prior run first (stale processes on fixed ports - 5760, 14550/14551, 9002 -
# would otherwise make the new launch silently attach to old state instead
# of a fresh one).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== pre-run cleanup ==="
"$SCRIPT_DIR/stop_sim_lab.sh" || true

echo "=== launching sim_lab ==="
cd "$SCRIPT_DIR/.."
tmuxp load -d --yes tmux/sim_lab.tmuxp.yaml
echo "Launched. Attach with: tmux attach -t sim_lab"
echo "Stop with: scripts/stop_sim_lab.sh"
