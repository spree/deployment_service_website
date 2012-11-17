class DelayedDeploymentSync < Struct.new(:add_on_deploy_id)
  include HTTParty
  base_uri "http://puppet.spreecommerce.com:5000"

  def perform

    deploy = AddOn::Deploy.find(add_on_deploy_id)

    AddOn::Deploy.where(:id => deploy.id).update_all(:config_state => 'connecting')#prevents after_update

    deploy.servers.each do |server|
      next if server.digest.present?

      begin
        result = self.class.get('/new', :query => {:key => PUPPET_KEY, :fqdn => server.fqdn}, :timeout => 300)
      rescue Exception => e
        AddOn::Deploy.where(:id => deploy.id).update_all(:config_state => 'exception')#prevents after_update
        raise e
      end

      if result.key? 'success'
        server.update_attribute(:digest, result['success'])
      else
        AddOn::Deploy.where(:id => deploy.id).update_all(:config_state => 'error')#prevents after_update
        raise "Error in response from API"
      end
    end

    AddOn::Deploy.where(:id => deploy.id).update_all(:config_state => 'complete')#prevents after_update

  end
end
