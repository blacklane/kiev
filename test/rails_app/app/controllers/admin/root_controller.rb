# frozen_string_literal: true

module Admin
  class RootController < ActionController::Base
    def get_by_id
      respond_to do |format|
        format.html { render html: "body" }
      end
    end
  end
end
