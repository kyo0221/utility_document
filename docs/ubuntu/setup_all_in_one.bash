#!/usr/bin/env bash
#
# Ubuntu 24.04 (x86_64 / amd64) 環境セットアップ 統合スクリプト
#
# docs/ubuntu/setup.md に記載されている手順（1〜8）をひとつにまとめたものです。
# 実行するだけで、一般的なセットアップの大部分が完了するように設計しています。
# Gitのユーザー名やPersonal Access Tokenなど個別の情報が必要な項目は、
# 実行中に日本語で対話形式で質問します。
#
# 使い方:
#   bash setup_all_in_one.bash
#
set -uo pipefail

# ============================================================
# 表示・入力用の共通ヘルパー
# ============================================================

C_RESET='\033[0m'
C_INFO='\033[1;34m'
C_OK='\033[1;32m'
C_WARN='\033[1;33m'
C_ERR='\033[1;31m'
C_STEP='\033[1;36m'

log_step() { printf "\n${C_STEP}==> %s${C_RESET}\n" "$1"; }
log_info() { printf "${C_INFO}[INFO]${C_RESET} %s\n" "$1"; }
log_ok()   { printf "${C_OK}[ OK ]${C_RESET} %s\n" "$1"; }
log_warn() { printf "${C_WARN}[WARN]${C_RESET} %s\n" "$1"; }
log_err()  { printf "${C_ERR}[ERR ]${C_RESET} %s\n" "$1" >&2; }

# 標準入力がリダイレクトされていても対話できるよう、常に /dev/tty から読む。
ask_yes_no() {
    local prompt="$1" default="${2:-y}" suffix ans
    suffix="[Y/n]"
    [[ "$default" == "n" ]] && suffix="[y/N]"
    while true; do
        read -r -p "$prompt $suffix: " ans </dev/tty
        ans="${ans:-$default}"
        case "$ans" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "  y または n で入力してください。" ;;
        esac
    done
}

ask_value() {
    local prompt="$1" default="${2:-}" ans
    if [[ -n "$default" ]]; then
        read -r -p "$prompt [$default]: " ans </dev/tty
        echo "${ans:-$default}"
    else
        while true; do
            read -r -p "$prompt: " ans </dev/tty
            [[ -n "$ans" ]] && break
            echo "  空欄にはできません。"
        done
        echo "$ans"
    fi
}

ask_secret() {
    local prompt="$1" ans
    read -r -s -p "$prompt: " ans </dev/tty
    echo >&2
    echo "$ans"
}

require_cmd() { command -v "$1" >/dev/null 2>&1; }

# ============================================================
# 事前チェック・共通処理
# ============================================================

preflight() {
    log_step "事前チェック"

    if [[ $EUID -eq 0 ]]; then
        log_err "このスクリプトはrootユーザーで実行しないでください（sudoは必要な箇所で自動的に呼び出します）。"
        exit 1
    fi

    if require_cmd lsb_release; then
        local codename
        codename="$(lsb_release -cs 2>/dev/null || true)"
        if [[ "$codename" != "noble" ]]; then
            log_warn "Ubuntu 24.04 (noble) 以外の環境を検出しました（検出値: ${codename:-不明}）。想定外の動作になる可能性があります。"
        fi
    fi

    ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"
    log_info "検出したアーキテクチャ: ${ARCH}"

    log_info "sudoの認証情報を確認します。パスワードの入力を求められることがあります。"
    if ! sudo -v; then
        log_err "sudo権限が確認できませんでした。処理を中断します。"
        exit 1
    fi
    # スクリプト実行中はsudoの認証をバックグラウンドで維持し、毎回のパスワード再入力を防ぐ。
    ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT

    log_info "パッケージ一覧を更新します（sudo apt update）。"
    sudo apt update
}

# ============================================================
# 1. ホームディレクトリ名を英語表記に変換する
# ============================================================

