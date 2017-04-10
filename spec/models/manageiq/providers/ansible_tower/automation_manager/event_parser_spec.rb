describe ManageIQ::Providers::AnsibleTower::AutomationManager::EventParser do
  let(:tower_url) { ENV['TOWER_URL'] || "https://dev-ansible-tower3.example.com/api/v1/" }
  let(:auth_userid) { ENV['TOWER_USER'] || 'testuser' }
  let(:auth_password) { ENV['TOWER_PASSWORD'] || 'secret' }

  let(:auth)                    { FactoryGirl.create(:authentication, :userid => auth_userid, :password => auth_password) }
  let(:automation_manager)      { provider.automation_manager }
  let(:expected_counterpart_vm) { FactoryGirl.create(:vm, :uid_ems => "4233080d-7467-de61-76c9-c8307b6e4830") }
  let(:provider) do
    _guid, _server, zone = EvmSpecHelper.create_guid_miq_server_zone
    FactoryGirl.create(:provider_ansible_tower,
                       :zone       => zone,
                       :url        => tower_url,
                       :verify_ssl => false,).tap { |provider| provider.authentications << auth }
  end

  # {
  #   "user"=>#<Set: {"create", "update", "delete"}>,
  #   "schedule"=>#<Set: {"update"}>,
  #   "organization"=>#<Set: {"associate", "create"}>,
  #   "project"=>#<Set: {"associate", "create", "update", "delete"}>,
  #   "credential"=>#<Set: {"associate", "create", "update", "delete"}>,
  #   "inventory"=>#<Set: {"create", "delete", "update"}>,
  #   "host"=>#<Set: {"create", "delete", "update"}>,
  #   "job_template"=>#<Set: {"associate", "create", "update", "delete", "disassociate"}>,
  #   "tower_settings"=>#<Set: {"create", "update"}>,
  #   "group"=>#<Set: {"create", "associate", "delete", "update"}>,
  #   "inventory_source"=>#<Set: {"update"}>,
  #   "job"=>#<Set: {"create", "delete", "update"}>,
  #   "label"=>#<Set: {"create", "delete"}>}
  context ".event_to_hash" do
    it "fetches all events" do
      VCR.use_cassette(described_class.name.underscore) do
        map = {}
        automation_manager.connect.api.activity_stream.all.each do |activity|
          map[activity.object1] ||= Set.new
          map[activity.object1] << activity.operation
          if activity.object1 == 'host'
            ap activity.operation
            ap activity.summary_fields.host.count
            ap activity.summary_fields.host.first.id
            # exit
          end
        end
        # p map
      end

    end

    # it "with a compute.instance.create.end event" do
    #   event = YAML.load_file(File.join(data_dir, 'compute_instance_create_end.yml'))
    #   data = described_class.event_to_hash(event, 123)
    #
    #   expected_attributes = common_attributes(event).merge(
    #     :event_type   => "compute.instance.create.end",
    #     :chain_id     => "r-otxomvqw",
    #     :timestamp    => "2015-05-12 07:24:39.462895",
    #     :host_ems_ref => "cdab9a8d-d653-4dee-81f9-173f9a22bd2e",
    #     :message      => "Success"
    #   )
    #
    #   expect(data).to have_attributes(expected_attributes)
    #
    #   expect(data[:full_data]).to    be_instance_of Hash
    #   expect(data[:host_ems_ref]).to be_instance_of String
    # end
    #
    # it "with a compute.instance.create.error event" do
    #   event = YAML.load_file(File.join(data_dir, 'compute_instance_create_error.yml'))
    #   data = described_class.event_to_hash(event, 123)
    #
    #   expected_attributes = common_attributes(event).merge(
    #     :event_type   => "compute.instance.create.error",
    #     :chain_id     => "r-36dfs67z",
    #     :timestamp    => "2015-05-12 07:22:19.122336",
    #     :host_ems_ref => "b94ebb7a-34f2-4146-94c3-5bbc46b4d5ff",
    #     :message      => "Failed to provision instance 3a0c66d5-d762-4b60-b604-850bc9a13cff: Failed to deploy. Error:" \
    #                      " Failed to execute command via SSH: LC_ALL=C /usr/bin/virsh --connect qemu:///system start"\
    #                      " baremetal_2."
    #   )
    #
    #   expect(data).to have_attributes(expected_attributes)
    #
    #   expect(data[:full_data]).to    be_instance_of Hash
    #   expect(data[:host_ems_ref]).to be_instance_of String
    # end
    #
    # it "with an orchestration.stack.create.end event" do
    #   event = YAML.load_file(File.join(data_dir, 'orchestration_stack_create_end.yml'))
    #   data = described_class.event_to_hash(event, 123)
    #
    #   expected_attributes = common_attributes(event).merge(
    #     :event_type => "orchestration.stack.create.end",
    #     :timestamp  => "2015-05-12 07:24:45.026776"
    #   )
    #
    #   expect(data).to have_attributes(expected_attributes)
    #
    #   expect(data[:full_data]).to be_instance_of Hash
    # end
    #
    # it "with an orchestration.stack.update.end event" do
    #   event = YAML.load_file(File.join(data_dir, 'orchestration_stack_update_end.yml'))
    #   data = described_class.event_to_hash(event, 123)
    #
    #   expected_attributes = common_attributes(event).merge(
    #     :event_type => "orchestration.stack.update.end",
    #     :timestamp  => "2015-05-12 07:33:57.772136"
    #   )
    #
    #   expect(data).to have_attributes(expected_attributes)
    #
    #   expect(data[:full_data]).to be_instance_of Hash
    # end
    #
    # it "with a port.create.end event" do
    #   event = YAML.load_file(File.join(data_dir, 'port_create_end.yml'))
    #   data = described_class.event_to_hash(event, 123)
    #
    #   expected_attributes = common_attributes(event).merge(
    #     :event_type => "port.create.end",
    #     :timestamp  => "2015-05-12 07:22:37.008738"
    #   )
    #
    #   expect(data).to have_attributes(expected_attributes)
    #
    #   expect(data[:full_data]).to be_instance_of Hash
    # end
    #
    # it "with a port.update.end event" do
    #   event = YAML.load_file(File.join(data_dir, 'port_update_end.yml'))
    #   data = described_class.event_to_hash(event, 123)
    #
    #   expected_attributes = common_attributes(event).merge(
    #     :event_type => "port.update.end",
    #     :timestamp  => "2015-05-12 07:22:43.948145"
    #   )
    #
    #   expect(data).to have_attributes(expected_attributes)
    #
    #   expect(data[:full_data]).to be_instance_of Hash
    # end
  end

  def data_dir
    File.expand_path(File.join(File.dirname(__FILE__), "event_parser_data"))
  end

  def common_attributes(event)
    {
      :event_type   => "compute.instance.create.error",
      :chain_id     => nil,
      :is_task      => nil,
      :source       => "OPENSTACK",
      :message      => nil,
      :timestamp    => nil,
      :full_data    => event,
      :ems_id       => 123,
      :username     => nil,
      :vm_ems_ref   => nil,
      :vm_name      => nil,
      :vm_location  => nil,
      :host_ems_ref => nil,
      :host_name    => nil,
    }
  end
end
