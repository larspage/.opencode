#!/bin/bash
#
# Sync skill runner - reads and writes Moe state files
# STATE lives in MeAndMoeBrain project
#

MEANDMOEBRAIN="/mnt/data/projects/MeAndMoeBrain"
STATE_DIR="$MEANDMOEBRAIN/STATE"
CHANGELOG="$STATE_DIR/CHANGELOG.md"
MAILBOX="$STATE_DIR/MAILBOX.md"
TODO="$STATE_DIR/TODO.md"

# MeAndMoeBrain files
SOUL="$MEANDMOEBRAIN/SOUL.md"
USER="$MEANDMOEBRAIN/USER.md"
AGENTS="$MEANDMOEBRAIN/AGENTS.md"
MEMORY="$MEANDMOEBRAIN/MEMORY.md"
MEMORY_DIR="$MEANDMOEBRAIN/memory"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

today_note() {
    date -u +"%Y-%m-%d"
}

yesterday_note() {
    date -u -d "yesterday" +"%Y-%m-%d"
}

cmd_brain_read() {
    echo -e "${GREEN}=== MEANDMOEBRAIN BRAIN READ ===${NC}"
    echo ""
    
    echo -e "${YELLOW}=== SOUL.md ===${NC}"
    [ -f "$SOUL" ] && head -20 "$SOUL" || echo "File not found"
    echo ""
    
    echo -e "${YELLOW}=== USER.md ===${NC}"
    [ -f "$USER" ] && head -20 "$USER" || echo "File not found"
    echo ""
    
    echo -e "${YELLOW}=== AGENTS.md ===${NC}"
    [ -f "$AGENTS" ] && head -20 "$AGENTS" || echo "File not found"
    echo ""
    
    echo -e "${YELLOW}=== MEMORY.md (last 20) ===${NC}"
    [ -f "$MEMORY" ] && tail -20 "$MEMORY" || echo "File not found"
    echo ""
    
    echo -e "${YELLOW}=== Today's Daily Note ===${NC}"
    TODAY=$(today_note)
    [ -f "$MEMORY_DIR/$TODAY.md" ] && cat "$MEMORY_DIR/$TODAY.md" || echo "No note for $TODAY"
    echo ""
    
    cmd_read
}

cmd_brain_sync() {
    echo -e "${GREEN}=== BRAIN SYNC (STARTUP) ===${NC}"
    echo "Timestamp: $(timestamp)"
    echo ""
    
    # Read all brain files
    cmd_brain_read
    
    # Check for yesterday's note to close
    YESTERDAY=$(yesterday_note)
    if [ -f "$MEMORY_DIR/$YESTERDAY.md" ]; then
        echo -e "${YELLOW}=== Closing Yesterday's Note: $YESTERDAY ===${NC}"
        # Add session end if not present
        if ! grep -q "## Session End" "$MEMORY_DIR/$YESTERDAY.md"; then
            echo "" >> "$MEMORY_DIR/$YESTERDAY.md"
            echo "## Session End" >> "$MEMORY_DIR/$YESTERDAY.md"
            echo "- Time: $(timestamp)" >> "$MEMORY_DIR/$YESTERDAY.md"
        fi
    fi
    
    # Create today's note if missing
    TODAY=$(today_note)
    if [ ! -f "$MEMORY_DIR/$TODAY.md" ]; then
        echo -e "${GREEN}Creating today's note: $TODAY.md${NC}"
        cat > "$MEMORY_DIR/$TODAY.md" <<EOF
# Daily Note: $TODAY

## Session Start
- Time: $(timestamp)

## Log

## Session End
- Time: 

## Memory Promotion
- Status: Pending
- Last Processed: 
EOF
    fi
    
    # Process pending memory promotions
    echo -e "${YELLOW}=== Processing Pending Memory Notes ===${NC}"
    for note in "$MEMORY_DIR"/*.md; do
        if [ -f "$note" ]; then
            if grep -q "Memory Promotion Status: Pending" "$note" 2>/dev/null; then
                echo "Found pending: $(basename $note)"
                # TODO: Implement promotion logic to MEMORY.md
            fi
        fi
    done
    
    # Scan for interrupted tasks [~]
    echo -e "${YELLOW}=== Scanning for Interrupted Tasks [~] ===${NC}"
    find "$MEANDMOEBRAIN" -name "TODO.md" -exec grep -l "\[~\]" {} \; 2>/dev/null | while read f; do
        echo "Found interrupted tasks in: $f"
        grep "\[~\]" "$f"
    done
    
    # Push to GitHub
    echo -e "${YELLOW}=== Pushing to GitHub ===${NC}"
    cd "$MEANDMOEBRAIN" && git add -A && git commit -m "Brain sync: $(timestamp)" && git push
    
    echo -e "${GREEN}=== BRAIN SYNC COMPLETE ===${NC}"
}

cmd_brain_close() {
    echo -e "${GREEN}=== BRAIN CLOSE (SHUTDOWN) ===${NC}"
    echo "Timestamp: $(timestamp)"
    echo ""
    
    # Log session summary to today's note
    TODAY=$(today_note)
    if [ -f "$MEMORY_DIR/$TODAY.md" ]; then
        echo -e "${YELLOW}Updating today's note...${NC}"
        # Update session end time
        sed -i "s/## Session End\n- Time: /## Session End\n- Time: $(timestamp)/" "$MEMORY_DIR/$TODAY.md"
        
        # Add session summary
        echo "" >> "$MEMORY_DIR/$TODAY.md"
        echo "## Session Summary" >> "$MEMORY_DIR/$TODAY.md"
        echo "- Closed at: $(timestamp)" >> "$MEMORY_DIR/$TODAY.md"
        echo "- Recent changes:" >> "$MEMORY_DIR/$TODAY.md"
        tail -5 "$CHANGELOG" >> "$MEMORY_DIR/$TODAY.md"
        
        # Set memory promotion status
        sed -i "s/Status: .*/Status: Pending/" "$MEMORY_DIR/$TODAY.md"
    fi
    
    # Bridge to project STATE files
    echo -e "${YELLOW}=== Bridging to Project STATE Files ===${NC}"
    find /mnt/data/projects -name "TODO.md" -exec grep -l "\[important\]\|\[cross-project\]" {} \; 2>/dev/null | while read f; do
        echo "Found tagged task in: $f"
        grep "\[important\]\|\[cross-project\]" "$f"
    done
    
    # Push to GitHub
    echo -e "${YELLOW}=== Pushing to GitHub ===${NC}"
    cd "$MEANDMOEBRAIN" && git add -A && git commit -m "Brain close: $(timestamp)" && git push
    
    echo -e "${GREEN}=== BRAIN CLOSE COMPLETE ===${NC}"
}

