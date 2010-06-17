# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Runo::Parser

  module_function

  def parse_html(html, action = :index)
    item = {}
    html = gsub_block(html, 'runo-\w+') {|open, inner, close|
      id = open[/id="(.+?)"/i, 1] || 'main'
      item[id] = parse_block(open, inner, close, action)
      "$(#{id})"
    }
    html = gsub_action_tmpl(html) {|id, act, open, inner, close|
      id ||= 'main'
      if item[id]
        item[id][:tmpl] ||= {}
        inner = gsub_action_tmpl(inner) {|i, a, *t|
          item[id][:tmpl][a] = t.join
          "$(.#{a})"
        }
        item[id][:tmpl][act] = open + inner + close
        "$(#{id}.#{act})"
      else
        open + inner + close
      end
    }
    html = gsub_scalar(html) {|id, meta|
      item[id] = meta
      "$(#{id})"
    }

    item.each {|id, meta|
      next unless meta[:klass] == 'set-dynamic'
      tmpl = meta[:tmpl][action]
      tmpl << '$(.navi)' unless _include_menu?(html, tmpl, id, 'navi')
      next if meta[:workflow].downcase == 'attachment'
      tmpl << '$(.submit)' unless _include_menu?(html, tmpl, id, 'submit')
      tmpl << '$(.action_create)' unless _include_menu?(html, tmpl, id, 'action_create')
      html.sub!("$(#{id})", "$(#{id}.message)\\&") unless _include_menu?(html, tmpl, id, 'message')
    }

    scrape_meta(html).merge(
      :label => scrape_label(html),
      :item  => item,
      :tmpl  => {action => html}
    )
  end

  def _include_menu?(html, tmpl, id, action)
    html.include?("$(#{id}.#{action})") || tmpl.include?("$(.#{action})")
  end

  def gsub_action_tmpl(html, &block)
    rex_klass = /(?:\w+\-)?(?:action|view|navi|submit|done)\w*/
    gsub_block(html, rex_klass) {|open, inner, close|
      klass = open[/class=(?:"|"[^"]*?\s)(#{rex_klass})(?:"|\s)/, 1]
      id, action = (klass =~ /-/) ? klass.split('-', 2) : [nil, klass]
      block.call(id, action.intern, open, inner, close)
    }
  end

  def gsub_block(html, class_name, &block)
    rex_open_tag = /\s*<(\w+)[^>]+?class=(?:"|"[^"]*?\s)#{class_name}(?:"|\s).*?>\n?/i 
    out = ''
    s = StringScanner.new html
    until s.eos?
      if s.scan rex_open_tag
        open_tag = s[0]
        inner_html, close_tag = scan_inner_html(s, s[1])
        close_tag << "\n" if s.scan /\n/
        out << block.call(open_tag, inner_html, close_tag)
      else
        out << s.scan(/.+?(?=\t| |<|\z)/m)
      end
    end
    out
  end

  def gsub_scalar(html, &block)
    out = ''
    s = StringScanner.new html
    until s.eos?
      if s.scan /\$\((\w+)(?:\s+|\s*=\s*)([\w\-]+)\s*/m
        out << block.call(s[1], {:klass => s[2]}.merge(scan_tokens s))
      else
        out << s.scan(/.+?(?=\$|\w|<|\z)/m)
      end
    end
    out
  end

  def scrape_meta(html)
    meta = {}
    html.gsub!(/(?:^\s+)?<meta[^>]*name="runo-([^"]+)[^>]*content="([^"]+).*?>\s*/i) {
      meta[$1.intern] = $2.include?(',') ? $2.split(/\s*,\s*/) : $2
      ''
    }
    meta
  end

  def scrape_label(html)
    if html.sub!(/\A((?:[^<]*<!--)?[^<]*<[^>]*title=")([^"]+)/, '\\1')
      label_plural = $2.to_s.split(/,/).collect {|s| s.strip }
      label_plural *= 4 if label_plural.size == 1
      label = label_plural.first
      Runo::I18n.msg[label] ||= label_plural
      label
    end
  end

  def parse_block(open_tag, inner_html, close_tag, action = :index)
    open_tag.sub!(/id=".*?"/i, 'id="@(name)"')
    workflow = open_tag[/class=(?:"|".*?\s)runo-(\w+)/, 1]

    if inner_html =~ /<(\w+).+?class=(?:"|"[^"]*?\s)body(?:"|\s)/i
      item_html = ''
      sd_tmpl = gsub_block(inner_html, 'body') {|open, inner, close|
        item_html = open + inner + close
        '$()'
      }
    else
      item_html = inner_html
      sd_tmpl = '$()'
    end

    tmpl = {}
    sd_tmpl = gsub_action_tmpl(sd_tmpl) {|id, act, open, inner, close|
      inner = gsub_action_tmpl(inner) {|i, a, *t|
        tmpl[a] = t.join
        "$(.#{a})"
      }
      tmpl[act] = open + inner + close
      "$(.#{act})"
    }

    item_meta = Runo::Parser.parse_html(item_html, action)
    if action == :summary
      item_meta[:tmpl][action].sub!(
        /\$\(.*?\)/m,
        '<a href="$(.uri_detail)">\&</a>'
      ) unless workflow.downcase == 'attachment' || item_meta[:tmpl].include?('$(.uri_detail)')
    else
      item_meta[:tmpl][action].sub!(
        /\$\([^\.]*?\)/m,
        '$(.a_update)\&</a>'
      ) unless workflow.downcase == 'attachment' || item_meta[:tmpl].include?('$(.action_update)')
      item_meta[:tmpl][action].sub!(
        /.*\$\(.*?\)/m,
        '\&$(.hidden)'
      ) unless workflow.downcase == 'attachment' || item_meta[:tmpl].include?('$(.hidden)')
    end

    sd = {
      :klass    => 'set-dynamic',
      :workflow => workflow,
      :tmpl     => tmpl.merge(action => "#{open_tag}#{sd_tmpl}#{close_tag}"),
      :item     => {
        'default' => item_meta,
      },
    }
    (inner_html =~ /\A\s*<!--(.+?)-->/m) ? sd.merge(scan_tokens StringScanner.new($1)) : sd
  end

  def parse_token(prefix, token, meta = {})
    case prefix
      when ':'
        meta[:default] = token
      when ';'
        meta[:defaults] ||= []
        meta[:defaults] << token
      when ','
        meta[:options] ||= []
        meta[:options] << token
      else
        case token
          when /^(-?\d+)?\.\.(-?\d+)?$/
            meta[:min] = $1.to_i if $1
            meta[:max] = $2.to_i if $2
          when /^(\d+)\*(\d+)$/
            meta[:width]  = $1.to_i
            meta[:height] = $2.to_i
          else
            meta[:tokens] ||= []
            meta[:tokens] << token
        end
    end
    meta
  end

  def scan_inner_html(s, name)
    contents = ''
    gen = 1
    until s.eos? || (gen < 1)
      contents << s.scan(/(.*?)(<#{name}|<\/#{name}>|\z)/m)
      gen += 1 if s[2] == "<#{name}"
      gen -= 1 if s[2] == "</#{name}>"
    end
    contents.gsub!(/\A\n+/, '')
    contents.gsub!(/[\t ]*<\/#{name}>\z/, '')
    [contents, $&]
  end

  def scan_tokens(s)
    meta = {}
    until s.eos? || s.scan(/\)/)
      prefix = s[1] if s.scan /([:;,])?\s*/
      if s.scan /(["'])(.*?)(\1|$)/
        token = s[2]
      elsif s.scan /[^\s\):;,]+/
        token = s[0]
      end
      prefix ||= ',' if s.scan /(?=,)/ # 1st element of options
      prefix ||= ';' if s.scan /(?=;)/ # 1st element of defaults

      parse_token(prefix, token, meta)
      s.scan /\s+/
    end
    meta
  end

end
