import Foundation
import PDFKit
import SwiftUI
import AppKit

@MainActor
final class ReportService {
    static let shared = ReportService()

    private let fileManager = FileManager.default
    private lazy var reportsDirectory: URL = {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let axiomDir = docs.appendingPathComponent("Axiom", isDirectory: true)
        let reportsDir = axiomDir.appendingPathComponent("Reports", isDirectory: true)
        try? fileManager.createDirectory(at: reportsDir, withIntermediateDirectories: true)
        return reportsDir
    }()

    private init() {}

    func generateMonthlyReport(for month: Date) -> URL? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let year = components.year, let monthNum = components.month else { return nil }

        let monthName = DateFormatter().monthSymbols[monthNum - 1]
        let beliefs = DatabaseService.shared.allBeliefs

        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        let beliefsThisMonth = beliefs.filter { $0.createdAt >= startOfMonth && $0.createdAt <= endOfMonth }
        let allEvidenceThisMonth = beliefsThisMonth.flatMap { belief in
            belief.evidenceItems.filter { $0.createdAt >= startOfMonth && $0.createdAt <= endOfMonth }
        }
        let avgScore = beliefs.isEmpty ? 0 : beliefs.map(\.score).reduce(0, +) / Double(beliefs.count)

        let beliefsWithChanges = beliefs.map { belief -> (Belief, Double) in
            let history = belief.scoreHistory.filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
            let change = history.count >= 2 ? history.last!.score - history.first!.score : 0
            return (belief, change)
        }.sorted { abs($0.1) > abs($1.1) }
        let topChanges = Array(beliefsWithChanges.prefix(3))

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let goldColor = NSColor(red: 1.0, green: 0.79, blue: 0.16, alpha: 1.0)
        let greenColor = NSColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        let redColor = NSColor(red: 0.94, green: 0.33, blue: 0.31, alpha: 1.0)
        let whiteColor = NSColor.white
        let grayColor = NSColor.gray
        let borderColor = NSColor(red: 0.23, green: 0.23, blue: 0.24, alpha: 1.0)

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: nil, nil) else { return nil }

        var mediaBox = CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height)
        pdfContext.beginPage(mediaBox: &mediaBox)

        let ctx = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx

        var yPosition: CGFloat = 50
        let margin: CGFloat = 50

        func drawText(_ text: String, at y: CGFloat, x: CGFloat, font: NSFont, color: NSColor) {
            text.draw(at: CGPoint(x: x, y: pageRect.height - y), withAttributes: [.font: font, .foregroundColor: color])
        }

        let headerFont = NSFont.systemFont(ofSize: 24, weight: .bold)
        let sectionFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
        let bodyFont = NSFont.systemFont(ofSize: 12, weight: .regular)
        let footerFont = NSFont.systemFont(ofSize: 10, weight: .regular)

        drawText("Axiom Monthly Belief Report — \(monthName) \(year)", at: yPosition, x: margin, font: headerFont, color: whiteColor)
        yPosition += 60

        borderColor.setStroke()
        let divider = NSBezierPath()
        divider.move(to: CGPoint(x: margin, y: pageRect.height - yPosition))
        divider.line(to: CGPoint(x: 562, y: pageRect.height - yPosition))
        divider.lineWidth = 1
        divider.stroke()
        yPosition += 30

        drawText("Summary", at: yPosition, x: margin, font: sectionFont, color: goldColor)
        yPosition += 25

        let summaryItems = [
            "Total Beliefs: \(beliefs.count)",
            "Beliefs Added This Month: \(beliefsThisMonth.count)",
            "Average Belief Score: \(Int(avgScore))%",
            "Evidence Added This Month: \(allEvidenceThisMonth.count)"
        ]
        for item in summaryItems {
            drawText(item, at: yPosition, x: margin + 20, font: bodyFont, color: whiteColor)
            yPosition += 20
        }
        yPosition += 20

        drawText("Top Belief Changes", at: yPosition, x: margin, font: sectionFont, color: goldColor)
        yPosition += 25

        if topChanges.isEmpty {
            drawText("No significant changes tracked this month.", at: yPosition, x: margin + 20, font: bodyFont, color: grayColor)
            yPosition += 20
        } else {
            for (belief, change) in topChanges {
                let changeStr = change >= 0 ? "+\(Int(change))%" : "\(Int(change))%"
                drawText("\(belief.text.prefix(50))... → \(changeStr)", at: yPosition, x: margin + 20, font: bodyFont, color: change >= 0 ? greenColor : redColor)
                yPosition += 20
            }
        }
        yPosition += 20

        drawText("Pattern Observations", at: yPosition, x: margin, font: sectionFont, color: goldColor)
        yPosition += 25

        let patterns = PatternDetectionService.shared.analyzeAllPatterns(in: beliefs)
        if patterns.isEmpty {
            drawText("Continue working on your beliefs to see patterns emerge.", at: yPosition, x: margin + 20, font: bodyFont, color: grayColor)
        } else {
            for pattern in patterns.prefix(5) {
                drawText("• \(pattern.title): \(pattern.description)", at: yPosition, x: margin + 20, font: bodyFont, color: whiteColor)
                yPosition += 20
            }
        }

        drawText("Generated by Axiom", at: pageRect.height - 50, x: margin, font: footerFont, color: grayColor)

        NSGraphicsContext.restoreGraphicsState()
        pdfContext.endPage()
        pdfContext.closePDF()

        let fileURL = reportsDirectory.appendingPathComponent("Axiom_Report_\(monthName)_\(year).pdf")
        do {
            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    func generateBeliefMap() -> URL? {
        let beliefs = DatabaseService.shared.allBeliefs
        let connections = DatabaseService.shared.allConnections
        let pageRect = CGRect(x: 0, y: 0, width: 792, height: 612)

        let goldColor = NSColor(red: 1.0, green: 0.79, blue: 0.16, alpha: 1.0)
        let greenColor = NSColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1.0)
        let redColor = NSColor(red: 0.94, green: 0.33, blue: 0.31, alpha: 1.0)
        let whiteColor = NSColor.white
        let grayColor = NSColor.gray
        let bgColor = NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
        let borderColor = NSColor(red: 0.23, green: 0.23, blue: 0.24, alpha: 1.0)

        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: nil, nil) else { return nil }

        var mediaBox = CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height)
        pdfContext.beginPage(mediaBox: &mediaBox)

        let ctx = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx

        let margin: CGFloat = 50
        var yPos: CGFloat = 50

        func drawText(_ text: String, at y: CGFloat, x: CGFloat, font: NSFont, color: NSColor) {
            text.draw(at: CGPoint(x: x, y: pageRect.height - y), withAttributes: [.font: font, .foregroundColor: color])
        }

        let titleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
        let subFont = NSFont.systemFont(ofSize: 12, weight: .regular)
        let legendFont = NSFont.systemFont(ofSize: 10, weight: .medium)
        let nodeFont = NSFont.systemFont(ofSize: 11, weight: .regular)
        let headerFont = NSFont.systemFont(ofSize: 10, weight: .bold)
        let footerFont = NSFont.systemFont(ofSize: 9, weight: .regular)

        drawText("Belief Network Map", at: yPos, x: margin, font: titleFont, color: whiteColor)
        yPos += 40
        drawText("\(beliefs.count) beliefs · \(connections.count) connections", at: yPos, x: margin, font: subFont, color: grayColor)
        yPos += 40

        let legendItems: [(String, NSColor)] = [("Core Belief", goldColor), ("Supporting", greenColor), ("Contradicting", redColor)]
        for (i, (label, color)) in legendItems.enumerated() {
            let x = margin + CGFloat(i) * 200
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: x, y: pageRect.height - yPos - 4, width: 10, height: 10)).fill()
            drawText(label, at: yPos, x: x + 15, font: legendFont, color: whiteColor)
        }
        yPos += 30

        borderColor.setStroke()
        let divPath = NSBezierPath()
        divPath.move(to: CGPoint(x: margin, y: pageRect.height - yPos))
        divPath.line(to: CGPoint(x: pageRect.width - margin, y: pageRect.height - yPos))
        divPath.lineWidth = 0.5
        divPath.stroke()
        yPos += 20

        let beliefsPerRow = 3
        let nodeWidth = (pageRect.width - 2 * margin - CGFloat(beliefsPerRow - 1) * 20) / CGFloat(beliefsPerRow)
        let nodeHeight: CGFloat = 80

        for (index, belief) in beliefs.prefix(30).enumerated() {
            let col = index % beliefsPerRow
            let row = index / beliefsPerRow
            let x = margin + CGFloat(col) * (nodeWidth + 20)
            let y = yPos + CGFloat(row) * (nodeHeight + 20)
            if y + nodeHeight > pageRect.height - margin { break }

            let nodeRect = NSRect(x: x, y: pageRect.height - y - nodeHeight, width: nodeWidth, height: nodeHeight)
            (belief.isCore ? NSColor(red: 1.0, green: 0.79, blue: 0.16, alpha: 0.15) : bgColor).setFill()
            NSBezierPath(roundedRect: nodeRect, xRadius: 8, yRadius: 8).fill()
            (belief.isCore ? goldColor : borderColor).setStroke()
            NSBezierPath(roundedRect: nodeRect, xRadius: 8, yRadius: 8).stroke()

            let textY = pageRect.height - y - nodeHeight + 8
            belief.text.draw(in: NSRect(x: x + 8, y: textY, width: nodeWidth - 16, height: 44), withAttributes: [.font: nodeFont, .foregroundColor: whiteColor])

            let scoreColor: NSColor = belief.score >= 70 ? greenColor : belief.score >= 40 ? goldColor : redColor
            "\(Int(belief.score))%".draw(at: CGPoint(x: x + 8, y: pageRect.height - y - 24), withAttributes: [.font: headerFont, .foregroundColor: scoreColor])
            "\(belief.supportingCount) for · \(belief.contradictingCount) against".draw(at: CGPoint(x: x + 50, y: pageRect.height - y - 24), withAttributes: [.font: footerFont, .foregroundColor: grayColor])
        }

        "Generated by Axiom".draw(at: CGPoint(x: margin, y: 30), withAttributes: [.font: footerFont, .foregroundColor: grayColor])

        NSGraphicsContext.restoreGraphicsState()
        pdfContext.endPage()
        pdfContext.closePDF()

        let fileURL = reportsDirectory.appendingPathComponent("Axiom_BeliefMap.pdf")
        do {
            try pdfData.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            return nil
        }
    }

    func listReports() -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(at: reportsDirectory, includingPropertiesForKeys: [.creationDateKey]) else { return [] }
        return files.filter { $0.pathExtension == "pdf" }.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            return d1 > d2
        }
    }
}
