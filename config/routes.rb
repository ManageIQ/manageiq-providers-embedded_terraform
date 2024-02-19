Rails.application.routes.draw do
  {
    :embedded_terraform_workflow => {
      :get  => %i[map_credentials download_data download_summary_pdf show show_list tagging_edit],
      :post => %i[report_data search_clear button show_list tagging_edit]
    },
    :embedded_terraform_repository => {
      :get  => %i[download_data download_summary_pdf edit new show show_list tagging_edit],
      :post => %i[report_data button edit new repository_refresh show_list tagging_edit]
    },
    :embedded_terraform_credential => {
      :get  => %i[download_data download_summary_pdf edit new show show_list tagging_edit],
      :post => %i[report_data search_clear button show_list tagging_edit]
    }
  }.each do |controller_name, controller_actions|
    get controller_name.to_s, :controller => controller_name, :action => :index

    controller_actions[:get]&.each do |action_name|
      get "#{controller_name}/#{action_name}(/:id)", :action => action_name, :controller => controller_name
    end

    controller_actions[:post]&.each do |action_name|
      post "#{controller_name}/#{action_name}(/:id)", :action => action_name, :controller => controller_name
    end
  end
end