step_rename_home_dirs() {
    log_step "1. ホームディレクトリ名を英語表記に変換する"

    if ! ask_yes_no "~/デスクトップ 等のディレクトリ名を英語表記（Desktop等）に変換しますか？" y; then
        log_info "スキップしました。"
        return
    fi

    if [[ -n "${DISPLAY:-}" ]] && require_cmd xdg-user-dirs-gtk-update; then
        log_info "ダイアログが表示された場合は「Update Names」を選択してください。"
        LANG=C xdg-user-dirs-gtk-update || log_warn "xdg-user-dirs-gtk-updateに失敗しました。"
    elif require_cmd xdg-user-dirs-update; then
        LANG=C xdg-user-dirs-update --force
    else
        log_warn "xdg-user-dirs-updateコマンドが見つかりません。スキップします。"
        return
    fi
    log_ok "ホームディレクトリ名を変換しました。"
}

# ============================================================
# 2. Google Chromeのインストール
# ============================================================

step_install_chrome() {
    log_step "2. Google Chromeのインストール"

    if ! ask_yes_no "Google Chromeをインストールしますか？" y; then
        log_info "スキップしました。"
        return
    fi

    if [[ "$ARCH" != "amd64" ]]; then
        log_warn "Google Chromeの.debはamd64専用のため、検出アーキテクチャ（${ARCH}）ではスキップします。"
        return
    fi

    if (
        set -e
        tmp_deb="$(mktemp -u /tmp/google-chrome-stable_current_amd64.XXXXXX.deb)"
        wget -q -O "$tmp_deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo apt install -y "$tmp_deb"
        rm -f "$tmp_deb"
    ); then
        log_ok "Google Chromeをインストールしました。"
    else
        log_warn "Google Chromeのインストールに失敗しました。"
    fi
}

# ============================================================
# 3. Slackのインストール
# ============================================================

step_install_slack() {
    log_step "3. Slackのインストール"

    if ! ask_yes_no "Slackをインストールしますか？" y; then
        log_info "スキップしました。"
        return
    fi

    local downloads_dir="${HOME}/Downloads"
    local deb_file=""
    if [[ -d "$downloads_dir" ]]; then
        deb_file="$(find "$downloads_dir" -maxdepth 1 -name 'slack-desktop-*.deb' 2>/dev/null | sort -V | tail -n1)"
    fi

    if [[ -z "$deb_file" ]]; then
        log_warn "Slackの.debファイルがSlack公式サイトからの自動ダウンロードに対応していないため、事前に手動ダウンロードが必要です。"
        log_info "以下のURLから「Ubuntu/Debian用の.debファイル」をダウンロードし、${downloads_dir} に保存してください:"
        log_info "  https://slack.com/intl/ja-jp/downloads/linux"
        if ask_yes_no "ダウンロードが完了しましたので、続けて確認しますか？" n; then
            deb_file="$(find "$downloads_dir" -maxdepth 1 -name 'slack-desktop-*.deb' 2>/dev/null | sort -V | tail -n1)"
        fi
    fi

    if [[ -z "$deb_file" ]]; then
        log_warn "Slackの.debファイルが見つからなかったため、インストールをスキップしました。"
        log_info "後で手動インストールする場合: sudo apt install ./slack-desktop-*.deb"
        return
    fi

    if sudo apt install -y "$deb_file"; then
        log_ok "Slackをインストールしました（${deb_file}）。"
    else
        log_warn "Slackのインストールに失敗しました。"
    fi
}

# ============================================================
# 4. Visual Studio Codeのインストール
# ============================================================

step_install_vscode() {
    log_step "4. Visual Studio Codeのインストール"

    if ! ask_yes_no "Visual Studio Codeをインストールしますか？" y; then
        log_info "スキップしました。"
        return
    fi

    if (
        set -e
        sudo apt install -y wget gpg apt-transport-https

        tmp_gpg="$(mktemp)"
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$tmp_gpg"
        sudo install -D -o root -g root -m 644 "$tmp_gpg" /etc/apt/keyrings/packages.microsoft.gpg
        rm -f "$tmp_gpg"

        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

        sudo apt update
        sudo apt install -y code
    ); then
        log_ok "Visual Studio Codeをインストールしました。"
    else
        log_warn "Visual Studio Codeのインストールに失敗しました。"
    fi
}

# ============================================================
# 5. ROS 2 Jazzyのインストール
# ============================================================

