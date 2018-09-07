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
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id).first
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    return nil unless result
    self.new(result)
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
    self.class.columns.map do |column|
      self.send(column)
    end
  end

  def insert
    col_names = self.class.columns.join(',')
    question_marks = (["?"] * self.class.columns.count).join(',')
    DBConnection.execute(<<-SQL, self.attribute_values)
      INSERT INTO
        #{self.class.table_name}(#{col_names})
      VALUES
        (#{question_marks})
    SQL

    count = DBConnection.execute(<<-SQL)
      SELECT
        COUNT(*) AS count
      FROM
        #{self.class.table_name}
    SQL

    count = count.first['count']
    self.id = count
  end

  def update
    col_names = self.class.columns.map { |column| "#{column} = ?"}.join(',')
    DBConnection.execute(<<-SQL, self.attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    begin
      self.id
      id_present = true
    rescue
      id_present = false
    end

    if id_present
      self.update
    else
      self.insert
    end
  end
end
