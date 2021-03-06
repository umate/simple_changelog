module SimpleChangelog
  class Repository
    def initialize(path = Rails.root)
      @repo = Grit::Repo.new path
      @tags = @repo.tags
      @commits = @repo.commits
    end

    def load_history
      history = {}

      if @tags.any? || @commits.any?
        middle_tags = convert_tags(@tags).sort_by { |t| t.date }
        tags = [tail_tag] + middle_tags
        tags << head_tag if has_head_commits?(middle_tags)
        tags.reverse!
        tags.each_cons(2) do |prev, succ|
          history[prev] = commits_between(succ, prev).sort_by { |c| c.message }
        end
      end

      history
    end

    def current_version_tag
      if @tags.empty?
        @commits.empty? ? '' : 'HEAD'
      else
        last_tag = @tags.sort_by { |t| t.tag_date }.last
        last_tag.name
      end
    end

    private

    def has_head_commits?(middle_tags)
      commit = @repo.commits('master', 1).first
      middle_tags.none? { |t| t.commit_id == commit.id }
    end

    def head_tag
      commit = @repo.commits('master', 1).first
      Tag.new('HEAD', commit.date, commit.id)
    end

    def tail_tag
      commit = @repo.commits('master', 1, @repo.commit_count - 1).first
      Tag.new('TAIL', commit.date, commit.id)
    end

    def commits_between(from, to)
      commits = @repo.commits_between(from.commit_id, to.commit_id)
      convert_commits(commits)
    end

    def convert_commits(commits)
      commits.map { |c| Commit.new(c.short_message, c.date, c.id) }
    end

    def convert_tags(tags)
      tags.map { |t| Tag.new(t.name, t.tag_date, t.commit.id) }
    end
  end
end