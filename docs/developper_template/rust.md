# Rustパッケージ用テンプレート

ROS 2のRust（[`ros2_rust`](https://github.com/ros2-rust/ros2_rust) / `rclrs`、`ament_cargo`）パッケージを最小構成で作成するためのテンプレート。
ビルドには `rclrs` crateに加えて colcon 拡張の `cargo-ament-build` が必要（`pip install git+https://github.com/colcon/colcon-cargo.git git+https://github.com/colcon/colcon-ros-cargo.git` などで導入）。
以下のファイルをそのままパッケージディレクトリに配置し、プレースホルダーを置き換えるだけで最小構成のノードが動作する。

```
パッケージ名/
├── Cargo.toml
├── package.xml
└── src/
    └── ノード名.rs
```

### package.xml
```
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>パッケージ名</name>
  <version>1.0.0</version>
  <description>説明文</description>
  <maintainer email="メアド">メンテナ名</maintainer>
  <license>ライセンス名</license>

  <depend>rclrs</depend>
  <depend>メッセージ型パッケージ</depend>
  <!-- <depend>追加の依存関係</depend> -->

  <export>
    <build_type>ament_cargo</build_type>
  </export>
</package>
```

### Cargo.toml
```
[package]
name = "パッケージ名"
version = "1.0.0"
edition = "2021"

[dependencies]
rclrs = "*"
メッセージ型パッケージ = "*"

[[bin]]
name = "実行可能ファイル名"
path = "src/ノード名.rs"
```

### src/ノード名.rs
```
use std::time::Duration;

use rclrs::*;

struct クラス名 {
    #[allow(dead_code)]
    node: Node,

    // メンバ変数宣言例:
    publisher_: Publisher<メッセージ型>,
    _subscriber_: Subscription<メッセージ型>,
    _timer_: Timer,
}

impl クラス名 {
    fn new(executor: &Executor) -> Result<Self, RclrsError> {
        let node = executor.create_node("ノード名")?;

        // パブリッシャー宣言例:
        let publisher_ = node.create_publisher::<メッセージ型>("トピック名")?;

        // サブスクライバー宣言例:
        let _subscriber_ = node.create_subscription(
            "トピック名",
            move |msg: メッセージ型| {
                // 受信コールバック内容
                // msg.データメンバ でアクセス可能
            },
        )?;

        // パラメータ宣言例:
        let _parameter_ = node
            .declare_parameter::<型>("パラメータ名")
            .default(デフォルト値)
            .mandatory()?;

        // タイマー宣言例:
        let _timer_ = node.create_timer_repeating(
            Duration::from_millis(周期),
            move || {
                // タイマーコールバック内容
            },
        )?;

        Ok(Self { node, publisher_, _subscriber_, _timer_ })
    }
}

fn main() -> Result<(), RclrsError> {
    let context = Context::default_from_env()?;
    let mut executor = context.create_basic_executor();
    let _クラス名 = クラス名::new(&executor)?;

    executor.spin(SpinOptions::default()).first_error()
}
```
