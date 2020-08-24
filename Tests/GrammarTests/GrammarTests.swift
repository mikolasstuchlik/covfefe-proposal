import XCTest
import Covfefe
@testable import Grammar

final class GrammarTests: XCTestCase {
    func testExample() {
        let grammarDsl = GrammarDsl.build {
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

    func testPrecedence() {
        let grammarDsl = GrammarDsl.build {
            %"person"   → %"name" .. %"space" | %"name" | %"name2" .. ^"aaa"
        }
        print(grammarDsl.description)
        
    }
    
    // https://www.oasis-open.org/committees/relax-ng/compact-20020607.html
    
    func testRelaxNGCompact() {
        let grammarDsl1 = GrammarDsl.build {
            %"topLevel"
                → (%"decl")* .. ( %"pattern" | (%"grammarContent")*)

            %"decl"
                →  ^"namespace" .. %"identifierOrKeyword" .. ^"=" .. %"namespaceUri"
                | ^"default" .. ^"namespace" .. (%"identifierOrKeyword")-? .. ^"=" .. %"namespaceUri"
                | ^"datatypes" .. %"identifierOrKeyword" .. ^"=" .. %"literal"

            %"pattern"
                → ^"element" .. %"nameClass" .. ^"{" .. %"pattern" .. ^"}"
                | ^"attribute" .. %"nameClass" .. ^"{" .. %"pattern" .. ^"}"
                | %"pattern" .. (^"," .. ^"pattern")+
                | %"pattern" ..  (^"&" .. %"pattern")+
                | %"pattern" .. (^"|" .. %"pattern")+
                | %"pattern" .. ^"?"
                | %"pattern" .. ^"*"
                | %"pattern" .. ^"+"
                | ^"list" .. ^"{" .. %"pattern" .. ^"}"
                | ^"mixed" .. ^"{" .. %"pattern" .. ^"}"
                | %"identifier"
                | ^"parent" .. %"identifier"
                | ^"empty"
                | ^"text"
                | (%"datatypeName")-? .. %"datatypeValue"
                | %"datatypeName" .. (^"{" .. (%"param")* .. ^"}")-? .. (%"exceptPattern")-?
                | ^"notAllowed"
                | ^"externalRef" .. %"uri" .. (%"inherit")-?
                | ^"grammar" .. ^"{" .. (%"grammarContent")* .. ^"}"
                | ^"(" .. %"pattern" .. ^")"
        }

        let grammarDsl2 = GrammarDsl.build {
            %"param"
                → %"identifierOrKeyword" .. ^"=" .. %"literal"

            %"exceptPattern"
                → ^"-" .. %"pattern"

            %"grammarContent"
                → ^"start"
                | %"define"
                | ^"div" .. ^"{" .. (%"grammarContent")* .. ^"}"
                | ^"include" .. %"uri" .. (%"inherit")-? .. (^"{" .. (%"includeContent")* .. ^"}")-?

            %"includeContent"
                → %"define"
                | %"start"
                | ^"div" .. ^"{" .. (%"includeContent")* .. ^"}"
        }

        let grammarDsl3 = GrammarDsl.build {
            %"start"
                → ^"start" .. %"assignMethod" .. %"pattern"

            %"define"
                → %"identifier" .. %"assignMethod" .. %"pattern"

            %"assignMethod"
                → ^"="
                | ^"|="
                | ^"&="

            %"nameClass"
                → %"name"
                | %"nsName" .. (%"exceptNameClass")-?
                | %"anyName" .. (%"exceptNameClass")-?
                | %"nameClass" .. ^"|" .. %"nameClass"
                | ^"(" .. %"nameClass" .. ^")"

        }
            
        let grammarDsl4 = GrammarDsl.build {
            %"name"
                → %"identifierOrKeyword"
                | %"CName"

            %"exceptNameClass"
                → ^"-" .. %"nameClass"

            %"datatypeName"
                → %"CName"
                | ^"string"
                | ^"token"

            %"datatypeValue"
                → %"literal"

            %"uri"
                → %"literal"

            %"namespaceUri"
                → %"literal"
                | ^"inherit"

            %"inherit"
                → ^"inherit" .. ^"=" .. %"identifierOrKeyword"

            %"identifierOrKeyword"
                → ^"identifier"
                | ^"keyword"

        }
                
        let grammarDsl5 = GrammarDsl.build {
            %"identifier"
                → %"NCName" // TODO Set operation: (NCName - keyword)
                | %"quotedIdentifier"

            %"quotedIdentifier"
                → ^"\\" .. %"NCName"

            %"CName"
                → %"NCName" .. ^":" .. %"NCName"

            %"nsName"
                → %"NCName" .. ^":*"

            %"anyName"
                → ^"*"

            %"literal"
                → (%"literalSegment")+

            %"literalSegment"
                → ^"\"" .. (%"Char")* .. ^"\""  //TODO Set operation: '"' (Char - '"')* '"'
                | ^"'" .. (%"Char")* .. ^"'"

            %"keyword"
                → ^"attribute"
                | ^"default"
                | ^"datatypes"
                | ^"div"
                | ^"element"
                | ^"empty"
                | ^"externalRef"
                | ^"grammar"
                | ^"include"
                | ^"inherit"
                | ^"list"
                | ^"mixed"
                | ^"namespace"
                | ^"notAllowed"
                | ^"parent"
                | ^"start"
                | ^"string"
                | ^"text"
                | ^"token"
        }
        
        let extensionDsl = GrammarDsl.build {
            %"Char"
                → TerminalRange(from: "A", to: "Z")
                | TerminalRange(from: "a", to: "z")
                | TerminalRange(from: "0", to: "9")

            %"whitespaces"
                → ^CharacterSet.whitespaces
                | ^"\\n"

            %"NCName"
                → (%"Char")+

        }
        
        print(extensionDsl.description)
        
        let finalGrammar = [grammarDsl1, grammarDsl2, grammarDsl3, grammarDsl4, grammarDsl5, extensionDsl].reduce(GrammarDsl.empty, GrammarDsl.formUnion(from:and:))
        
        let grammar = try! Grammar(ebnf: finalGrammar.description, start: "topLevel")
        
        let parser = EarleyParser(grammar: grammar)

        let syntaxTree = try! parser.syntaxTree(for: gir)
        
    }

    static var allTests = [
        ("testExample", testExample),
        ("testRelaxNGCompact", testRelaxNGCompact),
        ("testPrecedence", testPrecedence)
    ]
}
