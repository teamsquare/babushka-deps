dep 'memcached.running' do
  requires [
    'user and group exist'.with(:user => 'memcached'),
    'memcached.managed',
    'memcached.startable'
  ]

  setup do
    must_be_root
  end

  met? do
    (summary = shell("monit summary")) && summary[/'memcached'.*(Initializing|Running|Not monitored - start pending)/]
  end

  meet do
    shell '/etc/init.d/memcached stop && monit start memcached'
  end
end

dep 'memcached.startable' do
  setup do
    must_be_root
  end

  met? {
    "/etc/monit/conf.d/memcached.monitrc".p.exists? &&
    "/etc/memcached.conf".p.exists? &&
    "/etc/monit/conf.d/memcached.monitrc".p.grep(/^# Generated by babushka/) &&
    "/etc/memcached.conf".p.grep(/^# Generated by babushka/)
  }

  meet do
    render_erb "monit/memcached.monitrc.erb", :to => "/etc/monit/conf.d/memcached.monitrc", :perms => 700
    render_erb "memcached/memcached.conf.erb", :to => "/etc/memcached.conf", :perms => 644
    shell "monit reload"
  end
end