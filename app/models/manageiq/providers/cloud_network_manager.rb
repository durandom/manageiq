class ManageIQ::Providers::CloudNetworkManager < ManageIQ::Providers::NetworkManager
  belongs_to :parent_manager,
             :foreign_key => :parent_ems_id,
             :class_name  => "ManageIQ::Providers::CloudManager",
             :inverse_of  => :network_manager,
             :autosave    => true

  # declared on ext_management_system
  has_many :hosts, :through => :parent_manager
  has_many :vms,   :through => :parent_manager

  # declared on cloud_manager
  has_many :availability_zones,             :through => :parent_manager
  has_many :cloud_object_store_containers,  :through => :parent_manager
  has_many :cloud_object_store_objects,     :through => :parent_manager
  has_many :cloud_resource_quotas,          :through => :parent_manager
  has_many :cloud_tenants,                  :through => :parent_manager
  has_many :cloud_volume_snapshots,         :through => :parent_manager
  has_many :cloud_volumes,                  :through => :parent_manager
  has_many :direct_orchestration_stacks,    :through => :parent_manager
  has_many :flavors,                        :through => :parent_manager
  has_many :key_pairs,                      :through => :parent_manager
  has_many :orchestration_stacks,           :through => :parent_manager
  has_many :orchestration_stacks_resources, :through => :parent_manager

  # delegated to parent manager because they are virtual_attributes
  delegate :total_vms, :to => :parent_manager
end
