# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_temp_session',
  :secret      => 'b832cc50231a858804612da82ec9ad193a477a35025f2a20d4140f1ab604299bea7f2ce552bc70f0d55a576e9602e144e701f404397ac86e82ab3399db187b46'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
