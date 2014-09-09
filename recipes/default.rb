if (node['ec2'].nil?) then
	log("Refusing to install CloudWatch Logs because this does not appear to be an EC2 instance.") { level :warn }
	return
end

if (node.default["cwlogs"]["logfiles"].nil?) then
	log("Refusing to install CloudWatch Logs because no logs have been configured. (node.default['cwlogs']['logfiles'] is nil)") { level :warn }
	return
end



service "awslogs" do
	#awslogs service is created, enabled, and started by the installer at the end of this recipe, but we need to declare a chef resource for the template to notify
	action :nothing
end

template "/tmp/cwlogs.cfg" do
  source "cwlogs.cfg.erb"
  owner "root"
  group "root"
  mode 0644
  variables ({
  	:logfiles => node.default['cwlogs']['logfiles']
  })
  notifies :restart, "service[awslogs]"
end

directory "/opt/aws/cloudwatch" do
  recursive true
end

remote_file "/opt/aws/cloudwatch/awslogs-agent-setup.py" do
  source "https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py"
  mode "0755"
end

execute "Install CloudWatch Logs agent" do
  command "/opt/aws/cloudwatch/awslogs-agent-setup.py -n -r #{node.default['cwlogs']['region']} -c /tmp/cwlogs.cfg"
  not_if { system "pgrep -f aws-logs-agent-setup" }
end