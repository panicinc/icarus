Icarus provides first-class language support for **Swift**, **C**, **C++**, and **Objective-C**.

If you are Swift or C-family language developer, Icarus can provide you with first-class support for building client- and server-side applications and frameworks.

✨ Fun fact: This extension's debugging support was built entirely using Nova and Icarus. _"Look ma, no Xcode!"_

## Features

Icarus adds:

- 🖍️ **Syntax highlighting**, symbolication, and code folding using Tree-sitter grammars
- 🧪 **Language intelligence**, completions, issues, and more via SourceKit-LSP
- 🐛 **Debugging** via LLDB both locally and on supported remote platforms

![](https://github.com/panicinc/icarus/raw/main/screenshot.png)

Intelligence is provided using [SourceKit-LSP](https://github.com/apple/sourcekit-lsp) from the Swift open-source project. This language server provides support for Swift natively and uses `clangd` behind the scenes for C-family languages.

Debugging is supported using _LLDB.framework_, distributed with both Apple's Xcode tools and the standalone Swift toolchain.

## Requirements

Syntax highlighting, symbolication, and code folding for all supported languages are included out of the box.

For language intelligence, completions, and debugging, a Swift toolchain is required (even if you are just working with C-family languages, as the toolchain provides support for everything).

- If you already have Apple's Xcode app in your `/Applications` folder, there should be nothing else you'll need to do.
- Otherwise, the easiest way to get started is to download Apple's Xcode command-line tools using `xcode-select --install`.
- Alternatively, you can install a [development version of the Swift toolchain](https://www.swift.org/download/) and select it for use in the extension preferences.

## C / C++ and Compile Commands

Projects utilizing the C or C++ languages may need to provide a `compile_commands.json` file in the project root for some language features to work. This file can be generated by most common build systems, including CMake. For more information, [check out the Clang documentation](https://clang.llvm.org/docs/JSONCompilationDatabase.html).

## Building, Running, and Debugging Your Project

### Local Debugging

To build and run your project, you will want to create a Task in Nova's tasks interface. Follow these steps for a quick way to get up and running:

1. Open your project settings by clicking your project name in the toolbar.
2. Next to "Tasks" in the settings list, click the plus button and choose **LLDB Debug** to add a new debugging task.
    - Name your task something descriptive if you'd like, such as the name of your built target, its configuration, etc.
    - Set the executable path to your product's path for running and debugging.
    - Tweak any additional options as needed, such as launch arguments.
3. Click the disclosure triangle beside your task to expand out the Pipeline options.
4. In the "Build" section, add one or more custom script steps to tell Nova how to interface with your build system.

For the Build pipeline step(s), it should just be a matter of adding the appropriate shell commands to a Build pipeline step to invoke and compile your target or product in the same way you'd build in a terminal.

### Remote Debugging

Similarly to local debugging, remote debugging uses a Task in Nova's tasks interface.

1. Open your project settings by clicking your project name in the toolbar.
2. Next to "Tasks" in the settings list, click the plus button and choose **LLDB Remote Debug** to add a new debugging task.
    - Name your task something descriptive if you'd like, such as the name of your built target, its configuration, etc.
    - Set the LLDB platform plugin to an appropriate value for the target destination (such as `remote-linux` for Linux hosts, Docker containers, etc.). You can choose a value from the drop-down list populated with those supported by locally-installed copy of LLDB.
    - Set the executable path to your product's path for running and debugging. Note: this is the path to the executable on the remote host.
    - Add one or more **path mappings** to tell Nova how to translate between your local filesystem and the remote filesystem of the target, for properly setting up breakpoints and translating stack frames.
    - Tweak any additional options as needed, such as launch arguments.
3. Click the disclosure triangle beside your task to expand out the Pipeline options.
4. In the "Build" section, add one or more custom script steps to tell Nova how to interface with your build system.
    - For building directly within a Docker container, using `docker exec <containerName> <command> <args…>` is a very useful way to invoke a build system.
    - For building locally, you may need to ensure cross-compilation support is set up within your build system and products are sync'd to the remote host.

For the Build pipeline step(s), it should just be a matter of adding the appropriate shell commands to a Build pipeline step to invoke and compile your target or product in the same way you'd build in a terminal.


