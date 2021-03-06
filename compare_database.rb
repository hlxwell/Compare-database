require 'rubygems'
require 'pp'
require 'active_record'

###############
class NewDB < ActiveRecord::Base
  establish_connection(
    :adapter  => 'mysql',
    :database => 'joblet_amn',
    :username => 'root',
    :password => '',
    :host     => 'localhost'
  )
end
new_tables = NewDB.connection.tables.collect(&:classify)
new_tables.each do |table|
  eval "class #{table}New < NewDB
    set_table_name '#{table.tableize}'
end"
end
new_table_with_columns = {}
new_tables.each do |table|
  eval "new_table_with_columns['#{table}'] = #{table}New.column_names"
end

###############
class OldDB < ActiveRecord::Base
  establish_connection(
    :adapter  => 'mysql',
    :database => 'joblet_production',
    :username => 'root',
    :password => '',
    :host     => 'localhost'
  )
end
old_tables = OldDB.connection.tables.collect(&:classify)
old_tables.each do |table|
  eval "class #{table}Old < OldDB
    set_table_name '#{table.tableize}'
end"
end
old_table_with_columns = {}
old_tables.each do |table|
  eval "old_table_with_columns['#{table}'] = #{table}Old.column_names"
end

###############################################
puts "== old tables don't have ======="
pp (new_tables - old_tables)
puts "== new tables don't have ======="
pp (old_tables - new_tables)

puts "\n\n\n\n"

def puts_migration_code(table, columns)
  columns.each do |col|
    #TODO: currently it't not support limit and other options
    col_type = ""
    eval "col_type = #{table}New.columns_hash['#{col}'].type.to_s"
    pp "add_column :#{table.tableize}, :#{col}, :#{col_type}"
  end
end

def check_column_type(table, columns)
  columns.each do |col|
    #TODO: currently it't not support limit and other options
    new_col_type = ""
    old_col_type = ""
    eval "old_col_type = #{table}Old.columns_hash['#{col}'].type.to_s"
    eval "new_col_type = #{table}New.columns_hash['#{col}'].type.to_s"

    if new_col_type != old_col_type
      pp "change_column :#{table.tableize}, :#{col}, :#{old_col_type}, :#{new_col_type}"
    end
  end
end

def check_column_default_value(table, columns)
  columns.each do |col|
    #TODO: currently it't not support limit and other options
    new_default_value = ""
    old_default_value = ""
    
    eval "old_default_value = #{table}Old.columns_hash['#{col}'].default.to_s"
    eval "new_default_value = #{table}New.columns_hash['#{col}'].default.to_s"

    if new_default_value != old_default_value
      pp "change_column_default(:#{table.tableize}, :#{col}, '#{new_default_value}')"
      # pp "change_column :#{table.tableize}, :#{col}, :#{old_col_type}, :#{new_col_type}"
    end
  end
end

new_table_with_columns.each do |k,v|
  added_columns = removed_columns = []
  added_columns = v - old_table_with_columns[k] if old_table_with_columns[k]
  removed_columns = old_table_with_columns[k] - v if old_table_with_columns[k]

  if old_table_with_columns[k]
    old_table_columns = old_table_with_columns[k]
    new_table_columns = v

    ### get common columns
    common_columns = new_table_columns - removed_columns
    check_column_type(k, common_columns)
    check_column_default_value(k, common_columns)    
  end

  if !added_columns.blank? or !removed_columns.blank?
    puts "=== diff of #{k} ==="
    unless added_columns.blank?
      puts "+ add columns"
      puts_migration_code k, added_columns
    end

    unless removed_columns.blank?
      puts "- removed columns"
      puts_migration_code k, removed_columns
    end

    v - (removed_columns + added_columns)
  end
end