# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Sofa_I18n < Test::Unit::TestCase

	include Sofa::I18n

	def setup
		Sofa::I18n.domain = 'index'
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

	def test_lang_case
		Sofa::I18n.lang = 'JA-jp'
		assert_equal(
			['ja-JP'],
			Sofa::I18n.lang,
			'Sofa::I18n.lang should be properly downcase/upcased'
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

	def test_domain
		Sofa::I18n.domain = 'foo'
		assert_equal(
			'foo',
			Sofa::I18n.domain,
			'Sofa::I18n.domain should be return the current domain'
		)
	end

	def test_bindtextdomain
		Sofa::I18n.bindtextdomain('foo','bar/baz')
		assert_equal(
			'foo',
			Sofa::I18n.domain,
			'Sofa::I18n.bindtextdomain should set the current domain'
		)
		assert_equal(
			'bar/baz',
			Sofa::I18n.po_dir,
			'Sofa::I18n.bindtextdomain should set the path to po files'
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
			Sofa::I18n.msg.reject {|k,v| k == :plural },
			'Sofa::I18n.msg should return a hash containing {msgid => msgstr}'
		)
		assert_instance_of(
			::Proc,
			Sofa::I18n.msg[:plural],
			'Sofa::I18n.msg[:plural] should return a proc'
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

		Sofa::I18n.merge_msg!(:plural => Proc.new { 123 })
		assert_equal(
			{'color' => 'farge'},
			Sofa::I18n.msg,
			'Sofa::I18n.merge_msg! should not merge :plural'
		)

		Sofa::I18n.lang = 'no'
		assert_equal(
			{},
			Sofa::I18n.msg,
			'Sofa::I18n.merge_msg! should not affect anything other than the current thread'
		)
	end

	def test_rex_plural_expression_ok
		src = <<'_eos'.split "\n"
"Plural-Forms: nplurals=1; plural=0;"
"Plural-Forms: nplurals=2; plural=n != 1;"
"Plural-Forms: nplurals=2; plural=n>1;"
"Plural-Forms: nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2;"
"Plural-Forms: nplurals=3; plural=n==1 ? 0 : n==2 ? 1 : 2;"
"Plural-Forms: nplurals=3; Plural=n==1 ? 0 : (n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2;"
"Plural-Forms: nplurals=3; Plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2;"
"Plural-Forms: nplurals=3; Plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;"
"Plural-Forms: nplurals=3; Plural=(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2;"
"Plural-Forms: nplurals=3; Plural=n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;"
"Plural-Forms: nplurals=4; Plural=n%100==1 ? 0 : n%100==2 ? 1 : n%100==3 || n%100==4 ? 2 : 3;"
_eos
		src.each {|s|
			assert_match(
				Sofa::I18n::REX::PLURAL_EXPRESSION,
				s,
				'Sofa::I18n::REX::PLURAL_EXPRESSION should match'
			)
		}
	end

	def test_rex_plural_expression_ng
		src = <<'_eos'.split "\n"
"Plural-Forms: nplurals=1; plural=rm '.';"
"Plural-Forms: nplurals=1; plural=Fileutils.rm_r('.');"
"Plural-Forms: nplurals=1; plural=Fileutils.rm_r '.';"
"Plural-Forms: nplurals=1; plural=Fileutils.rm_r ".";"
"Plural-Forms: nplurals=2; plural=n;"
"Plural-Forms: nplurals=2; plural=nn;"
"Plural-Forms: nplurals=3; plural=n();"
"Plural-Forms: nplurals=3; plural=n(123);"
"Plural-Forms: nplurals=3; plural=n 123;"
_eos
		src.each {|s|
			assert_no_match(
				Sofa::I18n::REX::PLURAL_EXPRESSION,
				s,
				'Sofa::I18n::REX::PLURAL_EXPRESSION should not match malicious expressions'
			)
		}
	end

	def test__
		Sofa::I18n.lang = 'ja'
		assert_equal(
			'色',
			_('color'),
			'Sofa::I18n#_() should return a string according to the msgid'
		)

		Sofa::I18n.lang = 'en-GB'
		assert_equal(
			'colour',
			_('color'),
			'Sofa::I18n#_() should return a string according to the msgid'
		)

		Sofa::I18n.lang = 'no'
		assert_equal(
			'color',
			_('color'),
			'Sofa::I18n#_() should return a msgid if the msgid is not existed in the msg'
		)
	end

	def test_n_
		Sofa::I18n.lang = 'ja'
		assert_equal(
			'%{n}色',
			n_('one color','%{n} colors',1),
			'Sofa::I18n#n_() should return a string according to the msgid and the n'
		)
		assert_equal(
			'%{n}色',
			n_('one color','%{n} colors',2),
			'Sofa::I18n#n_() should return a string according to the msgid and the n'
		)

		Sofa::I18n.lang = 'en-GB'
		assert_equal(
			'one colour',
			n_('one color','%{n} colors',1),
			'Sofa::I18n#n_() should return a string according to the msgid and the n'
		)
		assert_equal(
			'%{n} colours',
			n_('one color','%{n} colors',2),
			'Sofa::I18n#n_() should return a string according to the msgid and the n'
		)

		Sofa::I18n.lang = 'no'
		assert_equal(
			'one color',
			n_('one color','%{n} colors',1),
			'Sofa::I18n#_() should return a msgid if the msgid is not existed in the msg'
		)
		assert_equal(
			'%{n} colors',
			n_('one color','%{n} colors',2),
			'Sofa::I18n#_() should return a msgid if the msgid is not existed in the msg'
		)
	end

	def test__with_n_
		Sofa::I18n.lang = 'en-GB'
		assert_equal(
			'one colour',
			_('one color'),
			'Sofa::I18n#_() should return msgstr[0] if the msgid refer to plural msgstrs'
		)
	end

	def test_msgstr
		Sofa::I18n.lang = 'en-GB'

		assert_instance_of(
			Sofa::I18n::Msgstr,
			_('color'),
			'Sofa::I18n#_() should return a instance of Sofa::I18n::Msgstr'
		)

		s = n_('one color','%{n} colors',2)
		assert_instance_of(
			Sofa::I18n::Msgstr,
			s,
			'Sofa::I18n#n_() should return a instance of Sofa::I18n::Msgstr'
		)
		assert_equal(
			'2 colours',
			s % {:n => 2},
			'Sofa::I18n::Msgstr#% should be able to proccess named variables'
		)
		assert_equal(
			'2 colours',
			s % [2],
			"Sofa::I18n::Msgstr#% should regard %{...} as '%s' if given an array"
		)
		assert_equal(
			'2 colours',
			s % 2,
			"Sofa::I18n::Msgstr#% should regard %{...} as '%s' if given a scalar"
		)

		s = n_('one color','%{n} colors',1)
		assert_instance_of(
			Sofa::I18n::Msgstr,
			s,
			'Sofa::I18n#n_() should return a instance of Sofa::I18n::Msgstr'
		)
		assert_equal(
			'one colour',
			s % {:n => 1},
			'Sofa::I18n::Msgstr#% should work with msgstrs without a placeholder'
		)
	end

end
