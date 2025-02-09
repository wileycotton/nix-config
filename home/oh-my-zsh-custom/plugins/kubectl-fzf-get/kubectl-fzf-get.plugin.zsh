function kg() {
    local resource_type preview_cmd namespace_opt

    if [ -n "$1" ]; then
        resource_type="$1"
    else
        resource_type=$(kubectl api-resources --no-headers | \
            awk '{print $1}' | sort -u | \
            fzf --prompt="Select resource type > ")
    fi

    [ -z "$resource_type" ] && return 1

    # Build the preview command with proper width handling
    preview_cmd="COLUMNS=\$FZF_PREVIEW_COLUMNS kubectl get $resource_type {1} -o yaml $namespace_opt | bat -f -l yaml --style numbers"

    # Main fzf command with preview
    kubectl get "$resource_type" $namespace_opt | \
        fzf --header-lines=1 \
            --layout=reverse \
            --border \
            --prompt="Select $resource_type > " \
            --preview-window=right:70%:wrap \
            --preview "$preview_cmd"
}
# Create the completion function for kg
function _kg {
    # Set up the words array as if we're completing 'kubectl get'
    words=(kubectl get "${words[@]:1}")
    # Adjust CURRENT to account for the added 'get' argument
    (( CURRENT++ ))
    # Call the original kubectl completion
    _kubectl
}

# Register the completion
compdef _kg kg
