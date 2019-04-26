module JIRA
  module Resource
    class ChangelogEntryFactory < JIRA::BaseFactory # :nodoc:
    end

    class ChangelogEntry < JIRA::Base
      def status_change?
        !!status_change_item
      end

      def status_change_item
        self.items.detect{|i| i['field'] == 'status' }
      end

      def from_status
        all_statuses.detect{|s| s.id == status_change_item['from'] } if status_change?
      end

      def to_status
        all_statuses.detect{|s| s.id == status_change_item['to'] } if status_change?
      end

      private

      def all_statuses
        @@all_statuses ||= client.Status.all
      end
    end
  end
end