step_install_ros2() {
    log_step "5. ROS 2 Jazzyのインストール"

    if ! ask_yes_no "ROS 2 Jazzyをインストールしますか？（ダウンロード容量が大きいです）" y; then
        log_info "スキップしました。"
        return
    fi

    log_info "5.1 ロケールの設定"
    if (
        set -e
        sudo apt install -y locales
        sudo locale-gen en_US en_US.UTF-8
        sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    ); then
        log_ok "ロケールを設定しました。"
    else
        log_warn "ロケールの設定に失敗しました。処理を続行します。"
    fi

    log_info "5.2 Ubuntu Universeリポジトリの有効化"
    if (
        set -e
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y universe
    ); then
        log_ok "Universeリポジトリを有効化しました。"
    else
        log_warn "Universeリポジトリの有効化に失敗しました。処理を続行します。"
    fi

    log_info "5.3 ROS 2 APTリポジトリの追加"
    if (
        set -e
        sudo apt update
        sudo apt install -y curl
        ROS_APT_SOURCE_VERSION="$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')"
        [[ -n "$ROS_APT_SOURCE_VERSION" ]]
        tmp_deb="$(mktemp -u /tmp/ros2-apt-source.XXXXXX.deb)"
        curl -fL -o "$tmp_deb" "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo "$VERSION_CODENAME")_all.deb"
        sudo apt install -y "$tmp_deb"
        rm -f "$tmp_deb"
    ); then
        log_ok "ROS 2 APTリポジトリを追加しました。"
    else
        log_warn "ROS 2 APTリポジトリの追加に失敗しました。ROS 2のインストールを中止します。"
        return
    fi

    log_info "5.4 パッケージのインストール"
    echo "  1) デスクトップ版（ros-jazzy-desktop / RViz・デモ・チュートリアル等を含む。基本はこちらでOK）"
    echo "  2) 最小構成（ros-jazzy-ros-base）"
    local variant
    variant="$(ask_value "インストールするパッケージ構成の番号を入力してください" "1")"
    local ros_pkg="ros-jazzy-desktop"
    [[ "$variant" == "2" ]] && ros_pkg="ros-jazzy-ros-base"

    local dev_tools=0
    if ask_yes_no "colcon等の開発ツール（ros-dev-tools）もインストールしますか？" y; then
        dev_tools=1
    fi

    if (
        set -e
        sudo apt update
        sudo apt upgrade -y
        sudo apt install -y "$ros_pkg"
        if [[ $dev_tools -eq 1 ]]; then
            sudo apt install -y ros-dev-tools
        fi
    ); then
        log_ok "ROS 2 Jazzy（${ros_pkg}）をインストールしました。"
    else
        log_warn "ROS 2パッケージのインストールに失敗しました。"
        return
    fi

    log_info "5.5 環境設定"
    local marker="# >>> ROS 2 Jazzy setup >>>"
    if grep -qF "$marker" "${HOME}/.bashrc" 2>/dev/null; then
        log_info "~/.bashrcには既にROS 2の設定が追加されています。スキップします。"
    else
        {
            echo ""
            echo "$marker"
            echo "source /opt/ros/jazzy/setup.bash"
            echo "# <<< ROS 2 Jazzy setup <<<"
        } >> "${HOME}/.bashrc"
        log_ok "~/.bashrcにROS 2の環境設定を追加しました。"
    fi

    log_info "5.6 動作確認について"
    log_info "  以下をターミナルを2つ開いて実行すると、送受信の動作確認ができます（このスクリプトでは自動実行しません）。"
    log_info "    ターミナル1: source /opt/ros/jazzy/setup.bash && ros2 run demo_nodes_cpp talker"
    log_info "    ターミナル2: source /opt/ros/jazzy/setup.bash && ros2 run demo_nodes_py listener"
}

# ============================================================
# 6. Gitのインストールとコミットメッセージテンプレート
# ============================================================

