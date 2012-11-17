class ConfigurationValidator < ActiveModel::Validator
  def validate(record)
    if record.deploy_demo && record.spree_version.demo_git_url.nil?
      record.errors[:base] << 'No sample store is available for selected Spree version'
    end

    return if record.config_state == 'new'

    all_classes = record.servers.map(&:classes).map{ |c| c.split(',') }.flatten

    if all_classes.count('appserver') == 0
      record.errors[:base] << 'You must add at least one server with the role of "Application Server".'
    end

    if all_classes.count('dbserver') == 0
      record.errors[:base] << 'You must add one server with the role of "Database Server".'
    end

    if all_classes.count('dbserver') > 1
      record.errors[:base] << 'You must have only one server with the role of "Database Server".'
    end

    if all_classes.count('loadbalancer') > 1
      record.errors[:base] << 'You must have only one server with the role of "Load Balancer".'
    end

    if all_classes.count('loadbalancer') == 1 && all_classes.count('appserver') < 2
      record.errors[:base] << 'You must have two or more servers with the role of "Application Server" when using the "Load Balancer" role.'
    end
  end
end
