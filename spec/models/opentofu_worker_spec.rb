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

  context "kubernetes deployment" do
    let(:apps_connection_stub) { double("AppsConnection") }
    let(:orchestrator) { ContainerOrchestrator.new }
    before { EvmSpecHelper.local_miq_server }

    it "exposes the correct port" do
      allow(ContainerOrchestrator).to receive(:new).and_return(orchestrator)
      expect(orchestrator).to receive(:my_node_affinity_arch_values).and_return(["amd64", "arm64"])
      expect(orchestrator).to receive(:kube_apps_connection).and_return(apps_connection_stub)
      expect(orchestrator).to receive(:my_namespace).and_return("my-namespace")
      expect(subject).to     receive(:scale_deployment)

      expect(apps_connection_stub).to receive(:create_deployment) do |deployment|
        expect(deployment.fetch_path(:spec, :template, :spec, :containers, 0, :ports)).to match_array([{:containerPort => 6000}])
      end

      subject.create_container_objects
    end
  end
end
