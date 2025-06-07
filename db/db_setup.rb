require 'active_record'
require_relative './migrate/create_schemas.rb'

# tells ruby to establish a connection to the sqlite database
# "use sqlite3 and connect to the database in the db.sqlite3 file in this directory"
ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'db.sqlite3'
)

# drop tables if they exist
puts "Dropping tables of they exist..."
ActiveRecord::Base.connection.drop_table(:reviews, if_exists: true)
ActiveRecord::Base.connection.drop_table(:pull_requests, if_exists: true)
ActiveRecord::Base.connection.drop_table(:repositories, if_exists: true)

# create new tables for fresh data
CreateSchemas.new.change

puts "Database Created!"