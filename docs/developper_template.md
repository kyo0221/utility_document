### CmakeLists.txt
```
cmake_minimum_required(VERSION 3.8)
project(パッケージ名)

find_package(ament_cmake_auto REQUIRED)
ament_auto_find_build_dependencies()

ament_auto_add_library(${PROJECT_NAME} SHARED
    DIRECTORY src
)

rclcpp_components_register_node(${PROJECT_NAME}
    PLUGIN "ネームスペース::クラス名"
    EXECUTABLE 実行可能ファイル名
)

ament_auto_package(USE_SCOPED_HEADER_INSTALL_DIR)
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

  <buildtool_depend>ament_cmake_auto</buildtool_depend>

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <depend>rclcpp</depend>
  <depend>rclcpp_components</depend>
  <!-- <depend>追加の依存関係</depend> -->

  <export>
    <build_type>ament_cmake</build_type>
  </export>
</package>
```

### .hpp
```
#ifndef __ヘッダー名_HPP__
#define __ヘッダー名_HPP__

#include "rclcpp/rclcpp.hpp"

#include "メッセージ型ヘッダー.hpp"

namespace ネームスペース {
class クラス名 : public rclcpp::Node {
public:
    クラス名 (const rclcpp::NodeOptions &node_options);
    ~クラス名 ();

private:
    // パラメータ宣言例:
    型 parameter_;

    // コールバック関数宣言例:
    void コールバック関数名(const メッセージ型::SharedPtr msg);
    void タイマーコールバック関数名();

    // メンバ変数宣言例:
    rclcpp::Publisher<メッセージ型>::SharedPtr publisher_;
    rclcpp::Subscription<メッセージ型>::SharedPtr subscriber_;
    rclcpp::TimerBase::SharedPtr timer_;
};
}  // namespace ネームスペース

#endif  // __ヘッダー名_HPP__
```

### .cpp
```
#include "パッケージ名/ヘッダー名.hpp"

namespace ネームスペース {

クラス名::クラス名(const rclcpp::NodeOptions & node_options) : Node("ノード名", node_options) {
    // コンストラクタ内容

    // パブリッシャー、サブスクライバー 宣言例:
    publisher_ = this->create_publisher<メッセージ型>("トピック名", キューサイズ);
    subscriber_ = this->create_subscription<メッセージ型>(
        "トピック名", キューサイズ,
        std::bind(&クラス名::コールバック関数名, this, std::placeholders::_1)
    );

    // パラメータ宣言例:
    parameter_ = this->declare_parameter<型>("パラメータ名", デフォルト値);

    // タイマー宣言例:
    timer_ = this->create_wall_timer(
        std::chrono::milliseconds(周期),
        std::bind(&クラス名::タイマーコールバック関数名, this)
    );
}

クラス名::~クラス名() {
    // デストラクタ内容
}

void クラス名::コールバック関数名(const メッセージ型::SharedPtr msg) {
    // 受信コールバック内容
msg->データメンバ名 でアクセス可能
}

void クラス名::タイマーコールバック関数名() {
// タイマーコールバック内容
}

}  // namespace ネームスペース

#include "rclcpp_components/register_node_macro.hpp"
RCLCPP_COMPONENTS_REGISTER_NODE(ネームスペース::クラス名)
```

---

## Pythonパッケージ用テンプレート

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

  <test_depend>ament_lint_auto</test_depend>
  <test_depend>ament_lint_common</test_depend>

  <depend>rclpy</depend>
  <!-- <depend>追加の依存関係</depend> -->

  <export>
    <build_type>ament_python</build_type>
  </export>
</package>
```

### setup.py
```
from setuptools import find_packages, setup

package_name = 'パッケージ名'

setup(
    name=package_name,
    version='1.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='メンテナ名',
    maintainer_email='メアド',
    description='説明文',
    license='ライセンス名',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
            '実行可能ファイル名 = パッケージ名.ノード名:main',
        ],
    },
)
```

### setup.cfg
```
[develop]
script_dir=$base/lib/パッケージ名
[install]
install_scripts=$base/lib/パッケージ名
```

### resource/パッケージ名
```
（中身は空のままでよい。パッケージ名を認識させるためのマーカーファイル）
```

### パッケージ名/\_\_init\_\_.py
```
（中身は空のままでよい）
```

### パッケージ名/ノード名.py
```
import rclpy
from rclpy.node import Node

from メッセージ型パッケージ.msg import メッセージ型


class クラス名(Node):
    def __init__(self):
        super().__init__('ノード名')

        # パブリッシャー、サブスクライバー 宣言例:
        self.publisher_ = self.create_publisher(メッセージ型, 'トピック名', キューサイズ)
        self.subscriber_ = self.create_subscription(
            メッセージ型, 'トピック名', self.コールバック関数名, キューサイズ)

        # パラメータ宣言例:
        self.declare_parameter('パラメータ名', デフォルト値)
        self.parameter_ = self.get_parameter('パラメータ名').value

        # タイマー宣言例:
        self.timer_ = self.create_timer(周期, self.タイマーコールバック関数名)

    def コールバック関数名(self, msg):
        # 受信コールバック内容
        # msg.データメンバ名 でアクセス可能
        pass

    def タイマーコールバック関数名(self):
        # タイマーコールバック内容
        pass


def main(args=None):
    rclpy.init(args=args)
    node = クラス名()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
```