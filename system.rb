def ssh_conf_path file
  "/etc#{'/ssh' if Babushka.host.linux?}/#{file}_config"
end

dep 'system', :host_name, :locale_name do
  setup do
    must_be_root
  end

  requires [
    'set.locale'.with(locale_name),
    'hostname'.with(host_name),
    'secured ssh logins',
    'core software',
    'lax host key checking',
    'admins can sudo',
    'tmp cleaning grace period'
  ]

  requires 'bad certificates removed' if Babushka.host.linux?
end

dep 'hostname', :host_name, :for => :linux do
  def current_hostname
    shell('hostname -f')
  end
  host_name.default(shell('hostname'))
  met? {
    current_hostname == host_name
  }
  meet {
    sudo "echo #{host_name} > /etc/hostname"
    sudo "sed -ri 's/^127.0.0.1.*$/127.0.0.1 #{host_name} #{host_name.to_s.sub(/\..*$/, '')} localhost.localdomain localhost/' /etc/hosts"
    sudo "hostname #{host_name}"
  }
end

# It's hard to test for other timezones (EST maps to Australia/Melbourne, etc),
# and I only need UTC right now :)
dep 'utc' do
  met? {
    shell('date')[/\bUTC\b/]
  }
  meet {
    sudo 'echo UTC > /etc/timezone'
    sudo 'dpkg-reconfigure --frontend noninteractive tzdata'
  }
end

dep 'secured ssh logins' do
  requires 'sshd.managed', 'sed.managed'
  met? {
    # -o NumberOfPasswordPrompts=0
    output = raw_shell('ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no nonexistentuser@localhost').stderr
    if output.downcase['connection refused']
      log_ok "sshd doesn't seem to be running."
    elsif (auth_methods = output.scan(/Permission denied \((.*)\)\./).join.split(',')).empty?
      log_error "sshd returned unexpected output."
    else
      (auth_methods == %w[publickey]).tap {|result|
        log "sshd #{'only ' if result}accepts #{auth_methods.to_list} logins.", :as => (:ok if result)
      }
    end
  }
      meet {
        %w[
      PasswordAuthentication
      GSSAPIAuthentication
      ChallengeResponseAuthentication
    ].each {|option|
          shell("sed -i'' -e 's/^[# ]*#{option}\\W*\\w*$/#{option} no/' #{ssh_conf_path(:sshd)}")
        }
      }
      after {
        if [:debian, :ubuntu].include?(Babushka.host.flavour)
          shell "/etc/init.d/ssh restart"
    elsif [:centos].include?(Babushka.host.flavour)
      shell "/etc/init.d/sshd restart"
    else
      log "not sure how to restart ssh daemon on this host type"
    end
  }
end

dep 'lax host key checking' do
  requires 'sed.managed'
  met? {
    ssh_conf_path(:ssh).p.grep(/^StrictHostKeyChecking[ \t]+no/)
  }
  meet {
    shell("sed -i'' -e 's/^[# ]*StrictHostKeyChecking\\W*\\w*$/StrictHostKeyChecking no/' #{ssh_conf_path(:ssh)}")
  }
end

dep 'admins can sudo' do
  requires 'sudo.managed', 'admin group'
  met? {
    !'/etc/sudoers'.p.read.split("\n").grep(/^%admin\b/).empty?
  }
  meet {
    '/etc/sudoers'.p.append("%admin  ALL=(ALL) ALL\n")
  }
end

dep 'admin group' do
  met? { '/etc/group'.p.grep(/^admin\:/) }
  meet { sudo 'groupadd admin' }
end

dep 'tmp cleaning grace period', :for => :ubuntu do
  met? {
    "/etc/default/rcS".p.grep(/^[^#]*TMPTIME=0/).nil?
  }
  meet {
    shell("sed -i'' -e 's/^TMPTIME=0$/TMPTIME=30/' '/etc/default/rcS'")
  }
end