cmd_brain_push() {
    echo -e "${GREEN}=== BRAIN PUSH (MANUAL) ===${NC}"
    cd "$MEANDMOEBRAIN" && git add -A && git commit -m "Brain push: $(timestamp)" && git push
    echo -e "${GREEN}=== PUSH COMPLETE ===${NC}"
}

cmd_read() {
    echo -e "${YELLOW}=== MAILBOX ===${NC}"
    [ -f "$MAILBOX" ] && cat "$MAILBOX" || echo "File not found: $MAILBOX"
    echo ""
    echo -e "${YELLOW}=== TODO ===${NC}"
    [ -f "$TODO" ] && cat "$TODO" || echo "File not found: $TODO"
    echo ""
    echo -e "${YELLOW}=== CHANGELOG (last 20) ===${NC}"
    [ -f "$CHANGELOG" ] && tail -20 "$CHANGELOG" || echo "File not found: $CHANGELOG"
}

cmd_start() {
    echo -e "${GREEN}=== SESSION START ===${NC}"
    echo "Timestamp: $(timestamp)"
    echo ""
    echo -e "${YELLOW}Open Threads:${NC}"
    [ -f "$MAILBOX" ] && grep "^## Open" -A 10 "$MAILBOX" | grep -v "^##" | grep -v "^-$" | head -5
    echo ""
    echo -e "${YELLOW}Active TODO:${NC}"
    [ -f "$TODO" ] && grep "^\- \[" "$TODO" | head -5
}

cmd_end() {
    echo -e "${GREEN}=== SESSION END ===${NC}"
    echo "Timestamp: $(timestamp)"
    echo ""
    echo -e "${YELLOW}Recent Changes:${NC}"
    [ -f "$CHANGELOG" ] && tail -5 "$CHANGELOG"
    echo ""
    echo -e "${YELLOW}Open Threads:${NC}"
    [ -f "$MAILBOX" ] && grep "^## Open" -A 10 "$MAILBOX" | grep -v "^##" | grep -v "^-$" | head -5
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
    [ -f "$TODO" ] && cat "$TODO" || echo "File not found: $TODO"
}

usage() {
    echo "Sync Skill Runner"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Brain Commands (MeAndMoeBrain):"
    echo "  brain-read     - Read all brain files (SOUL, USER, AGENTS, MEMORY, daily notes)"
    echo "  brain-sync     - Startup: read brain, process notes, push to GitHub"
    echo "  brain-close    - Shutdown: log session, set pending, push to GitHub"
    echo "  brain-push     - Manual push to GitHub"
    echo ""
    echo "Project STATE Commands:"
    echo "  read           - Read all STATE files (CHANGELOG, MAILBOX, TODO)"
    echo "  start          - Session start: show active state"
    echo "  end            - Session end: show resolution"
    echo "  add <msg>      - Add CHANGELOG entry"
    echo "  mail <msg>     - Add MAILBOX entry"
    echo "  todo           - Show TODO items"
    echo ""
    echo "Categories: deploy, cleanup, fix, add, docs, state, config"
}

# Main
case "$1" in
    brain-read) cmd_brain_read ;;
    brain-sync) cmd_brain_sync ;;
    brain-close) cmd_brain_close ;;
    brain-push) cmd_brain_push ;;
    read) cmd_read ;;
    start) cmd_start ;;
    end) cmd_end ;;
    add) cmd_add "$@" ;;
    mail) cmd_mail "$@" ;;
    todo) cmd_todo ;;
    *) usage ; exit 1 ;;
esac
