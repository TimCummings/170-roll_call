# roll_call.rb

# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

require_relative 'rolls'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def root
  File.expand_path '..', __FILE__
end

def build_path(*components)
  if ENV['RACK_ENV'] == 'test'
    File.join root, 'test', components
  else
    File.join root, components
  end
end

def empty?(field)
  field.nil? || field.strip.empty?
end

def handle_error(status_code, error_message, view_to_render)
  flash error_message
  halt status_code, erb(view_to_render)
end

helpers do
  def flash(message)
    session['message'] = message
  end

  def checked?(present_members, member)
    !present_members.nil? && present_members.include?(member)
  end
end

# index
get '/' do
  erb :index
end

# view a list of all groups
get '/groups' do
  erb :groups
end

# render new group form
get '/groups/new' do
  erb :new_group
end

# create a new group
post '/groups' do
  @group = Groups.new params['group_name']
  @group.save!
  flash "Created group #{@group}."
  redirect '/groups'
rescue Groups::Error => error
  handle_error 422, error.message, :new_group
end

# view a specific group by ID
get '/groups/:group_id' do
  @group = Groups.find params['group_id']

  if @group.nil?
    handle_error 404, 'Invalid Group.', :groups
  else
    erb :group
  end
end

# render the edit group form
get '/groups/:group_id/edit' do
  @group = Groups.find params['group_id'].to_i
  erb :edit_group
end

# edit a group by ID
post '/groups/:group_id' do
  @group = Groups.find params['group_id'].to_i

  # use class Initialize to detect errors
  Groups.new params['group_name']

  if @group.nil?
    handle_error 404, 'Invalid Group.', :groups
  else
    @group.name = params['group_name']
    @group.save!
    flash "Updated group #{@group}."
    redirect "/groups/#{@group.id}"
  end

  rescue Groups::Error => error
    handle_error 422, error.message, :edit_group
end

# delete a group by ID
post '/groups/:group_id/delete' do
  @group = Groups.find params['group_id'].to_i

  if @group.nil?
    handle_error 404, 'Invalid Group.', :groups
  else
    @group.delete!
    flash "Deleted group #{@group}."
    redirect '/groups'
  end
end

# add a member to a group
post '/groups/:group_id/members' do
  @group = Groups.find params['group_id'].to_i
  @member = params['member_name']

  if empty? @member
    handle_error 422, 'Member name cannot be empty.', :group
  else
    @group.add @member
    @group.save!
    flash "Added #{@member} to group #{@group}."
    redirect "/groups/#{@group.id}"
  end
rescue Groups::Error => error
  handle_error 422, error.message, :group
end

# delete a member from a group
post '/groups/:group_id/members/:member_name/delete' do
  @group = Groups.find params['group_id'].to_i
  @member = params['member_name']
 
  @group.remove @member
  @group.save!
  flash "Removed #{@member} from group #{@group}."
  redirect "/groups/#{@group.id}"
rescue Groups::Error => error
  handle_error 422, error.message, :group
end

# view rolls (previously logged roll calls)
get '/rolls' do
  erb :rolls
end

# render the log (new) roll form
get '/rolls/new' do
  @group = Groups.find params['group_id']
  erb :new_roll
end

# create a new roll
post '/rolls' do
  @group = Groups.find params['group_id']
  @date_string = params['date']
  @present_members = params['present_members']

  roll = Rolls.new @date_string, @group, @present_members
  roll.save!

  flash "Logged roll #{roll}."
  redirect '/rolls'

rescue Groups::Error => error
  handle_error 422, error.message, :groups
rescue Rolls::Error => error
  handle_error 422, error.message, :new_roll
end

# view a roll by ID
get '/rolls/:roll_id' do
  @roll = Rolls.find params['roll_id'].to_i
  erb :roll
end

# delete a roll by ID
post '/rolls/:roll_id/delete' do
  @roll = Rolls.find params['roll_id'].to_i

  if @roll.nil?
    handle_error 404, "Invalid Roll.", :rolls
  else
    @roll.delete!
    flash "Deleted roll #{@roll}."
    redirect '/rolls'
  end
end
