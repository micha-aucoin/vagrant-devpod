# -*- mode: ruby -*-
# vi: set ft=ruby :

def read_env_file(file)
  env = {}
  if File.exist?(file)
    File.readlines(file).each do |line|
      key, value = line.strip.split('=', 2)
      env[key] = value
    end
  end
  env
end

host_env = read_env_file('.env')

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.network "public_network"
  config.ssh.forward_x11 = true
  # config.ssh.forward_agent = true

  # config.vm.provision "shell", inline: "sleep 60"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = "4192" # 4GB of RANDUM
  end

  config.vm.provision "install packages", type: "shell" do |s|
    s.inline = <<-SHELL
      # sudo vim /etc/ssh/sshd_config
      # X11Forwarding yes
      # X11DisplayOffset 10
      # xdg-open http://github.com

      packages=(
          build-essential
          bash-completion
          git
          fzf
          jq
          firefox
          xdg-utils
          direnv
      )

      apt-get update
      for pkg in "${packages[@]}"; do
          echo "Installing $pkg..."
          apt-get install -y --no-install-recommends "$pkg"
      done
    SHELL
  end

  config.vm.provision "install kubectl", type: "shell" do |s|
    s.inline = <<-SHELL
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
      if echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check; then
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      fi
      rm -f kubectl kubectl.sha256
    SHELL
  end

  config.vm.provision "direnv", type: "shell", privileged: false do |s|
    s.inline = "echo 'eval \"$(direnv hook bash)\"' >> ~/.bashrc"
  end

  config.vm.provision "set_timezone", type: "shell" do |s|
    s.inline = "timedatectl set-timezone 'America/Chicago'"
  end

  config.vm.provision "ssh_keygen", type: "shell", privileged: false do |s|
    s.inline = "ssh-keygen -t ed25519 -f '/home/vagrant/.ssh/#{host_env['SSH_NAME']}' -N '' -C '#{host_env['SSH_NAME']}'"
  end

  config.vm.provision "bash_aliases", type: "shell", privileged: false do |s|
    s.inline = "echo \"alias ssha='eval \\$(ssh-agent -s) && ssh-add ~/.ssh/#{host_env['SSH_NAME']}'\" >> ~/.bash_aliases"
  end

  config.vm.provision "install devpod", type: "shell", privileged: false do |s|
    s.inline = 'curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64" && sudo install -c -m 0755 devpod /usr/local/bin && rm -f devpod'
  end

  config.vm.provision "add kubernetes provider", type: "shell", privileged: false do |s|
    s.inline = 'devpod provider add kubernetes && devpod provider use kubernetes && devpod provider list'
  end
  
  config.vm.provision "no ide", type: "shell", privileged: false do |s|
    s.inline = 'devpod ide use none && devpod ide list'
  end

  config.vm.provision "set dotfiles", type: "shell", privileged: false do |s|
    s.inline = 'devpod context set-options -o DOTFILES_URL=git@github.com:micha-aucoin/dotfiles-devpod.git'
  end

  config.vm.provision "add_github_repos", type: "shell", privileged: false do |s|
    s.path = "scripts/add_github_repos.sh"
    s.env = {
      "GITHUB_TOKEN" => host_env['GITHUB_TOKEN'],
      "SSH_NAME" => host_env['SSH_NAME'],
      "GIT_COMMANDS" => <<-EOF
        git clone git@github.com:micha-aucoin/homelab.git;
      EOF
    }
  end

  config.vm.provision "symlinks", type: "shell", privileged: false do |s|
    s.inline = <<-SHELL
      cp /vagrant/kubeconfig /vagrant/.envrc $HOME/homelab
      chmod 600 $HOME/homelab/.envrc $HOME/homelab/kubeconfig
    SHELL
  end

  config.trigger.before :destroy do |trigger|
    trigger.name = "remove_gh_ssh_key"
    trigger.warn = "This will remove the SSH key from your GitHub account."
    trigger.run_remote = {
      path: "scripts/remove_gh_ssh_key.sh",
      env: {
        "GITHUB_TOKEN" => host_env['GITHUB_TOKEN']
      }
    }
  end

end
