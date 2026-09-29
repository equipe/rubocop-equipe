require "minitest/autorun"
require "rubocop"
require_relative "../lib/rubocop/cop/equipe/it_in_single_line_block"

class ItInSingleLineBlockTest < Minitest::Test
  COP = RuboCop::Cop::Equipe::ItInSingleLineBlock

  def test_replaces_the_parameter_of_a_single_line_brace_block
    assert_correction "users.map { |user| user.name }", "users.map { it.name }"
  end

  def test_replaces_every_use_of_the_parameter
    assert_correction "rows.select { |row| row.size > 1 && row.first }", "rows.select { it.size > 1 && it.first }"
  end

  def test_keeps_multiline_blocks
    assert_no_offense "users.each do |user|\n  user.touch\nend"
    assert_no_offense "users.each { |user|\n  user.touch\n}"
  end

  def test_keeps_single_line_do_blocks
    assert_no_offense "users.each do |user| user.touch end"
  end

  def test_keeps_blocks_with_several_parameters
    assert_no_offense "hash.map { |key, value| key }"
    assert_no_offense "pairs.map { |(key, value)| key }"
    assert_no_offense "list.map { |*items| items }"
  end

  def test_keeps_the_parameter_of_a_lambda
    assert_no_offense "scope :by_club, ->(club) { where(club: club) }"
    assert_no_offense "lambda { |club| where(club: club) }"
  end

  def test_keeps_an_unused_parameter
    assert_no_offense "proc { |_user| true }"
  end

  def test_keeps_the_outer_parameter_of_nested_blocks
    assert_correction "users.map { |user| user.roles.map { |role| role.name } }", "users.map { |user| user.roles.map { it.name } }"
  end

  def test_keeps_blocks_that_already_call_it
    assert_no_offense "describe { |user| it(user) }"
  end

  def test_needs_ruby_3_4
    refute COP.support_target_ruby_version?(3.3)
    assert COP.support_target_ruby_version?(3.4)
  end

  private
    def assert_correction(source, expected)
      offenses, corrected = investigate(source)
      assert_equal 1, offenses.size
      assert_equal expected, corrected
    end

    def assert_no_offense(source)
      assert_empty investigate(source).first
    end

    def investigate(source)
      config = RuboCop::Config.new({ "AllCops" => { "TargetRubyVersion" => 3.4 }, COP.cop_name => { "Enabled" => true } }, "")
      processed = RuboCop::ProcessedSource.new(source, 3.4, "test.rb", parser_engine: :parser_prism)
      report = RuboCop::Cop::Commissioner.new([ COP.new(config, autocorrect: true) ]).investigate(processed)
      corrector = RuboCop::Cop::Corrector.new(processed)
      report.correctors.compact.each { |other| corrector.merge!(other) }
      [ report.offenses, corrector.rewrite ]
    end
end
