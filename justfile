migrate name="create migration":
    @test -f build/sqlite_migrator/bundle/bin/sqlite_migrator || just migrate-build
    ./build/sqlite_migrator/bundle/bin/sqlite_migrator "{{name}}"
    
migrate-dev name="create migration":
    dart run sqlite_migrator/sqlite_migrator.dart "{{name}}"

migrate-build:
    dart build cli -t sqlite_migrator/sqlite_migrator.dart -o build/sqlite_migrator
