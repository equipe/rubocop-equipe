# rubocop-equipe

Shared RuboCop configuration for Equipe's Ruby projects, so the code looks the
same everywhere.

It builds on [rubocop-rails-omakase](https://github.com/rails/rubocop-rails-omakase),
the Rails default, and adds:

- Formatting of multiline code, following [Standard](https://github.com/standardrb/standard):
  fixed indentation for arguments, hashes, arrays and call chains. Whether the dots
  in a call chain lead or trail is up to each project.
- Multiline arrays with one element per line, and `->` for lambdas.
- Methods below `private` and `protected` indented one step.
- A single order for class bodies (`Layout/ClassStructure`).
- The Lint and Security departments.
- The Performance department, with the cops that are on by default and
  `Performance/SelectMap`. Tests are excluded, as in Omakase.
- Empty lines between the `included`, `prepended`, `class_methods` and
  `concerning` blocks of a concern, as between defs.
- `it` for the only parameter of a single-line brace block, with our own cop
  `Equipe/ItInSingleLineBlock`, and a named parameter in longer blocks
  (`Style/ItBlockParameter`). Both need Ruby 3.4. rubocop-performance 1.27
  does not see `it` blocks in most of its block cops, such as `SelectMap`,
  `Detect` and `MapCompact`, so those patterns go unnoticed in new code until
  that is fixed upstream.
- No local variables in ERB templates, with our own cop
  `Equipe/AssignmentInTemplate`: a value a template names is the parameter of
  a block, `value.then do |name|`, several as `[ a, b ].then do |a, b|`.
  RuboCop reads the templates for this cop alone, and every other department
  leaves out `**/*.erb`.

Metrics stay disabled, as in Omakase.

## Usage

```ruby
# Gemfile
group :development do
  gem "rubocop-equipe", github: "equipe/rubocop-equipe", require: false
end
```

```yaml
# .rubocop.yml
inherit_gem: { rubocop-equipe: rubocop.yml }
```

Project-specific rules go below. Add the Rails department there when a project
is ready for it.

## Adopting it in an existing project

1. Run `bin/rubocop -a`. Everything outside Lint, Security, Performance
   and `Layout/ClassStructure` is safe to autocorrect, so commit it on its own and
   add the commit to `.git-blame-ignore-revs`.
2. Record the remaining offenses with
   `bin/rubocop --auto-gen-config --no-exclude-limit --auto-gen-only-exclude`
   and include `.rubocop_todo.yml` with `inherit_from`.
3. Clean up one cop at a time, removing its exclusions from the todo file.

## Development

The cops live in `lib/rubocop/cop/equipe`. Run their tests with `bundle exec rake`.

## Class structure

The autocorrection of `Layout/ClassStructure` is unsafe. The order of callbacks,
associations and validations can change behavior: a `before_destroy` guard, for
example, must run before `has_many ..., dependent: :destroy`. Moving constants
and methods is harmless. Review the rest, and keep an order that matters with
an inline `rubocop:disable` and the reason.
