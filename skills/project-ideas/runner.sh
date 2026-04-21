#!/bin/bash
#
# Project Ideas skill runner - manage and prioritize project ideas

PROJECTS_DIR="$HOME/.opencode/agent/core/Project ideas"
DATA_FILE="$HOME/.opencode/skills/project-ideas/projects.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Ensure data file exists
init_data() {
    if [ ! -f "$DATA_FILE" ]; then
        echo '{"projects":[]}' > "$DATA_FILE"
    fi
}

# Get current timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Add a project to the JSON
add_project() {
    local name="$1"
    local category="$2"
    local description="$3"
    
    init_data
    
    # Check if project exists
    if jq -e ".projects[] | select(.name == \"$name\")" "$DATA_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Project already exists: $name${NC}"
        return 1
    fi
    
    # Add new project
    local new_project=$(jq -n \
        --arg name "$name" \
        --arg category "$category" \
        --arg description "$description" \
        --arg status "idea" \
        --arg priority 5 \
        --arg project_name "" \
        --arg timestamp "$(get_timestamp)" \
        '{
            name: $name,
            project_name: $project_name,
            category: $category,
            description: $description,
            status: $status,
            priority: ($priority | tonumber),
            created: $timestamp,
            updated: $timestamp
        }')
    
    jq ".projects += [$new_project]" "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    echo -e "${GREEN}Added: $name${NC}"
}

# Set status for a project
set_status() {
    local name="$1"
    local status="$2"
    
    init_data
    
    if [ "$status" != "idea" ] && [ "$status" != "in-progress" ] && [ "$status" != "done" ]; then
        echo -e "${RED}Invalid status. Use: idea, in-progress, done${NC}"
        return 1
    fi
    
    # Use index-based lookup - find matching project and get its index
    local index=$(jq -r ".projects | to_entries | .[] | select(.value.name | contains(\"$name\")) | .key" "$DATA_FILE")
    
    if [ -z "$index" ]; then
        echo -e "${RED}Project not found: $name${NC}"
        echo "Available projects:"
        jq -r '.projects[].name' "$DATA_FILE" | head -5
        return 1
    fi
    
    # Update status by index
    jq ".\"projects\"[$index].status = \"$status\" | .\"projects\"[$index].updated = \"$(get_timestamp)\"" "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    echo -e "${GREEN}Set status '$status' for: $name${NC}"
}

# Set priority for a project
set_priority() {
    local name="$1"
    local priority="$2"
    
    init_data
    
    if ! [[ "$priority" =~ ^[1-9]$|^10$ ]]; then
        echo -e "${RED}Priority must be 1-10 (1 = highest)${NC}"
        return 1
    fi
    
    local index=$(jq -r ".projects | to_entries | .[] | select(.value.name | contains(\"$name\")) | .key" "$DATA_FILE")
    
    if [ -z "$index" ]; then
        echo -e "${RED}Project not found: $name${NC}"
        return 1
    fi
    
    jq ".\"projects\"[$index].priority = ($priority | tonumber) | .\"projects\"[$index].updated = \"$(get_timestamp)\"" "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    echo -e "${GREEN}Set priority $priority for: $name${NC}"
}

# Set category for a project
set_category() {
    local name="$1"
    local category="$2"
    
    init_data
    
    local index=$(jq -r ".projects | to_entries | .[] | select(.value.name | contains(\"$name\")) | .key" "$DATA_FILE")
    
    if [ -z "$index" ]; then
        echo -e "${RED}Project not found: $name${NC}"
        return 1
    fi
    
    jq ".\"projects\"[$index].category = \"$category\" | .\"projects\"[$index].updated = \"$(get_timestamp)\"" "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    echo -e "${GREEN}Set category '$category' for: $name${NC}"
}

# Set project name (friendly name for the project)
set_project_name() {
    local name="$1"
    local project_name="$2"
    
    init_data
    
    local index=$(jq -r ".projects | to_entries | .[] | select(.value.name | contains(\"$name\")) | .key" "$DATA_FILE")
    
    if [ -z "$index" ]; then
        echo -e "${RED}Project not found: $name${NC}"
        return 1
    fi
    
    jq ".\"projects\"[$index].project_name = \"$project_name\" | .\"projects\"[$index].updated = \"$(get_timestamp)\"" "$DATA_FILE" > "$DATA_FILE.tmp" && mv "$DATA_FILE.tmp" "$DATA_FILE"
    echo -e "${GREEN}Set project name '$project_name' for: $name${NC}"
}

