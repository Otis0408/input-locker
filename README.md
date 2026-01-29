# InputLocker

一个简洁的 macOS 菜单栏应用，用于锁定输入法，防止系统自动切换输入法。

## 功能特性

- 🔒 锁定当前输入法，防止意外切换
- 🔓 一键解锁输入法
- 🌓 完美支持深色/浅色模式（使用 SF Symbols）
- 🇨🇳 全中文界面
- 🚀 开机自启动选项
- ⚡️ 实时监控输入法变化（Carbon API + 定时器双重保障）

## 系统要求

- macOS 10.15 (Catalina) 或更高版本
- Xcode Command Line Tools

## 编译安装

```bash
# 编译
make build

# 运行
make run

# 安装到 /Applications
make install
```

## 使用方法

1. 启动应用后，菜单栏会出现一个锁图标
2. 点击图标，选择"锁定当前输入法"
3. 此后系统会自动保持该输入法，任何切换都会被立即恢复
4. 需要切换输入法时，先点击"解锁"

## 技术实现

- **语言**: Swift
- **框架**: AppKit (NSApplication, NSStatusItem)
- **输入法 API**: Carbon Framework (TISInputSource)
- **图标**: SF Symbols (自适应深色/浅色模式)
- **监控机制**: CFNotificationCenter + Timer 双重保障

## 许可证

MIT License

## 作者

Lei185
