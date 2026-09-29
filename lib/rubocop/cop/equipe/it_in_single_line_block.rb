module RuboCop
  module Cop
    module Equipe
      # Uses `it` for the only parameter of a single-line brace block. Longer
      # blocks keep a named parameter, which Style/ItBlockParameter enforces
      # with its allow_single_line style.
      #
      # @example
      #   # bad
      #   users.map { |user| user.name }
      #
      #   # good
      #   users.map { it.name }
      #   users.each do |user|
      #     user.touch
      #   end
      #   scope :by_club, ->(club) { where(club: club) }
      #
      # A lambda keeps its parameter, which names what it takes. A block is
      # also left alone when the parameter is unused, since dropping it
      # changes the arity of a block given to define_method, when it holds
      # another block, whose own `it` would shadow the outer one, and when it
      # already calls `it`.
      class ItInSingleLineBlock < Base
        extend AutoCorrector
        extend TargetRubyVersion
        include RangeHelp

        MSG = "Use `it` for the only parameter of a single-line block."

        minimum_target_ruby_version 3.4

        def on_block(node)
          return unless node.braces? && node.single_line? && node.body
          return if node.lambda?
          return unless node.arguments.one? && node.first_argument.arg_type?

          name = node.first_argument.name
          uses = node.body.each_node(:lvar).select { |lvar| lvar.children.first == name }
          return if uses.empty?
          return if node.body.each_node(:any_block).any?
          return if node.body.each_node(:send, :lvar).any? { |reference| it_reference?(reference) }

          add_offense(node.arguments) do |corrector|
            corrector.remove(range_with_surrounding_space(node.arguments.source_range, side: :right))
            uses.each { |use| corrector.replace(use, "it") }
          end
        end

        private
          def it_reference?(node)
            node.send_type? ? node.receiver.nil? && node.method?(:it) : node.children.first == :it
          end
      end
    end
  end
end
