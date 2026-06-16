# FitStreak

iOS app. SwiftUI + SwiftData, Swift Testing, targeting current iOS.

## Conventions

- Swift (latest stable). Use modern language features. No deprecated APIs.
- UI: SwiftUI. Flag it if you genuinely need UIKit.
- Persistence: SwiftData (`@Model`, `@Query`, `modelContext`). Not Core Data.
- Concurrency: async/await and structured concurrency.
- Prefer value types and `let`. Keep logic out of View bodies; use
  `@Observable` models. No force-unwraps in app code.

## Testing

- Swift Testing (`@Test`, `#expect`). Not XCTest.
- Test-drive logic (models, calculations, persistence): failing test first,
  then implement. Do not unit-test SwiftUI views; iterate those visually
  against previews and the simulator.

## Tooling (Xcode MCP)

- Build with `BuildProject`, not raw `xcodebuild`.
- Run tests with `RunAllTests` / `RunSomeTests`.
- Inspect UI with `RenderPreview`.
- For Apple API questions, use `DocumentationSearch` and the SwiftUI Skills
  local docs rather than recalling from memory.

## Working agreement

- Build UI with sample data first, then wire up real SwiftData.
- Small commits per logical unit.
- Ask before adding any dependency.
