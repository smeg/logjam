require File.dirname(__FILE__) + '/../test_helper'

class RunTest < Test::Unit::TestCase
  fixtures :runs

  # Replace this with your real tests.
  def test_normal_create
    run = Run.new(
      :project   => 'A Team Van 2.0', 
      :build     => "postgres",
      :started   => Time.now,
      :committer => 'murdock',
      :revision  => 2320
    )
    assert run.save, run.errors.full_messages.join("\n")
  end                   
  
  def test_create_duplicate_revision
    run = runs(:a_team_postgres).clone
    assert ! run.save, "Shouldn't be able to save a duplicate run record"
    
    run.revision += 1
    assert run.save, run.errors.full_messages.join("\n")
  end

  def test_update_existing_build
    run = Run.new(
      :project   => 'A Team Van 2.0',
      :build     => 'oracle',
      :started   => 5.minutes.ago,
      :committer => 'hannibal',
      :revision  => 2321
    )
    assert run.save, run.errors.full_messages.join("\n")
    
    run.status = 'success'
    run.finished = Time.now
    assert run.save, run.errors.full_messages.join("\n")
  end
  
  def test_find_and_update
    run = Run.new(
      :project   => 'A Team Van 2.0',
      :build     => 'oracle',
      :started   => 5.minutes.ago,
      :committer => 'hannibal',
      :revision  => 2321
    )
    assert run.save, run.errors.full_messages.join("\n")
    
    same_run = Run.find_by_project_and_build_and_revision('A Team Van 2.0', 'oracle', 2321)
    same_run.status   = 'broken'
    same_run.finished = Time.now
    assert same_run.save, same_run.errors.full_messages.join("\n")
  end         
                                                 
  def test_notify_failures
    assert_raise(RuntimeError) { Run.notify(:project => :foo, :build => :bar )}
    assert_raise(RuntimeError) { Run.notify(:project => :foo, :revision => :bar )}
    assert_raise(RuntimeError) { Run.notify(:build => :foo, :revision => :bar )}
  end
  
  def test_notify
    run = Run.notify(:project   => 'Some New Project', 
                     :build     => 'oracle', 
                     :revision  => 1,
                     :started   => 5.minutes.ago(Time.now),
                     :committer => 'rick@rickbradley.com')

    assert_equal run.project, 'Some New Project'
    assert_equal run.build, 'oracle'
    assert_equal run.revision, 1                      
    assert_equal run.committer, 'rick@rickbradley.com'
    assert_equal run.status, 'running'
    assert run.started
    assert ! run.finished
    
    finished = Run.notify(:project  => 'Some New Project',
                          :build    => 'oracle',
                          :revision => 1,
                          :status   => 'success')  
                          
    %w(project build revision committer started log).each do |meth|                     
      assert_equal run.send(meth), finished.send(meth), "run.#{meth} != finished.#{meth}"
    end                                               
    assert_equal 'success', finished.status
    assert (finished.finished - Time.now).abs < 5
  end
  
  def test_finished_summary  
    assert summary = Run.finished_summary, "Should be some Run instances in the finished summary"
    assert_equal 1, summary.length, "Should be 3 runs over 2 projects in the finished summary"

    run = summary.shift
    assert_equal "Rush 2112", run.project
    assert_equal "oracle", run.build
    assert_equal 2112, run.revision
  end
  
  def test_finished_summary_filtered
    assert summary = Run.finished_summary(:project => 'Rush 2112'), "Should be some A Team projects in summary"
    assert_equal 1, summary.length, "Should be 1 run over 1 project in the filtered summary"

    run = summary.shift
    assert_equal "Rush 2112", run.project
    assert_equal "oracle", run.build
    assert_equal 2112, run.revision

    assert summary = Run.finished_summary(:build => 'oracle'), "Should be some oracle builds in the summary"
    assert_equal 1, summary.length, "Should be 1 run over 1 project in the filtered summary"

    run = summary.shift
    assert_equal "Rush 2112", run.project
    assert_equal "oracle", run.build
    assert_equal 2112, run.revision

    assert summary = Run.finished_summary(:build => 'oracle', :project => "Rush 2112"), "Should be an oracle build for 2112 in the summary"
    assert_equal 1, summary.length, "Should be 1 run over 1 project in the filtered summary"

    run = summary.shift  
    assert_equal "Rush 2112", run.project
    assert_equal "oracle", run.build
    assert_equal 2112, run.revision    

    assert summary = Run.finished_summary(:project => "Bogus Project"), "Should return an empty summary list."
    assert_equal 0, summary.length, "Should be no runs in the filtered summary"
  end

  def test_running_summary  
    assert summary = Run.running_summary, "Should be some Run instances in the running summary"
    assert_equal 2, summary.length, "Should be 2 runs over 1 projects in the running summary"

    run = summary.shift
    assert_equal "A Team Van 2.0", run.project
    assert_equal "oracle", run.build
    assert_equal 1234, run.revision

    run = summary.shift
    assert_equal "A Team Van 2.0", run.project
    assert_equal "postgres", run.build
    assert_equal 1235, run.revision
  end
  
  def test_running_summary_filtered
    assert summary = Run.running_summary(:project => 'A Team Van 2.0'), "Should be some A Team projects in summary"
    assert_equal 2, summary.length, "Should be 2 runs over 1 project in the filtered summary"

    run = summary.shift
    assert_equal "A Team Van 2.0", run.project
    assert_equal "oracle", run.build
    assert_equal 1234, run.revision

    run = summary.shift
    assert_equal "A Team Van 2.0", run.project
    assert_equal "postgres", run.build
    assert_equal 1235, run.revision

    assert summary = Run.running_summary(:build => 'oracle'), "Should be some oracle builds in the summary"
    assert_equal 1, summary.length, "Should be 1 run over 1 project in the filtered summary"

    run = summary.shift
    assert_equal "A Team Van 2.0", run.project
    assert_equal "oracle", run.build
    assert_equal 1234, run.revision

    assert summary = Run.running_summary(:build => 'oracle', :project => "A Team Van 2.0"), "Should be an oracle build for ATeam in the summary"
    assert_equal 1, summary.length, "Should be 1 run over 1 project in the filtered summary"

    run = summary.shift
    assert_equal "A Team Van 2.0", run.project
    assert_equal "oracle", run.build
    assert_equal 1234, run.revision
 
    assert summary = Run.running_summary(:project => "Bogus Project"), "Should return an empty summary list."
    assert_equal 0, summary.length, "Should be no runs in the filtered summary"
  end
end
