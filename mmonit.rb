dep 'mmonit.running', :version, :install_prefix do
  version.default!('2.4')
  install_prefix.default!('/usr/local')

  requires %w(mmonit mmonit.startable)

  setup do
    must_be_root
  end

  met? do
    (summary = shell("monit summary")) && summary[/'mmonit'.*Running/]
  end

  meet do
    shell 'monit start mmonit'
  end
end

dep 'mmonit', :version, :install_prefix do
  setup do
    must_be_root
  end

  requires 'flex.managed', 'libsqlite3-dev.managed', 'libzdb.src', 'user and group exist'.with(:user => 'mmonit')

  version.default!('2.4')
  install_prefix.default!('/usr/local')

  met? do
    "#{install_prefix}/mmonit-#{version}/bin/mmonit".p.exists?
  end

  meet do
    tar_file = "mmonit-#{version}-linux-x64.tar.gz"
    shell "wget http://mmonit.com/dist/#{tar_file} -P /tmp"
    shell "tar xvf /tmp/#{tar_file} -C #{install_prefix}"
    shell "rm /tmp/#{tar_file}"
  end
end

dep 'mmonit.startable', :version, :install_prefix do
  setup do
    must_be_root
  end

  version.default!('2.4')
  install_prefix.default!('/usr/local')

  met? { "/etc/monit/mmonit.monitrc".p.exists? }
  meet do
    render_erb "monit/mmonit.monitrc.erb", :to => "/etc/monit/conf.d/mmonit.monitrc", :perms => 700
    shell "monit reload"
  end
end