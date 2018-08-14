require 'rspec'
require_relative '../lib/cte_parser'
require_relative '../lib/helpers.rb'
require_relative '../lib/test_database_connector'

describe TestDatabaseConnector do
	include Helpers
	describe '#create_tables!' do
		context 'when there is a single CTE' do
			let(:queries) do
				CteParser.new("""
					WITH bogus_cte_table AS (
						SELECT
							pandas,
							field_2,
						FROM chezeborgers
						ORDER BY pandas
					)
					SELECT *
					FROM bogus_table
				""").parse!
			end
			it 'creates a single time' do
				expected_query = remove_whitespace(%(
					DROP TABLE IF EXISTS bogus_cte_table;
					CREATE TEMP TABLE bogus_cte_table;
					meow
				))
				connector = TestDatabaseConnector.new(queries)
				expect(
					connector
				).to receive(:execute).once.with(expected_query)
				connector.create_tables!
			end
		end
	end

	describe '#execute' do
		let(:queries) do
				CteParser.new("""
					WITH bogus_cte_table AS (
						SELECT
							pandas,
							field_2,
						FROM chezeborgers
						ORDER BY pandas
					)
					SELECT *
					FROM bogus_table
				""").parse!
			end
	end
end