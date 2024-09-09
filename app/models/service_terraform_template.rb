class ServiceTerraformTemplate < ServiceGeneric
  delegate :terraform_template, :to => :service_template, :allow_nil => true

  CONFIG_OPTIONS_WHITELIST = %i[
    credential_id
    execution_ttl
    extra_vars
    verbosity
  ].freeze

  def my_zone
    miq_request&.my_zone
  end

  # A chance for taking options from automate script to override options from a service dialog
  def preprocess(action, add_options = {})
    if add_options.present?
      _log.info("Override with new options:")
      $log.log_hashes(add_options)
    end

    save_job_options(action, add_options)
  end

  def execute(action)
    task_opts = {
      :action => "Launching Terraform Template",
      :userid => "system"
    }

    queue_opts = {
      :args        => [action],
      :class_name  => self.class.name,
      :instance_id => id,
      :method_name => "launch_terraform_template",
      :role        => "embedded_terraform",
      :zone        => my_zone
    }

    task_id = MiqTask.generic_action_with_callback(task_opts, queue_opts)
    task    = MiqTask.wait_for_taskid(task_id)
    raise task.message unless task.status_ok?
  end

  def check_completed(action)
    status = stack(action).raw_status
    done   = status.completed?

    # If the stack is completed the message has to be nil otherwise the stack
    # will get marked as failed
    _, message = status.normalized_status unless status.succeeded?
    [done, message]
  rescue MiqException::MiqOrchestrationStackNotExistError, MiqException::MiqOrchestrationStatusError => err
    [true, err.message] # consider done with an error when exception is caught
  end

  def launch_terraform_template(action)
    terraform_template = terraform_template(action)

    stack = ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Stack.create_stack(terraform_template, get_job_options(action))
    add_resource!(stack, :name => action)
  end

  def stack(action)
    service_resources.find_by(:name => action, :resource_type => 'OrchestrationStack').try(:resource)
  end

  def refresh(action)
    stack(action).refresh
  end

  def on_error(action)
    _log.info("on_error called for service action: #{action}")
    update(:retirement_state => 'error') if action == "Retirement"
    if job(action)
      stack(action).try(:refresh)
      postprocess(action)
    else
      _log.info("postprocess not called because job was nil")
    end
  end

  def postprocess(action)
    log_stdout(action)
  end


   def job(action)
     service_resources.find_by(:name => action, :resource_type => 'OrchestrationStack').try(:resource)
   end

  def check_refreshed(_action)
    [true, nil]
  end

  private

  def get_job_options(action)
    options[job_option_key(action)].deep_dup
  end

  def config_options(action)
    options.fetch_path(:config_info, action.downcase.to_sym).slice(*CONFIG_OPTIONS_WHITELIST).with_indifferent_access
  end

  def save_job_options(action, overrides)
    job_options = config_options(action)
    job_options[:extra_vars].try(:transform_values!) do |val|
      val.kind_of?(String) ? val : val[:default] # TODO: support Hash only
    end
    job_options.deep_merge!(parse_dialog_options) unless action == ResourceAction::RETIREMENT
    job_options.deep_merge!(overrides)
    translate_credentials!(job_options)

    options[job_option_key(action)] = job_options
    save!
  end

  def job_option_key(action)
    "#{action.downcase}_job_options".to_sym
  end

  def parse_dialog_options
    dialog_options = options[:dialog] || {}

    params = dialog_options.each_with_object({}) do |(attr, val), obj|
      var_key = attr.sub(/^(password::)?dialog_/, '')
      obj[var_key] = val
    end

    params.blank? ? {} : {:extra_vars => params}
  end

  def translate_credentials!(options)
    options[:credentials] = []

    credential_id = options.delete(:credential_id)
    options[:credentials] << Authentication.find(credential_id).native_ref if credential_id.present?
  end

  def log_stdout(action)
    log_option = options.fetch_path(:config_info, action.downcase.to_sym, :log_output) || 'on_error'
    job = job(action)
    if job.nil?
      $log.info("No stdout available due to missing job")
    else
      terraform_log_stdout(log_option, job)
    end
  end

  def terraform_log_stdout(log_option, job)
    raise ArgumentError, "invalid job object" if job.nil?
    return unless %(on_error always).include?(log_option)
    return if log_option == 'on_error' && job.raw_status.succeeded?

    $log.info("Stdout from ansible job #{job.name}: #{job.raw_stdout('txt_download')}")
  rescue StandardError => err
    if job.nil?
      $log.error("Job was nil, must pass a valid job")
    else
      $log.error("Failed to get stdout from ansible job #{job.name}")
    end
    $log.log_backtrace(err)
  end
end
