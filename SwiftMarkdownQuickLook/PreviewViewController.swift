import Cocoa
import Quartz
import SwiftMarkdownCore

class PreviewViewController: NSViewController, QLPreviewingController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 400, height: 300)

        if let textView = scrollView.documentView as? NSTextView {
            textView.isEditable = false
            textView.isSelectable = true
            textView.backgroundColor = .textBackgroundColor
            textView.textContainerInset = NSSize(width: 16, height: 16)
        }

        self.view = scrollView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)

            let document = MarkdownParser.parseDocument(content)
            let renderer = DocumentRenderer()
            let theme = MarkdownTheme.default
            let context = RenderContext()
            let attributedString = renderer.render(document, theme: theme, context: context)

            DispatchQueue.main.async {
                if let scrollView = self.view as? NSScrollView,
                   let textView = scrollView.documentView as? NSTextView {
                    textView.textStorage?.setAttributedString(attributedString)
                }
                handler(nil)
            }
        } catch {
            handler(error)
        }
    }
}
