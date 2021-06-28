require 'spec_helper'

describe 'bind::default' do
  context 'on unspecified platform (EL 5/6 as reference)' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        platform: 'centos', version: '7', step_into: %w(
          bind_service bind_config bind_acl
        )
      ).converge(described_recipe)
    end

    it 'uses bind_acl resource' do
      expect(chef_run).to create_bind_acl('trusted-nets')
    end

    %w(bind bind-utils bind-libs).each do |bind_package|
      it "installs package #{bind_package}" do
        expect(chef_run).to install_package(bind_package)
      end
    end

    it 'creates /var/named with mode 750 and owner named' do
      expect(chef_run).to create_directory('/var/named').with(
        mode: '0750',
        user: 'named'
      )
    end

    it 'creates /etc/named with mode 750 and owner named' do
      expect(chef_run).to create_directory('/etc/named').with(
        mode: '0750',
        user: 'named'
      )
    end

    it 'renders file /etc/named/named.options' do
      expect(chef_run).to render_file('/etc/named/named.options')
    end

    it 'renders file /etc/named/named.rfc1912.zones' do
      expect(chef_run).to create_cookbook_file('/etc/named/named.rfc1912.zones')
    end

    it 'renders file /etc/named.conf with included files' do
      expect(chef_run).to render_file('/etc/named.conf').with_content(%r{include "/etc/named/named.options"})
      expect(chef_run).to render_file('/etc/named.conf').with_content(%r{include "/etc/named/named.rfc1912.zones"})
    end

    %w(named.empty named.loopback named.localhost named.ca).each do |var_file|
      it "it creates cookbook file /var/named/#{var_file}" do
        expect(chef_run).to create_cookbook_file("/var/named/#{var_file}")
      end
    end

    %w(data primary secondary).each do |subdir|
      it "creates subdirectory /var/named/#{subdir}" do
        expect(chef_run).to create_directory("/var/named/#{subdir}")
      end
    end

    it 'notifies bind service' do
      config_template = chef_run.template('/etc/named/named.options')
      expect(config_template).to notify('bind_service[default]').to(:restart)
    end
  end

  context 'on virtual guest for any platform' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'redhat', version: '6') do |node|
        node.automatic['virtualization']['role'] = 'guest'
      end.converge(described_recipe)
    end
  end

  context 'on Ubuntu 18.04' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(
        platform: 'ubuntu', version: '18.04', step_into: %w(
          bind_service bind_config bind_acl
        )
      ).converge(described_recipe)
    end
    %w(bind9 bind9utils).each do |bind_package|
      it "installs package #{bind_package}" do
        expect(chef_run).to install_package(bind_package)
      end
    end

    it 'creates /var/cache/bind with mode 750 and owner bind' do
      expect(chef_run).to create_directory('/var/cache/bind').with(
        mode: '0750',
        user: 'bind'
      )
    end

    it 'creates /etc/bind with mode 750 and owner bind' do
      expect(chef_run).to create_directory('/etc/bind').with(
        mode: '0750',
        user: 'bind'
      )
    end

    it 'renders file /etc/bind/named.options' do
      expect(chef_run).to render_file('/etc/bind/named.options')
    end

    it 'renders file /etc/bind/named.rfc1912.zones' do
      expect(chef_run).to create_cookbook_file('/etc/bind/named.rfc1912.zones')
    end

    it 'renders file /etc/bind/named.conf with included files' do
      expect(chef_run).to render_file('/etc/bind/named.conf').with_content(%r{include "/etc/bind/named.options"})
      expect(chef_run).to render_file('/etc/bind/named.conf').with_content(%r{include "/etc/bind/named.rfc1912.zones"})
    end

    %w(named.empty named.loopback named.localhost named.ca).each do |var_file|
      it "it creates cookbook file /var/cache/bind/#{var_file}" do
        expect(chef_run).to create_cookbook_file("/var/cache/bind/#{var_file}")
      end
    end

    %w(data primary secondary).each do |subdir|
      it "creates subdirectory /var/cache/bind/#{subdir}" do
        expect(chef_run).to create_directory("/var/cache/bind/#{subdir}")
      end
    end

    it 'notifies service[bind]' do
      config_template = chef_run.template('/etc/bind/named.options')
      expect(config_template).to notify('bind_service[default]').to(:restart)
    end
  end
end
