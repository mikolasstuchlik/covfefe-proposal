import Foundation

infix operator → : AssignmentPrecedence

func →(_ nonTerminal: NonTerminal, _ prouct: Product) -> Production {
    Production(nonTerminal: nonTerminal, product: prouct)
}

func →(_ nonTerminal: NonTerminal, _ prouct: Product) -> GrammarDsl {
    GrammarDsl(grammar: [Production(nonTerminal: nonTerminal, product: prouct)])
}

prefix operator %

prefix func %(_ name: String) -> NonTerminal {
    NonTerminal(name: name)
}

prefix operator ^

prefix func ^(_ content: String) -> Terminal {
    Terminal(content: content)
}

prefix func ^<T: Sequence>(_ content: T) -> OptionProduct where T.Element: StringProtocol {
    OptionProduct(list: content.map { Terminal(content: "\($0)") } )
}

prefix func ^(_ content: CharacterSet) -> OptionProduct {
    ^content.allCharacters().map { $0.description }
}

infix operator .. : MultiplicationPrecedence

func ..(_ lProduct: Product, _ rProduct: Product ) -> StringProduct {
    StringProduct(string: [lProduct, rProduct])
}

infix operator | : AdditionPrecedence
func |(_ lProduct: Product, _ rProduct: Product) -> OptionProduct {
    OptionProduct(concat: lProduct, with: rProduct)
}

postfix operator +
postfix func +(_ product: Product) -> PositiveIterationProduct {
    PositiveIterationProduct(product: product)
}

postfix operator *
postfix func *(_ product: Product) -> IterationProduct {
    IterationProduct(product: product)
}

postfix operator -?
postfix func -?(_ product: Product) -> OptionalProduct {
    OptionalProduct(product: product)
}

protocol Product: CustomStringConvertible { }

struct Production: CustomStringConvertible {
    let nonTerminal: NonTerminal
    let product: Product

    var description: String {
        "\(nonTerminal) = \(product);"
    }
}

struct NonTerminal: Product, Hashable {
    let name: String

    var description: String {
        "\(name)"
    }
}

struct Terminal: Product {
    static let ε = Terminal(content: "")

    let content: String

    var description: String {
        "\"\(content.covfefeEscaped)\""
    }
}

struct TerminalRange: Product {
    let start: Character
    let end: Character

    
    init(from start: Character, to end: Character) {
        self.start = start
        self.end = end
    }

    var description: String {
        "\"\(start)\" ... \"\(end)\""
    }
}

struct OptionProduct: Product {
    let list: [Product]

    var description: String {
        "(" + list.map { $0.description }.joined(separator: " | ") + ")"
    }
    
    init(list: [Product]) {
        self.list = list
    }
    
    init(concat leftProduct: Product, with rightProduct: Product) {
        switch (leftProduct as? OptionProduct, rightProduct as? OptionProduct) {
        case let (leftList?, rightList?):
            self = OptionProduct(list: leftList.list + rightList.list)
        case let (leftList?, nil):
            self = OptionProduct(list: leftList.list + [rightProduct])
        case let (nil, rightList?):
            self = OptionProduct(list: [leftProduct] + rightList.list)
        case (nil, nil):
            self = OptionProduct(list: [leftProduct, rightProduct])
        }
    }
}

struct StringProduct: Product {
    let string: [Product]

    var description: String {
        string.map { $0.description }.joined(separator: ", ")
    }
}

struct OptionalProduct: Product {
    let product: Product

    var description: String {
        "[\(product)]"
    }
}

struct IterationProduct: Product {
    let product: Product

    var description: String {
        "[{\(product)}]"
    }
}

struct PositiveIterationProduct: Product {
    let product: Product

    var description: String {
        "{\(product)}"
    }
}

struct GrammarDsl: CustomStringConvertible {
    static let empty = GrammarDsl(grammar: [])
    
    let grammar: [Production]
    
    var description: String {
        grammar.map { $0.description }.joined(separator: "\n")
    }

    static func build(@GrammarBuilder builder: () -> GrammarDsl) -> GrammarDsl {
        builder()
    }
    
    func union(with otherGrammar: GrammarDsl) -> GrammarDsl {
        let components = self.grammar + otherGrammar.grammar
        var newGrammar = [NonTerminal:Product]()
        for item in components {
            guard let existing = newGrammar[item.nonTerminal] else {
                newGrammar[item.nonTerminal] = item.product
                continue
            }
            
            newGrammar[item.nonTerminal] = OptionProduct(concat: item.product, with: existing)
        }
        
        return GrammarDsl(grammar: newGrammar.map(Production.init(nonTerminal:product:)))
    }
    
    static func formUnion(from lGrammar: GrammarDsl, and rGrammar: GrammarDsl) -> GrammarDsl {
        lGrammar.union(with: rGrammar)
    }
}

extension String {
    var covfefeEscaped: String {
        self.map { char -> String in
            switch char {
            case #"\"#:
                return #"\\"#
            case "\"":
                return "\\\""
            default:
                return String(char)
            }
        }.joined()
    }
}

extension CharacterSet {
    func allCharacters() -> [Character] {
        var result: [Character] = []
        for plane: UInt8 in 0...16 where self.hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), self.contains(uniChar) {
                    result.append(Character(uniChar))
                }
            }
        }
        return result
    }
}

@_functionBuilder
enum GrammarBuilder {
    static func buildBlock(_ components: Production...) -> GrammarDsl {
        return components.reduce(GrammarDsl.empty) { $0.union(with: GrammarDsl(grammar: [$1])) }
    }
}
