import Foundation
import RobinHood
import CDMarkdownKit
import UIKit

protocol MarkdownParsingOperationFactoryProtocol {
    func createParseOperation(
        for string: String,
        preferredWidth: CGFloat
    ) -> BaseOperation<MarkupAttributedText>
}

final class MarkdownParsingOperationFactory: MarkdownParsingOperationFactoryProtocol {
    let maxSize: Int?

    init(maxSize: Int?) {
        self.maxSize = maxSize
    }

    private func createMarkdownParser(for preferredWidth: CGFloat, imageDetectionEnabled: Bool) -> CDMarkdownParser {
        let textParagraphStyle = NSMutableParagraphStyle()
        textParagraphStyle.paragraphSpacing = 8
        textParagraphStyle.paragraphSpacingBefore = 8
        let listParagraphStyle = NSMutableParagraphStyle()
        listParagraphStyle.paragraphSpacing = 2
        listParagraphStyle.paragraphSpacingBefore = 0
        listParagraphStyle.firstLineHeadIndent = 0
        listParagraphStyle.lineSpacing = 0

        let parser = CDMarkdownParser(
            font: CDFont.systemFont(ofSize: 15),
            fontColor: R.color.colorTextSecondary()!,
            paragraphStyle: textParagraphStyle,
            imageDetectionEnabled: imageDetectionEnabled
        )

        parser.bold.color = R.color.colorTextSecondary()!
        parser.bold.backgroundColor = nil
        parser.header.color = R.color.colorTextPrimary()!
        parser.header.backgroundColor = nil
        parser.list.color = R.color.colorTextSecondary()!
        parser.list.backgroundColor = nil
        parser.list.paragraphStyle = listParagraphStyle
        parser.quote.color = R.color.colorTextSecondary()
        parser.quote.backgroundColor = nil
        parser.link.color = R.color.colorButtonTextAccent()!
        parser.link.backgroundColor = nil
        parser.automaticLink.color = R.color.colorButtonTextAccent()!
        parser.automaticLink.backgroundColor = nil
        parser.italic.color = R.color.colorTextSecondary()!
        parser.italic.backgroundColor = nil
        let codeParagraphStyle = NSMutableParagraphStyle()
        parser.code.font = UIFont.systemFont(ofSize: 15)
        parser.code.color = R.color.colorTextPrimary()!
        parser.code.backgroundColor = UIColor(white: 20.0 / 256.0, alpha: 1.0)
        parser.code.paragraphStyle = codeParagraphStyle
        parser.syntax.font = UIFont.systemFont(ofSize: 15)
        parser.syntax.color = R.color.colorTextPrimary()!
        parser.syntax.backgroundColor = UIColor(white: 20.0 / 256.0, alpha: 1.0)

        // library uses only width internally and adjusts the height of the image
        parser.image.size = CGSize(width: preferredWidth, height: 0)

        return parser
    }

    private func createOperation(
        for string: String,
        preferredWidth: CGFloat,
        maxSize: Int?
    ) -> BaseOperation<MarkupAttributedText> {
        ClosureOperation<MarkupAttributedText> {
            let attributedString: NSAttributedString
            let isFull: Bool

            if let maxSize = maxSize {
                let preprocessed = String(string.prefix(4 * maxSize))
                let parser = self.createMarkdownParser(for: preferredWidth, imageDetectionEnabled: false)
                let resultString = parser.parse(preprocessed)

                attributedString = resultString.truncate(maxLength: maxSize)
                isFull = resultString.length <= maxSize
            } else {
                isFull = true
                let parser = self.createMarkdownParser(for: preferredWidth, imageDetectionEnabled: true)
                attributedString = parser.parse(string)
            }

            let preferredHeight = attributedString.boundingRect(
                with: CGSize(width: preferredWidth, height: 0),
                options: .usesLineFragmentOrigin,
                context: nil
            ).height

            let preferredSize = CGSize(width: preferredWidth, height: preferredHeight)

            return .init(
                originalString: string,
                attributedString: attributedString,
                preferredSize: preferredSize,
                isFull: isFull
            )
        }
    }

    func createParseOperation(
        for string: String,
        preferredWidth: CGFloat
    ) -> BaseOperation<MarkupAttributedText> {
        createOperation(for: string, preferredWidth: preferredWidth, maxSize: maxSize)
    }
}
