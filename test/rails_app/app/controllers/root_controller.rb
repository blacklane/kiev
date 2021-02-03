# frozen_string_literal: true

class RootController < ActionController::Base
  def show
    respond_to do |format|
      format.html { render html: "body" }
      format.json { render json: "{\"body\":true}" }
      format.xml { render xml: "<body>true</body>" }
    end
  end

  def post_file
    respond_to do |format|
      format.html do
        params[:file].read
        params[:file].close
        render text: "body"
      end
    end
  end

  def log_in_action
    respond_to do |format|
      Rails.logger.info("test")
      format.html { render html: "body" }
    end
  end

  def request_data
    respond_to do |format|
      Kiev.payload(
        a: 0.0 / 0,
        b: BigDecimal("1"),
        c: "test",
        "c" => "c",
        d: User.new(id: 100, name: "Joe"),
        e: -3.14,
        f: true,
        j: false
      )
      format.html { render html: "body" }
    end
  end

  def raise_exception
    raise RuntimeError, "Error"
  end

  def record_not_found
    raise ActiveRecord::RecordNotFound if defined?(ActiveRecord)
  end

  def get_by_id
    respond_to do |format|
      format.html { render html: "body" }
    end
  end

  def test_event
    Kiev.event(:test_event, some_data: User.new(id: 1000, name: "Jane", money: BigDecimal("1") / 3))
    respond_to do |format|
      format.html { render html: "body" }
    end
  end

  def exception_as_control_flow
    raise KievIgnoredException, "exception message"
  end

  # You should be careful about rescue_from
  # Order matters. More generic errors should go first
  # This handler also will catch ActiveRecord::RecordNotFound and others
  def error_generic(exception)
    # if you are using generic error handler you must pass error to Kiev explicitly
    Kiev.error = exception
    # using this to show propper error code for ActiveRecord::RecordNotFound
    # but text in case of ActiveRecord::RecordNotFound will be wrong
    render(
      status: ::ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name),
      plain: "Internal server error"
    )
  end
  rescue_from StandardError, with: :error_generic

  # https://apidock.com/rails/ActiveSupport/Rescuable/ClassMethods/rescue_from
  rescue_from("KievIgnoredException") do |exception|
    render plain: exception.message, status: 403
  end
end
