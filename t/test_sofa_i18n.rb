# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Sofa_I18n < Test::Unit::TestCase

	include Sofa::I18n

	def setup
	end

	def teardown
	end

	def test_lang
		Sofa::I18n.lang = 'ja'
		assert_instance_of(
			Array,
			Sofa::I18n.lang,
			'Sofa::I18n.lang should return an array'
		)
		assert_equal(
			['ja'],
			Sofa::I18n.lang,
			'Sofa::I18n.lang should return the current acceptable language-ranges'
		)
	end

	def test_multiple_lang
		Sofa::I18n.lang = 'ja,de;q=0.5,en;q=0.8'
		assert_equal(
			['ja','en','de'],
			Sofa::I18n.lang,
			'Sofa::I18n.lang should sort the language-ranges by their quality values'
		)
	end

	def test_same_qvalues
		Sofa::I18n.lang = 'ja,de;q=0.5,en;q=0.5'
		assert_equal(
			['ja','de','en'],
			Sofa::I18n.lang,
			'Sofa::I18n.lang should be sorted by their original order if the qvalues are same'
		)
		Sofa::I18n.lang = 'ja,de,en'
		assert_equal(
			['ja','de','en'],
			Sofa::I18n.lang,
			'Sofa::I18n.lang should be sorted by their original order if the qvalues are same'
		)
	end

end
