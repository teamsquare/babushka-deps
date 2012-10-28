dep 'npm installed' do
  requires 'nodejs installed'

  met? do
    '/usr/local/bin/npm'.p.exists?
  end

  meet do
    shell 'curl https://npmjs.org/install.sh | sudo sh'
  end
end