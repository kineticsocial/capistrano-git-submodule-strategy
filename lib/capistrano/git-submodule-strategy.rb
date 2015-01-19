require 'capistrano/git'

class Capistrano::Git
  module SubmoduleStrategy
    # do all the things a normal capistrano git session would do
    include Capistrano::Git::DefaultStrategy

    def test
      test! " [ -f #{repo_path}/HEAD ] "
    end

    def check
      unless test!(:git, :'ls-remote', repo_url)
        context.error "Repo `#{repo_url}` does not exists"
        return false
      end
      
      # Regular Expression Match
      match = "\/refs\/(heads|tags)\/#{fetch(:branch)}"
      if context.capture(:git, :'ls-remote', repo_url).split("\n").any?{ |i| !i.match(/#{match}/).nil?}
        context.error "Branch `#{fetch(:branch)}` not found in repo `#{repo_url}`"
        return false
      end

      true
    end

    def clone
      git :clone, '--mirror', repo_url, repo_path
    end

    def update
      git :remote, :update
    end

    # put the working tree in a release-branch,
    # make sure the submodules are up-to-date
    # and copy everything to the release path
    def release
      unless context.test(:test, '-e', release_path) && context.test("ls -A #{release_path} | read linevar")
        git :clone, '--depth=1', '--recursive', '-b', fetch(:branch), "file://#{repo_path}", release_path
        unless fetch(:git_keep_meta, false)
          context.execute("find #{release_path} -name '.git*' -printf '\"%p\"" + '\n' + "' | xargs -I {} rm -rfv {}")
        end
      end
    end
  end
end
