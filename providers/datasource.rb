# Support whyrun
def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.info "#{ @new_resource } already exists - nothing to do."
  else
    converge_by("Create #{ @new_resource }") do
      create_datasource
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by("Delete #{ @new_resource }") do
      delete_datasource
    end
  else
    Chef::Log.info "#{ @current_resource } doesn't exist - can't delete."
  end
end

def load_current_resource
  @current_resource = Chef::Resource::WildflyDatasource.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.jndiname(@new_resource.jndiname)
  @current_resource.drivername(@new_resource.drivername)
  @current_resource.connectionurl(@new_resource.connectionurl)
  if datasource_exists?(@current_resource.name)
    # TODO: Set @current_resource port properties from registry
    @current_resource.exists = true
  end
end

private

def datasource_exists?(name)
  Chef::Log.info "datasource_exists"
  resource = bash "check_datasource" do
    user "wildfly"
    cwd "/opt/wildfly"
    code <<-EOH
      bin/jboss-cli.sh -c ' /subsystem=datasources/data-source=#{name}:read-resource'
    EOH
    action :nothing
    returns 0
  end
  begin
    resource.run_action(:run)
    return true
  rescue
    return false
  end
end

def create_datasource
  Chef::Log.info "create_datasource"
  bash "install_datasource" do
    user "wildfly"
    cwd  "/opt/wildfly"
    code <<-EOH
      bin/jboss-cli.sh -c command="data-source add --name=#{new_resource.name} --jndi-name=#{new_resource.jndiname} --driver-name=#{new_resource.drivername} --connection-url=#{new_resource.connectionurl}"
    EOH
  end
end

def delete_datasource
  Chef::Log.info "delete_datasource"
  bash "remove_datasource" do
    user "wildfly"
    cwd  "/opt/wildfly"
    code <<-EOH
      bin/jboss-cli.sh -c command="data-source remove --name=#{new_resource.name}"
    EOH
  end
end
