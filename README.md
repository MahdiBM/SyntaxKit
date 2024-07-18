<p align="center">
    <a href="https://github.com/MahdiBM/enumerator-macro/actions/workflows/tests.yml">
        <img src="https://github.com/MahdiBM/enumerator-macro/actions/workflows/tests.yml/badge.svg" alt="Tests Badge">
    </a>
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-6.0%20%2F%205.10-brightgreen.svg" alt="Latest/Minimum Swift Version">
    </a>
</p>

# EnumeratorMacro
A utility for creating case-by-case code for your Swift enums using the Mustache templating engine.   
`EnumeratorMacro` uses [swift-mustache](https://github.com/hummingbird-project/swift-mustache)'s flavor.

The macro will parse your enum code, and pass different info of your enum to the mustache template renderer.   
Then you can access each case-name, case-parameters etc.. in the template, and create code based on that.

## How Does Mustache Templating Work?

It's rather simple.
* Inject variables using the `{{variableName}}` syntax.
* Loop though arrays using the `{{#array}} {{/array}}` syntax.
* Apply if conditions using the `{{#boolean}} {{/boolean}}` syntax.
* Apply inverted if conditions using the `{{^boolean}} {{/boolean}}` syntax.
* Apply transformations using the "function call" syntax: `snakedCased(variable)`.
  *  Available transformations are mentioned below.
* Use `{{! comment here }}` syntax to write comments in the template.
* See [the reference](https://mustache.github.io/mustache.5.html) and the [swift-mustache docs](https://docs.hummingbird.codes/2.0/documentation/mustache) for more info.

## General Behavior

<details>
  <summary> Click to expand </summary>

`EnumeratorMacro` will:

* Remove empty lines from the final generated code, to get rid of possible excessive empty lines.
  * Search for the `testRemovesExcessiveTrivia()` test for an example. 
* Remove last trailing comma in a case switch, which is an error. For easier templating.
  * Search for the `testRemovesLastErroneousCommaInCaseSwitch()` test for an example.
* Emit helpful diagnostics whenever possible.
  * See the [Error Handling](#error-handling) section for more info.

</details>

## Examples

### Derive Case Names
```swift
@Enumerator("""
var caseName: String {
    switch self {
    {{#cases}}
    case .{{name}}: "{{name}}"
    {{/cases}}
    }
}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```diff
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)

+    var caseName: String {
+        switch self {
+        case .a: "a"
+        case .b: "b"
+        case .testCase: "testCase"
+        }
+    }
}
```

### Create a Subtype Enum

<details>
  <summary> Click to expand </summary>

```swift
@Enumerator("""
enum Subtype: String {
    {{#cases}}
    case {{name}}
    {{/cases}}
}
""",
"""
var subtype: Subtype {
    switch self {
    {{#cases}}
    case .{{name}}:
        .{{name}}
    {{/cases}}
    }
}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```diff
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)

+    enum Subtype: String {
+        case a
+        case b
+        case testCase
+    }

+    var subtype: Subtype {
+        switch self {
+        case .a:
+            .a
+        case .b:
+            .b
+        case .testCase:
+            .testCase
+        }
+    }
}
```

</details>

### Create Is-Case Properties

<details>
  <summary> Click to expand </summary>
    
```swift
@Enumerator("""
{{#cases}}
var is{{capitalized(name)}}: Bool {
    switch self {
    case .{{name}}: return true
    default: return false
    }
}
{{/cases}}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```diff
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)

+    var isA: Bool {
+        switch self {
+        case .a: return true
+        default: return false
+        }
+    }

+    var isB: Bool {
+        switch self {
+        case .b: return true
+        default: return false
+        }
+    }

+    var isTestCase: Bool {
+        switch self {
+        case .testCase: return true
+        default: return false
+        }
+    }
}
```

</details>
    
### Create a Copy of The Enum

<details>
  <summary> Click to expand </summary>
    
Not very practical but I'll leave it here for showcase for now.

```swift
@Enumerator("""
enum Copy {
    {{#cases}}
    case {{name}}{{withParens(joined(namesAndTypes(parameters)))}}
    {{/cases}}
}
""")
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```diff
enum TestEnum {
    case a(val1: String, val2: Int)
    case b
    case testCase(testValue: String)

+    enum Copy {
+        case a(val1: String, val2: Int)
+        case b
+        case testCase(testValue: String)
+    }
}
```

</details>

###  Create Functions For Each Case

```swift
@Enumerator("""
{{#cases}}
{{^isEmpty(parameters)}}
func get{{capitalized(name)}}() -> ({{joined(tupleValue(parameters))}})? {
    switch self {
    case let .{{name}}{{withParens(joined(names(parameters)))}}:
        return {{withParens(joined(names(parameters)))}}
    default:
        return nil
    }
}
{{/isEmpty(parameters)}}
{{/cases}}
""")
enum TestEnum {
    case a(val1: String, Int)
    case b
    case testCase(testValue: String)
}
```
Is expanded to:
```diff
enum TestEnum {
    case a(val1: String, Int)
    case b
    case testCase(testValue: String)

+    func getA() -> (val1: String, param2: Int)? {
+        switch self {
+        case let .a(val1, param2):
+            return (val1, param2)
+        default:
+            return nil
+        }
+    }

+    func getTestCase() -> (String)? {
+        switch self {
+        case let .testCase(testValue):
+            return (testValue)
+        default:
+            return nil
+        }
+    }
}
```

## Available Context Values

Here's a sample context object:

```json
{
    "cases": [
        {
            "index": 0,
            "name": "caseName",
            "parameters": {
                "name": "parameterName",
                "type": "parameterType",
                "isOptional": true
            }
        }
    ]
}
```

## Available Functions

Although not visible when writing templates, each underlying value that is passed to the template engine has an actual type.

In addition to [`swift-mustache`'s own "functions"/"transforms"](https://docs.hummingbird.codes/2.0/documentation/hummingbird/transforms/), `EnumeratorMacro` supports these transformations for each type:

* `String`:
  * `capitalized() -> String`: Capitalizes the first letter.
  * `snakeCased() -> String`: Converts the string from camelCase to snake_case.
  * `camelCased() -> String`: Converts the string from snake_case to camelCase.
  * `withParens() -> String`: If the string is not empty, surrounds it in parenthesis.
* `Int`:
  * `plusOne() -> Int`: Add one to the integer.
  * `minusOne() -> Int`: Subtract one from the integer.
  * `equalZero() -> Bool`: Returns whether the integer is equal to zero.
  * `odd() -> Bool`: Returns whether the integer is odd or not.
  * `even() -> Bool`: Returns whether the integer is even or not.
* `Array`:
  * `first() -> Element`: Returns the first element of the array.
  * `last() -> Element`: Returns the last element of the array.
  * `count() -> Int`:  Returns the number of the elements in the array.
  * `isEmpty() -> Bool`: Returns whether the array is empty or not.
  * `reversed() -> Self`: Returns a reversed array.
  * `sorted() -> Self`: Sorts the elements, if the elements of the array are comparable.
  * `joined() -> String`: Equivalent to `.joined(separator: ", ")`
  * `keyValues() -> Array<KeyValue>`: Parses the elements of the array as key-value pairs separated by ':'.
* `KeyValue`:
  * `key() -> String`: Returns the key. You could use Mustache-native {{key}} syntax as well.
  * `value() -> String`: Returns the value. You could use Mustache-native {{value}} syntax as well.
* `[Case]` (`cases`):
  * `filterNoParams() -> [Case]`: Filters-in the cases with no parameters.
  * `filterWithParams() -> [Case]`: Filters-in the cases with one or more parameters.
* `[Parameter]` (`parameters`):
  * `names() -> [String]`: Returns the names of the parameters.
    * `names(parameters)` -> `[param1, param2, param3]`.
  * `types() -> [String]`: Returns the types of the parameters.
    * Use with `joined`: `joined(types(parameters))` -> `(String, Int, Double)`.
  * `namesAndTypes() -> [String]`: Returns a string-array where each element is equivalent to `"\(name): \(type)"`.
    * Use with `joined`: `joined(namesAndTypes(parameters))` -> `(key: String)` or `(key: String, value: Int)`. 
  * `tupleValue() -> String`: Suitable to be used for making tuples from the parameters.
    * Use with `withParens`: `withParens(tupleValue(parameters))` -> `(String)` or `(key: String, value: Int)`. 

Feel free to suggest a function if you think it'll solve a problem.

## Error Handling

<details>
  <summary> Click to expand </summary>
    
In case there is an error in the expanded macro code, or in any other step of the code generation, `EnumeratorMacro` will try to emit diagnostics pointing to the line of the code which is the source of the issue.

For example, `EnumeratorMacro` will properly forward template render errors from the template engine to your source code.
In the example below, I've mistakenly written `{{cases}` instead of `{{cases}}`:

<kbd> <img width="767" alt="Screenshot 2024-07-13 at 12 09 16 AM" src="https://github.com/user-attachments/assets/6763cfd4-b435-4ffb-adc9-03912b09a3b3"> </kbd>


Or here, the expanded Swift code would result in a code with syntax error and the macro is preemprively reporting the error.
Here, I've supposedly forgot to write the `:` between `caseName` and `String`.

<kbd> <img width="768" alt="Screenshot 2024-07-13 at 12 10 19 AM" src="https://github.com/user-attachments/assets/97f177a4-e5a0-437f-b3f9-3e9ef902e744"> </kbd>


`EnumeratorMacro` can also catch an invalid function being used:

<kbd> <img width="824" alt="Screenshot 2024-07-17 at 6 44 41 PM" src="https://github.com/user-attachments/assets/d664830d-1897-4099-86b2-1c32d3f6def1"> </kbd>

</details>

## How To Add EnumeratorMacro To Your Project

To use the `EnumeratorMacro` library in a SwiftPM project, 
add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/MahdiBM/enumerator-macro", branch: "main"),
```

Include `EnumeratorMacro` as a dependency for your targets:

```swift
.target(name: "<target>", dependencies: [
    .product(name: "EnumeratorMacro", package: "enumerator-macro"),
]),
```

Finally, add `import EnumeratorMacro` to your source code.
