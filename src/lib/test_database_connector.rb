require_relative 'helpers'

class TestDatabaseConnector
	include Helpers
	attr_reader :queries, :connection
	def initialize(queries)
		@queries = queries
		@connection = nil
	end

	def open_connection
	end

	def close_connection
	end

	def execute(query)
	end

	def create_tables!
		queries.each do |query|
			next if query.cte_name.nil?
			create_table_query =  remove_whitespace(%(
				DROP TABLE IF EXISTS #{query.cte_name};
				CREATE TEMP TABLE #{query.cte_name};
			))
			execute(create_table_query)
		end
	end

	def create_test_table_query(table_name)
	end
end