#!/usr/bin/env ruby
require 'pp'
require 'yaml'
require 'colorize'
require 'base64'

# Usage
# ./gcp-deploy teamup-retailer production - For generating production files for teamup
# ./gcp-deploy supply staging - For generating staging files for supply
#
raise 'Both project &  is required' if ARGV[0].empty? || ARGV[1].empty?

# Validate project
raise 'Only teamup-retailer or supply' unless
    ARGV[0] == 'teamup-retailer' || ARGV[0] == 'supply'

# Validate environment
raise 'Only staging or production or stress-test are allowed' unless
    ARGV[1] == 'production' || ARGV[1] == 'staging' || ARGV[1] == 'stress'


def return_gcp_project_id_for_supply(environment)
  case(environment)
  when 'production'
    return 'supply-production'.freeze
  when 'staging'
    return 'supply-staging-250020'.freeze
  when 'stress'
    return 'supply-stress-test'.freeze
  else
    raise 'Unknown environment'
  end
end

def return_gcp_project_id_for_teamup(environment)
  case(environment)
  when 'production'
    return 'teamup-production'.freeze
  when 'staging'
    return 'teamup-staging'.freeze
  else
    raise 'Unknown environment'
  end
end

# Determine GCP project ID
app_name = ARGV[0]
environment = ARGV[1]

if app_name == 'teamup-retailer'
  GCP_PROJECT_ID = return_gcp_project_id_for_teamup(environment)
elsif app_name == 'supply'
  GCP_PROJECT_ID = return_gcp_project_id_for_supply(environment)
else
  raise 'Invalid State: Unknown App Name'
end

# Create directories if they don't exist
puts "Creating directories".green
system 'mkdir', '-p', "k8s/#{environment}/#{app_name}"
system 'mkdir', '-p', "k8s/#{environment}/#{app_name}/cron_jobs"

if app_name == 'teamup-retailer'
  SECRET_OBJECT = 'teamup-credentials'.freeze
elsif app_name == 'supply'
  SECRET_OBJECT = 'supply-credentials'.freeze
end

# system("gcloud config set project #{GCP_PROJECT_ID}")
# system("gcloud config set compute/zone #{GCP_ZONE_ID}")

