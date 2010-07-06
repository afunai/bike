# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

require "#{::File.dirname __FILE__}/t"

class TC_Runo_Call < Test::Unit::TestCase

  def setup
    @runo = Runo.new
  end

  def teardown
  end

  def test_get
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/'
    )
    assert_match(
      /<html/,
      res.body,
      'Runo#call() should return the folder.get if the base field is a SD'
    )
  end

  def test_get_non_exist
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/non/exist/'
    )
    assert_equal(
      404,
      res.status,
      'Runo#call() should return 404 if the given path is non-existent'
    )
  end

  def test_get_partial
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/20091120_0001/name/'
    )
    assert_equal(
      'FZ',
      res.body,
      'Runo#call() should return the base.get unless the base field is a SD'
    )
  end

  def test_get_sub
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/'
    )
    assert_match(
      %r{<li><a>qux</a></li>},
      res.body,
      "Runo#call() should return sets other than 'main' as well"
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/sub/d=2010/'
    )
    assert_match(
      %r{<li><a>qux</a></li>},
      res.body,
      "Runo#call() should pass args for a sd other than 'main' as well"
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/sub/d=2009/'
    )
    assert_no_match(
      %r{<li><a>qux</a></li>},
      res.body,
      "Runo#call() should pass args for a sd other than 'main' as well"
    )
  end

  def test_get_contact
    Runo.client = nil
    Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/1234567890.0123/t_contact/'
    )
    assert_equal(
      200,
      res.status,
      'Runo#call to contact by nobody should return status 200'
    )
    assert_equal(
      <<_html,
<html>
  <head><base href="http:///t_contact/" /><title></title></head>
  <body>
    <h1></h1>
<form id="form_main" method="post" enctype="multipart/form-data" action="/t_contact/1234567890.0123/update.html">
<input name="_token" type="hidden" value="#{Runo.token}" />
    <ul id="main" class="app-contact">
      <li><a><span class="text"><input type="text" name="_001-name" value="foo" size="32" /></span></a>: <span class="text"><input type="text" name="_001-comment" value="bar!" size="64" /></span></li>
    </ul>
<div class="submit">
  <input name=".status-public" type="submit" value="create" />
</div>
</form>
  </body>
</html>
_html
      res.body,
      'Runo#call to contact by nobody should return :create'
    )
  end

  def test_get_contact_forbidden
    Runo.client = nil
    Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.build(
      '20100425_1234' => {'name' => 'cz', 'comment' => 'howdy.'}
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425/1234/index.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'getting an contact by nobody should not return any contents'
    )
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425_1234/'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'peeking an contact by nobody should not return any contents'
    )
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425_1234/comment/'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'peeking an contact by nobody should not return any contents'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425/1234/done.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'getting an contact by nobody should not return any contents'
    )
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425_1234/done.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'peeking an contact by nobody should not return any contents'
    )
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425_1234/comment/done.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'peeking an contact by nobody should not return any contents'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425/1234/preview_create.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'getting an contact by nobody should not return any contents'
    )
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425_1234/preview_create.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'peeking an contact by nobody should not return any contents'
    )
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_contact/20100425_1234/comment/preview_create.html'
    )
    assert_no_match(
      /howdy/,
      res.body,
      'peeking an contact by nobody should not return any contents'
    )
  end

  def test_get_summary
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_summary/p=1/'
    )
    assert_equal(
      <<'_html',
<html>
<head><base href="http:///t_summary/" /><title>summary</title></head>
<body>
<h1>summary</h1>
<table id="main" class="app-blog">
  <tr><td><a href="/t_summary/20100326/1/read_detail.html">frank</a></td><td>hi.</td></tr>
</table>
</body>
</html>
_html
      res.body,
      'Runo#call() should use [:tmpl][:summary] when available and appropriate'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/t_summary/p=1/read_detail.html'
    )
    assert_equal(
      <<'_html',
<html>
<head><base href="http:///t_summary/" /><title>index</title></head>
<body>
<h1>index</h1>
<ul id="main" class="app-blog">
  <li><a>frank</a>: hi.</li>
</ul>
</body>
</html>
_html
      res.body,
      'Runo#call() should use [:tmpl] when the action is :read -> :detail'
    )

    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).get(
      "http://example.com/t_summary/p=1/update.html"
    )
    tid = res.body[%r{/(#{Runo::REX::TID})/}, 1]
    assert_equal(
      <<"_html",
<html>
<head><base href="http:///t_summary/" /><title>index</title></head>
<body>
<h1>index</h1>
<form id="form_main" method="post" enctype="multipart/form-data" action="/t_summary/#{tid}/update.html">
<input name="_token" type="hidden" value="#{Runo.token}" />
<ul id="main" class="app-blog">
  <li><a><span class="text"><input type="text" name="20100326_0001-name" value="frank" size="32" /></span></a>: <span class="text"><input type="text" name="20100326_0001-comment" value="hi." size="64" /></span></li>
</ul>
<div class="submit">
  <input name=".status-public" type="submit" value="update" />
  <input name=".action-preview_delete" type="submit" value="delete..." />
</div>
</form>
</body>
</html>
_html
      res.body,
      'Runo#call() should use [:tmpl] unless the action is :read'
    )
  end

  def test_get_static
    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/css/foo.css'
    )
    assert_equal(
      200,
      res.status,
      'Runo#call should return a static file if the given path is under css/, js/, etc.'
    )
    assert_equal(
      'text/css',
      res.headers['Content-Type'],
      'Runo#call should return a static file if the given path is under css/, js/, etc.'
    )
    assert_equal(
      "#foo {bar: baz;}\n",
      res.body,
      'Runo#call should return a static file if the given path is under css/, js/, etc.'
    )
  end

  def test_get_static_not_css
    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/not_css/foo.css'
    )
    assert_not_equal(
      "#foo {bar: baz;}\n",
      res.body,
      'Runo#call should not return a static file if the step is not exactly css/, js/, etc.'
    )
  end

  def test_get_static_non_exist
    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/css/non-exist.css'
    )
    assert_equal(
      404,
      res.status,
      'Runo#call should return 404 if the static file is not found'
    )
  end

  def test_get_static_ambiguous
    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/css/0123456789.1234/_001/img/bar.jpg'
    )
    assert_equal(
      'Not Found', # from Runo#call
      res.body,
      'Runo#call should not look for a static file if the path includes a tid'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/css/20100613_1234/img/bar.jpg'
    )
    assert_equal(
      'Not Found', # from Runo#call
      res.body,
      'Runo#call should not look for a static file if the path includes an id'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/css/0123456789.1234/20100613_1234/img/bar.jpg'
    )
    assert_equal(
      'Not Found', # from Runo#call
      res.body,
      'Runo#call should not look for a static file if the path includes an id'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/css/20100613_1234/bar/id=img/'
    )
    assert_equal(
      'Not Found', # from Runo#call
      res.body,
      'Runo#call should not look for a static file if the path includes an id'
    )
  end

  def test_get_static_forbidden
    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/_users/00000000_test.yaml'
    )
    assert_no_match(
      /^password/,
      res.body,
      'Runo#call should not return meta files nor raw data'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/_users/css/../00000000_test.yaml'
    )
    assert_no_match(
      /password/,
      res.body,
      'Runo#call should not allow bad paths'
    )
  end

  def test_get_static_cascade
    Runo.client = 'root'

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/bar/css/foo.css'
    )
    assert_equal(
      "#foo {bar: baz;}\n",
      res.body,
      'Runo#call should look the acnestor dirs for the static directory'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/bar/css/non_exist.css'
    )
    assert_equal(
      404,
      res.status,
      'Runo#call should return 404 if the file is not found in the nearest static dir'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/baz/css/foo.css'
    )
    assert_equal(
      404,
      res.status,
      'Runo#call should not look the ancestor dirs if the file is not found in the nearest dir'
    )

    res = Rack::MockRequest.new(@runo).get(
      'http://example.com/foo/bar/js/non_exist.css'
    )
    assert_equal(
      404,
      res.status,
      'Runo#call should return 404 if the static dir is not found in any ancestor dirs'
    )
  end

  def test_post_simple_create
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "_1-name=fz&_1-comment=hi.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'Runo#call with post method should return status 303'
    )
    assert_match(
      Runo::REX::PATH_ID,
      res.headers['Location'],
      'Runo#call with post method should return a proper location'
    )

    res.headers['Location'] =~ Runo::REX::PATH_ID
    new_id = sprintf('%.8d_%.4d', $1, $2)

    val = Runo::Set::Static::Folder.root.item('t_store', 'main', new_id).val
    assert_instance_of(
      ::Hash,
      val,
      'Runo#call with post method should store the item in the storage'
    )
    val.delete '_timestamp'
    assert_equal(
      {'_owner' => 'root', 'name' => 'fz', 'comment' => 'hi.'},
      val,
      'Runo#call with post method should store the item in the storage'
    )
  end

  def test_post_invalid_create
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/t_store/main/update.html",
      {
        :input => "_1-name=tooooooooooooloooooooooooooooooooooooooooong&_1-comment=hi.&.status-public=create&_token=#{Runo.token}"
      }
    )
    tid = res.body[%r{/(#{Runo::REX::TID})/}, 1]

    assert_equal(
      422,
      res.status,
      'Runo#post with an invalid new item should be an error'
    )
    assert_instance_of(
      Runo::Set::Dynamic,
      Runo.transaction[tid],
      'the suspended SD should be kept in Runo.transaction'
    )
  end

  def test_post_empty_create
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "_1-name=&_1-comment=&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      422,
      res.status,
      'Runo#post with an empty new item should be an error'
    )
  end

  def test_post_empty_update
    Runo.client = 'root'

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "_1-name=don&_1-comment=brown.&.status-public=create&_token=#{Runo.token}"
      }
    )
    res.headers['Location'] =~ Runo::REX::PATH_ID
    new_id   = sprintf('%.8d_%.4d', $1, $2)

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "#{new_id}-name=don&.status-public=update&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'Runo#post without any update on the item should not raise an error'
    )

    res = Rack::MockRequest.new(@runo).get(
      res.headers['Location']
    )
    assert_no_match(
      /message/,
      res.body,
      'Runo#post without any update on the item should not set any messages'
    )
  end

  def test_post_back_and_forth
    Runo.client = 'root'

    # post from a form without status
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/1234567890.9999/update.html',
      {
        :input => "_1-comment=brown."
      }
    )

    # back to the form, post again with status
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/1234567890.9999/update.html',
      {
        :input => "_1-name=don&_1-comment=brown.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'Runo#post twice from the same form should work if the previous post is without status'
    )

    # back to the form one more time, post again with status
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/1234567890.9999/update.html',
      {
        :input => "_1-name=roy&_1-comment=brown.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      422,
      res.status,
      'Runo#post twice from the same form should not work if the previous post is with status'
    )
    assert_equal(
      'transaction expired',
      res.body,
      'Runo#post twice from the same form should not work if the previous post is with status'
    )
  end

  def test_post_with_invalid_token
    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "_1-name=fz&_1-comment=hi.&.status-public=create&_token=invalid"
      }
    )
    assert_equal(
      403,
      res.status,
      'Runo#call without a valid token should return status 403'
    )
    assert_equal(
      'invalid token',
      res.body,
      'Runo#call without a valid token should return status 403'
    )
  end

  def test_post_with_attachment
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_attachment', 'main').storage.clear

    # post an attachment
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_attachment/main/update.html',
      {
        :input => "_012-files-_1-file=wow.jpg&_012-files-_1.action-create=create&_token=#{Runo.token}"
      }
    )
    assert_match(
      'update.html',
      res.headers['Location'],
      'Runo#call without the root status should always return :update'
    )
    assert_equal(
      {},
      Runo::Set::Static::Folder.root.item('t_attachment', 'main').val,
      'Runo#call without the root status should not update the persistent storage'
    )

    tid = res.headers['Location'][Runo::REX::TID]
    assert_instance_of(
      Runo::Set::Dynamic,
      Runo.transaction[tid],
      'the suspended SD should be kept in Runo.transaction'
    )

    # post the item
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/#{tid}/update.html",
      {
        :input => "_012-comment=hello.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_no_match(
      /update\.html/,
      res.headers['Location'],
      'Runo#call with the root status should commit the transaction'
    )
    assert_not_equal(
      {},
      Runo::Set::Static::Folder.root.item('t_attachment', 'main').val,
      'Runo#call with the root status should update the persistent storage'
    )

    res.headers['Location'] =~ Runo::REX::PATH_ID
    new_id   = sprintf('%.8d_%.4d', $1, $2)
    new_item = Runo::Set::Static::Folder.root.item('t_attachment', 'main', new_id)
    assert_not_equal(
      {},
      new_item.val,
      'Runo#call with the root status should commit all the pending items'
    )
    assert_equal(
      'hello.',
      new_item.val['comment'],
      'Runo#call with the root status should commit the root items'
    )
    assert_equal(
      {'file' => 'wow.jpg'},
      new_item.val['files'].values.first,
      'Runo#call with the root status should commit the descendant items'
    )

    # post a reply
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/t_attachment/main/#{new_id}/replies/update.html",
      {
        :input => "_001-reply=wow.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(303, res.status)
    assert_match(
      %r{/#{Runo::REX::TID}/t_attachment/#{new_id}/replies/read_detail.html},
      res.headers['Location'],
      'Runo#call with a sub-app status should commit the root item'
    )
    assert_not_equal(
      {},
      Runo::Set::Static::Folder.root.item('t_attachment', 'main', new_id, 'replies').val,
      'Runo#call with a sub-app status should update the persistent storage'
    )
  end

  def test_post_only_attachment
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_attachment', 'main').storage.clear

    # post an item
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/t_attachment/main/update.html",
      {
        :input => "_012-comment=abc&.status-public=create"
      }
    )
    res.headers['Location'] =~ Runo::REX::PATH_ID
    new_id = sprintf('%.8d_%.4d', $1, $2)

    # post an attachment
    tid = '1234567890.1234'
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/#{tid}/t_attachment/update.html",
      {
        :input => "#{new_id}-files-_1-file=boo.jpg&#{new_id}-files-_1.action-create=create&_token=#{Runo.token}"
      }
    )
    attachment_id = Runo.transaction[tid].item(new_id, 'files').val.keys.first
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/#{tid}/update.html",
      {
        :input => "#{new_id}-files-#{attachment_id}-file=boo.jpg&#{new_id}-files-_1-file=&.status-public=create&_token=#{Runo.token}"
      }
    )

    assert_not_nil(
      Runo::Set::Static::Folder.root.item('t_attachment', 'main', new_id).val['files'],
      'Runo#call should treat the post with only an attachement nicely'
    )
  end

  def test_post_with_invalid_attachment
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_attachment', 'main').storage.clear

    # post an invalid empty attachment
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_attachment/main/update.html',
      {
        :input => "_012-files-_1-file=&_012-files-_1.action-create=create&_token=#{Runo.token}"
      }
    )
    tid = res.headers['Location'][Runo::REX::TID]

    # post the root item
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/#{tid}/update.html",
      {
        :input => "_012-comment=hello.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'Runo#call with the root status should ignore the invalid empty attachment'
    )
    assert_not_equal(
      {},
      Runo::Set::Static::Folder.root.item('t_attachment', 'main').val,
      'Runo#call with the root status should ignore the invalid empty attachment'
    )

    # post an invalid non-empty attachment
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_attachment/main/update.html',
      {
        :input => "_012-files-_1-file=tooloooooooooooong&_012-files-_1.action-create=create&_token=#{Runo.token}"
      }
    )
    tid = res.headers['Location'][Runo::REX::TID]

    # post the root item
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/#{tid}/update.html",
      {
        :input => "_012-comment=hello.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      422,
      res.status,
      'Runo#call with the root status should not ignore the invalid non-empty attachment'
    )
  end

  def test_post_preview_update
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear
    base_uri = ''

    res = Rack::MockRequest.new(@runo).post(
      "http://#{base_uri}/t_store/main/update.html",
      {
        :input => ".action-preview_update=submit&_1-name=fz&_1-comment=howdy.&.status-public=create"
      }
    )
    tid = res.headers['Location'][Runo::REX::TID]

    assert_equal(
      303,
      res.status,
      'Runo#call with :preview action should return status 303 upon success'
    )
    assert_equal(
      "http://#{base_uri}/#{tid}/id=_1/preview_update.html",
      res.headers['Location'],
      'Runo#call with :preview action should return a proper location'
    )
    assert_instance_of(
      Runo::Set::Dynamic,
      Runo.transaction[tid],
      'the suspended SD should be kept in Runo.transaction'
    )

    res = Rack::MockRequest.new(@runo).get(
      "http://#{base_uri}/#{tid}/id=_1/preview_update.html"
    )
    assert_equal(
      <<"_html",
<html>
  <head><base href="http://#{base_uri}/t_store/" /><title></title></head>
  <body>
    <h1></h1>
<ul class="message notice">
  <li>please confirm.</li>
</ul>
<form id="form_main" method="post" enctype="multipart/form-data" action="/#{tid}/update.html">
<input name="_token" type="hidden" value="#{Runo.token}" />
    <ul id="main" class="app-blog">
      <li><a>fz</a>: howdy.<input type="hidden" name="_1.action" value="create" /></li>
    </ul>
<div class="submit">
  <input name=".status-public" type="submit" value="create" />
</div>
</form>
  </body>
</html>
_html
      res.body,
      'Runo#call with :preview action should set a proper transaction upon success'
    )

    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/#{tid}/update.html",
      {
        :input => "_1.action=create&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'Runo#call with post method should return status 303'
    )
    assert_match(
      Runo::REX::PATH_ID,
      res.headers['Location'],
      'Runo#call with post method should return a proper location'
    )

    res.headers['Location'] =~ Runo::REX::PATH_ID
    new_id = sprintf('%.8d_%.4d', $1, $2)

    val = Runo::Set::Static::Folder.root.item('t_store', 'main', new_id).val
    assert_instance_of(
      ::Hash,
      val,
      'Runo#call with post method should store the item in the storage'
    )
    val.delete '_timestamp'
    assert_equal(
      {'_owner' => 'root', 'name' => 'fz', 'comment' => 'howdy.'},
      val,
      'Runo#call with post method should store the item in the storage'
    )
  end

  def test_post_preview_invalid
    Runo.client = 'root'

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => ".action-preview_update=submit&_1-name=verrrrrrrrrrrrrrrrrrrrrrrrrrrrrrylong&_1-comment=howdy.&.status-public=create"
      }
    )
    assert_equal(
      422,
      res.status,
      'Runo#call with :preview action & malformed input should return status 422'
    )
    assert_match(
      /malformed input\./,
      res.body,
      'Runo#call with :preview action & malformed input should return :update'
    )

    tid = res.body[%r{/(#{Runo::REX::TID})/}, 1]
    assert_instance_of(
      Runo::Set::Dynamic,
      Runo.transaction[tid],
      'the suspended SD should be kept in Runo.transaction'
    )
  end

  def test_post_contact
    Runo.client = nil
    Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_contact/main/update.html',
      {
        :input => "_1-name=fz&_1-comment=hi.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'Runo#call with post method should return status 303'
    )
    assert_no_match(
      Runo::REX::PATH_ID,
      res.headers['Location'],
      'Runo#call should not tell the item location when the workflow is contact'
    )

    res = Rack::MockRequest.new(@runo).get(
      res.headers['Location'],
      {}
    )
    assert_match(
      /thank you!/,
      res.body,
      'Runo#call should refer to (action).html if available'
    )
    assert_no_match(
      /message/,
      res.body,
      'Runo#call should not include messages for action :done'
    )
    assert_no_match(
      /login/,
      res.body,
      'Runo#call should always allow action :done'
    )
  end

  def test_post_contact_forbidden
    Runo.client = nil
    Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.build(
      '20100425_1234' => {'_owner' => 'nobody', 'name' => 'cz', 'comment' => 'howdy.'}
    )

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_contact/main/update.html',
      {
        :input => "20100425_1234-comment=modified&20100425_1234.action=create&.status-public=create"
      }
    )
    assert_equal(
      403,
      res.status,
      'Runo#call should not allow nobody to update an existing contact'
    )
    assert_equal(
      {'20100425_1234' => {'_owner' => 'nobody', 'name' => 'cz', 'comment' => 'howdy.'}},
      Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.val,
      'Runo#call should not allow nobody to update an existing contact'
    )

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_contact/main/create.html',
      {
        :input => "20100425_1234-comment=modified&20100425_1234.action=create&.status-public=create"
      }
    )
    assert_equal(
      403,
      res.status,
      'Runo#call should not allow nobody to update an existing contact'
    )
    assert_equal(
      {'20100425_1234' => {'_owner' => 'nobody', 'name' => 'cz', 'comment' => 'howdy.'}},
      Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.val,
      'Runo#call should not allow nobody to update an existing contact'
    )

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_contact/main/20100425_1234/create.html',
      {
        :input => "comment=modified&.action=create&.status-public=create"
      }
    )
    assert_equal(
      403,
      res.status,
      'Runo#call should not allow nobody to update an existing contact'
    )
    assert_equal(
      {'20100425_1234' => {'_owner' => 'nobody', 'name' => 'cz', 'comment' => 'howdy.'}},
      Runo::Set::Static::Folder.root.item('t_contact', 'main').storage.val,
      'Runo#call should not allow nobody to update an existing contact'
    )
  end

  def test_post_wrong_action
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).post(
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

    Runo.client = 'root'
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/read.html',
      {
        :input => "_1-name=fz&_1-comment=hi.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_equal(
      303,
      res.status,
      'post with an action other than :update should be regarded as :update'
    )
  end

  def test_post_login
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/foo/20100222/1/login.html",
      {
        :input => "id=test&pw=test&dest_action=update"
      }
    )
    assert_equal(
      'test',
      Runo.client,
      'Runo#call with :login action should set Runo.client upon success'
    )
    assert_equal(
      303,
      res.status,
      'Runo#call with :login action should return status 303'
    )
    assert_match(
      %r{/foo/20100222/1/update.html},
      res.headers['Location'],
      'Runo#call with :login action should return a proper location'
    )
  end

  def test_post_login_with_wrong_pw
    Runo.client = nil
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/foo/20100222/1/login.html",
      {
        :input => "id=test&pw=wrong&dest_action=update"
      }
    )
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#call with :login action should not set Runo.client upon failure'
    )
    assert_equal(
      422,
      res.status,
      'Runo#call with :login action should return status 422 upon failure'
    )
  end

  def test_post_logout
    Runo.client = 'frank'
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/foo/20100222/1/logout.html?_token=#{Runo.token}",
      {}
    )
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#call with :logout action should unset Runo.client'
    )
    assert_equal(
      303,
      res.status,
      'Runo#call with :logout action should return status 303'
    )
    assert_match(
      %r{/foo/20100222/1/index.html},
      res.headers['Location'],
      'Runo#call with :logout action should return a proper location'
    )
  end

  def test_post_logout_with_invalid_token
    Runo.client = 'frank'
    res = Rack::MockRequest.new(@runo).post(
      "http://example.com/foo/20100222/1/logout.html?_token=invalid",
      {}
    )
    assert_equal(
      403,
      res.status,
      'Runo#call without a valid token should return status 403'
    )
    assert_equal(
      'invalid token',
      res.body,
      'Runo#call without a valid token should return status 403'
    )
    assert_equal(
      'frank',
      Runo.client,
      'Runo#call without a valid token should return status 403'
    )
  end

  def test_get_logout
    Runo.client = 'frank'
    res = Rack::MockRequest.new(@runo).get(
      "http://example.com/foo/20100222/1/logout.html?_token=#{Runo.token}",
      {}
    )
    assert_equal(
      'nobody',
      Runo.client,
      'Runo#call with :logout action should work via both get and post'
    )
    assert_match(
      %r{/foo/20100222/1/index.html},
      res.headers['Location'],
      'Runo#call with :logout action should work via both get and post'
    )
  end

  def test_message_notice
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "_2-name=fz&_2-comment=hi.&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_match(
      %r{#{Runo::REX::TID}/t_store/},
      res.headers['Location'],
      'Runo#call should return both the base path and tid at :done'
    )

    tid    = res.headers['Location'][Runo::REX::TID]
    new_id = res.headers['Location'][Runo::REX::PATH_ID]

    res = Rack::MockRequest.new(@runo).get(
      res.headers['Location']
    )
    assert_match(
      /created 1 entry\./,
      res.body,
      'Runo#call should include the current message'
    )

    res = Rack::MockRequest.new(@runo).get(
      "http://example.com/#{tid}/#{new_id}index.html"
    )
    assert_no_match(
      /created 1 entry\./,
      res.body,
      'Runo#call should not include the message twice'
    )

    res.headers['Location'] =~ Runo::REX::PATH_ID
    new_id = sprintf('%.8d_%.4d', $1, $2)
    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "#{new_id}-comment=howdy.&.status-public=update&_token=#{Runo.token}"
      }
    )
    res = Rack::MockRequest.new(@runo).get(
      res.headers['Location']
    )
    assert_match(
      /updated 1 entry\./,
      res.body,
      'Runo#call should include a message according to the action'
    )

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "#{new_id}.action=delete&.status-public=delete&_token=#{Runo.token}"
      }
    )
    res = Rack::MockRequest.new(@runo).get(
      res.headers['Location']
    )
    assert_match(
      /deleted 1 entry\./,
      res.body,
      'Runo#call should include a message according to the action'
    )
  end

  def test_message_notice_plural
    Runo.client = 'root'

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_attachment/main/update.html',
      {
        :input => "_1-comment=foo&_2-comment=bar&.status-public=create&_token=#{Runo.token}"
      }
    )
    res = Rack::MockRequest.new(@runo).get(
      res.headers['Location']
    )
    assert_match(
      /created 2 tArticles\./,
      res.body,
      'the message should be plural if more than one item have results.'
    )
  end

  def test_message_alert
    Runo.client = 'nobody'

    res = Rack::MockRequest.new(@runo).get(
      "http://example.com/foo/20091120/1/update.html"
    )
    assert_match(
      /please login\./,
      res.body,
      'Runo#call should include the current message'
    )
  end

  def test_message_error
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input => "_2-name=verrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrylongname&.status-public=create&_token=#{Runo.token}"
      }
    )
    assert_match(
      /malformed input\./,
      res.body,
      'Runo#call should include the current message'
    )
  end

  def test_message_i18n
    Runo.client = 'root'
    Runo::Set::Static::Folder.root.item('t_store', 'main').storage.clear

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input                 => "_3-name=&.status-public=create&_token=#{Runo.token}",
        'HTTP_ACCEPT_LANGUAGE' => 'en, de',
      }
    )
    assert_match(
      /malformed input/,
      res.body,
      "Runo::I18n.find_msg should return at least an empty hash for 'en' as HTTP_ACCEPT_LANGUAGE."
    )

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input                 => "_3-name=&.status-public=create&_token=#{Runo.token}",
        'HTTP_ACCEPT_LANGUAGE' => 'en-US, de',
      }
    )
    assert_match(
      /malformed input/,
      res.body,
      "Runo::I18n.find_msg should return at least an empty hash for 'en' as HTTP_ACCEPT_LANGUAGE."
    )

    res = Rack::MockRequest.new(@runo).post(
      'http://example.com/t_store/main/update.html',
      {
        :input                 => "_3-name=&.status-public=create&_token=#{Runo.token}",
        'HTTP_ACCEPT_LANGUAGE' => 'de, en',
      }
    )
    assert_match(
      /Fehlerhafte Eingabe/,
      res.body,
      'Set::Dynamic#_g_message should be i18nized according to HTTP_ACCEPT_LANGUAGE.'
    )
  end

end
