require 'json'

include_recipe "global_search::default"

hosts = get_role_member_hostnames 'common'

file "/tmp/hosts" do
  content hosts.to_json
end
