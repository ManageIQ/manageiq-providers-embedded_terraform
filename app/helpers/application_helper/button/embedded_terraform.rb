class ApplicationHelper::Button::EmbeddedTerraform < ApplicationHelper::Button::Basic
  def disabled?
    if !MiqRegion.my_region.role_active?('embedded_terraform')
      @error_message = _("Embedded Terraform Role is not enabled.")
    elsif Rbac.filtered(ManageIQ::Providers::EmbeddedTerraform::AutomationManager.all).empty?
      @error_message = _("User isn't allowed to use the Embedded Terraform provider.")
    end
    @error_message.present?
  end
end
