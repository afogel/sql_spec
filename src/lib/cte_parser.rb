require 'pry-byebug'

# It'd be nice to figure out why I can't set using attr_accessor methods.
class CteParser
	Query = Struct.new(:query, :cte_name)

	attr_accessor :cte_name,
								:input_query,
								:inside_subquery,
								:parenthesis_depth,
								:return_queries,
								:subquery,
								:tokenized_query

	def initialize(full_query)
		@cte_name = nil
		@input_query = full_query.split(' ')
		@inside_subquery = false
		@parenthesis_depth = 0
		@return_queries = []
		@subquery = []
		@tokenized_query = input_query.map(&:downcase)
	end

	def parse!
		tokenized_query.each_with_index do |token, index|
			set_cte_name!(index) if cte_declaration_complete?(token, index)
			toggle_subquery_building! if beginning_new_query?(token)

			# TODO: DRY up conditional branches
			if inside_subquery
				if token.include?('(') || !token.include?(')') || (token.include?(')') && parenthesis_depth > 1)
					add_term_to_query!(index)
				elsif (token.include?(')') && parenthesis_depth <= 1)
					if cte_query_being_built?
						add_term_to_query!(index)
					else
						finalize_subquery!
					end
				else
					raise 'Parsing error!'
				end
			end

			increment_parenthesis_depth!(token)
			decrement_parenthesis_depth!(token)
			finalize_subquery! if index == tokenized_query.length - 1
		end
		return_queries
	end

	private

	def beginning_new_query?(token)
		token.include?('select')
	end

	def set_cte_name!(index)
		@cte_name = tokenized_query[index - 2]
	end

	def cte_declaration_complete?(token, index)
		token.include?('(') && tokenized_query[index - 1] == 'as'
	end

	def output_token(index)
		input_query[index]
	end

	def increment_parenthesis_depth!(token)
		@parenthesis_depth += token.count('(') if token.include?('(')
	end

	def decrement_parenthesis_depth!(token)
		@parenthesis_depth -= token.count(')') if token.include?(')')
	end

	def cte_query_being_built?
		cte_name.nil?
	end

	def add_term_to_query!(index)
		subquery.push(input_query[index])
	end

	def finalize_subquery!
		return_queries.push(Query.new(subquery.join(' '), cte_name))
		reset_state_used_to_build_subqueries!
	end

	def reset_state_used_to_build_subqueries!
		@inside_subquery = false
		subquery.clear
		@cte_name = nil
	end

	def toggle_subquery_building!
		@inside_subquery = true
	end
end