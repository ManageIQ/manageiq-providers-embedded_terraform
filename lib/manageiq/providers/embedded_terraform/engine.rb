module ManageIQ
  module Providers
    module EmbeddedTerraform
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::EmbeddedTerraform

        config.autoload_paths << root.join('lib').to_s

        initializer :append_secrets do |app|
          app.config.paths["config/secrets"] << root.join("config", "secrets.defaults.yml").to_s
          app.config.paths["config/secrets"] << root.join("config", "secrets.yml").to_s
        end

        def self.vmdb_plugin?
          true
        end

        def self.menu
          [
            Menu::Section.new(:embedded_terraform_automation_manager, N_("Embedded Terraform"), nil, [
              Menu::Item.new('embedded_terraform_workflow',    N_('Workflows'),    'embedded_terraform_workflow',    {:feature => 'embedded_configuration_script_payload_view', :any => true}, '/embedded_terraform_workflow/show_list'),
              Menu::Item.new('embedded_terraform_repository',  N_('Repositories'), 'embedded_terraform_repository',  {:feature => 'embedded_configuration_script_source_view',  :any => true}, '/embedded_terraform_repository/show_list'),
              Menu::Item.new('embedded_terraform_credentials', N_('Credentials'),  'embedded_terraform_credentials', {:feature => 'embedded_configuration_script_source_view', :any => true},  '/embedded_terraform_credential/show_list')
            ], :default, :automate, :default, nil, :aut),
          ]
        end

        def self.plugin_name
          _('Embedded Terraform Provider')
        end

        def self.init_loggers
          $embedded_terraform_log ||= Vmdb::Loggers.create_logger("embedded_terraform.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $embedded_terraform_log, :level_embedded_terraform)
        end
      end
    end
  end
end
