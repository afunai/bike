# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Complex < Test::Unit::TestCase

	class ::Sofa::Set::Dynamic
		def _g_vegetable(arg)
			"'potato'"
		end
	end

	class ::Sofa::Workflow::Pipco < ::Sofa::Workflow
		DEFAULT_SUB_ITEMS = {
			'_owner' => {:klass => 'meta-owner'},
		}
		PERM = {
			:create    => 0b1100,
			:read      => 0b1111,
			:update    => 0b1110,
			:delete    => 0b1010,
		}
		def _g_submit(arg)
			'[pipco]'
		end
	end

	class ::Sofa::Tomago < ::Sofa::Field
		def _get(arg)
			args = arg.keys.collect {|k| "#{k}=#{arg[k]}" }.sort
			"'#{val}'(#{args.join ','})"
		end
	end

	def setup
		# Set::Dynamic of Set::Static of (Scalar and (Set::Dynamic of Set::Static of Scalar))
		@sd = Sofa::Set::Dynamic.new(
			:id       => 'main',
			:klass    => 'set-dynamic',
			:workflow => 'pipco',
			:group    => ['roy','don'],
			:tmpl     => <<'_tmpl'.chomp,
<ul id="@(name)" class="sofa-pipco">
$()</ul>
$(.navi)$(.submit)$(.action_create)
_tmpl
			:item     => {
				'default' => Sofa::Parser.parse_html(<<'_html')
	<li id="@(name)">
		$(name = tomago 32 :'nobody'): $(comment = tomago 64 :'hello.')
		<ul id="files" class="sofa-attachment">
			<li id="@(name)">$(file = tomago :'foo.jpg')</li>
		</ul>
		<ul id="replies" class="sofa-pipco">
			<li id="@(name)">$(reply = tomago :'hi.')</li>
		</ul>
		$(replies.vegetable)
	</li>
_html
			}
		)
		@sd.load(
			'20091123_0001' => {
				'_owner'  => 'carl',
				'name'    => 'CZ',
				'comment' => 'oops',
				'files'   => {
					'20091123_0001' => {'file' => 'carl1.jpg'},
					'20091123_0002' => {'file' => 'carl2.jpg'},
				},
				'replies'   => {
					'20091125_0001' => {'_owner' => 'bobby','reply' => 'howdy.'},
				},
			},
			'20091123_0002' => {
				'_owner'  => 'roy',
				'name'    => 'RE',
				'comment' => 'wee',
				'files'   => {
					'20091123_0001' => {'file' => 'roy.png'},
				},
				'replies'   => {
					'20091125_0001' => {'_owner' => 'don','reply' => 'ho ho.'},
					'20091125_0002' => {'_owner' => 'roy','reply' => 'oops.'},
				},
			}
		)

		[
			@sd,
			@sd.item('20091123_0001','files'),
			@sd.item('20091123_0001','replies'),
			@sd.item('20091123_0002','files'),
			@sd.item('20091123_0002','replies'),
		].each {|sd|
			sd[:tmpl_action_create] = ''
			sd[:tmpl_navi] = ''
			sd[:tmpl_submit_create] = '[c]'
			sd[:tmpl_submit_delete] = '[d]'
			def sd._g_submit(arg)
				"[#{my[:id]}-#{arg[:orig_action]}]\n"
			end

			sd.each {|item|
				item[:tmpl_action_update] = ''
			}
		}
	end

	def teardown
		Sofa.client = nil
	end

	def test_get_default
		Sofa.client = 'root' #nil
		result = @sd.get

		assert_match(
			/'potato'/,
			result,
			'Set#get should include $(foo.baz) whenever the action :baz is permitted'
		)
		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=read,p_action=read): 'oops'(action=read,p_action=read)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=read,p_action=read)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=read,p_action=read)</li>
		</ul>
		<ul id="main-20091123_0001-replies" class="sofa-pipco">
			<li id="main-20091123_0001-replies-20091125_0001"><a href="/20091123_0001/replies/20091125/1/update.html">'howdy.'(action=read,p_action=read)</a></li>
		</ul>
		'potato'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
		<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0001"><a href="/20091123_0002/replies/20091125/1/update.html">'ho ho.'(action=read,p_action=read)</a></li>
			<li id="main-20091123_0002-replies-20091125_0002"><a href="/20091123_0002/replies/20091125/2/update.html">'oops.'(action=read,p_action=read)</a></li>
		</ul>
		'potato'
	</li>