# Show all projects
cmd_list() {
    init_data
    
    echo -e "${CYAN}=== All Project Ideas ===${NC}"
    echo ""
    
    local count=$(jq '.projects | length' "$DATA_FILE")
    if [ "$count" -eq 0 ]; then
        echo "No projects yet. Run 'scan' to import from .md files."
        return
    fi
    
    # First show in-progress projects
    local in_progress=$(jq '[.projects[] | select(.status == "in-progress")] | length' "$DATA_FILE")
    if [ "$in_progress" -gt 0 ]; then
        echo -e "${GREEN}--- IN PROGRESS ---${NC}"
        jq -r '.projects[] | select(.status == "in-progress") | 
            "  \(.name)\n  Project: \(.project_name // "(not set)")\n  Priority: \(.priority) | Category: \(.category // "none")"
        ' "$DATA_FILE"
        echo ""
    fi
    
    # Then show ideas
    local ideas=$(jq '[.projects[] | select(.status == "idea")] | length' "$DATA_FILE")
    if [ "$ideas" -gt 0 ]; then
        echo -e "${CYAN}--- IDEAS ---${NC}"
        jq -r '.projects[] | select(.status == "idea") | 
            "  \(.name)\n  Project: \(.project_name // "(not set)")\n  Priority: \(.priority) | Category: \(.category // "none")"
        ' "$DATA_FILE"
        echo ""
    fi
    
    # Then show done projects
    local done=$(jq '[.projects[] | select(.status == "done")] | length' "$DATA_FILE")
    if [ "$done" -gt 0 ]; then
        echo -e "${YELLOW}--- DONE ---${NC}"
        jq -r '.projects[] | select(.status == "done") | 
            "  \(.name) | Project: \(.project_name // "(not set)")"
        ' "$DATA_FILE"
    fi
}

# Show priority queue (for picking next project)
cmd_queue() {
    init_data
    
    echo -e "${CYAN}=== Priority Queue (ready to work on) ===${NC}"
    echo ""
    
    local count=$(jq '[.projects[] | select(.status != "done")] | length' "$DATA_FILE")
    if [ "$count" -eq 0 ]; then
        echo "No active projects. All done!"
        return
    fi
    
    # Show in-progress first, then sorted by priority
    echo -e "${YELLOW}--- IN PROGRESS ---${NC}"
    jq -r '.projects[] | select(.status == "in-progress") | 
        "  \(.name)\n  Project: \(.project_name // "none") [priority: \(.priority)] [category: \(.category // "none")]"
    ' "$DATA_FILE"
    
    echo ""
    echo -e "${YELLOW}--- IDEAS (by priority) ---${NC}"
    jq -r '.projects[] | select(.status == "idea") | 
        select(.status == "idea") | 
        "\(.priority). \(.name)\n    project: \(.project_name // "none") [category: \(.category // "none")]"
    ' "$DATA_FILE" | sort -n
}

