class LogCleaner
  def initialize( options = {} )
    @type = options[:type]
    @from = options[:from]
    @to   = options[:to]
  end

  def clean
    local  if @type.eql? "local"
    server if @type.eql? "server"
  end

  private

  def local
    if (@from && @to)
      deleted_logs = PingLog.local.where(:created_at => @from..@to).destroy_all
    elsif (@from && @to.nil?)
      deleted_logs = PingLog.local.from_date(@from).destroy_all
    elsif (@from.nil? && @to)
      deleted_logs = PingLog.local.to_date(@to).destroy_all
    end
    RedisTools.clear_by_log(deleted_logs)
  end

  def server
    if (@from && @to)
      PingLog.server.where(:created_at => @from..@to).destroy_all
    elsif (@from && @to.nil?)
      PingLog.server.from_date(@from).destroy_all
    elsif (@from.nil? && @to)
      PingLog.server.to_date(@to).destroy_all
    end
  end
end