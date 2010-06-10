# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Set_Static < Test::Unit::TestCase

	def setup
	end

	def teardown
	end

	def test_initialize
		ss = Runo::Set::Static.new(:html => <<'_html')
<html>
	<h1>$(title text 32)</h1>
	<ul id="foo" class="runo-blog">
		<li title="Diary">
			$(subject text 64)
			$(body textarea 72*10)
			<ul><li>qux</li></ul>
		</li>
	</ul>
</html>
_html
		assert_equal(
			{
				'title' => {:klass => 'text', :tokens => ['32']},
				'foo'   => {
					:klass    => 'set-dynamic',
					:workflow => 'blog',
					:tmpl     => <<'_tmpl'.chomp,
	<ul id="@(name)" class="runo-blog">
$()	</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
					:item     => {
						'default' => {
							:label => 'Diary',
							:tmpl  => <<'_tmpl',
		<li title="">
			$(.a_update)$(subject)</a>
			$(body)$(.hidden)
			<ul><li>qux</li></ul>
		</li>
_tmpl
							:item  => {
								'body'    => {
									:width  => 72,
									:height => 10,
									:klass  => 'textarea',
								},
								'subject' => {
									:klass  => 'text',
									:tokens => ['64'],
								},
							},
						},
					},
				},
			},
			ss[:item],
			'Set::Static#initialize should load @meta'
		)
	end

	def test_empty?
		ss = Runo::Set::Static.new(:html => <<'_html')
<html>
	<h1>$(title = text 32)</h1>
</html>
_html
		ss.load 'title' => 'foo'
		assert(
			!ss.empty?,
			'Set::Static#empty? should return false if any item has a value'
		)

		ss.load 'title' => nil
		assert(
			ss.empty?,
			'Set::Static#empty? should return true if the all items do not have a value'
		)

		ss.load 'title' => ''
		assert(
			ss.empty?,
			'Set::Static#empty? should return true if the all items do not have a value'
		)
	end

	def test_item
		ss = Runo::Set::Static.new(:html => <<'_html')
<html>
	<h1>$(title = text 32)</h1>
	<ul id="main" class="runo-attachment">
		<li>hi</li>
	</ul>
