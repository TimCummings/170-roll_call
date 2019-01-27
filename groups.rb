# groups.rb

# frozen_string_literal :true

require 'psych'
require 'pry'

# Collection for which roll is to be called, e.g. a class of students.
class Groups
  def self.root
    File.expand_path '..', __FILE__
  end

  def self.build_path(*components)
    if ENV['RACK_ENV'] == 'test'
      File.join root, 'test', components
    else
      File.join root, components
    end
  end

  def self.path
    build_path 'data', 'groups.yml'
  end

  def self.all
    if File.exist? path
      Psych.load_file(path) || {}
    else
      {}
    end
  end

  def self.find(id)
    raise Error, 'Invalid Group.' unless number?(id)
    all[id.to_i]
  end

  def self.max_id
    ids = all.map { |id, group| id }
    ids.max || 0
  end

  def self.number?(id)
    id.is_a?(Integer) || (id.is_a?(String) && id == id.to_i.to_s)
  end

  attr_reader :id, :members
  attr_accessor :name

  def initialize(name)
    raise Error, 'Group name cannot be empty.' if empty? name
    @name = name
    @id = self.class.max_id + 1
    @members = []
  end

  def save!
    groups = self.class.all
    groups[id] = self

    File.open(self.class.path, 'w') { |file| file.write Psych.dump(groups) }
  end

  def delete!
    groups = self.class.all

    if groups.delete id
      File.open(self.class.path, 'w') { |file| file.write Psych.dump(groups) }
    end
  end

  def empty?(field)
    field.nil? || field.strip.empty?
  end

  def to_s
    name
  end

  def member?(member_name)
    members.any? { |member| member == member_name }
  end

  def add(member)
    raise Error, 'Member name cannot be empty.' if empty? member
    raise Error, "Member #{member} is already in this group." if member? member
    members << member
  end

  def remove(member)
    raise Error, 'Member name cannot be empty.' if empty? member
    member_index = members.index(member)
    members.slice! member_index if member_index
  end

  # generic Groups exception class
  class Error < RuntimeError
  end
end