</ul>
_html
			result,
			'Set#get should work recursively as a part of the complex'
		)
	end

	def test_get_with_parent_action
		Sofa.client = 'root'
		result = @sd.get(:action => :update)

		assert_match(
			/id="main-20091123_0001-files"/,
			result,
			'Set::Dynamic#get(:action => :update) should include child attachments'
		)
		assert_no_match(
			/id="main-20091123_0001-replies"/,
			result,
			'Set::Dynamic#get(:action => :update) should not include child apps'
		)
		assert_no_match(
			/'potato'/,
			result,
			'Set::Dynamic#get(:action => :update) should not include any value of child apps'
		)
		assert_no_match(
			/<form.+<form/m,
			result,
			'Set::Dynamic#get(:action => :update) should not return nested forms'
		)
		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0001-files-_001">'foo.jpg'(action=create,p_action=create)[c]</li>
		</ul>
	</li>
	<li id="main-20091123_0002">
		'RE'(action=update,p_action=update): 'wee'(action=update,p_action=update)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0002-files-_001">'foo.jpg'(action=create,p_action=create)[c]</li>
		</ul>
	</li>
</ul>
[main-update]
_html
			result,
			'Set#get should distribute the action to its items'
		)
	end

	def test_get_with_partial_permission
		Sofa.client = 'carl' # can edit only his own item

		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0001-files-_001">'foo.jpg'(action=create,p_action=create)[c]</li>
		</ul>
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
		<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0001"><a>'ho ho.'(action=read,p_action=read)</a></li>
			<li id="main-20091123_0002-replies-20091125_0002"><a>'oops.'(action=read,p_action=read)</a></li>
		</ul>
		'potato'
	</li>
</ul>
[main-update]
_html
			@sd.get(:action => :update),
			'Field#get should fall back to a possible action if the given action is not permitted'
		)

		@sd.item('20091123_0002','comment')[:owner] = 'carl' # enclave in roy's item
		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)[d]</li>
			<li id="main-20091123_0001-files-_001">'foo.jpg'(action=create,p_action=create)[c]</li>
		</ul>
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=update): 'wee'(action=update,p_action=update)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
	</li>
</ul>
[main-update]
_html
			@sd.get(:action => :update),
			'Field#get should preserve the given action wherever possible'
		)
	end

	def test_get_with_partial_action
		Sofa.client = 'root'

		Sofa.current[:base] = @sd.item('20091123_0002','replies')
		Sofa.base[:tid] = '123.45'

		result = @sd.get(
			'20091123_0002' => {
				'replies' => {
					:action => :update,
					:conds  => {:id => '20091125_0002'},
				},
			}
		)
		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=read,p_action=read): 'oops'(action=read,p_action=read)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=read,p_action=read)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=read,p_action=read)</li>
		</ul>
		<ul id="main-20091123_0001-replies" class="sofa-pipco">
			<li id="main-20091123_0001-replies-20091125_0001"><a href="/20091123_0001/replies/20091125/1/update.html">'howdy.'(action=read,p_action=read)</a></li>
		</ul>
		'potato'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
<form id="main-20091123_0002-replies" method="post" action="/123.45/20091123_0002/replies/update.html">
		<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0002"><a>'oops.'(action=update,p_action=update)</a></li>
		</ul>
[replies-update]
</form>
		'potato'
	</li>
