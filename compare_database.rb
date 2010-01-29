require 'rubygems'
require 'pp'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter  => 'mysql',
  :database => 'joblet_amn',
  :username => 'root',
  :password => '',
  :host     => 'localhost'
)

new_tables = ActiveRecord::Base.connection.tables.collect(&:classify)
new_tables.each do |table|
  eval "class #{table} < ActiveRecord::Base;end"
end

new_table_with_columns = {}
new_tables.each do |table|
  eval "new_table_with_columns['#{table}'] = #{table}.column_names"
end



ActiveRecord::Base.establish_connection(
  :adapter  => 'mysql',
  :database => 'joblet_from_pg',
  :username => 'root',
  :password => '',
  :host     => 'localhost'
)
old_tables = ActiveRecord::Base.connection.tables.collect(&:classify)
old_tables.each do |table|
  eval "class #{table} < ActiveRecord::Base;end"
end

old_table_with_columns = {}
old_tables.each do |table|
  eval "old_table_with_columns['#{table}'] = #{table}.column_names"
end







puts "== tables old don't have ======="
pp (new_tables - old_tables)
puts "== tables new don't have ======="
pp (old_tables - new_tables)

common_tables = new_tables&old_tables


new_table_with_columns.each do |k,v|
  puts "=== diff of #{k} ==="
  pp v - old_table_with_columns[k] if old_table_with_columns[k]
end