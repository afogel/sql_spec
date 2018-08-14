require 'colorize'
require_relative './test'
require_relative './cte_parser'

class TestGroup
	include Test

	attr_reader :raw_query, :parsed_query

	def self.describe(raw_query)
		@raw_query = raw_query
		@parsed_query = CteParser.new(raw_query).parse!
		puts 'For query:'.yellow
		puts raw_query.yellow
		yield
	end
end

query = """
WITH bogus_cte_table AS (
	SELECT
		pandas,
		field_2,
	FROM chezeborgers
	ORDER BY pandas
)
SELECT *
FROM bogus_table
"""

TestGroup.describe(query) do
	Test.it('does the thing') do
		Test.assert_equal('a', 'b')
	end

	Test.it('does a different thing') do
		Test.assert_equal('a', 'a')
	end
end