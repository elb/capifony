namespace :symfony do
  desc "Runs custom symfony command"
  task :default, :roles => :app, :except => { :no_release => true } do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} #{task_arguments} --env=#{symfony_env_prod}'"
  end


  namespace :logs do
    [:tail, :tail_dev].each do |action|
      lines = ENV['lines'].nil? ? '50' : ENV['lines']
      log   = action.to_s == 'tail' ? 'prod.log' : 'dev.log'
      desc "Tail #{log}"
      task action, :roles => :app, :except => { :no_release => true } do
        run "#{try_sudo} tail -n #{lines} -f #{shared_path}/#{log_path}/#{log}" do |channel, stream, data|
          trap("INT") { puts 'Interupted'; exit 0; }
          puts
          puts "#{channel[:host]}: #{data}"
          break if stream == :err
        end
      end
    end
  end

  namespace :assets do
    desc "Updates assets version (in config.yml)"
    task :update_version, :roles => :app, :except => { :no_release => true } do
      run "#{try_sudo} sed -i 's/\\(assets_version:[ ]*\\)\\([a-zA-Z0-9_]*\\)\\(.*\\)$/\\1#{real_revision[0,7]}\\3/g' #{latest_release}/#{app_config_path}/config.yml"
    end

    desc "Installs bundle's assets"
    task :install, :roles => :app, :except => { :no_release => true } do
      capifony_pretty_print "--> Installing bundle's assets"

      install_options = ''

      if true == assets_symlinks then
        install_options += " --symlink"
      end

      if true == assets_relative then
        install_options += " --relative"
      end

      run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} assets:install #{web_path}#{install_options} --env=#{symfony_env_prod}'"
      capifony_puts_ok
    end
  end

  namespace :assetic do
    desc "Dumps all assets to the filesystem"
    task :dump, :roles => :app,  :except => { :no_release => true } do
      capifony_pretty_print "--> Dumping all assets to the filesystem"

      run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} assetic:dump --env=#{symfony_env_prod} --no-debug'"
      capifony_puts_ok
    end
  end

  namespace :vendors do
    [:install, :reinstall, :upgrade].each do |action|
      desc "Runs the bin/vendors script to #{action.to_s} the vendors"
      task action, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> #{action.to_s.capitalize}ing vendors"

        cmd = action.to_s
        case action
        when :reinstall
          cmd = "install --reinstall"
        when :upgrade
          cmd = "update"
        end

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_vendors} #{cmd}'"
        capifony_puts_ok
      end
    end
  end

  namespace :bootstrap do
    desc "Runs the bin/build_bootstrap script"
    task :build, :roles => :app, :except => { :no_release => true } do
      capifony_pretty_print "--> Building bootstrap file"

      if !remote_file_exists?("#{latest_release}/#{build_bootstrap}") && true == use_composer then
        set :build_bootstrap, "vendor/sensio/distribution-bundle/Sensio/Bundle/DistributionBundle/Resources/bin/build_bootstrap.php"
        run "#{try_sudo} sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} #{app_path} || echo '#{build_bootstrap} not found, skipped''"
      else
        run "#{try_sudo} sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped''"
      end

      capifony_puts_ok
    end
  end

  namespace :cache do
    [:clear, :warmup].each do |action|
      desc "Cache #{action.to_s}"
      task action, :roles => :app, :except => { :no_release => true } do
        case action
        when :clear
          capifony_pretty_print "--> Clearing cache"
        when :warmup
          capifony_pretty_print "--> Warming up cache"
        end

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{symfony_console} cache:#{action.to_s} --env=#{symfony_env_prod}'"
        run "#{try_sudo} chmod -R g+w #{latest_release}/#{cache_path}"
        capifony_puts_ok
      end
    end
  end

  namespace :project do
    desc "Clears all non production environment controllers"
    task :clear_controllers, :roles => :app, :except => { :no_release => true } do
      capifony_pretty_print "--> Clear controllers"

      command = "#{try_sudo} sh -c 'cd #{latest_release} && rm -f"
      controllers_to_clear.each do |link|
        command += " #{web_path}/" + link
      end
      run command + "'"

      capifony_puts_ok
    end
  end
end
