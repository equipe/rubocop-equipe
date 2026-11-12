require "minitest/autorun"
require "rubocop"
require_relative "../lib/rubocop/cop/equipe/assignment_in_template"

class AssignmentInTemplateTest < Minitest::Test
  COP = RuboCop::Cop::Equipe::AssignmentInTemplate

  def test_finds_an_assignment_in_a_tag
    assert_offenses "<% total = order.total %>\n<p><%= total %> kr</p>\n", [ [ 1, "total" ] ]
  end

  def test_finds_an_assignment_in_a_condition
    assert_offenses "<% if (thumbnail = ticket.thumbnail) %>\n  <%= image_tag thumbnail %>\n<% end %>\n", [ [ 1, "thumbnail" ] ]
  end

  def test_finds_or_assignments_operator_assignments_and_several_at_once
    template = "<% count ||= 0 %>\n<% count += 1 %>\n<% first, last = names.minmax %>\n"
    assert_offenses template, [ [ 1, "count" ], [ 2, "count" ], [ 3, "first" ], [ 3, "last" ] ]
  end

  def test_finds_an_assignment_inside_a_block_that_spans_tags
    template = "<%= form_with model: user do |form| %>\n  <% label = form.label :name %>\n  <%= label %>\n<% end %>\n"
    assert_offenses template, [ [ 2, "label" ] ]
  end

  def test_points_at_the_name_after_text_with_multibyte_characters
    offense = investigate("<p>Hästägare</p> <% owner = horse.owner %>\n").first
    assert_equal 1, offense.line
    assert_equal 20, offense.column
    assert_equal "owner", offense.location.source
  end

  def test_tells_how_to_name_the_value_instead
    assert_match "`value.then do |total|`", investigate("<% total = order.total %>").first.message
  end

  def test_keeps_block_parameters
    assert_no_offense "<% order.total.then do |total| %>\n  <%= total %>\n<% end %>\n"
    assert_no_offense "<% [ order.total, order.paid ].then do |total, paid| %>\n<% end %>\n"
    assert_no_offense "<% rows.each_with_index do |row, index| %><%= index %><% end %>\n"
  end

  def test_keeps_comparisons_keyword_arguments_and_instance_variables
    assert_no_offense "<% if total == 0 %>\n<% end %>\n"
    assert_no_offense "<%= render \"row\", total: order.total %>\n"
    assert_no_offense "<% @title = \"Hem\" %>\n"
  end

  def test_keeps_comments_and_escaped_tags
    assert_no_offense "<%# total = order.total %>\n<%% total = order.total %>\n"
  end

  def test_reads_tags_that_trim_whitespace
    assert_offenses "<%- total = order.total -%>\n<%= total %>\n", [ [ 1, "total" ] ]
  end

  def test_reads_templates_that_are_html_alone
    assert_no_offense "<div class=\"card\">\n  <p>Hej</p>\n</div>\n"
    assert_no_offense ""
  end

  def test_says_nothing_when_the_ruby_of_the_template_does_not_parse
    assert_no_offense "<% if total %>\n"
  end

  private
    def assert_offenses(template, expected)
      offenses = investigate(template)
      assert_equal expected, offenses.map { [ it.line, it.location.source ] }
    end

    def assert_no_offense(template)
      assert_empty investigate(template)
    end

    def investigate(template)
      config = RuboCop::Config.new({ "AllCops" => { "TargetRubyVersion" => 3.4 }, COP.cop_name => { "Enabled" => true } }, "")
      processed = RuboCop::ProcessedSource.new(template, 3.4, "app/views/show.html.erb", parser_engine: :parser_prism)
      RuboCop::Cop::Commissioner.new([ COP.new(config) ]).investigate(processed).offenses.sort_by { [ it.line, it.column ] }
    end
end
