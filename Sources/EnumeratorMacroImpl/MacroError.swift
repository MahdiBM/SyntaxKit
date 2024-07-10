import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments
    case unacceptableArguments
    case expectedAtLeastOneArgument

    var description: String {
        switch self {
        case .isNotEnum:
            "Only enums are supported."
        case .macroDeclarationHasNoArguments:
            "The macro declaration needs to have at least 1 StringLiteral argument."
        case .unacceptableArguments:
            "The arguments passed to the macro were unacceptable."
        case .expectedAtLeastOneArgument:
            "At least one argument of type StaticString is required."
        }
    }
}

extension MacroError: DiagnosticMessage {
    var message: String {
        self.description
    }

    var diagnosticID: MessageID {
        .init(domain: "EnumeratorMacro.MacroError", id: self.description)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
