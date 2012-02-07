A master copy of the unmapped_reason table is now kept in the production
database.

The production database is kept on the ens-staging1 server and is called
"ensembl_production".

The master table for the unmapped_reason table is called
"master_unmapped_reason" and should be copied to any new Core or
Core-like database into the unmapped_reason table (as in: rename it).

For new entries, please insert them into this master table (after
notifying the current release coordinator).


For the release coordinator:

In misc-scripts/production_database/scripts lives a script called
"push_master_tables.pl".  This script is used to synchronise all master
tables over all Core and Core-like databases on all staging servers.

Please run that script with its "--about" and "--help" command line
switches for more information.


$Id: README-production_db.txt,v 1.2 2011/12/08 14:56:21 mh6 Exp $
