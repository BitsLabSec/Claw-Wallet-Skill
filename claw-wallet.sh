#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$SCRIPT_DIR/clay-sandbox"
LOG_FILE="$SCRIPT_DIR/sandbox.log"
PID_FILE="$SCRIPT_DIR/sandbox.pid"
SKILL_BRANCH="${CLAW_WALLET_SKILL_BRANCH:-dev}"

stop_sandbox() {
    cd "$SCRIPT_DIR"
    "$BIN" stop >/dev/null 2>&1 || true
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
    fi
    echo "claw wallet sandbox stop requested."
}

# upgrade runs before binary check (git + install, no sandbox needed yet)
if [ "${1:-}" = "upgrade" ]; then
    shift
    cd "$SCRIPT_DIR"
    stop_sandbox
    if [ -d "$SCRIPT_DIR/.git" ]; then
        git stash
        git pull
        git stash pop
    else
        echo "No .git found (installed via npx skills). Initializing git and pulling latest ..."
        cd "$SCRIPT_DIR"
        BAK_DIR="$(mktemp -d)"
        [ -f "$SCRIPT_DIR/.env.clay" ] && cp -a "$SCRIPT_DIR/.env.clay" "$BAK_DIR/"
        [ -f "$SCRIPT_DIR/identity.json" ] && cp -a "$SCRIPT_DIR/identity.json" "$BAK_DIR/"
        [ -f "$SCRIPT_DIR/share3.json" ] && cp -a "$SCRIPT_DIR/share3.json" "$BAK_DIR/"
        git init
        git remote add origin https://github.com/ClawWallet/Claw-Wallet-Skill.git
        if git fetch origin "$SKILL_BRANCH" 2>/dev/null; then
            git reset --hard "origin/$SKILL_BRANCH"
        elif git fetch origin main 2>/dev/null; then
            git reset --hard origin/main
        else
            git fetch origin master
            git reset --hard origin/master
        fi
        [ -f "$BAK_DIR/.env.clay" ] && cp -a "$BAK_DIR/.env.clay" "$SCRIPT_DIR/"
        [ -f "$BAK_DIR/identity.json" ] && cp -a "$BAK_DIR/identity.json" "$SCRIPT_DIR/"
        [ -f "$BAK_DIR/share3.json" ] && cp -a "$BAK_DIR/share3.json" "$SCRIPT_DIR/"
        rm -rf "$BAK_DIR"
    fi
    CLAW_WALLET_SKIP_INIT=1 bash "$SCRIPT_DIR/install.sh"
    exit 0
fi

# uninstall runs before binary check
if [ "${1:-}" = "uninstall" ]; then
    shift
    stop_sandbox
    echo ""
    echo "=== WARNING: Uninstall claw-wallet skill ==="
    echo "This will DELETE the entire skill directory and all wallet data."
    echo "Files to be removed: .env.clay, identity.json, share3.json, and all others."
    echo "This action is IRREVERSIBLE. Please backup .env.clay, identity.json, share3.json first if needed."
    echo ""
    read -p "Type 'yes' to confirm uninstall: " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Uninstall cancelled."
        exit 0
    fi
    echo "Removing $SCRIPT_DIR ..."
    cd "$(dirname "$SCRIPT_DIR")"
    rm -rf "$SCRIPT_DIR"
    echo "claw-wallet skill has been uninstalled."
    exit 0
fi

if [ ! -x "$BIN" ]; then
    echo "claw wallet sandbox is not installed. Expected binary at: $BIN"
    echo "Run: bash $SCRIPT_DIR/install.sh"
    exit 1
fi

is_running() {
    if [ -f "$PID_FILE" ]; then
        PID="$(cat "$PID_FILE" 2>/dev/null || true)"
        if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

start_sandbox() {
    if is_running; then
        echo "claw wallet sandbox is already running."
        echo "PID file: $PID_FILE"
        echo "Log file: $LOG_FILE"
        return 0
    fi

    cd "$SCRIPT_DIR"
    if command -v setsid >/dev/null 2>&1; then
        nohup setsid "$BIN" serve >> "$LOG_FILE" 2>&1 < /dev/null &
    else
        nohup "$BIN" serve >> "$LOG_FILE" 2>&1 < /dev/null &
    fi
    echo $! > "$PID_FILE"
    echo "claw wallet sandbox launched in the background."
    echo "PID file: $PID_FILE"
    echo "Log file: $LOG_FILE"
    if [ -f "$SCRIPT_DIR/.env.clay" ]; then
        echo "API auth: if HTTP returns 401, send header Authorization: Bearer <token> using AGENT_TOKEN or CLAY_AGENT_TOKEN from .env.clay (or agent_token in identity.json). See SKILL.md."
    fi
}

restart_sandbox() {
    stop_sandbox
    sleep 2
    start_sandbox
}

case "${1:-}" in
    ""|start)
        [ "${1:-}" = "start" ] && shift
        start_sandbox
        exit 0
        ;;
    restart)
        shift
        restart_sandbox
        exit 0
        ;;
    stop)
        shift
        stop_sandbox
        exit 0
        ;;
    is-running)
        shift
        if is_running; then
            echo "claw wallet sandbox is running."
            exit 0
        else
            echo "claw wallet sandbox is not running."
            exit 1
        fi
        ;;
    serve)
        shift
        cd "$SCRIPT_DIR"
        exec "$BIN" serve "$@"
        ;;
esac

cd "$SCRIPT_DIR"
exec "$BIN" "$@"
