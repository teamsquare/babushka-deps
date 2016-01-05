dep 'sidekiq.running' do
  requires ['monit running', 'sidekiq.startable']

  setup do
    must_be_root
  end

  met? do
    (summary = shell("monit summary")) && summary[/'sidekiq'/]
  end

  meet do
    shell '/etc/init.d/redis-server stop && monit start redis'
  end
end

dep 'sidekiq.configured', :app_path, :user do
  setup do
    must_be_root
  end

  met? do
    "/etc/init/sidekiq.conf".p.grep(/^# Generated by babushka/)
  end

  meet do
    render_erb "init/sidekiq.conf.erb", :to => "/etc/init/sidekiq.conf", :perms => 644
  end
end


dep 'sidekiq.startable', :app_path, :user do
  requires [
    'sidekiq.configured'.with(app_path, user)
  ]

  setup do
    must_be_root
  end

  met? { "/etc/monit/conf.d/sidekiq.monitrc".p.exists? }
  meet do
    render_erb "monit/sidekiq.monitrc.erb", :to => "/etc/monit/conf.d/sidekiq.monitrc", :perms => 700
    shell "monit reload"
  end
end