(comment) @comment

[ "{" "}" "[" "]" ] @punctuation.bracket

(string_literal) @string
(escape_sequence) @string.escape
(integer_literal) @value.number

"*" @operator

(module_declaration "module" @keyword)
(requires_declaration "requires" @keyword)
(header_declaration "header" @keyword)
(header_declaration "umbrella" @keyword.modifier)
(header_attribute [ "size" "mtime" ] @keyword)
(umbrella_dir_declaration "umbrella" @keyword)
(inferred_submodule_declaration "module" @keyword)
(export_declaration "export" @keyword)
(export_as_declaration "export_as" @keyword)
(use_declaration "use" @keyword)
(link_declaration "link" @keyword)
(config_macros_declaration "config_macros" @keyword)
(conflict_declaration "conflict" @keyword)
(inferred_submodule_member "export" @keyword)

[
  "explicit"
  "framework"
  "extern"
  "private"
  "textual"
] @keyword.modifier

(module_id (identifier) @identifier.type)
(module_declaration (module_id (identifier) @identifier.type.declare))

(attribute (identifier) @identifier.property)

(feature "!" @operator)
(feature (identifier) @identifier.property)

(config_macro_list (identifier) @processing.directive)
