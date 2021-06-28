unified_mode true

require 'digest'

PrimaryZone = Struct.new(:name, :options, :view, :file_name)

property :bind_config, String, default: 'default'

property :soa, Hash, default: {}
property :records, Array, default: []
property :default_ttl, [String, Integer], default: 86400
property :options, Array, default: []
property :view, String
property :file_name, String, name_property: true
property :zone_name, String

property :template_cookbook, String, default: 'bind'
property :template_name, String, default: 'primary_zone.erb'

property :manage_serial, [true, false], default: false

action :create do
  bind_config = with_run_context :root do
    find_resource!(:bind_config, new_resource.bind_config)
  end

  new_resource.view = bind_config.default_view unless new_resource.view
  new_resource.zone_name = new_resource.file_name unless new_resource.zone_name

  bind_service = with_run_context :root do
    find_resource!(:bind_service, bind_config.bind_service)
  end

  # Assume records with no owner field are those belonging to the zone.
  # Split them out so that we can render them at the top of the zone.
  records, zone_records = new_resource.records.partition do |r|
    r.key?(:owner) && !r[:owner].nil? && !r[:owner].empty?
  end

  sorted_zone_records = zone_records.sort_by { |record| [record[:type], record[:rdata]] }
  sorted_records = records.sort_by { |record| [record[:owner], record[:type], record[:rdata]] }

  soa = {
    serial: '1',
    mname: 'localhost.',
    rname: 'hostmaster.localhost.',
    refresh: '1w',
    retry: '15m',
    expire: '52w',
    minimum: 30,
  }.merge(new_resource.soa)

  if new_resource.manage_serial
    new_hash = Digest::SHA256.hexdigest(
      Marshal.dump(
        [soa, new_resource.default_ttl, sorted_zone_records, sorted_records]
      )
    )

    persisted_values = node.normal['bind']['zone'][new_resource.file_name]

    # override soa with the value in persisted_values if it exists
    soa[:serial] = persisted_values['serial'] if persisted_values.attribute?('serial')

    unless persisted_values['hash'] == new_hash
      soa[:serial] = soa[:serial].succ if persisted_values.attribute?('serial')

      node.default['bind']['zone'][new_resource.name].tap do |zone|
        zone['serial'] = soa[:serial]
        zone['hash'] = new_hash
      end
    end
  end

  template new_resource.name do
    path "#{bind_service.vardir}/primary/db.#{new_resource.file_name}"
    owner bind_service.run_user
    group bind_service.run_group
    cookbook new_resource.template_cookbook
    source new_resource.template_name
    variables(
      default_ttl: new_resource.default_ttl,
      soa: soa,
      zone_records: sorted_zone_records,
      records: sorted_records
    )
    mode '0440'
    action :create
    notifies :restart, "bind_service[#{bind_service.name}]", :delayed
  end

  bind_config_template = with_run_context :root do
    find_resource!(:template, bind_config.conf_file)
  end

  bind_config_template.variables[:primary_zones] << PrimaryZone.new(
    new_resource.zone_name,
    new_resource.options,
    new_resource.view,
    new_resource.file_name
  )
end
