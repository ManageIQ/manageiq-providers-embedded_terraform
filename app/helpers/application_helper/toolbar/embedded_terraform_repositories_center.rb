class ApplicationHelper::Toolbar::EmbeddedTerraformRepositoriesCenter < ApplicationHelper::Toolbar::Basic
  button_group('embedded_terraform_repositories_reloading',
               [
                 button(
                   :embedded_terraform_repositories_reload,
                   'fa fa-refresh fa-lg',
                   N_('Refresh this page'),
                   N_(''),
                   :url_parms    => "main_div",
                   :send_checked => true,
                   :klass        => ApplicationHelper::Button::ButtonWithoutRbacCheck
                 ),
               ])
  button_group('embedded_terraform_repositories',
               [
                 select(
                   :embedded_terraform_repositories_configuration,
                   nil,
                   t = N_('Configuration'),
                   t,
                   :items => [
                     button(
                       :embedded_configuration_script_source_refresh,
                       'fa fa-refresh fa-lg',
                       N_('Refresh Selected Terraform Repositories'),
                       N_('Refresh Selected Terraform Repositories'),
                       :klass        => ApplicationHelper::Button::EmbeddedTerraform,
                       :url          => "repository_refresh",
                       :confirm      => N_("Refresh selected Terraform Repositories?"),
                       :enabled      => false,
                       :url_parms    => 'unused_div',
                       :send_checked => true,
                       :onwhen       => "1+"
                     ),
                     separator,
                     button(
                       :embedded_configuration_script_source_add,
                       'pficon pficon-add-circle-o fa-lg',
                       t = N_('Add New Repository'),
                       t,
                       :klass        => ApplicationHelper::Button::EmbeddedTerraform,
                       :url_parms    => "unused_div",
                       :send_checked => true
                     ),
                     button(
                       :embedded_configuration_script_source_edit,
                       'pficon pficon-edit fa-lg',
                       t = N_('Edit this Repository'),
                       t,
                       :klass        => ApplicationHelper::Button::EmbeddedTerraform,
                       :enabled      => false,
                       :onwhen       => "1",
                       :url_parms    => "unused_div",
                       :send_checked => true
                     ),
                     button(
                       :embedded_configuration_script_source_delete,
                       'pficon pficon-delete fa-lg',
                       t = N_('Remove selected Repositories from Inventory'),
                       t,
                       :klass        => ApplicationHelper::Button::EmbeddedTerraform,
                       :send_checked => true,
                       :enabled      => false,
                       :onwhen       => "1+",
                       :data         => {'function'      => 'sendDataWithRx',
                                         'function-data' => {:controller     => 'provider_dialogs',
                                                             :modal_title    => N_('Delete Repositories'),
                                                             :modal_text     => N_('Are you sure you want to delete the following repositories?'),
                                                             :api_url        => 'configuration_script_sources',
                                                             :async_delete   => true,
                                                             :redirect_url   => '/embedded_terraform_repository/show_list',
                                                             :component_name => 'RemoveGenericItemModal'}}
                     ),
                   ]
                 )
               ])
  button_group('embedded_terraform_repositories_policy',
               [
                 select(
                   :ansible_repositories_policy_choice,
                   nil,
                   t = N_('Policy'),
                   t,
                   :enabled => false,
                   :onwhen  => "1+",
                   :items   =>
                               [
                                 button(
                                   :ansible_repository_tag,
                                   'pficon pficon-edit fa-lg',
                                   N_('Edit Tags for the selected Terraform Repositories'),
                                   N_('Edit Tags'),
                                   :url_parms    => "main_div",
                                   :send_checked => true,
                                   :enabled      => false,
                                   :onwhen       => "1+"
                                 ),
                               ]
                 )
               ])
end
