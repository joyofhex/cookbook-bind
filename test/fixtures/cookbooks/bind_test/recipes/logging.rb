bind_service 'default' do
  action [:create, :start]
end

bind_config 'default' do
  default_view 'internal'
end

bind_primary_zone 'example.com'

bind_primary_zone_template 'internal-sub.example.com' do
  zone_name 'sub.example.com'
  records [
    { owner: 'www', type: 'A', ttl: 100, rdata: '10.2.1.1' },
    { type: 'MX', rdata: '20 mx2.example.com.' },
    { type: 'MX', rdata: '10 mx1.example.com.' },
    { type: 'NS', rdata: 'ns1.example.com.' },
    { type: 'NS', rdata: 'ns0.example.com.' },
    { type: 'NS', rdata: 'ns3.example.com.' },
    { type: 'A', rdata: '10.0.0.1' },
    { type: 'TXT', rdata: 'internal' },
  ]

  soa serial: '5'
end

bind_logging_channel 'query-log' do
  destination 'file'
  path '/tmp/query.log'
  severity 'debug 3'
end

bind_logging_category 'queries' do
  channels 'query-log'
end

bind_logging_channel 'general-log' do
  destination 'file'
  path '/tmp/general.log'
  severity 'info'
end

bind_logging_category 'client' do
  channels 'general-log'
end

bind_logging_category 'default' do
  channels 'general-log'
end
