
require 'json'

module GlobalSearch
  module GlobalSearch 

   def get_environment_nodes(env=node.chef_environment.downcase)
      real_endpoint = Chef::Config[:chef_server_url].to_s
      real_node_name = Chef::Config[:node_name].to_s
      real_client_key = Chef::Config[:client_key].to_s

      # Search cache per organization
      attr_key = "#{env.downcase}_chef_search_cache"

      begin
        #Point the Chef Search client at the appropriate organizations Chef server and load the correct client key
        #If we're searching outside the current organization, and we know where to search
        if env.downcase != node.chef_environment.downcase and node['global_search']['search'].has_key? env.downcase
          require 'fileutils'

          client_name = node["global_search"]["search"][env.downcase]['client_name']

          client_key_path = File.join(Chef::Config[:file_cache_path], "#{client_name}.pem")
          File.open(client_key_path, 'w') { |file| file.write(node['global_search']['search'][env.downcase]['search_key']) }

          Chef::Config[:client_key] = client_key_path
          Chef::Config[:node_name] = client_name
          Chef::Config[:verify_api_cert] = false
          Chef::Config[:ssl_verify_mode] = :verify_none
          Chef::Config[:chef_server_url] = node['global_search']['search'][env.downcase]['endpoint']
        end

        # Get nodes via search.
        unless node.run_state.has_key? attr_key
          node.run_state[attr_key] = search(:node, "*:*")
        end
      rescue StandardError => error
        Chef::Log.error("Unable to get nodes for #{env}: #{error}")
      ensure
        # Reset the Chef client config back to the original values
        Chef::Config[:chef_server_url] = real_endpoint
        Chef::Config[:node_name] = real_node_name
        Chef::Config[:client_key] = real_client_key

        # Return the nodes.
        return node.run_state[attr_key] rescue []
      end
    end

    # @param [String] role the role for which we want a sorted list of members
    # @return [Array] sorted list of node objects in the current environment which belong to the searched role
    def get_role_member_list( role, env=node.chef_environment.downcase )
        nodes = get_environment_nodes(env.downcase)
        if !nodes
          return []
        end
        nodes.select { |n| n.role? role }
    end

    # @param [String] role the role for which we want a sorted list of members
    # @return [Array] sorted list of node names in the current environment which belong to the searched role
    def get_role_member_hostnames(role, env=node.chef_environment.downcase)
      get_role_member_list( role, env ).map { |n| n.hostname }
    end
    # @param [String] role the role for which we want a sorted list of members
    # @return [Array] sorted list of node names in the current environment which belong to the searched role
    def get_role_member_ips(role, env=node.chef_environment.downcase)
      get_role_member_list( role, env ).map { |n| n.ipaddress }
    end

    # @param [String] role the role for which we want a sorted list of members
    # @return [Array] sorted list of node names in the current environment which belong to the searched role
    def get_role_member_fqdns(role, env=node.chef_environment.downcase)
      get_role_member_list( role, env ).map { |n| n.fqdn }
    end

  end
end
