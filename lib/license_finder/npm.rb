require 'json'
require 'license_finder/package'

module LicenseFinder
  class NPM

    DEPENDENCY_GROUPS = ["dependencies", "devDependencies", "bundleDependencies", "bundledDependencies"]

    def self.current_modules
      return @modules if @modules

      json = npm_json
      dependencies = DEPENDENCY_GROUPS.map { |g| (json[g] || {}).values }.flatten(1).reject{ |d| d.is_a?(String) }

      @modules = dependencies.map do |node_module|
        Package.new(OpenStruct.new(
          :name => node_module.fetch("name", nil),
          :version => node_module.fetch("version", nil),
          :full_gem_path => node_module.fetch("path", nil),
          :license => self.harvest_license(node_module),
          :summary => node_module.fetch("description", nil),
          :description => node_module.fetch("readme", nil)
        ))
      end
    end

    def self.has_package?
      File.exists?(package_path)
    end

    private

    def self.npm_json
      command = "npm list --json --long"
      output, success = capture(command)
      if success
        json = JSON(output)
      else
        json = JSON(output) rescue nil
        if json
          $stderr.puts "Command #{command} returned error but parsing succeeded."
        else
          raise "Command #{command} failed to execute: #{output}"
        end
      end
      json
    end

    def self.capture(command)
      [`#{command}`, $?.success?]
    end

    def self.package_path
      Pathname.new('package.json').expand_path
    end

    def self.harvest_license(node_module)
      license = node_module.fetch("licenses", []).first

      if license.is_a? Hash
        license = license.fetch("type", nil)
      end

      if license.nil?
        license = node_module.fetch("license", nil)

        if license.is_a? Hash
          license = license.fetch("type", nil)
        end
      end

      license
    end
  end
end
