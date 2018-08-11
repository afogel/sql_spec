require 'rspec'
require 'cte_parser'

describe CteParser do
	describe '#parse!' do
		context 'when there is no CTE' do
			let(:query) do
				"""
					SELECT *
					FROM bogus_table
				"""
			end
			it 'identifies the table name from the FROM statement' do
				destructured_query = CteParser.parse!(query)
				expect(destructured_query.final_query.table_name).to.be(nil)
			end
			it 'identifies the associated query correctly' do
				destructured_query = CteParser.parse!(query)
				expected_query = """
					SELECT *
					FROM bogus_table
				"""
				expect(destructured_query.final_query.query).to.eql(expected_query)
			end
		end
		context 'when there is one CTE' do
				let(:query) do
					"""
						WITH bogus_cte_table AS (
							SELECT
								field_1,
								field_2,
							FROM chezeborgers
						)
						SELECT *
						FROM bogus_table
					"""
				end
			it 'identifies a table name from the CTE title and the FROM statement' do
				destructured_query = CteParser.parse!(query)
				expect(destructured_query.ctes[0].table_name).to.eql("bogus_cte_table")
			end
			it 'identifies the associated query correctly' do
				destructured_query = CteParser.parse!(query)
				expected_query = """
					SELECT
						field_1,
						field_2,
					FROM chezeborgers
				"""
				expect(destructured_query.ctes[0].table_name).to.eql(expected_query)
			end
		end
		context 'when there are multiple CTEs' do
			let(:query) do
					"""
					WITH bogus_table AS (
						SELECT
							field_1,
							field_2,
						FROM chezeborgers
					),
					moneky_brains AS (
						SELECT
							field_3,
							field_4,
						FROM bogus_cte_table
					)
					SELECT *
					FROM bogus_table
				"""
			end
			it 'identifies table names from the CTE titles and the FROM statement' do
				destructured_query = CteParser.parse!(query)
				expect(destructured_query.ctes[1].table_name).to.eql("moneky_brains")
			end
			it 'identifies the query correctly' do
				destructured_query = CteParser.parse!(query)
				expected_query = """
					SELECT
						field_3,
						field_4
					FROM bogus_cte_table
				"""
				expect(destructured_query.ctes[1].query).to.eql(expected_query)
			end
		end
	end
end