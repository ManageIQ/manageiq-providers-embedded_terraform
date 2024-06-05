FactoryBot.define do
  factory :terraform_stack,
          :class  => "ManageIQ::Providers::EmbeddedTerraform::AutomationManager::Stack",
          :parent => :orchestration_stack
end
