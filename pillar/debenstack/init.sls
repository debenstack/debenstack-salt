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
        maintenance: maintenance
    subconfig:
        maintenance:
            generated: maintenance
            username: maintenance_user
            serialiser: MaintenanceSerialiser
            defaults: maintenance
        wiki:
            database: mediawiki
            username: mediawiki_user
            backups: wiki
            generated: wiki
            restoremethod: docker
            serialiser: WikiSerialiser
            defaults: wiki
        personalblog:
            database: ghost_personalblog
            username: ghost_pb_user
            backups: personalblog
            generated: personalblog
            restoremethod: local
            serialiser: PersonalBlogSerialiser
            defaults: personalblog
        techblog:
            database: ghost_techblog
            username: ghost_tb_user
            backups: techblog
            generated: techblog
            restoremethod: local
            serialiser: TechBlogSerialiser
            defaults: techblog
        photoblog:
            database: ghost_photoblog
            username: ghost_photoblog_user
            backups: photoblog
            generated: photoblog
            restoremethod: local
            serialiser: PhotoBlogSerialiser
            defaults: photoblog
        profile:
            database: profile_website
            username: profile_user
            backups: profile
            generated: profile
            restoremethod: local
            serialiser: ProfileSerialiser
            defaults: profile
        traccar:
            database: traccar
            username: traccar_user
            backups: traccar
            generated: traccar
            restoremethod: local
            serialiser: TraccarSerialiser
            defaults: traccar
          
    