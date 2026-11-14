require "minitest/autorun"
require "rubocop"
require_relative "../lib/rubocop/cop/equipe/non_restful_action"

class NonRestfulActionTest < Minitest::Test
  COP = RuboCop::Cop::Equipe::NonRestfulAction

  def test_flags_another_public_method_of_a_controller
    offenses = investigate(controller("def withdraw\nend"))

    assert_equal [ "withdraw" ], offenses.map { it.location.source }
    assert_includes offenses.first.message, "`withdraw` is not a RESTful action"
  end

  def test_points_to_a_controller_nested_under_this_one
    offense = investigate("class Meetings::PeopleController < ApplicationController\n  def payable\n  end\nend").first

    assert_includes offense.message, "`Meetings::People::...Controller`"
  end

  def test_allows_the_seven_restful_actions
    assert_no_offense controller(%w[ index show new edit create update destroy ].map { "def #{it}\nend" }.join("\n"))
  end

  def test_allows_methods_below_private_and_protected
    assert_no_offense controller("def show\nend\n\nprivate\n  def set_entry\n  end")
    assert_no_offense controller("protected\n  def set_entry\n  end")
  end

  def test_allows_methods_made_private_inline_or_by_name
    assert_no_offense controller("private def set_entry\nend")
    assert_no_offense controller("def set_entry\nend\nprivate :set_entry")
  end

  def test_flags_a_method_made_public_again
    assert_equal 1, investigate(controller("private\n  def set_entry\n  end\n\npublic\n  def withdraw\n  end")).size
  end

  def test_flags_namespaced_controllers
    assert_equal 1, investigate("class Admin::EntriesController < ApplicationController\n  def withdraw\n  end\nend").size
    assert_equal 1, investigate("module Admin\n  class EntriesController < ApplicationController\n    def withdraw\n    end\n  end\nend").size
  end

  def test_flags_a_public_method_of_the_application_controller
    assert_equal 1, investigate("class ApplicationController < ActionController::Base\n  def current_user\n  end\nend").size
  end

  def test_leaves_other_classes_and_concerns_alone
    assert_no_offense "class Entry < ApplicationRecord\n  def withdraw\n  end\nend"
    assert_no_offense "module Withdrawable\n  def withdraw\n  end\nend"
  end

  def test_leaves_class_methods_alone
    assert_no_offense controller("def self.local_prefixes\nend")
    assert_no_offense controller("class << self\n  def local_prefixes\n  end\nend")
  end

  def test_leaves_methods_of_a_class_inside_the_controller_alone
    assert_no_offense controller("class Filter\n  def apply\n  end\nend")
  end

  private
    def controller(body)
      "class EntriesController < ApplicationController\n#{body}\nend"
    end

    def assert_no_offense(source)
      assert_empty investigate(source)
    end

    def investigate(source)
      config = RuboCop::Config.new({ COP.cop_name => { "Enabled" => true } }, "")
      processed = RuboCop::ProcessedSource.new(source, 3.4, "app/controllers/entries_controller.rb", parser_engine: :parser_prism)
      RuboCop::Cop::Commissioner.new([ COP.new(config) ]).investigate(processed).offenses
    end
end
