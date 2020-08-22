import XCTest
import Covfefe
@testable import Grammar

final class GrammarTests: XCTestCase {
    func testExample() {
        let string = foo().description
        print(string)
        let grammar = try! Covfefe.Grammar(ebnf: string, start: "obcan")
        
        let parser = EarleyParser(grammar: grammar)

        let syntaxTree = try! parser.syntaxTree(for: "Matěj Kašpar Jirásek")
        print(syntaxTree)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
