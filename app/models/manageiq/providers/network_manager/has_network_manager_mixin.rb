module ManageIQ::Providers::NetworkManager::HasNetworkManagerMixin
  extend ActiveSupport::Concern

  included do
    provider_namespace = ManageIQ::Providers::Inflector::provider_module(self)

    has_one :network_manager,
            :foreign_key => :parent_ems_id,
            # :class_name  => "#{provider_namespace}::NetworkManager",
            :autosave    => true,
            :inverse_of  => :parent_manager,
            :dependent   => :destroy

    has_many :cloud_networks,  :through => :network_manager
    has_many :cloud_subnets,   :through => :network_manager
    has_many :floating_ips,    :through => :network_manager
    has_many :network_ports,   :through => :network_manager
    has_many :network_routers, :through => :network_manager
    has_many :public_networks, :through => :network_manager
    has_many :security_groups, :through => :network_manager
    has_many :security_groups, :through => :network_manager

    alias_method :all_cloud_networks, :cloud_networks

    before_create :add_network_manager

    def add_network_manager
      unless network_manager
        build_network_manager(:name            => "#{name} Network Manager",
                              :zone_id         => zone_id,
                              :provider_region => provider_region)
      end
    end
  end
end
