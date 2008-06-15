module SummaryHelper
  def link_to_revision(rev, repo)
    repo ? link_to(rev, repo.gsub(/\#\{rev\}/, rev.to_s)) : rev.to_s
  end
end
