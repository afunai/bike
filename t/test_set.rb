# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_initialize
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
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
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl',
<ul id="foo" class="sofa-blog">$()</ul>
_tmpl
					:set_html => <<'_html',
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
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
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
			Sofa::Field::Set::Static::Dynamic,
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
			main[:set_html],
			'Set#item() should load the metas of child items'
		)
	end

	def test_val
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
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

	def test_get
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.load_default
		assert_equal(
			<<'_html',
<li>
	nobody: peek a boo
</li>
_html
			set.get,
			'Set#get should return the html by [:tmpl]'
		)

		comment = set.item('comment')
		def comment._get_foo(arg)
			'foo foo'
		end
		assert_equal('foo foo',set.item('comment').get(:action => 'foo'))
		assert_equal(
			<<'_html',
<li>
	nobody: foo foo
</li>
_html
			set.get(:action => 'foo'),
			'Set#get should pass :action to the child items'
		)
	end

	def test_recursive_tmpl
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
<li>$()</li>
_html
		assert_nothing_raised(
			'Set#get should avoid recursive reference to [:tmpl]'
		) {
			set.get
		}
	end

	def test_load_default
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
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

	def test_load
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.load('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			set.val,
			'Set#load should not touch the item for which value is not given'
		)
		set.load('name' => 'frank','comment' => 'cut the schmuck some slack.')
		assert_equal(
			{'name' => 'frank','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set#load should load the items at once'
		)
		set.load('name' => 'carl')
		assert_equal(
			{'name' => 'carl','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set#load should not touch the item for which value is not given'
		)
	end

	def test_create
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.create('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			set.val,
			'Set#create should not touch the item for which value is not given'
		)
	end

	def test_update
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.update('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			set.val,
			'Set#update should not touch the item for which value is not given'
		)
		set.update('name' => 'frank','comment' => 'cut the schmuck some slack.')
		assert_equal(
			{'name' => 'frank','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set#udpate should load the items at once'
		)
		set.update('name' => 'carl')
		assert_equal(
			{'name' => 'carl','comment' => 'cut the schmuck some slack.'},
			set.val,
			'Set#update should not touch the item for which value is not given'
		)
	end

	def test_delete
		set = Sofa::Field::Set::Static.new(:html => <<'_html')
<li>
	name:(text 32 :'nobody'): comment:(text 128 :'peek a boo')
</li>
_html
		set.item('name').load 'foo'

		set.delete
		assert(
			set.deleted?,
			'Set#delete should set deleted?() to true'
		)
		assert_equal(
			{'name' => 'foo'},
			set.val,
			'Set#delete should not touch any item'
		)
	end

end