# Show priority queue (for picking next project)
cmd_queue() {
    init_data
    
    echo -e "${CYAN}=== Priority Queue (ready to work on) ===${NC}"
    echo ""
    
    local count=$(jq '[.projects[] | select(.status != "done")] | length' "$DATA_FILE")
    if [ "$count" -eq 0 ]; then
        echo "No active projects. All done!"
        return
    fi
    
    # Show in-progress first
    local in_progress_count=$(jq '[.projects[] | select(.status == "in-progress")] | length' "$DATA_FILE")
    if [ "$in_progress_count" -gt 0 ]; then
        echo -e "${YELLOW}--- IN PROGRESS ---${NC}"
        while IFS= read -r line; do
            echo "  $line"
        done < <(jq -r '.projects[] | select(.status == "in-progress") | 
            "\(.name) | proj: \(.project_name // "-") | pri: \(.priority) | cat: \(.category // "none")"
        ' "$DATA_FILE")
        echo ""
    fi
    
    # Then ideas sorted by priority
    local ideas_count=$(jq '[.projects[] | select(.status == "idea")] | length' "$DATA_FILE")
    if [ "$ideas_count" -gt 0 ]; then
        echo -e "${YELLOW}--- IDEAS (by priority) ---${NC}"
        while IFS= read -r line; do
            echo "  $line"
        done < <(jq -r '.projects[] | select(.status == "idea") | 
            "\(.priority). \(.name) | proj: \(.project_name // "-") | cat: \(.category // "none")"
        ' "$DATA_FILE" | sort -t'.' -k1 -n)
    fi
}

# Show single project details
cmd_show() {
    local name="$1"
    init_data
    
    if [ -z "$name" ]; then
        echo -e "${RED}Usage: $0 show \"Project Name\"${NC}"
        return 1
    fi
    
    # Use contains for partial matching
    jq -r ".projects[] | select(.name | contains(\"$name\")) | 
        \"Name: \(.name)\nProject Name: \(.project_name // "none")\nStatus: \(.status)\nPriority: \(.priority)\nCategory: \(.category // "none")\nDescription: \(.description)\nCreated: \(.created)\nUpdated: \(.updated)\""
    "$DATA_FILE"
}

# Scan .md files and import ideas
cmd_scan() {
    init_data
    
    echo -e "${CYAN}=== Scanning for new ideas ===${NC}"
    echo "Looking in: $PROJECTS_DIR"
    echo ""
    
    if [ ! -d "$PROJECTS_DIR" ]; then
        echo -e "${RED}Ideas folder not found: $PROJECTS_DIR${NC}"
        return 1
    fi
    
    local count=0
    
    # Find all .md files
    for file in "$PROJECTS_DIR"/*.md; do
        if [ -f "$file" ]; then
            echo "Scanning: $(basename "$file")"
            
            # Extract project names from - **"Project Name"** pattern
            # Clean up: remove leading "-", spaces, "**", and quotes
            local projects=$(grep -oP '^\s*-\s+\*\*"?([^"]+)"?\*\*' "$file" 2>/dev/null | \
                sed 's/^-[[:space:]]*//;s/\*\*//g;s/"//g')
            
            while IFS= read -r project; do
                # Skip empty lines and non-project headers
                if [ -n "$project" ] && [ ${#project} -gt 3 ]; then
                    # Check if already exists (compare cleaned names)
                    if ! jq -e ".projects[] | select(.name == \"$project\")" "$DATA_FILE" > /dev/null 2>&1; then
                        add_project "$project" "uncategorized" "Imported from $(basename "$file")"
                        count=$((count + 1))
                    fi
                fi
            done <<< "$projects"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Imported $count new project ideas${NC}"
}

# Show help
usage() {
    echo "Project Ideas Skill"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list                    - Show all project ideas"
    echo "  queue                   - Show priority queue (next project to work on)"
    echo "  scan                    - Scan .md files for new ideas"
    echo "  show \"<name>\"           - Show project details"
    echo "  init \"<name>\" \"<project-name>\" - Create project from idea (sets name + in-progress)"
    echo "  status \"<name>\" <status>  - Set status: idea, in-progress, done"
    echo "  priority \"<name>\" <1-10>  - Set priority (1 = highest)"
    echo "  category \"<name>\" <cat>  - Set category"
    echo "  projectname \"<name>\" \"<name>\" - Set friendly project name"
    echo ""
    echo "Examples:"
    echo "  $0 queue"
    echo "  $0 init \"Just Pick Dinner\" dinner-picker"
    echo "  $0 status \"Just Pick Dinner\" in-progress"
    echo "  $0 priority \"Minimum Viable Day\" 1"
    echo "  $0 projectname \"Just Pick Dinner\" dinner-picker"
}

# Main
case "$1" in
    list) cmd_list ;;
    queue) cmd_queue ;;
    scan) cmd_scan ;;
    show) cmd_show "$2" ;;
    init)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Usage: $0 init \"<idea-name>\" \"<project-name>\"${NC}"
            exit 1
        fi
        set_project_name "$2" "$3"
        set_status "$2" "in-progress"
        ;;
    status) 
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Usage: $0 status \"<name>\" <status>${NC}"
            exit 1
        fi
        set_status "$2" "$3" 
        ;;
    priority)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Usage: $0 priority \"<name>\" <1-10>${NC}"
            exit 1
        fi
        set_priority "$2" "$3"
        ;;
    category)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Usage: $0 category \"<name>\" <category>${NC}"
            exit 1
        fi
        set_category "$2" "$3"
        ;;
    projectname)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Usage: $0 projectname \"<name>\" \"<project-name>\"${NC}"
            exit 1
        fi
        set_project_name "$2" "$3"
        ;;
    *) usage ; exit 1 ;;
esac