debenstack:
    folders:
        backups: /repos/debenstack-backups
        dockerconf: ./dockerconf
        generated: ./generated
        lib: /repos/debenstack-lib
        debenstack: /repos/debenstack
    # Specifies which configs below to setup
    mainconfig:
        names:
            - wiki
            - personalblog
            - techblog
            - profile
            - traccar
            - photoblog
            - adventurewiki
        maintenance: maintenance
    subconfig:
        maintenance:
            generated: maintenance
            username: maintenance_user
            serialiser: MaintenanceSerialiser
            defaults: maintenance
        wiki:
            database: mediawiki
            dbtype: mysql
            username: mediawiki_user
            backups: wiki
            generated: wiki
            restoremethod: docker
            #restoremethod: local
            serialiser: WikiSerialiser
            defaults: wiki
        adventurewiki:
            database: adventurewiki
            dbtype: mysql # needs to switch to postgres for optimisations. but need backups in postgres as well
            username: adventurewiki_user
            backups: adventurewiki
            generated: adventurewiki
            restoremethod: docker
            serialiser: AdventureWikiSerialiser
            defaults: adventurewiki
        personalblog:
            database: ghost_personalblog
            dbtype: mysql
            username: ghost_pb_user
            backups: personalblog
            generated: personalblog
            restoremethod: local
            serialiser: PersonalBlogSerialiser
            defaults: personalblog
        techblog:
            database: ghost_techblog
            dbtype: mysql
            username: ghost_tb_user
            backups: techblog
            generated: techblog
            restoremethod: local
            serialiser: TechBlogSerialiser
            defaults: techblog
        photoblog:
            database: ghost_photoblog
            dbtype: mysql
            username: ghost_photoblog_user
            backups: photoblog
            generated: photoblog
            restoremethod: local
            serialiser: PhotoBlogSerialiser
            defaults: photoblog
        profile:
            database: profile_website
            dbtype: mysql
            username: profile_user
            backups: profile
            generated: profile
            restoremethod: local
            serialiser: ProfileSerialiser
            defaults: profile
        traccar:
            database: traccar
            dbtype: mysql
            username: traccar_user
            backups: traccar
            generated: traccar
            restoremethod: local
            serialiser: TraccarSerialiser
            defaults: traccar
          
    