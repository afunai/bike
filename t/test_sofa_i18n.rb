# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Sofa_I18n < Test::Unit::TestCase

	include Sofa::I18n

	def setup
		Sofa::I18n.po_dir = './t/locale'
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

	def test_lang_downcase
		Sofa::I18n.lang = 'ja-JP'
		assert_equal(
			['ja-jp'],
			Sofa::I18n.lang,
			'Sofa::I18n.lang should be downcased'
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

	def test_po_dir
		Sofa::I18n.po_dir = 'foo/bar'
		assert_equal(
			'foo/bar',
			Sofa::I18n.po_dir,
			'Sofa::I18n.po_dir should be return the path to po files'
		)
	end

	def test_msg
		Sofa::I18n.lang = 'ja'
		assert_instance_of(
			::Hash,
			Sofa::I18n.msg,
			'Sofa::I18n.msg should return a hash'
		)
		assert_equal(
			{'color' => '色','one color' =>['%{n}色']},
			Sofa::I18n.msg,
			'Sofa::I18n.msg should return a hash containing {msgid => msgstr}'
		)

		Sofa::I18n.lang = 'po'
		assert_equal(
			{},
			Sofa::I18n.msg,
			'Sofa::I18n.msg should be reset when the lang is updated'
		)
	end

	def test_merge_msg!
		Sofa::I18n.lang = 'no'
		assert_equal({},Sofa::I18n.msg)

		Sofa::I18n.merge_msg!('color' => 'farge')
		assert_equal(
			{'color' => 'farge'},
			Sofa::I18n.msg,
			'Sofa::I18n.merge_msg! should dynamically merge a hash to the msg of the current thread'
		)

		Sofa::I18n.lang = 'no'
		assert_equal(
			{},
			Sofa::I18n.msg,
			'Sofa::I18n.merge_msg! should not affect anything other than the current thread'
		)
	end

	def test__
		Sofa::I18n.lang = 'ja'
		assert_equal(
			'色',
			_('color'),
			'Sofa::I18n#_() should return the string according to the msgid'
		)

		Sofa::I18n.lang = 'en-GB'
		assert_equal(
			'colour',
			_('color'),
			'Sofa::I18n#_() should return the string according to the msgid'
		)

		Sofa::I18n.lang = 'no'
		assert_equal(
			'color',
			_('color'),
			'Sofa::I18n#_() should return msgid if the msgid is not existed in the msg'
		)
	end

end
