# Re-create private key file

'-----BEGIN RSA PRIVATE KEY-----' > 'id_rsa'
$SSH_DEPLOY_KEY >> 'id_rsa'
'-----END RSA PRIVATE KEY-----' >> 'id_rsa'

scp -B -v -r -i ./id_rsa _rendered $REMOTE_DEPLOY_LOCATION

Remote-Item 'id_rsa'