class OpentofuWorker < MiqWorker
  self.required_roles = ["embedded_terraform"]
  self.rails_worker   = false

  def self.service_base_name
    "opentofu-runner"
  end

  def self.service_file
    "#{service_base_name}.service"
  end

  def self.worker_deployment_name
    "opentofu-runner"
  end

  def self.kill_priority
    MiqWorkerType::KILL_PRIORITY_GENERIC_WORKERS
  end

  self.maximum_workers_count = 1

  # There can only be a single instance running so the unit name can just be
  # "opentofu-runner.service"
  def unit_instance
    ""
  end

  def container_image_name
    "opentofu-runner"
  end

  def container_image_namespace
    ENV["CONTAINER_IMAGE_NAMESPACE"]
  end

  def container_image_tag
    ENV["CONTAINER_IMAGE_TAG"] || "latest"
  end

  def default_image
    "#{container_image_namespace}/#{container_image_name}:#{container_image_tag}"
  end

  def container_image
    ENV["OPENTOFU_RUNNER_IMAGE"] || default_image
  end

  def unit_config_file
    # Override this in a sub-class if the specific instance needs
    # any additional config
    <<~UNIT_CONFIG_FILE
      [Service]
      MemoryHigh=#{worker_settings[:memory_threshold].bytes}
      TimeoutStartSec=#{worker_settings[:starting_timeout]}
      TimeoutStopSec=#{worker_settings[:stopping_timeout]}
      #{unit_environment_variables.map { |env_var| "Environment=#{env_var}" }.join("\n")}
    UNIT_CONFIG_FILE
  end

  def unit_environment_variables
    database_config = ActiveRecord::Base.connection_db_config.configuration_hash

    [
      "DATABASE_HOSTNAME=#{database_config[:host]}",
      "DATABASE_NAME=#{database_config[:database]}",
      "DATABASE_USERNAME=#{database_config[:username]}",
      "MEMCACHED_SERVER=#{::Settings.session.memcache_server}"
    ]
  end

end
