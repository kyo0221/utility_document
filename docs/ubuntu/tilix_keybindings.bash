#!/usr/bin/env bash
#
# Tilix キーボードショートカット設定スクリプト
#
# Tilixのデフォルトのキーボードショートカットを、以下のカスタム設定に
# 変更します（docs/ubuntu/setup.md の8.3参照）。
#
#   操作                        デフォルト               変更後
#   ターミナルを右に分割        Ctrl+Alt+R            -> Ctrl+Shift+E
#   ターミナルを下に分割        Ctrl+Alt+D            -> Ctrl+Shift+O
#   セッションを開く            Ctrl+Shift+O          -> 無効化（下分割と衝突するため）
#   次のセッションへ切替        Ctrl+PageDown         -> Ctrl+N
#   前のセッションへ切替        Ctrl+PageUp           -> Ctrl+U
#   セッションを次へ並べ替え    Ctrl+Shift+PageDown   -> 無効化
#   セッションを前へ並べ替え    Ctrl+Shift+PageUp     -> 無効化
#
# 設定はdconf（/com/gexperts/Tilix/keybindings/）に書き込まれ、起動中の
# Tilixにも即座に反映されます。デフォルトに戻す場合は以下を実行してください。
#
#   dconf reset -f /com/gexperts/Tilix/keybindings/
#
# 使い方:
#   bash tilix_keybindings.bash
#
set -uo pipefail

SCHEMA="com.gexperts.Tilix.Keybindings"

if ! command -v gsettings >/dev/null 2>&1; then
    echo "[ERR ] gsettingsコマンドが見つかりません。" >&2
    exit 1
fi

if ! gsettings list-schemas 2>/dev/null | grep -qx "$SCHEMA"; then
    echo "[ERR ] Tilixの設定スキーマ（${SCHEMA}）が見つかりません。先にTilixをインストールしてください。" >&2
    exit 1
fi

failed=0

apply() {
    local key="$1" value="$2" desc="$3"
    if gsettings set "$SCHEMA" "$key" "$value" 2>/dev/null; then
        printf "[ OK ] %-30s %-22s (%s)\n" "$key" "$value" "$desc"
    else
        echo "[WARN] ${key} の設定に失敗しました。" >&2
        failed=1
    fi
}

apply session-add-right               '<Primary><Shift>e' "ターミナルを右に分割"
apply session-add-down                '<Primary><Shift>o' "ターミナルを下に分割"
apply session-open                    'disabled'          "セッションを開く（無効化）"
apply win-switch-to-next-session      '<Primary>n'        "次のセッションへ切替"
apply win-switch-to-previous-session  '<Primary>u'        "前のセッションへ切替"
apply win-reorder-next-session        'disabled'          "セッションを次へ並べ替え（無効化）"
apply win-reorder-previous-session    'disabled'          "セッションを前へ並べ替え（無効化）"

if [[ $failed -eq 0 ]]; then
    echo "Tilixのキーボードショートカットを変更しました。"
else
    echo "一部の設定に失敗しました。Tilixのバージョンによりキー名が異なる可能性があります。" >&2
    exit 1
fi
