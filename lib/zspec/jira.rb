module ZSpec
  class Jira
    def initialize(jira_client:, issue_count:, project_name:, transition_id:, tracker:)
      @jira_client   = jira_client
      @issue_count   = issue_count
      @project_name  = project_name
      @transition_id = transition_id
      @tracker       = tracker
    end

    def report
      @tracker.current_failures.each do |failure|
        message = failure["message"]

        alltime_failure = alltime_failures[message]
        next if alltime_failure.nil?

        issue = issues[zpsec_key(message)]
        if issue.nil?
          create_issue(alltime_failure)
        elsif issue.status.name == "Done"
          save_issue(issue, alltime_failure)
          transition_issue(issue)
        end
      end
    rescue StandardError
    end

    private

    def create_issue(failure)
      save_issue(@jira_client.Issue.build, failure)
    end

    def transition_issue(issue)
      issue.transitions.build.save("transition" => { "id" => @transition_id })
    end

    def save_issue(issue, failure)
      issue.save(
        "fields" => {
          "summary" => zpsec_key(failure["message"]),
          "description" => "#{failure['message']} failed #{failure['count']} times.",
          "project" => {
            "key" => @project_name
          },
          "labels" => ["flake"],
          "issuetype" => {
            "name": "Bug"
          }
        }
      )
    end

    def alltime_failures
      @alltime_failures ||= @tracker.alltime_failures.take(@issue_count)
        .to_h { |failure| [failure["message"], failure] }
    end

    def project
      @project ||= @jira_client.Project.find(@project_name)
    end

    def issues
      @issues ||= project.issues.to_h { |issue| [issue.summary, issue] }
    end


    def zpsec_key(message)
      "ZSPEC: #{message}"
    end
  end
end
