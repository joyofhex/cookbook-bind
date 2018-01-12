# frozen_string_literal: true
require 'spec_helper'

describe 'adding primary zones' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos', version: '7.3.1611', step_into: %w(bind_config bind_primary_zone bind_service)
    ).converge('bind_test::spec_primary_zone')
  end

  it 'uses the custom resource' do
    expect(chef_run).to create_bind_primary_zone('example.com')
    expect(chef_run).to create_bind_primary_zone('example.org')
    expect(chef_run).to create_cookbook_file('example.org')
  end

  it 'will copy the zone file from the test cookbook' do
    expect(chef_run).to render_file('/var/named/primary/db.example.com').with_content { |content|
      expect(content).to include '$ORIGIN example.com.'
    }
  end

  it 'will place the config in the named config' do
    expect(chef_run).to render_file('/etc/named/primary.zones').with_content { |content|
      expect(content).to include 'zone "example.com" IN {'
      expect(content).to include 'file "primary/db.example.com";'
    }
  end

  it 'will add options to the zone' do
    stanza = <<~EOF
      zone "example.org" IN {
        type master;
        file "primary/db.example.org";
        allow-transfer { none; };
      };
    EOF
    expect(chef_run).to render_file('/etc/named/primary.zones').with_content { |content|
      expect(content).to include stanza
    }
  end

  it 'notifies reload bind_service[default]' do
    example_org = chef_run.cookbook_file('example.org')
    example_com = chef_run.cookbook_file('example.com')
    expect(example_org).to notify('bind_service[default]').to(:reload).delayed
    expect(example_com).to notify('bind_service[default]').to(:reload).delayed
  end
end
