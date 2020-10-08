# x509


## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with x509](#setup)
    * [What x509 affects](#what-x509-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with x509](#beginning-with-x509)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

The X509 loosely follows the [Debian X.509 Packaging Best Practises](https://wiki.debian.org/X.509).
It distributes CA certificates and integrates them into the systems
common trusted certificate bundle. This is useful for distributing
intermediate CA's that are commonly used these days. You can also 
distribute your own self-signed CA or puppet ca for the entire OS
to take advantage off.

It features a way to distribute server certs to be used by applications
like web servers, redis, rabbitmq or what have you. The private
keys are fetched from hiera and can therefore be encrypted with 
eyaml. This means that you can put the keys in your code without
leaking them.

So to conclude it:
  - Provides a safe way to potentially store cert/keypairs
  - Conveniently distributes self-signed or intermediary CAs

## Setup

### What x509 affects

When adding certificate authorities your systems general trust
database will be updated. This is done using the apppropriate
technique for the underlying OS.

Your private keys are pretty safely stored in /etc/x509/keys and
only root and members of the group (default: x509) can read the
contents. Add your application users to this group. For example
add _www-data_ to group _x509_ to allow apache to read the private
key in order to use a cert keypair.

### Setup requirements
In order to be able to use the module safely, your private keys
must be protected. The smartest and easiest way to do this is 
to use eyaml for hiera.

If you haven't already done this, you should first read the 
[Hiera eyaml documentation](https://githttps://github.com/voxpupuli/hiera-eyaml).

Please take this advice seriously. Your private keys are important 
to keep, well private. Learn to use eyaml sooner than later.
### Beginning with x509

X509 will read the hash x509::keys and treat the keys as names
of cn to distribute. They are just names of files, but should
correspond can be configured like this:

---
cns:
  - snakeoil.example.com

# This is unencrypted
x509::certs:
  snakeoil.example.com: >
    -----BEGIN CERTIFICATE-----
    MIIEMTCCAxmgAwIBAgIBADANBgkqhkiG9w0BAQUFADCBlTELMAkGA1UEBhMCR1Ix
    RDBCBgNVBAoTO0hlbGxlbmljIEFjYWRlbWljIGFuZCBSZXNlYXJjaCBJbnN0aXR1
    dGlvbnMgQ2VydC4gQXV0aG9yaXR5MUAwPgYDVQQDEzdIZWxsZW5pYyBBY2FkZW1p
    3zp9hctxEJBZhjiKrdhjJWnveeGqGLPtk3kIC6rrK7gGe6r2m4ZvO/DX/g+O
    8c/BZcRYpj+yrsCkgmR835q/WUmgKLgs4uacedDVJxxmpHYN0AdB4Esiw7Gq
    IMo+eRmCBzKY3FGnUX8jAlVk8dnUWraDMpr4eDcwp3bv2LHnU+hmmpBn/hdb
    zP6JBy2VHaXTzsvSmrSArZJKMeopkvmsjBeriH7CBGcnPT2JIOzIpngeUiz5
    sqVRjE4/F6wNxJKkvFLhNz/rIINzVeQHxObG1hLhLZZT+0DACOjGoPpT6K7K
    YyBhbmQgUmVzZWFyY2ggSW5zdGl0dXRpb25zIFJvb3RDQSAyMDExMB4XDTExMTIw
    NjEzNDk1MloXDTMxMTIwMTEzNDk1MlowgZUxCzAJBgNVBAYTAkdSMUQwQgYDVQQK
    dIsXRSZMFpGD/md9zU1jZ/rzAxKWeAaNsWftjj++n08C9bMJL/NMh98qy5V8Acys
    Nnq/onN694/BtZqhFLKPM58N7yLcZnuEvUUXBj08yrl3NI/K6s8/MT7jiOOASSXI
    l7WdmplNsDz4SgCbZN2fOUvRJ9e4
    -----END CERTIFICATE-----

# This is encrypted (with hiera-eyaml-gpg)
x509::keys:
  snakeoil.example.com: >
    ENC[GPG,hQIMA2J/QY05/enwAQ//Yzv++EKDK5yfqOzrJDZl6Zyj9Y356KPfVJOGwePJ
    AmbU+YW+Yf8myReweR7c0F8r73I8JSJz9GXWZpaph/cYhFp3rJvL3aHnwFOb
    mUuGdUIfEuXc+TGU0kI7MpYahBjGErNfvYfBbnxmZB8ux2vzyo2CQDAi5qBU
    bv7FYMTdFklwXK+S+cyI8kKi3Hg9Ewh9dWh46ND6wil+54Is6j6/ZR/r7CD1
    nKiQhBo9tJM8S0T3HKGOcIPNWtSuqJ3R17pDCS8IDgqBiYgM3GpFw8CiHPHW
    3zp9hctxEJBZhjiKrdhjJWnveeGqGLPtk3kIC6rrK7gGe6r2m4ZvO/DX/g+O
    8c/BZcRYpj+yrsCkgmR835q/WUmgKLgs4uacedDVJxxmpHYN0AdB4Esiw7Gq
    IMo+eRmCBzKY3FGnUX8jAlVk8dnUWraDMpr4eDcwp3bv2LHnU+hmmpBn/hdb
    zP6JBy2VHaXTzsvSmrSArZJKMeopkvmsjBeriH7CBGcnPT2JIOzIpngeUiz5
    sqVRjE4/F6wNxJKkvFLhNz/rIINzVeQHxObG1hLhLZZT+0DACOjGoPpT6K7K
    puNKNpCJnZ2Rq2C5INGRVLZP2tDxfxSDTbBTbJoC0DV/FT+hXN+OzpEhoFrg
    jzVFaN+IHWIX7P40rU/U92+x9wguqZ3AjtrdtFLkNG7o1w1JJlAwDzq6JdIi
    d4aVJ9ECd497xG7YMkAv7xUrv26qpXIqLV1pS+iRAQWYQ3jd644UeUYcERt0
    Yo9EJ7yTvIG/gtvSe4o2fSvLDvUSv7nH9S+vEKB6kZ+cee6QJd8vss/WzI92
    Tcvj/7HhItI=]




## Usage

Include usage examples for common use cases in the **Usage** section. Show your
users how to use your module to solve problems, and be sure to include code
examples. Include three to five examples of the most important or common tasks a
user can accomplish with your module. Show users how to accomplish more complex
tasks that involve different types, classes, and functions working in tandem.

## Reference

This section is deprecated. Instead, add reference information to your code as
Puppet Strings comments, and then use Strings to generate a REFERENCE.md in your
module. For details on how to add code comments and generate documentation with
Strings, see the [Puppet Strings documentation][2] and [style guide][3].

If you aren't ready to use Strings yet, manually create a REFERENCE.md in the
root of your module directory and list out each of your module's classes,
defined types, facts, functions, Puppet tasks, task plans, and resource types
and providers, along with the parameters for each.

For each element (class, defined type, function, and so on), list:

* The data type, if applicable.
* A description of what the element does.
* Valid values, if the data type doesn't make it obvious.
* Default value, if any.

For example:

```
### `pet::cat`

#### Parameters

##### `meow`

Enables vocalization in your cat. Valid options: 'string'.

Default: 'medium-loud'.
```

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other
warnings.

## Development

In the Development section, tell other users the ground rules for contributing
to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You can also add any additional sections you feel are
necessary or important to include here. Please use the `##` header.

[1]: https://puppet.com/docs/pdk/latest/pdk_generating_modules.html
[2]: https://puppet.com/docs/puppet/latest/puppet_strings.html
[3]: https://puppet.com/docs/puppet/latest/puppet_strings_style.html
