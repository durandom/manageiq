module ManageIQ::Providers
  class BaseManager < ExtManagementSystem
    require_nested :Refresher

    include Inflector::Methods

    # belongs_to :parent_manager, :class_name => 'ManageIQ::Providers::BaseManager'

    def self.metrics_collector_queue_name
      self::MetricsCollectorWorker.default_queue_name
    end

    def metrics_collector_queue_name
      self.class.metrics_collector_queue_name
    end

    def ext_management_system
      self
    end

    def refresher
      self.class::Refresher
    end

    def http_proxy_uri
      VMDB::Util.http_proxy_uri(emstype.try(:to_sym)) || VMDB::Util.http_proxy_uri
    end
  end
end