</ul>
_html
			result,
			'Field#get should be able to handle a partial action'
		)

		result = @sd.get(
			:conds => {:id => '20091123_0002'},
			'20091123_0002' => {
				'replies' => {
					:action => :update,
					:conds  => {:id => '20091125_0002'},
				},
			}
		)
		assert_equal(
			<<'_html',
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
<form id="main-20091123_0002-replies" method="post" action="/123.45/20091123_0002/replies/update.html">
		<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0002"><a>'oops.'(action=update,p_action=update)</a></li>
		</ul>
[replies-update]
</form>
		'potato'
	</li>
</ul>
_html
			result,
			'Field#get should be able to handle a partial action'
		)
	end

	def test_get_partial_forbidden
		Sofa.client = 'carl'
		assert_match(
			/\(action=update/,
			@sd.item('20091123_0001','files').get(:action => :update)
		)
		assert_match(
			/\(action=update/,
			@sd.item('20091123_0001','files','20091123_0001').get(:action => :update)
		)

		@sd.instance_variable_set(:@item_object,{}) # remove item('_001')

		Sofa.client = nil
		assert_raise(
			Sofa::Error::Forbidden,
			'Field#get should not show an inner attachment when the parent is forbidden'
		) {
			@sd.item('20091123_0001','files').get(:action => :update)
		}
		assert_raise(
			Sofa::Error::Forbidden,
			'Field#get should not show an inner attachment when the parent is forbidden'
		) {
			@sd.item('20091123_0001','files','20091123_0001').get(:action => :update)
		}
	end

	def test_post_partial
		Sofa.client = 'don'
		original_val = YAML.load @sd.val.to_yaml
		@sd.update(
			'20091123_0002' => {
				'replies' => {
					'_0001' => {'reply' => 'yum.'},
				},
			}
		)
		assert_equal(
			original_val,
			@sd.val,
			'Field#val should not change before the commit'
		)
		@sd.commit
		assert_not_equal(
			original_val,
			@sd.val,
			'Field#val should change after the commit'
		)
	end

	def test_post_attachment_forbidden
		Sofa.client = nil
		assert_raise(
			Sofa::Error::Forbidden,
			'Field#post to an inner attachment w/o the perm of the parent should be forbidden'
		) {
			@sd.update(
				'20091123_0002' => {
					'files' => {
						'_0001' => {'file' => 'evil.jpg'},
					},
				}
			)
		}
		assert_raise(
			Sofa::Error::Forbidden,
			'Field#post to an inner attachment w/o the perm of the parent should be forbidden'
		) {
			@sd.update(
				'20091123_0002' => {
					'files'   => {
						'20091123_0001' => {'file' => 'evil.png'},
					}
				}
			)
		}
		assert_raise(
			Sofa::Error::Forbidden,
			'Field#post to an inner attachment w/o the perm of the parent should be forbidden'
		) {
			@sd.item('20091123_0002','files','20091123_0001').update('file' => 'evil.gif')
		}
	end

	def test_commit_partial
		Sofa.client = 'don'
		@sd.update(
			'20091123_0002' => {
				'replies' => {
					'_0001' => {'reply'  => 'yum.'},
				},
			}
		)
		orig_val = @sd.val('20091123_0002','replies').dup

		@sd.commit :temp
		new_val = @sd.val('20091123_0002','replies').dup
		assert_equal(
			orig_val.size + 1,
			new_val.size,
			'Field#val should change after the commit :temp'
		)

		new_id = new_val.keys.find {|id| new_val[id] == {'_owner' => 'don','reply'  => 'yum.'} }
		@sd.update(
			'20091123_0002' => {
				'replies' => {
					new_id => {
						:action => :delete,
						'reply' => 'yum.',
					},
				},
			}
		)

		@sd.commit :temp
		new_val = @sd.val('20091123_0002','replies').dup
		assert_equal(
			orig_val,
			new_val,
			'Field#val should change after the commit :temp'
		)
	end

	def test_post_mixed
		Sofa.client = 'don'

		# create a sub-item on the pending item
		@sd.update(
			'_1234' => {
				'_owner'  => 'don',
				'replies' => {
					'_0001' => {
						'_owner' => 'don',
						'reply'  => 'yum.',
					},
				},
			}
		)
		orig_val = @sd.val('_1234','replies').dup
		assert_equal(
			{},
			orig_val,
			'Field#val should change after the commit :temp'
		)

		orig_storage = @sd.storage
		@sd.instance_variable_set(:@storage,nil) # pretend persistent
		@sd.commit :temp
		@sd.instance_variable_set(:@storage,orig_storage)

		new_val = @sd.val('_1234','replies').dup
		assert_equal(
			{'_owner' => 'don','reply'  => 'yum.'},
			new_val.values.first,
			'Field#val should change after the commit :temp'
		)

		# delete the sub-item
		new_id = new_val.keys.find {|id| new_val[id] == {'_owner' => 'don','reply'  => 'yum.'} }
		@sd.update(
			'_1234' => {
				'replies' => {
					new_id => {
						:action  => :delete,
						'_owner' => 'don',
						'reply'  => 'yum.',
					},
				},
			}
		)
		assert_equal(
			:delete,
			@sd.item('_1234','replies',new_id).action,
			'Set::Dynamic#post should not overwrite the action of descendant'
		)

		orig_storage = @sd.storage
		@sd.instance_variable_set(:@storage,nil) # pretend persistent
		@sd.commit :temp
		@sd.instance_variable_set(:@storage,orig_storage)

		new_val = @sd.val('_1234','replies').dup
		assert_equal(
			{},
			new_val,
			'Field#val should change after the commit :temp'
		)

		# create an another sub-item
		@sd.update(
			'_1234' => {
				'_owner'  => 'don',
				'replies' => {
					'_0001' => {
						'_owner' => 'don',
						'reply'  => 'yuck.',
					},
				},
			}
		)

		orig_storage = @sd.storage
		@sd.instance_variable_set(:@storage,nil) # pretend persistent
		@sd.commit :temp
		@sd.instance_variable_set(:@storage,orig_storage)

		new_val = @sd.val('_1234','replies').dup
		assert_equal(
			{'_owner' => 'don','reply'  => 'yuck.'},
			new_val.values.first,
			'Field#val should change after the commit :temp'
		)
	end

end
