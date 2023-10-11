## Version 1.1

- Added remote debugging support with LLDB for setups such as another computer, a Docker container, etc. ([https://github.com/panicinc/icarus/issues/4](#4))
- Added syntax highlighting support for Make and CMake files.
- Resolved an issue preventing LLDB launch arguments from working properly.
- Migrated to a more robust Objective-C grammar, and rebased our Objective-C++ support on it as well.
- Additional improvements to syntax highlighting and symbolication for Swift and C++.

## Version 1.0.2

- Fixed an issue with C++ namespace highlight queries which could cause all C++ to fail to work properly.

## Version 1.0.1

- Fixed an issue with the file permissions of the debug adapter executable, which prevented it from being launched after the extension was installed.

## Version 1.0

- Initial release
