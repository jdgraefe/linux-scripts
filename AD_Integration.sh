#/bin/bash

rpm -q systemd && yum install chrony sssd samba-common-tools krb5-workstation || yum install ntp sssd samba-common krb5-workstation

currentTimestamp=`date +%y-%m-%d-%H:%M:%S`
prefix='/etc'

echo "Configure krb5"
krbConfFile="$prefix/krb5.conf"
krbConfFileBackup=$krbConfFile.$currentTimestamp.bak
if [ -f "$krbConfFile" ]; then
    echo backup $krbConfFile to $krbConfFileBackup
    cp $krbConfFile $krbConfFileBackup
fi

cat > "$krbConfFile" << EOF
[logging]
default = FILE:/var/log/krb5libs.log
kdc = FILE:/var/log/krb5kdc.log
admin_server = FILE:/var/log/kadmind.log

[libdefaults]
default_realm = adserver.example.com
dns_lookup_realm = true
dns_lookup_kdc = true
ticket_lifetime = 24h
renew_lifetime = 7d
forwardable = true

[realms]
adserver.example.com = {
}

[domain_realm]
.adserver.example.com = adserver.example.com
adserver.example.com = adserver.example.com

EOF

echo "Synchronize the time"

echo server server1.adserver.example.com iburst >>/etc/chrony.conf
systemctl enable chronyd
systemctl restart chronyd


echo "Configure smb"
smbConfFile="$prefix/samba/smb.conf"
smbConfFileBackup=$smbConfFile.$currentTimestamp.bak
if [ -f "$smbConfFile" ]; then
    echo backup $smbConfFile to $smbConfFileBackup
    cp $smbConfFile $smbConfFileBackup
fi
cat > "$smbConfFile" << EOF
[global]
    workgroup = adserver
    client signing = yes
    client use spnego = yes
    kerberos method = secrets and keytab
    log file = /var/log/samba/%m.log
    realm = adserver.example.com
    security = ads

EOF

kinit joe

echo "Join the domain."
net ads join -k -S server1.adserver.example.com

if [ $? -eq 0 ]; then
    echo "Enable sssd within NSS and PAM"
    authconfig --savebackup /tmp/authconfig_backup
    authconfig --enablesssd --enablesssdauth --enablelocauthorize --enablemkhomedir --update

    echo "Configure sssd.conf."

    sssdConfFile="$prefix/sssd/sssd.conf"
    sssdConfFileBackup=$sssdConfFile.$currentTimestamp.bak
    if [ -f "$sssdConfFile" ]; then
        echo backup $sssdConfFile to $sssdConfFileBackup
        cp $sssdConfFile $sssdConfFileBackup
    fi

    echo >$prefix/sssd/sssd.conf
    chmod 600 $prefix/sssd/sssd.conf

    cat > "$sssdConfFile" << EOF
[domain/adserver.example.com]
id_provider = ad
access_provider = ad
default_shell=/bin/bash
fallback_homedir=/home/%u
debug_level = 0

[sssd]
services = nss, pam
config_file_version = 2
domains = adserver.example.com

[nss]

[pam]

EOF
    echo "Restart SSSD"
    rpm -q systemd && systemctl restart sssd || service sssd restart
else
    echo "---------------------------------------------------"
    echo "Failed to join domain. Before running the script,"
    echo "- Ensure that /etc/resolv.conf is set to a DNS server that can resolve your AD DNS zones, and that the search domain is set to the AD DNS domain."
fi