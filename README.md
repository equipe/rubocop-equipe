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

Project-specific rules go below. Add the Rails or Performance departments there
when a project is ready for them.

## Adopting it in an existing project

1. Run `bin/rubocop -a`. Everything outside Lint, Security and
   `Layout/ClassStructure` is safe to autocorrect, so commit it on its own and
   add the commit to `.git-blame-ignore-revs`.
2. Record the remaining offenses with
   `bin/rubocop --auto-gen-config --no-exclude-limit --auto-gen-only-exclude`
   and include `.rubocop_todo.yml` with `inherit_from`.
3. Clean up one cop at a time, removing its exclusions from the todo file.

## Class structure

The autocorrection of `Layout/ClassStructure` is unsafe. The order of callbacks,
associations and validations can change behavior: a `before_destroy` guard, for
example, must run before `has_many ..., dependent: :destroy`. Moving constants
and methods is harmless. Review the rest, and keep an order that matters with
an inline `rubocop:disable` and the reason.
