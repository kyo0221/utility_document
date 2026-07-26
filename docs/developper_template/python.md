# Pythonパッケージ用テンプレート

ROS 2のPython（`ament_python`）パッケージを最小構成で作成するためのテンプレート。
以下のファイルをそのままパッケージディレクトリに配置し、プレースホルダーを置き換えるだけで最小構成のノードが動作する。

```
パッケージ名/
├── package.xml
├── setup.py
├── setup.cfg
├── resource/
│   └── パッケージ名
└── パッケージ名/
    ├── __init__.py
    └── ノード名.py
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
