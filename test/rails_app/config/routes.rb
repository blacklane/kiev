# frozen_string_literal: true

Rails.application.routes.draw do
  namespace(:admin) do
    get("get_by_id/:id" => "root#get_by_id")
    post("get_by_id/:id" => "root#get_by_id")
  end

  get("/" => "root#show")
  post("/" => "root#show")
  post("post_file" => "root#post_file")
  get("log_in_action" => "root#log_in_action")
  get("request_data" => "root#request_data")
  get("raise_exception" => "root#raise_exception")
  get("record_not_found" => "root#record_not_found")
  get("get_by_id/:id" => "root#get_by_id")
  post("get_by_id/:id" => "root#get_by_id")
  get("test_event" => "root#test_event")
  get("exception_as_control_flow" => "root#exception_as_control_flow")
end
