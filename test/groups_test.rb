# groups_test.rb

# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../groups'

class GroupsTest < Minitest::Test
  def setup
    FileUtils.touch Groups.path
  end

  def teardown
    FileUtils.rm Groups.path
  end

  def test_self_max_id
    assert_equal 0, Groups.max_id

    group1 = Groups.new 'My Test Group'
    group1.save!

    assert_equal 1, Groups.max_id
  end

  def test_initialization_without_name
    assert_raises(Groups::Error) { Groups.new('') }
  end

  def test_save!
    group1 = Groups.new 'My Test Group'
    group1.save!

    group2 = Groups.find group1.id
    assert_equal group1.name, group2.name
  end

  def test_delete!
    group1 = Groups.new 'My Test Group'
    group1.save!
    group1.delete!

    assert_nil Groups.find 1
  end

  def test_member?
    group1 = Groups.new 'My Test Group'
    assert_equal false, group1.member?('Elizabeth')

    group1.add 'Elizabeth'
    assert_equal true, group1.member?('Elizabeth')
  end

  def test_add_member
    group1 = Groups.new 'My Test Group'
    group1.add 'Elizabeth'

    assert group1.member? 'Elizabeth'
    assert_raises(Groups::Error) { group1.add('') }
    assert_raises(Groups::Error) { group1.add('Elizabeth') }
  end

  def test_remove_member
    group1 = Groups.new 'My Test Group'
    group1.add 'Elizabeth'

    assert_equal 'Elizabeth', group1.remove('Elizabeth')
    assert_nil group1.remove('George')
    assert_equal false, group1.member?('Elizabeth')
    assert_raises(Groups::Error) { group1.remove('') }
  end

  def test_members
    group1 = Groups.new 'My Test Group'
    group1.add 'Elizabeth'
    group1.add 'George'

    assert_equal ['Elizabeth', 'George'], group1.members
  end
end
