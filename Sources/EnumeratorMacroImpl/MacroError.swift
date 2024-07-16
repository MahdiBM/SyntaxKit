import SwiftDiagnostics
import SwiftSyntax

enum MacroError: Error, CustomStringConvertible {
    case isNotEnum
    case macroDeclarationHasNoArguments
    case unacceptableArguments
    case expectedAtLeastOneArgument
    case allArgumentsMustBeNonInterpolatedStringLiterals
    case renderedSyntaxContainsErrors(String)
    case couldNotFindLocationOfNode(syntax: String)
    case mustacheTemplateError(message: String)
    case internalError(String)
    case invalidTransform(transform: String, normalizedTypeName: String)

    var caseName: String {
        switch self {
        case .isNotEnum:
            "isNotEnum"
        case .macroDeclarationHasNoArguments:
            "macroDeclarationHasNoArguments"
        case .unacceptableArguments:
            "unacceptableArguments"
        case .expectedAtLeastOneArgument:
            "expectedAtLeastOneArgument"
        case .allArgumentsMustBeNonInterpolatedStringLiterals:
            "allArgumentsMustBeNonInterpolatedStringLiterals"
        case .renderedSyntaxContainsErrors:
            "renderedSyntaxContainsErrors"
        case .couldNotFindLocationOfNode:
            "couldNotFindLocationOfNode"
        case .mustacheTemplateError:
            "mustacheTemplateError"
        case .internalError:
            "internalError"
        case .invalidTransform:
            "invalidTransform"
        }
    }

    var description: String {
        switch self {
        case .isNotEnum:
            "Only enums are supported"
        case .macroDeclarationHasNoArguments:
            "The macro declaration needs to have at least 1 String-Literal argument"
        case .unacceptableArguments:
            "The arguments passed to the macro were unacceptable"
        case .expectedAtLeastOneArgument:
            "At least one argument of type StaticString is required"
        case .allArgumentsMustBeNonInterpolatedStringLiterals:
            "All arguments must be non-interpolated string literals."
        case let .renderedSyntaxContainsErrors(syntax):
            "Rendered syntax contains errors:\n\(syntax)"
        case let .couldNotFindLocationOfNode(syntax):
            "Could not find location of node for syntax:\n\(syntax)"
        case let .mustacheTemplateError(message):
            "Error while rendering the template: \(message)"
        case let .internalError(message):
            "An internal error occurred. Please file a bug report at https://github.com/mahdibm/enumerator-macro. Error:\n\(message)"
        case let .invalidTransform(transform, normalizedTypeName):
            """
            Invalid function call detected.
            '\(normalizedTypeName)' doesn't have a function called '\(transform)'
            """
        }
    }
}

extension MacroError: DiagnosticMessage {
    var message: String {
        self.description
    }

    var diagnosticID: MessageID {
        .init(domain: "EnumeratorMacro.MacroError", id: self.caseName)
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
