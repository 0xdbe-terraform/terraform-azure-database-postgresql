SET aad_validate_oids_in_tenant = off;
CREATE ROLE :"group" WITH LOGIN IN ROLE azure_ad_user;