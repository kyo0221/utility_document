# Ubuntu 24.04 セットアップ手順

## 1. ホームディレクトリ名を英語表記に変換する

日本語ロケールでUbuntuをインストールすると、`~/デスクトップ` `~/ダウンロード` `~/ドキュメント` のように日本語のディレクトリ名で作成される。これらを英語表記（`Desktop` `Downloads` `Documents` など）に変換する。

```bash
LANG=C xdg-user-dirs-gtk-update
```

実行するとダイアログが表示されるので「Update Names」を選択すると、ディレクトリ名が英語に変換される（中身のファイルも自動的に新しいディレクトリへ移動される）。

GUI環境がない場合やダイアログが出ない場合は、以下のコマンドで直接更新できる。

```bash
LANG=C xdg-user-dirs-update --force
```

---

## 2. Google Chromeのインストール

公式サイト: https://www.google.com/chrome/

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install ./google-chrome-stable_current_amd64.deb
```

`apt install`経由で`.deb`をインストールすることで、依存関係も含めて自動的に解決される。

---

## 3. Slackのインストール

公式サイト: https://slack.com/intl/ja-jp/downloads/linux

上記ページを開き「Ubuntu/Debian用の.debファイルをダウンロードする」から`.deb`パッケージをダウンロードする（ブラウザ経由でダウンロードするため、既定では`~/Downloads`に保存される）。

```bash
cd ~/Downloads
sudo apt install ./slack-desktop-*.deb
```

`apt install`経由で`.deb`をインストールすることで、依存関係も含めて自動的に解決される。

---

## 4. Visual Studio Codeのインストール

公式サイト: https://code.visualstudio.com/download

公式ドキュメント（Debian/Ubuntu向け）に従い、APTリポジトリを登録した上でインストールする。この方法であれば`sudo apt update && sudo apt upgrade`で以降のアップデートも自動的に反映される。

```bash
sudo apt update
sudo apt install wget gpg

wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

sudo apt install apt-transport-https
sudo apt update
sudo apt install code
```

---

## 5. ROS 2 Jazzyのインストール

公式ドキュメント: https://docs.ros.org/en/jazzy/Installation/Ubuntu-Install-Debs.html

### 5.1 ロケールの設定

UTF-8ロケールが設定されていることを確認する。

```bash
locale

sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

locale
```

### 5.2 Ubuntu Universeリポジトリの有効化

```bash
sudo apt install software-properties-common
sudo add-apt-repository universe
```

### 5.3 ROS 2 APTリポジトリの追加

```bash
sudo apt update && sudo apt install curl -y

export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
sudo apt install /tmp/ros2-apt-source.deb
```

### 5.4 パッケージのインストール

```bash
sudo apt update
sudo apt upgrade

# デスクトップ版（RViz、デモ、チュートリアル等を含む。基本はこちらでOK）
sudo apt install ros-jazzy-desktop

# 最小構成にしたい場合
# sudo apt install ros-jazzy-ros-base

# colcon等の開発ツールが必要な場合
sudo apt install ros-dev-tools
```

### 5.5 環境設定

```bash
source /opt/ros/jazzy/setup.bash

# 毎回sourceするのが手間な場合は.bashrcに追記しておく
echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
```

### 5.6 動作確認

ターミナルを2つ開き、それぞれで以下を実行する。

```bash
# ターミナル1
source /opt/ros/jazzy/setup.bash
ros2 run demo_nodes_cpp talker
```

```bash
# ターミナル2
source /opt/ros/jazzy/setup.bash
ros2 run demo_nodes_py listener
```

talker側の出力（`Publishing: 'Hello World: N'`等）がlistener側でも受信できていれば、インストールは正常に完了している。

---

## 6. Gitのインストールとコミットメッセージテンプレート

公式: https://git-scm.com/downloads/linux

### 6.1 インストール

```bash
sudo apt update
sudo apt install git
```

インストール後、必要に応じてユーザー情報を設定する。

```bash
git config --global user.name "ユーザー名"
git config --global user.email "メールアドレス"
```

### 6.2 認証情報の保存

HTTPS経由でリモートリポジトリ（GitHub等）にpush/pullするたびにユーザー名・パスワード（またはPersonal Access Token）の入力を求められるのを避けるため、認証情報をディスクに保存しておく。

```bash
git config --global credential.helper store
```

設定後、最初の1回だけ認証情報の入力を求められ、以降は`~/.git-credentials`に平文で保存された内容が自動的に使用される。共有PCなど他ユーザーがアクセスできる環境では、平文保存になる点に注意する。

### 6.3 デフォルトエディタの設定

`git commit`やコンフリクト解消などでエディタが起動する際に使われるデフォルトエディタをvimに設定する。

```bash
sudo apt install vim
git config --global core.editor "vim"
```

### 6.4 commitメッセージのテンプレート作成

Gitでコミット時に使いたいデフォルトメッセージを`~/.gitmessage.txt`に記述する。

```
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
```

作成した`~/.gitmessage.txt`をテンプレートとして登録する。

```bash
git config --global commit.template ~/.gitmessage.txt
```

これ以降、`git commit`実行時にエディタが開くとテンプレートの内容がデフォルトメッセージとして表示され、該当する行のコメントを外して使うことができる。

```bash
git commit
```

---

## 7. bashrcにgitブランチ表示機能を追加

現在のブランチ名をプロンプトに表示できるよう、`__git_ps1`を利用する。まず、Gitの公式リポジトリが提供する`git-prompt.sh`を取得する。

```bash
curl -o ~/.git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
```

`~/.bashrc`の末尾に以下を追記する。

```bash
source ~/.git-prompt.sh

export PS1='\[\033[01;32m\]\u@\h\[\033[01;33m\] \w \[\033[01;31m\]$(__git_ps1 "(%s)") \n\[\033[01;34m\]\$\[\033[00m\] '
```

色はUbuntuのデフォルトプロンプトで使われている配色に合わせており、それぞれ以下を表している。

- `\u@\h`（ユーザー名@ホスト名）: 緑（`01;32`）
- `\w`（カレントディレクトリ）: 黄（`01;33`）
- `$(__git_ps1 "(%s)")`（gitブランチ名。gitリポジトリ内にいる場合のみ表示）: 赤（`01;31`）
- `\$`（プロンプト記号）: 青（`01;34`）

設定を反映する。

```bash
source ~/.bashrc
```

gitリポジトリ内に`cd`すると、プロンプトに`(ブランチ名)`が表示されるようになる。
