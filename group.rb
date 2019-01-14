# group.rb

# frozen_string_literal :true

require 'pry'

# Collection for which roll is to be called, e.g. a class of students.
class Group
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
      Psych.load_file(path) || []
    else
      []
    end
  end

  def self.find(name)
    self.all.find { |group| group.name == name }
  end

  attr_reader :name, :members

  def initialize(name)
    raise Error, 'Group name cannot be empty.' if empty? name
    @name = name
    @members = []
  end

  def ==(other)
    name == other.name
  end

  def save!
    groups = self.class.all
    raise Error, "Group #{self} already exists." if groups.include? self
    groups << self

    File.open(self.class.path, 'w') { |file| file.write Psych.dump(groups) }
  end

  def delete!
    groups = self.class.all
    group_index = groups.index(self)

    if group_index
      groups.slice! group_index
      File.open(self.class.path, 'w') { |file| file.write Psych.dump(groups) }
    end
  end

  def update!
    groups = self.class.all
    group_index = groups.index(self)

    if group_index
      groups[group_index] = self
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

  # generic Group exception class
  class Error < RuntimeError
  end
end
