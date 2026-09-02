#!/bin/bash
# Double-click this in Finder to start the Project 50 tracker and open it
# in your default browser. Close this window (or press Ctrl+C) to stop the server.

cd "$(dirname "$0")" || exit 1

echo "Starting Project 50 Progress dashboard…"
python3 server.py &
SERVER_PID=$!

# Stop the server when this window is closed or interrupted.
trap 'kill "$SERVER_PID" 2>/dev/null' EXIT

sleep 1
open "http://localhost:8000"

echo
echo "Dashboard: http://localhost:8000"
echo "Leave this window open. Ctrl+C or close it to stop."
wait "$SERVER_PID"
