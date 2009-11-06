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
				'title' => {:klass => 'text',:tokens => ['32']},
				'foo'   => {
					:klass    => 'list',
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
	<ul id="main" class="sofa-blog">
		<li>hi</li>
	</ul>
</html>
_html
		title = set.item('title')
		assert_instance_of(
			Sofa::Field::Text,
			title,
			'Set#item() should return the child item on the fly'
		)
		assert_equal(
			title.object_id,
			set.item('title').object_id,
			'Set#item() should cache the loaded items'
		)
		assert_equal(
			32,
			title[:size],
			'Set#item() should load the metas of child items'
		)

		main = set.item('main')
		assert_instance_of(
			Sofa::Field::List,
			main,
			'Set#item() should return the child item on the fly'
		)
		assert_equal(
			main.object_id,
			set.item('main').object_id,
			'Set#item() should cache the loaded items'
		)
		assert_equal(
			"\t\t<li>hi</li>\n",
			main[:html],
			'Set#item() should load the metas of child items'
		)
	end

	def test_val
		set = Sofa::Field::Set.new(:html => <<'_html')
<li>
	name:(text): comment:(text)
</li>
_html
		set.item('name').load 'foo'
		assert_equal(
			{'name' => 'foo'},
			set.val,
			'Set#val should not include the value of the empty item'
		)
		set.item('comment').load 'bar'
		assert_equal(
			{'name' => 'foo','comment' => 'bar'},
			set.val,
			'Set#val should not include the value of the empty item'
		)
	end

	def test_load_default
		set = Sofa::Field::Set.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.load_default
		assert_equal(
			'nobody',
			set.item('name').val,
			'Set#load_default should load all the child items with their [:default]'
		)
		assert_equal(
			'peek a boo',
			set.item('comment').val,
			'Set#load_default should load all the child items with their [:default]'
		)
	end

	def tttt
		set.post(:load,'name' => 'frank','comment' => 'cut the schmuck some slack.')
		assert_equal(
			'frank',
			set.item('name').val,
			'Set#post should distribute given vals to the child items'
		)
	end

end
