module AddOn
  class DeploysController < ApplicationController
    before_filter :authenticate_user!
    before_filter :load_and_authorize_store!, :except => :index

    def index
      @store = Store.find(params[:store_id])
      authorize! :admin, @store
    end

    def new
      @deploy = Deploy.new
    end

    def create
      @deploy = @store.deploys.new(params[:add_on_deploy])
      if @deploy.save
        redirect_to edit_add_on_deploy_path(@deploy), :notice => 'Deployment was succssfully created.'
      else
        render :action => "new"
      end
    end

    def update
      if @deploy.update_attributes(params[:add_on_deploy])
        redirect_to edit_add_on_deploy_path(@deploy), :notice => 'Deployment was succssfully updated.'
      else
        render :action => "edit"
      end
    end

    def edit
    end

    def destroy
      if @deploy.destroy
        redirect_to add_on_deploys_path(:store_id => @store), :notice => 'Deployment was successfully deleted.'
      else
        redirect_to add_on_deploys_path(:store_id => @store), :error => 'Failed to delete deployment.'
      end
    end

    def capistrano
      if @deploy.valid?
        @app_servers = []

        @deploy.servers.each do |server|
          if server.classes.include? "appserver"
            @app_servers << server.ip_address
          end

          if server.classes.include? "utilserver"
            @app_servers << server.ip_address
          end

          if server.classes.include? "dbserver"
            @db_server = server.ip_address
          end
        end

        @app_servers.uniq!

        zero_seventy = SpreeVersion.where(:name => '0.70.x').first
        @compile_assets = @deploy.spree_version.position >= zero_seventy.position

        render :layout => false 
      else
        render :text => "Cannot generate Capistrano script as deployment configuration is invalid.", :layout => false
      end
    end

    private

    def load_and_authorize_store!
      if params[:store_id]
        @store = Store.find(params[:store_id])
      elsif params[:id]
        @deploy = Deploy.find(params[:id])
        @store = @deploy.store
      end

      @deployable_versions =  SpreeVersion.where("position >= ? ", SpreeVersion.where(:name => '0.60.x').first.position).order('position desc')

      authorize! :admin, @store
    end

  end
end
