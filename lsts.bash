
lsts_set_cmd() {
    [[ $# == 1 ]] || {
        echo "lsts_set_cmd requires the command to start the target language server"
        exit 1
    }
    ls="$(echo "$1" | awk '{print $1}')"
    command -v "$ls" > /dev/null || {
        echo "lsts_set_cmd cannot find the target language server: '$ls'"
        exit 1
    }
    LSTS_CMD="$1"
}

lsts_set_root() {
    [[ $# == 1 ]] || {
        echo "lsts_set_root requires a root directory for specifying workspaceFolders"
        exit 1
    }
    LSTS_ROOT="$1"
}

lsts_set_langId() {
    [[ $# == 1 ]] || {
        echo "lsts_set_langId requires the language identifier"
        exit 1
    }
    LSTS_LANG_ID="$1"
}

_LSTS_ID=0

lsts_send() {
    local body="$1"
    local len=${#body}
    printf "Content-Length: %d\r\n\r\n%s" "$len" "$body" >&"$LSTS_WRITE_FD"
}

lsts_recv() {
    local line content_length=0 raw

    while IFS= read -r -t "${LSTS_TIMEOUT:-10}" line <&"$LSTS_READ_FD"; do
        line="${line%$'\r'}"
        [[ -z "$line" ]] && break
        if [[ "$line" =~ ^Content-Length:\ ([0-9]+)$ ]]; then
            content_length="${BASH_REMATCH[1]}"
        fi
    done

    [[ "$content_length" -eq 0 ]] && {
        echo "lsts_recv: no Content-Length header received" >&2
        return 1
    }

    IFS= read -r -N "$content_length" -t "${LSTS_TIMEOUT:-10}" raw <&"$LSTS_READ_FD"

    LSTS_RESPONSE="$(printf '%s' "$raw" | tr '\t\n' '  ')"
}

lsts_recv_response() {
    while true; do
        lsts_recv || return 1
        printf '%s' "$LSTS_RESPONSE" | jq -e 'has("id")' >/dev/null 2>&1 && return 0
    done
}

lsts_request() {
    local method="$1" params="$2"
    _LSTS_ID=$((_LSTS_ID + 1))
    lsts_send "{\"jsonrpc\":\"2.0\",\"id\":${_LSTS_ID},\"method\":\"${method}\",\"params\":${params}}"
}

lsts_notify() {
    local method="$1" params="$2"
    lsts_send "{\"jsonrpc\":\"2.0\",\"method\":\"${method}\",\"params\":${params}}"
}

lsts_start() {
    : "${LSTS_CMD:?language server command not set. use lsts_set_cmd to set the command to start the target language server}"
    : "${LSTS_ROOT:?root directory not set. use lsts_set_root to set the root directory}"
    : "${LSTS_LANG_ID:?language Id not set. use lsts_set_langId to set the language Id}"

    cd "$LSTS_ROOT" || return 1

    _LSTS_ID=0
    coproc LSTS { ${LSTS_CMD}; }
    LSTS_READ_FD=${LSTS[0]}
    LSTS_WRITE_FD=${LSTS[1]}
}

lsts_stop() {
    lsts_notify "exit" "{}" 2>/dev/null || true
    kill "${LSTS_PID:-}" 2>/dev/null || true
    wait "${LSTS_PID:-}" 2>/dev/null || true
}

lsts_initialize() {
    local root_uri root_path

    if [[ -n "${LSTS_ROOT:-}" ]]; then
        if [[ "$LSTS_ROOT" == file://* ]]; then
            root_uri="\"${LSTS_ROOT}\""
            root_path="\"${LSTS_ROOT#file://}\""
        else
            root_uri="\"file://${LSTS_ROOT}\""
            root_path="\"${LSTS_ROOT}\""
        fi
    else
        root_uri="null"
        root_path="null"
    fi

    lsts_request "initialize" \
        "{\"processId\":null,\"rootUri\":${root_uri},\"rootPath\":${root_path},\"capabilities\":{}}"
    lsts_recv_response

    # Fail fast if the server returned a JSON-RPC error
    local err
    err="$(printf '%s' "$LSTS_RESPONSE" | jq -r '.error')"
    [[ "$err" == "null" ]] || {
        echo "lsts_initialize: server returned error: $err" >&2
        return 1
    }

    lsts_notify "initialized" "{}"
}

lsts_hover() {
    local path="$1" line="$2" character="$3" expected="$4"

    local uri="file://$LSTS_ROOT/$path"
    text="$(jq -Rs . <"$LSTS_ROOT/$path")"

    lsts_initialize

    lsts_notify "textDocument/didOpen" \
        "{\"textDocument\":{\"uri\":\"${uri}\",\"languageId\":\"${LSTS_LANG_ID}\",\"version\":1,\"text\":${text}}}"

    lsts_request "textDocument/hover" \
        "{\"textDocument\":{\"uri\":\"${uri}\"},\"position\":{\"line\":${line},\"character\":${character}}}"
    lsts_recv_response

    if [[ $# == 3 ]]; then
        printf "\e[01;33mWARNING: snapshot mode\e[0m\n" >&3
        echo "$LSTS_RESPONSE"
        return
    fi

    diff <(echo "$LSTS_RESPONSE") "$expected"
}
