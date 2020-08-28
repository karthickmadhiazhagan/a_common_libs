class ApiLogForPluginsController < ApplicationController
  self.main_menu = false
  before_action :require_admin
  before_action :find_log, only: [:log_served]

  def index
    @plugin_codes = ApiLogForPlugin.select(:plugin_code).group(:plugin_code).map(&:plugin_code)
    @api_logs = ApiLogForPlugin.all.order(created_at: :desc)
    if params[:plugin_code]
      @api_logs = @api_logs.where(plugin_code: params[:plugin_code])
    end
    @limit = params[:per_page].to_i == 0 ? 25 : params[:per_page].to_i
    @api_logs_count = @api_logs.size
    @api_logs_pages = Paginator.new self, @api_logs_count, @limit, params['page']
    @offset ||= @api_logs_pages.current.offset
    @api_logs = @api_logs.limit(@limit).offset(@offset)
  end

  def log_served
    @log.served = !@log.served
    if @log.save
      respond_to do |format|
        format.html { head :ok }
        format.js
      end
    else
      head 400
    end
  end

  private

  def find_log
    @log = ApiLogForPlugin.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end