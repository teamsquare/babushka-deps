dep 'crucible.installed', :version, :install_prefix, :home_directory, :crucible_user do
  version.default!('2.9.1')
  install_prefix.default!('/usr/local')
  home_directory.default!('/etc/crucible')
  crucible_user.default!('crucible')

  requires [
               'jdk'.with(6),
               'unzip.managed',
               'crucible.user'.with(crucible_user),
               'crucible'.with(version, install_prefix),
               'crucible.home_directory_set'.with(install_prefix, home_directory),
               'crucible.permissions'.with(install_prefix, home_directory, crucible_user)
           ]
end

dep 'crucible.user', :username do
  setup do
    must_be_root
  end

  met? {
    '/etc/passwd'.p.grep(/^#{username}\:/) and
        '/etc/group'.p.grep(/^#{username}\:/)
  }

  meet {
    shell "groupadd #{username}"
    shell "useradd --create-home --comment 'Account for running crucible' -g #{username} -s /bin/bash #{username}"
  }
end

dep 'crucible', :version, :install_prefix do
  setup do
    must_be_root
  end

  met? do
    "#{install_prefix}/crucible/bin/start.sh".p.exists?
  end

  meet do
    tar_file = "crucible-#{version}.zip"

    shell "wget http://www.atlassian.com/software/crucible/downloads/binary/#{tar_file} -P /tmp"
    shell "unzip /tmp/#{tar_file} -d /tmp"
    shell "mv /tmp/fecru-#{version} #{install_prefix}/crucible"
    shell "rm /tmp/#{tar_file}"
    shell "rm -rf /tmp/fecru-#{version}"
  end
end

dep 'crucible.home_directory_set', :install_prefix, :home_directory do
  setup do
    must_be_root
  end

  met? do
    "/etc/environment".p.grep(/FISHEYE_INST/)
  end

  meet do
    shell "mkdir -p #{home_directory}"
    shell "echo 'FISHEYE_INST=#{home_directory}' >> /etc/environment"
    shell "cp #{install_prefix}/crucible/config.xml #{home_directory}"  end
end

dep 'crucible.permissions', :install_prefix, :home_directory, :username do
  met? do
    output = shell?("stat #{install_prefix}/crucible | grep Uid | grep #{username}")

    !output.nil?
  end

  meet do
    shell "chown -R #{username}:#{username} #{install_prefix}/crucible/"
    shell "chown -R #{username}:#{username} #{home_directory}"
  end
end