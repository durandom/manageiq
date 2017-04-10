module ManageIQ::Providers::AnsibleTower::Shared::Inventory::Parser::ConfigurationScriptSource
  def parse
    configuration_script_sources
    credentials
  end

  def configuration_script_sources
    collector.projects.each do |project|
      inventory_object = persister.configuration_script_sources.find_or_build(project.id.to_s)
      inventory_object.description = project.description
      inventory_object.name = project.name
      # checking project.credential due to https://github.com/ansible/ansible_tower_client_ruby/issues/68
      inventory_object.authentication = persister.credentials.lazy_find(project.credential_id.to_s) if project.credential
      inventory_object.scm_type = project.scm_type
      inventory_object.scm_url = project.scm_url
      inventory_object.scm_branch = project.scm_branch
      inventory_object.scm_clean = project.scm_clean
      inventory_object.scm_delete_on_update = project.scm_delete_on_update
      inventory_object.scm_update_on_launch = project.scm_update_on_launch

      project.playbooks.each do |playbook_name|
        inventory_object_playbook = persister.configuration_script_payloads.find_or_build_by(
          :configuration_script_source => inventory_object,
          :manager_ref                 => playbook_name
        )
        inventory_object_playbook.name = playbook_name
      end
    end
  end

  def credentials
    collector.credentials.each do |credential|
      inventory_object = persister.credentials.find_or_build(credential.id.to_s)
      inventory_object.name = credential.name
      inventory_object.userid = credential.username
      provider_module = ManageIQ::Providers::Inflector.provider_module(collector.manager.class).name
      inventory_object.type = case credential.kind
                                when 'net' then "#{provider_module}::AutomationManager::NetworkCredential"
                                when 'ssh' then "#{provider_module}::AutomationManager::MachineCredential"
                                when 'vmware' then "#{provider_module}::AutomationManager::VmwareCredential"
                                when 'scm' then "#{provider_module}::AutomationManager::ScmCredential"
                                when 'aws' then "#{provider_module}::AutomationManager::AmazonCredential"
                                when 'rax' then "#{provider_module}::AutomationManager::RackspaceCredential"
                                when 'satellite6' then "#{provider_module}::AutomationManager::Satellite6Credential"
                                # when 'cloudforms' then "#{provider_module}::AutomationManager::$$$Credential"
                                when 'gce' then "#{provider_module}::AutomationManager::GoogleCredential"
                                # when 'azure' then "#{provider_module}::AutomationManager::???Credential"
                                when 'azure_rm' then "#{provider_module}::AutomationManager::AzureCredential"
                                when 'openstack' then "#{provider_module}::AutomationManager::OpenstackCredential"
                                else "#{provider_module}::AutomationManager::Credential"
                                end
      inventory_object.options = inventory_object.type.constantize::EXTRA_ATTRIBUTES.keys.each_with_object({}) do |k, h|
        h[k] = credential.public_send(k)
      end
    end
  end
end
