# リモートデスクトップ（RustDesk + Tailscale）

Ubuntu 22.04 を**操作される側**、Ubuntu 24.04 と Windows 11 を**操作する側**として構築する。検証環境は RustDesk 1.4.9 / X11 / GNOME。

---

## 0. 構成方針

操作される側がNAT配下でグローバルIPを持たない場合、外部から到達するには「公式パブリックサーバーを使う」か「仮想LANを張る」かのどちらかが要る。本手順は後者を採り、Tailscaleで全機を同一サブネットに入れて**RustDeskの直接IP接続**でつなぐ。

| 方式 | サーバー | 判断 |
| --- | --- | --- |
| 公式パブリックサーバー | 不要 | 混雑で不安定・第三者を経由する。不採用 |
| **Tailscale + 直接IP接続** | 不要 | 本手順。IDサーバーを介さずP2P |
| 自前 hbbs/hbbr | 要グローバルIP | VPS等がある場合のみ → [付録](#hbbshbbr) |

直接IP接続はIDサーバーを完全にバイパスするため、RustDeskのアカウント登録もID共有も不要になる。

---

## 1. 操作される側（Ubuntu 22.04）

### 1.1 セッションがX11であることを確認

RustDeskのWayland対応は実験的なので、X11で動かす。

```bash
echo $XDG_SESSION_TYPE   # → x11
```

`x11`でない場合のみ、GDMのWaylandを無効化して再起動する。

```bash
sudo sed -i 's/^#\?WaylandEnable=.*/WaylandEnable=false/' /etc/gdm3/custom.conf
sudo reboot
```

### 1.2 Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up     # 表示されたURLをブラウザで開いてログイン
tailscale ip -4       # → 100.x.y.z （このIPを控える）
```

Linuxでは`tailscaled`がsystemdサービスとして常駐するため、再起動後も自動で復帰する。

### 1.3 RustDesk

```bash
cd /tmp
curl -LO https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-x86_64.deb
sudo apt install -y ./rustdesk-1.4.9-x86_64.deb
```

debのpostinstが`rustdesk.service`をenable/startまで済ませるため、サービス登録の追加作業は不要。

```bash
systemctl is-enabled rustdesk; systemctl is-active rustdesk   # → enabled / active
```

### 1.4 固定パスワードと直接IP接続

無人アクセスに必要なのはこの2つだけ（GUIなら「設定 → セキュリティ」）。

```bash
sudo rustdesk --password 'ここに強いパスワード'   # 固定パスワード
sudo rustdesk --option direct-server Y           # 直接IP接続を許可（21118/tcpで待受）
```

OSのログインパスワードは使い回さない。設定できたか確認する。

```bash
sudo rustdesk --option direct-server   # → Y
ss -ltn sport = :21118                 # → LISTEN が1行出る
```

LISTENしない場合は`sudo systemctl restart rustdesk`。

### 1.5 ファイアウォール

ufwが有効なときのみ、tailscale経由の21118を通す。

```bash
sudo ufw status                                             # inactive なら以下は不要
sudo ufw allow in on tailscale0 to any port 21118 proto tcp
```

---

## 2. 操作する側（Ubuntu 24.04）

同じdebが24.04でも動く。操作する側は固定パスワードもdirect-serverも設定しなくてよい。

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

cd /tmp
curl -LO https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-x86_64.deb
sudo apt install -y ./rustdesk-1.4.9-x86_64.deb
```

---

## 3. 操作する側（Windows 11）

インストーラを順に実行するだけでよい。

1. Tailscale — <https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe> → 実行してログイン
2. RustDesk — <https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-x86_64.exe> → 実行

PowerShellで疎通を確認する（`100.x.y.z`は1.2で控えたIP）。

```powershell
tailscale up --unattended       # ログアウト後もTailscaleを維持（Windows専用オプション）
tailscale ping 100.x.y.z
Test-NetConnection 100.x.y.z -Port 21118   # TcpTestSucceeded : True
```

---

## 4. 接続

操作する側のRustDeskで、ID欄に**IDではなく操作される側のTailscale IP**を入力して接続し、1.4で決めた固定パスワードを入れる。

```
100.x.y.z
```

既定以外のポートにした場合のみ`100.x.y.z:ポート番号`と書く。

---

## 5. つながらないとき

| 症状 | 確認すること |
| --- | --- |
| `tailscale ping`が通らない | 両機の`tailscale status`が同一tailnetにいるか |
| pingは通るが接続できない | 操作される側で`ss -ltn sport = :21118`がLISTENか、ufwを通したか |
| 接続後に黒画面・操作不能 | 操作される側の`echo $XDG_SESSION_TYPE`が`x11`か |
| ログイン画面に入れない | GDMのWayland無効化（1.1）と`systemctl status rustdesk` |
| パスワードが弾かれる | `sudo rustdesk --password '...'`を再実行（要root・要インストール済み） |

---

## 付録: 自前サーバー（hbbs/hbbr） {#hbbshbbr}

グローバルIPを持つVPS等がある場合のみ。Tailscale方式では不要。

```bash
mkdir -p ~/rustdesk-server && cd ~/rustdesk-server
curl -LO https://raw.githubusercontent.com/rustdesk/rustdesk-server/master/docker-compose.yml
sed -i 's/rustdesk.example.com/自分のドメインまたはグローバルIP/' docker-compose.yml
docker compose up -d
```

開けるポートは以下。**21116のUDPを忘れるとホールパンチが効かない。**

| ポート | プロトコル | 用途 |
| --- | --- | --- |
| 21115 | TCP | NATタイプ判定 |
| 21116 | TCP + UDP | ID登録・ハートビート・ホールパンチ |
| 21117 | TCP | リレー（hbbr） |
| 21118 / 21119 | TCP | Webクライアント用。使わないなら閉じる |

起動時に生成される公開鍵を取り出す。

```bash
cat data/id_ed25519.pub
```

各クライアントの「設定 → ネットワーク → ID/リレーサーバー」に次を設定する。

| 項目 | 値 |
| --- | --- |
| IDサーバー | `example.com:21116` |
| リレーサーバー | `example.com:21117` |
| Key | `id_ed25519.pub`の中身 |

---

## 参考

- [RustDesk Documentation](https://rustdesk.com/docs/)
- [rustdesk/rustdesk-server](https://github.com/rustdesk/rustdesk-server)
- [Tailscale Download](https://tailscale.com/download)
