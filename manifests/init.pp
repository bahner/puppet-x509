# Class to easily add intermediate CA's and
# (wildcard) certificates in a safe way.
#
# Requires correspondence between names.
# _ for wildcard names is suggest, eg:
#     _.google.com
#
# The certs installed in the correct trust bundles
# by using required packages.
#
# will be integrated in the systems trusted CA's
# They will also be integrated into the keystore, but
# you might want to manually import the key into the keystore
#
# @example
# The $keys array should be stored in hiera and encrypted
# with eyaml. That's the proper way to do it. Anything else
# is not likely secure. But YMMV.
# Storing the private keys eyaml encrypted is fairly safe.
#
# class x509 {
#   $cns => [
#     '_.google.com',
#     '_.google.co.uk',
#   ]
#   $keys => [
#     { name: _.google.com,
#       data: >
#         ----- BEGIN PRIVATE KEY ----
#         pem encoded key
#         ----- END PRIVATE KEY ----
#     },
#     { name: _.google.co.uk,
#       data: >
#         ----- BEGIN PRIVATE KEY ----
#         pem encoded key
#         ----- END PRIVATE KEY ----
#     }
#   ]
# }
#
# @param ca_certificates_package_name
#   The name of the package that contains folders and binaries
#   needed to update system trusted certificates and
#   certificate authorities.
# @param shared_ca_certificates_folder
#   The folder to normally place trusted certificate authorities
#   and - more importantly - trusted intermediary certificate
#   authorities.
# @param shared_ca_trust_certificates_folder
#   The shared_ca_trust_certificates_folder is a RedHat
#   thing. It distinguishes between normal ca certificates
#   and trusted ca certificates. This is not about being more or
#   less trusted, but trusted certificates have rules embedded
#   as to what they can be used as.
#   So they need to be treated differently.
# @param update_ca_certficates_binary
#   The binary to run to update the systems trust by adding
#   the new certificates.
# @param group_name
#   The name of the group that is allowed to read private keys.
#   When you have several applications that need to read the
#   private key, eg. apache, tomcat, redis, in order to provide
#   secure communication.
# @params cns
#   List of the common names, actually the list of filenames
#   to instantiate on this system, but the common names
#   should be used. Use "_" for wildcards. It's very readable.
#   The common names will be used to find keys to instantiate
#   on this system, by finding an entry in the x509::keys that
#   have a matching name.
class x509 (

  String                $ca_certificates_package_name,
  String                $group_name,
  Stdlib::Absolutepath  $shared_ca_certificates_folder,
  Stdlib::Absolutepath  $shared_ca_trust_certificates_folder,
  Stdlib::Absolutepath  $update_ca_certficates_binary,
  Array[String]         $cns    = [],
  Hash                  $keys   = {},
  Hash                  $certs  = {},

) {

  $hostcert = lookup('pki::host::cert')
  $hostkey = lookup('pki::host::key')

  group {
    'x509':
      ensure     => present,
      name       => $group_name,
      forcelocal => true,
      system     => true,
  }

  File {
    owner   => root,
    group   => $group_name,
    mode    => '0755',
    require => [
      Group['x509'],
      Package['x509_ca-certificates']
    ],
    notify  => Exec['x509_update-ca-certificates'],
  }

  Package {
    'x509_ca-certificates':
      ensure => present,
      name   => $ca_certificates_package_name,
    ;
  }

  file {

    '/etc/x509':
      ensure => directory;

    '/etc/x509/certs':
      ensure  => directory,
      source  => 'puppet:///modules/x509/certs',
      recurse => true,
      require => File['/etc/x509'];

    '/etc/x509/private':
      ensure  => directory,
      mode    => '0550',
      require => File['/etc/x509'];

    'x509_shared_ca_certificates_folder':
      ensure  => directory,
      path    => $shared_ca_certificates_folder,
      source  => 'puppet:///modules/x509/ca',
      recurse => 'remote',
    ;

    'x509_shared_ca_trust_certificates_folder':
      ensure  => directory,
      path    => $shared_ca_trust_certificates_folder,
      source  => 'puppet:///modules/x509/ca-trust',
      recurse => 'remote',
    ;
    'hostcert':
      ensure  => 'present',
      path    => "/etc/x509/certs/${::fqdn}.pem",
      mode    => '0664',
      require => Exec['hostcert'],
    ;
    'hostkey':
      ensure  => 'present',
      path    => "/etc/x509/private/${::fqdn}.key",
      mode    => '0660',
      require => Exec['hostkey'],
    ;
  }

  # We only want to create those that are needed.
  # If a cert is needed in cns, but doesn't exist,
  # then that's an error.
  $cns.each | String $cn | {
    $cert = $certs[$cn]
    $key = $keys[$cn]

    file {
      "x509_certs_${cn}":
        ensure  => present,
        path    => "/etc/x509/certs/${cn}.crt",
        mode    => '0444',
        content => $cert,
        require => File['/etc/x509/certs'],
      ;
      "x509_keys_${cn}":
        ensure  => present,
        path    => "/etc/x509/private/${cn}.key",
        content => $key,
        mode    => '0440',
        group   => $group_name,
        require => File['/etc/x509/private'],
      ;
    }

    concat {
      "/etc/x509/private/${cn}.pem":
        group => $group_name,
        mode  => '0440',
    }

    concat::fragment {
      "${cn}_cert":
        target => "/etc/x509/private/${cn}.pem",
        source => "/etc/x509/certs/${cn}.crt",
        order  => 10
    }

    concat::fragment {
      "${cn}_key":
        target => "/etc/x509/private/${cn}.pem",
        source => "/etc/x509/private/${cn}.key",
        order  => 20
    }
  }

  exec {
    'x509_update-ca-certificates':
      command     => $update_ca_certficates_binary,
      subscribe   => File[
        x509_shared_ca_trust_certificates_folder,
        x509_shared_ca_certificates_folder,
      ],
      refreshonly => true,
    ;
    'hostcert':
      command => "ln ${hostcert} /etc/x509/certs/",
      path    => ['/bin', '/usr/bin'],
      creates => "/etc/x509/certs/${::fqdn}.pem",
    ;
    'hostkey':
      command => "ln ${hostkey} /etc/x509/private/${::fqdn}.key",
      path    => ['/bin', '/usr/bin'],
      creates => "/etc/x509/private/${::fqdn}.key",
    ;
  }
}
