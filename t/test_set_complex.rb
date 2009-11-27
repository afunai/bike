# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

class TC_Set_Complex < Test::Unit::TestCase

	class ::Sofa::Set::Dynamic
		def _get_vegetable(arg)
			"'potato'"
		end
	end

	class ::Sofa::Workflow::Pipco < ::Sofa::Workflow
		PERM = {
			:create    => 0b1100,
			:read      => 0b1111,
			:update    => 0b1110,
			:delete    => 0b1010,
			:vegetable => 0b1111,
		}
		def filter_get(arg,out)
			(arg[:action] == :update && arg[:p_action] != :update) ? <<_html : out
<form id="#{@sd[:full_name]}" method="post" action="#{@sd[:full_name]}">
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
		<ul id="replies" class="sofa-pipco">
			<li id="@(name)">reply:(tomago :'hi.')</li>
		</ul>
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
		Sofa.client = nil
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
			@sd.get,
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
			/<form.+<form/m,
			result,
			'Set::Dynamic#get(:action => :update) should not return nested forms'
		)
		assert_equal(
			<<'_html',
<form id="main" method="post" action="main">
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)</li>
		</ul>
		
		
	</li>
	<li id="main-20091123_0002">
		'RE'(action=update,p_action=update): 'wee'(action=update,p_action=update)
		<ul id="main-20091123_0002-files" class="sofa-attachment">
			<li id="main-20091123_0002-files-20091123_0001">'roy.png'(action=update,p_action=update)</li>
		</ul>
		
		
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
<form id="main" method="post" action="main">
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)</li>
		</ul>
		
		
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
<form id="main" method="post" action="main">
<ul id="main" class="sofa-pipco">
	<li id="main-20091123_0001">
		'CZ'(action=update,p_action=update): 'oops'(action=update,p_action=update)
		<ul id="main-20091123_0001-files" class="sofa-attachment">
			<li id="main-20091123_0001-files-20091123_0001">'carl1.jpg'(action=update,p_action=update)</li>
			<li id="main-20091123_0001-files-20091123_0002">'carl2.jpg'(action=update,p_action=update)</li>
		</ul>
		
		
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

end
