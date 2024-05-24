class ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Stack < ManageIQ::Providers::EmbeddedAutomationManager::OrchestrationStack
  belongs_to :ext_management_system,        :foreign_key => :ems_id,                       :class_name => "ManageIQ::Providers::EmbeddedTerraform::AutomationManager",           :inverse_of => false
  belongs_to :configuration_script_payload, :foreign_key => :configuration_script_base_id, :class_name => "ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Template", :inverse_of => :stacks
  belongs_to :miq_task,                     :foreign_key => :ems_ref,                      :inverse_of => false

  class << self
    alias create_job     create_stack
    alias raw_create_job raw_create_stack

    def create_stack(terraform_template, options = {})
      authentications = collect_authentications(terraform_template.manager, options)

      job = raw_create_stack(terraform_template, options)

      miq_task = job&.miq_task

      create!(
        :name                         => terraform_template.name,
        :ext_management_system        => terraform_template.manager,
        :verbosity                    => options[:verbosity].to_i,
        :authentications              => authentications,
        :configuration_script_payload => terraform_template,
        :miq_task                     => miq_task,
        :status                       => miq_task&.state,
        :start_time                   => miq_task&.started_on
      )
    end

    def raw_create_stack(terraform_template, options = {})
      terraform_template.run(options)
    rescue => err
      _log.error("Failed to create job from template(#{terraform_template.name}), error: #{err}")
      raise MiqException::MiqOrchestrationProvisionError, err.to_s, err.backtrace
    end

    private

    def collect_authentications(manager, options)
      credential_ids = options[:credentials] || []

      manager.credentials.where(:id => credential_ids)
    end
  end

  def raw_status
    Status.new(miq_task, nil)
  end
end
