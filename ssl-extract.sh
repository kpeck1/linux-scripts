#!/bin/bash

clear

echo "You are currently logged in as $USER"
echo "Please update authentication credentials"
sudo -v

# Asks for certname of PKCS12 cert
echo "What is the cert name?"
read certname

# Site name for SSL certificate
echo "What is the site name?"
read site

# .pfx encryption passphrase
echo "What is the .pfx passphrase?"
read -s passphrase

# OpenSSL commands to extract cert and key
sudo openssl pkcs12 -in $certname.pfx -nocerts -out $site.key -nodes -password pass:$passphrase
sudo openssl pkcs12 -in $certname.pfx -nokeys -out $site.crt -password pass:$passphrase
sudo openssl rsa -in $site.key -out $site.key

echo "Done!"
echo "The cert is $site.crt"
echo "The key is $site.key"
