# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require 'rubygems'
require 'rack'

class TC_Sofa_Call < Test::Unit::TestCase

	def setup
		@sofa = Sofa.new
	end

	def teardown
	end

	def test_get
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/'
		)
		assert_match(
			/<html/,
			res.body,
			'Sofa#call() should return the folder.get if the base field is a SD'
		)
	end

	def test_get_non_exist
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/non/exist/'
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call() should return 404 if the given path is non-existent'
		)
	end

	def test_get_partial
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/20091120_0001/name/'
		)
		assert_equal(
			'FZ',
			res.body,
			'Sofa#call() should return the base.get unless the base field is a SD'
		)
	end

	def test_get_sub
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/'
		)
		assert_match(
			%r{<li><a>qux</a></li>},
			res.body,
			"Sofa#call() should return sets other than 'main' as well"
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/sub/d=2010/'
		)
		assert_match(
			%r{<li><a>qux</a></li>},
			res.body,
			"Sofa#call() should pass args for a sd other than 'main' as well"
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/sub/d=2009/'
		)
		assert_no_match(
			%r{<li><a>qux</a></li>},
			res.body,
			"Sofa#call() should pass args for a sd other than 'main' as well"
		)
	end

	def test_get_enquete
		Sofa.client = nil
		Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.clear

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/1234567890.0123/t_enquete/'
		)
		assert_equal(
			200,
			res.status,
			'Sofa#call to enquete by nobody should return status 200'
		)
		assert_equal(
			<<'_html',
<html>
	<head><title>Root Folder</title></head>
	<body>
		<h1>Root Folder</h1>
<form id="main" method="post" enctype="multipart/form-data" action="/t_enquete/1234567890.0123/update.html">
		<ul id="main" class="sofa-enquete">
			<li><a><input type="text" name="_001-name" value="foo" class="" /></a>: <input type="text" name="_001-comment" value="bar!" class="" /></li>
		</ul>
<input name=".status-public" type="submit" value="create" />
</form>
	</body>
</html>
_html
			res.body,
			'Sofa#call to enquete by nobody should return :create'
		)
	end

	def test_get_enquete_forbidden
		Sofa.client = nil
		Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.build(
			'20100425_1234' => {'name' => 'cz','comment' => 'howdy.'}
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425/1234/index.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'getting an enquete by nobody should not return any contents'
		)
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425_1234/'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'peeking an enquete by nobody should not return any contents'
		)
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425_1234/comment/'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'peeking an enquete by nobody should not return any contents'
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425/1234/done.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'getting an enquete by nobody should not return any contents'
		)
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425_1234/done.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'peeking an enquete by nobody should not return any contents'
		)
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425_1234/comment/done.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'peeking an enquete by nobody should not return any contents'
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425/1234/confirm_create.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'getting an enquete by nobody should not return any contents'
		)
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425_1234/confirm_create.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'peeking an enquete by nobody should not return any contents'
		)
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/20100425_1234/comment/confirm_create.html'
		)
		assert_no_match(
			/howdy/,
			res.body,
			'peeking an enquete by nobody should not return any contents'
		)
	end

	def test_get_summary
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_summary/p=1/'
		)
		assert_equal(
			<<'_html',
<h1>summary</h1>
<table id="main" class="sofa-blog">
	<tr><td><a href="/t_summary/20100326/1/read_detail.html">frank</a></td><td>hi.</td></tr>
</table>
_html
			res.body,
			'Sofa#call() should use [:tmpl_summary] when available and appropriate'
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_summary/p=1/read_detail.html'
		)
		assert_equal(
			<<'_html',
<h1>index</h1>
<ul id="main" class="sofa-blog">
	<li><a>frank</a>: hi.</li>
</ul>
_html
			res.body,
			'Sofa#call() should use [:tmpl] when the action is :read -> :detail'
		)

		Sofa.client = 'root'
		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/t_summary/p=1/update.html"
		)
		tid = res.body[%r{/(#{Sofa::REX::TID})/},1]
		assert_equal(
			<<"_html",
<h1>index</h1>
<form id="main" method="post" enctype="multipart/form-data" action="/t_summary/#{tid}/update.html">
<ul id="main" class="sofa-blog">
	<li><a><input type="text" name="20100326_0001-name" value="frank" class="" /></a>: <input type="text" name="20100326_0001-comment" value="hi." class="" /></li>
</ul>
<input name=".status-public" type="submit" value="update" />
<input name=".action-confirm_delete" type="submit" value="delete..." />
</form>
_html
			res.body,
			'Sofa#call() should use [:tmpl] unless the action is :read'
		)
	end

	def test_get_static
		Sofa.client = 'root'
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/css/foo.css'
		)
		assert_equal(
			200,
			res.status,
			'Sofa#call should return a static file if the given path is under css/, js/, etc.'
		)
		assert_equal(
			'text/css',
			res.headers['Content-Type'],
			'Sofa#call should return a static file if the given path is under css/, js/, etc.'
		)
		assert_equal(
			"#foo {bar: baz;}\n",
			res.body,
			'Sofa#call should return a static file if the given path is under css/, js/, etc.'
		)
	end

	def test_get_static_not_css
		Sofa.client = 'root'
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/not_css/foo.css'
		)
		assert_not_equal(
			"#foo {bar: baz;}\n",
			res.body,
			'Sofa#call should not return a static file if the step is not exactly css/, js/, etc.'
		)
	end

	def test_get_static_non_exist
		Sofa.client = 'root'
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/foo/css/non-exist.css'
		)
		assert_equal(
			404,
			res.status,
			'Sofa#call should return 404 if the static file is not found'
		)
	end

	def test_get_static_forbidden
		Sofa.client = 'root'
		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/_users/00000000_test.yaml'
		)
		assert_no_match(
			/^password/,
			res.body,
			'Sofa#call should not return meta files nor raw data'
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/_users/css/../00000000_test.yaml'
		)
		assert_no_match(
			/password/,
			res.body,
			'Sofa#call should not allow bad paths'
		)
	end

	def test_post_simple_create
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with post method should return status 303'
		)
		assert_match(
			Sofa::REX::PATH_ID,
			res.headers['Location'],
			'Sofa#call with post method should return a proper location'
		)

		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id = sprintf('%.8d_%.4d',$1,$2)

		val = Sofa::Set::Static::Folder.root.item('t_store','main',new_id).val
		assert_instance_of(
			::Hash,
			val,
			'Sofa#call with post method should store the item in the storage'
		)
		val.delete '_timestamp'
		assert_equal(
			{'_owner' => 'root','name' => 'fz','comment' => 'hi.'},
			val,
			'Sofa#call with post method should store the item in the storage'
		)
	end

	def test_post_invalid_create
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/t_store/main/update.html",
			{
				:input => "_1-name=tooooooooooooloooooooooooooooooooooooooooong&_1-comment=hi.&.status-public=create"
			}
		)
		tid = res.body[%r{/(#{Sofa::REX::TID})/},1]

		assert_equal(
			422,
			res.status,
			'Sofa#post with an invalid new item should be an error'
		)
		assert_instance_of(
			Sofa::Set::Dynamic,
			Sofa.transaction[tid],
			'the suspended SD should be kept in Sofa.transaction'
		)
	end

	def test_post_empty_create
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_1-name=&_1-comment=&.status-public=create"
			}
		)
		assert_equal(
			422,
			res.status,
			'Sofa#post with an empty new item should be an error'
		)
	end

	def test_post_empty_update
		Sofa.client = 'root'

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_1-name=don&_1-comment=brown.&.status-public=create"
			}
		)
		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id   = sprintf('%.8d_%.4d',$1,$2)

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "#{new_id}-name=don&.status-public=update"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#post without any update on the item should not raise an error'
		)

		res = Rack::MockRequest.new(@sofa).get(
			res.headers['Location']
		)
		assert_no_match(
			/message/,
			res.body,
			'Sofa#post without any update on the item should not set any messages'
		)
	end

	def test_post_with_attachment
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_attachment','main').storage.clear

		# post an attachment
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_attachment/main/update.html',
			{
				:input => "_012-files-_1-file=wow.jpg&_012-files-_1.action-create=create"
			}
		)
		assert_match(
			'update.html',
			res.headers['Location'],
			'Sofa#call without the root status should always return :update'
		)
		assert_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call without the root status should not update the persistent storage'
		)

		tid = res.headers['Location'][Sofa::REX::TID]
		assert_instance_of(
			Sofa::Set::Dynamic,
			Sofa.transaction[tid],
			'the suspended SD should be kept in Sofa.transaction'
		)

		# post the item
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "_012-comment=hello.&.status-public=create"
			}
		)
		assert_no_match(
			/update\.html/,
			res.headers['Location'],
			'Sofa#call with the root status should commit the transaction'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call with the root status should update the persistent storage'
		)

		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id   = sprintf('%.8d_%.4d',$1,$2)
		new_item = Sofa::Set::Static::Folder.root.item('t_attachment','main',new_id)
		assert_not_equal(
			{},
			new_item.val,
			'Sofa#call with the root status should commit all the pending items'
		)
		assert_equal(
			'hello.',
			new_item.val['comment'],
			'Sofa#call with the root status should commit the root items'
		)
		assert_equal(
			{'file' => 'wow.jpg'},
			new_item.val['files'].values.first,
			'Sofa#call with the root status should commit the descendant items'
		)

		# post a reply
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/t_attachment/main/#{new_id}/replies/update.html",
			{
				:input => "_001-reply=wow.&.status-public=create"
			}
		)
		assert_equal(303,res.status)
		assert_match(
			%r{/#{Sofa::REX::TID}/t_attachment/#{new_id}/replies/read_detail.html},
			res.headers['Location'],
			'Sofa#call with a sub-app status should commit the root item'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main',new_id,'replies').val,
			'Sofa#call with a sub-app status should update the persistent storage'
		)
	end

	def test_post_only_attachment
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_attachment','main').storage.clear

		# post an item
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/t_attachment/main/update.html",
			{
				:input => "_012-comment=abc&.status-public=create"
			}
		)
		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id = sprintf('%.8d_%.4d',$1,$2)

		# post an attachment
		tid = '1234567890.1234'
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/t_attachment/update.html",
			{
				:input => "#{new_id}-files-_1-file=boo.jpg&#{new_id}-files-_1.action-create=create"
			}
		)
		attachment_id = Sofa.transaction[tid].item(new_id,'files').val.keys.first
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "#{new_id}-files-#{attachment_id}-file=boo.jpg&#{new_id}-files-_1-file=&.status-public=create"
			}
		)

		assert_not_nil(
			Sofa::Set::Static::Folder.root.item('t_attachment','main',new_id).val['files'],
			'Sofa#call should treat the post with only an attachement nicely'
		)
	end

	def test_post_with_invalid_attachment
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_attachment','main').storage.clear

		# post an invalid empty attachment
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_attachment/main/update.html',
			{
				:input => "_012-files-_1-file=&_012-files-_1.action-create=create"
			}
		)
		tid = res.headers['Location'][Sofa::REX::TID]

		# post the root item
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "_012-comment=hello.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with the root status should ignore the invalid empty attachment'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main').val,
			'Sofa#call with the root status should ignore the invalid empty attachment'
		)

		# post an invalid non-empty attachment
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_attachment/main/update.html',
			{
				:input => "_012-files-_1-file=tooloooooooooooong&_012-files-_1.action-create=create"
			}
		)
		tid = res.headers['Location'][Sofa::REX::TID]

		# post the root item
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "_012-comment=hello.&.status-public=create"
			}
		)
		assert_equal(
			422,
			res.status,
			'Sofa#call with the root status should not ignore the invalid non-empty attachment'
		)
	end

	def test_post_confirm_update
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/t_store/main/update.html",
			{
				:input => ".action-confirm_update=submit&_1-name=fz&_1-comment=howdy.&.status-public=create"
			}
		)
		tid = res.headers['Location'][Sofa::REX::TID]

		assert_equal(
			303,
			res.status,
			'Sofa#call with :confirm action should return status 303 upon success'
		)
		assert_equal(
			"http://localhost:9292/#{tid}/id=_1/confirm_update.html",
			res.headers['Location'],
			'Sofa#call with :confirm action should return a proper location'
		)
		assert_instance_of(
			Sofa::Set::Dynamic,
			Sofa.transaction[tid],
			'the suspended SD should be kept in Sofa.transaction'
		)

		res = Rack::MockRequest.new(@sofa).get(
			"http://localhost:9292/#{tid}/id=_1/confirm_update.html"
		)
		assert_equal(
			<<"_html",
<html>
	<head><title>Root Folder</title></head>
	<body>
		<h1>Root Folder</h1>
<ul class="message notice">
	<li>please confirm.</li>
</ul>
<form id="main" method="post" enctype="multipart/form-data" action="/#{tid}/update.html">
		<ul id="main" class="sofa-blog">
			<li><a>fz</a>: howdy.<input type="hidden" name="_1.action" value="create" /></li>
		</ul>
<input name=".status-public" type="submit" value="create" />
</form>
	</body>
</html>
_html
			res.body,
			'Sofa#call with :confirm action should set a proper transaction upon success'
		)

		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/#{tid}/update.html",
			{
				:input => "_1.action=create&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with post method should return status 303'
		)
		assert_match(
			Sofa::REX::PATH_ID,
			res.headers['Location'],
			'Sofa#call with post method should return a proper location'
		)

		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id = sprintf('%.8d_%.4d',$1,$2)

		val = Sofa::Set::Static::Folder.root.item('t_store','main',new_id).val
		assert_instance_of(
			::Hash,
			val,
			'Sofa#call with post method should store the item in the storage'
		)
		val.delete '_timestamp'
		assert_equal(
			{'_owner' => 'root','name' => 'fz','comment' => 'howdy.'},
			val,
			'Sofa#call with post method should store the item in the storage'
		)
	end

	def test_post_confirm_invalid
		Sofa.client = 'root'

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => ".action-confirm_update=submit&_1-name=verrrrrrrrrrrrrrrrrrrrrrrrrrrrrrylong&_1-comment=howdy.&.status-public=create"
			}
		)
		assert_equal(
			422,
			res.status,
			'Sofa#call with :confirm action & malformed input should return status 422'
		)
		assert_match(
			/malformed input\./,
			res.body,
			'Sofa#call with :confirm action & malformed input should return :update'
		)

		tid = res.body[%r{/(#{Sofa::REX::TID})/},1]
		assert_instance_of(
			Sofa::Set::Dynamic,
			Sofa.transaction[tid],
			'the suspended SD should be kept in Sofa.transaction'
		)
	end

	def test_post_enquete
		Sofa.client = nil
		Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_enquete/main/update.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with post method should return status 303'
		)
		assert_no_match(
			Sofa::REX::PATH_ID,
			res.headers['Location'],
			'Sofa#call should not tell the item location when the workflow is enquete'
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://example.com/t_enquete/done.html',
			{}
		)
		assert_no_match(
			/login/,
			res.body,
			'Sofa#call should always allow action :done'
		)
	end

	def test_post_enquete_forbidden
		Sofa.client = nil
		Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.build(
			'20100425_1234' => {'_owner' => 'nobody','name' => 'cz','comment' => 'howdy.'}
		)

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_enquete/main/update.html',
			{
				:input => "20100425_1234-comment=modified&20100425_1234.action=create&.status-public=create"
			}
		)
		assert_equal(
			403,
			res.status,
			'Sofa#call should not allow nobody to update an existing enquete'
		)
		assert_equal(
			{'20100425_1234' => {'_owner' => 'nobody','name' => 'cz','comment' => 'howdy.'}},
			Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.val,
			'Sofa#call should not allow nobody to update an existing enquete'
		)

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_enquete/main/create.html',
			{
				:input => "20100425_1234-comment=modified&20100425_1234.action=create&.status-public=create"
			}
		)
		assert_equal(
			403,
			res.status,
			'Sofa#call should not allow nobody to update an existing enquete'
		)
		assert_equal(
			{'20100425_1234' => {'_owner' => 'nobody','name' => 'cz','comment' => 'howdy.'}},
			Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.val,
			'Sofa#call should not allow nobody to update an existing enquete'
		)

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_enquete/main/20100425_1234/create.html',
			{
				:input => "comment=modified&.action=create&.status-public=create"
			}
		)
		assert_equal(
			403,
			res.status,
			'Sofa#call should not allow nobody to update an existing enquete'
		)
		assert_equal(
			{'20100425_1234' => {'_owner' => 'nobody','name' => 'cz','comment' => 'howdy.'}},
			Sofa::Set::Static::Folder.root.item('t_enquete','main').storage.val,
			'Sofa#call should not allow nobody to update an existing enquete'
		)
	end

	def test_post_wrong_action
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/read.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			403,
			res.status,
			'post with an action other than :update should be regarded as :update'
		)

		Sofa.client = 'root'
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/read.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'post with an action other than :update should be regarded as :update'
		)
	end

	def test_post_login
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/foo/20100222/1/login.html",
			{
				:input => "id=test&pw=test&dest_action=update"
			}
		)
		assert_equal(
			'test',
			Sofa.client,
			'Sofa#call with :login action should set Sofa.client upon success'
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with :login action should return status 303'
		)
		assert_match(
			%r{/foo/20100222/1/update.html},
			res.headers['Location'],
			'Sofa#call with :login action should return a proper location'
		)
	end

	def test_post_login_with_wrong_pw
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/foo/20100222/1/login.html",
			{
				:input => "id=test&pw=wrong&dest_action=update"
			}
		)
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa#call with :login action should not set Sofa.client upon failure'
		)
		assert_equal(
			422,
			res.status,
			'Sofa#call with :login action should return status 422 upon failure'
		)
	end

	def test_post_logout
		Sofa.client = 'frank'
		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/foo/20100222/1/logout.html",
			{}
		)
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa#call with :logout action should unset Sofa.client'
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with :logout action should return status 303'
		)
		assert_match(
			%r{/foo/20100222/1/index.html},
			res.headers['Location'],
			'Sofa#call with :logout action should return a proper location'
		)
	end

	def test_get_logout
		Sofa.client = 'frank'
		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/foo/20100222/1/logout.html",
			{}
		)
		assert_equal(
			'nobody',
			Sofa.client,
			'Sofa#call with :logout action should work via both get and post'
		)
		assert_match(
			%r{/foo/20100222/1/index.html},
			res.headers['Location'],
			'Sofa#call with :logout action should work via both get and post'
		)
	end

	def test_message_notice
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_2-name=fz&_2-comment=hi.&.status-public=create"
			}
		)
		assert_match(
			%r{#{Sofa::REX::TID}/t_store/},
			res.headers['Location'],
			'Sofa#call should return both the base path and tid at :done'
		)

		tid    = res.headers['Location'][Sofa::REX::TID]
		new_id = res.headers['Location'][Sofa::REX::PATH_ID]

		res = Rack::MockRequest.new(@sofa).get(
			res.headers['Location']
		)
		assert_match(
			/1 item created\./,
			res.body,
			'Sofa#call should include the current message'
		)

		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/#{tid}/#{new_id}index.html"
		)
		assert_no_match(
			/1 item created\./,
			res.body,
			'Sofa#call should not include the message twice'
		)

		res.headers['Location'] =~ Sofa::REX::PATH_ID
		new_id = sprintf('%.8d_%.4d',$1,$2)
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "#{new_id}-comment=howdy.&.status-public=update"
			}
		)
		res = Rack::MockRequest.new(@sofa).get(
			res.headers['Location']
		)
		assert_match(
			/1 item updated\./,
			res.body,
			'Sofa#call should include a message according to the action'
		)

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "#{new_id}.action=delete&.status-public=delete"
			}
		)
		res = Rack::MockRequest.new(@sofa).get(
			res.headers['Location']
		)
		assert_match(
			/1 item deleted\./,
			res.body,
			'Sofa#call should include a message according to the action'
		)
	end

	def test_message_alert
		Sofa.client = 'nobody'

		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/foo/20091120/1/update.html"
		)
		assert_match(
			/please login\./,
			res.body,
			'Sofa#call should include the current message'
		)
	end

	def test_message_error
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/update.html',
			{
				:input => "_2-name=verrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrylongname&.status-public=create"
			}
		)
		assert_match(
			/malformed input\./,
			res.body,
			'Sofa#call should include the current message'
		)
	end

end
