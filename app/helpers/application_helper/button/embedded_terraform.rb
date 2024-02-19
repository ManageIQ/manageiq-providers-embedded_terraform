class ApplicationHelper::Button::EmbeddedTerraform < ApplicationHelper::Button::Basic
  def disabled?
    if Rbac.filtered(ManageIQ::Providers::EmbeddedTerraform::AutomationManager.all).empty?
      @error_message = _("User isn't allowed to use the Embedded Terraform provider.")
    end
  end
end
