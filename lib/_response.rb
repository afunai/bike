# encoding: UTF-8

# Author::    Akira FUNAI
# Copyright:: Copyright (c) 2009 Akira FUNAI

module Bike::Response

  module_function

  def ok(result = {})
    body = result[:body].to_s
    return not_found(result) if body.empty?
    [
      200,
      (
        result[:headers] ||
        {
          'Content-Type'   => 'text/html',
          'Content-Length' => body.size.to_s,
        }
      ),
      [body],
    ]
  end

  def no_content(result = {})
    [
      204,
      (result[:headers] || {}),
      []
    ]
  end

  def see_other(result = {})
    body = <<_html
<a href="#{result[:location]}">see other</a>
_html
    [
      303,
      {
        'Content-Type'   => 'text/html',
        'Content-Length' => body.size.to_s,
        'Location'       => result[:location],
      },
      [body]
    ]
  end

  def forbidden(result = {})
    body = result[:body] || 'Forbidden'
    [
      403,
      {
        'Content-Type'   => 'text/html',
        'Content-Length' => body.size.to_s,
      },
      [body],
    ]
  end

  def not_found(result = {})
    body = result[:body] || 'Not Found'
    [
      404,
      {
        'Content-Type'   => 'text/html',
        'Content-Length' => body.size.to_s,
      },
      [body]
    ]
  end

  def unprocessable_entity(result = {})
    body = result[:body].to_s
    return not_found(result) if body.empty?
    [
      422,
      (
        result[:headers] ||
        {
          'Content-Type'   => 'text/html',
          'Content-Length' => body.size.to_s,
        }
      ),
      [body],
    ]
  end

end
