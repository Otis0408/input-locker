import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var inputSourceManager: InputSourceManager!

    private var statusMenuItem: NSMenuItem!
    private var lockMenuItem: NSMenuItem!
    private var unlockMenuItem: NSMenuItem!
    private var autoStartMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化输入法管理器
        inputSourceManager = InputSourceManager()
        inputSourceManager.delegate = self

        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            updateIcon()
        }

        // 创建菜单
        setupMenu()

        // 启动输入法监控
        inputSourceManager.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        inputSourceManager.stopMonitoring()
    }

    private func setupMenu() {
        menu = NSMenu()

        // 状态项（禁用）
        statusMenuItem = NSMenuItem(title: "状态：未锁定", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 锁定当前输入法
        lockMenuItem = NSMenuItem(title: "锁定当前输入法", action: #selector(lockCurrentInputSource), keyEquivalent: "l")
        lockMenuItem.target = self
        menu.addItem(lockMenuItem)

        // 解锁
        unlockMenuItem = NSMenuItem(title: "解锁", action: #selector(unlockInputSource), keyEquivalent: "u")
        unlockMenuItem.target = self
        menu.addItem(unlockMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 开机自启动
        autoStartMenuItem = NSMenuItem(title: "开机自启动", action: #selector(toggleAutoStart), keyEquivalent: "")
        autoStartMenuItem.target = self
        autoStartMenuItem.state = isAutoStartEnabled() ? .on : .off
        menu.addItem(autoStartMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitMenuItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)

        statusItem.menu = menu

        updateMenuState()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }

        let symbolName = inputSourceManager.isLocked ? "lock.shield.fill" : "lock.open.fill"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
        }
    }

    private func updateMenuState() {
        let isLocked = inputSourceManager.isLocked

        statusMenuItem.title = isLocked ? "状态：已锁定" : "状态：未锁定"
        lockMenuItem.isEnabled = !isLocked
        unlockMenuItem.isEnabled = isLocked

        updateIcon()
    }

    @objc private func lockCurrentInputSource() {
        inputSourceManager.lockCurrentInputSource()
        updateMenuState()

        // 显示通知
        showNotification(title: "输入法已锁定", message: "当前输入法已被锁定")
    }

    @objc private func unlockInputSource() {
        inputSourceManager.unlock()
        updateMenuState()

        // 显示通知
        showNotification(title: "输入法已解锁", message: "输入法锁定已解除")
    }

    @objc private func toggleAutoStart() {
        let newState = !isAutoStartEnabled()
        setAutoStart(enabled: newState)
        autoStartMenuItem.state = newState ? .on : .off
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }

    // MARK: - 开机自启动

    private func isAutoStartEnabled() -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.inputlocker.app"
        let jobDict = SMJobCopyDictionary(kSMDomainUserLaunchd, bundleIdentifier as CFString)
        return jobDict != nil
    }

    private func setAutoStart(enabled: Bool) {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.inputlocker.app"

        if enabled {
            // 添加到登录项
            let appPath = Bundle.main.bundlePath
            let url = URL(fileURLWithPath: appPath)

            if let sharedWorkspace = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.loginwindow" }) {
                // 使用 LSSharedFileList API (已弃用但仍可用)
                // 或者使用 SMLoginItemSetEnabled (需要 helper)
                // 简化实现：使用 AppleScript
                let script = """
                tell application "System Events"
                    make login item at end with properties {path:"\(appPath)", hidden:false}
                end tell
                """

                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                    if error != nil {
                        print("添加登录项失败")
                    }
                }
            }
        } else {
            // 从登录项移除
            let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "InputLocker"
            let script = """
            tell application "System Events"
                delete login item "\(appName)"
            end tell
            """

            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                if error != nil {
                    print("移除登录项失败")
                }
            }
        }
    }
}

// MARK: - InputSourceManagerDelegate

extension AppDelegate: InputSourceManagerDelegate {
    func inputSourceDidChange() {
        // 输入法变化时更新UI（如果需要）
    }

    func inputSourceWasRestored() {
        // 输入法被恢复时显示通知
        showNotification(title: "输入法已恢复", message: "输入法已自动切换回锁定的输入法")
    }
}
