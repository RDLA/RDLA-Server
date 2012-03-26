path =  `echo \`pwd\`/rdla-server.rb`

God.watch do |w|
  w.log = '/home/damien/godlog.log'
  w.name = "rdla-server"
  w.start = "ruby #{path}"
  w.keepalive
end
