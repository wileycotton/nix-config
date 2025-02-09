function kg() {
    local resource_type preview_cmd namespace_opt

    # Check if -n or --namespace flag is provided
    if [[ "$1" == "-n" || "$1" == "--namespace" ]]; then
        namespace_opt="-n $2"
        shift 2
    else
        namespace_opt=""
    fi

    if [ -n "$1" ]; then
        resource_type="$1"
    else
        resource_type=$(kubectl api-resources --no-headers | \
            awk '{print $1}' | sort -u | \
            fzf --prompt="Select resource type > ")
    fi

    [ -z "$resource_type" ] && return 1

    # Build the preview command with proper width handling
    preview_cmd="COLUMNS=\$FZF_PREVIEW_COLUMNS kubectl get $resource_type {1} -o yaml $namespace_opt | yq -C"
    if [ "$resource_type" = "pods" ]; then
        preview_cmd="COLUMNS=\$FZF_PREVIEW_COLUMNS kubectl describe pod {1} $namespace_opt | bat -l yaml --color=always --terminal-width=\$FZF_PREVIEW_COLUMNS"
    fi

    # Main fzf command with preview
    kubectl get "$resource_type" $namespace_opt | \
        fzf --header-lines=1 \
            --layout=reverse \
            --border \
            --prompt="Select $resource_type > " \
            --preview-window=right:70%:wrap \
            --preview "$preview_cmd" \
            --bind "ctrl-r:reload(kubectl get $resource_type $namespace_opt)" \
            --bind "ctrl-y:execute(COLUMNS=\$FZF_PREVIEW_COLUMNS kubectl get $resource_type {1} -o yaml $namespace_opt | yq -C | less -R)" \
            --bind "ctrl-d:execute(COLUMNS=\$FZF_PREVIEW_COLUMNS kubectl describe $resource_type {1} $namespace_opt | less -R)"
}
# Enhanced completion function with namespace support
_kg_completion() {
    local curcontext="$curcontext" state line ret=1
    typeset -A opt_args

    _arguments -C \
        '(-n --namespace)'{-n,--namespace}'[namespace]:namespace:->namespaces' \
        '1: :->resources' \
        '*: :->args' && ret=0

    case $state in
        namespaces)
            local namespaces
            namespaces=(${(f)"$(kubectl get namespaces -o name | cut -d/ -f2)"})
            _describe 'namespaces' namespaces && ret=0
            ;;
        resources)
            local resources
            resources=(${(f)"$(kubectl api-resources --no-headers | awk '{print $1":"$2}')"})
            _describe 'resource types' resources && ret=0
            ;;
    esac

    return ret
}