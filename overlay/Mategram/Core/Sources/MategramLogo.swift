import Foundation
import UIKit

public enum MategramLogo {
    public static func image(size: CGSize, color: UIColor, background: UIColor? = nil, cornerRadius: CGFloat = 0.0, scale: CGFloat = 1.84) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            if let background {
                let rect = CGRect(origin: .zero, size: size)
                background.setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
            }
            context.translateBy(x: size.width / 2.0, y: size.height * 525.0 / 1024.0)
            context.rotate(by: 36.0 * CGFloat.pi / 180.0)
            let factor = size.width / 1024.0 * scale
            context.scaleBy(x: factor, y: factor)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0.0, y: -62.0))
            path.addLine(to: CGPoint(x: 62.0, y: 56.0))
            path.addQuadCurve(to: CGPoint(x: -62.0, y: 56.0), controlPoint: CGPoint(x: 0.0, y: 22.0))
            path.close()
            path.lineWidth = 104.0
            path.lineJoinStyle = .round
            color.setFill()
            color.setStroke()
            path.fill()
            path.stroke()
        }
    }

    public static func centeredImage(size: CGSize, color: UIColor, background: UIColor? = nil, cornerRadius: CGFloat = 0.0, fill: CGFloat = 0.5) -> UIImage {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0.0, y: -62.0))
        path.addLine(to: CGPoint(x: 62.0, y: 56.0))
        path.addQuadCurve(to: CGPoint(x: -62.0, y: 56.0), controlPoint: CGPoint(x: 0.0, y: 22.0))
        path.close()
        let outline = path.cgPath.copy(strokingWithWidth: 104.0, lineCap: .round, lineJoin: .round, miterLimit: 10.0)
        let combined = UIBezierPath(cgPath: outline)
        combined.append(path)
        combined.apply(CGAffineTransform(rotationAngle: 36.0 * CGFloat.pi / 180.0))
        let bounds = combined.bounds
        let side = max(bounds.width, bounds.height)
        let target = min(size.width, size.height) * fill
        let factor = side > 0.0 ? target / side : 1.0
        combined.apply(CGAffineTransform(translationX: -bounds.midX, y: -bounds.midY))
        combined.apply(CGAffineTransform(scaleX: factor, y: factor))
        combined.apply(CGAffineTransform(translationX: size.width / 2.0, y: size.height / 2.0))
        combined.usesEvenOddFillRule = false
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            if let background {
                background.setFill()
                UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius).fill()
            }
            color.setFill()
            combined.fill()
        }
    }

    public static func symbol(_ name: String, color: UIColor) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 19.0, weight: .regular)
        guard let image = UIImage(systemName: name, withConfiguration: configuration)?.withTintColor(color, renderingMode: .alwaysOriginal) else {
            return nil
        }
        let canvas = CGSize(width: 29.0, height: 29.0)
        return UIGraphicsImageRenderer(size: canvas).image { _ in
            let origin = CGPoint(x: (canvas.width - image.size.width) / 2.0, y: (canvas.height - image.size.height) / 2.0)
            image.draw(at: origin)
        }
    }
}
