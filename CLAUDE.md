# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Eyesave is a native macOS application built with SwiftUI and Swift 5.0. Bundle ID: `nl.jkbs.eyesave`. Deployment target: macOS 26.2.

## Build Commands

```bash
# Build (Debug)
xcodebuild -project eyesave.xcodeproj -scheme eyesave -configuration Debug build

# Build (Release)
xcodebuild -project eyesave.xcodeproj -scheme eyesave -configuration Release build

# Clean
xcodebuild -project eyesave.xcodeproj -scheme eyesave clean
```

No test target is currently configured. No external package dependencies.

## Architecture

- **Entry point**: `eyesave/eyesaveApp.swift` — `@main` app struct using `WindowGroup` scene
- **UI**: `eyesave/ContentView.swift` — SwiftUI views
- **Assets**: `eyesave/Assets.xcassets/` — app icon and accent color

Single-window SwiftUI application. Strict concurrency and Main Actor isolation are enabled. App Sandbox is on with readonly user file access.
