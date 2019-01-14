# roll_call.rb

# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'psych'

require_relative 'group'

configure do
  enable :sessions
  set :session_secret, 'secret'
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
  status status_code
  flash error_message
  erb view_to_render
end

helpers do
  def flash(message)
    session['message'] = message
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
  erb :new
end

# create a new group
post '/groups' do
  @group = Group.new params['group_name']
  @group.save!
  flash "Created group #{@group}."
  redirect '/groups'
rescue Group::Error => error
  handle_error 422, error.message, :new
end

# view a specific group by name
get '/groups/:group_name' do
  @group = Group.find(params['group_name'])

  if @group.nil?
    handle_error 404, "Group #{params['group_name']} does not exist.", :groups
  else
    erb :group
  end
end

# delete a group by name
post '/groups/:group_name/delete' do
  @group = Group.new params['group_name']
  @group.delete!
  flash "Deleted group #{@group}."
  redirect '/groups'
rescue Group::Error => error
  handle_error 422, error.message, :groups
end
