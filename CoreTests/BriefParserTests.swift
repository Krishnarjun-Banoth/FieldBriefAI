import XCTest
@testable import FieldBriefCore

final class BriefParserTests: XCTestCase {
    func testPreservesMoreThanFiveActionsThroughParsingAndExport() throws {
        let tasks = (1...7).map { ["task": "Task \($0)", "owner": "Person \($0)", "due": "Friday"] }
        let data = try JSONSerialization.data(withJSONObject: ["title": "Inspection", "summary": "Seven commitments", "actions": tasks])
        let brief = try BriefParser.parse(String(decoding: data, as: UTF8.self))
        XCTAssertEqual(brief.actions.count, 7)
        XCTAssertEqual(brief.actions.last?.owner, "Person 7")
        XCTAssertTrue(brief.markdown.contains("Task 7"))
    }

    let fixture = #"{"title":"Site meeting","summary":"Met the client to review onboarding.","decisions":["Pilot first"],"actions":[{"task":"Share pilot scope","owner":"Asha","due":"Friday"}],"risks":[],"openQuestions":["Who signs off?"]}"#

    func testDecodesStructuredBrief() throws {
        let result = try BriefParser.parse(fixture)
        XCTAssertEqual(result.title, "Site meeting")
        XCTAssertEqual(result.actions.first?.owner, "Asha")
        XCTAssertEqual(result.decisions, ["Pilot first"])
    }

    func testParsesFencedJSON() throws {
        XCTAssertEqual(try BriefParser.parse("```json\n\(fixture)\n```").title, "Site meeting")
    }

    func testRejectsNonJSONResponse() {
        XCTAssertThrowsError(try BriefParser.parse("Looks good!"))
    }

    func testRejectsMissingRequiredField() {
        XCTAssertThrowsError(try BriefParser.parse(#"{"summary":"Hi"}"#))
    }

    func testRejectsEmptyTitle() {
        XCTAssertThrowsError(try BriefParser.parse(#"{"title":"  ","summary":"Hi"}"#))
    }

    func testDropsBlankOptionalItems() throws {
        let brief = try BriefParser.parse(#"{"title":"A","summary":"B","decisions":["", "  Yes  "],"actions":[{"task":" "},{"task":"Follow up"}]}"#)
        XCTAssertEqual(brief.decisions, ["Yes"])
        XCTAssertEqual(brief.actions.map(\.task), ["Follow up"])
    }

    func testRendersMarkdownWithOwnerAndDueDate() throws {
        let rendered = try BriefParser.parse(fixture).markdown
        XCTAssertTrue(rendered.contains("Person responsible: Asha"))
        XCTAssertTrue(rendered.contains("Due: Friday"))
        XCTAssertTrue(rendered.contains("## To confirm"))
    }

    func testDoesNotGenerateEmptyMarkdownSections() {
        let document = FieldBrief(title: "T", summary: "S")
        XCTAssertFalse(document.markdown.contains("## Risks"))
    }
}
