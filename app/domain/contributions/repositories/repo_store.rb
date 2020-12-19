# frozen_string_literal: true

module CodePraise
  module Repository
    # Collection of all local git repo clones
    class RepoStore
      def self.all
        Dir.glob(App.config.REPOSTORE_PATH + '/*')
      end

      def self.wipe
        all.each { |dir| FileUtils.rm_r(dir) }
      end
    end
  end
end
