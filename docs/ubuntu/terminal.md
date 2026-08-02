# ターミナル環境のセットアップ（starship + Nerd Font）

bashのプロンプトを[starship](https://starship.rs/)に置き換え、ワークスペース（カレントディレクトリ）〜時刻の部分をPowerline風の青系矢印セグメントで表示する環境を構築する。手順はUbuntu（GNOME Terminal）を前提とする。

完成形のイメージは以下の通り（`▶`の部分は実際にはPowerlineの矢印グリフで、セグメント同士が矢印でつながって描画される）。

```
 ~/cpp_pructice ▶▶▶ 23:21:30 ▶ on  main [!+?]
❯
```

- ディレクトリ部分: 濃紺（`#1c4961`）背景
- 中間: `#2f79a1` → `#3a95c7` と明るくなる矢印グラデーション
- 時刻部分: 明るい青（`#40a9e0`）背景、右端は矢印の先端で終わる
- その後にGitブランチ・状態、Python/venv情報（該当時のみ）

---

## 1. starshipのインストール

公式サイト: https://starship.rs/

公式のインストールスクリプトで`~/.local/bin`にインストールする（`~/.local/bin`はUbuntuでは`~/.profile`により標準でPATHに含まれる）。

```bash
mkdir -p ~/.local/bin
curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
```

インストールを確認する。

```bash
starship --version
# starship 1.26.0 など
```

---

## 2. bashrcへの組み込み

`~/.bashrc`の**末尾**に以下を追記する（プロンプトは最後に評価された設定が勝つため、既存の`PS1`設定より後ろに置く）。

```bash
# starship prompt (設定: ~/.config/starship.toml)
eval "$(starship init bash)"
```

自作の`export PS1=...`が残っている場合は、混乱を避けるためコメントアウトしておく。追記後、設定を反映する。

```bash
source ~/.bashrc
```

---

## 3. Nerd Fontのインストール

Powerlineの矢印グリフ（`` U+E0B0 / `` U+E0B2）は通常のフォントに含まれないため、これらを収録した[Nerd Fonts](https://www.nerdfonts.com/font-downloads)を導入する。ここではUbuntu標準の見た目に近い**UbuntuSansMono Nerd Font**を使う。

```bash
cd /tmp
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuSans.zip
mkdir -p ~/.local/share/fonts/UbuntuSansMono
unzip -o UbuntuSans.zip 'UbuntuSansMono*' -d ~/.local/share/fonts/UbuntuSansMono
fc-cache -f
```

`UbuntuSans.zip`にはプロポーショナル版（UbuntuSans）とモノスペース版（UbuntuSansMono）の両方が含まれるため、モノスペース版のみ展開している。インストールを確認する。

```bash
fc-list | grep "UbuntuSansMono Nerd Font Mono"
```

---

## 4. starshipの設定

`~/.config/starship.toml`を以下の内容で作成する。

```toml
# 必要最小限の構成: ディレクトリ + 時刻 + Git + Python/venv のみ
# ここに列挙したモジュール以外は一切表示されない
# ディレクトリ〜時刻は Powerline 風の青系矢印セグメント (要 Nerd Font / Powerline 対応フォント)
format = """
[](fg:#1c4961)\
$directory\
[](fg:#1c4961 bg:#2f79a1)\
[](fg:#2f79a1 bg:#3a95c7)\
[](fg:#3a95c7 bg:#40a9e0)\
$time\
[](fg:#40a9e0) \
$git_branch\
$git_status\
$python\
$line_break\
$character"""

# プロンプト間の空行を入れない
add_newline = false

[directory]
truncation_length = 4
truncate_to_repo = false
style = "bold fg:#eee8d5 bg:#1c4961"
format = "[ $path$read_only ]($style)"

[time]
disabled = false
time_format = "%T"
style = "bold fg:#eee8d5 bg:#40a9e0"
format = "[ $time ]($style)"

# git_branch / git_status / character はデフォルト設定のまま:
#   on  main [!+?]   記号のみで個数は出ない
#   (! 未ステージ変更 / + ステージ済 / ? 未追跡 / $ stash / ✘ 削除 / » リネーム
#    = コンフリクト / ⇡ リモートより先行 / ⇣ 遅れ / ⇕ 分岐)
#   ❯ は成功時に緑、失敗時に赤

[python]
# venv有効時 or Pythonプロジェクト内でのみ表示される
format = 'via [${symbol}(${version} )(\($virtualenv\) )]($style)'
```

### 4.1 注意: 矢印グリフの欠落チェック

`format`内の矢印（`` / ``）はUnicode私用領域の文字のため、エディタやクリップボード経由のコピーで**見た目を保ったまま欠落する**ことがある（ブラウザ上で`□`に見えても、コピーすれば文字自体は貼り付けられる）。欠落すると矢印が描画されず、セグメントがただの四角い背景色になる。作成後に以下で確認する。

```bash
grep -c $'' ~/.config/starship.toml   # → 4 (右向き矢印)
grep -c $'' ~/.config/starship.toml   # → 1 (左端キャップ)
```

カウントが足りない場合は、以下を実行すると空になった`[]`グループへ矢印を再挿入できる。

```bash
python3 - <<'EOF'
import io
p = __import__('os').path.expanduser('~/.config/starship.toml')
s = io.open(p, encoding='utf-8').read()
s = s.replace('[](fg:#1c4961)\\', '[](fg:#1c4961)\\')
s = s.replace('[](fg:#1c4961 bg:#2f79a1)', '[](fg:#1c4961 bg:#2f79a1)')
s = s.replace('[](fg:#2f79a1 bg:#3a95c7)', '[](fg:#2f79a1 bg:#3a95c7)')
s = s.replace('[](fg:#3a95c7 bg:#40a9e0)', '[](fg:#3a95c7 bg:#40a9e0)')
s = s.replace('[](fg:#40a9e0) ', '[](fg:#40a9e0) ')
io.open(p, 'w', encoding='utf-8').write(s)
EOF
```

### 4.2 表示の見方

- ディレクトリ: ホームは`~`、リポジトリ外でも省略せずフルパス表示（深さ4まで）
- 時刻: `23:21:30`形式（`%T` = `%H:%M:%S`）
- `on  main`（紫）: 現在のGitブランチ。リポジトリ内でのみ表示
- `[!+?]`（赤）: 作業ツリーの状態。記号のみで個数は表示されない
    - `!` 未ステージの変更 / `+` ステージ済み / `?` 未追跡ファイル
    - `$` stashあり / `✘` 削除 / `»` リネーム / `=` コンフリクト
    - `⇡` リモートより先行 / `⇣` 遅れ / `⇕` 分岐
- `via 🐍 v3.12.3 (venv)`: venv有効時またはPythonプロジェクト内でのみ表示
- `❯`: 直前のコマンドが成功なら緑、失敗なら赤

個数も表示したい場合は`[git_status]`セクションで`modified = '!${count}'`のように設定する。

---

## 5. GNOME Terminalのフォント設定

GNOME Terminalの既定は「システムの等幅フォント（`Monospace`）」で、日本語環境ではこれが**Noto Sans Mono CJK JP**に解決される。このフォントは矢印グリフを持たないため別フォントからフォールバック描画され、セルの寸法が合わずに**矢印の周囲へ背景色が四角くはみ出して見える**。これを避けるため、プロファイルのフォントをNerd Fontに固定する。

```bash
PROFILE=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
P="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE/"
gsettings set "$P" use-system-font false
gsettings set "$P" font 'UbuntuSansMono Nerd Font Mono 12'
```

GUIから設定する場合は、GNOME Terminalの「設定 → プロファイル → テキスト」で「システムの等幅フォントを使用」のチェックを外し、「UbuntuSansMono Nerd Font Mono 12」を指定する（設定は開いているターミナルにも即座に反映される）。

日本語テキストは従来どおりNoto CJKへフォールバックされるため、表示への影響はほぼない。元に戻す場合は`use-system-font`を`true`に戻すだけでよい。

---

## 6. 動作確認

新しいターミナルを開く（または`source ~/.bashrc`を実行する）。

- ディレクトリ〜時刻が矢印セグメントで表示され、矢印の上下に四角い背景色が残っていないこと
- Gitリポジトリに`cd`すると`on  ブランチ名`が表示されること
- ファイルを変更・追加すると`[!?]`のような状態記号が表示されること

プロンプトの出力自体は以下でも確認できる（右向き矢印が4個含まれていれば正常）。

```bash
starship prompt | grep -o $'' | wc -l   # → 4
```
