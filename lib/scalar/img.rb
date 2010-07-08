# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009-2010 Akira FUNAI

begin
  require 'quick_magick'
rescue LoadError
end

class Runo::Img < Runo::File

  DEFAULT_META = {
    :width   => 120,
    :height  => 120,
    :options => ['png', 'jpg', 'jpeg', 'gif', 'tiff', 'bmp'],
  }

  def self.quick_magick?
    Object.const_defined? :QuickMagick
  end

  def initialize(meta = {})
    meta[:crop] = true if meta[:tokens] && meta[:tokens].include?('crop')
    super
  end

  def thumbnail
    raise Runo::Error::Forbidden unless permit? :read

    if ps = my[:persistent_sd]
      @thumbnail ||= ps.storage.val "#{my[:persistent_name]}_small"
    end
    @thumbnail || body
  end

  def errors
    if @error_thumbnail
      [_('wrong file type: should be %{types}') % {:types => my[:options].join('/')}]
    else
      super
    end
  end

  def commit(type = :temp)
    super
    if type == :temp && @action == :delete
      @thumbnail = nil
    elsif type == :persistent && ps = my[:persistent_sd]
      case @action
        when :create, :update, nil
          ps.storage.store(
            "#{my[:persistent_name]}_small",
            @thumbnail,
            val['basename'][/\.([\w\.]+)$/, 1] || 'bin'
          ) if @thumbnail && valid?
      end
    end
  end

  private

  def _g_default(arg = {})
    path       = _path arg[:action]
    basename   = Runo::Field.h val['basename']
    s_basename = basename.sub(/\..+$/, '_small\\&')
    if val.empty?
      <<_html.chomp
<span class="dummy_img" style="width: #{my[:width]}px; height: #{my[:height]}px;"></span>
_html
    elsif errors.include?(_('wrong file type: should be %{types}') % {:types => my[:options].join('/')})
      super
    elsif arg[:sub_action] == :without_link
      <<_html.chomp
<img src="#{path}/#{s_basename}" alt="#{basename}" />
_html
    else
      <<_html.chomp
<a href="#{path}/#{basename}"><img src="#{path}/#{s_basename}" alt="#{basename}" /></a>
_html
    end
  end

  def _g_thumbnail(arg = {})
    _g_default arg.merge(:sub_action => :without_link)
  end

  def _thumbnail(tempfile)
    @error_thumbnail = nil
    begin
      tempfile.rewind
      img = QuickMagick::Image.read(tempfile.path).first
      if my[:crop]
        img.gravity = 'center'
        img.resize "#{my[:width]}x#{my[:height]}^"
        img.extent "#{my[:width]}x#{my[:height]}"
      else
        img.resize "#{my[:width]}x#{my[:height]}"
      end
      img.to_blob
    rescue QuickMagick::QuickMagickError
      @error_thumbnail = $!.inspect
      nil
    end if self.class.quick_magick?
  end

  def val_cast(v)
    @thumbnail = _thumbnail(v[:tempfile]) if v && v[:tempfile]
    super
  end

end
