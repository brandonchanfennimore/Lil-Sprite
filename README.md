# LittleSprite – macOS Desktop Pet

LittleSprite is a macOS desktop overlay application built using SwiftUI and AppKit.  
It renders a persistent animated sprite that moves across the screen using a borderless, transparent, always-on-top window.

## Overview

This project explores system-level window management and animation logic on macOS. The application uses SwiftUI for view rendering and AppKit for custom window configuration, enabling overlay behavior above standard application windows.

## Features

- Floating, always-on-top sprite window
- Borderless and transparent window configuration
- State-driven animation logic (walking, idle, directional transitions)
- Continuous movement across screen boundaries
- Dynamic sprite positioning using screen coordinate calculations

## Architecture

The application separates responsibilities into:

- **SwiftUI View Layer** — Handles sprite rendering and animation state
- **AppKit Window Controller** — Manages window configuration (borderless, floating level, transparency)
- **State Management Logic** — Controls animation cycles and directional behavior

This design enables flexibility for future interactive features.

## Technical Details

- Built with Swift
- Uses SwiftUI for UI rendering
- Integrates AppKit for low-level window control
- Custom window level configuration (`.floating`)
- Transparent background with disabled window shadow
- Borderless style mask for overlay effect

## Future Improvements

- User interaction events (click-to-react, drag behavior)
- Customizable sprite assets
- Settings panel for speed and behavior configuration
- Multi-sprite support
- Persistent configuration storage
