# rolls_test.rb

# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../rolls'

class RollsTest < Minitest::Test
  def setup
    FileUtils.touch Rolls.path
  end

  def teardown
    FileUtils.rm Rolls.path
  end

  def test_self_max_id
    assert_equal 0, Rolls.max_id

    roll1 = Rolls.new '01-01-2019', 1, []
    roll1.save!

    assert_equal 1, Rolls.max_id
  end

  def test_initialization_with_invalid_date
    assert_raises(Rolls::Error) { Rolls.new 'not a date', 1, [] }
  end

  def test_save!
    roll1 = Rolls.new '01-01-2019', 1, []
    roll1.save!

    roll2 = Rolls.find roll1.id
    assert_equal roll1.id, roll2.id
    assert_equal roll1.date, roll2.date
    assert_equal roll1.group_id, roll2.group_id
    assert_equal roll1.present_members, roll2.present_members
  end
end
