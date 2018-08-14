require 'colorize'

module Test
	Assertion = Struct.new(:outcome, :output_1, :output_2) do
		def to_s
			"expected #{output_1} to equal #{output_2}"
		end
	end
	def self.it(test_description)
		a = yield
		if a.outcome
			puts "it #{test_description}".green
		else
			puts "it #{test_description}".red
			puts a.to_s.red
		end
	end
	def self.assert_equal(statement_1, statement_2)
		output_1 = statement_1
		output_2 = statement_2
		outcome = output_1 == output_2
		Assertion.new(outcome, output_1, output_2)
	end
	def self.assert_not_equal(statement_1, statement_2)
		output_1 = statement_1
		output_2 = statement_2
		outcome = output_1 != output_2
		Assertion.new(outcome, output_1, output_2)
	end
end



