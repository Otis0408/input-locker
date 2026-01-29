import Foundation
import Carbon

protocol InputSourceManagerDelegate: AnyObject {
    func inputSourceDidChange()
    func inputSourceWasRestored()
}

class InputSourceManager {
    weak var delegate: InputSourceManagerDelegate?

    private(set) var isLocked: Bool = false
    private var targetInputSourceID: String?
    private var monitorTimer: Timer?

    func startMonitoring() {
        // 监听输入法切换通知
        let notificationName = kTISNotifySelectedKeyboardInputSourceChanged as CFString
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            observer,
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<InputSourceManager>.fromOpaque(observer).takeUnretainedValue()
                manager.handleInputSourceChange()
            },
            notificationName,
            nil,
            .deliverImmediately
        )

        // 启动定时器作为备用检测机制
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkInputSource()
        }
    }

    func stopMonitoring() {
        // 移除通知监听
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDistributedCenter(),
            observer,
            CFNotificationName(kTISNotifySelectedKeyboardInputSourceChanged as CFString),
            nil
        )

        // 停止定时器
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    func lockCurrentInputSource() {
        guard let currentID = getCurrentInputSourceID() else {
            print("无法获取当前输入法ID")
            return
        }

        targetInputSourceID = currentID
        isLocked = true

        print("已锁定输入法: \(currentID)")
    }

    func unlock() {
        isLocked = false
        targetInputSourceID = nil
        print("已解锁输入法")
    }

    private func handleInputSourceChange() {
        delegate?.inputSourceDidChange()
        checkInputSource()
    }

    private func checkInputSource() {
        guard isLocked, let targetID = targetInputSourceID else { return }

        guard let currentID = getCurrentInputSourceID() else { return }

        if currentID != targetID {
            print("检测到输入法变化: \(currentID) -> 恢复到: \(targetID)")
            switchToInputSource(withID: targetID)
            delegate?.inputSourceWasRestored()
        }
    }

    // MARK: - Carbon API 封装

    private func getCurrentInputSourceID() -> String? {
        guard let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        guard let idPointer = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID) else {
            return nil
        }

        let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String
        return id
    }

    private func switchToInputSource(withID targetID: String) {
        let inputSourceList = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource]

        guard let sources = inputSourceList else {
            print("无法获取输入法列表")
            return
        }

        for source in sources {
            guard let idPointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else {
                continue
            }

            let id = Unmanaged<CFString>.fromOpaque(idPointer).takeUnretainedValue() as String

            if id == targetID {
                let status = TISSelectInputSource(source)
                if status == noErr {
                    print("成功切换到输入法: \(targetID)")
                } else {
                    print("切换输入法失败，错误码: \(status)")
                }
                return
            }
        }

        print("未找到目标输入法: \(targetID)")
    }
}
