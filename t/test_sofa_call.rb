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
<form id="main" method="post" action="/1234567890.0123/t_enquete/update.html">
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

	def test_get_summary
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
		tid = '1234567890.01234'
		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/t_summary/#{tid}/p=1/update.html"
		)
		assert_equal(
			<<"_html",
<h1>index</h1>
<form id="main" method="post" action="/#{tid}/t_summary/update.html">
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

		assert_equal(
			{'_owner' => 'root','name' => 'fz','comment' => 'hi.'},
			Sofa::Set::Static::Folder.root.item('t_store','main',new_id).val,
			'Sofa#call with post method should store the item in the storage'
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
		assert_equal(
			{},
			Sofa.transaction[tid].send(:pending_items),
			'the suspended SD should be committed :temp'
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
			"http://example.com/1234567890.123456/t_attachment/main/#{new_id}/replies/update.html",
			{
				:input => "_001-reply=wow.&.status-public=create"
			}
		)
		assert_equal(303,res.status)
		assert_match(
			%r{/#{new_id}/replies/1234567890.123456/read_detail.html},
			res.headers['Location'],
			'Sofa#call with a sub-app status should commit the root item'
		)
		assert_not_equal(
			{},
			Sofa::Set::Static::Folder.root.item('t_attachment','main',new_id,'replies').val,
			'Sofa#call with a sub-app status should update the persistent storage'
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
			"http://example.com/#{tid}/t_attachment/update.html",
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
			"http://example.com/#{tid}/t_attachment/update.html",
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
			'http://example.com/t_store/1234567890.0123/main/update.html',
			{
				:input => ".action-confirm_update=submit&_1-name=fz&_1-comment=howdy.&.status-public=create"
			}
		)
		assert_equal(
			303,
			res.status,
			'Sofa#call with :confirm action should return status 303 upon success'
		)
		assert_equal(
			'http://localhost:9292/t_store/1234567890.0123/id=_1/confirm_update.html',
			res.headers['Location'],
			'Sofa#call with :confirm action should return a proper location'
		)

		res = Rack::MockRequest.new(@sofa).get(
			'http://localhost:9292/t_store/1234567890.0123/id=_1/confirm_update.html'
		)
		assert_equal(
			<<'_html',
<html>
	<head><title>Root Folder</title></head>
	<body>
		<h1>Root Folder</h1>
<form id="main" method="post" action="/1234567890.0123/t_store/update.html">
<ul class="message notice">
	<li>please confirm.</li>
</ul>
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
			'http://example.com/1234567890.0123/t_store/update.html',
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

		assert_equal(
			{'_owner' => 'root','name' => 'fz','comment' => 'howdy.'},
			Sofa::Set::Static::Folder.root.item('t_store','main',new_id).val,
			'Sofa#call with post method should store the item in the storage'
		)
	end

	def test_post_confirm_invalid
		Sofa.client = 'root'

		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/1234567890.0123/main/update.html',
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

	def test_post_wrong_action
		Sofa.client = nil
		res = Rack::MockRequest.new(@sofa).post(
			'http://example.com/t_store/main/read.html',
			{
				:input => "_1-name=fz&_1-comment=hi.&.status-public=create"
			}
		)
		assert_equal(
			422,
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

		tid    = res.headers['Location'][%r{/(\d+.\d+)/},1]
		new_id = res.headers['Location'][Sofa::REX::PATH_ID]

		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/t_store/#{tid}/#{new_id}index.html"
		)
		assert_match(
			/item updated\./,
			res.body,
			'Sofa#call should include the current Sofa.message'
		)

		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/t_store/#{tid}/#{new_id}index.html"
		)
		assert_no_match(
			/item updated\./,
			res.body,
			'Sofa#call should not include the used Sofa.message again'
		)
	end

	def test_message_alert
		Sofa.client = 'nobody'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		res = Rack::MockRequest.new(@sofa).get(
			"http://example.com/t_store/main/20100321/1/update.html"
		)
		assert_match(
			/please login\./,
			res.body,
			'Sofa#call should include the current Sofa.message'
		)
	end

	def test_message_error
		Sofa.client = 'root'
		Sofa::Set::Static::Folder.root.item('t_store','main').storage.clear

		tid = '1234567890.01234'

		res = Rack::MockRequest.new(@sofa).post(
			"http://example.com/t_store/#{tid}/main/update.html",
			{
				:input => "_2-name=verrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrylongname&.status-public=create"
			}
		)
		assert_match(
			/malformed input\./,
			res.body,
			'Sofa#call should include the current Sofa.message'
		)
	end

end
