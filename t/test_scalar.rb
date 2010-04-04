# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Scalar < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_text_meta
		f = field '$(foo text 3 1..5)'
		assert_equal(
			3,
			f[:size],
			'Text#initialize should set :size from the token'
		)
		assert_equal(
			1,
			f[:min],
			'Text#initialize should set :min from the range token'
		)
		assert_equal(
			5,
			f[:max],
			'Text#initialize should set :max from the range token'
		)
	end

	def test_text_val_cast
		f = field '$(foo text 3 1..5)'
		assert_equal(
			'',
			f.val,
			'Text#val_cast should cast the given val to String'
		)

		f.load 123
		assert_equal(
			'123',
			f.val,
			'Text#val_cast should cast the given val to String'
		)
	end

	private

	def field(html)
		meta = nil
		Sofa::Parser.gsub_scalar(html) {|id,m|
			meta = m
			''
		}
		Sofa::Field.instance meta
	end

end
