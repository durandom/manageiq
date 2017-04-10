shared_examples_for "refresh configuration_script_source" do |ansible_provider, manager_class, ems_type, cassette_path|
  let(:tower_url) { ENV['TOWER_URL'] || "https://dev-ansible-tower3.example.com/api/v1/" }
  let(:auth_userid) { ENV['TOWER_USER'] || 'testuser' }
  let(:auth_password) { ENV['TOWER_PASSWORD'] || 'secret' }

  let(:auth)                    { FactoryGirl.create(:authentication, :userid => auth_userid, :password => auth_password) }
  let(:automation_manager)      { provider.automation_manager }
  let(:expected_counterpart_vm) { FactoryGirl.create(:vm, :uid_ems => "4233080d-7467-de61-76c9-c8307b6e4830") }
  let(:provider) do
    _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
    FactoryGirl.create(ansible_provider,
                       :zone       => zone,
                       :url        => tower_url,
                       :verify_ssl => false,).tap { |provider| provider.authentications << auth }
  end
  let(:manager_class) { manager_class }

  it "will perform a refresh" do
    configuration_script_source = automation_manager.configuration_script_sources.create(
        :manager_ref => 4
    )
    2.times do
      VCR.use_cassette(cassette_path) do
        EmsRefresh.refresh(configuration_script_source)
        expect(automation_manager.reload.last_refresh_error).to be_nil
      end
    end
  end

  def assert_counts
    expect(Provider.count).to                                    eq(1)
    expect(automation_manager).to                             have_attributes(:api_version => "3.0.1")
    expect(automation_manager.configured_systems.count).to    eq(84)
    expect(automation_manager.configuration_scripts.count).to eq(11)
    expect(automation_manager.inventory_groups.count).to      eq(6)
    expect(automation_manager.configuration_script_sources.count).to eq(6)
    expect(automation_manager.configuration_script_payloads.count).to eq(438)
    expect(automation_manager.credentials.count).to eq(8)
  end

  def assert_credentials
    expect(expected_configuration_script.authentications.count).to eq(3)
    machine_credential = expected_configuration_script.authentications.find_by(
      :type => manager_class::MachineCredential
    )
    expect(machine_credential).to have_attributes(
      :name   => "Demo Credential",
      :userid => "admin",
    )
    expect(machine_credential.options.keys).to match_array(machine_credential.class::EXTRA_ATTRIBUTES.keys)
    expect(machine_credential.options[:become_method]).to eq('su')
    expect(machine_credential.options[:become_username]).to eq('root')

    network_credential = expected_configuration_script.authentications.find_by(
      :type => manager_class::NetworkCredential
    )
    expect(network_credential).to have_attributes(
      :name   => "Demo Creds 2",
      :userid => "awdd",
    )
    expect(network_credential.options.keys).to match_array(network_credential.class::EXTRA_ATTRIBUTES.keys)

    cloud_credential = expected_configuration_script.authentications.find_by(
      :type => manager_class::VmwareCredential
    )
    expect(cloud_credential).to have_attributes(
      :name   => "dev-vc60",
      :userid => "MiqAnsibleUser@vsphere.local",
    )
    expect(cloud_credential.options.keys).to match_array(cloud_credential.class::EXTRA_ATTRIBUTES.keys)

    scm_credential = expected_configuration_script_source.authentication
    expect(scm_credential).to have_attributes(
      :name   => "db-github",
      :userid => "syncrou"
    )
    expect(scm_credential.options.keys).to match_array(scm_credential.class::EXTRA_ATTRIBUTES.keys)
  end

  def assert_playbooks
    expect(expected_configuration_script_source.configuration_script_payloads.first).to be_an_instance_of(manager_class::Playbook)
    expect(expected_configuration_script_source.configuration_script_payloads.count).to eq(8)
    expect(expected_configuration_script_source.configuration_script_payloads.map(&:name)).to include('start_ec2.yml')
  end

  def assert_configuration_script_sources
    expect(automation_manager.configuration_script_sources.count).to eq(6)
    expect(expected_configuration_script_source).to be_an_instance_of(manager_class::ConfigurationScriptSource)
    expect(expected_configuration_script_source).to have_attributes(
      :name                 => 'DB_Github',
      :description          => 'DB Playbooks',
      :scm_type             => 'git',
      :scm_url              => 'https://github.com/syncrou/playbooks',
      :scm_branch           => 'master',
      :scm_clean            => false,
      :scm_delete_on_update => false,
      :scm_update_on_launch => true
    )
    expect(expected_configuration_script_source.authentication.name).to eq('db-github')
  end

  def assert_configured_system
    expect(expected_configured_system).to have_attributes(
      :type                 => manager_class::ConfiguredSystem.name,
      :hostname             => "Ansible-Host",
      :manager_ref          => "3",
      :virtual_instance_ref => "4233080d-7467-de61-76c9-c8307b6e4830",
    )
    expect(expected_configured_system.counterpart).to          eq(expected_counterpart_vm)
    expect(expected_configured_system.inventory_root_group).to eq(expected_inventory_root_group)
  end

  def assert_configuration_script_with_nil_survey_spec
    expect(expected_configuration_script).to have_attributes(
      :description => "Ansible-JobTemplate-Description",
      :manager_ref => "80",
      :name        => "Ansible-JobTemplate",
      :survey_spec => {},
      :variables   => {'abc' => 123},
    )
    expect(expected_configuration_script.inventory_root_group).to have_attributes(:ems_ref => "2")
    expect(expected_configuration_script.parent.name).to eq('hello_world.yml')
    expect(expected_configuration_script.parent.configuration_script_source.manager_ref).to eq('37')
  end

  def assert_configuration_script_with_survey_spec
    system = automation_manager.configuration_scripts.where(:name => "Ansible-JobTemplate-Survey").first
    expect(system).to have_attributes(
      :name        => "Ansible-JobTemplate-Survey",
      :description => "Ansible-JobTemplate-Description",
      :manager_ref => "81",
      :variables   => {'abc' => 123}
    )
    survey = system.survey_spec
    expect(survey).to be_a Hash
    expect(survey['spec'].first['question_name']).to eq('Survey')
  end

  def assert_inventory_root_group
    expect(expected_inventory_root_group).to have_attributes(
      :name    => "Dev-VC60",
      :ems_ref => "2",
      :type    => "ManageIQ::Providers::AutomationManager::InventoryRootGroup",
    )
  end

  private

  def expected_configured_system
    @expected_configured_system ||= automation_manager.configured_systems.where(:hostname => "Ansible-Host").first
  end

  def expected_configuration_script
    @expected_configuration_script ||= automation_manager.configuration_scripts.where(:name => "Ansible-JobTemplate").first
  end

  def expected_inventory_root_group
    @expected_inventory_root_group ||= automation_manager.inventory_groups.where(:name => "Dev-VC60").first
  end

  def expected_configuration_script_source
    @expected_configuration_script_source ||= automation_manager.configuration_script_sources.find_by(:name => 'DB_Github')
  end
end
