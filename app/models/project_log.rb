# app/models/project_log.rb
class ProjectLog < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :user, optional: true

  LEVELS = %w[debug info warn error fatal].freeze

  validates :level, inclusion: { in: LEVELS }
  validates :source, :message, :logged_at, presence: true

  before_validation :set_logged_at, on: :create

  def self.log(level, message, options = {})
    create(
      level: level.to_s,
      message: message,
      source: options[:source] || "application",
      project_id: options[:project_id],
      user_id: options[:user_id],
      details: options[:details],
      metadata: options[:metadata],
      tag: options[:tag],
      logged_at: options[:logged_at] || Time.current
    )
  end

  def self.debug(message, options = {})
    log("debug", message, options)
  end

  def self.info(message, options = {})
    log("info", message, options)
  end

  def self.warn(message, options = {})
    log("warn", message, options)
  end

  def self.error(message, options = {})
    log("error", message, options)
  end

  def self.fatal(message, options = {})
    log("fatal", message, options)
  end

  private

  def set_logged_at
    self.logged_at ||= Time.current
  end
end