</html>
_html
		title = ss.item('title')
		assert_instance_of(
			Runo::Text,
			title,
			'Set::Static#item() should return the child item on the fly'
		)
		assert_equal(
			title.object_id,
			ss.item('title').object_id,
			'Set::Static#item() should cache the loaded items'
		)
		assert_equal(
			32,
			title[:size],
			'Set::Static#item() should load the metas of child items'
		)

		main = ss.item('main')
		assert_instance_of(
			Runo::Set::Static::Dynamic,
			main,
			'Set::Static#item() should return the child item on the fly'
		)
		assert_equal(
			main.object_id,
			ss.item('main').object_id,
			'Set::Static#item() should cache the loaded items'
		)
		assert_equal(
			{
				'default' => {
					:label => nil,
					:tmpl  => "\t\t<li>hi</li>\n",
					:item  => {},
				},
			},
			main[:item],
			'Set::Static#item() should load the metas of child items'
		)

		assert_nil(
			ss.item('non-existent'),
			'Set::Static#item should return nil when the item is not in the storage'
		)
		assert_nil(
			ss.item(''),
			'Set::Static#item should return nil when the item is not in the storage'
		)
	end

	def test_val
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name text): $(comment text)
</li>
_html
		ss.item('name').load 'foo'
		assert_equal(
			{'name' => 'foo'},
			ss.val,
			'Set::Static#val should not include the value of the empty item'
		)
		ss.item('comment').load 'bar'
		assert_equal(
			{'name' => 'foo', 'comment' => 'bar'},
			ss.val,
			'Set::Static#val should not include the value of the empty item'
		)
	end

	def test_get
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.load_default
		assert_equal(
			<<'_html',
<li>
	nobody: peek a boo
</li>
_html
			ss.get,
			'Set::Static#get should return the html by [:tmpl]'
		)

		comment = ss.item('comment')
		def comment._g_foo(arg)
			'foo foo'
		end
		assert_equal('foo foo', ss.item('comment').get(:action => 'foo'))
		assert_equal(
			<<'_html',
<li>
	nobody: foo foo
</li>
_html
			ss.get(:action => 'foo'),
			'Set::Static#get should pass :action to the child items'
		)
	end

	def test_get_by_tmpl
		ss = Runo::Set::Static.new(:html => '$(foo text)')
		ss.item('foo').load 'hello'
		assert_equal(
			'foo hello foo',
			ss.send(:_get_by_tmpl, {}, 'foo $() foo'),
			'Set#_get_by_tmpl should replace %() with @val'
		)

		ss[:baz] = 1234
		assert_equal(
			'foo 1234 foo',
			ss.send(:_get_by_tmpl, {}, 'foo @(baz) foo'),
			'Set#_get_by_tmpl should replace @(...) with @meta[...]'
		)

		assert_equal(
			'foo baz foo',
			ss.send(:_get_by_tmpl, {}, 'foo _(baz) foo'),
			'Set#_get_by_tmpl should evaluate _(...)'
		)
	end

	def test_recursive_tmpl
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>$()</li>
_html
		assert_nothing_raised(
			'Set::Static#get should avoid recursive reference to [:tmpl]'
		) {
			ss.get
		}
	end

	def test_g_a_update
		ss = Runo::Set::Static.new(:html => '$(.a_update)', :parent => Runo::Set::Static.new)

		def ss.permit_get?(arg)
			true
		end
		assert_equal(
			'<a href="/update.html">',
			ss.get(:action => :read),
			'Set#_g_a_update should return href if the orig_action is :read and :update is permmited'
		)
		assert_equal(
			'<a>',
			ss.get(:action => :update),
			'Set#_g_a_update should omit href if the orig_action is not :read'
		)

		def ss.permit_get?(arg)
			true if arg[:action] == :read
		end
		def ss.permit?(action)
			true if action == :read
		end
		assert_equal(
			'<a>',
			ss.get(:action => :read),
			'Set#_g_a_update should omit href unless :update is permmited'
		)

		def ss.permit_get?(arg)
			true unless arg[:action] == :update
		end
		def ss.permit?(action)
			true unless action == :update
		end
		assert_equal(
			'<a href="/preview_delete.html">',
			ss.get(:action => :read),
			'Set#_g_a_update should return href to :preview_delete if only :delete is permmited'
		)
	end

	def test_post
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.post(:create, 'name' => 'carl')
		assert_equal(
			:create,
			ss.action,
			'Set::Static#post should set @action'
		)

		ss.commit
		assert_equal(
			:create,
			ss.result,
			'Set::Static#commit should set @result'
		)

		ss.post(:update, 'name' => 'carl')
		assert_nil(
			ss.result,
			'Set::Static#post should reset @result'
		)
	end

	def test_load_default
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.load_default
		assert_equal(
			'nobody',
			ss.item('name').val,
			'Set::Static#load_default should load all the child items with their [:default]'
		)
		assert_equal(
			'peek a boo',
			ss.item('comment').val,
			'Set::Static#load_default should load all the child items with their [:default]'
		)
	end

	def test_load
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.load('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			ss.val,
			'Set::Static#load should not touch the item for which value is not given'
		)
		ss.load('name' => 'frank', 'comment' => 'cut the schmuck some slack.')
		assert_equal(
			{'name' => 'frank', 'comment' => 'cut the schmuck some slack.'},
			ss.val,
			'Set::Static#load should load the items at once'
		)
		ss.load('name' => 'carl')
		assert_equal(
			{'name' => 'carl', 'comment' => 'cut the schmuck some slack.'},
			ss.val,
			'Set::Static#load should not touch the item for which value is not given'
		)
	end

	def test_create
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.create('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			ss.val,
			'Set::Static#create should not touch the item for which value is not given'
		)
	end

	def test_update
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.update('name' => 'carl')
		assert_equal(
			{'name' => 'carl'},
			ss.val,
			'Set::Static#update should not touch the item for which value is not given'
		)
		ss.update('name' => 'frank', 'comment' => 'cut the schmuck some slack.')
		assert_equal(
			{'name' => 'frank', 'comment' => 'cut the schmuck some slack.'},
			ss.val,
			'Set::Static#udpate should load the items at once'
		)
		ss.update('name' => 'carl')
		assert_equal(
			{'name' => 'carl', 'comment' => 'cut the schmuck some slack.'},
			ss.val,
			'Set::Static#update should not touch the item for which value is not given'
		)

		assert_nil(
			ss.result,
			'Set::Static#result should return nil before the commit'
		)
		ss.commit
		assert_equal(
			{
				'name'    => ss.item('name'),
				'comment' => ss.item('comment'),
			},
			ss.result,
			'Set::Static#result should return a hash of the committed items when :update'
		)
	end

	def test_delete
		ss = Runo::Set::Static.new(:html => <<'_html')
<li>
	$(name = text 32 :'nobody'): $(comment = text 128 :'peek a boo')
</li>
_html
		ss.item('name').load 'foo'

		ss.delete
		assert_equal(
			:delete,
			ss.action,
			'Set::Static#delete should set @action'
		)
		assert_equal(
			{'name' => 'foo'},
			ss.val,
			'Set::Static#delete should not touch any item'
		)
	end

end
