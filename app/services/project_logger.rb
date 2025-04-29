# app/services/project_logger.rb
class ProjectLogger
  class << self
    def debug(message, options = {})
      log("debug", message, options)
    end

    def info(message, options = {})
      log("info", message, options)
    end

    def warn(message, options = {})
      log("warn", message, options)
    end

    def error(message, options = {})
      log("error", message, options)
    end

    def fatal(message, options = {})
      log("fatal", message, options)
    end

    private

    def log(level, message, options = {})
      # Also log to Rails logger for console visibility
      Rails.logger.send(level, message)

      # Create database log entry
      ProjectLog.log(level, message, options)
    rescue => e
      # If database logging fails, at least log to Rails logger
      Rails.logger.error("Failed to create project log: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end
end
