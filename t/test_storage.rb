# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Storage < Test::Unit::TestCase

	def setup
		@list = Sofa::Field::List.new(
			:id       => 'main',
			:klass    => 'list',
			:parent   => Sofa::Field.instance(:id => 'foo',:klass => 'set-folder'),
			:set_html => <<'_html'
	<li>
		name:(text 32)
		comment:(text 64)
	</li>
_html
		)
	end

	def teardown
	end

	def test_instance
		assert_kind_of(
			Sofa::Storage,
			Sofa::Storage.instance(@list),
			'Storage.instance should return a storage instance according to the list'
		)
	end

end
