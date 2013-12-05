require 'spec_helper'


describe 'foreman::config::passenger' do
  let :default_facts do
    {
      :concat_basedir           => '/tmp',
      :interfaces               => 'lo',
      :ipaddress_lo             => '127.0.0.1',
      :postgres_default_version => '8.4',
    }
  end

  context 'on redhat' do
    let :facts do
      default_facts.merge({
        :operatingsystem => 'RedHat',
        :osfamily        => 'RedHat',
      })
    end

    describe 'without parameters' do
      let :pre_condition do
        "class {'foreman':}"
      end

      it do
        should include_class('apache::ssl')
        should include_class('passenger')
        should_not include_class('::passenger::install::scl')

        should contain_file('foreman_vhost').with({
          :path    => '/etc/httpd/conf.d/foreman.conf',
          :mode    => '0644',
          :notify  => 'Class[Foreman::Service]',
          :require => 'Class[Foreman::Install]',
        })

        should contain_file('foreman_vhost').with_content(/<VirtualHost \*:80>/)

        should contain_file('foreman_vhost').with_content(/<VirtualHost \*:443>/)

        should contain_file('foreman_vhost').with_content(/access plus 1 year/)

        should contain_file('/usr/share/foreman/config.ru').with({
          :owner   => 'foreman',
          :require => 'Class[Foreman::Install]',
        })

        should contain_file('/usr/share/foreman/config/environment.rb').with({
          :owner   => 'foreman',
          :require => 'Class[Foreman::Install]',
        })
      end
    end

    describe 'with listen_interface' do
      let :pre_condition do
        "class {'foreman':
          passenger_interface => 'lo',
        }"
      end

      it 'should contain the HTTP vhost' do
        should contain_file('foreman_vhost').with({
          :content => /<VirtualHost 127.0.0.1:80>/,
        })
      end

      it 'should contain the HTTPS vhost' do
        should contain_file('foreman_vhost').with({
          :content => /<VirtualHost 127.0.0.1:443>/,
        })
      end
    end

    describe 'with scl_prefix' do
      let :pre_condition do
        "class {'foreman':
          passenger_scl => 'ruby193',
        }"
      end

      it 'should include scl' do
        should include_class('passenger::install::scl')
      end
    end

    describe 'without ssl' do
      let :pre_condition do
        "class {'foreman':
          ssl => false,
        }"
      end

      it 'should contain the HTTP vhost' do
        should contain_file('foreman_vhost').with_content(/<VirtualHost \*:80>/)
      end

      it 'should not contain the HTTPS vhost' do
        should_not contain_file('foreman_vhost').with_content(/<VirtualHost \*:443>/)
      end
    end
  end
end
