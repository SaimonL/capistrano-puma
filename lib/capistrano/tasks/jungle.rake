git_plugin = self

namespace :puma do
  namespace :jungle do
    desc 'Install Puma jungle'
    task :install do
      on roles(fetch(:puma_role)) do |role|
        git_plugin.template_puma 'run-puma', "#{fetch(:tmp_dir)}/run-puma", role
        execute "chmod +x #{fetch(:tmp_dir)}/run-puma"

        if fetch(:nginx_sudo)
          sudo "mv #{fetch(:tmp_dir)}/run-puma #{fetch(:puma_run_path)}"
        else
          execute "mv #{fetch(:tmp_dir)}/run-puma #{fetch(:puma_run_path)}"
        end

        if test '[ -f /etc/redhat-release ]'
          #RHEL flavor OS
          git_plugin.rhel_install(role)
          execute "chmod +x #{fetch(:tmp_dir)}/puma"

          if fetch(:nginx_sudo)
            sudo "mv #{fetch(:tmp_dir)}/puma /etc/init.d/puma"
            sudo 'chkconfig --add puma'
          else
            execute "mv #{fetch(:tmp_dir)}/puma /etc/init.d/puma"
            execute 'chkconfig --add puma'
          end

        elsif test '[ -f /etc/lsb-release ]'
          #Debian flavor OS
          git_plugin.debian_install(role)
          execute "chmod +x #{fetch(:tmp_dir)}/puma"

          if fetch(:nginx_sudo)
            sudo "mv #{fetch(:tmp_dir)}/puma /etc/init.d/puma"
            sudo 'update-rc.d -f puma defaults'
          else
            execute "mv #{fetch(:tmp_dir)}/puma /etc/init.d/puma"
            execute 'update-rc.d -f puma defaults'
          end

        else
          #Some other OS
          error 'This task is not supported for your OS'
        end

        if fetch(:nginx_sudo)
          sudo "touch #{fetch(:puma_jungle_conf)}"
        else
          execute "touch #{fetch(:puma_jungle_conf)}"
        end
      end
    end

    desc 'Setup Puma config and install jungle script'
    task :setup do
      invoke 'puma:config'
      invoke 'puma:jungle:install'
      invoke 'puma:jungle:add'
    end

    desc 'Add current project to the jungle'
    task :add do
      on roles(fetch(:puma_role)) do|role|
        begin
          sudo "/etc/init.d/puma add '#{current_path}' #{fetch(:puma_user, role.user)} '#{fetch(:puma_conf)}'"
        rescue => error
          warn error
        end
      end
    end

    desc 'Remove current project from the jungle'
    task :remove do
      on roles(fetch(:puma_role)) do
        sudo "/etc/init.d/puma remove '#{current_path}'"
      end
    end

    %w[start stop restart status].each do |command|
      desc "#{command} puma"
      task command do
        on roles(fetch(:puma_role)) do
          sudo "service puma #{command} #{current_path}"
        end
      end
    end
  end
end
