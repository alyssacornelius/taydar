# Repository Guidelines

## Project Structure & Module Organization
The app target lives in `taydar/`. Core source files are currently `taydar/AppDelegate.swift` and `taydar/ContentView.swift`. App assets are stored in `taydar/Assets.xcassets/`. Xcode project settings, target configuration, and build metadata live in `taydar.xcodeproj/project.pbxproj`.

This repository does not currently include a separate test target, supporting frameworks, or docs folder. If you add new features, keep UI and app lifecycle code in small focused Swift files under `taydar/` and group related assets in `Assets.xcassets`.

## Build, Test, and Development Commands
Use Xcode for routine development or `xcodebuild` from the repo root for repeatable CLI builds:

- `open taydar.xcodeproj` opens the project in Xcode.
- `xcodebuild -project taydar.xcodeproj -scheme taydar -configuration Debug build` performs a local Debug build.
- `xcodebuild -project taydar.xcodeproj -scheme taydar -configuration Release build` verifies the Release configuration.
- `xcodebuild -project taydar.xcodeproj -scheme taydar clean` clears derived build products for the project.

If you add a test target, document the simulator destination and test command here.

## Coding Style & Naming Conventions
Follow standard Swift conventions: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties and methods, and one primary type per file when practical. Keep SwiftUI views declarative and small; extract helpers when `body` becomes dense.

No formatter or linter is checked in today. Format code using Xcode’s built-in indentation tools and keep imports minimal and ordered consistently.

## Testing Guidelines
There are no automated tests in the repository yet. New logic should ship with an XCTest target when feasible, with test files named after the unit under test, for example `ContentViewTests.swift`. Prefer focused tests for view-independent logic and keep manual validation notes in pull requests until automated coverage exists.

## Commit & Pull Request Guidelines
Git history currently starts with a short, imperative commit message: `Initial Commit`. Continue that style with concise subjects such as `Add plane detection helper` or `Refine RealityView placement`.

Pull requests should include:

- a short description of the change and its user impact,
- linked issue or task reference when applicable,
- screenshots or screen recordings for UI or AR changes,
- notes on how the change was built and tested locally.
