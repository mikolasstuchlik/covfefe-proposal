infix operator → : AssignmentPrecedence

func →(_ nonTerminal: NonTerminal, _ prouct: Product) -> Production {
    Production(nonTerminal: nonTerminal, product: prouct)
}

func →(_ nonTerminal: NonTerminal, _ prouct: Product) -> Grammar {
    Grammar(grammar: [Production(nonTerminal: nonTerminal, product: prouct)])
}

prefix operator %

prefix func %(_ name: String) -> NonTerminal {
    NonTerminal(name: name)
}

prefix operator ^

prefix func ^(_ content: String) -> Terminal {
    Terminal(content: content)
}

infix operator .. : AdditionPrecedence

func ..(_ lProduct: Product, _ rProduct: Product ) -> StringProduct {
    StringProduct(string: [lProduct, rProduct])
}

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
    let content: String

    var description: String {
        "'\(content)'"
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

struct Grammar: CustomStringConvertible {
    let grammar: [Production]
    
    var description: String {
        grammar.map { $0.description }.joined(separator: "\n")
    }

    static func build(@GrammarBuilder builder: () -> Grammar) -> Grammar {
        builder()
    }
}

@_functionBuilder
enum GrammarBuilder {
    static func buildBlock(_ components: Production...) -> Grammar {
        var grammar = [NonTerminal:Product]()
        for item in components {
            guard let existing = grammar[item.nonTerminal] else {
                grammar[item.nonTerminal] = item.product
                continue
            }
            
            grammar[item.nonTerminal] = OptionProduct(concat: item.product, with: existing)
        }
        
        return Grammar(grammar: grammar.map(Production.init(nonTerminal:product:)))
    }
}
