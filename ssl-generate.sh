#!/bin/bash

clear

echo "You are currently logged in as $USER"
echo "Please update authentication credentials"
sudo -v

# Get domain that SSL cert will be protecting
echo "What is the FQDN of the site you wish to encrypt?"
read fqdn

# Organization name
echo "What is the organization name?"
read organization

# Contact email, mostly admin@<domain>
echo "What is the contact email for this cert?"
read email

# State org is located in
echo "State?"
read state

# Country org is located in
echo "Country?"
read country

# City org is located in
echo "City?"
read city

echo "Generating..."

# Output to a tmp cfg file
sudo echo " [ req ]
prompt = no
default_bits = 4096
default_keyfile = $fqdn.key
encrypt_key = no
distinguished_name = req_distinguished_name

string_mask = utf8only

req_extensions = v3_req

[ req_distinguished_name ]
O=$organization
L=$city
ST=$state
C=$country
CN=$fqdn

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment" >> temp-openssl.cfg

# Runs OpenSSL command to generate new csr and key for cert
sudo openssl req -new -config temp-openssl.cfg -out $fqdn.csr

# Removes tmp file
sudo rm temp-openssl.cfg

echo "Done. The CSR name is: $fqdn.csr"
echo "The key name is: $fqdn.key"
echo "All have been encrypted with 4096-bit encryption"

