# frozen_string_literal: true

require 'msgpack'
require 'faraday'

class ApiProvider
  def initialize(connector)
    @connector = connector
  end

  def send_request(method, params = nil)
    body = prepare_request(method, params)

    rsp = Faraday.post(@connector, body, {
      'Content-Type': 'application/msgpack',
      'Accept': 'application/msgpack'
    })

    parse_body rsp
  end

  private

  def prepare_request(method, params)
    MessagePack.pack({
                       jsonrpc: '2.0',
                       method: method,
                       params: params
                     })
  end

  def parse_body(rsp)
    MessagePack.unpack rsp.body
  end
end
