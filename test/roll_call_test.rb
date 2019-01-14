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
    FileUtils.touch Group.path
  end

  def teardown
    FileUtils.rm Group.path
  end

  def session
    last_request.env['rack.session']
  end

  def test_viewing_all_groups
    group1 = Group.new 'Test Group 1'
    group2 = Group.new 'Test Group 2'
    group1.save!
    group2.save!

    get '/groups'

    assert_equal 200, last_response.status
    assert_includes last_response.body,
      '<li><a href="/groups/Test Group 1">Test Group 1</a>'

    assert_includes last_response.body,
      '<li><a href="/groups/Test Group 2">Test Group 2</a>'
  end

  def test_creating_a_new_group
    post '/groups', { 'group_name' => 'Test Group' }

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_includes last_response.body, 'Created group Test Group.'
    assert_includes last_response.body,
      '<li><a href="/groups/Test Group">Test Group</a>'
  end

  def test_creating_a_new_group_without_a_name
    post '/groups', { 'group_name' => '' }

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Group name cannot be empty.'
  end

  def test_creating_a_new_group_that_already_exists
    post '/groups', { 'group_name' => 'Test Group' }
    assert_equal 302, last_response.status

    post '/groups', { 'group_name' => 'Test Group'}

    assert_equal 422, last_response.status
    assert_includes last_response.body, 'Group Test Group already exists.'
  end

  def test_deleting_a_group
    group = Group.new('Test Group').save!
    post '/groups/Test%20Group/delete'

    assert_equal 302, last_response.status
    get last_response['Location']

    assert_includes last_response.body, 'Deleted group Test Group.'
    refute_includes last_response.body,
      '<li><a href="/groups/Test Group">Test Group</a>'
  end
end
