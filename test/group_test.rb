# group_test.rb

# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../group'

class GroupTest < Minitest::Test
  def test_initialization_without_name
    assert_raises(Group::Error) { Group.new('') }
  end

  def test_equality
    group1 = Group.new 'My Test Group'
    group2 = Group.new 'My Test Group'
    group3 = Group.new 'My Other Test Group'

    assert_equal group1, group2
    refute_equal group1, group3
  end

  def test_member?
    group1 = Group.new 'My Test Group'
    assert_equal false, group1.member?('Elizabeth')

    group1.add 'Elizabeth'
    assert_equal true, group1.member?('Elizabeth')
  end

  def test_add_member
    group1 = Group.new 'My Test Group'
    group1.add 'Elizabeth'

    assert group1.member? 'Elizabeth'
    assert_raises(Group::Error) { group1.add('') }
    assert_raises(Group::Error) { group1.add('Elizabeth') }
  end

  def test_remove_member
    group1 = Group.new 'My Test Group'
    group1.add 'Elizabeth'

    assert_equal 'Elizabeth', group1.remove('Elizabeth')
    assert_nil group1.remove('George')
    assert_equal false, group1.member?('Elizabeth')
    assert_raises(Group::Error) { group1.remove('') }
  end

  def test_members
    group1 = Group.new 'My Test Group'
    group1.add 'Elizabeth'
    group1.add 'George'

    assert_equal ['Elizabeth', 'George'], group1.members
  end
end
