# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_initialize
		set = Sofa::Field::Set.new(:html => <<'_html')
<html>
	<h1>title:(text 32)</h1>
	<ul id="foo" class="sofa-blog">
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
	</ul>
</html>
_html
		assert_equal(
			{
				'title' => {:klass => 'Text',:tokens => ['32']},
				'foo'   => {
					:klass    => 'List',
					:workflow => 'blog',
					:html     => <<'_html',
		<li>
			subject:(text 64)
			body:(textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
_html
				},
			},
			set[:item],
			'Set#initialize should load @meta'
		)
	end

	def test_item
		set = Sofa::Field::Set.new(:html => <<'_html')
<html>
	<h1>title:(text 32)</h1>
	<ul id="foo" class="sofa-blog">
	</ul>
</html>
_html
return
		assert_instance_of(
			Sofa::Field::Text,
			set.item('title'),
			'Set#item() should return the child item on the fly'
		)
	end

end
