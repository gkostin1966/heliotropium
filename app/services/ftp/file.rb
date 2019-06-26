# frozen_string_literal: true

module Ftp
  class File
    def self.null_file
      NullFile.new
    end

    def initialize(service, pathname)
      @service = service
      @pathname = pathname
    end

    def name
      ::File.basename(@pathname)
    end

    def content
      buffer = ''
      Net::FTP.open(@service.host, username: @service.user, password: @service.password, ssl: true) do |ftp|
        ::File.dirname(@pathname).split(::File::SEPARATOR).each do |dirname|
          ftp.chdir(dirname)
        end
        buffer = ftp.getbinaryfile(name, nil)
      rescue StandardError => e
        Rails.logger.error e
      end
      buffer
    end
  end

  class NullFile < File
    def initialize
      super(nil, nil)
    end

    def name
      ''
    end

    def content
      ''
    end
  end
end