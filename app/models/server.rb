class Server < ActiveRecord::Base
  belongs_to :deploy, :class_name => 'AddOn::Deploy'

  validates :fqdn, :uniqueness => true, :presence => true, :fqdn_format => true
  validates :ip_address, :ip_format => true, :presence => true

  validates :classes, :classes => true

  before_save :set_unicorn_workers
  after_create :queue_sync
  before_destroy :queue_remove

  def has_class?(klass)
    return false if self.classes.nil?
    self.classes.split(",").include? klass
  end


  def display_classes
    self.classes.split(',').map do |klass|
      case klass
        when 'appserver'; then 'Application Server'
        when 'loadbalancer'; then 'Load Balancer'
        when 'dbserver'; then 'Database Server'
        when 'utilserver'; then 'Utility Server'
      end
    end.join ', '
  end

  def company
    self.order.company if self.order.present?
  end

  private
    def queue_sync
      return if self.deploy.nil? || !self.deploy.valid? || self.deploy.config_state == 'new' || self.digest.present? 

      Delayed::Job.enqueue(DelayedDeploymentSync.new(self.deploy.id))
    end

    def queue_remove
      return if self.digest.nil? 

      Delayed::Job.enqueue(DelayedDeploymentRemove.new(self.fqdn, self.digest))
    end

    #only app servers get unicorns
    def set_unicorn_workers
      return if self.has_class?('appserver')

      self.number_unicorn_workers = 0
    end
end
