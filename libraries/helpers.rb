module BindCookbook
  module Helpers
    def default_property_for(property_name, chroot)
      if platform_family?('debian')
        debian_property_for(property_name, chroot)
      else
        rhel_property_for(property_name, chroot)
      end
    end

    def debian_property_for(property_name, chroot)
      {
        chroot_dir: chroot ? '/var/bind9/chroot' : nil,
        sysconfdir: chroot ? '/var/bind9/chroot/etc/bind' : '/etc/bind',
        vardir: chroot ? '/var/bind9/chroot/var/cache/bind' : '/var/cache/bind',
        dynamicdir: chroot ? '/var/bind9/chroot/var/cache/bind/dynamic' : '/var/cache/bind/dynamic',
        packages: %w(bind9 bind9-host bind9utils),
        run_user: 'bind',
        run_group: 'bind',
        options_file: chroot ? '/var/bind9/chroot/etc/bind/named.options' : '/etc/bind/named.options',
        conf_file: chroot ? '/var/bind9/chroot/etc/bind/named.conf' : '/etc/bind/named.conf',
        service_name: 'bind9',
        rndc_key_file: chroot ? '/var/bind9/chroot/etc/bind/rndc.key' : '/etc/bind/rndc.key',
        session_keyfile: chroot ? '/var/run/named/session.key' : nil,
        pid_file: chroot ? '/var/run/named/named.pid' : nil,
      }[property_name]
    end

    def rhel_property_for(property_name, chroot)
      {
        chroot_dir: chroot ? '/var/named/chroot' : nil,
        sysconfdir: '/etc/named',
        vardir: '/var/named',
        dynamicdir: '/var/named/dynamic',
        packages: chroot ? %w(bind-chroot bind-utils bind-libs) : %w(bind bind-utils bind-libs),
        run_user: 'named',
        run_group: 'named',
        options_file: '/etc/named/named.options',
        conf_file: '/etc/named.conf',
        service_name: chroot && (platform?('fedora') || node['platform_version'] >= '7.0') ? 'named-chroot' : 'named',
        rndc_key_file: '/etc/rndc.key',
      }[property_name]
    end
  end
end
