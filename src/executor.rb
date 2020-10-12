require 'tty-reader'
require 'pathname'
require 'tty-table'
require 'date'

class Executor

  # @param [ApiProvider] api_client
  def initialize(api_client, client_name)
    @cwd = Pathname.new '/'
    @api = api_client
    @clname = client_name
  end

  def run
    reader = TTY::Reader.new
    loop do
      line = reader.read_line("XDFS:#{@cwd} % ")
      execute_command line
    rescue RuntimeError => e
      puts "\n#{e}"
      next
    rescue TTY::Reader::InputInterrupt, Interrupt
      puts "\nBye!"
      break
    end
  end

  private

  # @param [String] line
  def execute_command(line)
    command, *args = line.split(/[\s]+/)

    case command
    when 'mkfs'
      reset
    when 'cd'
      change_dir(args[0])
    when 'ls'
      list_dir
    when 'touch'
      touch_file(args[0])
    when 'file'
      file_info(args[0])
    when 'rm'
      unlink_file(args[0])
    when 'rm-r'
      rmdir(args[0])
    when 'rm-rf'
      rmdirf(args[0])
    when 'cp'
      copy_file(args[0], args[1])
    when 'cp-f'
      fcopy_file(args[0], args[1])
    when 'mv'
      move_file(args[0], args[1])
    when 'mv-f'
      fmove_file(args[0], args[1])
    when 'mkdir'
      mkdir(args[0])
    when 'xferdn'
      download(args[0], args[1])
    when 'xferup'
      download(args[0], args[1])
    else
      raise RuntimeError, "unknown command!"
    end

    raise Interrupt if command == 'exit'
  end

  def download(remote, local)
    resolved = @cwd.join remote

    res = @api.send_request('files.download', {
      filename: resolved.to_path
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    puts "Got from #{res['result']['from']}"

    IO.binwrite local, res['result']['contents']
  end

  def upload(local, remote)
    resolved = @cwd.join remote

    contents = IO.binread local

    res = @api.send_request('files.upload', {
      filename: resolved.to_path,
      contents: contents,
      clientId: @clname
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Replicated on'])

    res['result']['replicatedOn'].each { |r| table << [r] }

    puts table.render(:basic)
  end

  def mkdir(dirname)
    resolved = @cwd.join dirname

    res = @api.send_request('directories.make', {
      dirname: resolved.to_path,
      clientId: @clname
    })

    raise RuntimeError, res['error']['message'] unless res['success']
  end

  def copy_file(from, to)
    fres = @cwd.join from
    tres = @cwd.join to

    res = @api.send_request('files.copy', {
      clientId: @clname,
      from: fres.to_path,
      to: tres.to_path,
      force: false
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Replicated on'])

    res['result']['replicatedOn'].each { |r| table << [r] }

    puts table.render(:basic)
  end

  def fcopy_file(from, to)
    fres = @cwd.join from
    tres = @cwd.join to

    res = @api.send_request('files.copy', {
      clientId: @clname,
      from: fres.to_path,
      to: tres.to_path,
      force: true
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Replicated on'])

    res['result']['replicatedOn'].each { |r| table << [r] }

    puts table.render(:basic)
  end

  def move_file(from, to)
    fres = @cwd.join from
    tres = @cwd.join to

    res = @api.send_request('files.move', {
      clientId: @clname,
      from: fres.to_path,
      to: tres.to_path,
      force: false
    })

    raise RuntimeError, res['error']['message'] unless res['success']
  end

  def fmove_file(from, to)
    fres = @cwd.join from
    tres = @cwd.join to

    res = @api.send_request('files.move', {
      clientId: @clname,
      from: fres.to_path,
      to: tres.to_path,
      force: true
    })

    raise RuntimeError, res['error']['message'] unless res['success']
  end

  def reset
    res = @api.send_request('xdfs.reset', nil)

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Available servers'])

    res['result']['replicas'].each { |r| table << [r] }

    puts table.render(:basic)
    puts "Total space available: #{coerce_size(res['result']['spaceAvailable'])}"
  end

  def rmdir(dname)
    resolved = @cwd.join dname

    res = @api.send_request('directories.delete', {
      dirname: resolved.to_path,
      recursive: false
    })

    raise RuntimeError, res['error']['message'] unless res['success']
  end

  def rmdirf(dname)
    resolved = @cwd.join dname

    res = @api.send_request('directories.delete', {
      dirname: resolved.to_path,
      recursive: true
    })

    raise RuntimeError, res['error']['message'] unless res['success']
  end

  def unlink_file(fname)
    resolved = @cwd.join fname

    res = @api.send_request('files.unlink', {
      filename: resolved.to_path
    })

    raise RuntimeError, res['error']['message'] unless res['success']
  end

  def change_dir(target_dir)
    resolved = @cwd.join target_dir

    res = @api.send_request('directories.read', {
      dirname: resolved.to_path
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    @cwd = resolved
  end

  def list_dir
    res = @api.send_request('directories.read', {
      dirname: @cwd.to_path
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Node', 'Type', 'Created at', 'Created by', 'Size'])

    res['result']['contents'].each do |c|
      table << [
        c['name'],
        c['type'],
        Time.at(c['createdAt']).strftime("%d/%m/%Y %R"),
        c['createdBy'],
        coerce_size(c['size'])
      ]
    end

    puts table.render(:basic)
  end

  def touch_file(fname)
    resolved = @cwd.join fname

    res = @api.send_request('files.create', {
      filename: resolved.to_path,
      clientId: @clname
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Replicated on'])

    res['result']['replicatedOn'].each { |r| table << [r] }

    puts table.render(:basic)
  end

  def file_info(fname)
    resolved = @cwd.join fname

    res = @api.send_request('files.getInfo', {
      filename: resolved.to_path,
    })

    raise RuntimeError, res['error']['message'] unless res['success']

    table = TTY::Table.new(header: ['Replicated on'])

    res['result']['replication'].each { |r| table << [r] }

    puts table.render(:basic)

    c = res['result']['nodeInfo']

    puts "Name: #{c['name']}"
    puts "Created At: #{Time.at(c['createdAt']).strftime("%d/%m/%Y %R")}"
    puts "Created By: #{c['createdBy']}"
    puts "Size: #{coerce_size(c['size'])}"
  end

  def coerce_size(size)
    suffixes = %w[b k M G]

    suffixes.each do |suf|
      return "#{size}#{suf}" if size < 1024

      size = (size / 1024.0).ceil(1)
    end
  end
end