dep 'confluence.installed', :version, :install_prefix, :home_directory, :confluence_user do
  version.default!('4.3.3')
  install_prefix.default!('/usr/local')
  home_directory.default!('/etc/confluence')
  confluence_user.default!('confluence')

  requires [
               'jre',
               'confluence.user'.with(confluence_user),
               'confluence'.with(version, install_prefix),
               'confluence.home_directory_set'.with(install_prefix, home_directory),
               'confluence.permissions'.with(install_prefix, home_directory, confluence_user)
           ]
end

dep 'confluence.user', :username do
  setup do
    must_be_root
  end

  met? {
    '/etc/passwd'.p.grep(/^#{username}\:/) and
        '/etc/group'.p.grep(/^#{username}\:/)
  }

  meet {
    shell "groupadd #{username}"
    shell "useradd --create-home --comment 'Account for running confluence' -g #{username} -s /bin/bash #{username}"
  }
end

dep 'confluence', :version, :install_prefix do
  setup do
    must_be_root
  end

  met? do
    "#{install_prefix}/confluence/bin/start-confluence.sh".p.exists?
  end

  meet do
    tar_file = "atlassian-confluence-#{version}.tar.gz"
    shell "wget http://www.atlassian.com/software/confluence/downloads/binary/#{tar_file} -P /tmp"
    shell "tar xvf /tmp/#{tar_file} -C #{install_prefix}"
    shell "mv #{install_prefix}/*confluence* #{install_prefix}/confluence"
    shell "rm /tmp/#{tar_file}"
  end
end

dep 'confluence.home_directory_set', :install_prefix, :home_directory do
  setup do
    must_be_root
  end

  met? do
    "#{install_prefix}/confluence/confluence/WEB-INF/classes/confluence-init.properties".p.grep(/#{home_directory}/)
  end

  meet do
    shell "mkdir -p #{home_directory}"
    shell "echo 'confluence.home=#{home_directory}' >> #{install_prefix}/confluence/confluence/WEB-INF/classes/confluence-init.properties"
  end
end

dep 'confluence.permissions', :install_prefix, :home_directory, :username do
  met? do
    output = shell?("stat #{install_prefix}/confluence/logs | grep Uid | grep #{username}")

    !output.nil?
  end

  meet do
    shell "chown -R root:root #{install_prefix}/confluence/"
    shell "chown -R #{username}:#{username} #{install_prefix}/confluence/logs"
    shell "chown -R #{username}:#{username} #{install_prefix}/confluence/temp"
    shell "chown -R #{username}:#{username} #{install_prefix}/confluence/work"
    shell "chown -R #{username}:#{username} #{home_directory}"
  end
end