require_relative 'src/api/api_provider'
require_relative 'src/executor'

username = ARGV.shift
server = ARGV.shift

api = ApiProvider.new(server)

cint = Executor.new(api, username)

cint.run