# roll_call_test.rb

# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'

Minitest::Reporters.use!

require_relative '../roll_call'

class RollCallTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.touch Groups.path
    FileUtils.touch Rolls.path
  end

  def teardown
    FileUtils.rm Groups.path
    FileUtils.rm Rolls.path
  end

  def session
    last_request.env['rack.session']
  end

  def test_viewing_all_groups
    group1 = Groups.new 'Test Group 1'
    group1.save!
    group2 = Groups.new 'Test Group 2'
    group2.save!

    get '/groups'

    assert_equal 200, last_response.status
    assert_includes last_response.body,
      '<a href="/groups/1">Test Group 1</a>'

    assert_includes last_response.body,
      '<a href="/groups/2">Test Group 2</a>'
  end

  def test_creating_a_new_group
    post '/groups', { 'group_name' => 'Test Group' }

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_includes last_response.body, 'Created group Test Group.'
    assert_includes last_response.body,
      '<a href="/groups/1">Test Group</a>'
  end

  def test_creating_a_new_group_without_a_name
    post '/groups', { 'group_name' => '' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Group name cannot be empty.'
  end

  def test_deleting_a_group
    group = Groups.new 'Test Group'
    group.save!

    post '/groups/1/delete'

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_includes last_response.body, 'Deleted group Test Group.'
    refute_includes last_response.body,
      '<li><a href="/groups/1">Test Group</a>'
  end

  def test_deleting_a_nonexistant_group
    post '/groups/23/delete'

    assert_equal 404, last_response.status
    assert_includes last_response.body, 'Invalid Group.'
  end

  def test_viewing_a_group
    group = Groups.new 'Test Group'
    group.save!

    get '/groups/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>Test Group</h2>'
  end

  def test_viewing_a_nonexistant_group
    get '/groups/23'

    assert_equal 404, last_response.status
    assert_includes last_response.body, 'Invalid Group.'
  end

  def test_adding_a_member_to_a_group
    group = Groups.new 'Test Group'
    group.save!

    post '/groups/1/members', { 'member_name' => 'Joel' }

    assert_equal 302, last_response.status
    assert_equal 'Added Joel to group Test Group.', session['message']

    assert Groups.find(1).member? 'Joel'

    get last_response['Location']
    assert_includes last_response.body,
      <<~MEMBER
        <ul>
            <li>
              Joel
      MEMBER
  end

  def test_adding_a_member_without_a_name
    group = Groups.new 'Test Group'
    group.save!

    post '/groups/1/members'

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Member name cannot be empty.'

    post '/groups/1/members', { 'member_name' => '' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Member name cannot be empty.'

    group = Groups.find 1
    assert group.members.empty?
  end

  def test_adding_a_member_already_in_group
    group = Groups.new 'Test Group'
    group.add 'John'
    group.save!

    post '/groups/1/members', { 'member_name' => 'John' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Member John is already in this group.'
    assert_equal 1, Groups.find(1).members.size
  end

  def test_removing_a_member_from_a_group
    group = Groups.new 'Test Group'
    group.save!

    post '/groups/1/members', { 'member_name' => 'Jane' }

    post '/groups/1/members/Jane/delete'

    assert_equal 302, last_response.status
    assert_equal session['message'], 'Removed Jane from group Test Group.'
    refute Groups.find(1).member? 'Jane'

    get last_response['Location']
    refute_includes last_response.body,
      <<~MEMBER
        <ul>
            <li>
              Jane
      MEMBER
  end

  def test_viewing_all_rolls
    group1 = Groups.new 'My Test Group'
    group1.save!

    roll1 = Rolls.new '01-01-2019', group1, ['Joe', 'Lisa']
    roll1.save!
    roll2 = Rolls.new '01-02-2019', group1, ['Ashley', 'Tom']
    roll2.save!

    get '/rolls'

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<a href=\"/rolls/1\">#{roll1}</a>"
  end

  def test_creating_a_new_roll
    group = Groups.new 'My Test Group'
    group.save!

    post '/rolls', { 'date' => '01-01-2019', 'group_id' => group.id,
                     'present_members' => ['Jack', 'Sarah'] }

    assert_equal 302, last_response.status
    get last_response['Location']

    roll = Rolls.find 1
    assert roll

    assert_includes last_response.body, "Logged roll #{roll}."
    assert_includes last_response.body, "<a href=\"/rolls/1\">#{roll}</a>"
  end

  def test_creating_a_new_roll_without_a_date
    group = Groups.new 'My Test Group'
    group.save!

    post '/rolls', { 'group_id' => group.id,
                     'present_members' => ['Jack', 'Sarah'] }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid date format.'
    assert_empty Rolls.all
  end

  def test_creating_a_new_roll_with_invalid_date
    group = Groups.new 'My Test Group'
    group.save!

    post '/rolls', { 'date' => '1234567890', 'group_id' => group.id,
                     'present_members' => ['Jack', 'Sarah'] }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid date format.'
    assert_empty Rolls.all
  end

  def test_creating_a_new_roll_without_a_group_id
    post '/rolls', { 'date' => '01-01-2019',
                     'present_members' => ['Jack', 'Sarah'] }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid Group.'
    assert_empty Rolls.all
  end

  def test_creating_a_new_roll_with_invalid_group_id
    post '/rolls', { 'date' => '01-01-2019', 'group_id' => 'seven',
                     'present_members' => ['Jack', 'Sarah'] }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid Group.'
    assert_empty Rolls.all
  end

  def test_creating_a_new_roll_without_present_members
    group = Groups.new 'My Test Group'
    group.save!

    post '/rolls', { 'date' => '01-01-2019', 'group_id' => group.id }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Invalid Members.'
    assert_empty Rolls.all
  end

  def test_deleting_a_roll
    group = Groups.new 'Test Group'
    group.save!

    roll = Rolls.new '01-01-2019', group, ['Joe', 'Lisa']
    roll.save!

    post "/rolls/#{roll.id}/delete"

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_includes last_response.body, "Deleted roll #{roll}."
    refute_includes last_response.body,
      "<a href=\"/rolls/#{roll.id}\">#{roll}</a>"
  end

  def test_deleting_a_nonexistant_roll
    post "/rolls/23/delete"

    assert_equal 404, last_response.status
    assert_includes last_response.body, 'Invalid Roll.'
  end
end
