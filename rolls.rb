# rolls.rb

# frozen_string_literal: true

require 'psych'
require 'date'

require_relative 'groups'

# Record of attendance of Members in a Group on a Date.
class Rolls
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
    build_path 'data', 'rolls.yml'
  end

  def self.all
    if File.exist? path
      Psych.load_file(path) || {}
    else
      {}
    end
  end

  def self.find(id)
    all[id]
  end

  def self.max_id
    ids = all.map { |id, roll| id }
    ids.max || 0
  end

  attr_reader :id, :date, :group, :present_members

  def date=(date_string)
    @date = Date.strptime(date_string, '%m-%d-%Y')
  rescue ArgumentError, TypeError
    raise Error, 'Invalid date format. Use "MM-DD-YYYY".'
  end

  def group=(group)
    if group.nil? || Groups.find(group.id).nil?
      raise Error, 'Invalid Group.'
    else
      @group = group
    end
  end

  def present_members=(members)
    if !members.is_a?(Array)
      raise Error, 'Invalid Members.'
    else
      @present_members = members
    end
  end

  def initialize(date_string, group, present_members = [])
    @id = self.class.max_id + 1
    self.date = date_string
    self.group = group
    self.present_members = present_members
  end

  def save!
    rolls = self.class.all
    rolls[id] = self

    File.open(self.class.path, 'w') { |file| file.write Psych.dump(rolls) }
  end

  def delete!
    rolls = self.class.all

    if rolls.delete id
      File.open(self.class.path, 'w') { |file| file.write Psych.dump(rolls) }
    end
  end

  def ==(other)
    date == other.date &&
      group.id == other.group.id &&
      present_members == other.present_members
  end

  def empty?(field)
    field.nil? || field.strip.empty?
  end

  def to_s
    "#{group.name} - #{date}"
  end

  class Error < RuntimeError
  end
end
