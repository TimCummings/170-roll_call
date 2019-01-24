# rolls.rb

# frozen_string_literal: true

require 'psych'
require 'date'

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

  attr_reader :id, :date, :group_id, :present_members

  def date=(date_string)
    @date = Date.strptime(date_string, '%m-%d-%Y')
  rescue ArgumentError
    raise Error, 'Invalid date format. Use "MM-DD-YYYY".'
  end

  def initialize(date_string, group_id, present_members = [])
    @id = self.class.max_id + 1
    self.date = date_string
    @group_id = group_id
    @present_members = present_members
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

  def empty?(field)
    field.nil? || field.strip.empty?
  end

  def to_s
    group = Groups.find group_id
    "#{group.name} - #{date}"
  end

  class Error < RuntimeError
  end
end
