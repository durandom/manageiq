describe ManageIQ::Providers::AnsibleTower::AutomationManager::Refresher do
  VCR.configure do |c|
    c.after_http_request do |request, response|
      if request.method == :post
        puts "POST Request:#{request.uri}"
        puts "#{request.to_hash}" # or request.body
      end
    end
    # c.allow_http_connections_when_no_cassette = true
  end
  # ManageIQ::Providers::AnsibleTower::Inventory::Persister::ConfigurationScriptSource
  it_behaves_like 'refresh configuration_script_source',
                  :provider_ansible_tower,
                  described_class.parent,
                  :ansible_tower_automation,
                  described_class.name.underscore + '_configuration_script_source'
end
