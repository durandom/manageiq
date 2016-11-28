class ManageIQ::Providers::InfraNetworkManager < ManageIQ::Providers::NetworkManager
  belongs_to :parent_manager,
             :foreign_key => :parent_ems_id,
             :class_name  => "ManageIQ::Providers::InfraManager",
             :inverse_of  => :network_manager,
             :autosave    => true
  # declared on ext_management_system
  has_many :hosts, :through => :parent_manager
  has_many :vms,   :through => :parent_manager

  # declared on infra_manager
  has_many :direct_orchestration_stacks,    :through => :parent_manager
  has_many :orchestration_stacks,           :through => :parent_manager
  has_many :orchestration_stacks_resources, :through => :parent_manager

  # delegated to parent manager because they are virtual_attributes
  delegate :total_vms, :to => :parent_manager
end
