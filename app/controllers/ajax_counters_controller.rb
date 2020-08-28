class AjaxCountersController < ApplicationController
  def counters
    counters = params[:counters]

    res_counters = {}
    if counters.present? && counters.is_a?(Array)
      counters.uniq.each do |counter_md5|
        next unless counter_md5.is_a?(String)

        counter = AclAjaxCounter[counter_md5]
        next if counter.blank?
        action_name = counter[:action_name]
        next unless User.current.respond_to?(action_name)
        period = counter[:period].to_i
        ext_params = counter[:params]

        begin
          count = User.current.send(action_name, view_context, ext_params || params, session).to_i
          if period > 0
            session[counter_md5] = { c: count, t: Time.now.utc, p: period }
          end
        end

        if count != 0
          res_counters[counter_md5] = count
        end
      end
    end

    render json: res_counters
  end
end