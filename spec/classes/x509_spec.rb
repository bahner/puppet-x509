# frozen_string_literal: true

require 'spec_helper'

describe 'x509' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'cns'  => ['snakeoil.example.com'],
          'keys' => { 'snakeoil.example.com' => 'snakeoil' },
          'certs' => { 'snakeoil.example.com' => 'snakeoil' },
        }
      end

      it { is_expected.to compile }
      it { is_expected.to compile.with_all_deps }
      it {
        is_expected.to contain_file('x509_certs_snakeoil.example.com').with(
          ensure: 'present',
          mode: '0444',
          content: 'snakeoil',
          path: '/etc/x509/certs/snakeoil.example.com.crt',
        )
      }
      it {
        is_expected.to contain_file('x509_keys_snakeoil.example.com').with(
          ensure: 'present',
          group: 'x509',
          mode: '0440',
          content: 'snakeoil',
          path: '/etc/x509/keys/snakeoil.example.com.key',
        )
      }
      it {
        is_expected.to contain_package('x509_ca-certificates').with(
          ensure: 'present',
          name: 'ca-certificates',
        )
      }

      case os_facts[:osfamily]
      when 'Debian'
        it do
          is_expected.to contain_file('x509_shared_ca_certificates_folder').with(
            ensure: 'directory',
            path: '/usr/local/share/ca-certificates',
          )
          is_expected.to contain_file('x509_shared_ca_trust_certificates_folder').with(
            path: '/usr/local/share/ca-certificates/trusted',
          )
          is_expected.to contain_exec('x509_update-ca-certificates').with(
            command: '/usr/bin/update-ca-certificates',
          )
        end
      when 'RedHat'
        it do
          is_expected.to contain_file('x509_shared_ca_certificates_folder').with(
            ensure: 'directory',
            path: '/etc/pki/ca-trust/source/anchors',
          )
          is_expected.to contain_file('x509_shared_ca_trust_certificates_folder').with(
            path: '/etc/pki/ca-trust/source/',
          )
          is_expected.to contain_exec('x509_update-ca-certificates').with(
            command: '/usr/bin/update-ca-trust',
          )
        end
      end
    end
  end
end
