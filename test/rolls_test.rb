# rolls_test.rb

# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../rolls'

class RollsTest < Minitest::Test
  def setup
    FileUtils.touch Groups.path
    FileUtils.touch Rolls.path
  end

  def teardown
    FileUtils.rm Groups.path
    FileUtils.rm Rolls.path
  end

  def test_self_max_id
    assert_equal 0, Rolls.max_id

    group = Groups.new 'My Test Group'
    group.save!

    roll1 = Rolls.new '01-01-2019', group, []
    roll1.save!

    assert_equal 1, Rolls.max_id
  end

  def test_initialization_with_invalid_date
    group = Groups.new 'My Test Group'
    group.save!

    assert_raises(Rolls::Error) { Rolls.new 'not a date',group , [] }
  end

  def test_save!
    group = Groups.new 'My Test Group'
    group.save!

    roll1 = Rolls.new '01-01-2019', group, []
    roll1.save!

    roll2 = Rolls.find roll1.id

    assert_equal roll1, roll2
  end

  def test_delete!
    group = Groups.new 'My Test Group'
    group.save!

    roll1 = Rolls.new '01-01-2019', group, []
    roll1.save!
    roll1.delete!

    assert_nil Rolls.find 1
  end

  def test_equality
    group = Groups.new 'My Test Group'
    group.save!

    roll1 = Rolls.new '01-01-2019', group, ['Joe', 'Lisa']
    same_roll = Rolls.new '01-01-2019', group, ['Joe', 'Lisa']

    assert_equal roll1, same_roll
  end

  def test_inequality_by_date
    group = Groups.new 'My Test Group'
    group.save!

    roll1 = Rolls.new '01-01-2019', group, ['Joe', 'Lisa']
    roll2 = Rolls.new '01-02-2019', group, ['Joe', 'Lisa']

    refute_equal roll1, roll2
  end

  def test_inequality_by_group_id
    group1 = Groups.new 'My Test Group'
    group1.save!
    group2 = Groups.new 'My Other Test Group'
    group2.save!

    roll1 = Rolls.new '01-01-2019', group1, ['Joe', 'Lisa']
    roll2 = Rolls.new '01-01-2019', group2, ['Joe', 'Lisa']

    refute_equal roll1, roll2
  end

  def test_inequality_by_present_members
    group = Groups.new 'My Test Group'
    group.save!

    roll1 = Rolls.new '01-01-2019', group, ['Joe', 'Lisa']
    roll2 = Rolls.new '01-01-2019', group, ['Joe']

    refute_equal roll1, roll2
  end
end
