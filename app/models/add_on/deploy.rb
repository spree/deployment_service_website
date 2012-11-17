module AddOn
  class Deploy < ActiveRecord::Base
    def self.table_name_prefix
      'add_on_'
    end

    after_update :queue_sync

    belongs_to :store
    belongs_to :spree_version

    has_many :servers, :class_name => "::Server", :dependent => :destroy

    validates_with ConfigurationValidator

    private
      def queue_sync
        return if !self.valid? || self.config_state == 'new' || self.servers.all? { |s| s.digest.present? }

        Delayed::Job.enqueue(DelayedDeploymentSync.new(self.id))
      end
  end
end
