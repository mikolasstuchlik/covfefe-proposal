import XCTest
import Covfefe
@testable import Grammar

final class GrammarTests: XCTestCase {
    
    func testCustomGrammar() {
        // Element: Grammar
        
        let (  grammar,    grammarEntry,      grammarEntyContent,      entity  ) =
            (%"grammar", %"grammar-entry", %"grammar-entry-content", %"entity")

        let (  grammar,    grammarEntry,      grammarEntyContent,  ) =
            (%"grammar", %"grammar-entry", %"grammar-entry-content")
        
        // Element: namespace (egnored)
        let (  namespace ) =
            (%"namespace")

        // Element: documentation
        let (  doc,    docContent  ) =
            (%"doc", %"doc-content")
        
        // Document support
        let (  entry,     lineEndingAndBegin    ) =
            (%"entry",  %"line-ending-and-begin")
        
        // Utility and primitives
        let (  char,    newLine,     symbol,    whiteSpace,     whiteSpaceNl   ) =
            (%"char", %"new-line", %"symbol", %"white-space", %"white-space-nl")
        
        let grammarDsl = GrammarDsl.build {
            grammar
                → ^"grammar" .. whiteSpaceNl+ .. ^"{" .. whiteSpaceNl+ .. grammarEntry .. whiteSpaceNl+ .. entity+ .. whiteSpaceNl+ .. ^"}" .. lineEndingAndBegin
            
            grammarEntry
                → ^"start" .. whiteSpaceNl+ .. ^"=" .. whiteSpaceNl+ .. grammarEntyContent .. lineEndingAndBegin
            
            grammarEntyContent
                → char+
            
            entity
                → (symbol | char | whiteSpace | newLine)
            
            namespace
                → (^"default" .. whiteSpace+)-? .. ^"namespace" .. whiteSpace+ .. (symbol | char) .. (symbol | char | whiteSpace)* .. (symbol | char)-? .. lineEndingAndBegin


            docContent
                → (symbol | char) .. (symbol | char | whiteSpace)* .. (symbol | char)-?
            
            doc
                → ^"##" .. whiteSpace* .. docContent-? .. lineEndingAndBegin


            entry
                → whiteSpaceNl* .. (doc | namespace)* .. grammar-?

            lineEndingAndBegin
                → whiteSpace* .. newLine .. (whiteSpace | newLine)*


            char
                → TerminalRange(from: "A", to: "Z")
                | TerminalRange(from: "a", to: "z")
                | TerminalRange(from: "0", to: "9")
            
            newLine
                → ^"\\n"
            
            symbol
                → ^["|", "+", "@", "#", "$", "~", "^", "&", "*", "{", "}", "°", "^", "[", "]", ";", "'", "<", ">", "–", "_", ":", "?", "!", "\\\"", "\\\\", "(", ")", "/", "%", "=", ".", ",", "-"]
            
            whiteSpace
                → ^CharacterSet.whitespaces
            
            whiteSpaceNl
                → whiteSpace | newLine
            
        }

        let ebnfGrammar = try! Grammar(ebnf: grammarDsl.description, start: entry.description)
        
        print(grammarDsl.description)
        
        let parser = EarleyParser(grammar: ebnfGrammar)

        _ = try! parser.syntaxTree(for: gir_grammar)
       
    }

    static var allTests = [
        ("testCustomGrammar", testCustomGrammar)
    ]
}

/*
       syntaxTree.allNodes { $0.name == doc.name }.forEach { (tree) in
           tree.allNodes { $0.name == docContent.name }.forEach { (subTree) in
               print(subTree.mapLeafs { gir_doc_only[$0] }.leafs.joined() )
           }
       }*/
