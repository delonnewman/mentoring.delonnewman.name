# frozen_string_literal: true

module Mentoring
  # Represent users of the system
  class User < Application.Entity()
    primary_key :id
    reference :username, :string, unique: true
    has :mentor, :boolean, required: false

    has :displayname, :string, required: false
    belongs_to :role

    has :meta, :hash, serialize: true, default: El::EMPTY_HASH

    email
    password

    timestamps

    def availability_schedule
      meta.fetch('profile.availability') { El::EMPTY_HASH }
    end

    def available?(now: Time.now)
      day = availability_schedule[now.wday]
      return false unless day

      now.hour >= day[:start] && now.hour <= day[:end]
    end

    def timezone
      tz = meta['profile.timezone']
      return unless tz

      zone = Timezone[tz]
      return unless zone.valid?

      zone
    end

    def utc_offset
      tz = timezone
      return unless tz

      tz.utc_offset(Time.now)
    end

    def localtime
      tz = timezone
      return unless tz

      t = Net::NTP.get('time.apple.com').reference_timestamp
      Time.at(t, in: tz)
    end

    def currently_available?(sessions:)
      available? && sessions.active_sessions(for_mentor: self).empty?
    end

    def status
      return :not_available unless available?

      :available
    end

    def name
      displayname || username
    end
    alias to_s name

    def stripe_description
      "#{name} (mentoring customer)"
    end

    def stripe_customer_id
      meta.fetch('stripe.customer_id')
    end

    def stripe_customer_id?
      !!meta['stripe.customer_id']
    end

    def first_name
      displayname.split(/\s+/).first || username
    end

    def admin?
      role?(:admin)
    end

    def role?(name)
      name = name.is_a?(Symbol) ? name.name : name
      role.name == name
    end
  end
end
