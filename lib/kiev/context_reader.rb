# frozen_string_literal: true

module Kiev
  # Abstracts common details about reading tracing context
  # into Kiev's request store. Subclass and override #[] to
  # change field lookup.
  class ContextReader
    REQUEST_ID = "request_id"
    REQUEST_DEPTH = "request_depth"
    TREE_PATH = "tree_path"

    def initialize(subject)
      @subject = subject
    end

    def [](key)
      subject[key]
    end

    def request_id
      self[REQUEST_ID] || SecureRandom.uuid
    end

    def tree_root?
      !self[REQUEST_ID]
    end

    def request_depth
      tree_root? ? 0 : (self[REQUEST_DEPTH].to_i + 1)
    end

    def tree_path
      if tree_root?
        SubrequestHelper.root_path(synchronous: false)
      else
        self[TREE_PATH]
      end
    end

    private

    attr_reader :subject
  end
end
