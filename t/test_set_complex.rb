# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Complex < Test::Unit::TestCase

	class ::Sofa::Set::Dynamic
		def _get_vegetable(arg)
			"'potato'"
		end
		def _get_enormous(arg)
			"'mouth'"
		end
	end

	class ::Sofa::Workflow::Pipco < ::Sofa::Workflow
		PERM = {
			:create    => 0b1100,
			:read      => 0b1111,
			:update    => 0b1110,
			:delete    => 0b1010,
		}
		def filter_get(arg,out)
# TODO: should be moved up to SD#get?
			(arg[:action] == :update && arg[:p_action] != :update) ? <<_html : out
<form id="#{@sd[:full_name]}" method="post" action="#{@sd[:folder] ? @sd[:folder][:full_name] : ''}">
#{out}</form>
_html
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
			:id        => 'main',
			:klass     => 'set-dynamic',
			:workflow  => 'pipco',
			:group     => ['roy','don'],
			:tmpl      => <<'_tmpl',
<ul id="@(name)" class="sofa-pipco">
$()</ul>
_tmpl
			:item_html => <<'_html'
	<li id="@(name)">
		name:(tomago 32 :'nobody'): comment:(tomago 64 :'hello.')
		<ul id="files" class="sofa-attachment">
			<li id="@(name)">file:(tomago :'foo.jpg')</li>
		</ul>
		$(files.update-enormous)
		<ul id="replies" class="sofa-pipco">
			<li id="@(name)">reply:(tomago :'hi.')</li>
		</ul>
		$(replies.update-enormous)
		$(replies.vegetable)
	</li>
_html
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
		assert_no_match(
			/'mouth'/,
			result,
			'Set#get should not include $(foo.bar-baz) when the parent action is not :bar'
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
			<li id="main-20091123_0001-replies-20091125_0001">'howdy.'(action=read,p_action=read)</li>
		</ul>
		'potato'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
		<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0001">'ho ho.'(action=read,p_action=read)</li>
			<li id="main-20091123_0002-replies-20091125_0002">'oops.'(action=read,p_action=read)</li>
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
		assert_match(
			/'mouth'/,
			result,
			'Set#get should include $(foo.bar-baz) when the parent action is :bar'
		)
		assert_no_match(
			/<form.+<form/m,
			result,
			'Set::Dynamic#get(:action => :update) should not return nested forms'
		)
		assert_equal(
			<<'_html',
<form id="main" method="post" action="">
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)</li>
		</ul>
		'mouth'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=update,p_action=update): 'wee'(action=update,p_action=update)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=update,p_action=update)</li>
		</ul>
		'mouth'
	</li>
</ul>
</form>
_html
			result,
			'Set#get should distribute the action to its items'
		)
	end

	def test_get_with_partial_permission
		Sofa.client = 'carl' # can edit only his own item

		assert_equal(
			<<'_html',
<form id="main" method="post" action="">
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)</li>
		</ul>
		'mouth'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
		<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0001">'ho ho.'(action=read,p_action=read)</li>
			<li id="main-20091123_0002-replies-20091125_0002">'oops.'(action=read,p_action=read)</li>
		</ul>
		'potato'
	</li>
</ul>
</form>
_html
			@sd.get(:action => :update),
			'Field#get should fall back to a possible action if the given action is not permitted'
		)

		@sd.item('20091123_0002','comment')[:owner] = 'carl' # enclave in roy's item
		assert_equal(
			<<'_html',
<form id="main" method="post" action="">
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)</li>
		</ul>
		'mouth'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=update): 'wee'(action=update,p_action=update)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
	</li>
</ul>
</form>
_html
			@sd.get(:action => :update),
			'Field#get should preserve the given action wherever possible'
		)
	end

	def test_get_with_partial_action
		Sofa.client = 'root'

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
			<li id="main-20091123_0001-replies-20091125_0001">'howdy.'(action=read,p_action=read)</li>
		</ul>
		'potato'
	</li>
	<li id="main-20091123_0002">
		'RE'(action=read,p_action=read): 'wee'(action=read,p_action=read)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=read,p_action=read)</li>
		</ul>
		<form id="main-20091123_0002-replies" method="post" action="">
<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0002">'oops.'(action=update,p_action=update)</li>
		</ul></form>
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
		<form id="main-20091123_0002-replies" method="post" action="">
<ul id="main-20091123_0002-replies" class="sofa-pipco">
			<li id="main-20091123_0002-replies-20091125_0002">'oops.'(action=update,p_action=update)</li>
		</ul></form>
		'potato'
	</li>
</ul>
_html
			result,
			'Field#get should be able to handle a partial action'
		)
	end

	def test_post_partial
		Sofa.client = 'don'
		original_val = YAML.load @sd.val.to_yaml
		@sd.update(
			'20091123_0002' => {
				'replies' => {
					'_0001' => {
						'_owner' => 'don',
						'reply'  => 'yum.',
					},
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

end