class ::Hash
  def deep_merge(second)
    merger = proc { |_key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
    self.merge(second.to_h, &merger)
  end
end

def create_pair(name:)
  var = {}
  var['name'] = name
  var['valueFrom'] = {}
  var['valueFrom']['secretKeyRef'] = {}
  var['valueFrom']['secretKeyRef']['name'] = SECRET_OBJECT
  var['valueFrom']['secretKeyRef']['key'] = name.downcase
  var
end

def clean_value(name:, value:)
  # puts "1#{name} is nil".red if value.nil?
  value.delete!("\n")
  # puts "2#{name} is nil".red if value.nil?
  value.delete!("'")
  # puts "3#{name} is nil".red if value.nil?
  # puts "#{value}".yellow
  base64 = Base64.strict_encode64(value)
  base64
end

# First Generate Secret yaml file
puts 'Generating Secrets..'.green
base_secret_hash = YAML::safe_load(File.open("./deploy/#{environment}/#{app_name}/base-secret.yaml").read)
base_secret_hash['data'] = {}
File.open("./deploy/#{environment}/#{app_name}/env.yaml").each_line do |line|
  data = line.split(': ').each(&:strip).join('|').split('|')
  key = data[0].downcase
  base_secret_hash['data']["#{key}"] = clean_value(name: key, value: data[1])
end

# Output final file
output_secret_file_name = "./k8s/#{environment}/#{app_name}/secret.yaml"
File.write(output_secret_file_name, YAML.dump(base_secret_hash))
# exit(0);

# Now generate deployment files

# Services
puts 'Generating Deployment..'.green
service_name = 'app'
service_hash = YAML::safe_load(File.open("./deploy/#{environment}/#{app_name}/base-deployment-#{service_name}.yaml").read)
env_nodes = []
File.open("./deploy/#{environment}/#{app_name}/env.yaml").each_line do |line|
  data = line.split(': ').each(&:strip).join('|').split('|')
  node = create_pair(name: data[0])
  env_nodes << node
  # puts "#{data}"
end

service_hash['spec']['template']['spec']['containers'][0]['env'] = env_nodes

file_name = "./k8s/#{environment}/#{app_name}/deployment.#{service_name}.yaml"
File.write(file_name, YAML.dump(service_hash))

# Now generate workers

puts 'Now generating sidekiq workers'.green
sidekiq_services = {
    'order_export_worker': {
        command: 'bundle exec sidekiq -q order_export,5',
        num_workers: 2
    },
    'product_import_worker': {
        command: 'bundle exec sidekiq -q product_import,5',
        num_workers: 1
    },
    'exports_worker': {
        command: 'bundle exec sidekiq -q exports,5',
        num_workers: 3
    },
    'shopify_cache_worker': {
        command: 'bundle exec sidekiq -q shopify_cache,5',
        num_workers: 5
    },
    'image_import_worker': {
        command: 'bundle exec sidekiq -q images_import,5',
        num_workers: 5
    },
    'worker': {
        command: 'bundle exec sidekiq -C config/sidekiq.yml',
        num_workers: 5
    }
}
# base_worker_hash = YAML::load(File.open("./deploy/#{environment}/base-deployment-worker.yaml").read)
sidekiq_services.each do |service_name, instruction|
  # Set Property Values
  base_worker_hash = YAML::safe_load(File.open("./deploy/#{environment}/#{app_name}/base-deployment-worker.yaml").read)
  service_name_dash_notation = service_name.to_s.tr('_', '-')
  base_worker_hash['metadata']['name'] = "#{service_name_dash_notation}-deployment"
  base_worker_hash['spec']['template']['spec']['containers'][0]['name'] = service_name_dash_notation
  base_worker_hash['spec']['template']['spec']['containers'][0]['command'] = instruction[:command].split(' ')
  base_worker_hash['spec']['template']['spec']['containers'][0]['env'] = env_nodes
  base_worker_hash['spec']['replicas'] = instruction[:num_workers]
  # Export File
  worker_file_name = "./k8s/#{environment}/#{app_name}/deployment.#{service_name_dash_notation}.yaml"
  File.write(worker_file_name, YAML.dump(base_worker_hash))
end

##########################
# Now generate Cron Jobs #
##########################
puts 'Now generating cron jobs'.green
job_services = {
    'retailer-update_order_cache': {
        command: 'rails retailer:update_order_cache[2]',
        crontab: '0 * * * *'
    },
    'retailer-update_product_cache': {
        command: 'rails retailer:update_product_cache[2]',
        crontab: '0 * * * *'
    },
    'retailer-bulk_update_retailer_inventory': {
        command: 'rails retailer:bulk_update_retailer_inventory',
        crontab: '0 * * * *'
    },
    'supplier-update_order_cache': {
        command: 'rails supplier:update_order_cache',
        crontab: '0 * * * *'
    },
    'supplier-update_product_cache': {
        command: 'rails supplier:update_product_cache[2]',
        crontab: '0 * * * *'
    },
    'supplier-download_dsco_fulfillments': {
        command: 'rake supplier:download_dsco_fulfillments',
        crontab: '0 * * * *'
    },

    'supplier-update_event_cache': {
        command: 'rails supplier:update_event_cache[2]',
        crontab: '0 * * * *'
    },
    'retailer-operational_emails':{
      command: 'rails retailer:operational_emails',
      crontab: '0 10 * * *'
    }
}

# It is important to ensure these aren't running. ALL EDI services.
production_only_services = {
    'edi-ingest_asns': {
        command: 'rails edi:ingest_asns',
        crontab: '0 * * * *'
    }
}

job_services = job_services.deep_merge(production_only_services) if environment == 'production'

# Only production - ingest_revlon_asns

job_services.each do |service_name, instruction|
  # Set Property Values
  base_worker_hash = YAML::safe_load(File.open("./deploy/#{environment}/#{app_name}/cron_jobs/base.yaml").read)
  service_name_dash_notation = service_name.to_s.tr('_', '-')
  base_worker_hash['metadata']['name'] = "#{service_name_dash_notation}-cron-job"
  base_worker_hash['spec']['jobTemplate']['spec']['template']['spec']['containers'][0]['name'] = service_name_dash_notation
  base_worker_hash['spec']['schedule'] = instruction[:crontab]
  base_worker_hash['spec']['jobTemplate']['spec']['template']['spec']['containers'][0]['args'] = instruction[:command].split(' ')
  base_worker_hash['spec']['jobTemplate']['spec']['template']['spec']['containers'][0]['env'] = env_nodes
  # Export File
  worker_file_name = "./k8s/#{environment}/#{app_name}/cron_jobs/#{service_name_dash_notation}.yaml"
  File.write(worker_file_name, YAML.dump(base_worker_hash))
end;0

# These should only be copied when setting up new clusters. Be sure to follow the steps
# outlined in Notion (or wherever docs are) when it comes to setting up new cluster.
# It is extremely important to be careful not to redeploy these YAML files once cluster is configured.

# puts 'Copying over other k8s files..'.green
# system("cp ./deploy/#{environment}/#{app_name}/base-cluster-ip-service.yaml ./k8s/#{environment}/#{app_name}/app-cluster-ip-service.yaml")
# system("cp ./deploy/#{environment}/#{app_name}/base-issuer.yaml ./k8s/#{environment}/#{app_name}/issuer.yaml")
# system("cp ./deploy/#{environment}/#{app_name}/base-certificate.yaml ./k8s/#{environment}/#{app_name}/certificate.yaml")
# system("cp ./deploy/#{environment}/#{app_name}/base-ingress.yaml ./k8s/#{environment}/#{app_name}/ingress.yaml")

puts 'Completed.'.green
