module ManageIQ::Providers::AnsibleTower::Shared::Inventory::Collector::ConfigurationScriptSource
  def connection
    @connection ||= manager.connect
  end

  def projects
    [
        connection.api.projects.find(target.manager_ref)
    ]
  end

  def credentials
    connection.api.credentials.all
  end
end
