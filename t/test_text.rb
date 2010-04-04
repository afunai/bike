# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Text < Test::Unit::TestCase

	def setup
		meta = nil
		Sofa::Parser.gsub_scalar('$(foo text 3 1..5)') {|id,m|
			meta = m
			''
		}
		@f = Sofa::Field.instance meta
	end

	def teardown
	end

	def test_meta
		assert_equal(
			3,
			@f[:size],
			'Text#initialize should set :size from the token'
		)
		assert_equal(
			1,
			@f[:min],
			'Text#initialize should set :min from the range token'
		)
		assert_equal(
			5,
			@f[:max],
			'Text#initialize should set :max from the range token'
		)
	end

	def test_val_cast
		assert_equal(
			'',
			@f.val,
			'Text#val_cast should cast the given val to String'
		)

		@f.load 123
		assert_equal(
			'123',
			@f.val,
			'Text#val_cast should cast the given val to String'
		)
	end

	def test_get
		@f.load 'bar'
		assert_equal(
			'bar',
			@f.get,
			'Text#get should return proper string'
		)
		assert_equal(
			'<input type="text" name="" value="bar" class="" />',
			@f.get(:action => :update),
			'Text#get should return proper string'
		)

		@f.load '<bar>'
		assert_equal(
			'&lt;bar&gt;',
			@f.get,
			'Text#get should escape the special characters'
		)
	end

end
