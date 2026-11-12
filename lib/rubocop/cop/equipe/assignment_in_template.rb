module RuboCop
  module Cop
    module Equipe
      # Keeps local variables out of ERB templates, whose Ruby is read as one program with each tag's code where it stands.
      class AssignmentInTemplate < Base
        MSG = "Name `%<name>s` with a block, `value.then do |%<name>s|`, several as " \
          "`[ a, b ].then do |a, b|`, or move the logic behind it to the model or a helper."
        TAG = /<%(={1,2}|-|\#|%)?(.*?)[-=]?%>/m

        def on_other_file
          check
          super
        end

        def on_new_investigation
          check
          super
        end

        private
          def check
            ruby = AST::ProcessedSource.new(template_ruby, processed_source.ruby_version, processed_source.path,
              parser_engine: processed_source.parser_engine)
            return unless ruby.valid_syntax? && ruby.ast

            ruby.ast.each_node(:lvasgn) do |node|
              add_offense(range_in_template(node.loc.name), message: format(MSG, name: node.name))
            end
          end

          def template_ruby
            template = processed_source.buffer.source

            template.gsub(/[^\n]/, " ").tap do |ruby|
              template.scan(TAG) do
                tag = Regexp.last_match
                next if tag[1] == "#" || tag[1] == "%"

                ruby[tag.begin(2), tag[2].length] = tag[2]
                ruby[tag.end(2)] = ";"
              end
            end
          end

          def range_in_template(range)
            Parser::Source::Range.new(processed_source.buffer, range.begin_pos, range.end_pos)
          end
      end
    end
  end
end
