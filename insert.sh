#!/bin/bash

psql -U postgres SIPXCONFIG << EOF
INSERT INTO location (location_id, name, fqdn, ip_address, password, primary_location, registered, use_stun, stun_address, stun_interval, public_address, public_port, start_rtp_port, stop_rtp_port, branch_id, public_tls_port, state, last_attempt, call_traffic, replicate_config, region_id) VALUES (2, 'Secondary', 'uc2.mihai.local', '10.3.0.151', 'GwGh1111', false, false,false, 'stun.ezuce.com', 60, NULL, 5060, 30000, 31000,NULL, 5061, 'UNINITIALIZED','2016-06-22 21:05:36.552', true, true, NULL);
INSERT INTO location (location_id, name, fqdn, ip_address, password, primary_location, registered, use_stun, stun_address, stun_interval, public_address, public_port, start_rtp_port, stop_rtp_port, branch_id, public_tls_port, state, last_attempt, call_traffic, replicate_config, region_id) VALUES (3, 'Tertiary', 'uc3.mihai.local', '10.3.0.152', 'GwGh1111', false, false,false, 'stun.ezuce.com', 60, NULL, 5060, 30000, 31000,NULL, 5061, 'UNINITIALIZED','2016-06-22 21:05:36.552', true, true, NULL);

EOF

