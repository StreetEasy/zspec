module ZSpec
  class Jira
    CLOSED_TRANSITIONS = ["Closed", "Done", "Won't Do", "CLOSED", "DONE", "WON'T DO"].freeze
    OPEN_TRANSITIONS = ["Reopened", "Open", "To Do", "REOPENED", "OPEN", "TO DO"].freeze

    def initialize(jira_client:, issue_count:, project_name:, tracker:)
      @jira_client   = jira_client
      @issue_count   = issue_count
      @project_name  = project_name
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
        elsif closed?(issue)
          update_issue(issue, alltime_failure)
          transition_issue(issue)
        end
      end
    rescue StandardError
    end

    private

    def create_issue(failure)
      @jira_client.Issue.build.issue.save(
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

    def update_issue(issue, failure)
      issue.save(
        "fields" => {
          "description" => "#{failure['message']} failed #{failure['count']} times."
        }
      )
    end

    def transition_issue(issue)
      issue.transitions.build.save("transition" => { "id" => get_open_transition_id(issue) })
    end

    def alltime_failures
      @alltime_failures ||= @tracker.alltime_failures.take(@issue_count)
        .to_h { |failure| [failure["message"], failure] }
    end

    def issues
      @issues ||= @jira_client.Issue.jql('labels = "flake"', expand: %w(transitions))
        .to_h { |issue| [issue.summary, issue] }
    end

    def get_open_transition_id(issue)
      issue.transitions.select { |t| OPEN_TRANSITIONS.include? t.name }.first.id
    end

    def closed?(issue)
      issue.transitions.select { |t| CLOSED_TRANSITIONS.include? t.name }.any? { |t| t.name == issue.status.name }
    end

    def zpsec_key(message)
      "ZSPEC: #{message}"
    end
  end
end
