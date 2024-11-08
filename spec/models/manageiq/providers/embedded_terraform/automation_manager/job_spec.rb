RSpec.describe ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Job do
  let(:template)    { FactoryBot.create(:terraform_template) }
  let(:job)         { described_class.create_job(template, env_vars, input_vars, credentials).tap { |job| job.state = state } }
  let(:state)       { "waiting_to_start" }
  let(:env_vars)    { {} }
  let(:input_vars)  { {:extra_vars => {}} }
  let(:credentials) { [] }
  let(:terraform_stack_id) { '999-999-999-999' }

  describe ".create_job" do
    it "create a job" do
      expect(described_class.create_job(template, env_vars, input_vars, credentials)).to have_attributes(
        :type    => "ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Job",
        :options => {
          :template_id        => template.id,
          :env_vars           => env_vars,
          :input_vars         => input_vars,
          :credentials        => credentials,
          :poll_interval      => 60,
          :action             => ResourceAction::PROVISION,
          :terraform_stack_id => nil
        }
      )
    end

    it "create a job for Retirement action" do
      expect(
        described_class.create_job(
          template, env_vars, input_vars, credentials, :action => ResourceAction::RETIREMENT, :terraform_stack_id => terraform_stack_id
        )
      ).to have_attributes(
        :type    => "ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Job",
        :options => {
          :template_id        => template.id,
          :env_vars           => env_vars,
          :input_vars         => input_vars,
          :credentials        => credentials,
          :poll_interval      => 60,
          :action             => ResourceAction::RETIREMENT,
          :terraform_stack_id => terraform_stack_id
        }
      )
    end
  end

  describe "#signal" do
    %w[start pre_execute execute poll_runner post_execute finish abort_job cancel error].each do |signal|
      shared_examples_for "allows #{signal} signal" do
        it signal.to_s do
          expect(job).to receive(signal.to_sym)
          job.signal(signal.to_sym)
        end
      end
    end

    %w[start pre_execute execute poll_runner post_execute finish abort_job cancel error].each do |signal|
      shared_examples_for "doesn't allow #{signal} signal" do
        it signal.to_s do
          expect { job.signal(signal.to_sym) }.to raise_error(RuntimeError, /#{signal} is not permitted at state #{job.state}/)
        end
      end
    end

    context "waiting_to_start" do
      let(:state) { "waiting_to_start" }

      it_behaves_like "allows start signal"
      it_behaves_like "doesn't allow pre_execute signal"
      it_behaves_like "doesn't allow execute signal"
      it_behaves_like "doesn't allow poll_runner signal"
      it_behaves_like "doesn't allow post_execute signal"
      it_behaves_like "allows finish signal"
      it_behaves_like "allows abort_job signal"
      it_behaves_like "allows cancel signal"
      it_behaves_like "allows error signal"
    end

    context "pre_execute" do
      let(:state) { "pre_execute" }

      it_behaves_like "doesn't allow start signal"
      it_behaves_like "allows pre_execute signal"
      it_behaves_like "doesn't allow execute signal"
      it_behaves_like "doesn't allow poll_runner signal"
      it_behaves_like "doesn't allow post_execute signal"
      it_behaves_like "allows finish signal"
      it_behaves_like "allows abort_job signal"
      it_behaves_like "allows cancel signal"
      it_behaves_like "allows error signal"
    end

    context "running" do
      let(:state) { "running" }

      it_behaves_like "doesn't allow start signal"
      it_behaves_like "doesn't allow pre_execute signal"
      it_behaves_like "doesn't allow execute signal"
      it_behaves_like "allows poll_runner signal"
      it_behaves_like "allows post_execute signal"
      it_behaves_like "allows finish signal"
      it_behaves_like "allows abort_job signal"
      it_behaves_like "allows cancel signal"
      it_behaves_like "allows error signal"
    end

    context "post_execute" do
      let(:state) { "post_execute" }

      it_behaves_like "doesn't allow start signal"
      it_behaves_like "doesn't allow pre_execute signal"
      it_behaves_like "doesn't allow execute signal"
      it_behaves_like "doesn't allow poll_runner signal"
      it_behaves_like "doesn't allow post_execute signal"
      it_behaves_like "allows finish signal"
      it_behaves_like "allows abort_job signal"
      it_behaves_like "allows cancel signal"
      it_behaves_like "allows error signal"
    end

    context "finished" do
      let(:state) { "finished" }

      it_behaves_like "doesn't allow start signal"
      it_behaves_like "doesn't allow pre_execute signal"
      it_behaves_like "doesn't allow execute signal"
      it_behaves_like "doesn't allow poll_runner signal"
      it_behaves_like "doesn't allow post_execute signal"
      it_behaves_like "allows finish signal"
      it_behaves_like "allows abort_job signal"
      it_behaves_like "allows cancel signal"
      it_behaves_like "allows error signal"
    end
  end

  describe "#start" do
    it "moves to state pre_execute" do
      job.signal(:start)
      expect(job.reload.state).to eq("pre_execute")
    end
  end

  describe "#poll_runner" do
    let(:state) { "running" }

    context "still running" do
      before { expect(job).to receive(:running?).and_return(true) }

      it "requeues poll_runner" do
        job.signal(:poll_runner)
        expect(job.reload.state).to eq("running")
      end
    end

    context "completed" do
      before { expect(job).to receive(:running?).and_return(false) }

      it "moves to state finished" do
        job.signal(:poll_runner)
        expect(job.reload.state).to eq("finished")
      end
    end
  end
end
