import Foundation
import UIKit
import MategramCore

private final class MategramRamMonitor: NSObject {
    static var shared: MategramRamMonitor?

    private weak var hostView: UIView?
    private let label = UILabel()
    private var timer: Timer?

    init(hostView: UIView) {
        self.hostView = hostView
        super.init()
        self.label.font = UIFont.monospacedDigitSystemFont(ofSize: 10.0, weight: .semibold)
        self.label.textColor = .white
        self.label.textAlignment = .center
        self.label.backgroundColor = UIColor(white: 0.0, alpha: 0.45)
        self.label.layer.cornerRadius = 7.0
        self.label.clipsToBounds = true
        self.label.isUserInteractionEnabled = false
        self.label.layer.zPosition = 10000.0
        let timer = Timer(timeInterval: 2.0, target: self, selector: #selector(self.tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        self.tick()
    }

    private func footprint() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), reboundPointer, &count)
            }
        }
        return result == KERN_SUCCESS ? info.phys_footprint : 0
    }

    @objc private func tick() {
        guard let hostView = self.hostView else {
            self.timer?.invalidate()
            return
        }
        if !MategramSettings.shared.bool(.ramMonitor) {
            self.label.removeFromSuperview()
            return
        }
        if self.label.superview !== hostView {
            hostView.addSubview(self.label)
        } else {
            hostView.bringSubviewToFront(self.label)
        }
        let megabytes = Double(self.footprint()) / 1048576.0
        self.label.text = String(format: "RAM %.0f MB", megabytes)
        let size = self.label.sizeThatFits(CGSize(width: 200.0, height: 20.0))
        let width = size.width + 12.0
        let top = max(hostView.safeAreaInsets.top, 20.0)
        self.label.frame = CGRect(x: 14.0, y: top - 2.0, width: width, height: 14.0)
    }
}

func mategramStartRamMonitor(hostView: UIView) {
    if MategramRamMonitor.shared == nil {
        MategramRamMonitor.shared = MategramRamMonitor(hostView: hostView)
    }
}
