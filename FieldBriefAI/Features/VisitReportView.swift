import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct VisitReportView: View {
    let title: String
    let report: String
    @State private var pdf: Data?

    var body: some View {
        ScrollView {
            Text(report).frame(maxWidth: .infinity, alignment: .leading).padding()
        }
        .navigationTitle(title)
        .toolbar {
            if let pdf {
                ShareLink(item: VisitReportPDF(data: pdf), preview: SharePreview("FieldBrief visit report")) {
                    Label("Share PDF", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("shareVisitPDF")
            }
        }
        .task(id: report) { pdf = Self.render(report) }
    }

    @MainActor
    private static func render(_ report: String) -> Data {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let formatter = UISimpleTextPrintFormatter(text: report)
        formatter.font = .systemFont(ofSize: 12)
        formatter.color = .black
        let renderer = VisitPrintRenderer(page: page)
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)
        let count = renderer.numberOfPages
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: count))
        return UIGraphicsPDFRenderer(bounds: page).pdfData { context in
            for index in 0..<count {
                context.beginPage()
                renderer.drawPage(at: index, in: page)
            }
        }
    }
}

private struct VisitReportPDF: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { $0.data }
            .suggestedFileName("FieldBrief-Visit-Report.pdf")
    }
}

private final class VisitPrintRenderer: UIPrintPageRenderer {
    private let page: CGRect

    init(page: CGRect) {
        self.page = page
        super.init()
    }

    override var paperRect: CGRect { page }
    override var printableRect: CGRect { page.insetBy(dx: 44, dy: 44) }
}
