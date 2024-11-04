FactoryBot.define do
  factory :embedded_terraform_job,
          :parent => :job,
          :class  => "ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Job" do
    options { {} }
    state   { "waiting_to_start" }
  end
end
