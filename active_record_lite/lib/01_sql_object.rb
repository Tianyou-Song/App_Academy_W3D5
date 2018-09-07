require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns

    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    columns = columns.first
    @columns = columns.map { |column| column.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        @attributes[column]
      end

      define_method("#{column}=") do |v|
        @attributes ||= Hash.new
        @attributes[column] = v
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.tableize
  end

  def self.all
    # ...
  end

  def self.parse_all(results)
    # ...
  end

  def self.find(id)
    # ...
  end

  def initialize(params = {})
    params.each do |k, v|
      k = k.to_sym
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k)
    end

    params.each do |k, v|
      k = k.to_sym
      self.send("#{k}=", v)
    end
  end

  def attributes
    @attributes ||= Hash.new
  end

  def attribute_values
    # ...
  end

  def insert
    # ...
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
