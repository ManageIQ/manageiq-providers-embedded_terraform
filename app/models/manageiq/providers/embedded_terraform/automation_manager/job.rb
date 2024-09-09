class ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Job < Job
  def self.create_job(template, env_vars, input_vars, credentials, poll_interval: 1.minute)
    super(
      :template_id   => template.id,
      :env_vars      => env_vars,
      :input_vars    => input_vars,
      :credentials   => credentials,
      :poll_interval => poll_interval,
    )
  end

  def start
    queue_signal(:pre_execute)
  end

  def pre_execute
    checkout_git_repository
    route_signal(:execute)
  end

  def execute
    template_path = File.join(options[:git_checkout_tempdir], template_relative_path)
    credentials   = Authentication.where(:id => options[:credentials])
    extra_vars    = options.dig(:input_vars, :extra_vars) || {}

    response = Terraform::Runner.run(decrypt_extra_vars(extra_vars), template_path, :credentials => credentials, :env_vars => options[:env_vars])

    options[:terraform_stack_id] = response.stack_id
    save!
    route_signal(:poll_runner)
    #queue_poll_runner
  end

  def poll_runner
    if running?
      queue_poll_runner
    else
      logs_update
      route_signal(:post_execute)
    end
  end

  def post_execute
    
    #cleanup_git_repository
    
    return queue_signal(:finish, message, status) if success?
    #queue_signal(:finish, message, status)
    return queue_signal(:abort, "Failed to run ansible", "error") unless success?
    _log.error("Failed to run template: [#{error_message}]")
    
    abort_job("Failed to run template", "error")
  end

  def logs_update
    terraform_response = {
      stack_id: stack_response&.response&.stack_id,
      stack_name: stack_response&.response&.stack_name,
      status: stack_response&.response&.status,
      stack_job_end_time: stack_response&.response&.stack_job_end_time,
      stack_job_start_time: stack_response&.response&.stack_job_start_time,
      created_at: stack_response&.response&.created_at,
      message: stack_response&.response&.message,
      error_message: stack_response&.response&.error_message
    }

    miq_task.context_data ||= {}
    miq_task.context_data[:terraform_response] = terraform_response
    context[:terraform_response] = terraform_response
    
    update!(:context => context, :started_on => context[:terraform_response][:stack_job_start_time])
    miq_task.update(context_data: miq_task.context_data)
  end

  def queue_signal(*args, deliver_on: nil, msg_timeout: nil)
    role     = options[:role] || "ems_operations"
    priority = options[:priority] || MiqQueue::NORMAL_PRIORITY
    super(*args, :msg_timeout => msg_timeout, :priority => priority, :role => role, :deliver_on => deliver_on, :server_guid => MiqServer.my_server.guid)
  end

  def route_signal(*args, deliver_on: nil)
    if MiqEnvironment::Command.is_podified?
      signal(*args)
    else
      queue_signal(*args, :deliver_on => deliver_on)
    end
  end

  alias initializing dispatch_start
  alias finish       process_finished
  alias abort_job    process_abort
  alias cancel       process_cancel
  alias error        process_error

  protected

  def running?
    stack_response&.running?
  end

  def success?
    stack_response&.response&.status == "SUCCESS"
  end

  def error_message
    stack_response&.response&.error_message
  end

  def load_transitions
    self.state ||= 'initialize'

    {
      :initializing => {'initialize'       => 'waiting_to_start'},
      :start        => {'waiting_to_start' => 'pre_execute'},
      :pre_execute  => {'pre_execute'      => 'execute'},
      :execute      => {'execute'          => 'running'},
      :poll_runner  => {'running'          => 'running'},
      :post_execute => {'running'          => 'post_execute'},
      :finish       => {'*'                => 'finished'},
      :abort_job    => {'*'                => 'aborting'},
      :cancel       => {'*'                => 'canceling'},
      :error        => {'*'                => '*'}
    }
  end

  def poll_interval
    options.fetch(:poll_interval, 1.minute).to_i
  end

  private

  def template
    @template ||= self.class.module_parent::Template.find(options[:template_id])
  end

  def template_relative_path
    JSON.parse(template.payload)["relative_path"]
  end

  def stack_response
    return if options[:terraform_stack_id].nil?

    @stack_response ||= Terraform::Runner::ResponseAsync.new(options[:terraform_stack_id])
  end

  def decrypt_extra_vars(extra_vars)
    result = extra_vars.deep_dup
    result.transform_values! { |val| val.kind_of?(String) ? ManageIQ::Password.try_decrypt(val) : val }
  end

  def configuration_script_source
    @configuration_script_source ||= template.configuration_script_source
  end

  def queue_poll_runner
    queue_signal(:poll_runner, :deliver_on => Time.now.utc + poll_interval)
  end

  def checkout_git_repository
    options[:git_checkout_tempdir] = Dir.mktmpdir("embedded-terraform-runner-git")
    save!

    _log.info("Checking out git repository to #{options[:git_checkout_tempdir].inspect}...")
    configuration_script_source.checkout_git_repository(options[:git_checkout_tempdir])
  rescue MiqException::MiqUnreachableError => err
    miq_task.job.timeout!
    raise "Failed to connect with [#{err.class}: #{err}], job aborted"
  end

  def cleanup_git_repository
    return unless options[:git_checkout_tempdir]

    _log.info("Cleaning up git repository checkout at #{options[:git_checkout_tempdir].inspect}...")
    FileUtils.rm_rf(options[:git_checkout_tempdir])
  rescue Errno::ENOENT
    nil
  end
end
