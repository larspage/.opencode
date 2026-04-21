#!/bin/bash
#
# Sync skill runner - reads and writes Moe state files
#

STATE_DIR="$HOME/STATE"
CHANGELOG="$STATE_DIR/CHANGELOG.md"
MAILBOX="$STATE_DIR/MAILBOX.md"
TODO="$STATE_DIR/TODO.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

cmd_read() {
    echo -e "${YELLOW}=== MAILBOX ===${NC}"
    cat "$MAILBOX"
    echo ""
    echo -e "${YELLOW}=== TODO ===${NC}"
    cat "$TODO"
    echo ""
    echo -e "${YELLOW}=== CHANGELOG (last 20) ===${NC}"
    tail -20 "$CHANGELOG"
}

cmd_start() {
    echo -e "${GREEN}=== SESSION START ===${NC}"
    echo "Timestamp: $(timestamp)"
    echo ""
    echo -e "${YELLOW}Open Threads:${NC}"
    grep "^## Open" -A 10 "$MAILBOX" | grep -v "^##" | grep -v "^-$" | head -5
    echo ""
    echo -e "${YELLOW}Active TODO:${NC}"
    grep "^\- \[" "$TODO" | head -5
}

cmd_end() {
    echo -e "${GREEN}=== SESSION END ===${NC}"
    echo "Timestamp: $(timestamp)"
    echo ""
    # Show what was done this session
    echo -e "${YELLOW}Recent Changes:${NC}"
    tail -5 "$CHANGELOG"
    echo ""
    # Show remaining open threads
    echo -e "${YELLOW}Open Threads:${NC}"
    grep "^## Open" -A 10 "$MAILBOX" | grep -v "^##" | grep -v "^-$" | head -5
}

cmd_add() {
    shift
    local msg="$*"
    if [ -z "$msg" ]; then
        echo -e "${RED}Error: missing message${NC}"
        echo "Usage: $0 add [category]: description"
        exit 1
    fi
    
    local entry="- $(timestamp) $msg"
    echo "$entry" >> "$CHANGELOG"
    echo -e "${GREEN}Added to CHANGELOG:${NC} $entry"
}

cmd_mail() {
    shift
    local msg="$*"
    if [ -z "$msg" ]; then
        echo -e "${RED}Error: missing message${NC}"
        echo "Usage: $0 mail [category]: description"
        exit 1
    fi
    
    local entry="- $(timestamp) $msg"
    echo "$entry" >> "$MAILBOX"
    echo -e "${GREEN}Added to MAILBOX:${NC} $entry"
}

cmd_todo() {
    echo -e "${YELLOW}=== TODO ===${NC}"
    cat "$TODO"
}

usage() {
    echo "Sync Skill Runner"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  read           - Read all state files"
    echo "  start         - Session start: show active state"
    echo "  end           - Session end: show resolution"
    echo "  add <msg>     - Add CHANGELOG entry"
    echo "  mail <msg>   - Add MAILBOX entry"
    echo "  todo         - Show TODO items"
    echo ""
    echo "Categories: deploy, cleanup, fix, add, docs, state, config"
}

# Main
case "$1" in
    read) cmd_read ;;
    start) cmd_start ;;
    end) cmd_end ;;
    add) cmd_add "$@" ;;
    mail) cmd_mail "$@" ;;
    todo) cmd_todo ;;
    *) usage ; exit 1 ;;
esac