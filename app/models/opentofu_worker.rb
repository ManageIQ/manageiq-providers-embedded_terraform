class OpentofuWorker < MiqWorker
  include MiqWorker::ServiceWorker

  self.required_roles        = ["embedded_terraform"]
  self.rails_worker          = false
  self.maximum_workers_count = 1

  HEALTH_PORT = 6000

  def self.service_base_name
    "opentofu-runner"
  end

  def self.service_file
    "#{service_base_name}.service"
  end

  def self.kill_priority
    MiqWorkerType::KILL_PRIORITY_GENERIC_WORKERS
  end

  def worker_deployment_name
    @worker_deployment_name ||= "#{deployment_prefix}opentofu-runner"
  end

  def container_port
    6000
  end

  def add_liveness_probe(container_definition)
    container_definition[:livenessProbe] = container_definition[:livenessProbe].except(:exec).merge(:httpGet => {:path => "/api/v1/ready", :port => HEALTH_PORT, :scheme => "HTTPS"})
  end

  def add_readiness_probe(container_definition)
    container_definition[:readinessProbe] = {
      :httpGet             => {:path => "/api/v1/ready", :port => HEALTH_PORT, :scheme => "HTTPS"},
      :initialDelaySeconds => 60,
      :timeoutSeconds      => 3
    }
  end

  private

  # There can only be a single instance running so the unit name can just be
  # "opentofu-runner.service"
  def unit_instance
    ""
  end

  def container_image_name
    "opentofu-runner"
  end

  def container_image
    ENV["OPENTOFU_RUNNER_IMAGE"] || worker_settings[:container_image] || default_image
  end

  def enable_systemd_unit
    super
    create_podman_secret
  end

  def unit_environment_variables
    {
      "DATABASE_HOSTNAME"     => database_configuration[:host],
      "DATABASE_NAME"         => database_configuration[:database],
      "DATABASE_USERNAME"     => database_configuration[:username],
      "MEMCACHE_SERVERS"      => ::Settings.session.memcache_server,
      "OPENTOFU_RUNNER_IMAGE" => container_image
    }
  end

  def configure_service_worker_deployment(definition)
    super
    if ENV["API_SSL_SECRET_NAME"].present?
      definition[:spec][:template][:spec][:containers].first[:volumeMounts] << {:name => "cert-path", :mountPath => "/opt/app-root/src/config/cert"}
      definition[:spec][:template][:spec][:volumes] << {:name => "cert-path", :secret => {:secretName => ENV["API_SSL_SECRET_NAME"], :items => [{:key => "tf_runner_crt", :path => "tls.crt"}, {:key => "tf_runner_key", :path => "tls.key"}], :defaultMode => 420}}
    end
  end

  def create_podman_secret
    return if AwesomeSpawn.run("runuser", :params => [[:login, "manageiq"], [:command, "podman secret exists --root=#{Rails.root.join("data/containers/storage")} opentofu-runner-secret"]]).success?

    secret = {"DATABASE_PASSWORD" => database_configuration[:password]}

    AwesomeSpawn.run!("runuser", :params => [[:login, "manageiq"], [:command, "podman secret create --root=#{Rails.root.join("data/containers/storage")} opentofu-runner-secret -"]], :in_data => secret.to_json)
  end

  def database_configuration
    ActiveRecord::Base.connection_db_config.configuration_hash
  end
end
