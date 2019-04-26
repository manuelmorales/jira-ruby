module JIRA
  module Resource
    class StatusFactory < JIRA::BaseFactory # :nodoc:
    end

    class Status < JIRA::Base
      def category_key
        statusCategory['key']
      end
    end
  end
end
