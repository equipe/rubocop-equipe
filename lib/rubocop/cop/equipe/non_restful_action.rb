module RuboCop
  module Cop
    module Equipe
      # Keeps a controller to the seven RESTful actions. Every public method of a
      # controller is an action, so another one gets a controller of its own or goes private.
      #
      # @example
      #   # bad
      #   class EntriesController < ApplicationController
      #     def withdraw
      #     end
      #   end
      #
      #   # good
      #   class Entries::WithdrawalsController < ApplicationController
      #     def create
      #     end
      #   end
      class NonRestfulAction < Base
        include VisibilityHelp

        MSG = "`%<name>s` is not a RESTful action. Make it a resource of its own: a nested controller, " \
          "`%<namespace>s::...Controller`, with only index, show, new, edit, create, update and destroy. " \
          "`close` in QuestionsController becomes `Questions::ClosuresController#create`. " \
          "Make the method private if it is not an action."
        RESTFUL_ACTIONS = %i[ index show new edit create update destroy ].to_set.freeze

        def on_def(node)
          return if RESTFUL_ACTIONS.include?(node.method_name)
          owner = node.each_ancestor(:class, :module, :sclass, :any_block).first
          return unless controller?(owner) && node_visibility(node) == :public

          namespace = owner.identifier.source.delete_suffix("Controller")
          add_offense(node.loc.name, message: format(MSG, name: node.method_name, namespace: namespace))
        end

        private
          def controller?(owner)
            owner&.class_type? && owner.identifier.short_name.end_with?("Controller")
          end
      end
    end
  end
end
