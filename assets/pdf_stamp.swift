// 给 PDF 加页脚与页码（macOS / PDFKit + Core Graphics，保留矢量）。
// 用法：swift pdf_stamp.swift in.pdf out.pdf "数据站 · 单篇笔记分析"
// 说明：封面（第 1 页）不加；页码格式 02 / 08。
import Foundation
import CoreGraphics
import CoreText
import AppKit

let args = CommandLine.arguments
guard args.count >= 4 else {
    print("usage: pdf_stamp.swift in.pdf out.pdf footerText")
    exit(2)
}
let inURL = URL(fileURLWithPath: args[1])
let outURL = URL(fileURLWithPath: args[2])
let footer = args[3]

guard let src = CGPDFDocument(inURL as CFURL) else { print("cannot open pdf"); exit(1) }
let total = src.numberOfPages

guard let out = CGContext(outURL as CFURL, mediaBox: nil, nil) else { print("cannot create pdf"); exit(1) }

let font = CTFontCreateWithName("PingFangSC-Regular" as CFString, 7.5, nil)
let gray = CGColor(red: 0.55, green: 0.53, blue: 0.49, alpha: 1)
let lineColor = CGColor(red: 0.86, green: 0.83, blue: 0.77, alpha: 1)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor(calibratedWhite: 0.55, alpha: 1)
]

for i in 1...total {
    guard let page = src.page(at: i) else { continue }
    var box = page.getBoxRect(.mediaBox)
    let info = [kCGPDFContextMediaBox as String: Data(bytes: &box, count: MemoryLayout<CGRect>.size)] as CFDictionary
    out.beginPDFPage(info)
    out.drawPDFPage(page)

    if i > 1 {
        let left: CGFloat = 42
        let right = box.width - 42
        let y: CGFloat = 28

        out.setStrokeColor(lineColor)
        out.setLineWidth(0.4)
        out.move(to: CGPoint(x: left, y: y + 12))
        out.addLine(to: CGPoint(x: right, y: y + 12))
        out.strokePath()

        func draw(_ text: String, x: CGFloat, alignRight: Bool) {
            let attr = NSAttributedString(string: text, attributes: attrs)
            let line = CTLineCreateWithAttributedString(attr)
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            out.textPosition = CGPoint(x: alignRight ? x - width : x, y: y)
            CTLineDraw(line, out)
        }
        draw(footer, x: left, alignRight: false)
        draw(String(format: "%02d / %02d", i, total), x: right, alignRight: true)
    }
    out.endPDFPage()
}
out.closePDF()
print("stamped \(total) pages ->", outURL.path)
