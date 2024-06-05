RSpec.describe ServiceTerraformTemplate do
  let!(:service) { FactoryBot.create(:service_terraform_template).tap { |s| s.add_resource!(stack, :name => "Provision") } }
  let(:stack)    { FactoryBot.create(:terraform_stack) }

  describe "#stack" do
    it "returns the associated orchestration_stack" do
      expect(service.stack("Provision")).to eq(stack)
    end
  end

  describe "#check_completed" do
    let(:stack) { FactoryBot.create(:terraform_stack, :miq_task => miq_task) }

    context "with a running deployment" do
      let(:miq_task) { FactoryBot.create(:miq_task, :state => "Running", :status => "Ok", :message => "process initiated") }

      it "returns not done" do
        done, _message = service.check_completed("Provision")
        expect(done).to be_falsey
      end
    end

    context "with a successful deployment" do
      let(:miq_task) { FactoryBot.create(:miq_task, :state => "Finished", :status => "Ok", :message => "Task completed successfully") }

      it "returns done" do
        done, _message = service.check_completed("Provision")
        expect(done).to be_truthy
      end

      it "returns a nil message" do
        _done, message = service.check_completed("Provision")
        expect(message).to be_nil
      end
    end

    context "with a failed deployment" do
      let(:miq_task) { FactoryBot.create(:miq_task, :state => "Finished", :status => "Error", :message => "Failed to run template") }

      it "returns done" do
        done, _message = service.check_completed("Provision")
        expect(done).to be_truthy
      end

      it "returns the task message" do
        _done, message = service.check_completed("Provision")
        expect(message).to eq("Failed to run template")
      end
    end
  end
end
