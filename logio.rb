dep 'logio', :install_prefix do
  install_prefix.default!('/usr/local')

  requires 'npm installed'

  met? do
    "#{install_prefix}/bin/log.io".p.exists?
  end

  meet do
    shell 'npm config set unsafe-perm true'
    shell "npm install -g --prefix=#{install_prefix} log.io"
  end
end

dep 'logio.harvester', :logio_server, :node_type do
  requires 'logio'

  met? do
    '/etc/log.io/harvester.conf'.p.grep(/^\/\/ Generated by babushka/)
  end

  meet do
    render_erb "logio/#{node_type}_harvester.conf.erb", :to => "/etc/log.io/harvester.conf", :perms => 644, :comment => '//', :comment_suffix => ''
  end
end