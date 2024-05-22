RSpec.describe OpentofuWorker do
  let(:miq_server) { EvmSpecHelper.local_miq_server }
  let(:worker)     { FactoryBot.create(:opentofu_worker, :miq_server => miq_server) }

  it ".service_base_name" do
    expect(described_class.service_base_name).to eq("opentofu-runner")
  end

  it ".service_file" do
    expect(described_class.service_file).to eq("opentofu-runner.service")
  end

  it "#unit_name" do
    expect(worker.unit_name).to eq("opentofu-runner.service")
  end

  it "#container_port" do
    expect(worker.container_port).to eq(6000)
  end

  it "#worker_deployment_name" do
    expect(worker.worker_deployment_name).to eq("#{miq_server.compressed_id}-opentofu-runner")
  end
end