step_setup_git() {
    log_step "6. Gitのインストールとコミットメッセージテンプレート"

    log_info "6.1 インストール"
    if (
        set -e
        sudo apt install -y git vim
    ); then
        log_ok "gitとvimをインストールしました。"
    else
        log_warn "gitのインストールに失敗しました。以降のGit設定はスキップします。"
        return
    fi

    if ask_yes_no "Gitのユーザー名・メールアドレスを設定しますか？" y; then
        local current_name current_email git_name git_email
        current_name="$(git config --global user.name 2>/dev/null || true)"
        current_email="$(git config --global user.email 2>/dev/null || true)"
        git_name="$(ask_value "Gitのユーザー名を入力してください" "$current_name")"
        git_email="$(ask_value "Gitのメールアドレスを入力してください" "$current_email")"
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        log_ok "Gitのユーザー名・メールアドレスを設定しました（${git_name} <${git_email}>）。"
    else
        log_info "スキップしました。"
    fi

    log_info "6.2 認証情報の保存"
    if ask_yes_no "HTTPS経由でのpush/pull時に認証情報をディスクに保存しますか？（credential.helper store）" y; then
        git config --global credential.helper store
        log_ok "credential.helper storeを設定しました。"
        log_warn "認証情報は ~/.git-credentials に平文で保存されます。共有PCでは注意してください。"

        if ask_yes_no "GitHubのユーザー名とPersonal Access Tokenを今すぐ登録しますか？（初回pushでの入力を省略できます）" n; then
            local gh_user gh_token cred_file cred_line
            gh_user="$(ask_value "GitHubのユーザー名を入力してください")"
            gh_token="$(ask_secret "Personal Access Token を入力してください（画面には表示されません）")"
            cred_file="${HOME}/.git-credentials"
            cred_line="https://${gh_user}:${gh_token}@github.com"
            touch "$cred_file"
            chmod 600 "$cred_file"
            if grep -qF "@github.com" "$cred_file" 2>/dev/null; then
                log_warn "~/.git-credentials に既存のgithub.com向け認証情報があるため、追加登録はスキップしました。"
            else
                echo "$cred_line" >> "$cred_file"
                log_ok "GitHub向けの認証情報を ~/.git-credentials に登録しました。"
            fi
            unset gh_token cred_line
        fi
    else
        log_info "スキップしました。"
    fi

    log_info "6.3 デフォルトエディタの設定"
    if ask_yes_no "gitのデフォルトエディタをvimに設定しますか？" y; then
        git config --global core.editor "vim"
        log_ok "core.editorをvimに設定しました。"
    else
        log_info "スキップしました。"
    fi

    log_info "6.4 commitメッセージのテンプレート作成"
    if ask_yes_no "コミットメッセージのテンプレート（~/.gitmessage.txt）を作成しますか？" y; then
        local template_file="${HOME}/.gitmessage.txt"
        if [[ -f "$template_file" ]]; then
            cp "$template_file" "${template_file}.bak"
            log_info "既存の ${template_file} を ${template_file}.bak にバックアップしました。"
        fi
        cat > "$template_file" <<'EOF'
#🐛fix: バグ修正
#🔧modify: 機能改善
#♻ refactor: リファクタリング
#📝docs: ドキュメント変更
#🎨style: フォーマットや構造改善
#🔥remove:　不要な機能・ファイルの削除
#✨feat: 部分的な機能追加
#🍰chore: 自動生成されたファイル
#🌱init commit: 初期コミット
#🧪test: テストやCIの修正・改善
#👕lint: Lintエラーの修正やコードスタイルの修正
#🚀️perf: パフォーマンス改善
#🆙update: 依存パッケージなどのアップデート
#🚧wip: 作業中
EOF
        git config --global commit.template "$template_file"
        log_ok "commitメッセージテンプレートを作成し、登録しました。"
    else
        log_info "スキップしました。"
    fi
}

# ============================================================
# 7. bashrcにgitブランチ表示機能を追加
# ============================================================

step_bashrc_git_prompt() {
    log_step "7. bashrcにgitブランチ表示機能を追加"

    if ! ask_yes_no "プロンプトに現在のgitブランチ名を表示する設定を追加しますか？" y; then
        log_info "スキップしました。"
        return
    fi

    local marker="# >>> git branch prompt >>>"
    if grep -qF "$marker" "${HOME}/.bashrc" 2>/dev/null; then
        log_info "~/.bashrcには既にこの設定が追加されています。スキップします。"
        return
    fi

    if ! curl -fsSL -o "${HOME}/.git-prompt.sh" https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh; then
        log_warn "git-prompt.shの取得に失敗しました。この項目をスキップします。"
        return
    fi

    {
        echo ""
        echo "$marker"
        echo 'source ~/.git-prompt.sh'
        echo ""
        echo 'export PS1='"'"'\[\033[01;32m\]\u@\h\[\033[01;33m\] \w \[\033[01;31m\]$(__git_ps1 "(%s)") \n\[\033[01;34m\]\$\[\033[00m\] '"'"
        echo "# <<< git branch prompt <<<"
    } >> "${HOME}/.bashrc"

    log_ok "~/.bashrcにgitブランチ表示の設定を追加しました。"
}

