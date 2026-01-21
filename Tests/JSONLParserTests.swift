import XCTest
@testable import ClaudeCodeMonitor

final class JSONLParserTests: XCTestCase {
    var parser: JSONLParser!

    override func setUp() {
        super.setUp()
        parser = JSONLParser()
    }

    func testParseValidJSONL() throws {
        let jsonl = """
        {"type":"assistant","timestamp":"2026-01-13T02:48:11.866Z","sessionId":"test-session","message":{"role":"assistant","usage":{"input_tokens":100,"cache_creation_input_tokens":200,"cache_read_input_tokens":300,"output_tokens":50}}}
        {"type":"user","timestamp":"2026-01-13T02:48:10.866Z","sessionId":"test-session","message":{"role":"user"}}
        """

        let entries = try parser.parse(content: jsonl)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].type, "assistant")
        XCTAssertEqual(entries[0].sessionId, "test-session")
        XCTAssertNotNil(entries[0].message?.usage)
    }

    func testParseEmptyLines() throws {
        let jsonl = """
        {"type":"assistant","timestamp":"2026-01-13T02:48:11.866Z","sessionId":"test","message":{"usage":{"input_tokens":10,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":5}}}

        {"type":"assistant","timestamp":"2026-01-13T02:48:12.866Z","sessionId":"test","message":{"usage":{"input_tokens":20,"cache_creation_input_tokens":0,"cache_read_input_tokens":0,"output_tokens":10}}}
        """

        let entries = try parser.parse(content: jsonl)
        XCTAssertEqual(entries.count, 2)
    }

    func testTokenWeighting() {
        let usage = LogEntry.Usage(
            inputTokens: 100,
            cacheCreationInputTokens: 200,
            cacheReadInputTokens: 1000,
            outputTokens: 50
        )

        // 100 + 200 + 50 + (1000 * 0.1) = 450
        XCTAssertEqual(usage.weightedTotal, 450.0, accuracy: 0.01)
    }

    func testDateParsing() {
        let entry = LogEntry(
            type: "assistant",
            timestamp: "2026-01-13T02:48:11.866Z",
            sessionId: "test",
            message: nil,
            uuid: "123"
        )

        XCTAssertNotNil(entry.date)
    }
}
