require "gemstash"

module Gemstash
  # Class that supports unyanking a gem from the private repository of gems.
  class GemUnyanker
    include Gemstash::Env::Helper

    # This error is thrown when unyanking a non-existing gem name.
    class UnknownGemError < StandardError
    end

    # This error is thrown when unyanking a non-existing gem version.
    class UnknownVersionError < StandardError
    end

    # This error is thrown when unyanking a non-yanked gem version.
    class NotYankedVersionError < StandardError
    end

    def initialize(auth_key, gem_name, slug)
      @auth_key = auth_key
      @gem_name = gem_name
      @slug = slug
    end

    def unyank
      check_auth
      update_database
      invalidate_cache
    end

  private

    def storage
      @storage ||= Gemstash::Storage.for("private").for("gems")
    end

    def full_name
      @full_name ||= "#{@gem_name}-#{@slug}"
    end

    def check_auth
      Gemstash::Authorization.check(@auth_key, "unyank")
    end

    def update_database
      gemstash_env.db.transaction do
        raise UnknownGemError, "Cannot unyank an unknown gem!" unless Gemstash::DB::Rubygem[name: @gem_name]
        version = Gemstash::DB::Version.find_by_full_name(full_name)
        raise UnknownVersionError, "Cannot unyank an unknown version!" unless version
        raise NotYankedVersionError, "Cannot unyank a non-yanked version!" if version.indexed
        version.reindex
        storage.resource(version.storage_id).update_properties(indexed: true)
      end
    end

    def invalidate_cache
      gemstash_env.cache.invalidate_gem("private", @gem_name)
    end
  end
end