# ============================================================
# 8. Tilixのインストールと既定のターミナル設定
# ============================================================

step_install_tilix() {
    log_step "8. Tilixのインストールと既定のターミナル設定"

    if ! ask_yes_no "ターミナルエミュレータTilixをインストールしますか？" y; then
        log_info "スキップしました。"
        return
    fi

    if sudo apt install -y tilix; then
        log_ok "Tilixをインストールしました。"
    else
        log_warn "Tilixのインストールに失敗しました。この項目をスキップします。"
        return
    fi

    if ask_yes_no "Tilixを既定のターミナルに設定しますか？" y; then
        # x-terminal-emulator の登録パスはパッケージ側の都合で変わり得るため、候補一覧から取得する。
        local tilix_alt
        tilix_alt="$(update-alternatives --list x-terminal-emulator 2>/dev/null | grep -i tilix | head -n1)"
        if [[ -n "$tilix_alt" ]]; then
            if sudo update-alternatives --set x-terminal-emulator "$tilix_alt"; then
                log_ok "x-terminal-emulatorをTilixに設定しました（${tilix_alt}）。"
            else
                log_warn "update-alternativesでの既定ターミナル設定に失敗しました。"
            fi
        else
            log_warn "x-terminal-emulatorの候補にTilixが見つかりませんでした。設定をスキップします。"
        fi

        # GNOMEのCtrl+Alt+Tショートカットで起動するターミナルもTilixにする。
        if require_cmd gsettings; then
            if gsettings set org.gnome.desktop.default-applications.terminal exec tilix 2>/dev/null; then
                log_ok "GNOMEの既定ターミナル（Ctrl+Alt+T）をTilixに設定しました。"
            else
                log_warn "gsettingsでの設定に失敗しました（GNOME以外のデスクトップ環境では不要です）。"
            fi
        fi
    else
        log_info "既定のターミナル設定はスキップしました。"
    fi

    # キーボードショートカットのカスタム設定（tilix_keybindings.bash を呼び出す）
    if ask_yes_no "Tilixのキーボードショートカットをカスタム設定（分割: Ctrl+Shift+E / Ctrl+Shift+O、セッション切替: Ctrl+N / Ctrl+U 等）に変更しますか？" y; then
        local kb_script
        kb_script="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/tilix_keybindings.bash"
        if [[ -f "$kb_script" ]]; then
            bash "$kb_script" || log_warn "キーボードショートカットの設定に失敗しました。"
        else
            log_info "同じディレクトリに tilix_keybindings.bash が見つからないため、公開サイトから取得します。"
            local tmp_kb
            tmp_kb="$(mktemp -u /tmp/tilix_keybindings.XXXXXX.bash)"
            if curl -fsSL -o "$tmp_kb" "https://kyo0221.github.io/utility_document/ubuntu/tilix_keybindings.bash"; then
                bash "$tmp_kb" || log_warn "キーボードショートカットの設定に失敗しました。"
                rm -f "$tmp_kb"
            else
                log_warn "tilix_keybindings.bash の取得に失敗しました。スキップします。"
            fi
        fi
    else
        log_info "キーボードショートカットの変更はスキップしました。"
    fi
}

# ============================================================
# メイン処理
# ============================================================

main() {
    echo "============================================================"
    echo " Ubuntu 24.04 (x86_64 / amd64) セットアップ 統合スクリプト"
    echo "============================================================"
    echo "各項目は Enter キーのみで既定の動作（多くは「実行する」）になります。"
    echo "不要な項目は n と入力してスキップしてください。"

    preflight

    step_rename_home_dirs
    step_install_chrome
    step_install_slack
    step_install_vscode
    step_install_ros2
    step_setup_git
    step_bashrc_git_prompt
    step_install_tilix

    echo
    echo "============================================================"
    log_ok "セットアップ処理が完了しました。"
    log_info "変更を反映するには、ターミナルを再起動するか、次を実行してください:"
    log_info "  source ~/.bashrc"
    echo "============================================================"
}

main "$@"
