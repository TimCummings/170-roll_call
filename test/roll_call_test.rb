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
  end

  def teardown
    FileUtils.rm Groups.path
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
    group = Groups.new('Test Group').save!
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
    assert_includes last_response.body, 'Group 23 does not exist.'
  end

  def test_viewing_a_group
    group = Groups.new('Test Group').save!
    get '/groups/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>Test Group</h2>'
  end

  def test_viewing_a_nonexistant_group
    get '/groups/23'

    assert_equal 404, last_response.status
    assert_includes last_response.body, 'Group 23 does not exist.'
  end

  def test_adding_a_member_to_a_group
    group = Groups.new('Test Group').save!
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
    group = Groups.new('Test Group').save!
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
    group = Groups.new('Test Group').save!
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
end
