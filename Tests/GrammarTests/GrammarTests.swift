import XCTest
import Covfefe
@testable import Grammar

final class GrammarTests: XCTestCase {
    func testExample() {
        let grammarDsl = Grammar.build {
            %"person"   → %"name" .. %"space" .. (%"name" .. %"space")-? .. %"surname"
            %"name"     → ^"Mikolas"
                        | ^"Jan"
                        | ^"Lukas"
            %"surname"  → ^"Stuchlik"
                        | ^"Dvorak"
            %"space"    → ^" "
        }
        
        let grammar = try! Grammar(ebnf: grammarDsl.description, start: "person")
        
        let parser = EarleyParser(grammar: grammar)

        let syntaxTree = try! parser.syntaxTree(for: "Mikolas Stuchlik")
        
        print(grammarDsl.description)
        
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
