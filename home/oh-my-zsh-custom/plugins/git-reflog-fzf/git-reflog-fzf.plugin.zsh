# Define the function
function grf() {
    git reflog | fzf --layout=reverse \
        --border \
        --preview 'git show --color=always {1}' \
        --preview-window=right:60%:wrap
}

# Create an alias
alias grfl='grf'

# Add completion support
compdef grf=git
compdef grfl=git

# Add help text for the function
function _grf_help() {
    echo "Usage: grf"
    echo "Interactive git reflog viewer with fzf preview"
}

# Register the help text
[[ -n "${_comps[grf]}" ]] && compdef _grf_help grf
