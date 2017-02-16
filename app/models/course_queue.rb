class CourseQueue < ApplicationRecord
  belongs_to :course
  has_many :course_queue_entries
  has_many :course_queue_online_instructors
  has_many :online_instructors, through: :course_queue_online_instructors, class_name: 'User'

  def request(requester:, description:, location:, group:)
    # Check the user's request limit
    if outstanding_requests.where(requester: requester).count > 0
      raise "Limit one open request per user"
    end

    # Now the group's
    count = outstanding_requests.where(course_group: group).count
    if group_mode && group && count > 0
      raise "Limit one open request per group"
    end

    CourseQueueEntry.create!(
      course_queue: self,
      requester: requester,
      course_group: group,
      description: description,
      location: location,
    )
  end

  def outstanding_requests
    course_queue_entries.where(resolved_at: nil).order('created_at ASC')
  end

  def pop!(user)
    self.outstanding_requests.first.resolve_by!(user)
  end

  def is_open?
    self.online_instructors.count > 0
  end

  def self.open_queues
    where(is_open: true)
  end
end
