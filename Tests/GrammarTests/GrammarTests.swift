import XCTest
import Covfefe
@testable import Grammar

final class GrammarTests: XCTestCase {
    
    func testCustomGrammar() {
        let (  entry,    char,    newLine,     symbol,    lineEndingAndBegin,       whiteSpace,     doc,    docContent  ) =
            (%"entry", %"char", %"new-line", %"symbol", %"line-ending-and-begin", %"white-space", %"doc", %"doc-content")
        
        let (  documentBegin  ) =
            (%"document-begin")
        
        let grammarDsl = GrammarDsl.build {
            entry
                → documentBegin .. (doc)*
            
            doc
                → ^"##" .. whiteSpace* .. docContent-? .. lineEndingAndBegin-?
            
            docContent
                → (symbol | char) .. (symbol | char | whiteSpace)* .. (symbol | char)-?
            

            lineEndingAndBegin
                → whiteSpace* .. newLine .. (whiteSpace | newLine)*
            
            documentBegin
                → (whiteSpace | newLine)*
                    
            symbol
                → ^["|", "+", "@", "#", "$", "~", "^", "&", "*", "{", "}", "°", "^", "[", "]", ";", "'", "<", ">", "–", "_", ":", "?", "!", "\\\"", "\\\\", "(", ")", "/", "%"]
            
            whiteSpace
                → ^CharacterSet.whitespaces
            
            char
                → TerminalRange(from: "A", to: "Z")
                | TerminalRange(from: "a", to: "z")
                | TerminalRange(from: "0", to: "9")
            
            newLine
                → ^"\\n"
        }

        let grammar = try! Grammar(ebnf: grammarDsl.description, start: entry.description)
        
        let parser = EarleyParser(grammar: grammar)

        let syntaxTree = try! parser.syntaxTree(for: gir_doc_only)
        
        syntaxTree.allNodes { $0.name == doc.name }.forEach { (tree) in
            tree.allNodes { $0.name == docContent.name }.forEach { (subTree) in
                print(subTree.mapLeafs { gir_doc_only[$0] }.leafs.joined() )
            }
        }
    }

    static var allTests = [
        ("testCustomGrammar", testCustomGrammar)
    ]
}
