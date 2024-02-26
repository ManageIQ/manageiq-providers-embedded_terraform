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

  def container_image
    "opentofu-runner"
  end
end
