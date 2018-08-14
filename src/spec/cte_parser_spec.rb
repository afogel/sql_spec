require 'rspec'
require_relative '../lib/helpers.rb'
require_relative '../lib/cte_parser.rb'

describe CteParser do
	include Helpers
	describe '#parse!' do
		context 'when there is no CTE' do
			let(:query) do
				"""
					SELECT *
					FROM bogus_table
				"""
			end
			it 'returns no cte table name from the FROM statement' do
				destructured_query = CteParser.new(query).parse!
				expect(destructured_query.last.cte_name).to be(nil)
			end
			it 'identifies the associated query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT *
					FROM bogus_table
				"""
				expect(destructured_query.last.query).to eql(remove_whitespace(expected_query))
			end
		end
		context 'when there is one CTE' do
				let(:query) do
					"""
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
				end
			it 'identifies a table name from the CTE title and the FROM statement' do
				destructured_query = CteParser.new(query).parse!
				expect(destructured_query.first.cte_name).to eql("bogus_cte_table")
			end
			it 'identifies no table name for the non-CTE query' do
				destructured_query = CteParser.new(query).parse!
				expect(destructured_query.last.cte_name).to be(nil)
			end
			it 'identifies the associated query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT
						pandas,
						field_2,
					FROM chezeborgers
					ORDER BY pandas
				"""
				expect(destructured_query.first.query).to eql(remove_whitespace(expected_query))
			end
		end
		context 'when there are multiple CTEs' do
			let(:query) do
					"""
					WITH bogus_table AS (
						(SELECT *
						FROM bogus_table)
						UNION
						(SELECT *
						FROM bogus_table)
					),
					moneky_brains AS (
						SELECT
							field_3,
							 ROUND((chickens_count::float / robots.count)*100, 1) AS brain_count
						FROM bogus_cte_table
						ORDER BY field_3
						GROUP BY brain_count
					)
					(SELECT *
					FROM bogus_table)
					UNION
					(SELECT *
					FROM bogus_table)
				"""
			end
			it 'parses the large query into 3 subqueries' do
				destructured_query = CteParser.new(query).parse!
				expect(destructured_query.length).to eql(3)
			end
			it 'orders the queries by order in which they should be executed' do
				destructured_query = CteParser.new(query).parse!
				expected_cte_names = ['bogus_table', 'moneky_brains', nil]
				expect(destructured_query.map(&:cte_name)).to eql(expected_cte_names)
			end
			it 'identifies the first CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					(SELECT *
						FROM bogus_table)
						UNION
						(SELECT *
						FROM bogus_table)
				"""
				expect(destructured_query[0].query).to eql(remove_whitespace(expected_query))
			end
			it 'identifies the middle CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT
						field_3,
						ROUND((chickens_count::float / robots.count)*100, 1) AS brain_count
					FROM bogus_cte_table
					ORDER BY field_3
					GROUP BY brain_count
				"""
				expect(destructured_query[1].query).to eql(remove_whitespace(expected_query))
			end
			it 'identifies the non-CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					(SELECT *
					FROM bogus_table)
					UNION
					(SELECT *
					FROM bogus_table)
				"""
				expect(destructured_query.last.query).to eql(remove_whitespace(expected_query))
			end
			it 'does not assign a cte_name to the non-CTE query' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT *
					FROM bogus_table
				"""
				expect(destructured_query.last.cte_name).to be(nil)
			end
		end

		context 'when the CTEs contain complex queries' do
			let(:query) do
					"""
					WITH bogus_table AS (
						SELECT
							field_1,
							MIN(TO_DATE(CONCAT(TO_CHAR(timestamp, 'WW-'), DATE_PART(year, timestamp)), 'WW-YYYY')) AS timestamp,
							MIN(
								TO_DATE(
									CONCAT(
										TO_CHAR(
											timestamp, 'WW-'
										),
									DATE_PART(
										year,
										timestamp
									)
								), 'WW-YYYY'
							)
						) AS timestamp2
						FROM chezeborgers
					),
					moneky_brains AS (
						SELECT
							field_3,
							NTH_VALUE(rank, 2) OVER (
				        PARTITION BY great_ape_rank
				        ORDER BY created_at
				        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
				      ) AS next_monkey_rank
						FROM bogus_cte_table
					),
					ali_g AS (
						SELECT
						  booyakasha,
						  respek,
						  COUNT(respek) AS counts
					  FROM big_up_yourself
					  WHERE borat='false'
					  GROUP BY booyakasha, respek
					  ORDER BY respek
					)
					SELECT
						NTH_VALUE(title, 2) OVER (
			        PARTITION BY user_id
			        ORDER BY created_at
			        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			      ) AS subsequent_class
					FROM bogus_table
					LEFT JOIN moneky_brains
						ON moneky_brains.field_3=bogus_table.field_1
					UNION
					SELECT
						wingdings
					FROM nicky_cage
				"""
			end
			it 'parses the large query into 4 subqueries' do
				destructured_query = CteParser.new(query).parse!
				expect(destructured_query.length).to eql(4)
			end
			it 'orders the queries by order in which they should be executed' do
				destructured_query = CteParser.new(query).parse!
				expected_cte_names = ['bogus_table', 'moneky_brains', 'ali_g', nil]
				expect(destructured_query.map(&:cte_name)).to eql(expected_cte_names)
			end
			it 'identifies the first CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT
						field_1,
						MIN(TO_DATE(CONCAT(TO_CHAR(timestamp, 'WW-'), DATE_PART(year, timestamp)), 'WW-YYYY')) AS timestamp,
						MIN(
							TO_DATE(
								CONCAT(
									TO_CHAR(
										timestamp, 'WW-'
									),
								DATE_PART(
									year,
									timestamp
								)
							), 'WW-YYYY'
						)
					) AS timestamp2
					FROM chezeborgers
				"""
				expect(destructured_query[0].query).to eql(remove_whitespace(expected_query))
			end
			it 'identifies the second CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT
						field_3,
						NTH_VALUE(rank, 2) OVER (
			        PARTITION BY great_ape_rank
			        ORDER BY created_at
			        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			      ) AS next_monkey_rank
					FROM bogus_cte_table
				"""
				expect(destructured_query[1].query).to eql(remove_whitespace(expected_query))
			end
			it 'identifies the third CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT
					  booyakasha,
					  respek,
					  COUNT(respek) AS counts
				  FROM big_up_yourself
				  WHERE borat='false'
				  GROUP BY booyakasha, respek
				  ORDER BY respek
				"""
				expect(destructured_query[2].query).to eql(remove_whitespace(expected_query))
			end
			it 'identifies the non CTE query correctly' do
				destructured_query = CteParser.new(query).parse!
				expected_query = """
					SELECT
						NTH_VALUE(title, 2) OVER (
			        PARTITION BY user_id
			        ORDER BY created_at
			        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			      ) AS subsequent_class
					FROM bogus_table
					LEFT JOIN moneky_brains
						ON moneky_brains.field_3=bogus_table.field_1
					UNION
					SELECT
						wingdings
					FROM nicky_cage
				"""
				expect(destructured_query[3].query).to eql(remove_whitespace(expected_query))
			end
		end
	end
end