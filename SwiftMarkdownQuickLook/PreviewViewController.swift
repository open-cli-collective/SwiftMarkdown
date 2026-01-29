import Cocoa
import Quartz
import SwiftMarkdownCore

class PreviewViewController: NSViewController, QLPreviewingController {
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        // Create a simple text view for now
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        textView.isEditable = false
        textView.autoresizingMask = [.width, .height]
        textView.backgroundColor = .textBackgroundColor
        self.view = textView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)

            DispatchQueue.main.async {
                if let textView = self.view as? NSTextView {
                    // TODO: Parse markdown and render as attributed string
                    textView.string = content
                }
                handler(nil)
            }
        } catch {
            handler(error)
        }
    }
}
