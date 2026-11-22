import Foundation
import UIKit

private func mategramFirstResponder(in view: UIView) -> UIView? {
    if view.isFirstResponder {
        return view
    }
    for subview in view.subviews {
        if let found = mategramFirstResponder(in: subview) {
            return found
        }
    }
    return nil
}

func mategramSelectAll(in root: UIView?) {
    guard let root, let responder = mategramFirstResponder(in: root) else {
        return
    }
    responder.selectAll(nil)
}

func mategramUndo(in root: UIView?) {
    guard let root else {
        return
    }
    let responder = mategramFirstResponder(in: root) ?? root
    responder.undoManager?.undo()
}
