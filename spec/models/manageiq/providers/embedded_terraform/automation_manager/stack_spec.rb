RSpec.describe ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Stack do
  describe "#raw_status" do
    let(:stack) { FactoryBot.create(:terraform_stack, :miq_task => miq_task) }

    context "with a running deployment" do
      let(:miq_task) { FactoryBot.create(:miq_task, :state => "Running", :status => "Ok", :message => "process initiated") }

      it "returns a status that is running" do
        expect(stack.raw_status.completed?).to be_falsey
      end
    end

    context "with a successful deployment" do
      let(:miq_task) { FactoryBot.create(:miq_task, :state => "Finished", :status => "Ok", :message => "Task completed successfully") }

      it "returns a status that is completed" do
        expect(stack.raw_status.completed?).to be_truthy
      end
    end

    context "with a failed deployment" do
      let(:miq_task) { FactoryBot.create(:miq_task, :state => "Finished", :status => "Error", :message => "Failed to run template") }

      it "returns a status that is failed" do
        expect(stack.raw_status.failed?).to be_truthy
      end

      it "returns a normalized_status with a reason" do
        expect(stack.raw_status.normalized_status).to eq(["failed", "Failed to run template"])
      end
    end
  end
end
