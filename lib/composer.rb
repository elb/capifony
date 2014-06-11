# Whether to use composer to install vendors.
# If set to false, it will use the bin/vendors script
set :use_composer,          false

# Path to composer binary
# If set to false, Capifony will download/install composer
set :composer_bin,          false

# Options to pass to composer when installing/updating
set :composer_options,      "--no-scripts --verbose --prefer-dist"

# Whether to update vendors using the configured dependency manager (composer or bin/vendors)
set :update_vendors,        false

# Copy vendors from previous release
set :copy_vendors,          false

set :vendor_dir,            "vendor"

namespace :symfony do
  namespace :composer do
    desc "Gets composer and installs it"
    task :get, :roles => :app, :except => { :no_release => true } do
      if remote_file_exists?("#{previous_release}/composer.phar")
        capifony_pretty_print "--> Copying Composer from previous release"
        run "#{try_sudo} sh -c 'cp #{previous_release}/composer.phar #{latest_release}/'"
        capifony_puts_ok
      end

      if !remote_file_exists?("#{latest_release}/composer.phar")
        capifony_pretty_print "--> Downloading Composer"

        run "#{try_sudo} sh -c 'cd #{latest_release} && curl -s http://getcomposer.org/installer | #{php_bin}'"
      else
        capifony_pretty_print "--> Updating Composer"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} composer.phar self-update'"
      end
      capifony_puts_ok
    end

    desc "Updates composer"

    desc "Runs composer to install vendors from composer.lock file"
    task :install, :roles => :app, :except => { :no_release => true } do
      if !composer_bin
        symfony.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      capifony_pretty_print "--> Installing Composer dependencies"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} install #{composer_options}'"
      capifony_puts_ok
    end

    desc "Runs composer to update vendors, and composer.lock file"
    task :update, :roles => :app, :except => { :no_release => true } do
      if !composer_bin
        symfony.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      capifony_pretty_print "--> Updating Composer dependencies"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} update #{composer_options}'"
      capifony_puts_ok
    end

    desc "Dumps an optimized autoloader"
    task :dump_autoload, :roles => :app, :except => { :no_release => true } do
      if !composer_bin
        symfony.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      capifony_pretty_print "--> Dumping an optimized autoloader"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} dump-autoload --optimize'"
      capifony_puts_ok
    end

    task :copy_vendors, :except => { :no_release => true } do
      capifony_pretty_print "--> Copying vendors from previous release"

      run "vendorDir=#{current_path}/#{vendor_dir}; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir #{latest_release}/#{vendor_dir}; fi;"
      capifony_puts_ok
    end
  end
end