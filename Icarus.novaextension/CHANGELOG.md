## Version 2.0.1

- Fixed an issue preventing some header files from opening with the C syntax.

## Version 2.0

- Added remote debugging support with LLDB, for debugging targets running on another computer, in a Docker container, etc. ([https://github.com/panicinc/icarus/issues/4](#4))
- Added language support for Make, CMake, Strings, and Clang Module Map files.
- Resolved an issue preventing LLDB launch arguments from working properly.
- Added a configuration option for choosing the working directory of launched debugging targets.
- Improved highlighting for Swift language features introduced in 5.9 / 5.10, such as actors, async/await, and macros.
- Added highlighting for hashbang lines in Swift files.
- Improved highlighting of the Swift core metatypes: Any, AnyClass, AnyObject, Type, and Protocol.
- Fixed an issue preventing Swift protocol declarations from showing up as symbols and foldable.
- Fixed an issue preventing Swift computed properties from showing up as foldable.
- Migrated to a more robust Objective-C grammar, and rebased the Objective-C++ support on it.
- Additional improvements to highlighting and symbolication for Swift and C++.

## Version 1.0.2

- Fixed an issue with C++ namespace highlight queries which could cause all C++ to fail to work properly.

## Version 1.0.1

- Fixed an issue with the file permissions of the debug adapter executable, which prevented it from being launched after the extension was installed.

## Version 1.0

- Initial release
