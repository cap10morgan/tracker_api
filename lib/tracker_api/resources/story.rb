module TrackerApi
  module Resources
    class Story
      include Shared::Base

      attribute :client

      attribute :accepted_at, DateTime
      attribute :comment_ids, Shared::Collection[Integer]
      attribute :comments, Shared::Collection[Comment]
      attribute :created_at, DateTime
      attribute :current_state, String # (accepted, delivered, finished, started, rejected, planned, unstarted, unscheduled)
      attribute :deadline, DateTime
      attribute :description, String
      attribute :estimate, Float
      attribute :external_id, String
      attribute :follower_ids, Shared::Collection[Integer]
      attribute :followers, Shared::Collection[Person]
      attribute :integration_id, Integer
      attribute :kind, String
      attribute :label_ids, Shared::Collection[Integer]
      attribute :labels, Shared::Collection[Label]
      attribute :name, String
      attribute :owned_by_id, Integer # deprecated!
      attribute :owned_by, Person
      attribute :owner_ids, Shared::Collection[Integer]
      attribute :owners, Shared::Collection[Person]
      attribute :planned_iteration_number, Integer
      attribute :project_id, Integer
      attribute :requested_by, Person
      attribute :requested_by_id, Integer
      attribute :story_type, String # (feature, bug, chore, release)
      attribute :task_ids, Shared::Collection[Integer]
      attribute :tasks, Shared::Collection[Task]
      attribute :updated_at, DateTime
      attribute :url, String


      class UpdateRepresenter < Representable::Decorator
        include Representable::JSON

        property :follower_ids, if: ->(options) { !options[:input].blank? }
        property :name
        property :description
        property :story_type
        property :current_state
        property :estimate
        property :accepted_at
        property :deadline
        property :requested_by_id
        property :owner_ids, if: ->(options) { !options[:input].blank? }
        collection :labels, class: Label, decorator: Label::UpdateRepresenter, render_empty: true
        property :integration_id
        property :external_id
      end

      # @return [String] Comma separated list of labels.
      def label_list
        @label_list ||= labels.collect(&:name).join(',')
      end

      # Adds a new label to the story.
      #
      # @param [Label|Hash|String] label
      def add_label(label)
        new_label = if label.kind_of?(String)
          Label.new(name: label)
        else
          label
        end

        # Use attribute writer to get coercion and dirty tracking.
        self.labels = @labels.dup.push(new_label)
      end

      # Provides a list of all the activity performed on the story.
      #
      # @param [Hash] params
      # @return [Array[Activity]]
      def activity(params = {})
        Endpoints::Activity.new(client).get_story(project_id, id, params)
      end

      # Provides a list of all the comments on the story.
      #
      # @param [Hash] params
      # @return [Array[Comment]]
      def comments(params = {})
        if params.blank? && @comments.present?
          @comments
        else
          @comments = Endpoints::Comments.new(client).get(project_id, id, params)
        end
      end

      # Provides a list of all the tasks on the story.
      #
      # @param [Hash] params
      # @return [Array[Task]]
      def tasks(params = {})
        if params.blank? && @tasks.present?
          @tasks
        else
          @tasks = Endpoints::Tasks.new(client).get(project_id, id, params)
        end
      end

      # Provides a list of all the owners of the story.
      #
      # @param [Hash] params
      # @return [Array[Person]]
      def owners(params = {})
        if params.blank? && @owners.present?
          @owners
        else
          @owners = Endpoints::StoryOwners.new(client).get(project_id, id, params)
        end
      end

      # @param [Hash] params attributes to create the task with
      # @return [Task] newly created Task
      def create_task(params)
        Endpoints::Task.new(client).create(project_id, id, params)
      end

      # Save changes to an existing Story.
      def save
        raise ArgumentError, 'Can not update a story with an unknown project_id.' if project_id.nil?

        Endpoints::Story.new(client).update(self, UpdateRepresenter.new(Story.new(self.dirty_attributes)))
      end
    end
  end
end
