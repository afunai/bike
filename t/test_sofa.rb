# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Sofa < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_session
		assert(
			Sofa.session.respond_to?(:[]),
			'Sofa.session should be a Session or Hash'
		)
	end

	def test_client
		Sofa.client = nil
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa.client should return nobody before login'
		)

		Sofa.client = 'frank'
		assert_equal(
			'frank',
			Sofa.client,
			'Sofa.client should return the user who logged in'
		)

		Sofa.client = nil
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa.client should return nobody after logout'
		)
	end

end
